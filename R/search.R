# ── Internal: objective function factory ─────────────────────────────────────

#' Build an objective function from a character name or callable
#'
#' All four search functions accept `objective` as either a column name
#' (character) or a function `f(env) -> scalar`. This helper standardises
#' both cases, eliminating four identical copy-pasted blocks.
#'
#' @param objective Character column name or a function accepting a `clade_env`
#'   object and returning a numeric scalar.
#' @return A function `f(env) -> numeric(1)`.
#' @keywords internal
.make_obj_fn <- function(objective) {
  if (is.function(objective)) return(objective)
  col <- objective
  function(env) {
    d <- get_run_data(env)
    mean(d$ticks[[col]], na.rm = TRUE)
  }
}

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
#' @param verbose Logical. Print progress (default `TRUE`).
#' @param checkpoint_path Optional file path. If supplied, the current
#'   archive + history + iteration index are saved to this RDS file every
#'   `checkpoint_every` iterations (and once more at the end). If the
#'   same path is passed to a subsequent call, the search resumes from
#'   the saved iteration. Set to `NULL` (default) to disable
#'   checkpointing. Added 0.5.6.
#' @param checkpoint_every Integer. How often to write the checkpoint,
#'   in iterations (default 100L). Ignored when `checkpoint_path` is
#'   `NULL`. Added 0.5.6.
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
                               n_iterations     = 1000L,
                               objective        = "genetic_diversity",
                               mutation_params  = NULL,
                               mutation_sd      = 0.1,
                               verbose          = TRUE,
                               checkpoint_path  = NULL,
                               checkpoint_every = 100L) {
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

  obj_fn <- .make_obj_fn(objective)

  if (is.null(mutation_params)) {
    # 0.4.1: prefer high-leverage behavioural drivers as the default search
    # axes. Previously the default was "every positive double in specs",
    # which produced tiny behavioural variation because most spec entries
    # (brain_energy_base, bnn_sigma_init, etc.) have weak coupling to
    # genetic_diversity / n_agents. The resulting archive typically filled
    # only one cell (see dev/audit/fidelity/map_elites.md).
    #
    # The curated list below maps to the main axes of population dynamics
    # and trait evolution. Users who want a different default can pass
    # `mutation_params` explicitly.
    behavioural_drivers <- c(
      "grass_rate", "mutation_sd", "move_cost", "idle_cost",
      "metabolic_rate_init_mean", "max_bite"
    )
    mutation_params <- intersect(behavioural_drivers, names(specs_base))
    # Fallback: if none of the drivers are present in a custom specs
    # object, fall back to the legacy "all positive doubles" filter.
    if (length(mutation_params) == 0L) {
      mutation_params <- names(Filter(function(v) {
        is.double(v) && length(v) == 1L && !is.na(v) && v > 0
      }, specs_base))
    }
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

  # 0.5.6: checkpoint/resume. If `checkpoint_path` points at an
  # existing RDS, load the saved archive + history + last iteration
  # index and resume from i = (last_i + 1). Otherwise start fresh.
  start_iter <- 1L
  if (!is.null(checkpoint_path) && file.exists(checkpoint_path)) {
    saved <- tryCatch(readRDS(checkpoint_path), error = function(e) NULL)
    if (!is.null(saved) && is.list(saved) &&
        all(c("archive", "history", "iteration") %in% names(saved))) {
      archive <- saved$archive
      history <- saved$history
      start_iter <- as.integer(saved$iteration) + 1L
      if (verbose)
        message(sprintf("MAP-Elites: resuming from checkpoint %s at iter %d",
                        checkpoint_path, start_iter))
    }
  }

  .save_checkpoint <- function(iter) {
    if (is.null(checkpoint_path)) return(invisible(NULL))
    saveRDS(list(archive = archive, history = history,
                 iteration = iter),
            file = checkpoint_path)
    invisible(NULL)
  }

  if (verbose) message(sprintf("MAP-Elites: %d iterations, %d cells", n_iterations, n_cells))

  for (i in seq.int(start_iter, n_iterations)) {
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

    if (!is.null(checkpoint_path) &&
        as.integer(checkpoint_every) > 0L &&
        i %% as.integer(checkpoint_every) == 0L) {
      .save_checkpoint(i)
    }

    if (verbose && i %% 100 == 0) {
      message(sprintf("  iter %d: %.3f filled cells: %d / %d",
                      i, score, tail(history$filled_cells, 1L), n_cells))
    }
  }

  # 0.5.6: final checkpoint after the loop completes, so the last
  # iteration's result is persisted even if it fell between scheduled
  # checkpoints.
  if (!is.null(checkpoint_path)) .save_checkpoint(n_iterations)

  # 0.4.1: warn if the archive coverage is pathologically low at the end —
  # a strong signal that the mutation step is too small for the chosen
  # archive resolution, or that the simulator's behavioural descriptor
  # hasn't had time to equilibrate at the chosen `max_ticks`. Skipped when
  # the user asked for verbose=FALSE (search already logged quiet), or when
  # fewer than 50 iterations ran (might just be a warm-up).
  filled_frac <- sum(!vapply(archive, is.null, logical(1L))) / n_cells
  if (filled_frac < 0.1 && n_iterations >= 50L) {
    warning(sprintf(
      "MAP-Elites: only %.1f%% of the archive (%d / %d cells) was filled ",
      100 * filled_frac, sum(!vapply(archive, is.null, logical(1L))), n_cells),
      "after ", n_iterations, " iterations. ",
      "Possible causes: (a) mutation_sd too small (try 0.2 or 0.3); ",
      "(b) archive_dims bins too fine for the behavioural range; ",
      "(c) max_ticks too short for the descriptor to stabilise; ",
      "(d) mutation_params doesn't include behavioural drivers (defaults ",
      "to grass_rate / mutation_sd / move_cost / idle_cost / ",
      "metabolic_rate_init_mean / max_bite when available).",
      call. = FALSE)
  }

  map_plot <- if (length(dim_names) == 2L) .map_elites_plot(archive, archive_dims) else NULL

  list(archive = archive, map = map_plot, history = history)
}

#' CMA-ES optimisation over simulation parameters
#'
#' Optimises a scalar objective function over the simulation parameter space
#' using a pure-R implementation of the Covariance Matrix Adaptation Evolution
#' Strategy (CMA-ES; Hansen & Ostermeier 2001). Unlike MAP-Elites, CMA-ES
#' finds a single optimal parameter set by adapting its search distribution to
#' the local curvature of the objective landscape.
#'
#' Parameters are optimised on the log scale so that positive constraints are
#' always satisfied. Each generation evaluates `lambda` candidate parameter
#' sets, selects the best `mu = lambda/2`, and updates the mean, step size,
#' and covariance matrix. No external packages are required.
#'
#' @param specs_base A specs list from [default_specs()].
#' @param objective Character or function (same as [search_map_elites()]).
#' @param params Character vector of positive numeric parameter names to
#'   optimise. Defaults to `c("grass_rate", "mutation_sd")`.
#' @param n_iterations Integer. Maximum CMA-ES generations (default 200L).
#' @param popsize Integer or `NULL`. CMA-ES population size `lambda`. If
#'   `NULL` (default), uses the standard formula
#'   `max(8, 4 + floor(3 * log(n_params)))`.
#' @param sigma0 Numeric. Initial step size on the log scale (default 0.3).
#' @param n_cores Integer. Parallel cores for candidate evaluation (default
#'   1L). Uses [parallel::makeCluster()] PSOCK workers (one R session +
#'   Julia per worker) when `> 1`. Was `parallel::mclapply` before 0.5.6
#'   but that path silently deadlocked because JuliaConnectoR is not
#'   fork-safe.
#' @param verbose Logical (default `TRUE`).
#'
#' @return A list with:
#' \describe{
#'   \item{`$specs`}{Best specs encountered across all generations.}
#'   \item{`$score`}{Best objective value encountered.}
#'   \item{`$history`}{Data frame with one row per generation and columns
#'     `generation`, `evals`, `best_score`, `mean_score`, `sigma`.}
#' }
#'
#' @references
#' Hansen, N. & Ostermeier, A. (2001) Completely derandomized self-adaptation
#'   in evolution strategies. *Evolutionary Computation* 9(2):159-195.
#' Hansen, N. (2006) The CMA evolution strategy: a comparing review. In:
#'   Towards a New Evolutionary Computation, Springer, pp 75-102.
#'
#' @examples
#' \dontrun{
#' result <- search_cmaes(
#'   default_specs(),
#'   objective    = "genetic_diversity",
#'   params       = c("grass_rate", "mutation_sd"),
#'   n_iterations = 50L
#' )
#' result$specs$grass_rate
#' result$history   # one row per generation
#' }
#'
#' @seealso [search_map_elites()], [search_gradient()], [search_viability()]
#' @importFrom stats rnorm
#' @export
search_cmaes <- function(specs_base,
                          objective    = "genetic_diversity",
                          params       = c("grass_rate", "mutation_sd"),
                          n_iterations = 200L,
                          popsize      = NULL,
                          sigma0       = 0.3,
                          n_cores      = 1L,
                          verbose      = TRUE) {
  stopifnot(is.list(specs_base), is.character(params), length(params) >= 1L)
  n_iterations <- as.integer(n_iterations)
  n_cores      <- as.integer(n_cores)

  for (p in params) {
    v <- specs_base[[p]]
    if (is.null(v) || !is.numeric(v) || length(v) != 1L || v <= 0)
      stop(sprintf(
        "search_cmaes() requires positive numeric params; specs_base$%s is %s.",
        p, deparse(v)
      ), call. = FALSE)
  }

  .clade_start_julia(verbose = FALSE)
  obj_fn <- .make_obj_fn(objective)

  # ---- CMA-ES hyper-parameters (Hansen 2006 defaults) -----------------------
  n      <- length(params)
  lambda <- if (is.null(popsize)) max(8L, 4L + floor(3 * log(n))) else
              as.integer(popsize)
  mu     <- lambda %/% 2L

  raw_w  <- log(mu + 0.5) - log(seq_len(mu))   # log-decay
  w      <- raw_w / sum(raw_w)                   # normalised weights
  mueff  <- 1 / sum(w^2)                         # effective mu

  cc     <- (4 + mueff/n) / (n + 4 + 2*mueff/n)
  cs     <- (mueff + 2)   / (n + mueff + 5)
  c1     <- 2 / ((n + 1.3)^2 + mueff)
  cmu    <- min(1 - c1,
               2 * (mueff - 2 + 1/mueff) / ((n + 2)^2 + mueff))
  damps  <- 1 + 2*max(0, sqrt((mueff - 1)/(n + 1)) - 1) + cs
  chiN   <- sqrt(n) * (1 - 1/(4*n) + 1/(21*n^2))

  # Per-parameter log-scale clipping bounds
  prob_params <- c("grass_rate", "grass_init_prob", "transmission_prob",
                   "disease_death_prob", "crossover_rate")
  lo_log <- vapply(params, function(p) {
    if (p %in% prob_params) log(.Machine$double.eps) else
      log(specs_base[[p]]) - 5
  }, numeric(1L))
  hi_log <- vapply(params, function(p) {
    if (p %in% prob_params) log(1 - .Machine$double.eps) else
      log(specs_base[[p]]) + 5
  }, numeric(1L))

  # ---- State ----------------------------------------------------------------
  xmean     <- log(vapply(params, function(p) specs_base[[p]], numeric(1L)))
  sigma     <- sigma0
  pc        <- numeric(n)
  ps        <- numeric(n)
  B         <- diag(n)
  D         <- rep(1.0, n)
  C         <- diag(n)
  invsqrtC  <- diag(n)
  eigeneval <- 0L

  best_specs  <- specs_base
  best_score  <- -Inf
  total_evals <- 0L
  history     <- vector("list", n_iterations)

  build_specs <- function(log_x) {
    log_x <- pmax(lo_log, pmin(hi_log, log_x))
    s <- specs_base
    for (j in seq_len(n)) s[[params[j]]] <- exp(log_x[j])
    s
  }

  eval_one <- function(s) {
    env <- tryCatch(run_alife(s, verbose = FALSE), error = function(e) NULL)
    if (is.null(env)) return(-Inf)
    tryCatch(obj_fn(env), error = function(e) -Inf)
  }

  if (verbose)
    message(sprintf("CMA-ES: n=%d, lambda=%d, mu=%d, max_gen=%d",
                    n, lambda, mu, n_iterations))

  # 0.5.6: create a single PSOCK cluster for all generations. Each
  # worker boots its own Julia; the compile cost is paid once here
  # rather than per-generation. Cluster is torn down on function exit.
  .cma_cluster <- if (n_cores > 1L) {
    cl <- parallel::makeCluster(as.integer(n_cores))
    on.exit(try(parallel::stopCluster(cl), silent = TRUE), add = TRUE)
    parallel::clusterEvalQ(cl, suppressPackageStartupMessages(library(clade)))
    parallel::clusterExport(cl, c("eval_one"), envir = environment())
    cl
  } else NULL

  for (gen in seq_len(n_iterations)) {

    # ---- Sample lambda candidates -------------------------------------------
    Z <- matrix(rnorm(lambda * n), nrow = lambda, ncol = n)
    X <- t(xmean + sigma * (B %*% (D * t(Z))))     # lambda x n
    X <- pmax(matrix(lo_log, lambda, n, byrow = TRUE),
              pmin(matrix(hi_log, lambda, n, byrow = TRUE), X))

    # ---- Evaluate -----------------------------------------------------------
    cands       <- lapply(seq_len(lambda), function(k) build_specs(X[k, ]))
    total_evals <- total_evals + lambda

    # 0.5.6: switched from mclapply to a single PSOCK cluster reused
    # across generations. mclapply deadlocked because forked workers
    # share the parent's JuliaConnectoR socket; PSOCK spawns separate
    # R sessions each with their own Julia. The cluster is created
    # once (before the generation loop) so the per-worker Julia
    # compile cost is paid just once per search_cmaes() call.
    scores <- if (!is.null(.cma_cluster)) {
      unlist(parallel::parLapply(.cma_cluster, cands, eval_one))
    } else {
      vapply(cands, eval_one, numeric(1L))
    }
    scores[!is.finite(scores)] <- -Inf

    # ---- Select & recombine -------------------------------------------------
    ord  <- order(scores, decreasing = TRUE)
    Xsel <- X[ord[seq_len(mu)], , drop = FALSE]   # mu x n

    if (scores[ord[1L]] > best_score) {
      best_score <- scores[ord[1L]]
      best_specs <- cands[[ord[1L]]]
    }

    xold  <- xmean
    xmean <- colSums(w * Xsel)    # weighted mean

    # ---- Step-size control (cumulative path ps) -----------------------------
    ps <- (1 - cs) * ps +
          sqrt(cs * (2 - cs) * mueff) *
          (invsqrtC %*% (xmean - xold) / sigma)

    hsig <- as.numeric(
      sqrt(sum(ps^2)) /
        sqrt(1 - (1 - cs)^(2 * (gen + eigeneval))) / chiN < 1.4 + 2/(n + 1)
    )

    # ---- Rank-1 cumulation path pc ------------------------------------------
    pc <- (1 - cc) * pc +
          hsig * sqrt(cc * (2 - cc) * mueff) * (xmean - xold) / sigma

    # ---- Covariance update --------------------------------------------------
    artmp <- (Xsel - matrix(xold, mu, n, byrow = TRUE)) / sigma
    C <- (1 - c1 - cmu) * C +
         c1 * (tcrossprod(pc) + (1 - hsig) * cc * (2 - cc) * C) +
         cmu * crossprod(artmp * w)

    # ---- Step-size update ---------------------------------------------------
    sigma <- sigma * exp((cs / damps) * (sqrt(sum(ps^2)) / chiN - 1))
    sigma <- max(1e-10, sigma)

    # ---- Lazy eigendecomposition (every ~lambda/(c1+cmu)/n/10 gens) --------
    if (gen - eigeneval > lambda / (c1 + cmu) / n / 10) {
      eigeneval <- gen
      C    <- (C + t(C)) / 2          # symmetrise
      eig  <- eigen(C, symmetric = TRUE)
      D    <- sqrt(pmax(0, eig$values))
      B    <- eig$vectors
      invsqrtC <- B %*% diag(1 / (D + 1e-12)) %*% t(B)
    }

    fin_scores <- scores[is.finite(scores)]
    history[[gen]] <- data.frame(
      generation = gen,
      evals      = total_evals,
      best_score = best_score,
      mean_score = if (length(fin_scores)) mean(fin_scores) else NA_real_,
      sigma      = sigma
    )

    if (verbose && gen %% 10 == 0)
      message(sprintf("  gen %3d: best=%.4f  sigma=%.4f",
                      gen, best_score, sigma))
  }

  list(specs   = best_specs,
       score   = best_score,
       history = do.call(rbind, history))
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
#' @param n_cores Integer. Parallel cores for finite-difference evaluation
#'   (default 1L). Finite-difference gradient needs `length(params) + 1`
#'   evaluations per step, which are embarrassingly parallel. When `> 1`,
#'   runs them across a [parallel::makeCluster()] PSOCK cluster (each
#'   worker an R session + Julia). Cluster is created once per call and
#'   reused across steps. 0.5.6.
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
#'   efficient optimization. *Johns Hopkins APL Technical Digest* 19(4):482-492.
#' Innes, M. (2018) Don't unroll adjoint: differentiating SSA-form programs.
#'   arXiv:1810.07951. (Zygote.jl -- Phase 4b deferred.)
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

  obj_fn <- .make_obj_fn(objective)

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

  # 0.5.6: create a single PSOCK cluster for parallel finite-difference
  # evaluation. Each step needs length(params) + 1 run_alife() calls,
  # all independent. Cluster lives across all steps; Julia compile cost
  # paid once per worker. Cluster torn down on function exit.
  n_cores <- as.integer(n_cores)
  cl <- if (n_cores > 1L) {
    clu <- parallel::makeCluster(n_cores)
    on.exit(try(parallel::stopCluster(clu), silent = TRUE), add = TRUE)
    parallel::clusterEvalQ(clu, suppressPackageStartupMessages(library(clade)))
    parallel::clusterExport(clu,
                            c("build_specs", "obj_fn"),
                            envir = environment())
    clu
  } else NULL

  # Evaluate a list of log-vector candidates, parallel or serial.
  evaluate_many <- function(log_x_list) {
    if (is.null(cl)) {
      vapply(log_x_list, evaluate, numeric(1L))
    } else {
      unlist(parallel::parLapply(cl, log_x_list, function(lx) {
        s <- build_specs(lx)
        env <- tryCatch(suppressWarnings(run_alife(s, verbose = FALSE)),
                        error = function(e) NULL)
        if (is.null(env)) NA_real_ else obj_fn(env)
      }))
    }
  }

  for (step in seq_len(n_steps)) {
    # Build the batch: baseline + perturbation along each param.
    candidates <- c(list(log_x),
                    lapply(seq_along(params), function(j) {
                      lx <- log_x; lx[j] <- lx[j] + epsilon; lx
                    }))
    scores <- evaluate_many(candidates)
    score0       <- scores[1L]
    scores_plus  <- scores[-1L]

    if (is.finite(score0) && score0 > best_score) {
      best_score <- score0
      best_specs <- build_specs(log_x)
    }

    grad <- ifelse(is.finite(scores_plus) & is.finite(score0),
                   (scores_plus - score0) / epsilon, 0)

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
    "n_altruistic_acts", "n_shelters_built", "n_cooperation_acts",
    "n_dispersal_events", "n_habitat_moves",
    "n_predators", "n_prey_killed", "n_juveniles", "n_helpers",
    "n_toxic_attacks", "n_avoided_attacks",
    "mean_signal_magnitude", "mean_toxicity", "mean_plasticity",
    "mean_helper_tendency", "mean_habitat_preference", "mean_brain_size",
    # Tier 1: complex landscape
    "n_ground_agents", "n_shrub_agents", "n_canopy_agents",
    "mean_wing_size", "mean_shrub_coverage", "mean_canopy_coverage",
    # Tier 2a: spatial sorting
    "n_front_agents", "mean_front_dispersal", "mean_rear_dispersal",
    # Tier 2b: IFfolk
    "n_iffolk_transfers")
}

# ── search_random() ───────────────────────────────────────────────────────────

#' Stochastic parameter sweep for evolutionary outcome discovery
#'
#' Evaluates `n_samples` randomly drawn parameter configurations and returns
#' the results ranked by the chosen objective. Each sample is obtained by
#' independently perturbing each element of `search_params` (log-scale for
#' positive parameters, linear scale otherwise). This provides an inexpensive
#' exploration baseline comparable to a Latin Hypercube Sampling (LHS) sweep.
#'
#' Use `search_random()` to:
#' * Screen which parameters most strongly influence genetic diversity.
#' * Identify high-diversity corners of the parameter space before running
#'   the more expensive [search_map_elites()] or [search_cmaes()].
#' * Compare stochastic results to MAP-Elites elites to spot archive gaps.
#'
#' @param specs_base A specs list from [default_specs()].
#' @param search_params Named list of parameter ranges. Each element should be
#'   a numeric vector of length 2 (`c(min, max)`) for uniform sampling, or a
#'   numeric vector of length > 2 for discrete sampling. Example:
#'   ```r
#'   list(
#'     mutation_sd   = c(0.01, 0.5),
#'     grass_rate    = c(0.05, 0.8),
#'     n_agents_init = c(10L, 200L)
#'   )
#'   ```
#' @param n_samples Integer. Number of random configurations to evaluate
#'   (default `50L`).
#' @param objective Character or function. Column from `get_run_data()$ticks`
#'   to maximise (default `"genetic_diversity"`), or a function `f(env)`
#'   returning a numeric scalar.
#' @param verbose Logical. Print progress (default `TRUE`).
#'
#' @return A data frame with one row per sample, columns:
#' \describe{
#'   \item{`rank`}{Rank by descending objective score (1 = best).}
#'   \item{`score`}{Objective value for this sample.}
#'   \item{...}{One column per element of `search_params` showing the sampled
#'     value used.}
#' }
#' Attribute `"specs_list"` is a list of the full specs for each sample row,
#' accessible via `attr(result, "specs_list")`.
#'
#' @examples
#' \dontrun{
#' # Screen mutation_sd and grass_rate for highest genetic diversity
#' result <- search_random(
#'   specs_base    = default_specs(),
#'   search_params = list(
#'     mutation_sd   = c(0.01, 0.5),
#'     grass_rate    = c(0.05, 0.8),
#'     n_agents_init = c(10L, 150L)
#'   ),
#'   n_samples  = 30L,
#'   objective  = "genetic_diversity"
#' )
#' head(result)                          # top configurations
#' plot(result$grass_rate, result$score) # partial dependence
#' }
#'
#' @seealso [search_map_elites()], [search_cmaes()], [search_gradient()]
#' @importFrom stats runif
#' @export
search_random <- function(specs_base,
                           search_params,
                           n_samples  = 50L,
                           objective  = "genetic_diversity",
                           verbose    = TRUE) {
  stopifnot(is.list(specs_base), is.list(search_params), length(search_params) >= 1L)
  n_samples <- as.integer(n_samples)
  stopifnot(n_samples >= 1L)

  param_names <- names(search_params)
  if (is.null(param_names) || any(!nzchar(param_names)))
    stop("search_params must be a fully named list.", call. = FALSE)

  obj_fn <- .make_obj_fn(objective)

  # Storage
  scores     <- numeric(n_samples)
  sampled    <- vector("list", n_samples)
  specs_list <- vector("list", n_samples)

  for (i in seq_len(n_samples)) {
    s <- specs_base

    # Draw one random configuration
    drawn <- numeric(length(search_params))
    names(drawn) <- param_names
    for (p in param_names) {
      rng <- search_params[[p]]
      val <- if (length(rng) == 2L) {
        # Uniform in [min, max]
        runif(1L, min(rng), max(rng))
      } else {
        # Discrete: sample one element
        sample(rng, 1L)
      }
      # Preserve integer type when base param is integer
      if (is.integer(specs_base[[p]])) val <- as.integer(round(val))
      s[[p]] <- val
      drawn[p] <- val
    }
    sampled[[i]] <- drawn

    if (isTRUE(verbose))
      message(sprintf("[search_random] sample %d/%d", i, n_samples))

    env   <- tryCatch(run_alife(s, verbose = FALSE), error = function(e) NULL)
    score <- if (is.null(env)) NA_real_ else tryCatch(obj_fn(env), error = function(e) NA_real_)
    scores[i]     <- score
    specs_list[[i]] <- s
  }

  # Assemble result
  param_df <- as.data.frame(do.call(rbind, sampled))
  for (p in param_names) {
    if (is.integer(specs_base[[p]])) param_df[[p]] <- as.integer(param_df[[p]])
  }
  result <- cbind(data.frame(score = scores), param_df)
  result <- result[order(-result$score, na.last = TRUE), , drop = FALSE]
  result$rank <- seq_len(nrow(result))
  result <- result[, c("rank", "score", param_names), drop = FALSE]
  rownames(result) <- NULL
  attr(result, "specs_list") <- specs_list[order(-scores, na.last = TRUE)]
  result
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

# ── search_viability() ────────────────────────────────────────────────────────

#' Grid-search parameter viability: which combinations allow population survival?
#'
#' Runs a grid of parameter combinations and measures the fraction of replicates
#' in which the population survives to the end of the simulation. Returns both a
#' data frame and a ggplot2 heatmap so you can quickly identify the "viable
#' region" of parameter space before running CMA-ES or MAP-Elites inside it.
#'
#' This directly answers the question "which parameters allow organisms to
#' evolve?" without requiring CMA-ES to converge first.
#'
#' @param specs_base A specs list from [default_specs()].
#' @param param_x Character. Name of the first parameter to vary.
#' @param values_x Numeric vector of values to test for `param_x`.
#' @param param_y Character or `NULL`. Optional second parameter (creates a 2D
#'   grid when supplied).
#' @param values_y Numeric vector of values for `param_y`. Ignored if
#'   `param_y = NULL`.
#' @param n_reps Integer. Replicates per grid cell (different random seeds;
#'   default 3L).
#' @param survival_threshold Numeric. Fraction of initial agents that must
#'   survive for a run to count as viable (default 0.1).
#' @param objective Character or function or `NULL`. If supplied, the mean
#'   objective score across surviving replicates is added as column
#'   `mean_objective` (default `NULL`).
#' @param n_cores Integer. Parallel cores for cell evaluation (default 1L).
#'   Every `(param_x, param_y) × replicate` combination is independent, so
#'   the grid runs across a [parallel::makeCluster()] PSOCK cluster when
#'   `> 1`. Added 0.5.6.
#' @param verbose Logical (default `TRUE`).
#'
#' @return A list with:
#' \describe{
#'   \item{`$data`}{Data frame with columns `param_x`, optionally `param_y`,
#'     `viability` (fraction surviving), `mean_final_pop`, and optionally
#'     `mean_objective`.}
#'   \item{`$map`}{A ggplot2 tile/line plot coloured by viability.}
#' }
#'
#' @examples
#' \dontrun{
#' s <- default_specs()
#' s$complex_landscape <- TRUE
#' vm <- search_viability(
#'   s,
#'   param_x = "shrub_density",  values_x = seq(0.1, 0.5, 0.1),
#'   param_y = "canopy_density", values_y = seq(0.05, 0.3, 0.1),
#'   n_reps  = 3L
#' )
#' vm$map          # heatmap
#' vm$data         # raw viability fractions
#' }
#'
#' @seealso [search_cmaes()], [tune_complex_landscape()]
#' @export
search_viability <- function(specs_base,
                              param_x, values_x,
                              param_y = NULL, values_y = NULL,
                              n_reps = 3L,
                              survival_threshold = 0.1,
                              objective = NULL,
                              n_cores = 1L,
                              verbose = TRUE) {
  stopifnot(is.list(specs_base))
  stopifnot(is.character(param_x), length(param_x) == 1L)
  stopifnot(is.numeric(values_x), length(values_x) >= 1L)
  if (!is.null(param_y)) {
    stopifnot(is.character(param_y), length(param_y) == 1L)
    stopifnot(is.numeric(values_y), length(values_y) >= 1L)
  }
  n_reps <- as.integer(n_reps)
  stopifnot(n_reps >= 1L)

  if (is.null(specs_base[[param_x]]))
    stop(sprintf("specs_base does not contain parameter '%s'.", param_x),
         call. = FALSE)
  if (!is.null(param_y) && is.null(specs_base[[param_y]]))
    stop(sprintf("specs_base does not contain parameter '%s'.", param_y),
         call. = FALSE)

  obj_fn <- if (!is.null(objective)) .make_obj_fn(objective) else NULL

  # Build grid
  grid <- if (is.null(param_y)) {
    data.frame(vx = values_x, vy = NA_real_, stringsAsFactors = FALSE)
  } else {
    expand.grid(vx = values_x, vy = values_y, stringsAsFactors = FALSE)
  }

  .clade_start_julia(verbose = FALSE)

  # 0.5.6: build a flat list of (cell × replicate) specs, then evaluate
  # either serially or across a PSOCK cluster. Flattening lets us
  # parallelise across BOTH grid cells AND replicate seeds — every
  # combination is independent.
  flat_specs <- list()
  flat_meta  <- list()
  for (i in seq_len(nrow(grid))) {
    vx <- grid$vx[i]; vy <- grid$vy[i]
    for (r in seq_len(n_reps)) {
      s <- specs_base
      s[[param_x]] <- vx
      if (!is.null(param_y)) s[[param_y]] <- vy
      s$random_seed <- as.integer(r * 1000L + i)
      flat_specs[[length(flat_specs) + 1L]] <- s
      flat_meta[[length(flat_meta) + 1L]]   <- list(cell = i, rep = r,
                                                     vx = vx, vy = vy)
    }
  }

  n_cores <- as.integer(n_cores)
  if (verbose)
    message(sprintf("[search_viability] %d cells × %d reps = %d runs (%s)",
                    nrow(grid), n_reps, length(flat_specs),
                    if (n_cores > 1L) sprintf("%d PSOCK cores", n_cores)
                    else               "serial"))

  eval_one <- function(s) {
    env <- tryCatch(suppressWarnings(run_alife(s, verbose = FALSE)),
                    error = function(e) NULL)
    if (is.null(env)) return(list(n_fin = 0L, obj = NA_real_))
    out <- list(n_fin = length(env$agents),
                obj   = if (!is.null(obj_fn))
                          tryCatch(obj_fn(env), error = function(e) NA_real_)
                        else NA_real_)
    out
  }

  per_run <- if (n_cores > 1L) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(try(parallel::stopCluster(cl), silent = TRUE), add = TRUE)
    parallel::clusterEvalQ(cl, suppressPackageStartupMessages(library(clade)))
    parallel::clusterExport(cl, c("obj_fn"), envir = environment())
    parallel::parLapply(cl, flat_specs, eval_one)
  } else {
    lapply(flat_specs, eval_one)
  }

  # Reduce to per-cell rows
  results <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    cell_idx <- which(vapply(flat_meta, function(m) m$cell, integer(1L)) == i)
    cell_runs <- per_run[cell_idx]
    final_pop <- vapply(cell_runs, function(r) r$n_fin, integer(1L))
    n_init <- specs_base$n_agents_init
    survived <- sum(final_pop / n_init > survival_threshold)
    row <- list(
      param_x_val    = grid$vx[i],
      param_y_val    = if (is.null(param_y)) NA_real_ else grid$vy[i],
      viability      = survived / n_reps,
      mean_final_pop = mean(final_pop, na.rm = TRUE)
    )
    if (!is.null(obj_fn))
      row$mean_objective <- mean(vapply(cell_runs,
                                         function(r) r$obj, numeric(1L)),
                                  na.rm = TRUE)
    results[[i]] <- as.data.frame(row, stringsAsFactors = FALSE)
  }

  df <- do.call(rbind, results)
  names(df)[names(df) == "param_x_val"] <- param_x
  if (!is.null(param_y)) {
    names(df)[names(df) == "param_y_val"] <- param_y
  } else {
    df$param_y_val <- NULL
  }

  list(data = df, map = .viability_plot(df, param_x, param_y))
}

