# clade 0.5.4 (2026-04-16)

## Audit: s-mimicry ecology-limited calibration (honest null)

Applied the 0.5.3 methodology (adequate seeds + 2×SE testing from
the start) to an 8-cell parameter search for a regime that produces
statistically clean upward toxicity evolution under the full 0.4.4
vector-signal machinery.

Result: **every tested regime shows Δtoxicity < 0** (range −0.002
to −0.009) across 40 total runs. The selection arithmetic:

- Toxicity cost: 0.03–0.06 energy/tick (cost × mean toxicity)
- Aposematic protection: 9–23 avoidance events per 1000 ticks
  across ~2000 attacks = ~1% of predator attacks on toxic prey
  blocked.
- Net effect: cost dominates benefit by ~10× at default population
  scales (n=100, 12–20 predators).

This is the **Zahavi (1975) handicap-honesty challenge at ABM
scale** — mirrors the 0.5.3 Red Queen finding (Hamilton's two-fold
cost of sex) as a real simulation-ecology limitation where the
canonical mechanism is correct but the cost-to-benefit ratio in
the default clade kernel doesn't support the evolution the theory
predicts.

s-mimicry stays 🟠 with kernel machinery confirmed correct and
ecology-limitation documented. Deferred to 0.6+ as a scenario
design question (smaller populations, more intense predation, or
bootstrapping with correlated signal + toxicity).

No kernel changes.

---

# clade 0.5.3 (2026-04-16)

## Audit: s-mating-systems 0.5.1 "first sex > asex" claim retracted

Applied the 0.5.2 body-size precedent (16-seed sweep with 2×SE
hypothesis test) to the Red Queen scenario. Across 448 audit runs
covering 19 distinct parameter regimes:

- **16-seed replication** at the 0.5.1 default `parasite_discrete`
  parameters: Δn (sex − asex) = −0.49 ± 1.54 → flat within 2×SE.
  The 0.5.1 "+1.1 first sex wins" finding was 3-seed noise.
- **Regime search** over `n_loci × pressure × exponent × mutation`
  (16 cells, 8 seeds each): all 16 regimes show direction in
  favour of sex on average; NONE crosses 2×SE.
- **Top-3 verification at 16 seeds**: the 8-seed apparent signals
  (+2.3 to +2.8) collapse to flat Δn ∈ {−1.07, +0.42, −0.45}.

The canonical discrete-allele Red Queen mechanism is implemented
correctly (direction consistently non-negative on average), but
clade's baseline cost of sex is higher than parasite selection
pressure can offset at every tested regime. Hamilton (1980)
himself noted sex's two-fold cost is a tall order for parasites;
this finding is consistent with his caveat.

Verdict: **s-mating-systems stays 🟠** with direction correct and
the "first sex wins" claim retracted. Pushing to ✅ is deferred as
a scenario-design question (minimise clade's baseline cost of sex
via population size, mate-finding dynamics, or longer runs).

No kernel changes.

---

# clade 0.5.2 (2026-04-16)

## Audit: s-body-size P2 direction resolved

16-seed × 2-sensing-mode × 2-predator-level factorial replaces the
earlier 5-seed audits. **P1 (Cope direction) robust** at +9–11%
upward drift (SE ≤ 0.7% of the effect). **P2 (predation direction)
NULL** in both sensing modes — neither the Shine-acceleration
(0.4.3 framing) nor the Brooks-Dodson-detectability (0.4.1 framing)
is statistically supported at default parameters. Both direction
claims retracted.

Side finding: the 0.4.2 graded predator sensing produces a larger
Cope drift (+0.107) than legacy binary sensing (+0.087), an
SE-bounded real effect from finer threat information improving
foraging efficiency.

No kernel changes.

---

# clade 0.5.1 (2026-04-16)

## Kernel: discrete-allele Red Queen (Hamilton 1980 canonical)

0.5.0's continuous-trait parasite module did NOT produce Hamilton's
canonical Red Queen — sex offspring as midpoints of parents cluster
near the parasite optimum, so sex is *more* exposed. 0.5.1 adds the
discrete-allele variant that reproduces the textbook effect.

