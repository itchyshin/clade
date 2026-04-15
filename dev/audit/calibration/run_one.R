# One-scenario CMA-ES calibration driver.
#
# Usage:
#   Rscript dev/audit/calibration/run_one.R <scenario-name> [--iter N] [--pop K]
#
# Example:
#   Rscript dev/audit/calibration/run_one.R s-baldwin --iter 30 --pop 8

suppressWarnings(suppressMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(devtools)
  library(jsonlite)
}))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop("usage: run_one.R <scenario-name> [--iter N] [--pop K]")
}
scenario <- args[[1]]

n_iter <- 30L
pop    <- 8L
i <- 2L
while (i <= length(args)) {
  if (args[[i]] == "--iter" && i < length(args)) { n_iter <- as.integer(args[[i+1]]); i <- i + 2L }
  else if (args[[i]] == "--pop" && i < length(args)) { pop <- as.integer(args[[i+1]]); i <- i + 2L }
  else i <- i + 1L
}

out_dir <- "dev/audit/calibration/_artifacts"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(out_dir, "progress.log")
.log <- function(event, detail = "") {
  line <- sprintf("%s\t%s\t%s\t%s\n",
                  format(Sys.time(), "%H:%M:%S"), scenario, event, detail)
  cat(line, file = log_path, append = TRUE)
  cat(line)
}

.log("START", sprintf("iter=%d pop=%d", n_iter, pop))

source("dev/audit/calibration/fitness_functions.R")

if (!scenario %in% names(fitness_registry)) {
  .log("NO_FITNESS", "scenario not in registry"); quit(status = 2)
}

reg <- fitness_registry[[scenario]]

suppressMessages(devtools::load_all(".", quiet = TRUE))

specs_base <- reg$specs_mods(default_specs())

# Validate that every param has a positive numeric value in specs_base.
ok <- TRUE
for (p in reg$params) {
  v <- specs_base[[p]]
  if (is.null(v) || !is.numeric(v) || length(v) != 1L || v <= 0) {
    .log("PARAM_NOT_POSITIVE_NUMERIC", sprintf("%s = %s", p, deparse(v)))
    ok <- FALSE
  }
}
if (!ok) quit(status = 3)

# Warm Julia once so first CMA-ES candidate doesn't eat the precompile.
t0 <- Sys.time()
try({
  clade::run_alife(local({s <- specs_base; s$max_ticks <- 5L; s$n_agents_init <- 6L; s}),
                   verbose = FALSE)
}, silent = TRUE)
.log("WARM_DONE", sprintf("%.1fs", as.numeric(difftime(Sys.time(), t0, units = "secs"))))

# Baseline fitness at the unmodified specs.
baseline_env <- tryCatch(clade::run_alife(specs_base, verbose = FALSE),
                         error = function(e) NULL)
baseline_fit <- if (is.null(baseline_env)) {
  NA_real_
} else {
  tryCatch(as.numeric(reg$fitness(baseline_env)), error = function(e) NA_real_)
}
.log("BASELINE", sprintf("fitness=%s", format(baseline_fit, digits = 4)))

# CMA-ES — maximise fitness. search_cmaes in this package maximises the
# objective returned by .make_obj_fn, which treats a function as-is.
t1 <- Sys.time()
res <- tryCatch(
  clade::search_cmaes(
    specs_base   = specs_base,
    objective    = reg$fitness,
    params       = reg$params,
    n_iterations = n_iter,
    popsize      = pop,
    sigma0       = 0.3,
    verbose      = FALSE
  ),
  error = function(e) list(error = conditionMessage(e))
)
elapsed <- as.numeric(difftime(Sys.time(), t1, units = "secs"))

if (!is.null(res$error)) {
  .log("SEARCH_ERROR", res$error)
  jsonlite::write_json(
    list(scenario = scenario, error = res$error, baseline_fitness = baseline_fit),
    file.path(out_dir, sprintf("%s.json", scenario)),
    auto_unbox = TRUE, pretty = TRUE
  )
  quit(status = 4)
}

best_specs <- {
  if      (!is.null(res$specs))      res$specs
  else if (!is.null(res$best_specs)) res$best_specs
  else                               specs_base
}
best_fit <- {
  if      (!is.null(res$score))      as.numeric(res$score)
  else if (!is.null(res$best_score)) as.numeric(res$best_score)
  else                               NA_real_
}

# Report key param deltas
delta <- list()
for (p in reg$params) {
  delta[[p]] <- list(
    initial = as.numeric(specs_base[[p]]),
    final   = as.numeric(best_specs[[p]] %||% NA_real_)
  )
}

out <- list(
  scenario          = scenario,
  params            = reg$params,
  iterations        = n_iter,
  popsize           = pop,
  elapsed_sec       = elapsed,
  baseline_fitness  = baseline_fit,
  best_fitness      = best_fit,
  improvement       = if (is.na(baseline_fit) || is.na(best_fit)) NA
                      else as.numeric(best_fit - baseline_fit),
  param_deltas      = delta,
  history_length    = length(res$history %||% list())
)
jsonlite::write_json(out, file.path(out_dir, sprintf("%s.json", scenario)),
                     auto_unbox = TRUE, pretty = TRUE, null = "null")

.log("END", sprintf("best=%s delta=%s elapsed=%.1fs",
                    format(best_fit, digits = 4),
                    format(out$improvement, digits = 4),
                    elapsed))
