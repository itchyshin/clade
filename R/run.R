#' Run an evolutionary simulation
#'
#' `run_alife()` is the primary entry point for clade. It sends `specs` to
#' Julia once, runs all `specs$max_ticks` ticks entirely in Julia, and returns
#' an environment list containing the final agent population and all logged
#' statistics. The Julia session is started automatically on the first call.
#'
#' The R-Julia boundary is crossed **once per call** regardless of simulation
#' length or agent count. This contrasts with Rcpp-based simulators (including
#' alifeR) where data is marshalled across the R-C++ boundary on every tick.
#'
#' @param specs A named list of simulation parameters, typically from
#'   [default_specs()] with modifications. All parameters are documented in
#'   [default_specs()].
#' @param verbose Logical. Print progress messages (default `TRUE`). Pass
#'   `FALSE` for batch runs or testing.
#'
#' @return An `env` list with components:
#' \describe{
#'   \item{`$agents`}{A list of agent lists, one per surviving agent.}
#'   \item{`$t`}{Final tick number (equals `specs$max_ticks`).}
#'   \item{`$specs`}{The specs list used for this run (may differ from input
#'     if `world_evolution = TRUE`).}
#'   \item{`$progress`}{A data frame of per-tick logged statistics (same as
#'     `get_run_data(env)$ticks`).}
#'   \item{`$deaths`}{A data frame of per-death records (same as
#'     `get_run_data(env)$deaths`).}
#'   \item{`$genome_log`}{A list of per-tick genome matrices (non-NULL only
#'     when `specs$log_genomes = TRUE`).}
#' }
#'
#' @examples
#' \dontrun{
#' specs <- default_specs()
#' env   <- run_alife(specs)
#' data  <- get_run_data(env)
#' plot_run(data)
#'
#' # Diploid run
#' specs$ploidy <- 2L
#' env2 <- run_alife(specs)
#'
#' # BNN with epigenetics
#' specs$brain_type  <- "bnn"
#' specs$epigenetics <- TRUE
#' env3 <- run_alife(specs)
#' }
#'
#' @seealso [default_specs()], [get_run_data()], [batch_alife()],
#'   [search_map_elites()]
#' @export
run_alife <- function(specs = default_specs(), verbose = TRUE) {
  .clade_start_julia(verbose = verbose)
  .validate_specs(specs)

  if (verbose) {
    message(sprintf(
      "clade: %d agents, %d ticks, brain=%s, ploidy=%d",
      specs$n_agents_init, specs$max_ticks, specs$brain_type, specs$ploidy
    ))
  }

  # Serialise specs to Julia and run the simulation
  env_julia <- JuliaConnectoR::juliaCall(
    "Clade.run_clade",
    .specs_to_julia(specs)
  )

  # Convert the Julia result back to an R list
  env <- .julia_env_to_r(env_julia, specs)

  # 0.5.6: attach a viability report and warn on crashed runs. Trait-mean
  # audits on crashed runs are unreliable (dominated by tiny surviving
  # populations). Silent on "weak" verdicts — that's common enough that a
  # warning every time would be noise.
  env$viability <- tryCatch({
    ticks <- as.data.frame(lapply(env$progress, unlist))
    viability_report(ticks, n_agents_init = specs$n_agents_init)
  }, error = function(e) NULL)

  if (!is.null(env$viability) && env$viability$verdict == "crashed") {
    warning(
      "run_alife(): population crashed — ",
      env$viability$message,
      ". Trait-mean interpretations on this run are unreliable. ",
      "Suppress with suppressWarnings() if you expected this (e.g. in a ",
      "deliberate viability stress test).",
      call. = FALSE
    )
  }

  env
}

#' Synonym for run_alife()
#'
#' `run_clade()` is an alias for [run_alife()], provided for consistency with
#' the package name.
#'
#' @inheritParams run_alife
#' @export
run_clade <- run_alife