**New Agent field** `parasite_haplotype::Vector{Int32}` (heritable
binary haplotype of length `n_parasite_loci`). Mendelian inheritance
with free recombination: diploid offspring inherit each locus
independently from either parent, producing genuinely novel
haplotype combinations. Haploid clone + per-locus mutation.

**Hamming-distance matching** in the parasite module: per-host
penalty `= pressure × ((n_loci − hamming) / n_loci)^exponent`.
Hosts exactly matching the parasite haplotype pay full pressure;
mismatched hosts escape cleanly.

**New specs**: `n_parasite_loci` (default 0L), `parasite_match_mode`
(`"auto"` / `"continuous"` / `"discrete"`), `parasite_mutation_rate`
(0.01), `parasite_discrete_exponent` (4.0).

## Audit: first sex > asex observation in clade

Tuning grid found regimes with Δn up to +7.7 at `n_loci = 16,
pressure = 2.0, exponent = 6, mutation = 0.02`. At audit-default
parameters (3 seeds × 500 ticks): Δn = +1.1 under the
`parasite_discrete` condition. P2 PASS (canonical Red Queen
direction). P3 PASS (continuous-trait parasites disfavour sex, as
predicted from 0.5.0).

s-mating-systems stays 🟠 (magnitude modest) but direction now
matches Hamilton 1980.

---

# clade 0.5.0 (2026-04-16)

## Kernel: coevolving parasite module (continuous-trait)

New `inst/julia/src/modules/coevolving_parasite.jl`. Collective
parasite "population" represented as a single virulence-genotype
vector that tracks the host signal centroid with lag. Per-host
Gaussian-falloff energy penalty based on Euclidean distance to the
parasite optimum.

**New specs**: `coevolving_parasites` (default FALSE),
`parasite_virulence_rate` (0.1), `parasite_pressure` (0.5),
`parasite_distance_scale` (1.0). Opt-in; no-op unless
`signal_dims > 0`.

## Honest finding documented

Continuous-trait parasites do NOT produce Hamilton's canonical
Red Queen. Under continuous matching, sex offspring (midpoint of
parents) sit closer to the population centroid than asex clones,
so sex is *more* exposed. Audit verdict: Δn = −2.5 under
`parasite_continuous`. The mechanism nevertheless models a real
biological phenomenon — parasites selecting against genetic
convergence — and the scaffolding set up for 0.5.1 to implement
Hamilton's discrete-allele variant.

---

# clade 0.4.4 (2026-04-16)

## Kernel: vector-signal predator memory (Bates/Müller canonical)

**Dedicated `signal_memory::Vector{Float32}` field on Agent**
replaces 0.4.0 Tier 4's overloading of `preference` (which is meant
for prey mate-choice). Cleaner semantics; same mechanism.

**Delta-rule Rescorla-Wagner update** in `apply_predator_toxin!`.
The predator learns a linear model that *predicts* toxicity from
the signal vector:

    memory += lr × (tox − dot(memory, signal)) × signal

This is the Widrow-Hoff rule, standard for supervised linear
regression. Symmetric (reinforcement on toxic prey, extinction on
non-toxic prey) → enables Batesian breakdown when palatable mimics
outnumber toxic models.

**Avoidance uses predicted toxicity**:
`avoid if dot(memory, signal) >= avoid_threshold`.

**Aposematic pleiotropy** — new spec `signal_toxicity_coupling ∈
[0, 1]`. When > 0, each agent's `signal[1]` is pulled toward its
own toxicity each tick — the honest-signal mechanism theory
requires.

## Audit fixes

- Counter-summation bug in `dev/audit/fidelity/mimicry.R`:
  `tail(d$n_avoided_attacks, 1L)` replaced by `sum(...)` —
  per-tick counters reset each tick, so tail was spuriously 0.
- s-mimicry P3 (learning fires) FAIL → PASS (12–28 avoidances /
  600 ticks).
