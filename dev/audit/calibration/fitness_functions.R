# Per-scenario fitness functions + search-parameter lists.
#
# Each entry has:
#   $params       - character vector of numeric-positive param names
#                   to sweep via CMA-ES. Initial values are read from
#                   specs_base; sigma0 is proportional to the initial.
#   $specs_mods   - function(specs) -> specs: set the non-numeric /
#                   flag parameters that define the scenario (e.g. set
#                   `kin_selection = TRUE`, `rl_mode = "actor_critic"`).
#                   Applied to default_specs() before the search.
#   $fitness      - function(env) -> numeric: the objective, higher is
#                   better. Returns -Inf if the metric is unavailable.
#
# The driver `run_one.R` wires these into `clade::search_cmaes`.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# ---- helpers ---------------------------------------------------------------

.safe_traj <- function(env, col) {
  d <- clade::get_run_data(env)
  if (!is.null(d$ticks) && col %in% names(d$ticks)) {
    x <- as.numeric(d$ticks[[col]])
    x[is.finite(x)]
  } else {
    numeric(0)
  }
}

.early_late <- function(x) {
  n <- length(x); if (n < 4) return(c(NA_real_, NA_real_))
  c(mean(x[seq_len(max(1L, floor(n / 4)))]),
    mean(x[seq.int(max(1L, floor(3 * n / 4)), n)]))
}

.slope <- function(x) {
  if (length(x) < 4) return(NA_real_)
  unname(coef(stats::lm(x ~ seq_along(x)))[2L])
}

# ---- definitions -----------------------------------------------------------

fitness_registry <- list()

fitness_registry[["s-baldwin"]] <- list(
  params     = c("grass_rate", "learning_rate_init_mean"),
  specs_mods = function(s) { s$brain_type <- "bnn"; s$max_ticks <- 400L; s$n_agents_init <- 80L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_prior_sigma"); if (!length(x)) return(-Inf)
    -as.numeric(.slope(x))  # positive fitness = sigma narrowing
  }
)

fitness_registry[["s-plasticity"]] <- list(
  params     = c("plasticity_init_mean", "plasticity_mutation_sd", "grass_rate"),
  specs_mods = function(s) { s$phenotypic_plasticity <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_plasticity"); if (!length(x)) return(-Inf)
    el <- .early_late(x); if (any(is.na(el))) return(-Inf)
    el[2] - el[1]
  }
)

fitness_registry[["s-rl"]] <- list(
  params     = c("learning_rate_init_mean", "rl_update_freq"),
  specs_mods = function(s) { s$brain_type <- "bnn"; s$rl_mode <- "actor_critic"; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_prior_sigma"); if (!length(x)) return(-Inf)
    -as.numeric(.slope(x))
  }
)

fitness_registry[["s-social-learning"]] <- list(
  params     = c("social_learning_rate", "mutation_sd"),
  specs_mods = function(s) { s$social_learning <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "genetic_diversity"); if (!length(x)) return(-Inf)
    -as.numeric(.slope(x))
  }
)

fitness_registry[["s-brain-size"]] <- list(
  params     = c("brain_size_cost_scale", "brain_size_sensing_exponent"),
  specs_mods = function(s) { s$brain_size_evolution <- TRUE; s$parental_care <- TRUE; s$care_duration <- 15L; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_brain_size"); if (!length(x)) return(-Inf)
    el <- .early_late(x); if (any(is.na(el))) return(-Inf)
    el[2] - el[1]
  }
)

fitness_registry[["s-complex-landscape"]] <- list(
  params     = c("canopy_threshold", "wing_size_init_mean", "canopy_energy"),
  specs_mods = function(s) { s$complex_landscape <- TRUE; s$max_ticks <- 400L; s$n_agents_init <- 120L; s },
  fitness    = function(env) {
    w <- .safe_traj(env, "mean_wing_size"); c <- .safe_traj(env, "n_canopy_agents")
    if (!length(w) || !length(c)) return(-Inf)
    el <- .early_late(w); if (any(is.na(el))) return(-Inf)
    (el[2] - el[1]) + 0.01 * sum(c)
  }
)

fitness_registry[["s-dispersal-ifd"]] <- list(
  params     = c("dispersal_init_mean", "dispersal_mutation_sd"),
  specs_mods = function(s) { s$dispersal_evolution <- TRUE; s$spatial_sorting <- TRUE; s$toroidal <- FALSE; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_rear_dispersal"); if (!length(x)) return(-Inf)
    el <- .early_late(x); if (any(is.na(el))) return(-Inf)
    el[2] - el[1]
  }
)

fitness_registry[["s-kin"]] <- list(
  params     = c("kin_altruism_cost", "kin_altruism_benefit", "grass_rate"),
  specs_mods = function(s) { s$kin_selection <- TRUE; s$max_ticks <- 300L; s$n_agents_init <- 80L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_altruistic_acts"); if (!length(x)) return(-Inf)
    mean(x)
  }
)

fitness_registry[["s-cooperation"]] <- list(
  params     = c("cooperation_multiplier", "cooperation_cost"),
  specs_mods = function(s) { s$cooperation_evolution <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_cooperation_acts"); if (!length(x)) return(-Inf)
    mean(x)
  }
)