#' Run multiple simulations in parallel
#'
#' `batch_alife()` runs a list of specs across R worker processes. At
#' `n_cores = 1L` (default), runs are serial via [lapply()]. At
#' `n_cores > 1L`, runs are distributed across a
#' [parallel::makeCluster()] PSOCK cluster — each worker is a
#' separate R process with its own Julia session.
#'
#' The PSOCK approach (0.5.6 default) replaces an earlier
#' [parallel::mclapply()] path that silently deadlocked: forked R
#' workers shared the parent's JuliaConnectoR socket and all blocked
#' on the same Julia server. See `dev/docs/parallelism-audit.md`.
#'
#' @param specs_list A list of specs lists. Each element is passed to
#'   [run_alife()] independently.
#' @param n_cores Integer. Number of R worker processes to use (default 1L).
#'   Each worker pays a ~60 s Julia compile cost on its first run; for
#'   batches smaller than ~20 scenarios, serial may be faster. For 50+
#'   scenarios, the speedup is near-linear in `n_cores` (capped by
#'   available cores; see CLAUDE.md for this machine's 200-core cap).
#' @param verbose Logical. Print progress (default `FALSE` for batch mode).
#'
#' @return A list of `env` objects, one per element of `specs_list`, in the
#'   same order.
#'
#' @examples
#' \dontrun{
#' specs_list <- lapply(c(0.05, 0.1, 0.2), function(gr) {
#'   s <- default_specs()
#'   s$grass_rate <- gr
#'   s
#' })
#' results <- batch_alife(specs_list, n_cores = 3L)
#' }
#'
#' @seealso [run_alife()], [get_run_data()]
#' @export
batch_alife <- function(specs_list, n_cores = 1L, verbose = FALSE) {
  stopifnot(is.list(specs_list), length(specs_list) >= 1L)
  n_cores <- as.integer(n_cores)

  run_one <- function(specs) run_alife(specs, verbose = verbose)

  if (n_cores <= 1L) {
    return(lapply(specs_list, run_one))
  }

  # 0.5.6: switched from `parallel::mclapply` to
  # `parallel::makeCluster("PSOCK")` because mclapply forks the R
  # session, and forked workers all share the same JuliaConnectoR
  # socket — concurrent requests deadlock the Julia server. PSOCK
  # spawns separate R processes, each with its own Julia, so runs
  # parallelise cleanly.
  #
  # Trade-off: each worker pays a ~60 s Julia compile cost on first
  # run_alife() call. For batches < 20 scenarios this makes parallel
  # slower than serial; for 50+ scenarios the speedup is near-linear.
  cl <- parallel::makeCluster(n_cores)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  # Make `clade` available on every worker. The package must be
  # installed on the worker's lib path; during dev, call
  # devtools::load_all() in the parent before batch_alife() and the
  # workers will also find it through .libPaths().
  parallel::clusterEvalQ(cl, {
    suppressPackageStartupMessages(library(clade))
  })
  parallel::parLapply(cl, specs_list, run_one)
}

#' Run one specs object with multiple random seeds
#'
#' `batch_seeds()` is a convenience wrapper around [batch_alife()] for
#' the common case of replicating a single simulation across several random
#' seeds. Each replicate is identical except for its `random_seed`.
#'
#' @param specs A specs list from [default_specs()] (or [quick_specs()] /
#'   [full_specs()]) with your modifications. The `random_seed` field is
#'   overwritten for each replicate.
#' @param seeds Integer vector of seeds to use (default `1:5`).
#' @param n_cores Integer. Number of parallel R workers (default `1L`).
#'   Passed to [batch_alife()].
#' @param verbose Logical. Print progress (default `FALSE`).
#'
#' @return A named list of `env` objects, one per seed, named
#'   `"seed_1"`, `"seed_2"`, etc.
#'
#' @examples
#' \dontrun{
#' s <- default_specs()
#' s$max_ticks <- 300L
#' results <- batch_seeds(s, seeds = 1:3)
#' lapply(results, function(e) tail(get_run_data(e)$ticks$mean_energy, 1))
#' }
#'
#' @seealso [batch_alife()], [default_specs()], [quick_specs()]
#' @export
batch_seeds <- function(specs, seeds = 1:5, n_cores = 1L, verbose = FALSE) {
  stopifnot(is.list(specs), length(seeds) >= 1L)
  seeds <- as.integer(seeds)
  specs_list <- lapply(seeds, function(s) {
    sp <- specs
    sp$random_seed <- s
    sp
  })
  names(specs_list) <- paste0("seed_", seeds)
  results <- batch_alife(specs_list, n_cores = n_cores, verbose = verbose)
  names(results) <- paste0("seed_", seeds)
  results
}

#' Generate a factorial grid of specs
#'
#' Produces a `list` of specs objects, one per combination of the supplied
#' parameter values. Every other field is inherited from `base`. Useful for
#' systematic parameter-space exploration with [batch_alife()].
#'
#' @param base A specs list (from [default_specs()], [fast_specs()], etc.)
#'   to use as the template for each combination.
#' @param ... Named vectors / lists of candidate values for each parameter.
#'   For example, `grass_rate = c(0.1, 0.2, 0.3), mutation_sd = c(0.02, 0.05)`
#'   generates a 3 × 2 = 6-cell grid. String-typed parameters can also be
#'   passed (e.g. `life_history = c("iteroparous", "semelparous")`).
#' @param seed_from Integer or `NULL`. If provided, overrides each cell's
#'   `random_seed` with `seed_from + 0L, seed_from + 1L, ...` so a grid run
#'   is reproducible. Default `1L`.
#'
#' @return A named list of specs. Names encode the parameter values, e.g.
#'   `"grass_rate=0.1;mutation_sd=0.02"`.
#'
#' @examples
#' \dontrun{
#' base <- fast_specs()
#' specs_list <- grid_specs(base,
#'                          grass_rate   = c(0.1, 0.2, 0.3),
#'                          mutation_sd  = c(0.02, 0.05))
#' results <- batch_alife(specs_list, n_cores = 6L)
#' }
#'
#' @seealso [batch_alife()], [sample_specs()], [summarize_batch()]
#' @export
grid_specs <- function(base, ..., seed_from = 1L) {
  stopifnot(is.list(base))
  params <- list(...)
  if (length(params) == 0L)
    stop("grid_specs() requires at least one named parameter", call. = FALSE)
  nms <- names(params)
  if (is.null(nms) || any(nms == ""))
    stop("all parameter arguments to grid_specs() must be named", call. = FALSE)

  grid <- do.call(expand.grid,
                  c(params, list(KEEP.OUT.ATTRS = FALSE,
                                  stringsAsFactors = FALSE)))
  out <- vector("list", nrow(grid))
  cell_names <- character(nrow(grid))

  for (i in seq_len(nrow(grid))) {
    s <- base
    pair_strs <- character(length(nms))
    for (j in seq_along(nms)) {
      s[[nms[j]]]   <- grid[i, nms[j]]
      pair_strs[j]  <- paste0(nms[j], "=", grid[i, nms[j]])
    }
    if (!is.null(seed_from))
      s$random_seed <- as.integer(seed_from) + as.integer(i) - 1L
    cell_names[i] <- paste(pair_strs, collapse = ";")
    out[[i]]      <- s
  }

  names(out) <- cell_names
  out
}