.viability_plot <- function(df, param_x, param_y) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(NULL)

  if (is.null(param_y)) {
    ggplot2::ggplot(df, ggplot2::aes(x = .data[[param_x]],
                                      y = .data$viability)) +
      ggplot2::geom_line(colour = "#2166ac", linewidth = 1) +
      ggplot2::geom_point(colour = "#2166ac", size = 2) +
      ggplot2::labs(x = param_x, y = "Viability (fraction surviving)",
                    title = "Parameter viability scan") +
      ggplot2::theme_minimal()
  } else {
    ggplot2::ggplot(df, ggplot2::aes(x = .data[[param_x]],
                                      y = .data[[param_y]],
                                      fill = .data$viability)) +
      ggplot2::geom_tile() +
      ggplot2::scale_fill_gradient2(low = "#d73027", mid = "#ffffbf",
                                     high = "#1a9850", midpoint = 0.5,
                                     limits = c(0, 1),
                                     name = "Viability") +
      ggplot2::labs(x = param_x, y = param_y,
                    title = "Parameter viability map") +
      ggplot2::theme_minimal()
  }
}

# ── Scenario-specific objective functions ─────────────────────────────────────

#' Objective function for the complex landscape scenario
#'
#' Measures how well the complex-landscape module is working by combining:
#' (1) wing size evolution (late mean - early mean), (2) niche diversity
#' entropy across ground/shrub/canopy layers, and (3) a log-survival bonus.
#' Returns `-Inf` for extinct populations or runs with fewer than 10 active
#' ticks, making it safe to pass directly to [search_cmaes()].
#'
#' @param env A `clade_env` object from [run_alife()].
#' @return A numeric scalar. Higher is better; `-Inf` = unviable.
#'
#' @examples
#' \dontrun{
#' s <- default_specs()
#' s$complex_landscape <- TRUE; s$max_ticks <- 100L
#' env <- run_alife(s, verbose = FALSE)
#' objective_complex_landscape(env)
#' }
#'
#' @seealso [tune_complex_landscape()], [search_cmaes()]
#' @importFrom utils head tail
#' @export
objective_complex_landscape <- function(env) {
  d      <- get_run_data(env)
  ticks  <- d$ticks
  active <- ticks[ticks$n_agents > 0, ]
  n      <- nrow(active)
  if (n < 10L || is.null(active$mean_wing_size)) return(-Inf)

  early <- mean(head(active$mean_wing_size, max(1L, n %/% 5L)), na.rm = TRUE)
  late  <- mean(tail(active$mean_wing_size, max(1L, n %/% 5L)), na.rm = TRUE)

  entropy <- 0.0
  cols <- c("n_ground_agents", "n_shrub_agents", "n_canopy_agents")
  if (all(cols %in% names(active))) {
    last20 <- tail(active, 20L)
    cnt <- as.matrix(last20[, cols])
    row_tot <- rowSums(cnt) + 1e-9
    p   <- sweep(cnt, 1L, row_tot, "/")
    entropy <- mean(-rowSums(ifelse(p > 0, p * log(p + 1e-9), 0)))
  }

  survival <- mean(active$n_agents, na.rm = TRUE) / env$specs$n_agents_init
  (late - early) + 0.5 * entropy + 0.2 * log1p(survival)
}

