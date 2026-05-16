# QoL utilities: print_specs, S3 methods for clade_env

# ── Spec groupings (single source of truth) ──────────────────────────────────
#
# Used by:
#   * `print_specs()` — interactive inspection of a specs list
#   * `.param_table()` (internal) — generates the parameter-reference vignette
#     tables from `default_specs()` introspection
#
# Order matters: vignette section order matches list order. Names that don't
# exist in `default_specs()` are silently skipped (so adding a planned-but-
# unimplemented field name here is harmless — it just won't render).
.SPEC_GROUPS <- list(
  "Grid & population"     = c("grid_rows", "grid_cols", "toroidal",
                               "random_tick_order",
                               "n_agents_init", "max_agents", "max_ticks",
                               "random_seed"),
  "Energy & metabolism"   = c("energy_init", "energy_max", "move_cost",
                               "idle_cost", "eat_gain", "max_bite",
                               "min_repro_energy", "repro_cost_mode",
                               "repro_cost", "repro_cost_fraction",
                               "offspring_energy_mode", "offspring_energy",
                               "offspring_energy_fraction",
                               "starvation_threshold"),
  "Grass dynamics"        = c("grass_init_prob", "grass_rate", "grass_max"),
  "Brain architecture"    = c("brain_type", "hidden_layers", "input_radius",
                               "n_genes", "transformer_history",
                               "transformer_heads", "synthesis_max_rules",
                               "ann_weight_values",
                               "ann_regularization_lambda",
                               "bnn_sigma_source", "bnn_sigma_init",
                               "bnn_sigma_min", "bnn_sample_freq",
                               "bnn_sigma_lr_scale", "bnn_sigma_lr_ref",
                               "bnn_action_noise_scale",
                               "action_exploration_epsilon"),
  "Brain metabolic cost"  = c("brain_energy_mode", "brain_energy_base",
                               "brain_energy_activity",
                               "brain_energy_sigma_scale",
                               "brain_energy_size_exponent",
                               "brain_size_cost_scale"),
  "Reproduction & sex"    = c("ploidy", "mate_choice_mode",
                               "mate_choice_strength", "mutation_sd",
                               "crossover_rate", "min_repro_age",
                               "n_chromosomes", "dominance_model",
                               "mate_search_radius",
                               "self_fertilization_fallback"),
  "Life history"          = c("max_age", "life_history", "senescence_rate",
                               "senescence_shape", "allee_threshold",
                               "max_age_scales_with_metabolism"),
  "Body size"             = c("body_size_evolution", "body_size_init_mean",
                               "body_size_mutation_sd", "body_size_min",
                               "body_size_max"),
  "Brain size evolution"  = c("brain_size_evolution", "brain_size_init_mean",
                               "brain_size_mutation_sd", "brain_size_min",
                               "brain_size_max",
                               "brain_size_sensing_exponent"),
  "Dispersal"             = c("dispersal_evolution", "dispersal_init_mean",
                               "dispersal_mutation_sd", "dispersal_min",
                               "dispersal_max", "dispersal_cost"),
  "Habitat preference"    = c("habitat_preference_evolution",
                               "habitat_preference_init_mean",
                               "habitat_preference_mutation_sd",
                               "habitat_preference_min",
                               "habitat_preference_max",
                               "habitat_preference_strength",
                               "habitat_move_cost"),
  "Kin selection"         = c("kin_selection", "kin_altruism_r_min",
                               "kin_altruism_cost", "kin_altruism_benefit",
                               "kin_altruism_min_donor_energy"),
  "Cooperation (PGG)"     = c("cooperation_evolution", "cooperation_multiplier",
                               "cooperation_init_mean",
                               "cooperation_mutation_sd", "cooperation_cost"),
  "Disease (SIR)"         = c("disease", "transmission_prob",
                               "disease_duration", "disease_energy_cost",
                               "disease_death_prob", "immune_duration",
                               "disease_seed_prob",
                               "immune_evolution", "immune_strength_init_mean",
                               "immune_strength_mutation_sd",
                               "immune_strength_min", "immune_strength_max"),
  "Predators"             = c("n_predators_init", "predator_energy_init",
                               "predator_live_energy",
                               "predator_attack_strength",
                               "predator_energy_gain",
                               "predator_min_repro_energy",
                               "predator_min_repro_age",
                               "predator_mutation_sd",
                               "predator_max_agents", "predator_max_age",
                               "predator_sense_graded",
                               "predator_move_energy"),
  "Group defense"         = c("group_defense", "group_defense_radius",
                               "group_defense_strength"),
  "Niche construction"    = c("niche_construction", "shelter_build_prob",
                               "shelter_min_energy", "shelter_max_depth",
                               "shelter_decay_prob",
                               "shelter_occupancy_bonus"),
  "Within-lifetime RL"    = c("rl_mode", "learning_rate",
                               "learning_rate_init_mean",
                               "learning_rate_min", "learning_rate_max",
                               "learning_rate_evolution",
                               "plasticity_cost", "rl_update_freq",
                               "lamarckian"),
  "Social learning"       = c("social_learning", "social_learning_freq",
                               "social_learning_rate"),
  "Signals & mate choice" = c("signal_dims", "signal_cost",
                               "signal_cost_mortality",
                               "signal_evolution_drift",
                               "signal_drift_sd",
                               "preference_bias_target",
                               "preference_bias_strength",
                               "signal_toxicity_coupling"),
  "Mimicry & toxicity"    = c("mimicry", "batesian_mimicry",
                               "toxicity_init_mean", "toxicity_mutation_sd",
                               "toxicity_cost_per_tick", "toxin_dose",
                               "signal_memory_rate", "avoid_threshold"),
  "Coevolving parasites"  = c("coevolving_parasites", "parasite_match_mode",
                               "parasite_virulence_rate",
                               "parasite_pressure",
                               "parasite_distance_scale",
                               "n_parasite_loci",
                               "parasite_mutation_rate",
                               "parasite_discrete_exponent"),
  "Parental care"         = c("parental_care", "juvenile_independence_age",
                               "juvenile_independence_energy",
                               "care_cost_per_tick", "feeding_rate",
                               "max_clutch_size",
                               "neonatal_foraging_deficit",
                               "neonatal_deficit_duration"),
  "Cooperative breeding"  = c("cooperative_breeding",
                               "helper_min_energy", "helper_transfer",
                               "helper_kin_threshold",
                               "helper_tendency_init_mean",
                               "helper_tendency_mutation_sd"),
  "Parental investment"   = c("parental_investment_evolution",
                               "female_investment", "male_repro_cost"),
  "Pace of life"          = c("metabolic_rate_evolution",
                               "metabolic_rate_init_mean",
                               "metabolic_rate_mutation_sd",
                               "metabolic_rate_min", "metabolic_rate_max",
                               "aging_rate_evolution",
                               "aging_rate_init_mean",
                               "aging_rate_mutation_sd",
                               "aging_rate_min", "aging_rate_max"),
  "Mutation-rate evol."   = c("mutation_rate_evolution",
                               "mutation_sd_init_mean",
                               "mutation_sd_min", "mutation_sd_max"),
  "Phenotypic plasticity" = c("phenotypic_plasticity",
                               "plasticity_sense_radius",
                               "plasticity_init_mean",
                               "plasticity_mutation_sd",
                               "plasticity_min", "plasticity_max"),
  "Stress hypermutation"  = c("stress_hypermutation",
                               "stress_mutation_multiplier",
                               "stress_threshold"),
  "Clutch size (r/K)"     = c("clutch_size_evolution",
                               "clutch_size_init_mean",
                               "clutch_size_min", "clutch_size_max",
                               "clutch_size_mutation_sd"),
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
  "Fixed patch"           = c("fixed_patch", "fixed_patch_value",
                               "fixed_patch_x", "fixed_patch_y",
                               "fixed_patch_radius"),
  "Epigenetics"           = c("epigenetics", "epigenetic_learning_coupling",
                               "epigenetic_inheritance",
                               "epigenetic_effect_size", "methylation_rate",
                               "demethylation_rate"),
  "Speciation"            = c("speciation", "isolation_threshold",
                               "speciation_cluster_interval"),
  "Seasonal dynamics"     = c("seasonal_amplitude", "season_length",
                               "seasonal_spatial_bias", "winter_death_prob"),
  "Scavenging"            = c("scavenging",
                               "carrion_fraction", "carrion_decay_rate",
                               "carrion_eat_gain",
                               "carrion_transmission_prob"),
  "ANN regularisation"    = c("ann_regularization"),
  "Wolf 2007 personality" = c("personality_syndrome", "personality_beta",
                               "personality_alpha", "personality_f_high",
                               "personality_f_low", "personality_b",
                               "personality_gamma", "personality_V",
                               "personality_delta",
                               "personality_antipred_per_tick",
                               "personality_hawkdove_per_tick",
                               "personality_hawkdove_radius",
                               "wolf_year1_repro_age",
                               "wolf_year2_repro_age",
                               "exploration_init_mean",
                               "exploration_mutation_sd",
                               "boldness_init_mean",
                               "boldness_mutation_sd",
                               "aggressiveness_init_mean",
                               "aggressiveness_mutation_sd"),
  "Trivers 1971 reciprocity" = c("reciprocal_altruism", "reciprocity_cost",
                                  "reciprocity_benefit_ratio",
                                  "reciprocity_interaction_rate",
                                  "reciprocity_radius",
                                  "partner_memory_size",
                                  "reciprocity_initial_init_mean",
                                  "reciprocity_initial_mutation_sd",
                                  "reciprocity_retaliation_init_mean",
                                  "reciprocity_retaliation_mutation_sd",
                                  "reciprocity_forgiveness_init_mean",
                                  "reciprocity_forgiveness_mutation_sd"),
  "Wolf 2008 responsive"  = c("responsive_personalities",
                               "responsiveness_cost",
                               "responsiveness_init_mean",
                               "responsiveness_mutation_sd"),
  "Logging & search"      = c("log_genomes", "log_freq")
)