- P4 (dose-response) FAIL → PASS (Spearman ρ = +0.40).
- P5 (pleiotropy direction, new) PASS (ρ = +1.0).
- Magnitudes still parameter-sensitive; s-mimicry stays 🟠 with
  substantially richer kernel semantics.

---

# clade 0.4.3 (2026-04-16)

## Kernel: expensive-brain mechanisms

Two opt-in features implementing the biological mechanisms
Aiello & Wheeler (1995) and Isler & van Schaik (2009) invoke for
parental-provisioning scenarios, letting s-brain-size reach ✅
at the default `brain_energy_base` without scenario-specific
overrides.

- **Neonatal foraging deficit** (`neonatal_foraging_deficit`,
  `neonatal_deficit_duration` in `R/config.R`). During the first
  `neonatal_deficit_duration` ticks of life, effective `max_bite`
  is scaled by `(1 - deficit)`. Parental care bypasses via the
  existing `feeding_rate` channel.
- **Super-linear brain-size cost** (`brain_energy_size_exponent`).
  `size_cost = base × n_weights^exponent`. Default 1.0 (linear,
  legacy); 1.5 gives Kleiber-style scaling.

Both default-off. s-brain-size ✅ via two routes: 0.4.2 base
override (stable populations) OR 0.4.3 biological mechanisms
(principled, with population trade-off).

---

# clade 0.4.2 (2026-04-16)

## Kernel: sense + death polish

Three small fixes flagged in the 0.4.1 kernel-as-biology docs:

- **Graded predator-distance signal.** `_pred_dist` now actually
  returns `1/(d+1)` as its docstring claimed. New spec
  `predator_sense_graded = TRUE` (default); legacy binary
  available via `= FALSE`.
- **Signal sensory inputs clamped to [0, 1]** so the signal
  channel matches the convention of the other sensory inputs.
- **`max_age` cap deferred to Gompertz senescence** when
  `senescence_rate > 0`, so the hard cap doesn't mask age-dependent
  mortality. Legacy default (`senescence_rate = 0`) unchanged.

## Audit reruns

1500-tick reruns of s-baldwin and s-plasticity under 0.4.1 Tier
5A+5C mechanisms. s-plasticity: seasonal > stable direction
confirmed. s-baldwin: canonical direction reversal from
pre-0.4.0 🔴 confirmed at short timescales, disappears at
equilibrium — sigma also mediates behavioural variance, so
seasonal stress amplifies the selection against wide posteriors.
Stays 🟠 (kernel-limited).

---

# clade 0.3.0

## New observables

- **`n_shelter_occupied`** (new column in `get_run_data()$ticks`).
  Counts agents sitting on a sheltered cell at each tick. Paired with
  `shelter_occupancy_bonus`, this gives a direct per-tick scalar for
  the aggregate energy transfer from ancestors' niche constructions
  to extant descendants — the Odling-Smee, Laland & Feldman (2003)
  heritable-niche effect as a single log column.

## Coverage

- **`tests/testthat/test-mimicry-batesian.R`** — 11 direction-only
  assertions for the Batesian-mode code path plus a regression guard
  on the `toxicity_cost_per_tick = 2.0` default.
- **`tests/testthat/test-niche-heritable.R`** — 7 assertions covering
  `shelter_occupancy_bonus` default (0), presence of
  `n_shelter_occupied` in log, bounded by agent count, zero when
  `niche_construction = FALSE`, and directional check that the
  occupancy bonus does not reduce mean_energy.

## Continuous integration

- `.github/workflows/R-CMD-check.yaml` runs `R CMD check` on every
  push and PR to main/master. Tests and vignettes are skipped
  (require Julia, not on GH runners); the check still catches
  package-level issues (namespace, docs, DESCRIPTION).
- `.github/workflows/pkgdown.yaml` builds and deploys the pkgdown
  site on push to main/master and on release publication.

## Code quality

- `R/visualization.R`: extracted `.plot_empty(message)` helper,
  replaced nine duplicated "theme_void with annotation" fallback
  blocks. File is ~40 lines shorter; behavior byte-identical.
- `inst/julia/src/reproduce.jl`: dropped a stale "Phase 2 stub"
  remark that referred to graduate_offspring!() before it was
  wired up in commit 7ad2b1d.