#' Objective function for the spatial sorting scenario
#'
#' Measures dispersal divergence between front and rear agents over the last
#' 20% of active ticks. Returns `-Inf` for extinct runs, `-1.0` when the front
#' represents fewer than 2% of the population (no meaningful invasion front).
#'
#' @param env A `clade_env` object from [run_alife()].
#' @return A numeric scalar. Higher is better; `-Inf` = unviable.
#'
#' @examples
#' \dontrun{
#' s <- default_specs()
#' s$dispersal_evolution <- TRUE; s$spatial_sorting <- TRUE
#' s$max_ticks <- 200L
#' env <- run_alife(s, verbose = FALSE)
#' objective_spatial_sorting(env)
#' }
#'
#' @seealso [tune_spatial_sorting()], [search_cmaes()]
#' @importFrom utils tail
#' @export
objective_spatial_sorting <- function(env) {
  d      <- get_run_data(env)
  ticks  <- d$ticks
  active <- ticks[ticks$n_agents > 0, ]
  n      <- nrow(active)
  if (n < 10L) return(-Inf)
  if (is.null(active$mean_front_dispersal)) return(-Inf)

  if (!is.null(active$n_front_agents)) {
    front_frac <- mean(active$n_front_agents /
                       (active$n_agents + 1e-9), na.rm = TRUE)
    if (front_frac < 0.02) return(-1.0)
  }

  last <- tail(active, max(1L, n %/% 5L))
  diff  <- mean(last$mean_front_dispersal - last$mean_rear_dispersal,
                na.rm = TRUE)
  front <- mean(last$mean_front_dispersal, na.rm = TRUE)
  diff + 0.2 * front
}

