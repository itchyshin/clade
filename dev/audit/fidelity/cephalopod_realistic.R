# s-cephalopod promotion attempt: NA → quantitative claim.
#
# Latent claim (Liedtke & Fromhage 2019): evolved mean learning rate
# should be HIGHEST at short lifespans, decline as lifespan increases.
# Short-lived agents cannot wait for genetic evolution to encode food-
# finding solutions, so within-lifetime learning is the only viable
# mechanism.
#
# Tested: max_age ∈ {30, 50, 100, 200} × 5 seeds × 5000 ticks at
# realistic_specs() scale. Pearson correlation between max_age and
# mean_learning_rate should be NEGATIVE with |r| large enough to
# survive seed noise.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS     <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L, 51L, 57L)
LIFESPANS <- c(30L, 50L, 100L, 200L)

build_spec <- function(ma, seed) {
  s <- realistic_specs()
  s$max_age                 <- ma
  s$complex_landscape       <- TRUE   # heterogeneous resources reward learning
  s$learning_rate_evolution <- TRUE
  s$learning_rate_init_mean <- 0.05
  s$rl_mode                 <- "actor_critic"
  s$random_seed             <- as.integer(seed)
  s
}

specs_list <- list()
for (ma in LIFESPANS) for (sd in SEEDS) {
  specs_list[[length(specs_list) + 1L]] <- build_spec(ma, sd)
}
message(sprintf("Built %d specs (%d lifespans x %d seeds)",
                length(specs_list), length(LIFESPANS), length(SEEDS)))

t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = length(specs_list))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  keep <- d$t >= 4000
  data.frame(
    max_age       = specs_list[[i]]$max_age,
    seed          = specs_list[[i]]$random_seed,
    verdict       = via$verdict,
    n_agents_eq   = mean(d$n_agents[keep],          na.rm = TRUE),
    mean_lr_final = tail(d$mean_learning_rate, 1L),
    mean_energy   = mean(d$mean_energy[keep],       na.rm = TRUE),
    n_final       = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/cephalopod_realistic.rds")

message("\n── Viability ──")
with(tbl, print(table(max_age, verdict)))

viable <- tbl[tbl$verdict != "crashed" & !is.na(tbl$mean_lr_final), ]
message("\n── Per-lifespan summary (viable, mean_lr_final) ──")
for (ma in LIFESPANS) {
  sub <- viable[viable$max_age == ma, ]
  if (nrow(sub) == 0L) {
    message(sprintf("  max_age=%3d | n=0 | all crashed", ma))
    next
  }
  message(sprintf(
    "  max_age=%3d | n=%d | mean_lr=%.4f ± %.4f | pop=%.0f ± %.0f",
    ma, nrow(sub),
    mean(sub$mean_lr_final), sd(sub$mean_lr_final) / sqrt(nrow(sub)),
    mean(sub$n_agents_eq),   sd(sub$n_agents_eq)   / sqrt(nrow(sub))))
}

# Slope test: mean_lr_final ~ max_age
if (nrow(viable) >= 4L && length(unique(viable$max_age)) >= 3L) {
  m <- lm(mean_lr_final ~ max_age, data = viable)
  s <- summary(m)
  slope <- s$coefficients["max_age", "Estimate"]
  se    <- s$coefficients["max_age", "Std. Error"]
  tval  <- s$coefficients["max_age", "t value"]
  message(sprintf(
    "\n── Linear slope (mean_lr_final ~ max_age) ──\n  slope = %+7.2e ± %.2e | t = %+5.2f | %s",
    slope, se, tval,
    if (slope < 0 && abs(tval) >= 2) "PASS — short lifespan selects for faster learning"
    else                             "recheck"))
}
