# QoL utilities: print_specs, S3 methods for clade_env

# print_specs() ---------------------------------------------------------------

#' Pretty-print all simulation parameters
#'
#' Prints every parameter in a [default_specs()] list with its current value,
#' grouped by biological theme. Pass a modified specs list to see which
#' parameters differ from the defaults.
#'
#' @param specs A named list of simulation parameters (from [default_specs()]).
#'   If `NULL` (default), prints the unmodified defaults.
#' @param diff_only Logical. If `TRUE`, only print parameters that differ from
#'   [default_specs()] defaults. Useful for inspecting a customised spec list.
#'   Default `FALSE`.
#'
#' @return Invisibly, the `specs` list (for piping).
#'
#' @examples
#' print_specs()
#'
#' s <- default_specs()
#' s$kin_selection <- TRUE
#' s$complex_landscape <- TRUE
#' print_specs(s, diff_only = TRUE)
#'
#' @export
print_specs <- function(specs = NULL, diff_only = FALSE) {
  defs <- default_specs()
  if (is.null(specs)) specs <- defs

  groups <- list(
    "Grid & population"     = c("grid_rows", "grid_cols", "n_agents_init",
                                 "max_agents", "max_ticks", "random_seed"),
    "Energy & metabolism"   = c("energy_init", "energy_max", "move_cost",
                                 "idle_cost", "eat_gain", "min_repro_energy",
                                 "repro_cost", "offspring_energy",
                                 "starvation_threshold"),
    "Grass dynamics"        = c("grass_init_prob", "grass_rate", "grass_max"),
    "Brain architecture"    = c("brain_type", "hidden_layers", "n_inputs",
                                 "n_outputs"),
    "Reproduction & sex"    = c("ploidy", "sex_ratio", "mating_system",
                                 "mutation_sd", "crossover_rate",
                                 "min_repro_age", "max_repro_age"),
    "Life history"          = c("max_age", "life_history", "senescence_rate",
                                 "repro_senescence"),
    "Body size"             = c("body_size_evolution", "body_size_init_mean",
                                 "body_size_mutation_sd", "body_size_min",
                                 "body_size_max"),
    "Dispersal"             = c("dispersal_evolution", "dispersal_init_mean",
                                 "dispersal_mutation_sd", "dispersal_min",
                                 "dispersal_max"),
    "Kin selection"         = c("kin_selection", "kin_altruism_r_min",
                                 "kin_altruism_cost",
                                 "kin_altruism_min_donor_energy"),
    "Disease (SIR)"         = c("disease", "transmission_prob",
                                 "disease_duration", "disease_energy_cost",
                                 "disease_death_prob", "immune_duration",
                                 "disease_seed_prob"),
    "Predators"             = c("n_predators_init", "predator_energy_init",
                                 "predator_attack_strength",
                                 "predator_min_repro_energy",
                                 "predator_max_agents"),
    "Niche construction"    = c("niche_construction", "shelter_build_prob",
                                 "shelter_min_energy", "shelter_max_depth",
                                 "shelter_decay_rate"),
    "Within-lifetime RL"    = c("rl_mode", "learning_rate",
                                 "learning_rate_evolution",
                                 "rl_update_freq"),
    "Social learning"       = c("social_learning", "social_learning_freq",
                                 "social_learning_radius"),
    "Signals & mate choice" = c("signal_dims", "signal_mutation_sd",
                                 "preference_mutation_sd"),
    "Mimicry & toxicity"    = c("mimicry", "toxicity_init_mean",
                                 "toxin_dose", "signal_memory"),
    "Parental care"         = c("parental_care", "juvenile_independence_age",
                                 "juvenile_independence_energy",
                                 "care_cost_per_tick", "feeding_rate"),
    "Cooperative breeding"  = c("cooperative_breeding",
                                 "helper_tendency_init_mean",
                                 "helper_tendency_mutation_sd"),
    "Phenotypic plasticity" = c("phenotypic_plasticity",
                                 "plasticity_init_mean",
                                 "plasticity_mutation_sd"),
    "Spatial sorting"       = c("spatial_sorting", "sorting_front_threshold",
                                 "sorting_mating_boost"),
    "IFfolk incl. fitness"  = c("iffolk_selection", "iffolk_r_min",
                                 "iffolk_radius", "iffolk_transfer",
                                 "iffolk_min_energy",
                                 "parliament_suppression", "parliament_cost"),
    "Complex landscape"     = c("complex_landscape", "shrub_density",
                                 "shrub_growth_rate", "shrub_energy",
                                 "canopy_density", "canopy_growth_rate",
                                 "canopy_energy", "canopy_threshold",
                                 "wing_size_init_mean", "wing_size_mutation_sd",
                                 "wing_size_min", "wing_size_max"),
    "Logging & search"      = c("log_genomes", "log_deaths",
                                 "log_freq", "verbose_julia")
  )

  # Collect all grouped names; any remaining go into "Other"
  grouped_names <- unlist(groups, use.names = FALSE)
  other <- setdiff(names(specs), grouped_names)
  if (length(other)) groups[["Other"]] <- other

  changed <- if (diff_only) {
    names(specs)[vapply(names(specs), function(nm) {
      !identical(specs[[nm]], defs[[nm]])
    }, logical(1L))]
  } else {
    NULL
  }

  cat(sprintf("-- clade specs (%d parameters) %s--\n",
              length(specs),
              if (diff_only) "[diff only] " else ""))

  for (grp in names(groups)) {
    keys <- intersect(groups[[grp]], names(specs))
    if (diff_only) keys <- intersect(keys, changed)
    if (!length(keys)) next

    cat(sprintf("\n  %s\n", grp))
    for (k in keys) {
      v <- specs[[k]]
      vs <- if (is.logical(v))     toupper(as.character(v))
            else if (length(v) > 6) sprintf("[%s ...]", paste(head(v, 6), collapse = ", "))
            else if (length(v) > 1) sprintf("[%s]", paste(v, collapse = ", "))
            else                    as.character(v)
      changed_flag <- if (!is.null(changed) && k %in% changed) " *" else ""
      cat(sprintf("    %-38s %s%s\n", k, vs, changed_flag))
    }
  }

  if (diff_only && !length(changed)) {
    cat("\n  (no parameters differ from defaults)\n")
  }

  invisible(specs)
}


