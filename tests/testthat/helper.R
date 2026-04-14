# helpers for clade tests
# All tests that do NOT require Julia are pure R (no .clade_start_julia()).
# Tests that require Julia are wrapped in skip_no_julia() to keep CRAN clean.

# ── Julia availability guard ──────────────────────────────────────────────────

#' Skip a test when Julia is not available.
#' Defined here so every test file can call it without re-defining it.
skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

# ── Minimal specs for fast unit tests ────────────────────────────────────────

.minimal_specs <- function(...) {
  s <- default_specs()
  s$grid_rows        <- 10L
  s$grid_cols        <- 10L
  s$n_agents_init    <- 5L
  s$max_ticks        <- 5L
  s$max_agents       <- 50L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

# ── Biological calibration helper ─────────────────────────────────────────────

#' Assert that a trait moves directionally over a simulation run.
#'
#' Runs `specs` through [run_alife()], computes the mean of `trait` over the
#' first and last `window` ticks, and asserts the relationship specified by
#' `direction`.
#'
#' @param specs  A specs list passed to [run_alife()].
#' @param trait  Column name in `get_run_data(env)$ticks`.
#' @param direction `"up"`, `"down"`, or `"any"` (just checks the column exists
#'   and is non-NA).
#' @param window  Number of ticks at each end used for averaging (default 30).
#' @param msg    Custom failure message (optional).
expect_evolution <- function(specs, trait, direction = "any",
                              window = 30L, msg = NULL) {
  env  <- run_alife(specs, verbose = FALSE)
  data <- get_run_data(env)$ticks

  if (!trait %in% names(data)) {
    testthat::fail(sprintf(
      "Column '%s' not found in run data.\nAvailable: %s",
      trait, paste(sort(names(data)), collapse = ", ")
    ))
  }

  col <- data[[trait]]
  n   <- length(col)
  w   <- max(1L, min(as.integer(window), n %/% 3L))

  v_start <- mean(col[seq_len(w)],           na.rm = TRUE)
  v_end   <- mean(col[seq(n - w + 1L, n)],  na.rm = TRUE)

  ok <- switch(direction,
    up   = v_end > v_start,
    down = v_end < v_start,
    any  = !is.na(v_start) && !is.na(v_end)
  )

  label <- msg %||% sprintf(
    "%s direction='%s' (start=%.4f, end=%.4f)",
    trait, direction, v_start, v_end
  )
  testthat::expect_true(ok, label = label)
  invisible(list(start = v_start, end = v_end))
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
