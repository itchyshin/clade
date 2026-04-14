# Phase 7 — Auto-calibration plan

For each scenario with a specific biological claim, run CMA-ES (or
MAP-Elites where diversity matters) to find the parameter regime that
maximises the claim's signal. Output: one JSON per scenario with
(best_specs, trajectory_at_best, improvement_over_defaults).

## Search budget

- Default: `n_iterations = 50`, `pop_size = 8` per scenario (CMA-ES),
  `n_replicates = 3` per candidate. ≈ 50 × 8 × 3 = 1200 sim-runs per
  scenario. Typical sim run ≈ 2 s → ~40 min wall clock per scenario on
  one warm Julia session.
- Parallelisation: one Julia-warm R process per scenario, up to 22
  in parallel. Machine cap is ≤200 cores / ≲300 GB memory. At ~1 GB
  each we're comfortably under.
- Total wall clock: ~40 min if all 22 run simultaneously.

## Fitness function inventory

One line per scenario. `metric` = column in `get_run_data(env)$ticks`.
`F` = fitness (higher is better). Search parameters are what CMA-ES
will sweep; everything else is fixed to the vignette's displayed specs.

| Scenario | Biological claim | Fitness F | Search parameters | Bounds |
|---|---|---|---|---|
| s-baldwin | BNN sigma narrows under genetic assimilation (Hinton & Nowlan 1987) | `-slope(mean_prior_sigma ~ t)` (positive F = narrowing) | `grass_rate`, `seasonal_amplitude`, `bnn_sigma_init`, `learning_rate_init_mean`, `rl_mode ∈ {none, actor_critic}` | 0.01–0.3; 0–0.9; 0.05–0.8; 0.001–0.1 |
| s-plasticity | Mean plasticity rises over generations | `late_mean(mean_plasticity) - early_mean(mean_plasticity)` | `plasticity_init_mean`, `plasticity_mutation_sd`, `grass_rate` | 0.05–0.5; 0.01–0.2; 0.03–0.3 |
| s-rl | Within-lifetime RL narrows sigma | `-slope(mean_prior_sigma ~ t)` with `rl_mode=actor_critic` | `learning_rate`, `rl_update_freq`, `bnn_sigma_init` | 0.001–0.1; 1–20; 0.1–0.5 |
| s-social-learning | Social learning reduces genetic diversity | `-slope(genetic_diversity ~ t)` | `social_learning_rate`, `social_learning_radius` | 0.01–0.5; 1–5 |
| s-brain-size | With parental care, mean_brain_size rises; without, falls | `mean_brain_size_with_care - mean_brain_size_no_care` (two inner runs) | `brain_size_cost_scale`, `care_duration`, `brain_size_sensing_exponent` | 0.5–3.0; 5–30; 0.1–0.5 |
| s-complex-landscape | mean_wing_size rises + n_canopy_agents rises | `sum(n_canopy_agents) + 100 * (late_mean(mean_wing_size) - init_wing_size)` | `canopy_threshold`, `wing_size_init_mean`, `wing_size_mutation_sd`, `canopy_energy` | 0.05–0.3; 0.05–0.2; 0.01–0.15; 20–80 |
| s-dispersal-ifd | mean_rear_dispersal rises (Shine et al. 2011) | `late - early` of `mean_rear_dispersal` on a **bounded** grid (`toroidal=FALSE`) | `dispersal_mutation_sd`, `dispersal_init_mean`, `n_agents_init`, `grid_rows` | 0.01–0.2; 0.1–0.5; 50–200; 20–60 |
| s-kin | n_altruistic_acts scales with relatedness density | `mean(n_altruistic_acts)` per tick | `kin_altruism_cost`, `kin_altruism_benefit`, `kin_altruism_r_min`, `grass_rate` | 1–5; 5–20; 0.1–0.4; 0.03–0.15 |
| s-cooperation | n_cooperation_acts sustained over time | `mean(n_cooperation_acts)` per tick | `cooperation_cost`, `cooperation_benefit`, `cooperation_init_mean` | 0.5–3; 2–10; 0.1–0.5 |
| s-parental-care | n_juveniles > 0 and population grows | `mean(n_juveniles) + 0.1 * late_mean(n_agents)` | `care_duration`, `feeding_rate`, `juvenile_independence_age`, `max_clutch_size` | 3–20; 1–10; 5–25; 1–5 |
| s-parental-investment | mean investment rises; offspring-per-parent falls | `late_mean(n_juveniles) + cor(mean_investment, n_juveniles) * 10` | `parental_care`, `parental_investment_evolution`, `male_repro_cost` | TRUE/TRUE fixed; 0.1–0.6 |
| s-clutch-size | Evolves toward bounded optimum | `late_mean(mean_clutch_size)` | `clutch_size_min`, `clutch_size_max`, `clutch_size_mutation_sd` | 1–2; 3–8; 0.1–0.5 |
| s-disease | Epidemic curve peaks then declines | `sum(n_infected) - 10 * |argmax(n_infected)/n - 0.3|` (peak near 30%) | `transmission_prob`, `recovery_prob`, `n_agents_init` | 0.05–0.5; 0.02–0.2; 60–200 |
| s-mimicry | mean_toxicity rises; predator learns avoidance | `late_mean(mean_toxicity) - early_mean(mean_toxicity)` | `toxin_dose`, `toxicity_cost_per_tick`, `signal_memory_rate` | 10–50; 0.5–5; 0.1–0.5 |
| s-signals | Signal-preference correlation rises (Fisher runaway) | `cor(signal, preference)` at final tick over agents | `signal_cost`, `signal_drift_sd`, `mate_choice` | 0.05–0.5; 0.005–0.05; TRUE |
| s-mating-systems | Sexual outperforms asexual under disease | `(energy_sexual - energy_asexual)` | two inner runs; search over `transmission_prob` | 0.05–0.5 |
| s-life-history | Mean age at death ≈ max_age fraction | `mean(deaths$age) / max_age` | `aging_rate_mutation_sd`, `max_age`, `repro_threshold` | 0.01–0.1; 150–400; 80–200 |
| s-pace-of-life | Metabolic rate trades off with lifespan | `cor(-metabolic, age_at_death)` via inner deaths dataframe | `metabolic_rate_mutation_sd`, `metabolic_rate_init_mean` | 0.01–0.2; 0.5–1.5 |
| s-pop-genetics | Autocorrelation of mean_body_size > 0.9 | lag-1 autocorrelation of `mean_body_size` | `body_size_mutation_sd`, `n_agents_init` | 0.01–0.1; 50–300 |
| s-speciation | max(n_species) ≥ 5 with turnover | `max(n_species) + sd(n_species)` | `isolation_threshold`, `mutation_sd`, `max_ticks` | 0.1–0.6; 0.05–0.25; 300–1000 |
| s-niche | n_shelters_built rises monotonically | `late_mean(n_shelters_built)` | `shelter_decay_prob`, `shelter_build_prob` | 0.01–0.15; 0.01–0.3 |
| s-scavenging | n_scavenge_events > 0 with population sustained | `mean(n_scavenge_events)` | `scavenge_benefit`, `carcass_decay_prob` | 1–10; 0.05–0.3 |
| s-seasonal | Population oscillates with season | FFT amplitude at `period = season_length` / mean | `seasonal_amplitude`, `season_length`, `winter_death_prob` | 0.1–0.8; 50–200; 0–0.1 |
| s-group-defense | Grouped agents have higher survival vs solo | `late_mean(n_agents) - predator_attacks_successful` | `group_defense_radius`, `predator_attack_strength` | 1–3; 20–60 |
| s-predator-prey | Classic Lotka-Volterra oscillation | FFT amplitude of n_agents at biologically plausible period | `predator_attack_strength`, `n_predators_init`, `predator_reproduction_rate` | 20–60; 3–15; 0.01–0.1 |
| s-predation-neural | Prey neural complexity rises under predation | diff in `mean_brain_size` between `n_predators_init=0` vs `>0` | `n_predators_init`, `predator_attack_strength` | 3–15; 20–60 |
| s-stress-hypermutation | Genetic diversity transiently spikes during crashes | `sd(genetic_diversity) / mean(genetic_diversity)` under `grass_rate ≤ 0.05` | `stress_threshold`, `stress_mutation_multiplier`, `grass_rate` | 10–40; 2–8; 0.02–0.08 |
| s-cephalopod | Evolved learning rate higher under short max_age | `-cor(max_age, mean_lr_final)` (negative cor → higher lr at short lifespan) | needs batch over `max_age ∈ {20,50,100,200}` per candidate | keep |
| s-body-size | Body size converges to selected optimum | `|late_mean(mean_body_size) - target|` minimised | `body_size_mutation_sd`, `body_size_cost_scale` | 0.01–0.1; 0.5–3 |
| s-baseline | mean_energy stable and nonzero | `late_mean(mean_energy) - 10 * sd(mean_energy) / mean(mean_energy)` | `grass_rate`, `eat_gain`, `idle_cost` | 0.03–0.3; 2–10; 0.3–1.5 |
| s-kitchen-sink | Population survives ≥ 300 ticks with all modules | `late_mean(n_agents) / max_agents` | `max_agents`, `grass_rate` | 200–1000; 0.05–0.3 |
| s-bad-science | (search-only; skip) | — | — | — |
| s-cross-module | (aggregate; skip) | — | — | — |
| s-map-elites | (search-only; skip) | — | — | — |
| s-module-comparison | (batch gallery; skip) | — | — | — |

