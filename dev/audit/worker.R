# Worker: handle a partition of scenarios in one warm R+Julia session.
#
# Usage (interactive or via Rscript):
#   source("dev/audit/worker.R")
#   audit_worker(
#     vignette_paths = c("vignettes/s-rl.Rmd", "vignettes/s-baseline.Rmd"),
#     worker_id      = "w01",
#     out_dir        = "dev/audit/_artifacts"
#   )

source(file.path("dev", "audit", "parse_rmd.R"))
source(file.path("dev", "audit", "scenario_oracle.R"))
source(file.path("dev", "audit", "run_one_scenario.R"))
source(file.path("dev", "audit", "diagnose.R"))

audit_worker <- function(vignette_paths, worker_id, out_dir,
                         png_dir = "vignettes/figures",
                         warm = TRUE, verbose = TRUE) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c("~/R/lib", .libPaths()))
  if (!"clade" %in% loadedNamespaces()) {
    suppressMessages(devtools::load_all(".", quiet = TRUE))
  }

  progress_path <- file.path(out_dir, "progress.log")
  .progress <- function(event, vignette = "", diagnosis = "", elapsed = NA_real_) {
    line <- sprintf("%s\t%s\t%s\t%s\t%s\t%s\n",
                    format(Sys.time(), "%H:%M:%S"), worker_id,
                    event, vignette, diagnosis,
                    if (is.na(elapsed)) "" else sprintf("%.1fs", elapsed))
    cat(line, file = progress_path, append = TRUE)
    if (verbose) cat(line)
  }

  t_warm <- Sys.time()
  if (warm) {
    .progress("WARM_START")
    clade::julia_is_ready()  # trigger startup indirectly
    try(clade::run_alife(  # tiny warm-up run
      local({ s <- clade::default_specs(); s$max_ticks <- 2L; s$n_agents_init <- 4L; s }),
      verbose = FALSE
    ), silent = TRUE)
    .progress("WARM_DONE", elapsed = as.numeric(difftime(Sys.time(), t_warm, units = "secs")))
  }

  rows <- list()
  for (idx in seq_along(vignette_paths)) {
    p <- vignette_paths[[idx]]
    .progress("BEGIN", basename(p),
              sprintf("(%d/%d)", idx, length(vignette_paths)))
    parsed  <- audit_parse_rmd(p)
    oracle  <- audit_oracle_for(parsed$vignette)
    run_res <- audit_run_one(parsed)
    diag    <- audit_diagnose(parsed, run_res, oracle, png_dir)
    .progress("END", basename(p), diag$diagnosis,
              elapsed = as.numeric(run_res$elapsed_sec %||% NA))

    # persist full trajectories per scenario
    json_path <- file.path(out_dir,
                           sub("\\.Rmd$", ".json", parsed$vignette))
    .write_json(list(parsed = .parsed_summary(parsed),
                     run    = .run_summary(run_res),
                     oracle = oracle,
                     diag   = diag),
                json_path)

    .one <- function(x, fallback = NA) if (is.null(x) || length(x) == 0L) fallback else x[[1]]
    rows[[length(rows) + 1L]] <- data.frame(
      vignette    = parsed$vignette,
      diagnosis   = .one(diag$diagnosis, NA_character_),
      metric      = as.character(.one(diag$metric, NA_character_)),
      direction   = as.character(.one(diag$direction, NA_character_)),
      observed    = as.character(.one(diag$observed, NA_character_)),
      signal_ok   = as.logical(.one(diag$signal_ok, NA)),
      n_pngs      = length(parsed$fig_refs),
      n_chunks    = parsed$n_chunks,
      elapsed_sec = as.numeric(.one(run_res$elapsed_sec, NA_real_)),
      status      = .one(run_res$status, NA_character_),
      detail      = as.character(.one(diag$detail, NA_character_)),
      stringsAsFactors = FALSE
    )
  }

  out_csv <- file.path(out_dir, sprintf("%s.csv", worker_id))
  if (length(rows)) {
    utils::write.csv(do.call(rbind, rows), out_csv, row.names = FALSE)
  }
  invisible(out_csv)
}

.parsed_summary <- function(p) {
  list(
    vignette = p$vignette, title = p$title,
    n_chunks = p$n_chunks,
    fig_refs = lapply(p$fig_refs, function(r) r[c("name", "png", "fig_cap")]),
    displayed_code = p$displayed_code,
    hypothesis = p$hypothesis,
    what_we_found = p$what_we_found
  )
}

.run_summary <- function(r) {
  list(
    status = r$status,
    elapsed_sec = r$elapsed_sec,
    specs = if (!is.null(r$specs)) as.list(r$specs)[intersect(names(r$specs),
             c("brain_type","ploidy","n_agents_init","max_ticks","grid_size",
               "grass_rate","rl_mode","epigenetics","body_size_evolution",
               "dispersal_evolution","disease","kin_selection","niche_construction",
               "cooperation_evolution","parental_care","social_learning","mimicry",
               "predators","group_defense","complex_landscape","habitat_preference_evolution",
               "seasonal_amplitude","speciation_threshold","brain_size_evolution",
               "iffolk_selection","learning_rate","learning_rate_evolution",
               "spatial_sorting","stress_hypermutation","scavenging",
               "clutch_size_evolution","parental_investment","mate_choice",
               "signal_mating"))] else NULL,
    ticks_tail = if (!is.null(r$ticks)) utils::tail(r$ticks, 5) else NULL,
    ticks_metrics = if (!is.null(r$ticks)) names(r$ticks) else NULL,
    error = r$error
  )
}

.write_json <- function(x, path) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    cat(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null",
                         force = TRUE, pretty = TRUE),
        file = path)
  } else {
    # Fallback: write dput
    saveRDS(x, sub("\\.json$", ".rds", path))
  }
}
