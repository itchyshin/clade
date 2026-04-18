# s-mating-systems at ultra_realistic scale.
#
# At realistic_specs() (N ≈ 120), 32 seeds gave Δn_sex-asex = +4.1 at
# t = +1.32. Finite-population theory (Otto & Michalakis 1998) says
# Red Queen advantage scales as ~μN. Quadrupling N to ~400 should
# quadruple the expected Δ, pushing t past 2σ.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L,
           113L, 121L, 131L, 139L, 149L, 157L, 163L, 173L,
           179L, 191L, 197L, 211L, 223L, 227L, 239L, 251L)

build_spec <- function(ploidy, seed) {
  s <- ultra_realistic_specs()
  s$ploidy                      <- as.integer(ploidy)
  s$crossover_rate              <- if (ploidy == 2L) 0.5 else 0.0
  s$coevolving_parasites        <- TRUE
  s$n_parasite_loci             <- 16L
  s$parasite_pressure           <- 2.0
  s$parasite_discrete_exponent  <- 6.0
  s$parasite_mutation_rate      <- 0.02
  s$random_seed                 <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(1L, sd)),
  lapply(SEEDS, function(sd) build_spec(2L, sd))
)
conditions <- c(rep("asex", length(SEEDS)), rep("sex", length(SEEDS)))

message(sprintf("Running %d specs (2 ploidies x 16 seeds) at ultra scale...",
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
  keep <- d$t >= 2000
  data.frame(
    condition     = conditions[i],
    seed          = specs_list[[i]]$random_seed,
    verdict       = via$verdict,
    n_agents      = mean(d$n_agents[keep],          na.rm = TRUE),
    gen_diversity = mean(d$genetic_diversity[keep], na.rm = TRUE),
    n_final       = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/mating_systems_ultra.rds")

viable <- tbl[tbl$verdict != "crashed", ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("asex", "sex")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf("  %-5s n=%d | pop=%.1f \u00b1 %.1f | div=%.3f \u00b1 %.3f",
                  cnd, nrow(sub),
                  mean(sub$n_agents),      sd(sub$n_agents)      / sqrt(nrow(sub)),
                  mean(sub$gen_diversity), sd(sub$gen_diversity) / sqrt(nrow(sub))))
}
asex <- viable[viable$condition == "asex", ]
sex  <- viable[viable$condition == "sex",  ]
if (nrow(asex) >= 4L && nrow(sex) >= 4L) {
  for (metric in c("n_agents", "gen_diversity")) {
    d_ <- mean(sex[[metric]]) - mean(asex[[metric]])
    se <- sqrt(var(sex[[metric]]) / nrow(sex) + var(asex[[metric]]) / nrow(asex))
    t_ <- d_ / se
    v <- if (!is.finite(t_)) "NA" else if (abs(t_) >= 2) "PASS" else "recheck"
    message(sprintf("  %-14s  \u0394(sex - asex) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, v))
  }
}
