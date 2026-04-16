#!/usr/bin/env Rscript
# 0.5.3 Red Queen top-3 regime verification at 16 seeds.
#
# The regime search found 3 cells with Δn > +2.3 at 8 seeds but none
# crossed 2×SE. With 16 seeds the SE halves and these regimes might
# reach significance. Verify.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2)
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

# Top 3 regimes from the 8-seed search
regimes <- list(
  list(n_loci = 16L, pressure = 4.0, exponent = 10.0, mutation = 0.02),
  list(n_loci = 24L, pressure = 2.0, exponent = 6.0,  mutation = 0.005),
  list(n_loci = 16L, pressure = 2.0, exponent = 10.0, mutation = 0.02)
)
seeds <- 1L:16L

cat(sprintf("── Top-3 regime verification: %d regimes × %d seeds × 2 ploidies = %d runs\n",
            length(regimes), length(seeds), length(regimes) * length(seeds) * 2))

results <- list()
for (i in seq_along(regimes)) {
  r <- regimes[[i]]
  ns <- list(haploid_asex = numeric(), diploid_sex = numeric())
  for (ploidy in 1:2) {
    for (sd in seeds) {
      s <- make_s(ploidy, r$n_loci, r$pressure, r$exponent, r$mutation, sd)
      env <- run_alife(s, verbose = FALSE)
      p <- env$progress
      idx <- p$t > 150
      n_mean <- mean(p$n_agents[idx], na.rm = TRUE)
      label <- if (ploidy == 1) "haploid_asex" else "diploid_sex"
      ns[[label]] <- c(ns[[label]], n_mean)
    }
  }
  asex_mean <- mean(ns$haploid_asex); asex_se <- sd(ns$haploid_asex) / sqrt(length(ns$haploid_asex))
  sex_mean  <- mean(ns$diploid_sex);  sex_se  <- sd(ns$diploid_sex)  / sqrt(length(ns$diploid_sex))
  dn    <- sex_mean - asex_mean
  dn_se <- sqrt(asex_se^2 + sex_se^2)
  significant <- dn > 2 * dn_se
  results[[i]] <- data.frame(
    regime   = i,
    n_loci   = r$n_loci,
    pressure = r$pressure,
    exponent = r$exponent,
    mutation = r$mutation,
    asex_n   = asex_mean,
    asex_se  = asex_se,
    sex_n    = sex_mean,
    sex_se   = sex_se,
    delta    = dn,
    delta_se = dn_se,
    sig      = significant
  )
  cat(sprintf("  regime %d (loci=%d pp=%.1f exp=%.1f mut=%.3f): Δn = %+.2f ± %.2f %s\n",
              i, r$n_loci, r$pressure, r$exponent, r$mutation, dn, dn_se,
              if (significant) "SEX WINS (2×SE)" else "flat"))
}
summary <- do.call(rbind, results)

cat("\n16-seed verification summary:\n")
print(summary)

any_sig <- any(summary$sig)
cat(sprintf("\nAny regime with statistically significant sex > asex at 16 seeds? %s\n",
            if (any_sig) "YES" else "NO"))

saveRDS(summary, "dev/audit/fidelity/red_queen_top3_16seeds_results.rds")