#' Sample specs randomly from parameter distributions
#'
#' Draws `n` specs from a set of univariate distributions. Each distribution
#' is either a numeric vector (sampled with replacement), a function of one
#' argument `n` that returns `n` values, or a two-element list
#' `list(runif_min, runif_max)` for uniform random draws.
#'
#' @param base A specs list template (see [grid_specs()]).
#' @param n Integer. Number of specs to draw.
#' @param ... Named distributions. See Details.
#' @param seed Integer. Seed for the R-side sampler so the draw is
#'   reproducible. Default `1L`.
#' @param seed_from Integer or `NULL`. Base for each drawn spec's
#'   `random_seed`. Default `1L`.
#'
#' @details
#' Three ways to specify a distribution for each parameter:
#'
#' - **Vector**: `grass_rate = c(0.05, 0.1, 0.2, 0.3, 0.5)` — draws from
#'   the vector with replacement.
#' - **Range (list of 2)**: `mutation_sd = list(0.01, 0.1)` — uniform
#'   draw from \[0.01, 0.1\]. Useful when the parameter is continuous.
#' - **Function**: `plasticity_init_mean = function(n) rbeta(n, 2, 2)` —
#'   any function that takes `n` and returns `n` values.
#'
#' @return A named list of specs. Names are `"sample_1"`, `"sample_2"`, …
#'
#' @examples
#' \dontrun{
#' base <- fast_specs()
#' specs_list <- sample_specs(base, n = 500L,
#'                            grass_rate   = list(0.05, 0.40),
#'                            mutation_sd  = c(0.02, 0.05, 0.1),
#'                            plasticity_init_mean = function(n) rbeta(n, 2, 2))
#' results <- batch_alife(specs_list, n_cores = 50L)
#' summary_tbl <- summarize_batch(results, specs_list)
#' }
#'
#' @seealso [batch_alife()], [grid_specs()], [summarize_batch()]
#' @export
sample_specs <- function(base, n, ..., seed = 1L, seed_from = 1L) {
  stopifnot(is.list(base), is.numeric(n), n >= 1L)
  n <- as.integer(n)
  dists <- list(...)
  nms   <- names(dists)
  if (is.null(nms) || any(nms == ""))
    stop("all arguments to sample_specs() must be named", call. = FALSE)

  set.seed(as.integer(seed))
  drawn <- lapply(dists, function(d) {
    if (is.function(d))                 return(d(n))
    if (is.list(d) && length(d) == 2L)  return(runif(n, min = d[[1L]], max = d[[2L]]))
    if (is.atomic(d))                   return(sample(d, size = n, replace = TRUE))
    stop("unsupported distribution spec: ", deparse(d), call. = FALSE)
  })

  out <- vector("list", n)
  for (i in seq_len(n)) {
    s <- base
    for (j in seq_along(nms)) s[[nms[j]]] <- drawn[[j]][i]
    if (!is.null(seed_from))
      s$random_seed <- as.integer(seed_from) + as.integer(i) - 1L
    out[[i]] <- s
  }
  names(out) <- paste0("sample_", seq_len(n))
  out
}

