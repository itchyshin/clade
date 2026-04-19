#' Sweep hypothesis conditions across seeds and compute per-run metrics
#'
#' `hypothesis_sweep()` is the researcher-facing wrapper for the
#' common simulation workflow surfaced repeatedly in clade's fidelity
#' audits: define a base spec, vary a small number of parameters
#' across several conditions, replicate each condition across seeds,
#' and collect summary metrics from each run's tick log.
#'
#' Each condition is a named list of parameter overrides applied on
#' top of `base_specs`. Conditions are crossed with `seeds` to produce
#' `length(conditions) * length(seeds)` runs, dispatched via
#' [batch_alife()].
#'
#' Metrics are evaluated on each run's `get_run_data(env)$ticks`
#' tibble (see [get_run_data()]) and must return a scalar or a
#' length-one logical. Common choices — mean over the last N ticks,
#' peak value, end-of-run value — are illustrated in the examples.
#'
#' @param base_specs A specs list from [default_specs()],
#'   [fast_specs()], [realistic_specs()], etc. Supplies the template
#'   from which each run's spec is derived.
#' @param conditions Named list of conditions. Each element is itself
#'   a named list of parameter overrides, e.g.
#'   `list(cost_low = list(signal_cost = 0.0, grass_rate = 0.2))`.
#'   The names appear in the output as the `condition` column.
#' @param seeds Integer vector of random seeds (default `1:8`). Each
#'   condition is replicated across all seeds.
#' @param metrics Named list of functions. Each function takes the
#'   `ticks` tibble returned by [get_run_data()] and returns a
#'   length-one scalar (numeric or logical). Defaults collect
#'   `final_n` (mean n_agents over the last 500 ticks) and `crashed`
#'   (a logical — whether n_agents fell below 10 at run end).
#' @param n_cores Integer. Passed to [batch_alife()]. Set as close as
#'   possible to `length(conditions) * length(seeds)` to keep each
#'   worker on one run (subject to your machine's compute limits —
#'   see CLAUDE.md for per-machine caps).
#' @param verbose Logical. Passed to [batch_alife()] (default FALSE).
#'
#' @return An S3 object of class `"hypothesis_sweep"` — a list with:
#'   * `runs`: tibble with one row per run, columns `condition`,
#'     `seed`, plus one column per metric.
#'   * `conditions`: the input conditions list (for re-referencing).
#'   * `metrics`: the input metrics list.
#'   * `base_specs`: the input base specs.
#'   * `seeds`: the seeds vector.
#'   * `elapsed`: difftime for the batch run.
#'
#' The object has a `print()` method that summarises per-condition
#' means ± SE across seeds.
#'
#' @examples
#' \dontrun{
#' # Example: how does grass_rate affect equilibrium population?
#' specs <- fast_specs()
#' specs$max_ticks <- 1000L
#'
#' sweep <- hypothesis_sweep(
#'   base_specs = specs,
#'   conditions = list(
#'     low  = list(grass_rate = 0.05),
#'     mid  = list(grass_rate = 0.10),
#'     high = list(grass_rate = 0.20)
#'   ),
#'   seeds = 1:8,
#'   n_cores = 24L
#' )
#' print(sweep)  # per-condition summary table
#'
#' # Test a specific direction:
#' hypothesis_report(sweep,
#'                   contrasts = list(food_effect = c("low", "high")),
#'                   metric = "final_n")
#' }
#'
#' @seealso [hypothesis_report()], [batch_alife()], [grid_specs()],
#'   [default_specs()]
#' @export
hypothesis_sweep <- function(base_specs,
                             conditions,
                             seeds    = 1:8,
                             metrics  = NULL,
                             n_cores  = 1L,
                             verbose  = FALSE) {
  stopifnot(is.list(base_specs),
            is.list(conditions), length(conditions) >= 1L,
            !is.null(names(conditions)),
            length(seeds) >= 1L)

  if (is.null(metrics)) {
    metrics <- list(
      final_n = function(ticks) {
        last_window <- utils::tail(ticks, 500L)
        mean(last_window$n_agents, na.rm = TRUE)
      },
      crashed = function(ticks) {
        utils::tail(ticks$n_agents, 1L) < 10L
      }
    )
  }
  stopifnot(is.list(metrics), length(metrics) >= 1L,
            !is.null(names(metrics)))
  seeds <- as.integer(seeds)
  n_cores <- as.integer(n_cores)

  # Build the full spec grid: one spec per (condition, seed) pair.
  spec_list <- list()
  meta <- data.frame(condition = character(0),
                     seed      = integer(0),
                     stringsAsFactors = FALSE)
  for (cname in names(conditions)) {
    overrides <- conditions[[cname]]
    stopifnot(is.list(overrides))
    for (sd in seeds) {
      spec <- base_specs
      for (pname in names(overrides)) {
        spec[[pname]] <- overrides[[pname]]
      }
      spec$random_seed <- as.integer(sd)
      key <- paste0(cname, "_seed", sd)
      spec_list[[key]] <- spec
      meta <- rbind(meta, data.frame(condition = cname, seed = sd,
                                     stringsAsFactors = FALSE))
    }
  }

  t_start <- Sys.time()
  envs <- batch_alife(spec_list, n_cores = n_cores, verbose = verbose)
  elapsed <- difftime(Sys.time(), t_start, units = "secs")

  # Compute metrics per run. get_run_data() is exported from R/analysis.R.
  metric_matrix <- vapply(seq_along(envs), function(i) {
    ticks <- get_run_data(envs[[i]])$ticks
    vapply(metrics, function(f) as.numeric(f(ticks)),
           FUN.VALUE = numeric(1L))
  }, FUN.VALUE = numeric(length(metrics)))

  # vapply returns a matrix when each result is length > 1; transpose
  # so rows correspond to runs.
  if (is.null(dim(metric_matrix))) {
    runs <- data.frame(meta,
                       setNames(list(metric_matrix), names(metrics)),
                       stringsAsFactors = FALSE)
  } else {
    runs <- cbind(meta,
                  as.data.frame(t(metric_matrix), stringsAsFactors = FALSE))
    names(runs)[-(1:2)] <- names(metrics)
  }

  out <- list(
    runs       = runs,
    conditions = conditions,
    metrics    = metrics,
    base_specs = base_specs,
    seeds      = seeds,
    elapsed    = elapsed
  )
  class(out) <- c("hypothesis_sweep", "list")
  out
}