#' Objective function for the IFfolk inclusive fitness scenario
#'
#' Measures the linear upward trend in `mean_helper_tendency` (scaled x1000
#' so CMA-ES gradients are numerically comfortable), plus a per-agent IFfolk
#' transfer bonus. Returns `-Inf` for extinct runs or fewer than 20 active
#' ticks (insufficient signal for the regression).
#'
#' @param env A `clade_env` object from [run_alife()].
#' @return A numeric scalar. Higher is better; `-Inf` = unviable.
#'
#' @examples
#' \dontrun{
#' s <- default_specs()
#' s$iffolk_selection <- TRUE; s$cooperative_breeding <- TRUE
#' s$max_ticks <- 200L
#' env <- run_alife(s, verbose = FALSE)
#' objective_iffolk(env)
#' }
#'
#' @seealso [tune_iffolk()], [search_cmaes()]
#' @importFrom stats lm coef
#' @export
objective_iffolk <- function(env) {
  d      <- get_run_data(env)
  ticks  <- d$ticks
  active <- ticks[ticks$n_agents > 0, ]
  n      <- nrow(active)
  if (n < 20L) return(-Inf)
  if (is.null(active$mean_helper_tendency)) return(-Inf)

  tick_idx <- seq_len(n)
  fit      <- lm(active$mean_helper_tendency ~ tick_idx)
  slope    <- coef(fit)[2L]

  bonus <- 0.0
  if (!is.null(active$n_iffolk_transfers)) {
    per_agent <- mean(active$n_iffolk_transfers /
                      (active$n_agents + 1e-9), na.rm = TRUE)
    bonus <- 0.1 * per_agent
  }

  slope * 1000 + bonus
}