#' Summarize a batch of run results into a tidy data frame
#'
#' Pulls the parameter values from each spec and summary stats from the
#' corresponding run result into a single row, returning a data frame
#' suitable for plotting or filtering. Intended as the lightweight
#' companion to [batch_alife()] for parameter-space exploration.
#'
#' @param results A list of `env` objects from [batch_alife()].
#' @param specs_list The list of specs passed to `batch_alife()`, so the
#'   parameter values can be recovered. Must have the same length as
#'   `results`.
#' @param param_names Character vector of spec field names to extract.
#'   If `NULL` (default), infers them from the first spec by taking
#'   every field that differs from [default_specs()].
#' @param metrics Named list of functions. Each function takes a single
#'   `env` and returns a scalar numeric. Default metrics: final population
#'   size, final mean energy, final genetic diversity, viability verdict.
#'
#' @return A data frame with one row per run. Columns: the named
#'   parameters, each metric, and `viability` (the verdict string).
#'
#' @examples
#' \dontrun{
#' specs_list <- sample_specs(fast_specs(), n = 100L,
#'                            grass_rate = list(0.05, 0.4))
#' results <- batch_alife(specs_list, n_cores = 10L)
#' tbl <- summarize_batch(results, specs_list,
#'                        param_names = "grass_rate")
#' plot(tbl$grass_rate, tbl$n_final)
#' }
#'
#' @seealso [batch_alife()], [grid_specs()], [sample_specs()],
#'   [viability_report()]
#' @export
summarize_batch <- function(results, specs_list,
                            param_names = NULL, metrics = NULL) {
  stopifnot(is.list(results), is.list(specs_list),
            length(results) == length(specs_list))

  if (is.null(metrics)) {
    metrics <- list(
      n_final           = function(env) tail(env$progress$n_agents,          1L),
      mean_energy_final = function(env) tail(env$progress$mean_energy,       1L),
      diversity_final   = function(env) tail(env$progress$genetic_diversity, 1L)
    )
  }

  if (is.null(param_names)) {
    def <- default_specs()
    first <- specs_list[[1L]]
    candidates <- intersect(names(first), names(def))
    param_names <- candidates[vapply(candidates, function(nm) {
      v <- first[[nm]]
      d <- def[[nm]]
      is.atomic(v) && length(v) == 1L &&
        !isTRUE(all.equal(v, d, check.attributes = FALSE))
    }, logical(1L))]
  }

  row <- function(i) {
    s   <- specs_list[[i]]
    env <- results[[i]]
    p   <- setNames(lapply(param_names, function(nm) s[[nm]]), param_names)
    m   <- setNames(lapply(metrics, function(f) {
      out <- tryCatch(f(env), error = function(e) NA_real_)
      if (length(out) != 1L) NA_real_ else as.numeric(out)
    }), names(metrics))
    viab <- if (!is.null(env$viability)) env$viability$verdict else NA_character_
    as.data.frame(c(p, m, list(viability = viab)),
                  stringsAsFactors = FALSE)
  }

  do.call(rbind, lapply(seq_along(results), row))
}

