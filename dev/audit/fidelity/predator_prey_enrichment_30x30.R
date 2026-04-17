# Does the "toroidal + complex_landscape doubles LV oscillation" finding
# scale from 50×50 down to the default 30×30 grid?
#
# Also tests the mechanism hypothesis: `complex_landscape` adds shrub +
# canopy *resource layers*, which biologically is closer to Rosenzweig
# 1971's "paradox of enrichment" (richer K → larger cycles) than to
# Huffaker 1958's spatial-refugia mechanism.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

oscillation_score <- function(prey, burn = 100L, lag_range = 20L:100L) {
  x <- prey[seq.int(burn + 1L, length(prey))]
  if (length(x) < max(lag_range) + 10L) return(NA_real_)
  if (sd(x) < 1)                         return(0)
  ac <- stats::acf(x, lag.max = max(lag_range), plot = FALSE)$acf[-1L]
  min_ac_in_range <- min(ac[lag_range])
  if (is.na(min_ac_in_range) || min_ac_in_range >= 0) return(0)
  -min_ac_in_range
}

.run <- function(cl, seed, rows = 30L) {
  s <- default_specs()
  s$n_agents_init             <- if (rows == 30L) 100L else 250L
  s$max_agents                <- 1000L
  s$n_predators_init          <- if (rows == 30L) 10L else 25L
  s$grid_rows                 <- rows
  s$grid_cols                 <- rows
  s$predator_energy_gain      <- 30
  s$predator_min_repro_energy <- 50
  s$predator_max_agents       <- if (rows == 30L) 100L else 250L
  s$grass_rate                <- 0.20
  s$max_ticks                 <- 800L
  s$toroidal                  <- TRUE
  s$complex_landscape         <- cl
  if (cl) {
    s$shrub_density  <- 0.35
    s$canopy_density <- 0.10
  }
  s$random_seed <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(osc = oscillation_score(d$n_agents),
       prey_mean = mean(tail(d$n_agents, 100L), na.rm = TRUE))
}

t0 <- Sys.time()
message("Scaling test: does patchy-amplification hold at 30×30?")

seeds <- c(1L, 7L, 13L, 19L, 25L)
res <- list()
for (rows in c(30L, 50L)) {
  for (cl in c(FALSE, TRUE)) {
    for (sd in seeds) {
      r <- .run(cl, sd, rows)
      res[[length(res) + 1L]] <- data.frame(
        rows = rows, complex_landscape = cl, seed = sd,
        osc = r$osc, prey_mean = r$prey_mean)
      message(sprintf("  rows=%d cl=%s seed=%2d → osc=%.3f prey_mean=%.0f",
                      rows, cl, sd, r$osc, r$prey_mean))
    }
  }
}
res <- do.call(rbind, res)

summary_df <- aggregate(cbind(osc, prey_mean) ~ rows + complex_landscape,
                        data = res,
                        FUN  = function(x) c(mean = mean(x, na.rm = TRUE),
                                             sd   = sd(  x, na.rm = TRUE)))
message("\nSummary:")
print(summary_df)

saveRDS(res, "dev/audit/fidelity/predator_prey_enrichment_30x30.rds")

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\nDone in %.1f min.", elapsed))