# S3 methods for clade_env ----------------------------------------------------

#' @export
print.clade_env <- function(x, ...) {
  n_alive <- tryCatch(length(x$agents), error = function(e) NA_integer_)
  n_ticks <- x$t
  grid    <- paste0(x$specs$grid_rows, "\u00d7", x$specs$grid_cols)
  brain   <- x$specs$brain_type
  ploidy  <- x$specs$ploidy

  mods <- c(
    if (isTRUE(x$specs$kin_selection))         "kin",
    if (isTRUE(x$specs$disease))               "disease",
    if (isTRUE(x$specs$niche_construction))     "niche",
    if (isTRUE(x$specs$body_size_evolution))    "body_size",
    if (isTRUE(x$specs$dispersal_evolution))    "dispersal",
    if (isTRUE(x$specs$social_learning))        "soc_learn",
    if (isTRUE(x$specs$parental_care))          "care",
    if (isTRUE(x$specs$cooperative_breeding))   "coop_breed",
    if (isTRUE(x$specs$mimicry))                "mimicry",
    if (isTRUE(x$specs$phenotypic_plasticity))  "plasticity",
    if (isTRUE(x$specs$spatial_sorting))        "spatial_sort",
    if (isTRUE(x$specs$iffolk_selection))       "iffolk",
    if (isTRUE(x$specs$complex_landscape))      "complex_landscape",
    if (!identical(x$specs$rl_mode, "none"))    paste0("rl:", x$specs$rl_mode),
    if (isTRUE(x$specs$n_predators_init > 0))   "predators"
  )
  mod_str <- if (length(mods)) paste(mods, collapse = ", ") else "baseline"

  cat(sprintf(
    "<clade_env>  grid %s | %d ticks | %d agents alive\n",
    grid, n_ticks, n_alive
  ))
  cat(sprintf("  brain: %s  ploidy: %d\n", brain, ploidy))
  cat(sprintf("  modules: %s\n", mod_str))
  cat("  $progress, $agents, $specs, $grass",
      " -- use get_run_data() for tidy output\n")
  invisible(x)
}

#' @export
summary.clade_env <- function(object, ...) {
  data   <- get_run_data(object)
  ticks  <- data$ticks
  active <- ticks$n_agents > 0

  cat("<clade_env> summary\n")
  cat(sprintf("  Ticks run    : %d\n", object$t))
  cat(sprintf("  Grid         : %d\u00d7%d\n",
              object$specs$grid_rows, object$specs$grid_cols))
  cat(sprintf("  Brain        : %s  ploidy=%d\n",
              object$specs$brain_type, object$specs$ploidy))

  if (any(active)) {
    tact <- ticks[active, ]
    cat(sprintf("  Pop range    : %d to %d agents (mean %.0f)\n",
                min(tact$n_agents), max(tact$n_agents),
                mean(tact$n_agents)))
    cat(sprintf("  Mean energy  : %.1f (final 10%% mean: %.1f)\n",
                mean(tact$mean_energy),
                mean(utils::tail(tact$mean_energy,
                                  max(1L, nrow(tact) %/% 10L)))))
    if (!is.null(tact$genetic_diversity))
      cat(sprintf("  Genome div.  : %.4f (final)\n",
                  utils::tail(tact$genetic_diversity[active], 1L)))
    if (!is.null(tact$mean_body_size) &&
        isTRUE(object$specs$body_size_evolution))
      cat(sprintf("  Body size    : %.3f (final mean)\n",
                  utils::tail(tact$mean_body_size[active], 1L)))
    if (!is.null(tact$mean_wing_size) &&
        isTRUE(object$specs$complex_landscape))
      cat(sprintf("  Wing size    : %.3f (final mean)\n",
                  utils::tail(tact$mean_wing_size[active], 1L)))
    if (!is.null(tact$n_iffolk_transfers) &&
        isTRUE(object$specs$iffolk_selection))
      cat(sprintf("  IFfolk xfers : %d total\n",
                  sum(tact$n_iffolk_transfers)))
  } else {
    cat("  Population   : EXTINCT\n")
  }

  if (!is.null(data$deaths) && nrow(data$deaths) > 0L)
    cat(sprintf("  Total deaths : %d\n", nrow(data$deaths)))

  invisible(object)
}