## Docs — post-release refresh

- `vignettes/showcase.Rmd`: Baldwin section gains the honest
  "σ rises at defaults; CMA-ES finds a narrowing regime" caveat;
  Mimicry and Niche sections document the new 0.3.0 flags.
- `vignettes/introduction.Rmd`, `vignettes/scenarios.Rmd`: gallery
  tables surface `batesian_mimicry` and `shelter_occupancy_bonus`.
- `vignettes/s-mimicry.Rmd`, `vignettes/s-niche.Rmd`: Key-parameters
  tables gain the new flags; What-we-found sections refreshed to
  describe the current (post-0.3.0) kernel rather than the
  pre-fix state.
- `vignettes/s-parental-care.Rmd`, `s-parental-investment.Rmd`:
  re-measured at displayed specs with the fixed graduation
  pathway; What-we-found quotes updated from "n_juveniles = 0
  throughout" to the actual current trajectories.
- `vignettes/baldwin-effect.Rmd`: Addendum section documents the
  CMA-ES-discovered regime where canalization emerges
  (grass_rate 0.027, learning_rate_init_mean 0.007).
- `vignettes/figures/showcase_bnn_canalization_demo.png`:
  previously orphaned (no generator produced it); now emitted by
  `gen_fixed_patch_fig.R` under both its original filename and the
  canalization alias, keeping both Baldwin articles in sync with
  live kernel biology.

## New biological mechanisms

- **Batesian mimicry** (`specs$batesian_mimicry = TRUE`). A palatable
  mimic (toxicity = 0) whose signal matches a toxic model species
  now benefits from the predator's learned aversion — the predator
  avoids the mimic alongside true toxic prey. Repeated attacks on
  palatable mimics decay the predator's aversion memory
  (Rescorla-Wagner toward 0), reproducing the Bates–Wallace predator
  discrimination-learning cycle. Default `FALSE` — existing runs are
  byte-identical. Reference: Bates (1862) *Trans. Linn. Soc.*
  23:495–566; Ruxton, Sherratt & Speed (2004) *Avoiding Attack*.
- **Heritable niche-construction benefit**
  (`specs$shelter_occupancy_bonus > 0`). Agents occupying a
  sheltered cell receive `bonus × depth` energy per tick, the
  Odling-Smee, Laland & Feldman (2003) heritable-environment
  effect. Existing `niche_construction` semantics (grass
  suppression + persistence + decay) are unchanged; the new
  parameter is additive and defaults to 0 (no behavior change).

## Ecology corrections

- `R/run.R` `.validate_specs()` now warns when
  `spatial_sorting = TRUE` combined with `toroidal = TRUE`.
  Shine et al. (2011) invasion-front dynamics require a bounded
  grid; on a torus the population centroid wraps and the "front"
  concept is geometrically ill-posed.
- `toxicity_cost_per_tick` default raised `0.5 → 2.0`. The prior
  default equalled `idle_cost`, making toxicity effectively free
  (Zahavi 1975 handicap principle violated). 2.0 makes a
  maximally-toxic agent pay ~4× the idle baseline per tick.
- `inst/julia/src/modules/disease.jl` docstring now documents that
  transmission is **density-dependent** (per-neighbour contact, not
  `β · S · I / N` frequency-dependent SIR) and that
  `disease_duration` is a deterministic recovery period
  (delta-distribution, not exponential). Includes the mean-field
  `R0 ≈ transmission_prob × 8 × disease_duration` approximation.

## CMA-ES auto-calibration harness

- New `dev/audit/calibration/` harness drives
  `search_cmaes()` over each scenario's parameter subspace, with a
  per-scenario fitness function encoding the biological claim.
  Parallel launcher (`run_all.sh`) runs 31 scenarios concurrently.
- Full Phase 7 results in
  [`dev/audit/calibration/RESULTS.md`](dev/audit/calibration/RESULTS.md).
  Headline discoveries: a regime where the **Baldwin effect does
  emerge** (`grass_rate ≈ 0.027`, `learning_rate_init_mean ≈ 0.007`)
  in the otherwise non-canalising foraging world; a regime where
  speciation fires (`mutation_sd ≈ 1.31`); the cephalopod paradox
  (Liedtke & Fromhage 2019) reproduced at short max_age with high
  learning rate.