# ── Convenience tuning wrappers ───────────────────────────────────────────────

#' Tune parameters for the complex landscape module
#'
#' Pre-configures [search_cmaes()] or [search_map_elites()] with biologically
#' sensible parameters and the [objective_complex_landscape()] objective for
#' the complex landscape (forest) module. Call this instead of configuring
#' CMA-ES manually.
#'
#' @param specs_base A specs list from [default_specs()]. `complex_landscape`
#'   and `wing_size_init_mean` are set automatically.
#' @param n_iterations Integer. Number of CMA-ES generations or MAP-Elites
#'   iterations (default 100L).
#' @param method Character. `"cmaes"` (default) or `"map_elites"`.
#' @param ... Additional arguments passed to [search_cmaes()] or
#'   [search_map_elites()].
#'
#' @return The result of [search_cmaes()] or [search_map_elites()].
#'
#' @examples
#' \dontrun{
#' tuned <- tune_complex_landscape(default_specs(), n_iterations = 50L)
#' tuned$specs    # optimal parameter set
#' tuned$history  # score over generations
#' }
#'
#' @seealso [objective_complex_landscape()], [search_viability()]
#' @export
tune_complex_landscape <- function(specs_base = default_specs(),
                                    n_iterations = 100L,
                                    method = "cmaes",
                                    ...) {
  specs_base$complex_landscape   <- TRUE
  specs_base$wing_size_init_mean <- 0.1

  params <- c("shrub_density", "canopy_density", "shrub_energy",
              "canopy_energy", "shrub_growth_rate")

  if (identical(method, "map_elites")) {
    search_map_elites(specs_base,
      archive_dims    = list(mean_wing_size       = seq(0, 1, by = 0.1),
                             mean_shrub_coverage  = seq(0, 1, by = 0.1)),
      n_iterations    = n_iterations,
      objective       = objective_complex_landscape,
      mutation_params = params, ...)
  } else {
    search_cmaes(specs_base,
      objective    = objective_complex_landscape,
      params       = params,
      n_iterations = n_iterations, ...)
  }
}

