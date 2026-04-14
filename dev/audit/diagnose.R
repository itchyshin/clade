# Decision tree: given (parsed, run_result, oracle, cached_png), classify.

audit_diagnose <- function(parsed, run_result, oracle, png_dir) {
  # RUN_ERROR trumps everything
  if (identical(run_result$status, "RUN_ERROR")) {
    return(list(diagnosis = "RUN_ERROR",
                detail    = run_result$error,
                metric    = oracle$metric,
                direction = oracle$direction,
                observed  = NA))
  }
  if (identical(run_result$status, "NO_RUN")) {
    return(list(diagnosis = "NO_RUN",
                detail    = "displayed chunks don't invoke run_alife()",
                metric    = oracle$metric,
                direction = oracle$direction,
                observed  = NA))
  }

  # PNG existence check
  pngs_missing <- character()
  for (ref in parsed$fig_refs) {
    p <- file.path(png_dir, ref$png)
    if (!file.exists(p)) pngs_missing <- c(pngs_missing, ref$png)
  }

  # Signal check
  observed <- NA; signal_ok <- NA
  metric <- oracle$metric
  traj <- NULL
  if (!is.na(metric) && startsWith(metric, "deaths:") &&
      !is.null(run_result$deaths)) {
    col <- sub("^deaths:", "", metric)
    if (col %in% names(run_result$deaths))
      traj <- as.numeric(run_result$deaths[[col]])
  } else if (!is.null(run_result$ticks) && !is.na(metric) &&
             metric %in% names(run_result$ticks)) {
    traj <- as.numeric(run_result$ticks[[metric]])
  }
  if (!is.null(traj)) {
    traj <- traj[is.finite(traj)]
    if (length(traj) >= 4) {
      observed <- .direction_of(traj)
      signal_ok <- .matches(observed, oracle$direction)
    }
  } else if (!is.na(metric) &&
             (!is.null(run_result$ticks) || !is.null(run_result$deaths))) {
    observed <- sprintf("metric '%s' not available", metric)
  }

  diag <- if (length(pngs_missing) > 0) {
    "MISSING_PNG"
  } else if (is.na(oracle$direction)) {
    "NO_ORACLE"
  } else if (isTRUE(signal_ok)) {
    "OK"
  } else if (isFALSE(signal_ok)) {
    "SIGNAL_WRONG"
  } else {
    "INSUFFICIENT_DATA"
  }

  list(
    diagnosis      = diag,
    detail         = if (length(pngs_missing)) paste("missing:", paste(pngs_missing, collapse = ", "))
                     else NA_character_,
    metric         = oracle$metric,
    direction      = oracle$direction,
    observed       = as.character(observed),
    signal_ok      = signal_ok
  )
}

.direction_of <- function(traj) {
  n <- length(traj)
  early <- mean(traj[seq_len(max(1L, floor(n/4)))])
  late  <- mean(traj[seq.int(from = max(1L, floor(3*n/4)), to = n)])
  peak  <- max(traj, na.rm = TRUE)
  endv  <- traj[n]
  # "peak_then_decline" requires peak occurs before final 25% of the run
  peak_idx <- which.max(traj)
  if (peak_idx < floor(3*n/4) && peak > endv * 1.5) return("peak_then_decline")
  if (late > early * 1.1)  return("up")
  if (late < early * 0.9)  return("down")
  if (any(traj > 0)) return("nonzero")
  "flat"
}

.matches <- function(observed, expected) {
  if (is.na(expected)) return(NA)
  if (expected == "nonzero") return(observed %in% c("up", "down", "peak_then_decline", "nonzero"))
  observed == expected
}
