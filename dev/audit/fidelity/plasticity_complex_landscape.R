# s-plasticity / s-baldwin — spatial-plasticity test via complex_landscape.
#
# Background: clade's TEMPORAL seasonal implementation is a uniform
# stressor (amplitude modulation + winter mortality), which is
# phenotype-agnostic and doesn't create the fluctuating-selection
# regime DeWitt & Scheiner 2004 assume. Hence our 0.5.10 test
# showed stable > seasonal in mean_prior_sigma (direction reversed
# from DeWitt).
#
# DeWitt 2004 §3 also treats SPATIAL heterogeneity as selecting for
# plasticity — different patches favor different phenotypes. clade
# has `complex_landscape = TRUE` (3-layer canopy/shrub/ground
# habitat); if patches select differently, plastic agents should
# evolve higher mean_prior_sigma than agents in a flat landscape.
#
# Design: 16 seeds × 2 conditions (flat vs complex_landscape). All
# default BNN settings (heterozygosity-sourced sigma). Metric:
# mean_prior_sigma averaged over last 500 ticks. Hypothesis: complex
# > flat in sigma.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(complex_landscape, seed) {
  s <- realistic_specs()
  s$complex_landscape <- complex_landscape
  s$random_seed       <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(FALSE, sd)),
  lapply(SEEDS, function(sd) build_spec(TRUE,  sd))
)
conditions <- c(rep("flat",    length(SEEDS)),
                rep("complex", length(SEEDS)))

message(sprintf("Running %d specs (2 conds x 16 seeds)...",
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
saveRDS(tbl, "dev/audit/fidelity/plasticity_complex_landscape.rds")

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("flat", "complex")) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) {
    message(sprintf("  %-8s n=0 (all crashed or weak)", cnd))
    next
  }
  message(sprintf(
    "  %-8s n=%d | sigma=%.4f \u00b1 %.4f | div=%.3f \u00b1 %.3f | pop=%.1f",
    cnd, nrow(sub),
    mean(sub$mean_prior_sigma), sd(sub$mean_prior_sigma) / sqrt(nrow(sub)),
    mean(sub$diversity),        sd(sub$diversity)        / sqrt(nrow(sub)),
    mean(sub$n_agents)))
}

flat    <- viable[viable$condition == "flat",    ]
complex <- viable[viable$condition == "complex", ]
if (nrow(flat) >= 4L && nrow(complex) >= 4L) {
  for (metric in c("mean_prior_sigma", "diversity", "n_agents")) {
    d_ <- mean(complex[[metric]]) - mean(flat[[metric]])
    se <- sqrt(var(complex[[metric]]) / nrow(complex) +
               var(flat[[metric]])    / nrow(flat))
    t_ <- d_ / se
    v <- if (!is.finite(t_)) "NA"
         else if (d_ > 0 && abs(t_) >= 2) "PASS (complex > flat)"
         else if (abs(t_) >= 2)           "PASS wrong direction"
         else                              "recheck"
    message(sprintf(
      "  %-16s \u0394(complex - flat) = %+.4f \u00b1 %.4f  t = %+5.2f  %s",
      metric, d_, se, t_, v))
  }
}