#' Tune parameters for the spatial sorting module
#'
#' Pre-configures [search_cmaes()] or [search_map_elites()] with
#' [objective_spatial_sorting()] and the key dispersal/sorting parameters.
#'
#' @param specs_base A specs list from [default_specs()]. `dispersal_evolution`
#'   and `spatial_sorting` are set automatically.
#' @param n_iterations Integer (default 100L).
#' @param method Character. `"cmaes"` (default) or `"map_elites"`.
#' @param ... Additional arguments passed to the chosen search function.
#'
#' @return The result of [search_cmaes()] or [search_map_elites()].
#'
#' @examples
#' \dontrun{
#' tuned <- tune_spatial_sorting(default_specs(), n_iterations = 50L)
#' tuned$specs$sorting_mating_boost
#' }
#'
#' @seealso [objective_spatial_sorting()], [search_viability()]
#' @export
tune_spatial_sorting <- function(specs_base = default_specs(),
                                  n_iterations = 100L,
                                  method = "cmaes",
                                  ...) {
  specs_base$dispersal_evolution <- TRUE
  specs_base$spatial_sorting     <- TRUE

  params <- c("sorting_mating_boost", "sorting_front_threshold",
              "dispersal_init_mean", "dispersal_mutation_sd")

  if (identical(method, "map_elites")) {
    search_map_elites(specs_base,
      archive_dims    = list(mean_front_dispersal = seq(0, 1, by = 0.1),
                             mean_rear_dispersal  = seq(0, 1, by = 0.1)),
      n_iterations    = n_iterations,
      objective       = objective_spatial_sorting,
      mutation_params = params, ...)
  } else {
    search_cmaes(specs_base,
      objective    = objective_spatial_sorting,
      params       = params,
      n_iterations = n_iterations, ...)
  }
}

