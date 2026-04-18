# s-plasticity / s-baldwin — spatial-flipping seasonal selection.
#
# 0.5.18 kernel change: new `seasonal_spatial_bias` spec flips grass
# distribution between summer (top half rich) and winter (bottom half
# rich). Creates fluctuating selection — the optimal foraging
# direction changes with season. This is the regime DeWitt & Scheiner
# 2004 / Hinton & Nowlan 1987 require for plasticity to be favoured.
#
# Design: 16 seeds × 3 conditions:
#   - stable:      seasonal_amplitude = 0, no spatial bias
#   - amp_only:    seasonal_amplitude = 0.5, no spatial bias
#                  (uniform stressor; previous test regime)
#   - flipping:    seasonal_amplitude = 0.5, seasonal_spatial_bias = 0.7
#                  (fluctuating-selection regime; the new test)
#
# Metric: mean_prior_sigma at end. Hypothesis: flipping > stable
# (high-heterozygosity agents do better when the optimum flips).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(regime, seed) {
  # default_specs (30x30) — more robust than realistic_specs for
  # the flipping regime, which is inherently harsher (half the grid
  # has low food at any time).
  s <- default_specs()
  s$n_agents_init  <- 100L
  s$max_agents     <- 500L
  s$grass_rate     <- 0.15
  s$max_ticks      <- 2000L
  # Enable within-lifetime learning so plastic agents can TRACK the
  # seasonal flip (sigma alone doesn't help; RL consolidates the
  # shift via bnn_update!).
  s$rl_mode                 <- "actor_critic"
  s$rl_update_freq          <- 5L
  s$bnn_sample_freq         <- 5L
  s$learning_rate_init_mean <- 0.01
  if (regime == "amp_only") {
    s$seasonal_amplitude     <- 0.5
    s$season_length          <- 100L
  } else if (regime == "flipping") {
    s$seasonal_amplitude     <- 0.5
    s$seasonal_spatial_bias  <- 0.9    # near-total spatial flip
    s$season_length          <- 100L   # longer seasons, agents experience
                                         # multiple full cycles
  }
  # stable: defaults (all seasonal specs = 0)
  s$random_seed <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec("stable",   sd)),
  lapply(SEEDS, function(sd) build_spec("amp_only", sd)),
  lapply(SEEDS, function(sd) build_spec("flipping", sd))
)
conditions <- c(rep("stable",   length(SEEDS)),
                rep("amp_only", length(SEEDS)),
                rep("flipping", length(SEEDS)))

message(sprintf("Running %d specs (3 conds x 16 seeds)...",
                length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = length(specs_list))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  keep <- d$t >= 1500
  data.frame(
    condition        = conditions[i],
    seed             = specs_list[[i]]$random_seed,
    verdict          = via$verdict,
    mean_prior_sigma = mean(d$mean_prior_sigma[keep], na.rm = TRUE),
    n_agents         = mean(d$n_agents[keep],         na.rm = TRUE),
    diversity        = mean(d$genetic_diversity[keep],na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/plasticity_fluctuating_selection.rds")

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("stable", "amp_only", "flipping")) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) {
    message(sprintf("  %-9s n=0 (all crashed/weak)", cnd))
    next
  }
  message(sprintf(
    "  %-9s n=%d | sigma=%.4f \u00b1 %.4f | div=%.3f \u00b1 %.3f | pop=%.1f",
    cnd, nrow(sub),
    mean(sub$mean_prior_sigma), sd(sub$mean_prior_sigma) / sqrt(nrow(sub)),
    mean(sub$diversity),        sd(sub$diversity)        / sqrt(nrow(sub)),
    mean(sub$n_agents)))
}

get_m <- function(cnd, metric) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) return(c(m = NA, se = NA, n = 0))
  c(m = mean(sub[[metric]]),
    se = sd(sub[[metric]]) / sqrt(nrow(sub)),
    n = nrow(sub))
}

# Key test: flipping vs stable in mean_prior_sigma
for (cmp in list(c("amp_only", "stable"), c("flipping", "stable"),
                 c("flipping", "amp_only"))) {
  a <- get_m(cmp[1], "mean_prior_sigma")
  b <- get_m(cmp[2], "mean_prior_sigma")
  if (is.na(a["m"]) || is.na(b["m"])) next
  d_ <- a["m"] - b["m"]
  se <- sqrt(a["se"]^2 + b["se"]^2)
  t_ <- d_ / se
  v <- if (!is.finite(t_)) "NA"
       else if (d_ > 0 && abs(t_) >= 2) "PASS"
       else if (abs(t_) >= 2)           "PASS wrong-dir"
       else                              "recheck"
  message(sprintf("  sigma Δ(%s - %s) = %+.4f \u00b1 %.4f  t = %+5.2f  %s",
                  cmp[1], cmp[2], d_, se, t_, v))
}
