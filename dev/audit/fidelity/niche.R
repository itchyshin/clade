#!/usr/bin/env Rscript
# Fidelity audit: niche construction (Odling-Smee et al. 2003).
# Prediction: shelter building is positive; occupancy bonus provides
#            heritable energetic benefit.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(niche, bonus, seed, max_ticks = 400L) {
  s <- default_specs()
  s$niche_construction     <- niche
  s$shelter_occupancy_bonus <- bonus
  s$n_predators_init       <- 10L
  s$predator_attack_strength <- 50
  s$predator_max_agents    <- 30L
  s$n_agents_init          <- 100L
  s$grid_rows              <- 30L; s$grid_cols <- 30L
  s$grass_rate             <- 0.12
  s$max_agents             <- 400L
  s$max_ticks              <- as.integer(max_ticks)
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$niche <- niche; d$bonus <- bonus; d$seed <- seed
  d
}

seeds <- 1L:3L
cat("── niche construction with/without bonus (3 seeds, 400 ticks)\n")
base <- lapply(seeds, function(sd) one_run(FALSE, 0, sd))
nc <- lapply(seeds, function(sd) one_run(TRUE, 0, sd))
nc_bonus <- lapply(seeds, function(sd) one_run(TRUE, 0.3, sd))

summarise_cond <- function(runs, label) {
  d <- do.call(rbind, runs)
  post <- d[d$t > 100, ]
  cat(sprintf("  %s: n=%.0f  shelters=%d  grass_cov=%.2f\n",
              label,
              mean(aggregate(n_agents ~ seed, post, mean)$n_agents),
              sum(post$n_shelters_built, na.rm = TRUE),
              mean(post$grass_coverage)))
  list(n = mean(post$n_agents),
       shelters = sum(post$n_shelters_built, na.rm = TRUE))
}
s_base  <- summarise_cond(base,  "baseline")
s_nc    <- summarise_cond(nc,    "niche_con (bonus=0)")
s_nc_b  <- summarise_cond(nc_bonus, "niche_con (bonus=0.3)")

p1_pass <- s_nc$shelters > 100
p2_pass <- s_nc_b$n > s_nc$n
cat(sprintf("\nP1 (shelters built): %s (%d)\n",
            if (p1_pass) "PASS" else "FAIL", s_nc$shelters))
cat(sprintf("P2 (occupancy_bonus raises pop vs no-bonus NC): %s (Δ=%+.1f)\n",
            if (p2_pass) "PASS" else "FAIL", s_nc_b$n - s_nc$n))

all_ticks <- do.call(rbind, c(base, nc, nc_bonus))
all_ticks$cond <- ifelse(!all_ticks$niche, "baseline",
                          ifelse(all_ticks$bonus > 0, "nc+bonus", "nc"))
saveRDS(all_ticks, "dev/audit/fidelity/niche_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, n_agents, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  labs(title = "Niche construction ± occupancy_bonus (Odling-Smee et al. 2003)",
       subtitle = sprintf("3 seeds × 400 ticks. Baseline n=%.0f, NC=%.0f, NC+bonus=%.0f",
                          s_base$n, s_nc$n, s_nc_b$n),
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/niche.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/niche.png\n")
