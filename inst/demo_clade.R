# demo_clade.R ----------------------------------------------------------------
#
# Interactive demonstration of the clade evolutionary simulator.
# Run this file section-by-section in RStudio (Cmd+Enter) or source it whole:
#
#   source(system.file("demo_clade.R", package = "clade"))
#
# Requirements: Julia >= 1.9, JuliaConnectoR installed.
# First run takes ~60-90 s to compile Julia; subsequent runs start in < 5 s.
# -----------------------------------------------------------------------------

library(clade)
library(ggplot2)
library(patchwork)

# Check Julia is ready --------------------------------------------------------
if (!julia_is_ready()) stop("Julia not available. See ?julia_is_ready.")
cat("Julia", julia_version(), "ready.\n\n")


# =============================================================================
# SECTION 1: Baseline world (grass only)
# Just agents foraging on a renewable grass resource. Shows natural selection
# shaping brain weights over 300 ticks on a 20x20 toroidal grid.
# =============================================================================

cat("=== 1. Baseline world ===\n")

s1 <- default_specs()
s1$grid_rows    <- 20L
s1$grid_cols    <- 20L
s1$n_agents_init <- 40L
s1$max_agents   <- 200L
s1$max_ticks    <- 300L
s1$random_seed  <- 1L

env1 <- run_alife(s1)

# S3 print gives a one-line summary
print(env1)

# Full tidy output
data1 <- get_run_data(env1)
print(plot_run(data1))

# What parameters were used?
print_specs(s1, diff_only = TRUE)


# =============================================================================
# SECTION 2: Complex landscape - the forest world
# Three resource layers: ground (grass), shrubs (mid-layer), canopy (top).
# Agents evolve wing_size to access the energy-rich canopy.
# Shrubs regrow faster than canopy; canopy has highest energy density.
# This is the ecological scenario underlying the cephalopod paradox.
# =============================================================================

cat("\n=== 2. Complex landscape: ground + shrubs + canopy ===\n")

s2 <- default_specs()
s2$grid_rows          <- 25L
s2$grid_cols          <- 25L
s2$n_agents_init      <- 60L
s2$max_agents         <- 350L
s2$max_ticks          <- 400L
s2$random_seed        <- 42L
# Enable the forest
s2$complex_landscape  <- TRUE
s2$shrub_density      <- 0.35
s2$shrub_energy       <- 25.0
s2$shrub_growth_rate  <- 0.04
s2$canopy_density     <- 0.15
s2$canopy_energy      <- 55.0
s2$canopy_growth_rate <- 0.005
s2$canopy_threshold   <- 0.6     # wing_size >= 0.6 grants canopy access
# Wing size evolves freely
s2$wing_size_init_mean    <- 0.1
s2$wing_size_mutation_sd  <- 0.05

env2 <- run_alife(s2)
summary(env2)   # shows wing_size final mean

data2 <- get_run_data(env2)

# Population and niche use over time
p2a <- ggplot(data2$ticks, aes(t)) +
  geom_line(aes(y = n_ground_agents,  colour = "Ground"),  linewidth = 0.8) +
  geom_line(aes(y = n_shrub_agents,   colour = "Shrubs"),  linewidth = 0.8) +
  geom_line(aes(y = n_canopy_agents,  colour = "Canopy"),  linewidth = 0.8) +
  scale_colour_manual(values = c(Ground = "#8c510a", Shrubs = "#74c476",
                                  Canopy = "#2171b5"),
                       name = "Layer") +
  labs(title = "Niche use over time", x = "Tick", y = "Agents per layer") +
  theme_minimal()

p2b <- ggplot(data2$ticks, aes(t, mean_wing_size)) +
  geom_line(colour = "#2171b5", linewidth = 1) +
  labs(title = "Wing size evolution", x = "Tick",
       y = "Mean wing size") +
  theme_minimal()

p2c <- ggplot(data2$ticks, aes(t)) +
  geom_line(aes(y = mean_shrub_coverage, colour = "Shrub"),  linewidth = 0.8) +
  geom_line(aes(y = mean_canopy_coverage, colour = "Canopy"), linewidth = 0.8) +
  scale_colour_manual(values = c(Shrub = "#74c476", Canopy = "#2171b5"),
                       name = NULL) +
  labs(title = "Resource coverage", x = "Tick", y = "Mean coverage") +
  theme_minimal()

print((p2a | p2b) / p2c)


