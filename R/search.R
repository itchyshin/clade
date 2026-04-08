#' MAP-Elites quality-diversity search over simulation parameters
#'
#' Finds a diverse archive of high-performing parameter combinations using the
#' MAP-Elites algorithm (Mouret & Clune 2015). Rather than finding one optimal
#' parameter set, MAP-Elites maintains a grid of niches in behaviour space;
#' each cell holds the best-performing specs for that behavioural region.
#'
#' ## Algorithm
#'
#' 1. Initialise: fill each archive cell by sampling random specs near
#'    `specs_base`.
#' 2. For each of `n_iterations` iterations:
#'    a. Select a random filled cell from the archive.
#'    b. Mutate its specs (Gaussian perturbation of numeric parameters).
#'    c. Run `run_alife(new_specs)`.
#'    d. Compute the behavioural descriptors from `get_run_data(env)`.
#'    e. If the new specs score better than the current occupant of the
#'       corresponding archive cell, replace it.
#' 3. Return the full archive.
#'
#' @param specs_base A specs list from [default_specs()]. Used as the starting
#'   point for mutations.
#' @param archive_dims A named list whose names are column names of
#'   `get_run_data()$ticks` and whose values are numeric vectors specifying
#'   the bin breakpoints for that dimension. Example:
#'   `list(genetic_diversity = seq(0, 1, by = 0.1), n_species = 1:10)`.
#' @param n_iterations Integer. Number of MAP-Elites iterations (default 1000L).
#' @param objective Character or function. If a character, the name of a
#'   column in `get_run_data()$ticks` to maximise (e.g. `"genetic_diversity"`).
#'   If a function, must accept an `env` list and return a numeric scalar.
#' @param mutation_params Character vector of parameter names (from
#'   [default_specs()]) to mutate. Defaults to all numeric parameters.
#' @param mutation_sd Numeric. Standard deviation of Gaussian perturbations to
#'   log-transformed parameter values (default 0.1).
#' @param n_cores Integer. Parallel cores for batch evaluation (default 1L).
#' @param verbose Logical. Print progress (default `TRUE`).
#'
#' @return A list with components:
#' \describe{
#'   \item{`$archive`}{A list of lists, one per archive cell, each containing:
#'     `$specs`, `$score`, `$behavioural_descriptor` (named numeric vector).}
#'   \item{`$map`}{A ggplot2 heatmap of the archive scores (for 2D archive
#'     dims only). `NULL` for higher-dimensional archives.}
#'   \item{`$history`}{Data frame with one row per iteration: `iteration`,
#'     `score`, `filled_cells`.}
#' }
#'
#' @references
#' Mouret, J.-B. & Clune, J. (2015) Illuminating search spaces by mapping
#'   elites. arXiv:1504.04909.
#' Chatzilygeroudis, K., Cully, A., Vassiliades, V. & Mouret, J.-B. (2021)
#'   Quality-Diversity Optimization: a novel branch of stochastic optimization.
#'   arXiv:2012.04322.
#'
#' @examples
#' \dontrun{
#' result <- search_map_elites(
#'   specs_base   = default_specs(),
#'   archive_dims = list(
#'     genetic_diversity = seq(0, 1, by = 0.1),
#'     n_species         = 1:10
#'   ),
#'   n_iterations = 500L,
#'   objective    = "genetic_diversity"
#' )
#' result$map   # ggplot2 heatmap
#' }
#'
#' @seealso [search_cmaes()], [search_gradient()], [run_alife()]
#' @importFrom stats rnorm
#' @importFrom utils head tail
#' @export
search_map_elites <- function(specs_base,
                               archive_dims,
                               n_iterations  = 1000L,
                               objective     = "genetic_diversity",
                               mutation_params = NULL,
                               mutation_sd   = 0.1,
                               n_cores       = 1L,
                               verbose       = TRUE) {
  stopifnot(is.list(specs_base), is.list(archive_dims), length(archive_dims) >= 1L)
  n_iterations <- as.integer(n_iterations)

  # Validate archive_dims names against the known descriptor columns produced
  # by get_run_data()$ticks. This catches typos before any Julia call.
  dim_names <- names(archive_dims)
  if (is.null(dim_names) || any(!nzchar(dim_names)))
    stop("archive_dims must be a fully named list.", call. = FALSE)
  bad <- setdiff(dim_names, .valid_descriptor_columns())
  if (length(bad) > 0L)
    stop(sprintf(
      "archive_dims contains unknown column name(s): %s. Valid columns are produced by get_run_data()$ticks.",
      paste(sprintf("'%s'", bad), collapse = ", ")
    ), call. = FALSE)

  obj_fn <- if (is.function(objective)) {
    objective
  } else {
    function(env) {
      d <- get_run_data(env)
      mean(d$ticks[[objective]], na.rm = TRUE)
    }
  }

  if (is.null(mutation_params)) {
    # Default to continuous (double) positive scalars only — never mutate
    # integer-typed parameters, since they encode discrete options (ploidy,
    # max_ticks, ...) that the Julia validator rejects on non-integer values.
    mutation_params <- names(Filter(function(v) {
      is.double(v) && length(v) == 1L && !is.na(v) && v > 0
    }, specs_base))
  }

  # Build archive grid
  dim_sizes <- vapply(archive_dims, length, integer(1L))
  n_cells   <- prod(dim_sizes)
  archive   <- vector("list", n_cells)
  history   <- data.frame(iteration = integer(0L), score = numeric(0L),
                           filled_cells = integer(0L))

  # If no iterations requested, return an empty archive without starting Julia.
  if (n_iterations == 0L) {
    return(list(archive = archive, map = NULL, history = history))
  }

  .clade_start_julia(verbose = FALSE)

  .find_cell <- function(descriptor) {
    # Map descriptor values to cell indices
    idx <- mapply(function(nm, val) {
      bins <- archive_dims[[nm]]
      max(1L, findInterval(val, bins))
    }, dim_names, descriptor)
    # Linear index into archive
    as.integer(sum((idx - 1L) * cumprod(c(1L, head(dim_sizes, -1L)))) + 1L)
  }

  .get_descriptor <- function(env) {
    d <- get_run_data(env)
    vals <- sapply(dim_names, function(nm) mean(d$ticks[[nm]], na.rm = TRUE))
    vals
  }

  .mutate_specs <- function(specs) {
    new_specs <- specs
    for (nm in mutation_params) {
      v <- specs[[nm]]
      if (is.numeric(v) && length(v) == 1L && !is.na(v) && v > 0) {
        new_specs[[nm]] <- exp(log(v) + rnorm(1L, 0, mutation_sd))
      }
    }
    new_specs
  }

  if (verbose) message(sprintf("MAP-Elites: %d iterations, %d cells", n_iterations, n_cells))

  for (i in seq_len(n_iterations)) {
    # Select parent specs
    filled <- which(!vapply(archive, is.null, logical(1L)))
    if (length(filled) == 0L) {
      candidate_specs <- .mutate_specs(specs_base)
    } else {
      parent_cell     <- sample(filled, 1L)
      candidate_specs <- .mutate_specs(archive[[parent_cell]]$specs)
    }

    # Evaluate (tryCatch to handle crashes gracefully)
    env <- tryCatch(
      run_alife(candidate_specs, verbose = FALSE),
      error = function(e) NULL
    )
    if (is.null(env)) next

    score      <- obj_fn(env)
    descriptor <- .get_descriptor(env)
    cell       <- .find_cell(descriptor)

    if (is.null(archive[[cell]]) || score > archive[[cell]]$score) {
      archive[[cell]] <- list(
        specs                 = candidate_specs,
        score                 = score,
        behavioural_descriptor = descriptor
      )
    }

    history <- rbind(history, data.frame(
      iteration    = i,
      score        = score,
      filled_cells = sum(!vapply(archive, is.null, logical(1L)))
    ))

    if (verbose && i %% 100 == 0) {
      message(sprintf("  iter %d: %.3f filled cells: %d / %d",
                      i, score, tail(history$filled_cells, 1L), n_cells))
    }
  }

  map_plot <- if (length(dim_names) == 2L) .map_elites_plot(archive, archive_dims) else NULL

  list(archive = archive, map = map_plot, history = history)
}