#' Stream a parameter-space sweep to disk, one row per run
#'
#' The counterpart to [batch_alife()] + [summarize_batch()] for long
#' sweeps: runs each spec in `specs_list`, extracts a scalar summary
#' per run via `summary_fn`, and appends one CSV row to `out_path` as
#' each run completes. Two advantages over batching:
#'
#' - **Memory**: the full `env` object for each run is discarded after
#'   the summary row is written, so a 1 M-run sweep doesn't accumulate
#'   1 M copies of `progress` / `deaths` in RAM.
#' - **Resumability**: if the job dies at run 800 000 of 1 000 000,
#'   re-running with the same `out_path` picks up after the last
#'   written row (matched by the `run_id` column).
#'
#' @param specs_list List of specs.
#' @param out_path   Path to the CSV. Created if absent; appended if
#'   present. First row is always a header.
#' @param summary_fn Function `(env, specs) -> named list or one-row
#'   data.frame`. Should return the summary stats you want to save
#'   per run. Default: viability verdict + n_final + mean_energy_final
#'   + genetic_diversity_final + the run's random_seed and any params
#'   that differ from [default_specs()].
#' @param n_cores    Integer. Parallel workers, as in [batch_alife()].
#' @param resume     Logical. If `TRUE` (default) and `out_path`
#'   already exists, skip runs whose `run_id` is in the existing CSV.
#'   Set `FALSE` to overwrite.
#' @param flush_every Integer. How often to flush the CSV to disk
#'   (in rows). Default 1 (flush every row — safest; small I/O cost).
#'
#' @return The path to the CSV (invisibly). Read back with
#'   `read.csv(out_path)`.
#'
#' @examples
#' \dontrun{
#' specs_list <- sample_specs(fast_specs(), n = 10000L,
#'   grass_rate  = list(0.05, 0.40),
#'   mutation_sd = c(0.02, 0.05, 0.10))
#' stream_specs_to_csv(specs_list, "/tmp/sweep.csv", n_cores = 50L)
#' tbl <- read.csv("/tmp/sweep.csv")   # even if 10k × 50 B = 500 KB
#' }
#'
#' @seealso [batch_alife()], [sample_specs()], [summarize_batch()]
#' @export
stream_specs_to_csv <- function(specs_list, out_path,
                                summary_fn  = NULL,
                                n_cores     = 1L,
                                resume      = TRUE,
                                flush_every = 1L) {
  stopifnot(is.list(specs_list), length(specs_list) >= 1L,
            is.character(out_path), length(out_path) == 1L)
  n_cores <- as.integer(n_cores)

  # Default summary: the parameter fields that differ from default_specs
  # plus a small set of run-level metrics. Users override for anything
  # richer.
  if (is.null(summary_fn)) {
    def <- default_specs()
    summary_fn <- function(env, specs) {
      diff_nms <- intersect(names(specs), names(def))
      diff_nms <- diff_nms[vapply(diff_nms, function(nm) {
        v <- specs[[nm]]; d <- def[[nm]]
        is.atomic(v) && length(v) == 1L &&
          !isTRUE(all.equal(v, d, check.attributes = FALSE))
      }, logical(1L))]
      params <- setNames(lapply(diff_nms, function(nm) specs[[nm]]),
                         diff_nms)
      metrics <- list(
        n_final           = tail(env$progress$n_agents,          1L),
        mean_energy_final = tail(env$progress$mean_energy,       1L),
        diversity_final   = tail(env$progress$genetic_diversity, 1L),
        viability         = if (!is.null(env$viability))
                              env$viability$verdict else NA_character_
      )
      c(params, metrics)
    }
  }

  # Assign run_ids — used for resumability
  run_ids <- if (!is.null(names(specs_list))) names(specs_list)
             else sprintf("run_%06d", seq_along(specs_list))

  # Resume: figure out which run_ids already have rows
  existing <- character(0L)
  if (resume && file.exists(out_path)) {
    existing_tbl <- tryCatch(utils::read.csv(out_path, stringsAsFactors = FALSE),
                             error = function(e) NULL)
    if (!is.null(existing_tbl) && "run_id" %in% names(existing_tbl))
      existing <- as.character(existing_tbl$run_id)
  }
  todo <- which(!run_ids %in% existing)
  if (length(todo) == 0L) {
    message(sprintf("All %d runs already in %s — nothing to do.",
                    length(specs_list), out_path))
    return(invisible(out_path))
  }
  message(sprintf("Streaming %d runs (%d already in %s, %d todo)...",
                  length(specs_list), length(existing), out_path,
                  length(todo)))

  specs_sub   <- specs_list[todo]
  run_ids_sub <- run_ids[todo]

  # Run one spec and return a one-row data frame with run_id
  run_one_row <- function(i) {
    id    <- run_ids_sub[i]
    specs <- specs_sub[[i]]
    env   <- tryCatch(suppressWarnings(run_alife(specs, verbose = FALSE)),
                      error = function(e) NULL)
    if (is.null(env)) {
      as.data.frame(list(run_id = id,
                         error_msg = "run_alife failed",
                         stringsAsFactors = FALSE))
    } else {
      row <- tryCatch(summary_fn(env, specs),
                      error = function(e) list(error_msg = conditionMessage(e)))
      as.data.frame(c(list(run_id = id), row), stringsAsFactors = FALSE)
    }
  }

  # Open CSV for append-write. Write header only if file is empty/new.
  header_needed <- !file.exists(out_path) ||
                   file.info(out_path)$size == 0L

  # Buffer rows in memory, flush every `flush_every` rows. flush_every = 1
  # is the safest — if the job dies, you lose at most one row.
  buffer <- list()
  flush_buffer <- function() {
    if (length(buffer) == 0L) return(invisible(NULL))
    df <- do.call(rbind, lapply(buffer, as.data.frame, stringsAsFactors = FALSE))
    write_header <- header_needed && !file.exists(out_path)
    utils::write.table(df, file = out_path, append = !write_header,
                       sep = ",", row.names = FALSE,
                       col.names = write_header || (header_needed && !nzchar(readLines(out_path, n = 1L))),
                       quote = TRUE)
    if (write_header) header_needed <<- FALSE
    buffer <<- list()
  }

  if (n_cores <= 1L) {
    # Serial: stream as we go
    for (i in seq_along(specs_sub)) {
      row <- run_one_row(i)
      buffer[[length(buffer) + 1L]] <- row
      if (length(buffer) >= flush_every) flush_buffer()
    }
    flush_buffer()
  } else {
    # Parallel: batches of size n_cores, flush after each batch
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterEvalQ(cl, {
      suppressPackageStartupMessages(library(clade))
    })
    # Share the worker fn + data via clusterExport
    parallel::clusterExport(cl,
                            c("run_ids_sub", "specs_sub", "summary_fn"),
                            envir = environment())
    idxs <- seq_along(specs_sub)
    batch_size <- n_cores * max(1L, as.integer(flush_every))
    batches <- split(idxs, ceiling(seq_along(idxs) / batch_size))
    for (b in batches) {
      rows <- parallel::parLapply(cl, b, function(i) {
        id    <- run_ids_sub[i]
        specs <- specs_sub[[i]]
        env   <- tryCatch(suppressWarnings(run_alife(specs, verbose = FALSE)),
                          error = function(e) NULL)
        if (is.null(env))
          as.data.frame(list(run_id = id, error_msg = "run_alife failed"),
                        stringsAsFactors = FALSE)
        else
          as.data.frame(c(list(run_id = id),
                          tryCatch(summary_fn(env, specs),
                                    error = function(e)
                                      list(error_msg = conditionMessage(e)))),
                        stringsAsFactors = FALSE)
      })
      buffer <- c(buffer, rows)
      flush_buffer()
    }
  }

  invisible(out_path)
}