# =============================================================================
# SECTION 3: Spatial sorting (Shine et al. 2011)
# At an invasion front, high-dispersal individuals co-occur with other
# high-dispersal individuals through spatial assortment -- not because they
# have higher LRS. This causes dispersal-enhancing alleles to "surf the wave."
# =============================================================================

cat("\n=== 3. Spatial sorting ===\n")

s3 <- default_specs()
s3$grid_rows              <- 30L
s3$grid_cols              <- 30L
s3$n_agents_init          <- 50L
s3$max_agents             <- 400L
s3$max_ticks              <- 400L
s3$random_seed            <- 7L
s3$dispersal_evolution    <- TRUE
s3$dispersal_init_mean    <- 0.3
s3$dispersal_mutation_sd  <- 0.04
# Enable spatial sorting
s3$spatial_sorting        <- TRUE
s3$sorting_front_threshold <- 0.75
s3$sorting_mating_boost   <- 3.0

env3 <- run_alife(s3)
data3 <- get_run_data(env3)

p3 <- ggplot(data3$ticks, aes(t)) +
  geom_line(aes(y = mean_front_dispersal, colour = "Front agents"),
            linewidth = 1) +
  geom_line(aes(y = mean_rear_dispersal,  colour = "Rear agents"),
            linewidth = 1, linetype = "dashed") +
  scale_colour_manual(values = c("Front agents" = "#e41a1c",
                                  "Rear agents"  = "#377eb8"),
                       name = NULL) +
  labs(title = "Spatial sorting: dispersal diverges between front and rear",
       subtitle = "Front agents evolve higher dispersal tendency (Shine et al. 2011)",
       x = "Tick", y = "Mean dispersal tendency") +
  theme_minimal()

print(p3)


# =============================================================================
# SECTION 4: IFfolk inclusive fitness + parliament suppression
# Agents maximise IFfolk = own_offspring + sum(r * relative's_offspring).
# Parliament suppression: defectors (low helper_tendency) are penalised
# when surrounded by cooperators -- the "parliament of genes" enforcing
# cooperation (Fromhage & Jennions 2019).
# =============================================================================

cat("\n=== 4. IFfolk inclusive fitness ===\n")

s4 <- default_specs()
s4$grid_rows               <- 20L
s4$grid_cols               <- 20L
s4$n_agents_init           <- 50L
s4$max_agents              <- 300L
s4$max_ticks               <- 400L
s4$random_seed             <- 13L
s4$cooperative_breeding    <- TRUE   # activates helper_tendency trait
s4$helper_tendency_init_mean <- 0.2
# IFfolk
s4$iffolk_selection        <- TRUE
s4$iffolk_r_min            <- 0.125  # cousins and closer
s4$iffolk_radius           <- 5L
s4$iffolk_transfer         <- 3.0
s4$iffolk_min_energy       <- 60.0
# Parliament suppression
s4$parliament_suppression  <- TRUE
s4$parliament_cost         <- 0.5

env4 <- run_alife(s4)
data4 <- get_run_data(env4)

p4a <- ggplot(data4$ticks, aes(t, mean_helper_tendency)) +
  geom_line(colour = "#4dac26", linewidth = 1) +
  labs(title = "Helper tendency evolves upward under IFfolk + parliament",
       x = "Tick", y = "Mean helper tendency") +
  theme_minimal()

p4b <- ggplot(data4$ticks, aes(t, n_iffolk_transfers)) +
  geom_line(colour = "#d01c8b", linewidth = 0.8) +
  labs(title = "IFfolk energy transfers per tick",
       x = "Tick", y = "Transfers") +
  theme_minimal()

print(p4a | p4b)


# =============================================================================
# SECTION 5: Custom module API
# Register a module that logs which agents are in the top energy quartile.
# Modules run at user-defined hook points and can modify any agent field.
# =============================================================================

cat("\n=== 5. Custom module API ===\n")

# Track how many agents are in the top energy quartile each tick
top_quartile_counts <- integer(0)

register_module(
  function(snap) {
    energies <- vapply(snap$agents, function(ag) ag$energy, numeric(1))
    q75 <- quantile(energies, 0.75)
    top_quartile_counts <<- c(top_quartile_counts,
                               sum(energies >= q75))
    snap
  },
  when = "post_tick",
  name = "top_quartile_tracker"
)

cat("Registered modules:\n")
print(list_modules())

s5 <- default_specs()
s5$grid_rows    <- 15L
s5$grid_cols    <- 15L
s5$n_agents_init <- 30L
s5$max_ticks    <- 100L
s5$random_seed  <- 99L

env5 <- run_alife(s5)
clear_modules()

