#!/usr/bin/env Rscript
# 0.5.3 Red Queen regime search.
#
# Motivation: the 0.5.3 16-seed audit showed Δn = -0.49 ± 1.54 at the
# default discrete-parasite parameters — statistically FLAT. The 0.5.1
# "+1.1 first sex-wins" claim was inside 3-seed noise. This script
# searches for a regime where the Red Queen produces a statistically
# significant sex > asex benefit at 8+ seeds.
#
# Strategy: sweep stronger parameters (more loci, higher pressure,
# sharper exponent, lower mutation to stabilise haplotypes).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

make_s <- function(ploidy, n_loci, pressure, exponent, mutation, seed,
                    max_ticks = 500L) {
  s <- default_specs()
  s$ploidy         <- as.integer(ploidy)
  s$crossover_rate <- if (ploidy == 2) 0.5 else 0.0
  s$n_agents_init  <- 100L
  s$grid_rows      <- 30L; s$grid_cols <- 30L
  s$grass_rate     <- 0.15
  s$max_agents     <- 400L
  s$max_ticks      <- as.integer(max_ticks)
  s$random_seed    <- as.integer(seed)
  s$coevolving_parasites        <- TRUE
  s$parasite_match_mode         <- "discrete"
  s$n_parasite_loci             <- as.integer(n_loci)
  s$parasite_pressure           <- pressure
  s$parasite_virulence_rate     <- 0.15
  s$parasite_discrete_exponent  <- exponent
  s$parasite_mutation_rate      <- mutation
  s
}

grid <- expand.grid(
  n_loci    = c(16L, 24L),
  pressure  = c(2.0, 4.0),
  exponent  = c(6.0, 10.0),
  mutation  = c(0.005, 0.02),
  KEEP.OUT.ATTRS = FALSE
)
seeds <- 1L:8L

cat(sprintf("── 0.5.3 Red Queen regime search: %d cells × %d seeds × 2 ploidies = %d runs\n",
            nrow(grid), length(seeds), nrow(grid) * length(seeds) * 2))

results <- list()
for (i in seq_len(nrow(grid))) {
  row <- grid[i, ]
  ns <- list(haploid_asex = numeric(), diploid_sex = numeric())
  for (ploidy in 1:2) {
    for (sd in seeds) {
      s <- make_s(ploidy, row$n_loci, row$pressure,
                  row$exponent, row$mutation, sd)
      env <- run_alife(s, verbose = FALSE)
      p <- env$progress
      idx <- p$t > 150
      n_mean <- mean(p$n_agents[idx], na.rm = TRUE)
      label <- if (ploidy == 1) "haploid_asex" else "diploid_sex"
      ns[[label]] <- c(ns[[label]], n_mean)
    }
  }
  asex_mean <- mean(ns$haploid_asex)
  asex_se   <- sd(ns$haploid_asex) / sqrt(length(ns$haploid_asex))
  sex_mean  <- mean(ns$diploid_sex)
  sex_se    <- sd(ns$diploid_sex) / sqrt(length(ns$diploid_sex))
  dn    <- sex_mean - asex_mean
  dn_se <- sqrt(asex_se^2 + sex_se^2)
  significant <- dn > 2 * dn_se
  results[[i]] <- data.frame(
    n_loci   = row$n_loci,
    pressure = row$pressure,
    exponent = row$exponent,
    mutation = row$mutation,
    asex_n   = asex_mean,
    sex_n    = sex_mean,
    delta    = dn,
    delta_se = dn_se,
    sig      = significant
  )
  cat(sprintf("  cell %2d/%d: loci=%2d pp=%.1f exp=%.1f mut=%.3f  Δn = %+6.2f ± %.2f  %s\n",
              i, nrow(grid), row$n_loci, row$pressure, row$exponent,
              row$mutation, dn, dn_se,
              if (significant) "SEX WINS (2×SE)" else "flat"))
}
summary <- do.call(rbind, results)

cat("\nTop 5 regimes by Δn:\n")
print(summary[order(-summary$delta), ][1:5, ])

any_sig <- any(summary$sig)
cat(sprintf("\nAny regime with statistically significant sex > asex? %s\n",
            if (any_sig) "YES" else "NO"))
if (any_sig) {
  best <- summary[summary$sig, ][which.max(summary[summary$sig, ]$delta), ]
  cat(sprintf("Best: loci=%d, pressure=%.1f, exp=%.1f, mut=%.3f, Δn = %+.2f ± %.2f\n",
              best$n_loci, best$pressure, best$exponent, best$mutation,
              best$delta, best$delta_se))
}

saveRDS(summary, "dev/audit/fidelity/red_queen_regime_results.rds")