#' Generate a SLURM array-job template for a parameter-space sweep
#'
#' Writes two files that together let you fan a clade sweep across a
#' SLURM cluster: an `.rds` with the full specs_list, and a shell
#' script that calls `Rscript -e 'clade::stream_specs_to_csv(...)'`
#' for a subset of specs per array task. You run the sweep yourself
#' with `sbatch <script>.sh` — this function does not talk to SLURM.
#'
#' Per-task behaviour: reads `SLURM_ARRAY_TASK_ID` from the
#' environment, selects the corresponding slice of the specs_list,
#' and appends summary rows to the shared `out_path` CSV. Because
#' [stream_specs_to_csv()] is resume-safe, re-running any array task
#' is idempotent — useful if some jobs get preempted.
#'
#' @param specs_list List of specs (e.g. from [sample_specs()]).
#' @param out_path Character. Path on the cluster filesystem where
#'   the CSV will be appended to. Must be reachable from every node.
#' @param script_path Character. Local path where the `.sh` file is
#'   written.
#' @param rds_path Character. Local path where the `.rds` of
#'   `specs_list` is written. Cluster nodes need to be able to read
#'   this path; for a shared filesystem just put it somewhere the
#'   cluster can see.
#' @param n_array_tasks Integer. Number of SLURM array tasks. Each
#'   gets `ceiling(length(specs_list) / n_array_tasks)` specs.
#'   Default: `min(100, length(specs_list))`.
#' @param n_cores_per_task Integer. `n_cores` passed to
#'   [stream_specs_to_csv()] within each array task. Default 4L.
#' @param time Character. SLURM `--time` value (e.g. `"06:00:00"`).
#' @param mem Character. SLURM `--mem` value (e.g. `"8G"`).
#' @param summary_fn Optional summary function, same as
#'   [stream_specs_to_csv()]. If `NULL` (default), the default
#'   summary is used on the cluster side.
#' @param R_library_path Optional character. Added to `.libPaths()`
#'   on the cluster node via `.libPaths(c("<path>", .libPaths()))`
#'   before `library(clade)`. Useful when clade is installed in a
#'   non-standard location on the cluster.
#' @param extra_sbatch_lines Character vector of extra `#SBATCH`
#'   directives (without the leading `#SBATCH`) to include in the
#'   script preamble.
#'
#' @return The path to the generated shell script (invisibly), with
#'   a message showing the `sbatch` command to invoke.
#'
#' @examples
#' \dontrun{
#' specs_list <- sample_specs(fast_specs(), n = 100000L,
#'                            grass_rate  = list(0.05, 0.45),
#'                            mutation_sd = c(0.05, 0.1, 0.2))
#' submit_sweep_slurm(
#'   specs_list,
#'   out_path     = "/shared/sweeps/big_sweep.csv",
#'   script_path  = "/shared/sweeps/submit.sh",
#'   rds_path     = "/shared/sweeps/specs.rds",
#'   n_array_tasks = 200L,
#'   n_cores_per_task = 8L,
#'   time         = "12:00:00",
#'   mem          = "16G")
#' # then: sbatch /shared/sweeps/submit.sh
#' }
#'
#' @seealso [stream_specs_to_csv()], [sample_specs()]
#' @export
submit_sweep_slurm <- function(specs_list,
                               out_path,
                               script_path,
                               rds_path,
                               n_array_tasks    = min(100L, length(specs_list)),
                               n_cores_per_task = 4L,
                               time             = "06:00:00",
                               mem              = "8G",
                               summary_fn       = NULL,
                               R_library_path   = NULL,
                               extra_sbatch_lines = character(0)) {
  stopifnot(is.list(specs_list), length(specs_list) >= 1L,
            is.character(out_path),    length(out_path)    == 1L,
            is.character(script_path), length(script_path) == 1L,
            is.character(rds_path),    length(rds_path)    == 1L)
  n_array_tasks    <- as.integer(n_array_tasks)
  n_cores_per_task <- as.integer(n_cores_per_task)

  # Ensure names
  if (is.null(names(specs_list)))
    names(specs_list) <- sprintf("run_%06d", seq_along(specs_list))

  # Save the specs + summary function (if any) as RDS. All array
  # tasks read from this file.
  saveRDS(list(specs_list = specs_list, summary_fn = summary_fn),
          file = rds_path)

  N <- length(specs_list)
  chunk_size <- as.integer(ceiling(N / n_array_tasks))

  libpaths_line <- if (!is.null(R_library_path))
    sprintf('.libPaths(c("%s", .libPaths()))', R_library_path)
  else ""

  sbatch_extras <- if (length(extra_sbatch_lines) > 0L)
    paste0("#SBATCH ", extra_sbatch_lines, collapse = "\n")
  else ""

  # The per-task R script body. Uses SLURM_ARRAY_TASK_ID to pick the
  # slice of specs_list; calls stream_specs_to_csv with resume = TRUE.
  r_body <- sprintf('
%s
suppressPackageStartupMessages(library(clade))

task <- as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))
if (is.na(task) || task < 1L)
  stop("SLURM_ARRAY_TASK_ID not set. Run with sbatch --array=...")

payload <- readRDS("%s")
specs_list <- payload$specs_list
summary_fn <- payload$summary_fn

N          <- length(specs_list)
chunk_size <- %dL
lo <- (task - 1L) * chunk_size + 1L
hi <- min(N, task * chunk_size)
if (lo > N) {
  message(sprintf("Task %%d out of range (N=%%d), nothing to do", task, N))
  quit(save = "no", status = 0L)
}