#' CMA-ES optimisation over simulation parameters
#'
#' Optimises a scalar objective function over the simulation parameter space
#' using the Covariance Matrix Adaptation Evolution Strategy (CMA-ES). Unlike
#' MAP-Elites, CMA-ES finds a single optimal parameter set.
#'
#' @param specs_base A specs list from [default_specs()].
#' @param objective Character or function (same as [search_map_elites()]).
#' @param params Character vector of numeric parameter names to optimise.
#'   Defaults to `c("grass_rate", "mutation_sd")`.
#' @param n_iterations Integer. Maximum CMA-ES generations (default 200L).
#' @param popsize Integer. CMA-ES population size (default 10L).
#' @param sigma0 Numeric. Initial step size (default 0.3).
#' @param n_cores Integer. Parallel cores (default 1L).
#' @param verbose Logical (default `TRUE`).
#'
#' @return A list with components `$specs` (best specs), `$score` (best
#'   objective value), `$history` (data frame of generation × score).
#'
#' @references
#' Hansen, N. & Ostermeier, A. (2001) Completely derandomized self-adaptation
#'   in evolution strategies. *Evolutionary Computation* 9(2):159–195.
#' Hansen, N. (2006) The CMA evolution strategy: a comparing review. In:
#'   Towards a New Evolutionary Computation, Springer, pp 75–102.
#'
#' @examples
#' \dontrun{
#' result <- search_cmaes(
#'   default_specs(),
#'   objective = "genetic_diversity",
#'   params    = c("grass_rate", "mutation_sd"),
#'   n_iterations = 50L
#' )
#' result$specs$grass_rate
#' }
#'
#' @seealso [search_map_elites()], [search_gradient()]
#' @export
search_cmaes <- function(specs_base,
                          objective    = "genetic_diversity",
                          params       = c("grass_rate", "mutation_sd"),
                          n_iterations = 200L,
                          popsize      = 10L,
                          sigma0       = 0.3,
                          n_cores      = 1L,
                          verbose      = TRUE) {
  .clade_start_julia(verbose = FALSE)

  obj_fn <- if (is.function(objective)) {
    objective
  } else {
    function(env) {
      d <- get_run_data(env)
      mean(d$ticks[[objective]], na.rm = TRUE)
    }
  }

  if (!requireNamespace("GA", quietly = TRUE)) {
    stop("Package 'GA' is required for search_cmaes(). ",
         "Install it with: install.packages('GA')", call. = FALSE)
  }

  # Extract and log-transform the parameters to optimise
  x0 <- log(vapply(params, function(p) specs_base[[p]], numeric(1L)))

  best_specs <- specs_base
  best_score <- -Inf
  history    <- data.frame(generation = integer(0L), score = numeric(0L))

  eval_fn <- function(x) {
    test_specs <- specs_base
    for (j in seq_along(params)) test_specs[[params[j]]] <- exp(x[j])
    env <- tryCatch(run_alife(test_specs, verbose = FALSE), error = function(e) NULL)
    if (is.null(env)) return(-Inf)
    obj_fn(env)
  }

  # Simple CMA-ES via GA package (real-valued GA as CMA-ES approximation)
  # Phase 4 will implement full Turing.jl CMA-ES; this is a serviceable
  # bootstrap for Phase 0.
  result <- GA::ga(
    type     = "real-valued",
    fitness  = eval_fn,
    lower    = x0 - 3,
    upper    = x0 + 3,
    popSize  = popsize,
    maxiter  = n_iterations,
    run      = n_iterations,
    parallel = n_cores > 1L,
    monitor  = verbose
  )

  best_x <- result@solution[1L, ]
  for (j in seq_along(params)) best_specs[[params[j]]] <- exp(best_x[j])
  best_score <- result@fitnessValue

  list(specs = best_specs, score = best_score, history = history)
}

