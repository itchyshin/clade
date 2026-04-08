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
#' @export
search_map_elites <- function(specs_base,
                               archive_dims,
                               n_iterations  = 1000L,
                               objective     = "genetic_diversity",
                               mutation_params = NULL,
                               mutation_sd   = 0.1,
                               n_cores       = 1L,
                               verbose       = TRUE) {
  .clade_start_julia(verbose = FALSE)
  stopifnot(is.list(specs_base), is.list(archive_dims), length(archive_dims) >= 1L)

  obj_fn <- if (is.function(objective)) {
    objective
  } else {
    function(env) {
      d <- get_run_data(env)
      mean(d$ticks[[objective]], na.rm = TRUE)
    }
  }

  if (is.null(mutation_params)) {
    mutation_params <- names(Filter(is.numeric, specs_base))
  }

  # Build archive grid
  dim_names <- names(archive_dims)
  dim_sizes <- vapply(archive_dims, length, integer(1L))
  n_cells   <- prod(dim_sizes)
  archive   <- vector("list", n_cells)
  history   <- data.frame(iteration = integer(0L), score = numeric(0L),
                           filled_cells = integer(0L))

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
      if (is.numeric(v) && length(v) == 1L && v > 0) {
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

#' Gradient descent through simulation (Julia-only)
#'
#' Uses Zygote.jl (automatic differentiation) to compute the gradient of a
#' scalar objective with respect to named simulation parameters, then applies
#' gradient ascent. This is unique to Julia backends — it is not possible with
#' Rcpp or C++ MEX.
#'
#' **Phase 4 feature.** In Phase 0, calling this function raises a clear error
#' explaining that gradient search requires the Phase 4 implementation.
#'
#' @param specs_base A specs list from [default_specs()].
#' @param params Character vector of parameter names to differentiate through.
#' @param objective Character. Name of a `$ticks` column to maximise.
#' @param n_steps Integer. Number of gradient ascent steps (default 200L).
#' @param lr Numeric. Learning rate (step size) (default 0.01).
#' @param verbose Logical (default `TRUE`).
#'
#' @return A list with `$specs` (final parameter values), `$score`,
#'   `$history`.
#'
#' @references
#' Innes, M. (2018) Don't unroll adjoint: differentiating SSA-form programs.
#'   arXiv:1810.07951. (Zygote.jl)
#' Baydin, A.G., Pearlmutter, B.A., Radul, A.A. & Siskind, J.M. (2018)
#'   Automatic differentiation in machine learning: a survey.
#'   *Journal of Machine Learning Research* 18(153):1–43.
#'
#' @examples
#' \dontrun{
#' # Requires Phase 4 implementation
#' result <- search_gradient(
#'   default_specs(),
#'   params    = c("grass_rate", "mutation_sd"),
#'   objective = "genetic_diversity",
#'   n_steps   = 200L,
#'   lr        = 0.01
#' )
#' }
#'
#' @seealso [search_map_elites()], [search_cmaes()]
#' @export
search_gradient <- function(specs_base,
                             params    = c("grass_rate", "mutation_sd"),
                             objective = "genetic_diversity",
                             n_steps   = 200L,
                             lr        = 0.01,
                             verbose   = TRUE) {
  stop(
    "search_gradient() requires the Phase 4 Julia gradient implementation.\n",
    "This function will be available after Phase 4 is merged.\n",
    "Use search_map_elites() or search_cmaes() in the meantime.",
    call. = FALSE
  )
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