message(sprintf("Task %%d: specs %%d..%%d (%%d specs)", task, lo, hi, hi - lo + 1L))
slice <- specs_list[lo:hi]

stream_specs_to_csv(slice,
                    out_path   = "%s",
                    summary_fn = summary_fn,
                    n_cores    = %dL,
                    resume     = TRUE)
', libpaths_line, rds_path, chunk_size, out_path, n_cores_per_task)

  sh <- sprintf('#!/bin/bash
#SBATCH --job-name=clade-sweep
#SBATCH --array=1-%d
#SBATCH --cpus-per-task=%d
#SBATCH --time=%s
#SBATCH --mem=%s
#SBATCH --output=clade-sweep_%%A_%%a.out
#SBATCH --error=clade-sweep_%%A_%%a.err
%s

set -euo pipefail
Rscript -e %s
',
    n_array_tasks,
    n_cores_per_task,
    time,
    mem,
    sbatch_extras,
    shQuote(r_body)
  )

  writeLines(sh, con = script_path)
  Sys.chmod(script_path, mode = "0755")

  message(sprintf("SLURM script written to: %s", script_path))
  message(sprintf("Submit with:  sbatch %s", script_path))
  message(sprintf("  - %d specs total, %d array tasks × ~%d specs/task",
                  N, n_array_tasks, chunk_size))
  message(sprintf("  - output CSV: %s (resume-safe)", out_path))

  invisible(script_path)
}

# ── Internal helpers ──────────────────────────────────────────────────────────

#' Validate a specs list before sending to Julia
#'
#' Checks types and value ranges for key parameters. Errors early in R rather
#' than letting Julia produce a cryptic stack trace.
#'
#' @param specs A specs list from [default_specs()].
#' @return Invisibly `TRUE` if all checks pass.
#' @keywords internal
.validate_specs <- function(specs) {
  stopifnot(is.list(specs))

  check_int_pos   <- function(nm) {
    v <- specs[[nm]]
    if (is.null(v) || !is.numeric(v) || length(v) != 1L || v < 1L)
      stop(sprintf("specs$%s must be a positive integer, got: %s",
                   nm, deparse(v)), call. = FALSE)
  }
  check_prob <- function(nm) {
    v <- specs[[nm]]
    if (is.null(v) || !is.numeric(v) || length(v) != 1L || v < 0 || v > 1)
      stop(sprintf("specs$%s must be in [0, 1], got: %s",
                   nm, deparse(v)), call. = FALSE)
  }
  check_choice <- function(nm, choices) {
    v <- specs[[nm]]
    if (is.null(v) || !is.character(v) || length(v) != 1L || !v %in% choices)
      stop(sprintf("specs$%s must be one of {%s}, got: %s",
                   nm, paste(choices, collapse = ", "), deparse(v)),
           call. = FALSE)
  }

  check_int_pos("grid_rows")
  check_int_pos("grid_cols")
  check_int_pos("n_agents_init")
  check_int_pos("max_ticks")

  check_choice("brain_type",
               c("bnn", "ann", "ctrnn", "grn", "transformer", "synthesis",
                 "random"))
  check_choice("dominance_model", c("additive", "dominant", "codominant"))
  check_choice("life_history",    c("iteroparous", "semelparous"))
  check_choice("rl_mode",         c("none", "actor_critic", "hebbian"))
  check_choice("brain_energy_mode",
               c("none", "size", "activity", "prediction_error"))

  if (!specs$ploidy %in% c(1L, 2L))
    stop("specs$ploidy must be 1L (haploid) or 2L (diploid).", call. = FALSE)

  check_prob("grass_init_prob")
  check_prob("grass_rate")
  check_prob("transmission_prob")
  check_prob("disease_death_prob")
  check_prob("crossover_rate")

  if (specs$n_agents_init > specs$max_agents)
    stop("specs$n_agents_init must not exceed specs$max_agents.", call. = FALSE)

  if (isTRUE(specs$social_learning) && specs$n_agents_init < 100L)
    warning(
      "social_learning = TRUE with n_agents_init < 100: neighbour density ",
      "is likely too low to trigger copying events. ",
      "Set n_agents_init >= 150L for reliable results.",
      call. = FALSE
    )

  # Shine et al. (2011) spatial sorting requires an invasion front; a
  # toroidal grid wraps continuously and has no defined front, so the
  # centroid/front-threshold computation in spatial_sorting.jl is
  # geometrically ill-posed. Warn the user and suggest toroidal = FALSE.
  if (isTRUE(specs$spatial_sorting) && isTRUE(specs$toroidal))
    warning(
      "spatial_sorting = TRUE with toroidal = TRUE: Shine et al. (2011) ",
      "invasion-front dynamics require a bounded grid. On a torus the ",
      "population centroid wraps and 'front' has no fixed location. ",
      "Set specs$toroidal <- FALSE for spatial_sorting experiments.",
      call. = FALSE
    )

  invisible(TRUE)
}

