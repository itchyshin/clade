#!/usr/bin/env Rscript
# Red Queen long-run experiment: does the sex advantage accumulate
# over 2000 ticks? And does smaller population (n=50) amplify drift-
# selection to favor sex under parasites?
#
# Hypothesis: the 0.5.3 16-seed null at 500 ticks may be a timescale
# issue. With 2000 ticks (~8× more generations), the cumulative
# selection differential from novel-haplotype escape should grow.
# Smaller populations amplify genetic drift + rare-genotype advantage.
#
# Design: 3 regimes × 16 seeds × 2 ploidies = 96 runs, 2000 ticks.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

make_s <- function(ploidy, n_agents, n_loci, pressure, exponent,
                    seed, max_ticks = 2000L) {
  s <- default_specs()
  s$ploidy         <- as.integer(ploidy)
  s$crossover_rate <- if (ploidy == 2) 0.5 else 0.0
  s$n_agents_init  <- as.integer(n_agents)
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
  s$parasite_mutation_rate      <- 0.02
  s
}

regimes <- list(
  list(name = "A: n=100, 2000t, loci=16, pp=4, exp=10",
       n_agents = 100, n_loci = 16, pressure = 4.0, exponent = 10.0),
  list(name = "B: n=50, 2000t, loci=16, pp=4, exp=10",
       n_agents = 50, n_loci = 16, pressure = 4.0, exponent = 10.0),
  list(name = "C: n=50, 2000t, loci=24, pp=3, exp=8",
       n_agents = 50, n_loci = 24, pressure = 3.0, exponent = 8.0)
)
seeds <- 1L:16L

cat(sprintf("── Red Queen long-run: %d regimes × %d seeds × 2 ploidies = %d runs × 2000 ticks\n",
            length(regimes), length(seeds), length(regimes) * length(seeds) * 2))

results <- list()
for (i in seq_along(regimes)) {
  r <- regimes[[i]]
  ns <- list(haploid_asex = numeric(), diploid_sex = numeric())
  for (ploidy in 1:2) {
    for (sd in seeds) {
      s <- make_s(ploidy, r$n_agents, r$n_loci, r$pressure, r$exponent, sd)
      env <- run_alife(s, verbose = FALSE)
      p <- env$progress
      idx <- p$t > 500
      n_mean <- mean(p$n_agents[idx], na.rm = TRUE)
      label <- if (ploidy == 1) "haploid_asex" else "diploid_sex"
      ns[[label]] <- c(ns[[label]], n_mean)
    }
  }
  asex_mean <- mean(ns$haploid_asex); asex_se <- sd(ns$haploid_asex)/sqrt(length(ns$haploid_asex))
  sex_mean  <- mean(ns$diploid_sex);  sex_se  <- sd(ns$diploid_sex)/sqrt(length(ns$diploid_sex))
  dn    <- sex_mean - asex_mean
  dn_se <- sqrt(asex_se^2 + sex_se^2)
  sig   <- dn > 2 * dn_se
  results[[i]] <- data.frame(
    regime   = r$name,
    asex_n   = asex_mean,
    asex_se  = asex_se,
    sex_n    = sex_mean,
    sex_se   = sex_se,
    delta    = dn,
    delta_se = dn_se,
    sig      = sig
  )
  cat(sprintf("  %s: Δn = %+.2f ± %.2f  %s\n",
              r$name, dn, dn_se,
              if (sig) "*** SEX WINS ***" else "flat"))
}
summary <- do.call(rbind, results)

cat("\nLong-run summary:\n")
print(summary)
cat(sprintf("\nAny regime with sex > asex at 2×SE? %s\n",
            if (any(summary$sig)) "YES — FIRST ROBUST RED QUEEN" else "NO"))

saveRDS(summary, "dev/audit/fidelity/red_queen_long_run_results.rds")
