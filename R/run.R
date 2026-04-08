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
  .julia_env_to_r(env_julia, specs)
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
#' `batch_alife()` runs a list of specs in parallel, distributing across
#' Julia threads (via `Threads.@threads`) if more than one thread is available,
#' and additionally across R worker processes via the `parallel` package.
#'
#' @param specs_list A list of specs lists. Each element is passed to
#'   [run_alife()] independently.
#' @param n_cores Integer. Number of R worker processes to use (default 1L).
#'   When `> 1`, uses [parallel::mclapply()] on Unix/macOS or
#'   [parallel::parLapply()] on Windows.
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

  if (n_cores <= 1L || .Platform$OS.type == "windows") {
    lapply(specs_list, run_one)
  } else {
    parallel::mclapply(specs_list, run_one, mc.cores = n_cores)
  }
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

  invisible(TRUE)
}

#' Convert an R specs list to a Julia-compatible named Dict
#'
#' Julia receives the specs as a `Dict{String, Any}`. Integers, doubles,
#' logicals, strings, and integer vectors are all supported by JuliaConnectoR.
#'
#' @param specs A validated specs list.
#' @return The result of `JuliaConnectoR::juliaCall("Dict", ...)`.
#' @keywords internal
.specs_to_julia <- function(specs) {
  # Ensure integer fields are sent as Int64 (not Float64)
  int_fields <- c(
    "grid_rows", "grid_cols", "n_agents_init", "max_agents", "max_ticks",
    "n_chromosomes", "ploidy", "max_age", "disease_duration",
    "immune_duration", "allee_threshold", "n_predators_init", "max_predators",
    "care_duration", "max_clutch_size", "signal_dims", "n_genes",
    "transformer_history", "transformer_heads", "synthesis_max_rules",
    "rl_update_freq", "social_learning_freq", "seasonal_period", "log_freq"
  )
  for (nm in int_fields) {
    if (!is.null(specs[[nm]])) specs[[nm]] <- as.integer(specs[[nm]])
  }

  # JuliaConnectoR::juliaCall() converts named R lists to Julia NamedTuples;
  # we pass each field as a keyword so the order does not matter.
  do.call(
    JuliaConnectoR::juliaEval,
    list(paste0(
      'Dict{String,Any}(',
      paste(
        sprintf('"%s" => %s', names(specs),
                vapply(specs, .r_val_to_julia_str, character(1L))),
        collapse = ", "
      ),
      ')'
    ))
  )
}

#' Render a scalar R value as a Julia literal string
#' @keywords internal
.r_val_to_julia_str <- function(v) {
  # NA check first — before type dispatch, because NA_integer_ is also integer
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
  list(
    agents     = env_julia$agents,
    t          = env_julia$t,
    specs      = specs,
    progress   = as.data.frame(env_julia$progress),
    deaths     = as.data.frame(env_julia$deaths),
    genome_log = env_julia$genome_log
  )
}