## Scenario audit

A systematic end-to-end audit of the 35 scenario vignettes under
`vignettes/s-*.Rmd` was performed. Each vignette's displayed code was run
against the live Julia kernel, the oracle metric trajectory inspected, and the
outcome classified. Full audit machinery ships under `dev/audit/` so this can
be rerun. Final state: 30 scenarios OK, 2 aggregate galleries (s-cross-module,
s-module-comparison) by design without a direction oracle, 2 search-only
scenarios (s-bad-science, s-map-elites) by design without trajectory output,
and 1 documented limitation (s-stress-hypermutation, flat mutation rate at
displayed defaults).

## Julia kernel

- **BNN REINFORCE score function fixed.** The previous update rule was
  `mu[i] += lr * advantage * sigma[i]`, which is not the score function of
  the Gaussian policy. The new rule
  `mu[i] += lr * advantage * (w_sample[i] - mu[i]) / sigma[i]^2` matches
  the exact score from Williams (1992) and Blundell et al. (2015) §3.2.
  A new `last_sample::Vector{Float32}` field on `BNNBrain` caches the
  Thompson-sampled weights from `forward()` for use by `bnn_update!`.
  This is likely the main reason earlier runs showed no Baldwin-effect
  sigma narrowing even in favourable regimes.
- **Parliament-of-genes penalty logic fixed** in `modules/kin.jl`. The
  counter previously included cooperators across all neighbours; now it
  counts cooperative kin separately, and the penalty fires when
  cooperative relatives outnumber non-cooperative relatives — consistent
  with Haig (2000) intragenomic conflict suppression.
- **Predator dedicated sensory architecture.** `seed_predators!` now
  builds a predator-specific brain architecture `[15, hidden..., 5]` so
  the brain's `n_inputs` matches the 15-element predator sense vector.
  Previously predators used the prey's architecture (dynamic size
  depending on `input_radius` and active sensory modules), producing a
  silent dimension mismatch whenever those defaults changed.
- **Mutation-rate evolution uses per-agent trait.** When
  `mutation_rate_evolution = TRUE`, `reproduce.jl` now reads
  `parent.mutation_sd` as the base mutation rate for meiosis. Previously
  the global `specs["mutation_sd"]` was used unconditionally, so the
  evolved trait never propagated. The stress-hypermutation multiplier
  continues to apply on top.
- **Parental-care graduation pathway wired up.** `reproduce.jl:126-131` was a
  Phase 2 stub that pushed offspring straight into `env.agents` even when
  `parental_care = TRUE`. Offspring now enter the parent's
  `carried_offspring` brood (with `care_load += 1`), age there via
  `age_juveniles!`, are fed via `feed_offspring!`, and graduate to the
  main agent pool via `graduate_offspring!` when they reach
  `juvenile_independence_age` or `juvenile_independence_energy`.
  Before the fix, `n_juveniles` was always 0 in `s-parental-care` and
  `s-parental-investment`; after, typical runs log hundreds of carried
  juveniles.
- **`randperm` now imported in `Clade.jl`.** Latent bug that only surfaced
  after the parental-care fix enabled the `graduate_offspring!` code path:
  `randperm` was referenced in `modules/parental_care.jl:153` but not
  imported in the `using Random` line.
- **Include-order fix** (`inst/julia/src/brains/ann.jl` → `bnn.jl`). The
  `_quantize_brain_weights!(::BNNBrain, ...)` method was defined in `ann.jl`
  before `bnn.jl` was loaded; on Julia 1.12 this aborts module load with
  `UndefVarError: BNNBrain`. The method now lives in `bnn.jl` alongside the
  type, matching the method's dispatch target.