fitness_registry[["s-parental-care"]] <- list(
  params     = c("feeding_rate", "care_cost_per_tick"),
  specs_mods = function(s) { s$parental_care <- TRUE; s$care_duration <- 10L; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    j <- .safe_traj(env, "n_juveniles"); a <- .safe_traj(env, "n_agents")
    if (!length(j) || !length(a)) return(-Inf)
    mean(j) + 0.1 * tail(a, 1)
  }
)

fitness_registry[["s-parental-investment"]] <- list(
  params     = c("male_repro_cost", "feeding_rate"),
  specs_mods = function(s) { s$parental_care <- TRUE; s$parental_investment_evolution <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    j <- .safe_traj(env, "n_juveniles"); a <- .safe_traj(env, "n_agents")
    if (!length(j) || !length(a)) return(-Inf)
    el <- .early_late(a); if (any(is.na(el))) return(-Inf)
    mean(j) + max(el[2], 0)
  }
)

fitness_registry[["s-clutch-size"]] <- list(
  params     = c("clutch_size_mutation_sd", "clutch_size_init_mean"),
  specs_mods = function(s) { s$clutch_size_evolution <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_clutch_size"); if (!length(x)) return(-Inf)
    tail(x, 1)
  }
)

fitness_registry[["s-disease"]] <- list(
  params     = c("transmission_prob", "disease_death_prob"),
  specs_mods = function(s) { s$disease <- TRUE; s$max_ticks <- 300L; s$n_agents_init <- 100L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_infected"); if (!length(x)) return(-Inf)
    # Reward peak-then-decline: peak near 1/3 of the run, declining thereafter.
    if (max(x) <= 0) return(-Inf)
    peak_pos <- which.max(x) / length(x)
    penalty  <- 10 * abs(peak_pos - 0.33)
    sum(x) - penalty
  }
)

fitness_registry[["s-mimicry"]] <- list(
  params     = c("toxin_dose", "toxicity_cost_per_tick", "signal_memory_rate"),
  specs_mods = function(s) { s$mimicry <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_toxicity"); if (!length(x)) return(-Inf)
    el <- .early_late(x); if (any(is.na(el))) return(-Inf)
    el[2] - el[1]
  }
)

fitness_registry[["s-signals"]] <- list(
  params     = c("signal_cost", "signal_drift_sd"),
  specs_mods = function(s) { s$signal_mating <- TRUE; s$signal_evolution_drift <- TRUE; s$mate_choice <- TRUE; s$ploidy <- 2L; s$signal_dims <- 2L; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    # Correlation of signal and preference across final agents.
    ags <- env$agents
    if (length(ags) < 10) return(-Inf)
    sigs <- vapply(ags, function(a) as.numeric(a$signal[1] %||% NA_real_), numeric(1))
    prefs <- vapply(ags, function(a) as.numeric(a$preference[1] %||% NA_real_), numeric(1))
    ok <- is.finite(sigs) & is.finite(prefs)
    if (sum(ok) < 10) return(-Inf)
    as.numeric(stats::cor(sigs[ok], prefs[ok]))
  }
)

fitness_registry[["s-mating-systems"]] <- list(
  params     = c("mutation_sd", "signal_cost"),
  specs_mods = function(s) { s$ploidy <- 2L; s$mate_choice <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_energy"); if (!length(x)) return(-Inf)
    tail(x, 1)
  }
)

fitness_registry[["s-life-history"]] <- list(
  params     = c("aging_rate_mutation_sd", "min_repro_energy"),
  specs_mods = function(s) { s$max_ticks <- 500L; s },
  fitness    = function(env) {
    d <- clade::get_run_data(env)
    if (is.null(d$deaths) || !nrow(d$deaths)) return(-Inf)
    mean(as.numeric(d$deaths$age), na.rm = TRUE)
  }
)

fitness_registry[["s-pace-of-life"]] <- list(
  params     = c("metabolic_rate_mutation_sd", "metabolic_rate_init_mean"),
  specs_mods = function(s) { s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_metabolic_rate"); if (!length(x)) return(-Inf)
    abs(as.numeric(.slope(x)))  # any directional change = signal of evolution
  }
)

fitness_registry[["s-pop-genetics"]] <- list(
  params     = c("body_size_mutation_sd", "mutation_sd"),
  specs_mods = function(s) { s$body_size_evolution <- TRUE; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_body_size"); if (length(x) < 4) return(-Inf)
    as.numeric(stats::cor(x[-length(x)], x[-1L]))
  }
)

fitness_registry[["s-speciation"]] <- list(
  params     = c("isolation_threshold", "mutation_sd"),
  specs_mods = function(s) { s$speciation <- TRUE; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_species"); if (!length(x)) return(-Inf)
    max(x) + stats::sd(x, na.rm = TRUE)
  }
)

fitness_registry[["s-niche"]] <- list(
  params     = c("shelter_decay_prob", "grass_rate"),
  specs_mods = function(s) { s$niche_construction <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_shelters_built"); if (!length(x)) return(-Inf)
    mean(x)
  }
)

