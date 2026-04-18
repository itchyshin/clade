#!/usr/bin/env Rscript
# triage_modules.R
# Run each module in isolation and report whether a key biological signal
# is non-zero (presence check) or directionally consistent (calibration).
#
# Usage:  Rscript inst/scripts/triage_modules.R
# Output: lines prefixed [OK], [FLAT], or [ERR]
#   [OK]   -- signal detected (trait non-zero or population persists)
#   [FLAT] -- module runs but produces no detectable signal
#   [ERR]  -- simulation threw an error

suppressPackageStartupMessages(library(clade))

# ── Helpers ───────────────────────────────────────────────────────────────────

run_check <- function(name, specs_fn, check_fn) {
  specs <- tryCatch(specs_fn(), error = function(e) NULL)
  if (is.null(specs)) {
    cat(sprintf("[ERR]  %-35s  (specs construction failed)\n", name))
    return(invisible(NULL))
  }
  result <- tryCatch({
    env  <- run_alife(specs, verbose = FALSE)
    data <- get_run_data(env)$ticks
    check_fn(data)
  }, error = function(e) {
    list(ok = FALSE, msg = sub("\n.*", "", conditionMessage(e)))
  })
  tag <- if (isTRUE(result$ok)) "[OK]  " else if (is.null(result$msg)) "[FLAT]" else "[ERR] "
  cat(sprintf("%s %-35s  %s\n", tag, name, result$msg %||% ""))
  invisible(result)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

# Base specs: small grid, short run, enough agents to see signal
base <- function() {
  sp <- default_specs()
  sp$n_agents_init <- 80L
  sp$max_agents    <- 400L
  sp$max_ticks     <- 300L
  sp
}

ok_if     <- function(cond, val_str = "") list(ok = cond, msg = val_str)
mean_last <- function(col, n = 50) mean(tail(col, n), na.rm = TRUE)
any_pos   <- function(col) any(col > 0, na.rm = TRUE)

# ── Module checks ─────────────────────────────────────────────────────────────

cat("=== clade module triage ===\n\n")

run_check("baseline (no modules)", function() base(), function(d) {
  ok_if(mean_last(d$n_agents) > 5,
        sprintf("mean_agents=%.1f", mean_last(d$n_agents)))
})

run_check("cooperation_evolution", function() {
  sp <- base(); sp$cooperation_evolution <- TRUE
  sp$cooperation_multiplier <- 3.0; sp
}, function(d) {
  m <- mean_last(d$mean_cooperation_level)
  ok_if(!is.na(m), sprintf("mean_coop=%.3f", m))
})

run_check("body_size_evolution", function() {
  sp <- base(); sp$body_size_evolution <- TRUE; sp
}, function(d) {
  m <- mean_last(d$mean_body_size)
  ok_if(!is.na(m) && m > 0, sprintf("mean_body_size=%.3f", m))
})

run_check("dispersal_evolution", function() {
  sp <- base(); sp$dispersal_evolution <- TRUE; sp
}, function(d) {
  ok_if(any_pos(d$n_dispersal_events),
        sprintf("total_dispersals=%d", sum(d$n_dispersal_events, na.rm = TRUE)))
})

run_check("habitat_preference_evolution", function() {
  sp <- base(); sp$habitat_preference_evolution <- TRUE; sp
}, function(d) {
  ok_if(any_pos(d$n_habitat_moves),
        sprintf("total_habitat_moves=%d", sum(d$n_habitat_moves, na.rm = TRUE)))
})

run_check("disease", function() {
  sp <- base()
  sp$disease           <- TRUE
  sp$transmission_prob <- 0.4
  sp$disease_seed_prob <- 0.05
  sp$disease_duration  <- 20L
  sp$immune_duration   <- 30L
  sp
}, function(d) {
  peak <- max(d$n_infected, na.rm = TRUE)
  ok_if(peak >= 2L, sprintf("peak_infected=%d", peak))
})

run_check("kin_selection", function() {
  sp <- base(); sp$kin_selection <- TRUE; sp
}, function(d) {
  ok_if(any_pos(d$n_altruistic_acts),
        sprintf("total_altruism=%d", sum(d$n_altruistic_acts, na.rm = TRUE)))
})

run_check("niche_construction", function() {
  sp <- base(); sp$niche_construction <- TRUE; sp
}, function(d) {
  ok_if(any_pos(d$n_shelters_built),
        sprintf("total_shelters=%d", sum(d$n_shelters_built, na.rm = TRUE)))
})

run_check("predators", function() {
  sp <- base()
  sp$n_predators_init <- 6L; sp$predator_max_agents <- 30L; sp
}, function(d) {
  m <- mean_last(d$n_predators)
  ok_if(m >= 1, sprintf("mean_predators=%.1f", m))
})

run_check("parental_care", function() {
  sp <- base()
  sp$parental_care    <- TRUE
  sp$care_duration    <- 8L
  sp$offspring_energy <- 35.0
  sp$repro_cost       <- 20.0
  sp
}, function(d) {
  ok_if(any_pos(d$n_juveniles),
        sprintf("max_juveniles=%d", max(d$n_juveniles, na.rm = TRUE)))
})

run_check("mimicry", function() {
  sp <- base()
  sp$mimicry          <- TRUE
  sp$n_predators_init <- 5L
  sp$toxin_dose       <- 20.0
  sp
}, function(d) {
  m <- mean_last(d$mean_toxicity)
  ok_if(!is.na(m), sprintf("mean_toxicity=%.4f", m))
})

run_check("scavenging", function() {
  sp <- base(); sp$scavenging <- TRUE; sp
}, function(d) {
  ok_if(any_pos(d$n_scavenge_events),
        sprintf("total_scavenges=%d", sum(d$n_scavenge_events, na.rm = TRUE)))
})

run_check("speciation", function() {
  sp <- base(); sp$speciation <- TRUE; sp
}, function(d) {
  m <- mean_last(d$n_species)
  ok_if(!is.na(m) && m >= 1, sprintf("mean_species=%.1f", m))
})

run_check("social_learning", function() {
  sp <- base()
  sp$social_learning      <- TRUE
  sp$social_learning_rate <- 0.1
  sp$social_learning_freq <- 5L
  sp
}, function(d) {
  ok_if(mean_last(d$n_agents) > 5,
        sprintf("mean_agents=%.1f (learning on)", mean_last(d$n_agents)))
})

run_check("rl_actor_critic", function() {
  sp <- base()
  sp$brain_type    <- "ann"
  sp$rl_mode       <- "actor_critic"
  sp$learning_rate <- 0.02
  sp
}, function(d) {
  ok_if(mean_last(d$n_agents) > 5,
        sprintf("mean_agents=%.1f (rl on)", mean_last(d$n_agents)))
})

run_check("epigenetics", function() {
  sp <- base()
  sp$epigenetics <- TRUE
  sp$brain_type  <- "bnn"
  sp
}, function(d) {
  m <- mean_last(d$mean_prior_sigma)
  ok_if(!is.na(m), sprintf("mean_prior_sigma=%.4f", m))
})

run_check("group_defense", function() {
  sp <- base()
  sp$n_predators_init <- 5L
  sp$group_defense    <- TRUE
  sp
}, function(d) {
  ok_if(any_pos(d$n_gd_events),
        sprintf("total_gd_events=%d", sum(d$n_gd_events, na.rm = TRUE)))
})

run_check("metabolic_rate_evolution", function() {
  sp <- base(); sp$metabolic_rate_evolution <- TRUE; sp
}, function(d) {
  m <- mean_last(d$mean_metabolic_rate)
  ok_if(!is.na(m) && m > 0, sprintf("mean_metabolic_rate=%.3f", m))
})

run_check("mutation_rate_evolution", function() {
  sp <- base(); sp$mutation_rate_evolution <- TRUE; sp
}, function(d) {
  m <- mean_last(d$mean_mutation_rate)
  ok_if(!is.na(m) && m > 0, sprintf("mean_mutation_rate=%.4f", m))
})

run_check("immune_evolution", function() {
  sp <- base()
  sp$disease          <- TRUE
  sp$immune_evolution <- TRUE
  sp$transmission_prob <- 0.3
  sp
}, function(d) {
  m <- mean_last(d$mean_immune_strength)
  ok_if(!is.na(m), sprintf("mean_immune_strength=%.3f", m))
})

run_check("cooperative_breeding", function() {
  sp <- base()
  sp$parental_care        <- TRUE
  sp$cooperative_breeding <- TRUE
  sp$care_duration        <- 8L
  sp
}, function(d) {
  ok_if(any_pos(d$n_helpers),
        sprintf("total_helpers=%d", sum(d$n_helpers, na.rm = TRUE)))
})

cat("\nDone. [OK]=working  [FLAT]=no signal  [ERR]=crash\n")