- **Manifest regenerated** for Julia ≥ 1.11 compatibility (previously pinned
  to Statistics 1.10 which doesn't ship with 1.12). Project.toml is
  unchanged.

## Vignettes

- **`s-pop-genetics.Rmd` chunk rewrite.** The displayed code called
  `h2$ci` and `plot(h2)`, neither of which
  `estimate_heritability()` returns. The chunk now shows the lag-1
  autocorrelation proxy (what the function actually computes) and plots the
  mean trajectory that the proxy is derived from, with a note pointing to
  `heritability_estimate()` for the parent-offspring-regression route.
- **`DESCRIPTION`**: `tidyr` added to `Suggests` because
  `vignettes/s-kitchen-sink.Rmd` and `vignettes/s-seasonal.Rmd` call
  `tidyr::pivot_longer()`.

## Infrastructure (under `dev/audit/`)

- Rmd parser (`parse_rmd.R`) extracts displayed chunks, figure refs, and
  "What we found" prose from every scenario.
- Scenario oracle (`scenario_oracle.R`) maps vignettes to expected module
  flags and a direction-only signal oracle. Each entry carries a comment
  documenting *why* the oracle is phrased as it is, grounded in the
  vignette's own reported findings (several vignettes document honest
  negative results and the oracle matches them).
- Serial driver (`run_audit.R`) runs all scenarios in one warm Julia session
  — parallel forks deadlock JuliaConnectoR's socket; sequential is reliable
  and completes in ~5–7 min.
- Text-drift scanner (`text_drift_scan.R`) catches displayed-vs-prose
  numeric drift without running the simulation.
- Consolidation survey (`consolidation_report.md`) enumerates ~550 lines of
  refactor opportunities across `R/` and `inst/julia/src/modules/`; scheduled
  for 0.3.0.
- `tests/testthat/test-scenario-signals.R` asserts direction-only signals
  for every scenario with an oracle, robust to seed noise.

## Known limitations surfaced by the audit

These are documented in each vignette's "What we found" section and are
intentionally preserved rather than papered over:

- BNN prior sigma rises rather than narrows in a competitive foraging world
  (s-baldwin). The Baldwin effect as formalised by Hinton & Nowlan (1987)
  requires a stable global fitness peak; clade's default world does not
  provide one. The vignette's 45-run 3×3 factorial plus run-length
  experiments (500/1000/2000/5000 ticks) establish this rigorously.
- `stress_hypermutation` scales `specs["mutation_sd"]` transiently at
  reproduction rather than mutating the per-agent `ag.mutation_sd` field,
  so the logged `mean_mutation_rate` stays flat even when the mechanism
  fires. The observable signal is a transient rise in `genetic_diversity`
  during resource crashes.

# clade 0.1.1 (development)

## Bug fixes

- `plasticity_init_mean` default changed from 0.0 to 0.3. The previous default
  sat at the trait floor; mutation pressure could not push it upward, so
  `mean_plasticity` was always 0 in practice.
- `wing_size_init_mean` default changed from 0.0 to 0.08; `canopy_threshold`
  changed from 0.6 to 0.15. The previous gap between init and threshold was
  unreachable by mutation in any realistic run, so `n_canopy_agents` was always
  0.
- `signal_evolution_drift` default changed from `FALSE` to `TRUE`. Without
  drift, signals remained exactly 0 forever, making mate-choice experiments
  uninformative.

## New features

- **Lamarckian evolution** (`lamarckian = TRUE`): when `rl_mode` is not
  `"none"`, the within-lifetime RL-updated brain weights are written back to
  the parent's genome before meiosis so offspring inherit the learned solution
  directly. Implemented in `inst/julia/src/modules/lamarckian.jl`. Distinct
  from the epigenetics module (which inherits methylation marks, not weight
  values) and from the Baldwin Effect (which leaves the genome unchanged).
  References: Baldwin (1896); Weismann (1892); Jablonka & Lamb (2005).

- **Discrete / quantized ANN weights** (`ann_weight_values`): when set to a
  numeric vector (e.g. `c(-1, 0, 1)` for ternary weights), every synaptic
  weight and bias is snapped to the nearest allowed value after genome
  expression. Applies to `"ann"` and `"bnn"` brain types. Biologically
  motivated by evidence that biological synapses operate in discrete strength
  states (Bhumbra & Bhatt 2020). Enables symbolic formula distillation from
  evolved ANNs (as in the original MATLAB `alife2025usra` codebase).

