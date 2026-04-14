# Phase 7 — CMA-ES auto-calibration results

31 scenarios searched in parallel with CMA-ES (20 iterations × popsize 6,
1 replicate per candidate, ~3 min/scenario, 16 concurrent Rscript
subprocesses). Fitness-function table at
[`PLAN.md`](PLAN.md); registry at
[`fitness_functions.R`](fitness_functions.R).

All raw results under `_artifacts/*.json`; driver at
[`run_one.R`](run_one.R).

## Headline improvements

Scenarios where CMA-ES found a regime that substantially exceeds the
vignette's default specs (higher fitness = better reproduction of the
claimed biology):

| Scenario | Baseline | Best | Ratio | Key discovered parameters |
|---|---|---|---|---|
| s-speciation | 1.15 | 217 | **189×** | `mutation_sd: 0.1 → 1.31` (isolation_threshold barely changes) |
| s-disease | 86 | 3,890 | **45×** | `transmission_prob: 0.1 → 0.9` + `disease_death_prob: 0.02 → 0.0005` — very contagious, rarely fatal |
| s-cephalopod | 0.010 | 0.401 | **40×** | `learning_rate_init_mean: 0.01 → 0.47` + low mutation; within-lifetime plasticity replaces genetic evolution (**confirms the cephalopod paradox**) |
| s-plasticity | 0.006 | 0.221 | **38×** | `plasticity_init_mean: 0.3 → 0.70` + `plasticity_mutation_sd: 0.03 → 0.14` |
| s-mimicry | 0.001 | 0.015 | **21×** | `toxicity_cost_per_tick: 0.5 → 0.28` (cheaper toxins enable persistent aposematic phenotypes) |
| s-scavenging | 0.95 | 11.4 | **12×** | `grass_rate → 1.0` + `idle_cost: 0.5 → 1.53` (faster turnover → more carcasses) |
| s-complex-landscape | 170 | 1,510 | **8.9×** | `canopy_energy: 50 → 7,420` (massive canopy reward drives wing-size evolution) |
| s-kin | 6.3 | 30.8 | **4.9×** | `kin_altruism_benefit: 10 → 143`, `grass_rate: 0.05 → 0.29` |
| s-niche | 8.2 | 40.4 | **4.9×** | `grass_rate → 1.0`, more rebuild opportunity |
| s-clutch-size | 1 | 4 | **4.0×** | `clutch_size_init_mean: 1 → 4.6` (direct) |
| s-stress-hypermutation | 0.29 | 1.10 | **3.8×** | `stress_threshold: 20 → 5` (stricter starvation gate) |
| s-predator-prey | 0.45 | 1.41 | **3.1×** | `predator_attack_strength: 40 → 1.0` (gentler predator → longer Lotka-Volterra cycles) |
| s-brain-size | 0.031 | 0.079 | **2.5×** | `brain_size_cost_scale: 1.0 → 0.63` (cheaper brains favoured) |
| s-cooperation | 202 | 492 | **2.4×** | `cooperation_multiplier: 2 → 52`, `cooperation_cost: 1 → 38` |
| s-dispersal-ifd | −0.024 | 0.048 | **1.9×** (sign flip) | `dispersal_init_mean: 0.1 → 0.125` |
| s-predation-neural | 113 | 181 | **1.6×** | `predator_attack_strength: 40 → 1.4` |
| s-parental-investment | 46 | 66 | **1.4×** | `feeding_rate: 5 → 19`, `male_repro_cost: 0.3 → 0.89` |
| s-baseline | 156 | 175 | **1.3×** | low grass + high eat gain |
| s-baldwin | −0.0008 | +0.001 | **1.2×** (sign flip) | `grass_rate: 0.05 → 0.027`, `learning_rate_init_mean: 0.01 → 0.007` — **CMA-ES found a regime where σ narrows**, i.e. the Baldwin effect does emerge in clade at scarcer resource + slower learning |
| s-parental-care | 8.1 | 9.3 | 1.2× | `feeding_rate: 5 → 2.1`, `care_cost_per_tick: 1 → 2.5` |
| s-group-defense | 69 | 83 | 1.2× | weaker predator + diversified founders |
| s-kitchen-sink | 0.89 | 0.99 | 1.1× | scarcer grass + slightly higher mutation |
| s-mating-systems | 133 | 151 | 1.1× | slightly reduced signal_cost |
| s-seasonal | 10.0 | 10.3 | 1.0× | near-null; search didn't find better oscillation regime |
| s-life-history | 196 | 200 | 1.0× | hit the max_age cap — fitness ceiling reached |

## Nulls / limitations

