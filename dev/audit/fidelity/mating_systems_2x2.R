# s-mating-systems — 2x2 Red Queen differential.
#
# Single-factor sex-vs-asex is confounded by sex's intrinsic cost
# (two-parent requirement). A 2x2 design (parasites on/off × sex/asex)
# isolates the Red Queen effect:
#   Red Queen benefit = (sex_parasites - sex_no_parasites)
#                     - (asex_parasites - asex_no_parasites)
# i.e. does sex handle parasites BETTER than asex handles them?
# This is the Hamilton 1980 claim, independent of sex's total viability.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L,
           113L, 121L, 131L, 139L, 149L, 157L, 163L, 173L,
           179L, 191L, 197L, 211L, 223L, 227L, 239L, 251L)

build_spec <- function(ploidy, parasites, seed) {
  s <- realistic_specs()
  s$ploidy                        <- as.integer(ploidy)
  s$crossover_rate                <- if (ploidy == 2L) 0.5 else 0.0
  s$mate_search_radius            <- 1L
  s$parental_investment_evolution <- TRUE
  s$female_investment             <- 0.5   # equalise cost per offspring
  if (parasites) {
    s$coevolving_parasites         <- TRUE
    s$n_parasite_loci              <- 16L
    s$parasite_pressure            <- 2.0
    s$parasite_discrete_exponent   <- 6.0
    s$parasite_mutation_rate       <- 0.02
  }
  s$random_seed                   <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(1L, FALSE, sd)),  # asex, no parasites
  lapply(SEEDS, function(sd) build_spec(1L, TRUE,  sd)),  # asex, parasites
  lapply(SEEDS, function(sd) build_spec(2L, FALSE, sd)),  # sex,  no parasites
  lapply(SEEDS, function(sd) build_spec(2L, TRUE,  sd))   # sex,  parasites
)
conditions <- c(rep("asex_noP",  length(SEEDS)),
                rep("asex_P",    length(SEEDS)),
                rep("sex_noP",   length(SEEDS)),
                rep("sex_P",     length(SEEDS)))

message(sprintf("Running %d specs (4 conditions × 16 seeds)...",
                length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 64L)
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  keep <- d$t >= 1500
  data.frame(
    condition = conditions[i],
    seed      = specs_list[[i]]$random_seed,
    verdict   = via$verdict,
    n_agents  = mean(d$n_agents[keep],          na.rm = TRUE),
    diversity = mean(d$genetic_diversity[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/mating_systems_2x2.rds")

message("\n── Viability ──")
with(tbl, print(table(condition, verdict)))

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]
message("\n── Per-condition summary ──")
for (cnd in c("asex_noP", "asex_P", "sex_noP", "sex_P")) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) {
    message(sprintf("  %-9s n=0 (all crashed or weak)", cnd))
  } else {
    message(sprintf("  %-9s n=%d | pop=%.1f \u00b1 %.1f | div=%.3f \u00b1 %.3f",
                    cnd, nrow(sub),
                    mean(sub$n_agents),  sd(sub$n_agents)  / sqrt(nrow(sub)),
                    mean(sub$diversity), sd(sub$diversity) / sqrt(nrow(sub))))
  }
}

# Hamilton 1980 differential:
#   parasite_cost_asex = asex_noP - asex_P  (how much parasites hurt asex)
#   parasite_cost_sex  = sex_noP  - sex_P   (how much parasites hurt sex)
#   RQ_benefit = parasite_cost_asex - parasite_cost_sex
#              > 0 means sex handles parasites better than asex.
get_stats <- function(cnd, metric) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) return(c(mean = NA_real_, se = NA_real_, n = 0L))
  c(mean = mean(sub[[metric]]),
    se   = sd(sub[[metric]]) / sqrt(nrow(sub)),
    n    = nrow(sub))
}
for (metric in c("n_agents", "diversity")) {
  an <- get_stats("asex_noP", metric)
  ap <- get_stats("asex_P",   metric)
  sn <- get_stats("sex_noP",  metric)
  sp <- get_stats("sex_P",    metric)
  asex_cost <- an["mean"] - ap["mean"]
  sex_cost  <- sn["mean"] - sp["mean"]
  rq        <- asex_cost - sex_cost
  # Variance of (A - B) - (C - D) = var(A) + var(B) + var(C) + var(D)
  # when samples are independent (different seeds/conditions).
  rq_se <- sqrt(an["se"]^2 + ap["se"]^2 + sn["se"]^2 + sp["se"]^2)
  t_rq  <- rq / rq_se
  v <- if (!is.finite(t_rq))     "NA"
       else if (rq > 0 && abs(t_rq) >= 2) "PASS \u2014 Red Queen direction confirmed"
       else if (abs(t_rq) >= 2)           "PASS (wrong direction)"
       else                                "direction-correct-but-sub-2\u03c3"
  message(sprintf(
    "  %-10s  asex_parasite_cost=%+.3f | sex_parasite_cost=%+.3f",
    metric, asex_cost, sex_cost))
  message(sprintf(
    "              RQ_benefit = %+.3f \u00b1 %.3f   t = %+.2f   %s",
    rq, rq_se, t_rq, v))
}