- **ANN weight regularisation** (`ann_regularization`): per-tick energy
  penalty for brain weight complexity. Two modes: `"weight_magnitude"` (L1
  penalty, drives weights toward zero) and `"weight_count"` (L0-like penalty,
  fixed cost per active synapse). Scaled by `ann_regularization_lambda`
  (default 0.001). The mean weight magnitude is now logged in every run as
  `mean_ann_weight_magnitude`. References: Laughlin et al. (1998);
  Attwell & Laughlin (2001).

- **Native Julia test directory** (`inst/julia/test/`): unit tests for
  quantization, regularisation, and Lamarckian logic that can be run directly
  in Julia without the R side. Run with
  `julia --project=inst/julia inst/julia/test/runtests.jl`.

- **Module triage script** (`inst/scripts/triage_modules.R`): runs each
  module in isolation for 300 ticks and reports whether a key biological signal
  is detected (`[OK]`), absent (`[FLAT]`), or crashing (`[ERR]`). Run with
  `Rscript inst/scripts/triage_modules.R`.

- **`expect_evolution()` test helper** (in `tests/testthat/helper.R`): asserts
  that a logged trait moves directionally over a simulation run. Also
  consolidates the duplicated `skip_no_julia()` definition into `helper.R` so
  individual test files no longer need to re-define it.

- **Non-toroidal grid** (`toroidal = FALSE`): all Julia modules now use a
  `wrap_or_clamp()` helper that either wraps (toroidal) or clamps to the grid
  boundary (linear). Required for spatial sorting and invasion-front experiments
  with a defined front.
- **Carrion as pathogen reservoir** (`carrion_transmission_prob`): when
  `scavenging = TRUE` and `disease = TRUE`, agents that die while infected
  deposit a flagged carcass; any agent that scavenges from it becomes infected
  with probability `carrion_transmission_prob` (default 0.0 — off for
  backwards compatibility).
- **`batch_seeds()`**: convenience wrapper around `batch_alife()` that takes a
  single specs object and a vector of seeds and returns a named list of results.
- **`quick_specs()` / `full_specs()`**: preset specs for fast exploratory runs
  (50 agents, 200 ticks, 20×20 grid) and publication-quality runs (200 agents,
  1000 ticks, 30×30 grid).

## Logging additions

Six previously-NA log columns are now populated:

- `mean_relatedness` — mean pairwise relatedness when `kin_selection = TRUE`.
- `n_scavenge_events` — number of carrion-eating events per tick.
- `n_gd_events` — number of group-defense damage reductions per tick.
- `mean_shelter_depth` — mean shelter depth across occupied cells.
- `mean_mutation_rate` — mean evolved `mutation_sd` when
  `mutation_rate_evolution = TRUE`.
- `mean_clutch_size` — mean clutch size when `clutch_size_evolution = TRUE`.

## Other

- Social learning warning: `run_alife()` now warns when
  `social_learning = TRUE` and `n_agents_init < 100`, since neighbour density
  at that population size is rarely sufficient to trigger copying events.

# clade 0.1.0

First public release.

## Core simulation

- Agent-based evolutionary simulation running entirely in Julia via
  JuliaConnectoR, eliminating per-tick R/Julia boundary overhead.
- Toroidal grid with logistic grass regrowth and seasonal amplitude modulation.
- Diploid or haploid genome with meiosis, Mendelian dominance models, and
  configurable crossover and mutation rates.
- Six brain types: Bayesian neural network (BNN, default), multilayer
  perceptron (ANN), continuous-time RNN (CTRNN), gene regulatory network
  (GRN), random null model, and stubs for transformer and synthesis brains.
- `run_alife()` — single simulation run; returns a named list compatible with
  `get_run_data()` and `plot_run()`.
- `batch_alife()` — run multiple replicates in sequence.
- `default_specs()` — fully documented parameter list with sensible defaults.