cat(sprintf("Custom module recorded %d ticks; mean top-quartile size = %.1f\n",
            length(top_quartile_counts),
            if (length(top_quartile_counts)) mean(top_quartile_counts) else NA))


# =============================================================================
# SECTION 6: Evolution of bad science (no Julia required)
# Smaldino & McElreath (2016): publication pressure selects for low research
# effort, raising the false-positive rate over evolutionary time.
# Replication slows but does not stop the deterioration.
# =============================================================================

cat("\n=== 6. Evolution of bad science ===\n")

rep_rates  <- c(0.0, 0.1, 0.5)
rep_labels <- c("No replication", "10% replication", "50% replication")

bs_list <- mapply(function(rr, lab) {
  df      <- run_bad_science(n_ticks = 500L, replication_rate = rr, seed = 1L)
  df$rate <- lab
  df
}, rep_rates, rep_labels, SIMPLIFY = FALSE)

df_bs <- do.call(rbind, bs_list)
df_bs$rate <- factor(df_bs$rate, levels = rev(rep_labels))

bs_cols <- c("No replication"  = "#d73027",
             "10% replication" = "#fc8d59",
             "50% replication" = "#4575b4")

p6a <- ggplot(df_bs, aes(t, mean_fpr, colour = rate)) +
  geom_line(linewidth = 0.9) +
  scale_colour_manual(values = bs_cols, name = NULL) +
  labs(title = "False-positive rate rises under publication pressure",
       x = "Tick", y = "Mean FPR") +
  theme_minimal()

p6b <- ggplot(df_bs, aes(t, mean_effort, colour = rate)) +
  geom_line(linewidth = 0.9) +
  scale_colour_manual(values = bs_cols, name = NULL) +
  labs(title = "Research effort declines",
       x = "Tick", y = "Mean effort") +
  theme_minimal()

print(p6a / p6b + plot_layout(guides = "collect") &
        theme(legend.position = "bottom"))


# =============================================================================
# SECTION 7: Kitchen-sink forest world
# Combines: complex landscape + dispersal evolution + spatial sorting +
#            IFfolk + kin selection + body size evolution
# Shows all new modules running simultaneously.
# =============================================================================

cat("\n=== 7. Kitchen-sink forest world ===\n")

s7 <- default_specs()
s7$grid_rows              <- 30L
s7$grid_cols              <- 30L
s7$n_agents_init          <- 80L
s7$max_agents             <- 500L
s7$max_ticks              <- 500L
s7$random_seed            <- 77L
# Forest
s7$complex_landscape      <- TRUE
s7$shrub_density          <- 0.3
s7$shrub_energy           <- 25.0
s7$canopy_density         <- 0.12
s7$canopy_energy          <- 50.0
s7$wing_size_init_mean    <- 0.1
s7$wing_size_mutation_sd  <- 0.04
# Dispersal + spatial sorting
s7$dispersal_evolution    <- TRUE
s7$dispersal_init_mean    <- 0.2
s7$spatial_sorting        <- TRUE
s7$sorting_mating_boost   <- 3.0
# IFfolk
s7$iffolk_selection       <- TRUE
s7$parliament_suppression <- TRUE
s7$cooperative_breeding   <- TRUE
# Kin selection
s7$kin_selection          <- TRUE
# Body size
s7$body_size_evolution    <- TRUE
s7$body_size_init_mean    <- 1.0

env7 <- run_alife(s7)
summary(env7)

data7 <- get_run_data(env7)
print(plot_run(data7))

# Trait trajectories for the new modules
p7 <- ggplot(data7$ticks, aes(t)) +
  geom_line(aes(y = mean_wing_size,          colour = "Wing size"),
            linewidth = 0.8) +
  geom_line(aes(y = mean_front_dispersal,    colour = "Dispersal (front)"),
            linewidth = 0.8) +
  geom_line(aes(y = mean_helper_tendency,    colour = "Helper tendency"),
            linewidth = 0.8) +
  scale_colour_manual(
    values = c("Wing size"        = "#2171b5",
               "Dispersal (front)"= "#e41a1c",
               "Helper tendency"  = "#4dac26"),
    name = NULL
  ) +
  labs(title = "New-module trait trajectories in the kitchen-sink run",
       x = "Tick", y = "Trait value") +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p7)

cat("\n=== Demo complete ===\n")
cat("Objects in workspace: env1, env2, env3, env4, env5, env7\n")
cat("Use summary(envN), get_run_data(envN), plot_run(get_run_data(envN))\n")
cat("Try print_specs(s7, diff_only = TRUE) to inspect the kitchen-sink params.\n")
