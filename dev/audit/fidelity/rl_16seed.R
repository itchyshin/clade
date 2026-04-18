# 16-seed re-audit of s-rl at the best cell from the 8-seed sweep
# (freq=5, lr=0.005 → Δ = +1.2, t = 1.5 — direction correct, not
# significant at 8 seeds). If t ≥ 2 at 16 seeds, the scenario promotes
# back to ✅.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

rl_make <- function(mode, seed) {
  s <- default_specs()
  s$rl_mode                 <- mode
  s$rl_update_freq          <- 5L
  s$learning_rate_init_mean <- 0.005
  s$n_agents_init           <- 80L
  s$grass_rate              <- 0.15
  s$max_ticks               <- 400L
  s$random_seed             <- as.integer(seed)
  s
}

# Build 16 × 2 = 32 specs
specs_list <- c(
  lapply(SEEDS, function(sd) rl_make("actor_critic", sd)),
  lapply(SEEDS, function(sd) rl_make("none",         sd))
)
modes <- c(rep("actor_critic", length(SEEDS)), rep("none", length(SEEDS)))

message(sprintf("Running %d specs × PSOCK cluster...", length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 32L)
message(sprintf("  batch: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  d <- get_run_data(env)$ticks
  data.frame(
    mode = modes[i], seed = specs_list[[i]]$random_seed,
    energy_last100 = mean(tail(d$mean_energy, 100L), na.rm = TRUE),
    n_final = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/rl_16seed.rds")

on  <- tbl$energy_last100[tbl$mode == "actor_critic"]
off <- tbl$energy_last100[tbl$mode == "none"]
delta <- mean(on) - mean(off)
se    <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
t_val <- delta / se

message(sprintf("\n── 16-seed s-rl at best cell (freq=5, lr=0.005) ──"))
message(sprintf("  actor_critic: %.2f ± %.2f", mean(on),  sd(on)))
message(sprintf("  none        : %.2f ± %.2f", mean(off), sd(off)))
message(sprintf("  Δ = %+.3f, SE = %.3f, t = %.2f → %s",
                delta, se, t_val,
                if (abs(t_val) >= 2) "PASS — promotes ✅" else "STILL RECHECK"))
