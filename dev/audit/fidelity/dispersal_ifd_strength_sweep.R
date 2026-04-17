# Diagnose s-dispersal-ifd.
#
# The v2 re-audit contrasted complex_landscape TRUE vs FALSE, hoping this
# would create a spatial gradient for habitat_preference to exploit. But
# inspection of `inst/julia/src/modules/habitat_preference.jl` revealed that
# habitat_preference only reads `env.grass`, not the shrub/canopy maps that
# `complex_landscape` populates. So the v2 "flat vs patchy" contrast wasn't
# actually contrasting anything relevant to the trait under audit.
#
# Proper diagnosis: sweep `habitat_preference_strength` ∈ {0.5, 1.0, 2.0, 4.0}
# at fast_specs + uniform grass, with `habitat_preference_evolution = TRUE`
# throughout. Prediction: higher strength → stronger selection gradient on
# the trait (moving-toward-grass-rich cells pays off more per preference
# unit) → positive habitat_preference evolves.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS    <- c(1L, 7L, 13L, 19L, 25L)
STRENGTH <- c(0.5, 1.0, 2.0, 4.0)

.base <- function(seed) {
  s <- fast_specs()
  s$n_agents_init <- 180L
  s$max_agents    <- 800L
  s$grid_rows     <- 40L
  s$grid_cols     <- 40L
  s$grass_rate    <- 0.25
  s$random_seed   <- as.integer(seed)
  s
}

one_run <- function(strength, seed) {
  s <- .base(seed)
  s$dispersal_evolution          <- TRUE
  s$dispersal_init_mean          <- 0.3
  s$habitat_preference_evolution <- TRUE
  s$habitat_preference_init_mean <- 0.0
  s$habitat_preference_mutation_sd <- 0.05
  s$habitat_preference_strength  <- strength
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(init = d$mean_habitat_preference[1L],
       final = tail(d$mean_habitat_preference, 1L),
       n_final = tail(d$n_agents, 1L),
       n_habitat_moves = tail(d$n_habitat_moves, 1L))
}

t0 <- Sys.time()
message("=== dispersal-ifd × habitat_preference_strength sweep ===")
# Prediction: Fretwell-Lucas IFD says preference should evolve positive
# because grass-rich cells give more energy. Higher strength = more
# effective movement toward grass → stronger positive selection.

res <- data.frame()
for (st in STRENGTH) {
  for (sd in SEEDS) {
    r <- one_run(st, sd)
    res <- rbind(res, data.frame(
      strength = st, seed = sd,
      init = r$init, final = r$final,
      delta = r$final - r$init, n_final = r$n_final,
      moves = r$n_habitat_moves))
    message(sprintf(
      "  strength=%.1f seed=%2d → init=%+.3f final=%+.3f Δ=%+.3f n=%d moves=%d",
      st, sd, r$init, r$final, r$final - r$init, r$n_final, r$moves))
  }
}

message("\n── Summary per strength ──")
for (st in STRENGTH) {
  sub   <- res[res$strength == st, ]
  message(sprintf(
    "  strength=%.1f | mean Δ=%+.4f ± %.4f | mean final=%+.4f | min_n=%d",
    st, mean(sub$delta), sd(sub$delta),
    mean(sub$final), min(sub$n_final)))
}

saveRDS(res, "dev/audit/fidelity/dispersal_ifd_strength_sweep.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