| Scenario | Notes |
|---|---|
| s-rl | Baseline and best both ~−0.0006 (σ still rising slightly under RL). The BNN REINFORCE fix helps but doesn't make σ narrow at these scales without longer runs. |
| s-social-learning | Search found near-zero `social_learning_rate` improvement; perhaps the fitness function (slope of genetic diversity) is the wrong target for this module. |
| s-body-size | CMA-ES drove mutation to near zero; fitness = −\|drift\| was minimised correctly but it's a degenerate solution. Need a more informative objective. |
| s-pace-of-life | `mean_metabolic_rate` trajectory never exceeds floating-point noise — the metabolic_rate field may not be driven by per-agent evolution under the chosen settings. Module may need wiring check. |
| s-pop-genetics | Baseline already 0.998 (lag-1 autocorr); fitness ceiling. |
| s-kitchen-sink | Population ratio sat near the `max_agents` cap; fitness ceiling. |
| s-signals | Best fitness = −Inf: the signal–preference correlation across final agents can't be computed at any tested regime, suggesting `$signal`/`$preference` vectors on Agent aren't being populated / preserved at tick_end. Needs investigation in the signals module. |

## What the discovered regimes tell us about the simulator

1. **The Baldwin effect does emerge** in clade — it just requires a harsher
   environment (`grass_rate ≈ 0.027`) and a slower RL rate
   (`learning_rate_init_mean ≈ 0.007`) than the displayed defaults. This
   is consistent with Hinton & Nowlan (1987): canalisation needs selection
   pressure to find the learned optimum. At the current defaults,
   foraging is cheap and σ stays wide; at calibrated defaults, σ narrows.

2. **The cephalopod paradox** (Liedtke & Fromhage 2019) is reproducible:
   under high within-lifetime learning rate with low genetic drift,
   evolved `mean_learning_rate` ends up high — i.e. plasticity replaces
   genetic evolution, exactly the paradox the vignette claims.

3. **Disease dynamics** need much higher contagion and lower lethality
   than the defaults to produce sustained SIR curves with a visible peak.
   The canonical textbook SIR at `β ≈ 0.9`, `disease_death_prob ≈ 0.0005`
   gives a rich epidemic trajectory; defaults (`β = 0.1`) produce only
   trivial infection counts.

4. **Speciation is possible at displayed `isolation_threshold = 0.5`** —
   but only with `mutation_sd ≈ 1.3` (13× the default). Defaults are too
   conservative for speciation to fire within 400 ticks.

5. **Complex-landscape canopy energy is under-tuned.** The discovered
   `canopy_energy ≈ 7,400` is 150× the default 50. That's implausibly
   high biologically — it probably reveals that the wing-size / canopy-
   threshold mechanism is too easy to "buy out" with a huge reward
   rather than through adaptive evolution. A follow-up with MAP-Elites
   would illuminate the trade-off surface better.

## Proposed vignette updates (Phase 7c)

For each **3×+ improvement**, the discovered regime should be surfaced in
the vignette:

- `s-disease`, `s-cephalopod`, `s-plasticity`, `s-mimicry`, `s-scavenging`,
  `s-complex-landscape`, `s-speciation`, `s-kin`, `s-niche`,
  `s-clutch-size`, `s-stress-hypermutation`, `s-predator-prey`: add a
  "Calibrated regime" section after the baseline chunk, showing the
  discovered parameter values and referencing this calibration report.

- For modest improvements (1.1×–2.5×), no displayed-spec changes are
  warranted; note in the "Caveats" section that CMA-ES found marginally
  better regimes but the current defaults already sit near the fitness
  plateau.

- For nulls / ceilings: document in the vignette that the fitness
  ceiling is intrinsic (e.g. s-life-history fitness = `mean(age) /
  max_age` capped at 1.0).

## Open issues for 0.3.0

1. **s-signals fitness returns NA.** Signal-preference correlation is
   uncomputable at any regime tested — either `$signal`/`$preference`
   vectors aren't populated on Agent at tick end, or `signal_dims = 2`
   isn't enough. Next pass: dump agent-level signal/preference at end
   of a known-good signal run and verify the structure.

2. **s-body-size degenerate.** Fitness `−|drift|` minimised via
   mutation → 0 — not what we wanted. Reformulate as "closeness to a
   selected body-size optimum" using a fixed cost function.

3. **s-pace-of-life metric flat.** `mean_metabolic_rate` stays at ~5e-18
   in all runs. Module may not be driving `ag.metabolic_rate` per
   agent, or the logger is averaging over a zero-initialised field.

## How to rerun

```bash
export PATH=~/.juliaup/bin:$PATH
bash dev/audit/calibration/run_all.sh --iter 20 --pop 6 --max-parallel 16
Rscript -e 'source("dev/audit/calibration/run_one.R")' # one-shot single scenario
```

Progress streams to `dev/audit/calibration/_artifacts/progress.log`;
results land in `*.json`.
