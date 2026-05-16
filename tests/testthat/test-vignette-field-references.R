# Drift-guard against stale spec-field references in vignettes.
#
# Background: 2026-05-16 Tier B2 audit (dev/audit/vignette-review/
# tier-B2-scenario-vignettes-summary.md) found `base$seed <- 42L` in
# 5 sites in vignettes/s-cross-module.Rmd — but the spec field is
# `random_seed`, not `seed`. The Julia kernel uses `get(specs,
# "random_seed", ...)`, so `base$seed` was silently ignored and those
# vignette code chunks were NOT seed-controlled.
#
# This test makes that class of bug impossible by scanning every R
# code chunk in vignettes/*.Rmd for assignments / accesses on
# specs-like variables (`specs`, `s`, `base`, or names ending in
# `_specs`), and asserting every accessed field name is either:
#   (a) in default_specs(), or
#   (b) in .VIGNETTE_FIELD_ALLOWLIST (return-value list members,
#       env-list members, tick-log column names, etc.).
#
# This is a *vignette* counterpart to test-test-field-assertions.R
# (which guards the same class in `tests/testthat/`).

library(testthat)

# Variable names commonly used to hold spec lists in vignettes (from
# the Tier B2 inventory: 66 `s$`, 18 `base$`, 8 `specs$`).
.SPEC_VAR_NAMES_RE <- "\\b(specs|s|base|[a-zA-Z][a-zA-Z0-9_]*_specs)\\$([a-zA-Z_][a-zA-Z0-9_]*)"

# Fields that legitimately appear after a specs-like variable but are
# NOT spec fields. Each entry must have a documented reason.
.VIGNETTE_FIELD_ALLOWLIST <- c(
  # ----- env / return-value list members -----
  # `env$agents`, `env$t`, `env$progress`, etc. — but `env`, `e`, `out`,
  # `res`, `data`, `rd` don't match .SPEC_VAR_NAMES_RE, so usually fine.
  # Listed here defensively in case a vignette aliases env to `s`.
  "agents", "t", "progress", "deaths", "genome_log", "viability", "specs",
  # ----- hypothesis_sweep return-value members -----
  "runs", "conditions", "metrics", "base_specs", "seeds", "elapsed",
  # ----- batch_alife return-value pattern (s = result[[i]]) -----
  "n_init", "n_final", "n_min", "tick_of_min", "verdict", "message",
  # ----- tick-log columns (inst/julia/src/logging.jl::_init_progress).
  # Listed defensively in case a vignette aliases data$ticks to `s`.
  "n_agents", "n_births", "n_deaths", "n_starvations", "n_age_deaths",
  "mean_energy", "sd_energy", "mean_age", "sd_age",
  "mean_body_size", "sd_body_size", "genetic_diversity", "n_species",
  "mean_cooperation_level", "mean_immune_strength", "sd_immune_strength",
  "mean_metabolic_rate", "mean_learning_rate", "mean_prior_sigma",
  "grass_coverage", "n_infected", "n_new_infections", "n_altruistic_acts",
  "n_shelters_built", "n_shelter_occupied", "n_cooperation_acts",
  "n_dispersal_events", "n_habitat_moves", "n_predators",
  "n_prey_killed", "n_avoided_attacks", "n_gd_events", "n_toxic_attacks",
  "n_scavenge_events", "n_helpers", "n_iffolk_transfers", "n_juveniles",
  "n_ground_agents", "n_shrub_agents", "n_canopy_agents",
  "n_front_agents", "mean_brain_size", "mean_signal_magnitude",
  "sd_signal_magnitude", "mean_preference_magnitude",
  "mean_signal_preference_dist", "mean_toxicity", "mean_helper_tendency",
  "mean_relatedness", "mean_canopy_coverage", "mean_shrub_coverage",
  "mean_shelter_depth", "mean_wing_size", "mean_habitat_preference",
  "mean_front_dispersal", "mean_rear_dispersal", "mean_plasticity",
  "mean_mutation_rate", "mean_clutch_size", "mean_ann_weight_magnitude",
  "agent_ids", "traits",
  # ----- death-record columns (env$deaths data.frame) -----
  "id", "age", "energy", "cause", "body_size", "num_offspring",
  # ----- viability_report return-value members -----
  "frac_initial", "weak", "crashed", "crashed_frac", "weak_frac", "min_n",
  # ----- paper-template.Rmd TODO placeholders -----
  # The template's `param_a` / `param_b` are pedagogical stand-ins
  # ("TODO: your parameter A") meant to be replaced by the user when
  # they fork the template for their own paper. They are not real
  # spec fields and will never be.
  "param_a", "param_b"
)

