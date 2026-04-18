# s-stress-hypermutation promotion attempt: scarcity sweep.
#
# 0.5.11 re-audit demoted at grass_rate = 0.06 (Δ = 0.000, baseline =
# hypermut = 0.263 exactly across 4 seeds). Hypothesis: under real
# diploid sex, baseline mutation input ALREADY equals what hypermut
# adds at moderate scarcity. Under more severe starvation
# (grass_rate ∈ {0.02, 0.03, 0.04}), a larger fraction of agents
# spends time below `stress_threshold` — hypermutation should have
# a bigger relative effect.
#
# Design: grass_rate ∈ {0.02, 0.03, 0.04, 0.06} × hypermut ∈ {ON, OFF}
# × 16 seeds = 128 runs. Metrics: mean genetic_diversity,
# fraction-of-runs-viable, mean population.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS      <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
                51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)
GRASS      <- c(0.02, 0.03, 0.04, 0.06)

build_spec <- function(hypermut, grass, seed) {
  s <- default_specs()
  s$stress_hypermutation       <- hypermut
  # stress_threshold must be > min_repro_energy (default 120L) for
  # stress-mutation to fire at all — reproduction is gated at
  # energy ≥ min_repro_energy, so threshold = 40 never triggers.
  # At threshold = 150, agents reproducing with energy 120–150 are
  # "stressed" (get 5× base mutation) — so under scarcity, a larger
  # fraction of births incur hypermutation.
  s$stress_threshold           <- 150.0
  s$stress_mutation_multiplier <- 5.0
  s$grass_rate                 <- grass
  s$n_agents_init              <- 100L
  s$grid_rows                  <- 30L
  s$grid_cols                  <- 30L
  s$max_agents                 <- 400L
  s$max_ticks                  <- 500L
  s$random_seed                <- as.integer(seed)
  s
}

specs_list <- list()
conditions <- character()
for (g in GRASS) {
  for (hm in c(FALSE, TRUE)) {
    for (sd in SEEDS) {
      specs_list[[length(specs_list) + 1L]] <- build_spec(hm, g, sd)
      conditions <- c(conditions,
                      sprintf("%s_g%.2f", if (hm) "on" else "off", g))
    }
  }
}

message(sprintf("Running %d specs (%d grass × 2 conds × %d seeds)...",
                length(specs_list), length(GRASS), length(SEEDS)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 64L)
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  keep <- d$t >= 200
  data.frame(
    condition = conditions[i],
    grass     = specs_list[[i]]$grass_rate,
    hypermut  = specs_list[[i]]$stress_hypermutation,
    seed      = specs_list[[i]]$random_seed,
    verdict   = via$verdict,
    diversity = mean(d$genetic_diversity[keep], na.rm = TRUE),
    n_agents  = mean(d$n_agents[keep],          na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/stress_hypermutation_scarcity_sweep.rds")

message("\n── Per-grass results ──")
message(sprintf("  %-6s | %-30s | %-30s | %-20s",
                "grass", "OFF (div; n)", "ON (div; n)", "Δ_div ± SE, t"))
for (g in GRASS) {
  off <- tbl[!tbl$hypermut & tbl$grass == g & tbl$verdict != "crashed", ]
  on  <- tbl[ tbl$hypermut & tbl$grass == g & tbl$verdict != "crashed", ]
  if (nrow(off) < 2L || nrow(on) < 2L) {
    message(sprintf("  %.2f   | off_n=%d on_n=%d (too few viable)",
                    g, nrow(off), nrow(on)))
    next
  }
  d_div <- mean(on$diversity) - mean(off$diversity)
  se_div <- sqrt(var(on$diversity) / nrow(on) +
                 var(off$diversity) / nrow(off))
  t_div <- d_div / se_div

  # viability signal: fraction-crashed as Fisher's exact
  off_all <- tbl[!tbl$hypermut & tbl$grass == g, ]
  on_all  <- tbl[ tbl$hypermut & tbl$grass == g, ]
  off_crash <- c(sum(off_all$verdict == "crashed"), nrow(off_all) - sum(off_all$verdict == "crashed"))
  on_crash  <- c(sum(on_all$verdict  == "crashed"), nrow(on_all)  - sum(on_all$verdict  == "crashed"))
  mtx <- rbind(off_crash, on_crash)
  ft <- tryCatch(fisher.test(mtx, alternative = "greater"),
                  error = function(e) list(p.value = NA_real_, estimate = NA_real_))

  v <- if (!is.finite(t_div)) "NA"
       else if (t_div > 0 && abs(t_div) >= 2) "PASS div"
       else if (abs(t_div) >= 2)              "PASS-wrong-dir"
       else                                    "recheck"
  message(sprintf(
    "  %.2f   | off_n=%2d div=%.3f n=%5.1f | on_n=%2d div=%.3f n=%5.1f | \u0394=%+.4f \u00b1 %.4f t=%+.2f %s  | Fisher p=%.3f",
    g, nrow(off), mean(off$diversity), mean(off$n_agents),
       nrow(on),  mean(on$diversity),  mean(on$n_agents),
       d_div, se_div, t_div, v, ft$p.value))
}
