# Driver: serial sweep in one warm R+Julia session.
#
# Parallelism across scenarios is possible in principle but fragile: forking
# an R process that already owns a JuliaConnectoR TCP socket causes some
# children to crash silently. Sequential execution is reliable and, because
# Julia stays warm across scenarios, total wall clock for 35 scenarios is
# ~3-5 min.
#
# Usage:
#   Rscript dev/audit/run_audit.R
#   Rscript dev/audit/run_audit.R --only s-rl.Rmd,s-baseline.Rmd

source(file.path("dev", "audit", "worker.R"))

.parse_cli <- function(args) {
  out <- list(only = NULL)
  i <- 1L
  while (i <= length(args)) {
    a <- args[[i]]
    if (a == "--only" && i < length(args)) {
      out$only <- strsplit(args[[i + 1L]], ",", fixed = TRUE)[[1]]
      i <- i + 2L
    } else i <- i + 1L
  }
  out
}

audit_run_all <- function(only = NULL,
                          vignette_dir = "vignettes",
                          out_dir = "dev/audit/_artifacts") {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  all_paths <- list.files(vignette_dir, pattern = "^s-.*\\.Rmd$",
                          full.names = TRUE)
  if (!is.null(only)) {
    keep <- basename(all_paths) %in% only
    all_paths <- all_paths[keep]
  }
  if (!length(all_paths)) stop("no scenario vignettes found")

  message(sprintf("[audit] %d scenarios, serial, single warm Julia session",
                  length(all_paths)))

  audit_worker(
    vignette_paths = all_paths,
    worker_id      = "w00",
    out_dir        = out_dir
  )

  # Rebuild canonical CSV from per-scenario JSONs — robust even if some
  # scenarios crashed the worker loop.
  .rebuild_csv_from_json(out_dir)
}

.rebuild_csv_from_json <- function(out_dir) {
  files <- list.files(out_dir, pattern = "^s-.*\\.json$", full.names = TRUE)
  if (!length(files)) {
    message("[audit] no scenario JSONs found; nothing to merge")
    return(invisible(NULL))
  }
  .one <- function(x, fallback = NA) if (is.null(x) || length(x) == 0L) fallback else x[[1]]
  .n_refs <- function(fr) {
    if (is.null(fr)) 0L
    else if (is.data.frame(fr)) nrow(fr)
    else if (is.list(fr)) length(fr)
    else 0L
  }
  rows <- lapply(files, function(f) {
    j <- jsonlite::fromJSON(f, simplifyVector = TRUE)
    data.frame(
      vignette    = j$parsed$vignette,
      diagnosis   = .one(j$diag$diagnosis, NA_character_),
      metric      = as.character(.one(j$diag$metric, NA_character_)),
      direction   = as.character(.one(j$diag$direction, NA_character_)),
      observed    = as.character(.one(j$diag$observed, NA_character_)),
      signal_ok   = as.logical(.one(j$diag$signal_ok, NA)),
      status      = .one(j$run$status, NA_character_),
      elapsed_sec = as.numeric(.one(j$run$elapsed_sec, NA_real_)),
      n_pngs      = .n_refs(j$parsed$fig_refs),
      n_metrics   = length(j$run$ticks_metrics %||% character()),
      detail      = as.character(.one(j$diag$detail, NA_character_)),
      stringsAsFactors = FALSE
    )
  })
  tbl <- do.call(rbind, rows)
  out <- file.path(out_dir, "scenario_audit.csv")
  utils::write.csv(tbl, out, row.names = FALSE)
  message(sprintf("[audit] wrote %s (%d rows)", out, nrow(tbl)))
  invisible(out)
}

if (!interactive() && sys.nframe() == 0) {
  cli <- .parse_cli(commandArgs(trailingOnly = TRUE))
  audit_run_all(only = cli$only)
}