# Internal: describe the type of a spec value as a short human-readable label.
.spec_type_label <- function(v) {
  if (is.null(v))         return("NULL")
  if (is.logical(v))      return("logical")
  if (is.character(v))    return(if (length(v) > 1L) "character vector" else "character")
  if (is.integer(v))      return(if (length(v) > 1L) "integer vector"   else "integer")
  if (is.double(v))       return(if (length(v) > 1L) "numeric vector"   else "numeric")
  if (is.list(v))         return("list")
  typeof(v)
}

# Internal: format a spec value for display.
.spec_value_format <- function(v) {
  if (is.null(v))                          return("NULL")
  if (length(v) == 0L)                     return(sprintf("%s(0)", typeof(v)))
  if (is.logical(v))                       return(toupper(as.character(v[1L])))
  if (length(v) == 1L && is.character(v))  return(sprintf("\"%s\"", v))
  if (length(v) == 1L && is.na(v))         return(sprintf("NA_%s_", typeof(v)))
  if (length(v) == 1L)                     return(as.character(v))
  if (length(v) <= 4L)                     return(sprintf("c(%s)", paste(v, collapse = ", ")))
  sprintf("c(%s, ...)", paste(utils::head(v, 4L), collapse = ", "))
}

#' List the named parameter groups (internal — used by vignettes)
#'
#' Returns the names of `.SPEC_GROUPS` in display order. Used by
#' `vignette("parameter-reference")` to iterate over groups
#' programmatically.
#'
#' @return Character vector of group names.
#' @keywords internal
.param_groups <- function() names(.SPEC_GROUPS)