#' Tune parameters for the IFfolk inclusive fitness module
#'
#' Pre-configures [search_cmaes()] or [search_map_elites()] with
#' [objective_iffolk()] and the key IFfolk/parliament parameters.
#'
#' @param specs_base A specs list from [default_specs()]. `iffolk_selection`
#'   and `cooperative_breeding` are set automatically.
#' @param n_iterations Integer (default 100L).
#' @param method Character. `"cmaes"` (default) or `"map_elites"`.
#' @param ... Additional arguments passed to the chosen search function.
#'
#' @return The result of [search_cmaes()] or [search_map_elites()].
#'
#' @examples
#' \dontrun{
#' tuned <- tune_iffolk(default_specs(), n_iterations = 50L)
#' tuned$specs$iffolk_transfer
#' }
#'
#' @seealso [objective_iffolk()], [search_viability()]
#' @export
tune_iffolk <- function(specs_base = default_specs(),
                         n_iterations = 100L,
                         method = "cmaes",
                         ...) {
  specs_base$iffolk_selection    <- TRUE
  specs_base$cooperative_breeding <- TRUE

  params <- c("iffolk_transfer", "iffolk_min_energy",
              "parliament_cost", "iffolk_radius")

  if (identical(method, "map_elites")) {
    search_map_elites(specs_base,
      archive_dims    = list(mean_helper_tendency  = seq(0, 1, by = 0.1),
                             n_iffolk_transfers    = seq(0, 100, by = 10)),
      n_iterations    = n_iterations,
      objective       = objective_iffolk,
      mutation_params = params, ...)
  } else {
    search_cmaes(specs_base,
      objective    = objective_iffolk,
      params       = params,
      n_iterations = n_iterations, ...)
  }
}