#' @export
print.hypothesis_sweep <- function(x, ...) {
  cat("<hypothesis_sweep>\n")
  cat(sprintf("  %d conditions x %d seeds = %d runs (%.1fs)\n",
              length(x$conditions), length(x$seeds),
              nrow(x$runs), as.numeric(x$elapsed)))
  metric_cols <- setdiff(names(x$runs), c("condition", "seed"))
  if (length(metric_cols)) {
    summary_tbl <- summary_hypothesis_sweep(x)
    cat("\n  Per-condition mean +/- SE:\n")
    print(summary_tbl, row.names = FALSE)
  }
  invisible(x)
}

# Internal: per-condition mean and SE.
summary_hypothesis_sweep <- function(x) {
  metric_cols <- setdiff(names(x$runs), c("condition", "seed"))
  conds <- names(x$conditions)
  rows <- lapply(conds, function(cn) {
    r <- x$runs[x$runs$condition == cn, metric_cols, drop = FALSE]
    stats <- lapply(metric_cols, function(m) {
      vals <- r[[m]]
      n    <- sum(!is.na(vals))
      if (n == 0) return(c(mean = NA_real_, se = NA_real_))
      c(mean = mean(vals, na.rm = TRUE),
        se   = if (n > 1) stats::sd(vals, na.rm = TRUE) / sqrt(n) else NA_real_)
    })
    names(stats) <- metric_cols
    row <- list(condition = cn)
    for (m in metric_cols) {
      row[[paste0(m, "_mean")]] <- stats[[m]]["mean"]
      row[[paste0(m, "_se")]]   <- stats[[m]]["se"]
    }
    as.data.frame(row, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}


#' Compute contrast tests from a hypothesis_sweep
#'
#' `hypothesis_report()` produces t-tests (Welch, two-sample) for
#' named pairwise contrasts drawn from a [hypothesis_sweep()] result.
#' The conventional behavioural-ecology audit pattern is to name a
#' contrast with a direction-of-effect question ("does parental care
#' reduce population variance?") and report `Δ ± SE` and `t` across
#' seeds.
#'
#' Each contrast is a length-two character vector specifying
#' `c(reference_condition, test_condition)`. The reported delta is
#' `mean(test) − mean(reference)` on the chosen metric; the
#' interpretation of the sign is left to the caller.
#'
#' The verdict column uses the 2σ threshold convention shared across
#' clade's fidelity audits: `|t| >= 2` → **PASS**, `1.5 <= |t| < 2` →
#' **marginal**, otherwise → **null**. This is a screening heuristic,
#' not a formal hypothesis test — report the underlying statistic in
#' publications.
#'
#' @param sweep A `hypothesis_sweep` object from [hypothesis_sweep()].
#' @param contrasts Named list of pairwise contrasts. Each element is a
#'   length-two character vector `c(reference, test)` naming
#'   conditions present in `sweep$conditions`.
#' @param metric Character. Name of the metric column in `sweep$runs`
#'   to test. Defaults to the first metric.
#'
#' @return An S3 `"hypothesis_report"` object — a list with `table`
#'   (a data frame of contrast statistics) and `metric` (the metric
#'   name). Has a `print()` method that renders the table.
#'
#' @examples
#' \dontrun{
#' sweep <- hypothesis_sweep(...)
#' hypothesis_report(sweep,
#'                   contrasts = list(
#'                     food_effect = c("low", "high"),
#'                     cost_under_stress = c("cost0_stress", "cost1_stress")
#'                   ),
#'                   metric = "final_n")
#' }
#'
#' @seealso [hypothesis_sweep()]
#' @export
hypothesis_report <- function(sweep, contrasts, metric = NULL) {
  stopifnot(inherits(sweep, "hypothesis_sweep"),
            is.list(contrasts), length(contrasts) >= 1L,
            !is.null(names(contrasts)))

  metric_cols <- setdiff(names(sweep$runs), c("condition", "seed"))
  if (is.null(metric)) metric <- metric_cols[1L]
  if (!metric %in% metric_cols)
    stop(sprintf("metric '%s' not in sweep (have: %s)",
                 metric, paste(metric_cols, collapse = ", ")),
         call. = FALSE)

  cond_names <- names(sweep$conditions)
  rows <- lapply(names(contrasts), function(cname) {
    pair <- contrasts[[cname]]
    stopifnot(is.character(pair), length(pair) == 2L,
              all(pair %in% cond_names))
    ref  <- sweep$runs[[metric]][sweep$runs$condition == pair[1]]
    test <- sweep$runs[[metric]][sweep$runs$condition == pair[2]]
    delta <- mean(test, na.rm = TRUE) - mean(ref, na.rm = TRUE)
    n_ref  <- sum(!is.na(ref))
    n_test <- sum(!is.na(test))
    se <- if (n_ref > 1L && n_test > 1L) {
      sqrt(stats::var(test, na.rm = TRUE) / n_test +
           stats::var(ref,  na.rm = TRUE) / n_ref)
    } else NA_real_
    tval <- if (!is.na(se) && se > 0) delta / se else NA_real_
    verdict <- if (is.na(tval)) "insufficient-seeds"
      else if (abs(tval) >= 2) "PASS"
      else if (abs(tval) >= 1.5) "marginal"
      else "null"
    data.frame(
      contrast  = cname,
      reference = pair[1],
      test      = pair[2],
      metric    = metric,
      n_ref     = n_ref,
      n_test    = n_test,
      delta     = delta,
      se        = se,
      t         = tval,
      verdict   = verdict,
      stringsAsFactors = FALSE
    )
  })
  tbl <- do.call(rbind, rows)
  out <- list(table = tbl, metric = metric)
  class(out) <- c("hypothesis_report", "list")
  out
}

#' @export
print.hypothesis_report <- function(x, ...) {
  cat(sprintf("<hypothesis_report>  metric = %s\n", x$metric))
  cat("\n")
  # Compact formatted printing
  t <- x$table
  t$delta <- signif(t$delta, 4L)
  t$se    <- signif(t$se, 3L)
  t$t     <- signif(t$t, 3L)
  print(t[, c("contrast", "reference", "test", "delta", "se", "t", "verdict")],
        row.names = FALSE)
  invisible(x)
}