**Scenarios targeted by Phase 7: 31.** Four are by-design un-searchable
(search-only or aggregate galleries) and are skipped.

## Execution design

Per scenario: a new file `dev/audit/calibration/<vignette>.R` that:

1. Loads clade via `devtools::load_all()`.
2. Defines `fitness(specs) -> Float64` per the table above.
3. Calls `clade::search_cmaes(fitness, bounds, n_iter = 50, pop_size = 8)`.
4. Writes `dev/audit/calibration/<vignette>.json` with
   {best_specs, fitness_best, fitness_default, iterations,
    convergence_trajectory}.
5. Also writes a tiny markdown report summarising the discovered regime
   vs. the vignette's current displayed specs.

Driver: `dev/audit/calibration/run_all.R` spawns each scenario's script
as an independent `Rscript` subprocess. Unlike the audit (which must
run serially because JuliaConnectoR's socket can't survive fork), each
subprocess has its own Julia — cost: 12s startup per subprocess, but
they run in parallel, so the precompile overhead is absorbed once.

## Review checkpoints

1. **Before launch**: you sign off on the fitness-function table above.
   Adjust any objective where "biological reality" differs from my
   interpretation. In particular, flag any fitness that should be
   *minimised* rather than *maximised*.
2. **After launch**: progress reported via a shared
   `dev/audit/calibration/progress.log` — a tail on that file gives
   live per-scenario status.
3. **After results**: I present a table of (vignette, default fitness,
   best fitness, improvement, discovered regime). For each scenario
   where improvement is meaningful, I propose a displayed-specs update
   in the Rmd; you approve per scenario.

## Open question for you

For scenarios where the vignette documents an **honest negative result**
(e.g. s-baldwin explicitly says "sigma does not narrow in competitive
foraging"), should Phase 7:

- (a) **Search anyway** — if CMA-ES finds a regime where the effect
  *does* emerge, we've made the scenario stronger and update both the
  prose and the displayed code.
- (b) **Skip** — the honest-negative finding is a feature, not a bug;
  leave it alone.

My recommendation: **(a)** with explicit fallback to (b) if no regime
produces the signal. This gives the vignette the best shot at a
positive result while preserving the honest-negative as a backup.
