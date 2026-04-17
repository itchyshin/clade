# Trajectory figure for the 2×2 toroidal × complex_landscape spatial
# refugia experiment. One representative seed per condition (seed = 7)
# so the reader can see the actual cycling the oscillation scores
# quantify.
#
# Usage: Rscript dev/audit/fidelity/predator_prey_refugia_trajectory_fig.R

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

.base <- function(tor, cl, seed) {
  s <- default_specs()
  s$n_agents_init             <- 250L
  s$max_agents                <- 1000L
  s$n_predators_init          <- 25L
  s$grid_rows                 <- 50L
  s$grid_cols                 <- 50L
  s$predator_energy_gain      <- 30
  s$predator_min_repro_energy <- 50
  s$predator_max_agents       <- 250L
  s$grass_rate                <- 0.20
  s$max_ticks                 <- 800L
  s$toroidal                  <- tor
  s$complex_landscape         <- cl
  if (cl) {
    s$shrub_density  <- 0.35
    s$canopy_density <- 0.10
  }
  s$random_seed <- as.integer(seed)
  s
}

message("Running 4 representative trajectories (seed = 7, 800 ticks each)...")
conditions <- list(
  list(tor = TRUE,  cl = FALSE, label = "toroidal, flat (osc = 0.30)",
       col  = "#1f78b4"),
  list(tor = TRUE,  cl = TRUE,  label = "toroidal, patchy (osc = 0.64)",
       col  = "#33a02c"),
  list(tor = FALSE, cl = FALSE, label = "bounded, flat (osc = 0.00)",
       col  = "#e31a1c"),
  list(tor = FALSE, cl = TRUE,  label = "bounded, patchy (osc = 0.00)",
       col  = "#ff7f00")
)

df <- do.call(rbind, lapply(conditions, function(x) {
  s   <- .base(x$tor, x$cl, 7L)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  data.frame(t = d$t, n_agents = d$n_agents, n_predators = d$n_predators,
             condition = x$label)
}))
df$condition <- factor(df$condition,
                       levels = sapply(conditions, `[[`, "label"))
cols <- setNames(sapply(conditions, `[[`, "col"),
                 sapply(conditions, `[[`, "label"))

p_prey <- ggplot(df, aes(t, n_agents, colour = condition)) +
  geom_line(linewidth = 0.7, alpha = 0.9) +
  scale_colour_manual(values = cols, name = NULL) +
  facet_wrap(~ condition, ncol = 2L, scales = "fixed") +
  labs(title = "Prey trajectories across the 2×2 Huffaker audit",
       subtitle = "50×50 grid, seed 7, 800 ticks. Patchy + toroidal gives the cleanest cycling in clade.",
       x = "Tick", y = "N agents") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        strip.text = element_text(size = 10))

ggsave("inst/figures/showcase_14_predators_refugia.png",
       plot = p_prey, width = 10, height = 6, dpi = 150)
ggsave("vignettes/figures/showcase_14_predators_refugia.png",
       plot = p_prey, width = 10, height = 6, dpi = 150)

message("  saved: showcase_14_predators_refugia.png")