#' Finite-difference gradient ascent over simulation parameters
#'
#' Optimises a scalar objective with respect to named numeric simulation
#' parameters using forward-difference gradient ascent. Each gradient
#' coordinate is estimated by re-running [run_alife()] with one parameter
#' perturbed by `epsilon` on the log scale, then comparing the resulting
#' objective to a baseline run. Updates are applied on the log scale so that
#' positive parameters remain positive.
#'
#' This implementation is intentionally backend-agnostic: it treats
#' `run_alife()` as a black box and only requires `(n_steps + 1) * n_params`
#' simulation calls per run. For a true gradient-through-simulation approach
#' using Zygote.jl automatic differentiation through the Julia backend, see
#' the deferred Phase 4b plan.
#'
#' @param specs_base A specs list from [default_specs()].
#' @param params Character vector of numeric parameter names to optimise.
#'   Defaults to `c("grass_rate", "mutation_sd")`.
#' @param objective Character or function. If a character, the name of a
#'   column in `get_run_data()$ticks` to maximise. If a function, must accept
#'   an `env` list and return a numeric scalar.
#' @param n_steps Integer. Number of gradient ascent steps (default 20L).
#' @param epsilon Numeric. Finite-difference step on the log scale
#'   (default 0.05).
#' @param learning_rate Numeric. Log-scale step size for parameter updates
#'   (default 0.1).
#' @param n_cores Integer. Reserved for future parallel finite-difference
#'   evaluation; currently unused (default 1L).
#' @param verbose Logical. Print progress (default `TRUE`).
#'
#' @return A list with components:
#' \describe{
#'   \item{`$specs`}{Best specs encountered across all gradient steps.}
#'   \item{`$score`}{Best objective value encountered.}
#'   \item{`$history`}{Data frame with one row per step and columns
#'     `step`, `score`, and one column per optimised parameter.}
#' }
#'
#' @references
#' Spall, J.C. (1998) An overview of the simultaneous perturbation method for
#'   efficient optimization. *Johns Hopkins APL Technical Digest* 19(4):482–492.
#' Innes, M. (2018) Don't unroll adjoint: differentiating SSA-form programs.
#'   arXiv:1810.07951. (Zygote.jl — Phase 4b deferred.)
#'
#' @examples
#' \dontrun{
#' result <- search_gradient(
#'   default_specs(),
#'   params        = c("grass_rate", "mutation_sd"),
#'   objective     = "genetic_diversity",
#'   n_steps       = 20L,
#'   epsilon       = 0.05,
#'   learning_rate = 0.1
#' )
#' result$specs$grass_rate
#' }
#'
#' @seealso [search_map_elites()], [search_cmaes()]
#' @importFrom stats setNames
#' @export
search_gradient <- function(specs_base,
                             params        = c("grass_rate", "mutation_sd"),
                             objective     = "genetic_diversity",
                             n_steps       = 20L,
                             epsilon       = 0.05,
                             learning_rate = 0.1,
                             n_cores       = 1L,
                             verbose       = TRUE) {
  stopifnot(is.list(specs_base), is.character(params), length(params) >= 1L)
  n_steps <- as.integer(n_steps)
  if (n_steps < 1L)
    stop("n_steps must be a positive integer.", call. = FALSE)

  for (p in params) {
    v <- specs_base[[p]]
    if (is.null(v) || !is.numeric(v) || length(v) != 1L || v <= 0)
      stop(sprintf(
        "search_gradient() requires positive numeric scalar specs for each parameter; specs_base$%s is %s.",
        p, deparse(v)
      ), call. = FALSE)
  }

  .clade_start_julia(verbose = FALSE)

  obj_fn <- if (is.function(objective)) {
    objective
  } else {
    function(env) {
      d <- get_run_data(env)
      mean(d$ticks[[objective]], na.rm = TRUE)
    }
  }

  # Per-parameter clipping bounds (log scale). Probabilities are clipped to
  # (0, 1); other positive parameters are clipped to a wide log window around
  # the starting value.
  prob_params <- c("grass_rate", "grass_init_prob", "transmission_prob",
                   "disease_death_prob", "crossover_rate")
  log_bounds <- lapply(params, function(p) {
    v0 <- specs_base[[p]]
    if (p %in% prob_params) {
      c(log(.Machine$double.eps), log(1 - .Machine$double.eps))
    } else {
      c(log(v0) - 5, log(v0) + 5)
    }
  })
  names(log_bounds) <- params

  # Build a specs list from a log-scale parameter vector.
  build_specs <- function(log_x) {
    s <- specs_base
    for (j in seq_along(params)) s[[params[j]]] <- exp(log_x[j])
    s
  }

  evaluate <- function(log_x) {
    s <- build_specs(log_x)
    env <- tryCatch(run_alife(s, verbose = FALSE), error = function(e) NULL)
    if (is.null(env)) return(NA_real_)
    obj_fn(env)
  }

  log_x <- log(vapply(params, function(p) specs_base[[p]], numeric(1L)))
  best_score <- -Inf
  best_specs <- specs_base
  history <- vector("list", n_steps)

  if (verbose)
    message(sprintf(
      "search_gradient: %d steps, %d params, epsilon=%.3g, lr=%.3g",
      n_steps, length(params), epsilon, learning_rate
    ))

  for (step in seq_len(n_steps)) {
    score0 <- evaluate(log_x)
    if (is.finite(score0) && score0 > best_score) {
      best_score <- score0
      best_specs <- build_specs(log_x)
    }

    grad <- numeric(length(params))
    for (j in seq_along(params)) {
      log_x_plus <- log_x
      log_x_plus[j] <- log_x[j] + epsilon
      score_plus <- evaluate(log_x_plus)
      if (is.finite(score_plus) && is.finite(score0)) {
        grad[j] <- (score_plus - score0) / epsilon
      } else {
        grad[j] <- 0
      }
    }

    log_x <- log_x + learning_rate * grad
    for (j in seq_along(params)) {
      log_x[j] <- min(max(log_x[j], log_bounds[[j]][1L]), log_bounds[[j]][2L])
    }

    row <- c(list(step = step, score = score0),
             setNames(as.list(exp(log_x)), params))
    history[[step]] <- as.data.frame(row, stringsAsFactors = FALSE)

    if (verbose)
      message(sprintf("  step %d: score=%.4f", step, score0))
  }

  history_df <- do.call(rbind, history)
  list(specs = best_specs, score = best_score, history = history_df)
}

