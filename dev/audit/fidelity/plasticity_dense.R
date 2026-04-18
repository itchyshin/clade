# s-plasticity audit on fast_specs (30x30 dense grid) so mate-finding
# works without selfing. Measures mean_prior_sigma evolution under mild
# seasonal amplitude.
#
# Previous realistic_specs attempts were confounded by mate-finding
# failure pegging sigma at bnn_sigma_init (kernel bug fixed 0.5.9).
# At 30x30 the population density is naturally higher, so most
# reproduction has a mate available and real heterozygosity evolves.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(env_type, seed) {
  s <- fast_specs()  # 30x30, 80 init, 2000 ticks, max_age=30
  if (env_type == "seasonal") {
    s$seasonal_amplitude <- 0.5
    s$season_length      <- 50L
  }
  s$random_seed <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec("stable",   sd)),
  lapply(SEEDS, function(sd) build_spec("seasonal", sd))
)
conditions <- c(rep("stable", length(SEEDS)), rep("seasonal", length(SEEDS)))

message(sprintf("Running %d specs (2 envs x 16 seeds) at fast_specs scale...",
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
    condition         = conditions[i],
    seed              = specs_list[[i]]$random_seed,
    verdict           = via$verdict,
    mean_prior_sigma  = mean(d$mean_prior_sigma[keep], na.rm = TRUE),
    n_agents          = mean(d$n_agents[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/plasticity_dense.rds")

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]
message("\n── Per-condition summary (n >= 20) ──")
for (cnd in c("stable", "seasonal")) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0) next
  message(sprintf("  %-8s n=%d | sigma=%.4f \u00b1 %.4f | pop=%.1f",
                  cnd, nrow(sub),
                  mean(sub$mean_prior_sigma),
                  sd(sub$mean_prior_sigma) / max(1, sqrt(nrow(sub))),
                  mean(sub$n_agents)))
}
seas <- viable[viable$condition == "seasonal", ]
stab <- viable[viable$condition == "stable",   ]
if (nrow(seas) >= 2L && nrow(stab) >= 2L) {
  d_ <- mean(seas$mean_prior_sigma) - mean(stab$mean_prior_sigma)
  se <- sqrt(var(seas$mean_prior_sigma) / nrow(seas) +
             var(stab$mean_prior_sigma) / nrow(stab))
  t_ <- d_ / se
  v <- if (!is.finite(t_)) "NA"
       else if (d_ > 0 && abs(t_) >= 2) "PASS (seasonal > stable, plasticity maintained)"
       else if (abs(t_) >= 2)           "PASS (wrong direction)"
       else                              "recheck"
  message(sprintf("  \u0394(seasonal - stable) = %+7.4f \u00b1 %.4f   t = %+5.2f   %s",
                  d_, se, t_, v))
}