## Optional biological modules

Each module is a no-op when its flag is `FALSE`; overhead is zero.

- **Disease / SIR** (`disease = TRUE`): stochastic transmission, energy costs,
  recovery, and immunity.
- **Kin selection** (`kin_selection = TRUE`): pedigree-based relatedness;
  donors transfer energy to the most-related Moore-neighbourhood agent above a
  relatedness threshold.
- **Cooperation** (`cooperation = TRUE`): reciprocal altruism mediated by a
  heritable cooperation-level trait.
- **Scavenging** (`scavenging = TRUE`): carrion deposited on agent death;
  scavengers gain energy from decaying carcasses.
- **Niche construction** (`niche_construction = TRUE`): agents build shelters
  that slow grass regrowth and reduce predator damage; shelters decay
  stochastically.
- **Epigenetics** (`epigenetics = TRUE`): heritable methylation marks
  canalize BNN weight uncertainty (sigma); transgenerational epigenetic
  inheritance (TEI) transmits marks to offspring with configurable probability.
- **Within-lifetime RL** (`rl_mode = "actor_critic"`): REINFORCE with
  baseline updates the output layer of each agent's neural network each tick,
  driven by energy-gain reward.
- **Social learning** (`social_learning = TRUE`): prestige-biased copying —
  agents blend a fraction of the highest-energy neighbour's output-layer
  weights into their own policy.
- **Brain size evolution** (`brain_size_evolution = TRUE`): heritable
  `brain_size` trait (Float32, reference 1.0) modelling the parental
  provisioning hypothesis (van Schaik et al. 2023; Griesser et al. 2023;
  Song et al. 2025). Larger brains incur a per-tick idle-cost surcharge
  (expensive brain hypothesis) and a proportional cognitive foraging bonus.
  The bootstrapping problem — large-brained offspring pay the metabolic cost
  from birth before their foraging advantage emerges — means brain size only
  evolves when `parental_care = TRUE` buffers the infancy energy deficit.
  A third effect — sensing quality — scales grass perception inputs by
  `brain_size ^ brain_size_sensing_exponent`, giving larger-brained agents a
  directional navigation advantage. Logged as `mean_brain_size` in
  `env$progress`. New parameters: `brain_size_evolution`,
  `brain_size_init_mean`, `brain_size_mutation_sd`, `brain_size_min`,
  `brain_size_max`, `brain_size_cost_scale`, `brain_size_sensing_exponent`.

## Parameter search

- `search_map_elites()` — MAP-Elites quality-diversity search over simulation
  parameters (Mouret & Clune 2015). Returns an archive of parameter sets
  covering a behavioural descriptor space.
- `search_cmaes()` — CMA-ES optimisation via the GA package.
- `search_gradient()` — finite-difference gradient ascent on the log parameter
  scale; backend-agnostic (no Zygote.jl dependency).

## Analysis

- `get_run_data()` — convert raw Julia environment to tidy `$ticks` and
  `$deaths` data frames.
- `estimate_heritability()` — lag-1 autocorrelation proxy for trait
  heritability (Falconer & Mackay 1996).
- `compute_ld()` — stub for linkage disequilibrium (Lewontin & Kojima 1960).
- `species_tree()` — stub for phylogenetic reconstruction.

## Visualisation

- `plot_run()` — population dynamics panel (n_agents, mean_energy,
  genetic_diversity, grass_coverage).
- `plot_environment()` — snapshot of the grid at a given tick.

## Vignettes

- *Getting started with clade* — installation, minimal run, parameter table,
  brain types, module table, disease example.
- *The Baldwin Effect* — within-lifetime RL and social learning accelerating
  genetic evolution; comparison of three conditions; epigenetic canalization.

## Testing

- 18 pure-R and Julia integration tests for RL and social learning.
- 12 tests for MAP-Elites, CMA-ES, and gradient search.
- 13 tests for epigenetics (methylation, TEI, sigma canalization).
- Full test suite covers genome, brains (ANN, BNN, CTRNN, GRN), disease, kin,
  cooperation, scavenging, niche, analysis helpers, and visualization.