.find_repo_root <- function() {
  cur <- normalizePath(".", mustWork = FALSE)
  for (i in 1:6) {
    if (file.exists(file.path(cur, "DESCRIPTION")) &&
        dir.exists(file.path(cur, "R")) &&
        dir.exists(file.path(cur, "tests"))) {
      return(cur)
    }
    cur <- dirname(cur)
  }
  NULL
}

# Extract the lines INSIDE R code chunks (between ```{r ...} and ```).
# Spec-field assignments in prose / fence-headers don't count.
.extract_r_chunks <- function(lines) {
  inside <- FALSE
  keep <- logical(length(lines))
  for (i in seq_along(lines)) {
    if (!inside && grepl("^```\\{r", lines[i])) {
      inside <- TRUE
      next  # the fence line itself is not chunk content
    }
    if (inside && grepl("^```\\s*$", lines[i])) {
      inside <- FALSE
      next
    }
    if (inside) keep[i] <- TRUE
  }
  lines[keep]
}

.scan_vignette <- function(path, valid_fields) {
  raw <- readLines(path, warn = FALSE)
  chunks <- .extract_r_chunks(raw)
  if (length(chunks) == 0L) return(character(0))
  text <- paste(chunks, collapse = "\n")

  matches <- regmatches(text, gregexpr(.SPEC_VAR_NAMES_RE, text, perl = TRUE))[[1]]
  if (length(matches) == 0L) return(character(0))

  # Pull the captured `$field` name from each match.
  fields <- sub(".*\\$", "", matches)
  fields <- unique(fields)
  unrecognised <- setdiff(fields, valid_fields)
  if (length(unrecognised) == 0L) return(character(0))

  rel <- basename(path)
  sprintf("%s: %s", rel, paste(sort(unrecognised), collapse = ", "))
}

test_that("every <specs|s|base|*_specs>$<field> in vignette R chunks is a real spec field", {
  repo_root <- .find_repo_root()
  skip_if(is.null(repo_root),
          "Could not locate package root from test working directory.")

  # Source default_specs() field names — the authoritative set.
  spec_fields <- tryCatch(
    names(clade::default_specs()),
    error = function(e) {
      skip("clade not loaded; cannot read default_specs() field names.")
    }
  )

  valid_fields <- c(spec_fields, .VIGNETTE_FIELD_ALLOWLIST)

  rmd_files <- list.files(file.path(repo_root, "vignettes"),
                          pattern = "\\.Rmd$", full.names = TRUE)
  all_hits <- unlist(lapply(rmd_files, .scan_vignette, valid_fields = valid_fields),
                     use.names = FALSE)

  expect_equal(
    all_hits, character(0L),
    info = paste0(
      "Vignette references a `<specs|s|base|*_specs>$<field>` that ",
      "is neither in default_specs() nor in .VIGNETTE_FIELD_ALLOWLIST.\n",
      "Either (a) fix the field name to match default_specs(), ",
      "(b) rename the local variable to avoid the spec-var heuristic, ",
      "or (c) add the field to .VIGNETTE_FIELD_ALLOWLIST in ",
      "tests/testthat/test-vignette-field-references.R with a comment ",
      "explaining the legitimate use.\nHits:\n  ",
      paste(all_hits, collapse = "\n  ")
    )
  )
})