#' Convert an R specs list to a Julia `Dict{String,Any}`
#'
#' Sends the specs list to Julia through [JuliaConnectoR::juliaCall()] and
#' lets the Julia helper `Clade.r_specs_to_dict()` unpack it into a
#' `Dict{String,Any}`. This replaces the earlier string-interpolation approach
#' which required manual escaping for every scalar type. JuliaConnectoR
#' serialises an R named list as an `RConnector.ElementList` whose scalars
#' retain their R types (integer, double, logical, character), and the Julia
#' helper rebuilds the Dict keyed by string.
#'
#' Values that JuliaConnectoR cannot serialise -- single `NA`s and zero-length
#' character vectors -- are dropped before sending. Julia reads optional
#' fields via `get(specs, key, default)`, so an absent key is equivalent to
#' `nothing` or the coded default.
#'
#' @param specs A validated specs list from [default_specs()].
#' @return A Julia proxy for the resulting `Dict{String,Any}`, suitable for
#'   passing to `Clade.run_clade()`.
#' @keywords internal
.specs_to_julia <- function(specs) {
  # Ensure integer fields are sent as Int64 (not Float64). JuliaConnectoR
  # preserves R's integer type across the boundary.
  int_fields <- c(
    "grid_rows", "grid_cols", "n_agents_init", "max_agents", "max_ticks",
    "n_chromosomes", "ploidy", "max_age", "disease_duration",
    "immune_duration", "allee_threshold", "n_predators_init",
    "predator_max_agents", "predator_max_age", "predator_min_repro_age",
    "juvenile_independence_age", "max_clutch_size", "signal_dims", "n_genes",
    "transformer_history", "transformer_heads", "synthesis_max_rules",
    "rl_update_freq", "social_learning_freq", "season_length", "log_freq",
    "fixed_patch_radius"
  )
  for (nm in int_fields) {
    if (!is.null(specs[[nm]])) specs[[nm]] <- as.integer(specs[[nm]])
  }

  # JuliaConnectoR cannot serialise NA scalars or length-0 character vectors.
  # Drop them; Julia reads optional fields via `get(specs, k, default)`, so
  # an absent key is equivalent to `nothing`.
  keep  <- vapply(specs, .is_sendable_to_julia, logical(1L))
  specs <- specs[keep]

  JuliaConnectoR::juliaCall("Clade.r_specs_to_dict", specs)
}

#' Test whether an R value can round-trip through JuliaConnectoR
#'
#' JuliaConnectoR fails to serialise `NULL`, `NA` scalars, and zero-length
#' character vectors. This helper returns `FALSE` for these, `TRUE` otherwise.
#' @keywords internal
.is_sendable_to_julia <- function(v) {
  if (is.null(v))                            return(FALSE)
  if (length(v) == 0L)                       return(FALSE)
  if (length(v) == 1L && is.na(v))           return(FALSE)
  TRUE
}

#' Render a scalar R value as a Julia literal string
#' @keywords internal
.r_val_to_julia_str <- function(v) {
  # NA check first -- before type dispatch, because NA_integer_ is also integer
  if (length(v) == 1L && is.na(v)) return("nothing")
  if (is.logical(v) && length(v) == 1L) {
    return(if (isTRUE(v)) "true" else "false")
  }
  if (is.integer(v) && length(v) == 1L)  return(as.character(v))
  if (is.double(v)  && length(v) == 1L)  return(sprintf("%.17g", v))
  if (is.character(v) && length(v) == 1L) return(sprintf('"%s"', v))
  if (is.integer(v)  && length(v) > 1L)  return(sprintf("[%s]", paste(v, collapse = ", ")))
  if (is.character(v) && length(v) == 0L) return("String[]")
  if (is.character(v) && length(v) > 1L) {
    return(sprintf('[%s]', paste(sprintf('"%s"', v), collapse = ", ")))
  }
  stop("Cannot serialise R value to Julia: ", deparse(v), call. = FALSE)
}

#' Convert a Julia env result to an R list
#'
#' JuliaConnectoR returns Julia structs as named R lists. This function
#' extracts the fields expected by [get_run_data()] and [plot_run()].
#'
#' @param env_julia The raw return value from `juliaCall("Clade.run_clade", ...)`.
#' @param specs The specs list used for this run.
#' @return A named R list with fields `$agents`, `$t`, `$specs`, `$progress`,
#'   `$deaths`, `$genome_log`.
#' @keywords internal
.julia_env_to_r <- function(env_julia, specs) {
  # env_julia$grass is a 2D Julia array; tryCatch in case grass is not
  # accessible (e.g. when testing with a mock env).
  grass_r <- tryCatch(
    {
      g <- env_julia$grass
      if (is.null(g)) NULL else matrix(as.numeric(g),
                                       nrow = as.integer(specs$grid_rows),
                                       ncol = as.integer(specs$grid_cols))
    },
    error = function(e) NULL
  )

  structure(
    list(
      agents        = env_julia$agents,
      t             = env_julia$t,
      specs         = specs,
      grass         = grass_r,
      progress      = as.data.frame(env_julia$progress),
      deaths        = as.data.frame(env_julia$deaths),
      genome_log    = env_julia$genome_log,
      total_carrion = env_julia$total_carrion,
      total_shelter = env_julia$total_shelter
    ),
    class = "clade_env"
  )
}