fitness_registry[["s-scavenging"]] <- list(
  # scavenging has no tunable numeric spec of its own; sweep a general
  # eco parameter that modulates carcass availability via starvation rate.
  params     = c("grass_rate", "idle_cost"),
  specs_mods = function(s) { s$scavenging <- TRUE; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_scavenge_events"); if (!length(x)) return(-Inf)
    mean(x)
  }
)

fitness_registry[["s-seasonal"]] <- list(
  params     = c("seasonal_amplitude", "winter_death_prob"),
  # Must start amplitude + winter_death_prob at >0 so CMA-ES has a
  # positive mean to explore around (search_cmaes guards against 0).
  specs_mods = function(s) { s$max_ticks <- 400L; s$season_length <- 100L; s$seasonal_amplitude <- 0.4; s$winter_death_prob <- 0.02; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_agents"); if (length(x) < 20) return(-Inf)
    # Power at the seasonal frequency
    sp <- stats::spec.pgram(x, plot = FALSE)
    target_f <- 1 / 100  # 1/season_length
    idx <- which.min(abs(sp$freq - target_f))
    log(sp$spec[idx] + 1e-9)
  }
)

fitness_registry[["s-group-defense"]] <- list(
  params     = c("predator_attack_strength", "mutation_sd"),
  specs_mods = function(s) { s$group_defense <- TRUE; s$predators <- TRUE; s$n_predators_init <- 5L; s$group_defense_radius <- 2L; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_agents"); if (!length(x)) return(-Inf)
    tail(x, 1)
  }
)

fitness_registry[["s-predator-prey"]] <- list(
  params     = c("predator_attack_strength", "grass_rate"),
  specs_mods = function(s) { s$predators <- TRUE; s$n_predators_init <- 5L; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "n_agents"); if (length(x) < 20) return(-Inf)
    stats::sd(x, na.rm = TRUE) / (mean(x, na.rm = TRUE) + 1e-9)
  }
)

fitness_registry[["s-predation-neural"]] <- list(
  params     = c("predator_attack_strength", "grass_rate"),
  specs_mods = function(s) { s$predators <- TRUE; s$n_predators_init <- 5L; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_energy"); if (!length(x)) return(-Inf)
    mean(x)
  }
)

fitness_registry[["s-stress-hypermutation"]] <- list(
  params     = c("stress_threshold", "stress_mutation_multiplier", "grass_rate"),
  specs_mods = function(s) { s$stress_hypermutation <- TRUE; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "genetic_diversity"); if (length(x) < 4) return(-Inf)
    stats::sd(x, na.rm = TRUE) / (mean(x, na.rm = TRUE) + 1e-9)
  }
)

fitness_registry[["s-cephalopod"]] <- list(
  params     = c("learning_rate_init_mean", "mutation_sd"),
  specs_mods = function(s) { s$complex_landscape <- TRUE; s$learning_rate_evolution <- TRUE; s$max_age <- 50L; s$max_ticks <- 300L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_learning_rate"); if (!length(x)) return(-Inf)
    tail(x, 1)
  }
)

fitness_registry[["s-body-size"]] <- list(
  params     = c("body_size_mutation_sd", "mutation_sd"),
  specs_mods = function(s) { s$body_size_evolution <- TRUE; s$max_ticks <- 400L; s },
  fitness    = function(env) {
    x <- .safe_traj(env, "mean_body_size"); if (length(x) < 4) return(-Inf)
    el <- .early_late(x); if (any(is.na(el))) return(-Inf)
    -abs(el[2] - el[1])   # minimise drift; i.e. find stable regime
  }
)

fitness_registry[["s-baseline"]] <- list(
  params     = c("grass_rate", "eat_gain", "idle_cost"),
  specs_mods = function(s) { s$max_ticks <- 400L; s },
  fitness    = function(env) {
    e <- .safe_traj(env, "mean_energy"); a <- .safe_traj(env, "n_agents")
    if (!length(e) || !length(a)) return(-Inf)
    late_e <- tail(e, max(1L, floor(length(e) / 4)))
    mean(late_e) - 10 * (stats::sd(late_e) / (mean(late_e) + 1e-9))
  }
)

fitness_registry[["s-kitchen-sink"]] <- list(
  params     = c("grass_rate", "mutation_sd"),
  specs_mods = function(s) {
    # Enable a broad "kitchen-sink" mix; keep each flag at its defaults.
    s$disease <- TRUE; s$kin_selection <- TRUE; s$cooperation_evolution <- TRUE
    s$niche_construction <- TRUE; s$parental_care <- TRUE; s$scavenging <- TRUE
    s$social_learning <- TRUE; s$body_size_evolution <- TRUE
    s$max_ticks <- 400L; s$n_agents_init <- 120L; s$max_agents <- 800L; s
  },
  fitness    = function(env) {
    a <- .safe_traj(env, "n_agents"); if (!length(a)) return(-Inf)
    tail(a, 1) / 800  # fraction of cap reached
  }
)

# Final sanity
stopifnot(all(vapply(fitness_registry, function(x)
  all(c("params", "specs_mods", "fitness") %in% names(x)), logical(1))))