#' Generate a parameter-reference table for one group (internal)
#'
#' Builds a `data.frame` with columns `parameter`, `default`, `type` for
#' all fields in `specs` that belong to the named group. Used by
#' `vignette("parameter-reference")` so that defaults are always
#' synchronised with `default_specs()` rather than hand-maintained.
#'
#' Fields listed in `.SPEC_GROUPS[[group]]` but absent from `specs` are
#' silently skipped (lets the groupings hold names of reserved-future
#' fields without breaking the table).
#'
#' @param group Character. Name of one of the groups in `.SPEC_GROUPS`.
#'   See [.param_groups()] for the full list.
#' @param specs A specs list (default: [default_specs()]).
#'
#' @return A `data.frame` with three columns: `parameter`, `default`,
#'   `type`. Empty `data.frame` if no field in `group` is in `specs`.
#'
#' @keywords internal
.param_table <- function(group, specs = default_specs()) {
  stopifnot(is.character(group), length(group) == 1L)
  if (!group %in% names(.SPEC_GROUPS)) {
    stop(sprintf("Unknown group '%s'. Use .param_groups() for valid names.",
                 group), call. = FALSE)
  }
  fields <- intersect(.SPEC_GROUPS[[group]], names(specs))
  if (!length(fields)) {
    return(data.frame(parameter = character(0L),
                      default   = character(0L),
                      type      = character(0L),
                      stringsAsFactors = FALSE))
  }
  data.frame(
    parameter = paste0("`", fields, "`"),
    default   = vapply(fields, function(nm) .spec_value_format(specs[[nm]]),
                       character(1L)),
    type      = vapply(fields, function(nm) .spec_type_label(specs[[nm]]),
                       character(1L)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

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

  # Shared grouping definitions — see `.SPEC_GROUPS` at the top of this file.
  groups <- .SPEC_GROUPS

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
