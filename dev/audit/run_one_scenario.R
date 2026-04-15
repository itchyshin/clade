# Run the displayed code of one scenario in a warm R/Julia session.
#
# We wrap `clade::run_alife` with an interceptor that records the final
# `specs` list actually passed to Julia — that is the audit's
# `displayed_specs`. We also capture `get_run_data(env)$ticks` for the
# metric trajectory.

audit_run_one <- function(parsed, timeout_sec = 600) {
  stopifnot(is.list(parsed))
  if (!nzchar(parsed$displayed_code)) {
    return(list(status = "NO_CODE", error = "vignette has no displayed chunks"))
  }

  # Sandbox env with access to clade + an interceptor
  recorded <- list(specs = NULL, env = NULL, data = NULL)

  env <- new.env(parent = globalenv())
  env$run_alife <- function(specs = clade::default_specs(), verbose = FALSE) {
    recorded$specs <<- specs
    e <- clade::run_alife(specs, verbose = verbose)
    recorded$env <<- e
    e
  }
  env$run_clade <- env$run_alife
  env$get_run_data <- function(env_) {
    d <- clade::get_run_data(env_)
    recorded$data <<- d
    d
  }
  env$default_specs <- clade::default_specs
  env$plot_run      <- function(...) invisible(NULL)   # suppress plots
  env$print         <- function(...) invisible(NULL)
  env$message       <- function(...) invisible(NULL)

  # Nested forks (mclapply inside mcparallel) deadlock JuliaConnectoR.
  # Force sequential batch execution; the audit checks trajectories, not
  # parallelism. Capture each call's specs and store them on recorded$specs
  # as the most-recent element (batch drift between calls is acceptable
  # for an initial audit — later fix phase inspects per-call via JSON).
  env$batch_alife <- function(specs_list, n_cores = 1L, ..., verbose = FALSE) {
    recorded$specs <<- specs_list[[1]]
    res <- lapply(specs_list, function(s) {
      e <- clade::run_alife(s, verbose = FALSE)
      if (is.null(recorded$env)) {
        recorded$env  <<- e
        recorded$data <<- clade::get_run_data(e)
      }
      e
    })
    names(res) <- names(specs_list)
    res
  }
  # Search functions embed their own optimizers with internal parallelism;
  # for audit purposes we short-circuit them to a tiny no-op returning NULL,
  # so scenarios that only display search_map_elites() etc. complete quickly
  # and are flagged NO_RUN (which is correct — no direct trajectory).
  env$search_map_elites <- function(...) invisible(NULL)
  env$search_cmaes      <- function(...) invisible(NULL)
  env$search_gradient   <- function(...) invisible(NULL)
  env$search_viability  <- function(...) invisible(NULL)
  # tune_* wrappers each run hundreds of simulations via CMA-ES; short-circuit
  # them so audit runtime stays bounded. The audit checks trajectories from
  # displayed run_alife() calls, not optimizer convergence.
  env$tune_complex_landscape <- function(...) list(specs = clade::default_specs(),
                                                    history = NULL)
  env$tune_spatial_sorting   <- env$tune_complex_landscape
  env$tune_iffolk            <- env$tune_complex_landscape

  t0 <- Sys.time()
  err <- NULL
  tryCatch(
    withCallingHandlers(
      eval(parse(text = parsed$displayed_code), envir = env),
      warning = function(w) invokeRestart("muffleWarning")
    ),
    error = function(e) err <<- conditionMessage(e)
  )
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  if (!is.null(err)) {
    return(list(status = "RUN_ERROR", error = err, elapsed_sec = elapsed))
  }
  if (is.null(recorded$env)) {
    return(list(status = "NO_RUN",
                error = "displayed chunks did not call run_alife()",
                elapsed_sec = elapsed))
  }

  list(
    status      = "OK",
    specs       = recorded$specs,
    ticks       = if (!is.null(recorded$data)) recorded$data$ticks else NULL,
    deaths      = if (!is.null(recorded$data)) recorded$data$deaths else NULL,
    elapsed_sec = elapsed
  )
}