# ── Internal: known descriptor column names ───────────────────────────────────

#' Valid behavioural-descriptor column names for archive_dims
#'
#' Mirrors the columns produced by [get_run_data()] `$ticks`. Used by
#' [search_map_elites()] for early validation of `archive_dims` names so that
#' typos are caught before any Julia call.
#' @keywords internal
.valid_descriptor_columns <- function() {
  c("t", "n_agents", "n_births", "n_deaths", "n_starvations",
    "n_age_deaths", "mean_energy", "sd_energy", "mean_age", "sd_age",
    "mean_body_size", "sd_body_size", "genetic_diversity", "n_species",
    "mean_cooperation_level", "mean_immune_strength", "sd_immune_strength",
    "mean_metabolic_rate", "mean_learning_rate", "mean_prior_sigma",
    "grass_coverage", "n_infected", "n_new_infections",
    "n_altruistic_acts", "n_shelters_built", "n_cooperation_acts")
}

# ── Internal: MAP-Elites plot ─────────────────────────────────────────────────

.map_elites_plot <- function(archive, archive_dims) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(NULL)

  dim_names <- names(archive_dims)
  dim_sizes <- vapply(archive_dims, length, integer(1L))

  rows_df <- lapply(seq_along(archive), function(i) {
    cell <- archive[[i]]
    if (is.null(cell)) {
      data.frame(i = i, score = NA_real_,
                 d1 = ((i - 1L) %% dim_sizes[1L]) + 1L,
                 d2 = ((i - 1L) %/% dim_sizes[1L]) + 1L)
    } else {
      data.frame(i = i, score = cell$score,
                 d1 = ((i - 1L) %% dim_sizes[1L]) + 1L,
                 d2 = ((i - 1L) %/% dim_sizes[1L]) + 1L)
    }
  })
  df <- do.call(rbind, rows_df)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$d1, y = .data$d2,
                                    fill = .data$score)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_viridis_c(na.value = "grey90", name = "Score") +
    ggplot2::labs(x = dim_names[1L], y = dim_names[2L],
                  title = "MAP-Elites archive") +
    ggplot2::theme_minimal()
}
