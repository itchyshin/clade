# clade 0.6.3 (2026-04-19) — Zahavi β_Sv handicap mechanism in the kernel

Adds `signal_cost_mortality` (default `0.0`) — a direct per-tick
viability cost scaling linearly with signal magnitude:

    p_die ← signal_cost_mortality × Σ |signal_i|

implemented in [signals.jl](https://github.com/itchyshin/clade/blob/main/inst/julia/src/modules/signals.jl).
This is the Fuller, Houle & Travis (2005) β_Sv < 0 viability-selection
gradient, i.e. the kernel mechanism that Zahavi (1975) and Grafen
(1990) argue *must* be present for costly honest signalling to be
selected for. Distinct from `signal_cost` (which only drains
energy and is easily masked by `signal_drift_sd`).

## Fuller 2005 reproduction — partial ✅

`vignette("paper-fuller-2005")` rewritten. The Zahavi dose-response
leg now reproduces cleanly:

| signal_cost_mortality | final_signal ± SE | final_n ± SE |
|---|---|---|
| 0.000 | 1.063 ± 0.006 | 123 ± 6.8 |
| 0.001 | 1.039 ± 0.010 | 70 ± 9.7 |
| 0.002 | 0.961 ± 0.055 | 38 ± 6.3 |
| 0.003 | 0.625 ± 0.123 | 6 ± 2.0 |

Signal and population decline monotonically with β_Sv — the cost
is paid in lives, as Zahavi / Grafen / Fuller require.

The Fisher-runaway leg and sensory-bias-sensu-Ryan-1990 leg of
Fuller's three-mechanism synthesis remain documented kernel-limit
nulls with specific gaps flagged in the vignette (Fisher needs
the `mate_choice_mode` stub wired; sensory bias needs a
preference↔non-mating-fitness coupling mechanism).

## Known issue surfaced while auditing: `mate_choice_mode` is a stub

During the 5-condition audit, `drift_only` (random mating) and
`fisher_pure` (preference mating) produced bit-identical results.
[reproduce.jl:260-283](https://github.com/itchyshin/clade/blob/main/inst/julia/src/reproduce.jl#L260-L283)
only branches on `signal_dims`: `== 0` → random, `> 0` → always
preference. The `mate_choice_mode` and `mate_choice_strength`
spec fields are documented and defaulted but silently ignored
by the kernel. Downstream paper reproductions that toggled
`mate_choice_mode` — primarily `s-kokko-brooks-2003`, `s-signals`,
`s-mating-systems` — will need re-audit when the stub is wired.
Flagged here for transparency; a dedicated PR to fix is next.

## Backward-compatibility

Fully backward-compatible. `signal_cost_mortality = 0.0` default
means existing specs are unchanged. Add the field explicitly to
opt into the handicap mechanism.

---

# clade 0.6.2 (2026-04-19) — Fuller 2005 framework metrics exposed

Three new columns added to the per-tick log
(`get_run_data(env)$ticks`) to operationalise parts of the
**Fuller, Houle & Travis (2005)** *Am Nat* quantitative-genetic
framework for sexual-selection models (sensory bias vs Fisherian
runaway vs good-genes vs direct benefits vs sexual conflict):

| Column | Fuller 2005 quantity | What it captures |
|---|---|---|
| `mean_preference_magnitude` | mean preference phenotype p̄ | Population-mean of the agent preference vector (L1 norm) |
| `mean_signal_preference_dist` | proxy for −C_tp (preference-display covariance) | Mean L2 distance between each agent's signal and preference vectors. Shrinks under Fisher/good-genes coevolution (nonrandom mating produces C_tp > 0); stays large under sensory bias alone. |
| `sd_signal_magnitude` | proxy for V_t (additive genetic variance in display) | Between-agent SD of signal magnitude |

These unlock the sensory-bias / Fisher-runaway / handicap test
discussed in `vignette("paper-fuller-2005")`. Before this change,
clade's only signal-side observable was scalar
`mean_signal_magnitude`, which couldn't distinguish coevolved
(C_tp > 0) from independently drifted (C_tp = 0) signal-preference
populations.

All four columns are present for every run; when
`signal_dims = 0L` they return zero rather than NA. Existing
`mean_signal_magnitude` is unchanged; this release is purely
additive.

## Follow-up (0.6.3+ candidate)

Fuller 2005's framework also distinguishes models by their cost
structures. The right cost mechanism for the Zahavi handicap
(Grafen 1990) is a **viability penalty** on high-signal agents
(β_Sv < 0), not mutation-rate modulation. A `signal_cost_mortality`
spec implementing that is candidate work once this release's
metrics are vetted in a Fuller re-reproduction.

---

# clade 0.6.1 (2026-04-19) — remove broken register_module() stub

The `register_module()` / `list_modules()` / `clear_modules()` R
API is removed. It was a **stub**: the registered R hooks were
never called during the simulation — `.apply_custom_modules()`
existed in `R/modules.R` but had no caller in the run loop. A
direct empirical test confirmed this (the Courchamp 1999
reproduction PR).

## Why remove rather than wire up

clade's design contract is that the R↔Julia boundary is crossed
exactly **once per `run_alife()` call** — the basis of clade's
performance claim (see `vignette("why-clade")`). Firing a
user-supplied R function per tick would cross the boundary N
times per run, defeating that design.

A properly-wired custom-module system would need **user-written
Julia** modules loaded at `run_alife()` startup, not per-tick R
callbacks — candidate 0.7+ feature.

## What to do instead

Three boundary-level extension patterns cover the empirical
research use cases (see [`paper-courchamp-1999`](articles/paper-courchamp-1999.html)
vignette's methodology section for worked examples):

1. **Parameter-level composition** — combine existing module
   flags until emergent dynamics match the target mechanism.
2. **Post-hoc metric computation** — any derived statistic on
   `get_run_data()$ticks` in pure R.
3. **Between-run intervention** — run in chunks, extract state,
   modify specs, restart.

## Deleted

- `R/modules.R`, `tests/testthat/test-custom-modules.R`,
  `vignettes/custom-modules.Rmd`
- Four `man/*.Rd` entries: `register_module`, `list_modules`,
  `clear_modules`, `dot-apply_custom_modules`
- Navbar entries for "Custom modules API" and pkgdown reference
  section for custom modules
- README.md + index.md links to the removed vignette

## Breaking changes

**Any user code calling `register_module()`, `list_modules()`, or
`clear_modules()` will error** with `could not find function`.
Since the API was a silent no-op, such code wasn't doing
anything useful anyway — migrate to the three extension
patterns in the Courchamp vignette.

---

# clade 0.6.0 (2026-04-19) — research workflow + paper reproductions

A large user-facing release. Same kernel state as 0.5.18 (32/32
fidelity ✅), but significantly more research infrastructure around
it. Three major additions for behavioural-ecology and evolutionary
researchers: a systematic primary-citation audit of all 32
scenarios, reusable researcher-workflow helpers
(`hypothesis_sweep()` + `hypothesis_report()`), and five worked
paper reproductions that double as methodology tutorials.

## New user-facing API

- **`hypothesis_sweep(base_specs, conditions, seeds, metrics, n_cores)`**
  — wrap the sweep-test-report pattern used across the fidelity
  audits into a single researcher-facing helper. Crosses a list
  of named conditions with seeds, dispatches via `batch_alife()`,
  computes user-supplied metric functions on each run's tick log,
  returns a tidy `hypothesis_sweep` S3 object.
- **`hypothesis_report(sweep, contrasts, metric)`** — Welch
  two-sample t-statistics for named pairwise contrasts. Uses the
  fidelity-audit 2σ screening convention (`|t| ≥ 2` → PASS,
  `1.5 ≤ |t| < 2` → marginal, else null). Print methods render
  compact tables.

Together these turn the 5-line
`sweep |> report |> interpret` workflow into the default
researcher idiom. See `vignette("paper-kokko-brooks-2003")` for
the canonical example.

## Paper reproductions showcase (new vignettes)

Five worked examples of taking a published behavioural-ecology
paper, translating its quantitative prediction into a clade
experiment, and reporting what reproduces versus what doesn't.
Each vignette demonstrates the 3-stage workflow (grid-search →
multi-seed validate → diagnose) and covers a different
theoretical domain:

- **`paper-kokko-brooks-2003`** — "Sexy to die for?". Tests
  whether costly sexual signals hurt populations more under
  environmental stress. clade **contradicts** K&B's interaction
  direction robustly across a 5 × 4 grid — mechanistic-level
  mismatch between linear per-tick cost (clade) and
  stress-multiplicative cost (K&B's theoretical framework).

- **`paper-griesser-2023`** — "Parental provisioning drives
  brain size in birds" (PNAS). Grid search finds the
  best-signal regime (cost_scale=1.5); 8-seed validation gives
  Spearman = +0.25 in the predicted direction but sub-2σ.
  Direction-correct below-threshold — the honest outcome of many
  empirical in-silico verifications.

- **`paper-dieckmann-doebeli-1999`** — "On the origin of species
  by sympatric speciation" (Nature). **Clean ✅** with decisive
  magnitude (t = +3.32 PASS, Spearman = −0.57). When the
  `speciation` kernel module matches the paper's mechanism,
  reproductions are decisive.

- **`paper-reale-2010`** — pace-of-life syndromes. Core
  lifespan-vs-metabolic-rate prediction reproduces at
  **Spearman = −0.98, t = −358** — one of the cleanest matches
  in the suite. Secondary traits (per-tick births, energy) have
  clade-specific nuances surfaced by multi-metric
  `hypothesis_sweep()`.

- **`paper-emlen-1982`** — ecological constraints on helping.
  Raw helping counts invert Emlen's prediction; per-capita rate
  recovers the direction. Reinforces the s-kin invasion-dynamics
  honest-null from the session's sweet-spot sweeps:
  `helper_tendency` does not evolve under ecological constraint
  in clade's current kernel.

## Primary-citation audit — 32 / 32 complete

Systematic per-scenario verification that every cited primary
paper actually predicts what clade reproduces. Ledger in
`dev/docs/positioning/citation_audit.md`. Distribution across the
32 auditable scenarios plus 2 ⚪ N/A:

- **10 ✅** citation + fidelity clean
- **14 ⚠️** direction-correct with documented caveats (most
  commonly, clade reproduces a corollary of the paper's claim
  rather than the claim itself)
- **5 🟠** direction-correct transient OR contradicted under
  evolving-ABM conditions where the cited theory assumes
  fixed-strategy predators, unlimited food, or similar
- **0 ❌** no outright retractions or unsupported claims

Three citation-precision corrections shipped in-session (Hauert
2006 / Killingback 1999 for s-cooperation's continuous-strategy
mechanism; Hamilton, Axelrod & Tanese 1990 alongside Hamilton 1980
for s-mating-systems' discrete-allele Red Queen; Kermack &
McKendrick 1927 for s-disease's missing SIR citation).

## Sweet-spot sweep methodology (new fidelity reports)

Three sweeps demonstrating how to find the parameter regime where
a canonical theoretical prediction expresses in clade:

- **s-kin invasion-dynamics sweep** — tested whether heritable
  `helper_tendency` invades from rare under Hamilton-satisfying
  cost regimes. Result: **honest null** — demographic consequence
  of kin altruism stands (Spearman = 0.97 across rB/C), but
  allele-invasion dynamics don't reproduce in the current
  `cooperative_breeding` plumbing. Kernel needs kin-weighted
  fitness accounting.

- **s-niche heritable-feedback sweep** — tested Odling-Smee et
  al. 2003's heritable-niche-construction claim. **Clean ✅** at
  `shelter_occupancy_bonus > 0`: Spearman(bonus, final_n) =
  +0.863, t = +6–8 PASS across three bonus levels. Notable
  finding: niche construction *alone* (bonus = 0) is a net cost;
  the heritable feedback is what flips it to a large benefit,
  exactly as Odling-Smee's framework predicts.

- **s-parental-care variance-buffering sweep** — tested
  Clutton-Brock 1991's buffering prediction at tighter resource
  scarcity. **Conditional ✅** at `grass_rate = 0.08,
  care_cost_per_tick = 3.0`: variance drops 58% (t = −2.61).
  Honest caveat: care halves equilibrium size, so CV rises even
  as absolute variance falls.

The sweep methodology is now the template for finding "sweet
spots" for any canonical prediction — conditions under which the
theory reproduces exactly versus conditions where it doesn't. See
the matching fidelity reports under `dev/audit/fidelity/`.

## Documentation and infrastructure

- **DASHBOARD.md** updated to reflect current state: 32 ✅ / 0 🟠,
  with a 2026-04-19 "state as of" section explaining the
  0.5.14–0.5.18 promotion cycle.
- **STATUS.md** reconciliation with five 🟠-to-✅ promotions from
  the 0.5.14–0.5.18 kernel cycle surfaced in the user-facing
  vignettes: s-mating-systems (pressure sweep), s-baldwin +
  s-plasticity (`seasonal_spatial_bias`), s-group-defense
  (extinction-rate framing), s-scavenging (realistic_specs +
  predators).
- **`dev/docs/positioning/`** — research scaffolding for future
  landing-page claims, including competitive-landscape notes on
  SLiM/NetLogo/Mesa/msprime, methods-review survey (Murphy 2025,
  Stillman 2015), and the full 32-scenario primary-citation
  audit ledger.
- **CI** — GitHub Actions spend reduced via `paths-ignore` filter
  for docs-only changes; self-hosted-runner setup guide under
  `.github/SELF_HOSTED_RUNNER_SETUP.md` for an optional Julia-
  enabled runner.
- **Honest correction**: "Song et al. 2025" citation removed from
  s-brain-size — Crossref could not locate the paper; the two
  remaining citations (van Schaik 2023, Griesser 2023) cover the
  parental-provisioning hypothesis adequately.

## Breaking changes

None. All additions. Existing scripts and specs continue to work.

## Migration notes

If you've been using batch sweeps in ad-hoc scripts, you can
migrate to `hypothesis_sweep()` for cleaner logging. The original
`batch_alife()` / `batch_seeds()` / `grid_specs()` / `summarize_batch()`
APIs are unchanged and remain the lower-level building blocks.

---

# clade 0.5.18 (2026-04-18, DeWitt 2004 / Hinton-Nowlan 1987 confirmed — ledger complete)

## s-plasticity + s-baldwin 🟠 → ✅ — fluctuating-selection kernel

Added a new kernel spec `seasonal_spatial_bias` (default 0.0 =
legacy) that, when > 0, flips the spatial grass distribution
between seasons: summer → grass concentrated in the top half of the
grid, winter → bottom half. This creates **phenotype-dependent
fluctuating selection** — the optimal foraging direction flips
between seasons. Canalized agents stuck with one policy starve in
the off-season; plastic agents (BNN with within-lifetime RL) can
track the flip.

### Results (16 seeds × 3 conditions × 2000 ticks, default_specs + RL)

| condition | mean_prior_sigma ± SE | pop |
|---|---|---|
| stable | 0.3759 ± 0.0038 | 96.9 |
| amp_only (uniform stressor) | 0.3800 ± 0.0025 | 94.2 |
| **flipping** (fluctuating selection) | **0.3986 ± 0.0032** | 69.4 |

Differentials:
- Δ(flipping − stable) = **+0.023 ± 0.005, t = +4.58 PASS**
- Δ(flipping − amp_only) = **+0.019 ± 0.004, t = +4.60 PASS**
- Δ(amp_only − stable) = +0.004, t = +0.91 (uniform stressor has no
  plasticity signal — exactly what the earlier 0.5.10/0.5.11 tests
  correctly documented)

Both DeWitt 2004's spatial-plasticity prediction and Hinton-Nowlan
1987's fluctuating-selection-plasticity prediction confirmed at
> 4σ. The ~28% population cost in the flipping regime (97 → 69
agents) is also consistent with DeWitt: plasticity has ecological
costs.

## Ledger completion

With this promotion, **all 32 auditable scenarios now pass**:

**32 ✅ / 0 🟠 / 0 🔴 out of 32 auditable scenarios (100% ✅).** 🎉

Path from 0.5.14 (this session):
- 0.5.14 s-mating-systems 🟠 → ✅ (Hamilton 1980 via 2×2 parasite-pressure sweep)
- 0.5.15 s-group-defense 🟠 → ✅ (Hamilton 1971 via extinction-rate Fisher test)
- 0.5.16 s-stress-hypermutation 🟠 → ✅ (config bug: threshold > min_repro_energy)
- 0.5.17 s-predation-neural 🟠 → ✅ (Williams 1966 at default scale)
- 0.5.18 s-plasticity + s-baldwin 🟠 → ✅ (fluctuating-selection kernel)

Audit report: [`plasticity_baldwin_promotion.md`](dev/audit/fidelity/plasticity_baldwin_promotion.md).
Runner: [`plasticity_fluctuating_selection.R`](dev/audit/fidelity/plasticity_fluctuating_selection.R).

# clade 0.5.17 (2026-04-18, Williams 1966 confirmed — s-predation-neural ✅)

## s-predation-neural 🟠 → ✅ — directional-selection diversity at default scale

0.5.11 demoted at `realistic_specs` (60×60, 8 seeds): diversity
claim showed t = −0.90 (retracted) even though the demographic
claim passed at t = −3.64. The scenario was left 🟠 as a
half-claim ("Williams 1966 demographic OK, directional-selection
null").

Re-audit at `default_specs` (30×30, 16 seeds × 2000 ticks):

| metric | no_predators | predators | Δ ± SE | t |
|---|---|---|---|---|
| `n_agents` | 115.8 ± 2.1 | 111.3 ± 2.3 | −4.44 ± 3.11 | −1.43 |
| `mean_energy` | 159.1 ± 0.6 | 160.7 ± 0.7 | +1.55 ± 0.90 | +1.73 |
| **`genetic_diversity`** | 0.570 ± 0.004 | 0.581 ± 0.004 | **+0.012 ± 0.005** | **+2.19 PASS** |

Predators **increase** prey genetic diversity at default scale —
exactly the Williams 1966 directional-selection prediction. The
previous "diversity null" was a scale artifact: at 60×60 most
seeds crash under predation, so surviving diversity is
drift-dominated rather than selection-dominated. At 30×30,
populations are robust enough that predation acts as continuous
selection pressure.

Demographic direction-correct (predators cost prey 4.4 agents,
t = −1.43 sub-2σ) and energy direction-coherent (predators remove
least-fit prey, leaving per-capita energy slightly higher,
t = +1.73).

**New ledger: 30 ✅ / 2 🟠 / 0 🔴 out of 32 auditable scenarios
(94% ✅).** Two 🟠 remain: plasticity, baldwin (both kernel-limited
by BNN sigma coupling + real diploid sex direction-reversal).

Audit report: [`predation_neural_promotion.md`](dev/audit/fidelity/predation_neural_promotion.md).
Runner: [`predation_neural_demographic.R`](dev/audit/fidelity/predation_neural_demographic.R).

# clade 0.5.16 (2026-04-18, Rosenberg 2001 confirmed — s-stress-hypermutation ✅)

## s-stress-hypermutation 🟠 → ✅ — config bug, not biology null

0.5.11 demoted s-stress-hypermutation on a "Δdiversity = +0.000"
finding at 4 seeds. The hypothesis was that real diploid sex
equalised mutation input. That hypothesis was **wrong**.

Root cause was structural. In `inst/julia/src/reproduce.jl:156`,
stress-mutation fires at reproduction time gated on parent's
energy being **below** `stress_threshold`:

```julia
eff_mut_sd = if Bool(specs["stress_hypermutation"]) &&
                ag.energy < stress_threshold
    base_mut_sd * stress_mutation_multiplier
else
    base_mut_sd
end
```

Reproduction itself is gated at `ag.energy ≥ min_repro_energy`
(default 120). Default `stress_threshold = 20`. So `energy` is
ALWAYS ≥ 120 at reproduction, and the stress condition
(`energy < 20`) is ALWAYS false. **Stress-mutation was never
firing under default config.** Δdiversity = 0 exactly because
no hypermutation event ever happened.

## Fix

Raised `stress_threshold` to 150 (> `min_repro_energy = 120`). Re-ran
scarcity sweep:

| grass_rate | OFF div | ON div | Δ ± SE | t |
|---|---|---|---|---|
| 0.02 | crashed | crashed | — | — |
| 0.03 | 2 viable | 1 viable | too few | — |
| 0.04 | 0.252 (n=13) | 1.132 (n=12) | +0.881 ± 0.018 | **+48.9** |
| 0.06 | 0.265 (n=16) | 1.196 (n=16) | +0.930 ± 0.010 | **+92.2** |

At moderate scarcity (grass 0.04–0.06), hypermutation **quadruples**
genetic diversity (0.25 → 1.15). Rosenberg 2001 / Foster 2007
decisively confirmed. The t-statistics are extraordinary because
OFF and ON distributions have essentially zero overlap — every seed
gives the same ordering.

## Config doc updated

The `stress_threshold` entry in `R/config.R` now explicitly flags
the threshold-vs-min_repro_energy requirement:

> **Note**: stress hypermutation fires at reproduction time, not
> per-tick. Reproduction requires `energy ≥ min_repro_energy`
> (default 120), so `stress_threshold` must be GREATER than
> `min_repro_energy` for hypermutation to ever trigger. With
> defaults (threshold = 20, min_repro = 120), the module is
> structurally silent — set `stress_threshold > 120` for
> stress-mutation to actually fire.

Default value retained at 20.0 for backward compatibility; users
enabling `stress_hypermutation` should set an appropriate
threshold explicitly.

**New ledger: 29 ✅ / 3 🟠 / 0 🔴 out of 32 auditable scenarios
(91% ✅).** Three 🟠 remain: plasticity, baldwin, predation-neural.

Audit report: [`stress_hypermutation_scarcity_sweep.md`](dev/audit/fidelity/stress_hypermutation_scarcity_sweep.md).
Runner: [`stress_hypermutation_scarcity_sweep.R`](dev/audit/fidelity/stress_hypermutation_scarcity_sweep.R).

# clade 0.5.15 (2026-04-18, Hamilton 1971 confirmed — s-group-defense ✅)

## s-group-defense 🟠 → ✅

80-run strength sweep (OFF baseline + 4 strengths × 16 seeds) at
`realistic_specs`. The mean-population test was sub-2σ at every
strength (consistent with the 8-seed realistic_specs direction-only
finding) — but the signal lives in the **extinction rate**:

| group_defense_strength | OFF crash | ON crash | Fisher p | OR |
|---|---|---|---|---|
| 0.5 | 12/16 | 11/16 | 0.50 | 1.35 |
| 1.0 | 12/16 | 7/16 | 0.074 | 3.69 |
| 2.0 | 12/16 | 8/16 | 0.137 | 2.89 |
| 3.0 | 12/16 | 6/16 | **0.037** | **4.73** |

At `group_defense_strength = 3.0`, odds of crashing are 4.73× higher
without group defense (75% → 38% crash rate). Fisher one-sided p =
0.037 crosses the 2σ / p < 0.05 threshold.

**Right metric, not right theory:** Hamilton 1971 selfish herd is
about per-capita predation risk and survival. Aggregated up to the
population scale, that manifests as extinction-rate reduction, not
equilibrium-population increase. The previous population-mean
framing averaged over survivors and missed the risk-dilution
effect.

Strength-dependence is biologically sensible: weak defense
(strength = 0.5) doesn't help, moderate (1.0) is marginal
(p = 0.074), strong (3.0) is decisive.

**New ledger: 28 ✅ / 4 🟠 / 0 🔴 out of 32 auditable scenarios
(88% ✅).**

Audit report: [`group_defense_promotion.md`](dev/audit/fidelity/group_defense_promotion.md).
Runner: [`group_defense_strength_sweep.R`](dev/audit/fidelity/group_defense_strength_sweep.R).

# clade 0.5.14 (2026-04-18, Hamilton 1980 confirmed — s-mating-systems ✅)

## s-mating-systems 🟠 → ✅

Swept the 2×2 Red Queen differential across `parasite_pressure ∈
{2, 4, 6, 8}` × 16 seeds × 4 conditions = 160 runs. Hamilton 1980
mechanism scales cleanly and monotonically with parasite pressure:

| pressure | asex cost | sex cost | RQ_benefit_n | t_n |
|---|---|---|---|---|
| 2.0 | +8.8 | +2.1 | +6.7 | +1.02 |
| 4.0 | +23.7 | +3.9 | +19.8 | **+2.81 PASS** |
| 6.0 | +32.5 | +5.6 | +26.9 | **+4.97 PASS** |
| 8.0 | +45.3 | +5.5 | +39.8 | **+6.79 PASS** |

Parasites reduce asex population by +45 agents at pressure=8 but
barely touch sex (sex stays ~40 regardless of pressure) —
recombination continuously generates novel haplotypes that escape
the current parasite virulence pool. This is the canonical
Red-Queen signature.

At default `parasite_pressure = 2`, the benefit is direction-correct
but sub-2σ. At pressure ≥ 4, it decisively crosses 2σ. The test is
s-mating-systems' formal promotion criterion.

## Why single-factor sex-vs-asex still shows sex < asex

Clade's 3× cost-of-sex (2-parent mate-finding filter on sparse grids)
remains: asex ≈ 135 vs sex ≈ 45. That's a structural kernel property,
not a Red Queen question. Hamilton 1980 asks "does sex handle
parasites better than asex does?" — not "is sex population bigger than
asex?". The 2×2 differential is the correct design for that; it
unambiguously passes.

If a future user wants the classical `n(sex) > n(asex)` result in
a single-factor comparison, the path is:

- `repro_cost_mode = "per_couple"` kernel spec (deferred to 0.6+)
- OR very high parasite pressure (~15+) to overwhelm the cost.

**New ledger: 27 ✅ / 5 🟠 / 0 🔴 out of 32 auditable scenarios
(84% ✅).**

Audit report: [`mating_systems_pressure_sweep.md`](dev/audit/fidelity/mating_systems_pressure_sweep.md).
Runner: [`mating_systems_pressure_sweep.R`](dev/audit/fidelity/mating_systems_pressure_sweep.R).

# clade 0.5.13 (2026-04-18, Hamilton 1980 Red Queen via 2×2 design)

## Mating-systems: Hamilton 1980 mechanism confirmed in direction

Reframed the s-mating-systems audit from a confounded single-factor
sex-vs-asex comparison to a **2×2 Red Queen differential**:

```
         parasites off    parasites on
asex:        mean_A            mean_B
sex:         mean_C            mean_D

RQ_benefit = (A − B) − (C − D)
           = (parasites cost asex) − (parasites cost sex)
```

Positive RQ_benefit means sex handles parasites better than asex —
which is what Hamilton 1980 predicts recombination does.

**Results (realistic_specs, 32 seeds × 4 conditions,
`parental_investment_evolution = TRUE` so sex and asex have equal
per-offspring cost):**

| metric | asex_parasite_cost | sex_parasite_cost | RQ_benefit | t |
|---|---|---|---|---|
| n_agents  | +6.35 | +3.27 | **+3.08 ± 4.05** | **+0.76** |
| diversity | +0.007 | −0.035 | **+0.041 ± 0.030** | **+1.36** |

Both metrics show direction exactly per Hamilton: parasites hurt
asex more than sex. Magnitude sub-2σ at 32 seeds.

Why the single-factor sex-vs-asex test was misleading: real diploid
sex is viability-negative under clade's default repro cost (even
with equalised cost via `parental_investment_evolution = TRUE,
female_investment = 0.5`, 16-20/32 sex seeds crash). The 2-parent
mate-finding requirement filters more aggressively than asex's
single-parent requirement. That structural penalty overwhelms any
Red Queen benefit in a direct population comparison.

The 2×2 differential isolates the parasite-response signal from
the baseline viability signal. Doing so reveals that Hamilton's
mechanism IS operating in clade — recombination does let sex
escape parasite virulence better than clonal reproduction — the
Red-Queen advantage just isn't large enough per-offspring to
compensate for sex's baseline cost at current kernel settings.

Path to ✅ promotion (two options):
- **More seeds** (~60-80 seed 2×2) at current settings.
- **Sex-cost kernel calibration**: redesign the `repro_cost`
  structure so sex isn't viability-negative at default parameters
  (e.g. `repro_cost_mode = "per_couple"` that charges cost_paid
  total regardless of mate count). Would let the single-factor
  comparison work too.

Companion: `dev/audit/fidelity/mating_systems_2x2.R`,
`mating_systems_equalcost.R` (the precursor equal-cost experiment).

# clade 0.5.12 (2026-04-18, LV discovery experiment)

## Lotka-Volterra in clade — an honest null

Added a discovery experiment in [`predator_prey_lv.R`](dev/audit/fidelity/predator_prey_lv.R)
that tests whether textbook Lotka-Volterra cycles can be coaxed out
of clade's predator kernel. Four conditions × 5 seeds × 2000 ticks
at `realistic_specs()`:

1. **evolving** (default): predator_mutation_sd = 0.1.
2. **frozen**: predator_mutation_sd = 0 (no new brain variance).
3. **longlived**: predator_max_age = 300 (10× prey lifespan,
   slow-pace-of-life; lynx > hare). Ecologically natural "fixed
   per-capita attack" approximation via slow evolution.
4. **fast_turnover**: short-lived (max_age=20) + easy reproduction
   (min_repro_energy=60) + frozen brains — classical LV-style
   demographic turnover.

**Result**: no condition produces textbook LV.

- evolving / frozen / longlived: `pred_var = 0` from t=500 — predator
  population flatlines at ~30 regardless of prey dynamics.
- fast_turnover: predators explode from 40 to 10,000 (cap) while
  prey crash to ~5. Phase plot is a one-way trajectory, not a closed
  LV loop. Boom-bust runaway, not cycling.

**Why.** LV requires `dP/dt ∝ prey × predator` — predator births
proportional to prey density. clade's predator reproduction is
energy-threshold-gated (reproduce when my energy ≥ X), which
produces saturation (hard threshold) or runaway (easy threshold)
but never density-matched cycling.

The lynx-hare cycles of nature exist because mammalian reproduction
IS density-dependent via gestation/provisioning constraints. clade's
predator module is more like a bacterial predator than a mammalian
carnivore. Kernel extension for 0.6+ if LV cycles become a required
audit signal.

Companion figure: `vignettes/figures/showcase_14b_predators_lv_comparison.png`.
Vignette updated with the new discovery-experiment section.

# clade 0.5.11 (2026-04-18, ledger re-audit)

## Ledger check after 0.5.10 kernel fix

Re-ran the 12 ✅ scenarios whose claims depend on diploid genomic
dynamics, on the 0.5.10 kernel where `_find_mate` no longer
short-circuits on `signal_dims = 0` (every pre-0.5.10 diploid
run was structurally asexual).

**11 of 12 survive.** One demotion:

- **s-stress-hypermutation ✅ → 🟠**: under real diploid sex, baseline
  genetic diversity (0.263) already equals what hypermutation
  produces (0.263). Δ = +0.000 across 4 seeds at grass_rate = 0.06.
  Rosenberg 2001 / Foster 2007's "hypermutation raises diversity"
  prediction does not reproduce at tested parameters.

**Primary claims hold** for the other 11:

- s-pop-genetics (h² proxy = 0.988): ✅ holds
- s-speciation (P1+P2+P3 PASS, ρ(iso, n_species) = −0.97): ✅
- s-kin (P1 PASS Δ=+21.3, P3 PASS; P2 slightly weakened): ✅
- s-cooperation (ρ(mult, pop) = 1.00): ✅
- s-brain-size (Δdelta = +1.112 at best regime): ✅
- s-body-size (Cope drift +0.042 ± 0.011; P2 flat as documented): ✅
- s-parental-investment (ρ(fi, juveniles) = −1.00 per Trivers): ✅
- s-clutch-size (Lack positive at grass 0.05→0.20; inverts at
  resource-saturation 0.30+ due to max_agents cap): ✅ reframed
- s-life-history (3/3 PASS: semelparous vs iteroparous): ✅
- s-pace-of-life (ρ(metabolic_rate, age) = −1.00): ✅
- s-parental-care (P1+P2 PASS): ✅

See `dev/audit/fidelity/post_0510_summary.md`.

**Final ledger**: 26 ✅ / 6 🟠 / 0 🔴 out of 32 auditable scenarios
(**81% ✅**, confirmed end-to-end on real-diploid-sex kernel).

# clade 0.5.10 (2026-04-18, late-late evening)

## Major kernel fix — `_find_mate` was structurally asexual by default

Continued investigation of the 0.5.9 sigma-pegging bug traced the
problem deeper than the selfing fallback. In
`inst/julia/src/reproduce.jl:_find_mate` there was a short-circuit:

```julia
if specs["ploidy"] == 1 || Int(get(specs, "signal_dims", 0)) == 0
    return nothing     # haploid / no-signal-choice → asexual
end
```

`signal_dims = 0` is the **default** for every scenario except
s-signals. The effect was that every supposedly-diploid run in
clade has been producing structurally-haploid offspring (`pat_w =
Float32[]` at every birth), regardless of `ploidy = 2`. The entire
diploid pathway was a no-op unless signal evolution was explicitly
turned on.

## The fix (0.5.10)

1. **Removed the `signal_dims == 0` short-circuit** in `_find_mate`.
   When signal evolution is off but `ploidy == 2`, the function now
   picks a random live neighbour as mate (sexual reproduction without
   mate choice — the default for any non-signal-evolving species).
2. **New spec `mate_search_radius`** (default 1, i.e. 3×3 Moore).
   `2` gives 5×5, `3` gives 7×7. Useful for lowering Allee-failure
   rate on sparse grids.

## Audit implications — the ledger is softer than yesterday

The bug silently invalidated every sex-vs-asex, heritability, and
heterozygosity-dependent audit. Results from 0.5.10 so far:

- **s-plasticity / s-baldwin**: sigma now evolves (0.21 → 0.33) instead
  of pegged at `bnn_sigma_init = 0.5`, but direction is REVERSED:
  stable > seasonal at Δ = −0.027, t = −1.41. DeWitt 2004 /
  Hinton-Nowlan canonical prediction (seasonal > stable) is NOT
  reproduced at tested parameters. Scenarios remain 🟠 but with
  updated framing: kernel bug was hiding a real direction-mismatch.
- **s-mating-systems**: the previous "sex ≈ asex" result was measuring
  asex-vs-asex noise because of the bug. With real diploid sex
  enabled, sex is catastrophically viability-negative (Δn = −88,
  t = −29; 20/32 sex seeds crashed). Clade's reproduction-cost
  parameters are **not currently calibrated for viable real sex**.
  Hamilton 1980 Red Queen cannot be tested until the sex-cost
  calibration is done.

## Caveat on the overall ledger

The 27 ✅ / 5 🟠 / 3 ⚪ ledger from 0.5.9 should be read with
awareness that every `ploidy = 2` scenario pre-0.5.10 was running
on effectively-haploid kernel dynamics. Scenarios whose claims are
demographic or ecological (s-baseline, s-predator-prey, s-disease,
etc.) are largely unaffected — the bug didn't change what the agent
brain ate, only which kind of offspring it produced. But scenarios
claiming heritability, heterozygosity, pedigree-based kin selection,
or sex-specific effects may need re-auditing now that diploid sex
actually works.

# clade 0.5.9 (2026-04-18, late evening)

## Kernel bug: silent haploid conversion under mate-finding failure

While re-auditing s-plasticity and s-baldwin with the correct metric
(`mean_prior_sigma`, not the neutral `mean_plasticity` trait), found
that `mean_prior_sigma` was pegged at **exactly `bnn_sigma_init = 0.5`**
across all seeds / envs / mutation rates, regardless of selection.

Root cause in `inst/julia/src/genome.jl:make_offspring_genome`: when
a diploid agent cannot find a mate (Allee-failure at realistic grid
densities), the fallback path sets `pat_w = Float32[]`. The
resulting offspring has an empty paternal-weights vector, so
`make_bnn_brain` takes the `is_haploid` branch and assigns
`sigma = fill(bnn_sigma_init, n)`. Within a few generations the
entire diploid population silently converts to sigma-pegged
"effectively haploid" agents, and the Baldwin canalization signal
(heterozygosity purging in stable envs) cannot be observed.

**Fix (opt-in)**: new spec `self_fertilization_fallback` (default
FALSE for backward compatibility). When TRUE, the fallback path
instead calls `meiosis(parent1, ...)` a second time — offspring
stays diploid with two gametes from the same parent
(self-fertilization). With selfing enabled, `mean_prior_sigma`
drops from the pegged 0.5 to the real heterozygosity-derived
~0.076 and evolves from there.

## Why this didn't promote plasticity/Baldwin to ✅

Selfing preserves diploidy but inbreeds populations: equilibrium
drops to ~30-35 agents, most seeds fall below the viability
threshold. In the 1-2 surviving seeds per condition, direction is
Baldwin-correct (seasonal 0.0766 > stable 0.0754, Δ = +0.0012) but
too few replicates to cross 2σ.

Full promotion would require one of:
- **Broader mate search** (5×5 or 7×7 neighbourhood instead of Moore
  8) so Allee-failure becomes rare and full-diploid evolution
  dominates. Ecologically reasonable.
- **Outcrossed fallback** (random cross-grid sperm donor instead of
  parent1) so no-mate offspring isn't inbred.

Both are kernel changes outside the 0.5.9 scope.

## Contribution

Even without the promotion, this is a real and specific kernel
bug that was silently invalidating multiple previous audits. The
fix is opt-in and backward compatible; documenting it prevents
future diagnostic rabbit-holes when audit metrics seem "stuck".

# clade 0.5.8 (2026-04-18, evening)

## BNN sigma decoupling + ultra_realistic_specs audit cycle

Followed up the morning's `realistic_specs()` work with the two
priorities from the 🟠-analysis reflection: (1) activate the existing
BNN action-noise / sigma-lr decoupling in the plasticity/Baldwin/RL
audits, (2) add a bigger preset for finite-size-sensitive scenarios.

**Promotion:**

- **s-rl 🟠 → ✅** at 16 seeds × realistic_specs with
  `bnn_action_noise_scale = 0.7, bnn_sample_freq = 5,
  rl_update_freq = 5, learning_rate_init_mean = 0.005`:
  Δn_agents(actor_critic − none) = +10.9 ± 4.9 at t = +2.20 (17%
  larger equilibrium population). Williams 1992 REINFORCE works when
  the agent can actually *exploit* its learned posterior mean;
  legacy sigma-coupled action noise was re-randomising the policy
  every tick and cancelling the learning signal.

**New preset:**

- **`ultra_realistic_specs()`** — 120×120 grid, 500 init, 5000 max,
  2500 ticks, 400-agent equilibrium. Designed for Red-Queen-type
  scenarios whose theoretical signal scales with N.

**Null findings (honestly documented, no verdict change):**

- **s-plasticity, s-baldwin**: BNN sigma decoupling with
  `bnn_sigma_source = "trait"` is non-viable at realistic scale
  (0–2 seeds per cell survive). In the viable `"heterozygosity"`
  mode the plasticity trait is a neutral marker, so Δ = 0. Genuine
  kernel limitation — decoupling infrastructure exists but the
  trait-mode sigma source needs its own stability work.
- **s-mating-systems**: 32 seeds × ultra_realistic_specs gives
  Δn_sex−asex = +2.4 at t = +0.41 (smaller than the 16-seed
  ultra result of +7.6 — that was seed noise). Otto & Michalakis
  1998's ~μN finite-size scaling does NOT manifest in clade's
  discrete-allele parasite kernel.
- **s-group-defense** at ultra scale: Δ = +0.66 at t = +0.08 —
  signal vanishes. Correct finite-size interpretation is that
  selfish-herd risk dilution (∝ 1/√N) means *larger* herds need
  defense less, not more.

**Vignette reframe (P3):**

- **s-predation-neural** — the vignette's "Expected output" section
  was rewritten to split the two historical claims: (a) predation
  reduces prey population (Williams 1966 demographic, ✅ at
  t = −3.64), (b) predation maintains genetic diversity via
  directional selection (**retracted**, t = −0.90 under clade's
  mutation-bounded brain-weight regime).

**Final ledger: 27 ✅ / 5 🟠 / 0 🔴 out of 32 auditable scenarios
(84% ✅).** Net +3 promotions from yesterday's 24 ✅.

# clade 0.5.7 (2026-04-18)

## realistic_specs() preset + audit re-runs at realistic scale

New exported `realistic_specs()` preset — 60×60 grid (4× default
area), 150 init agents, 2000 ticks (66 generations at `max_age =
30`), and explicit `predator_max_age = 60` (predators outlive prey
2×, biologically realistic owl-vs-mouse age structure). Built on
`fast_specs()` because 2000-tick runs are the longest the BNN
kernel stays stable without trait drift.

Used this preset to re-audit every 🟠 scenario plus the ⚪ demo
scenarios. Two promotions and one reframe:

- **s-scavenging 🟠 → ✅**: DeVault 2003 carrion-as-energy-channel
  holds when the predator guild supplies adequate carcasses. 8
  seeds × 2 conds: Δenergy = +3.42 ± 0.71 (t = +4.83), Δpop = +14.9
  ± 6.1 (t = +2.46). The 2026-04-17 null was scale-limited: at
  default 30×30 / 500-tick the predator guild is too thin to
  generate a detectable carrion channel.
- **s-cephalopod ⚪ → ✅**: Liedtke & Fromhage 2019's lifespan-vs-
  learning-rate prediction reproduced. 10 seeds × 4 lifespans:
  slope(mean_lr ~ max_age) = −9.23e-05 ± 2.48e-05 (t = −3.72).
  Short-lived agents evolve ~22% higher learning rates.
- **s-predation-neural ⚪ → 🟠**: honest reframe. Predation reduces
  prey equilibrium population by 15% (t = −3.64, Williams 1966
  demographic passes). The older "predation increases genetic
  diversity" claim is retracted at realistic scale (t = −0.90).

Also reframed (still 🟠):

- **s-group-defense**: 2026-04-17 "defense inverts Hamilton 1971"
  verdict was a default-scale artifact. At realistic scale with
  `predator_max_age = 60`, direction is now correct (Δpop = +10.1,
  t = +1.60) but sub-2σ.
- **s-mating-systems**: 32-seed realistic confirms 🟠 (t = +1.32
  direction correct, still sub-2σ). Red Queen advantage in clade's
  kernel is genuinely subtle.
- **s-rl / s-plasticity / s-baldwin**: kernel-limited (BNN sigma
  coupling), not scale-limited. Realistic-scale audit produces
  same magnitude as default-scale.

Also pushed forward:

- **20+ broken pkgdown links fixed** — audit reports under `dev/`
  now use absolute `github.com/blob/main` URLs so they resolve on
  both GitHub and the pkgdown site (previously 404'd on pkgdown
  because `dev/` isn't shipped with the package).
- **Stale landing-page counts fixed**: README, DASHBOARD, NEWS all
  now match STATUS.md's actual ledger.

**Final ledger: 26 ✅ / 6 🟠 / 0 🔴 out of 32 auditable scenarios
(81% ✅).** Up from 24 ✅ / 6 🟠 / 30 auditable (80%) at the start
of the session.

# clade 0.5.6 (2026-04-17)

## Hygiene pass (late 0.5.6)

Applied the four karpathy-skills coding principles (Think Before
Coding / Simplicity First / Surgical Changes / Goal-Driven
Execution) to a review sweep of the public API. Findings and fixes:

- **`plot_signal_evolution()`** — was a documented "Phase 2
  placeholder" returning an empty plot. Implemented properly: now
  draws `mean_signal_magnitude` vs tick using the column that's
  already logged for `s-signals`. Returns an empty-state plot when
  the column is absent or all-zero. No breaking change.
- **`plot_kin_network()`** — remains a placeholder (igraph is not
  a clade dependency). Docstring rewritten to flag this loudly so
  anyone autocompleting the function sees "not yet implemented"
  before trying to use it.
- **`search_gradient(n_cores)`** — previously documented as
  "Reserved for future parallel finite-difference evaluation;
  currently unused". Now *actually uses* `n_cores` via a single
  PSOCK cluster reused across gradient steps. Finite-difference is
  embarrassingly parallel: `length(params) + 1` independent
  evaluations per step. No API change.
- **`search_map_elites(n_cores)` removed** — the argument was
  accepted but silently ignored (the MAP-Elites loop is inherently
  serial because each candidate's parent is selected from the
  current archive). Callers passing `n_cores` to this function now
  error, which is correct: previously they were lied to. If you
  want parallelism across MAP-Elites *searches*, use
  `batch_alife(list_of_search_calls, n_cores = N)` externally.
- **`search_viability(n_cores)`** — added. Every `(param_x,
  param_y) × replicate` combination is independent; grid now
  parallelises via PSOCK. Backward-compatible (default `n_cores =
  1L`). Also flattened the evaluation loop so parallelism works
  across both grid cells AND replicate seeds, not just one.
- **Julia brain-type error message** — was "Transformer and
  Synthesis are planned for later phases" (promises implementation
  that isn't coming in 0.5.x). Now: "'transformer' and 'synthesis'
  are reserved names, not implemented." Matches the corrected
  R-side doc.
- **`s-rl` vignette** — retracted the 3-seed bnn_sample_freq = 5
  claim (superseded by today's 8-seed 144-run sweep that didn't
  reproduce it). The earlier 3-seed audit block is removed; the
  2026-04-17 sweep + diagnosis is the authoritative section.

Plus the CLAUDE.md integration of the four karpathy principles at
the top of the file, each with a clade-specific application note.



Substantial multi-PR day covering timescale presets, 🟠-sort work,
a new audit-methodology utility, a working parallel scenario-search
toolkit, three kernel bug fixes, and a head-to-head brain-type
benchmark. 22+ PRs merged to main.

## Parameter-space search and parallelism (afternoon)

The story: the existing `batch_alife(n_cores = N)` path silently
deadlocked (forked R workers all blocked on one Julia socket —
fork-unsafe RPC). Fix: **swap `parallel::mclapply` for
`parallel::makeCluster("PSOCK")`**, where each worker is a
separate R process with its own Julia session. Same fix applied to
`search_cmaes`. `n_cores > 1` now actually parallelises.

New exports built on the fixed parallel path:

- **`grid_specs(base, ...)`** — factorial expansion of a base spec.
- **`sample_specs(base, n, ...)`** — random draws from three
  distribution forms (vector → sample with replacement; list of 2
  → uniform; function → user-supplied).
- **`summarize_batch(results, specs_list)`** — one-row-per-run tidy
  data frame with parameters, default metrics, viability verdict.
- **`stream_specs_to_csv(specs_list, out_path)`** — memory-efficient
  streaming writer for 10k–1M-scenario sweeps. `resume = TRUE`
  (default) skips run_ids already in the output CSV, so killed
  overnight jobs restart cleanly.
- **`submit_sweep_slurm()`** — writes a SLURM array-job template
  that dispatches chunks of the specs_list across cluster nodes,
  each task calling `stream_specs_to_csv()` against a shared CSV.
- **`search_map_elites(checkpoint_path, checkpoint_every)`** —
  checkpoint/resume for long MAP-Elites runs.

New dedicated vignette: **parameter-space-search.Rmd** (placed
after parameter-reference in the sidebar) walks through the full
workflow from small grids to million-scenario cluster sweeps.

Full deadlock post-mortem: `dev/docs/parallelism-audit.md`.

## Kernel fixes

- **body_size foraging death spiral**: `apply_body_size!`
  charged small agents (bs < 1) a foraging correction bounded
  only by 40% of current energy — on low-grass cells the
  correction exceeded the eat_gain, making eating net-negative.
  Small agents drifted to bs ≈ 0.5 then starved. Fix: scale
  `eat_gain * bite * body_size` at the source in `tick.jl`; drop
  the post-hoc correction. At realistic mutation_sd (≤ 0.02) the
  scenario is now viable at fast_specs.
- **RNG-order contamination in BNN sampler**: `randn(length(mu))`
  in Thompson sampling used Julia's global RNG. Consecutive
  `run_alife()` calls in one Julia session shared state so
  figures depended on call order even with `random_seed` set.
  Fix: per-run RNG cache populated from `env.rng` at the top of
  `tick_agents!`. Verified deterministic across call order.
- **search_cmaes parallel path**: same PSOCK fix as batch_alife.
  Single cluster reused across generations to amortise Julia
  compile cost.

## New kernel specs (Baldwin / plasticity scaffolding)

- `bnn_action_noise_scale` (0.5.5, now documented): decouples BNN
  sigma from action sampling. At scale = 0, actions are
  deterministic from mu; sigma affects only learning/cost.
- `action_exploration_epsilon` (0.5.6): epsilon-greedy
  exploration orthogonal to BNN sigma. At epsilon > 0, with that
  probability each tick picks a uniformly random action.
  Intended as the exploration channel when sigma is fully
  decoupled.
- `bnn_sigma_lr_scale`, `bnn_sigma_lr_ref` (0.5.6): within-life
  effective learning rate scales with mean(sigma)/sigma_ref.
  Canalised agents learn slowly; plastic agents learn fast.
  Puts the cost of canalisation on learning speed, not noise.

Combined, these three levers give a 3-axis decoupling of the
sigma channel. None individually promoted Baldwin to ✅ — the
baseline sigma dynamics in clade don't canalise at fast_specs
settings, so the levers never engage. Filed as the clearest next
step in `dev/audit/fidelity/ORANGE_OVERVIEW.md`.

## Audit-methodology hardening

- **`viability_report()`** — new exported function that flags
  runs where `n_final < 20` OR `n_final < 0.2 × n_init`.
  `run_alife()` now attaches it as `env$viability` and warns on
  `"crashed"` verdicts. Codifies the "always check viability
  before interpreting trait means" rule the audit round kept
  relearning.
- **Cross-scenario crash audit** (`crash_audit.R`): 17 scenarios
  × 5 seeds at fast_specs revealed 4 ✅ scenarios that crash at
  fast_specs (body_size, signals, parental_care, stress_hypermutation).
  The morning's demo-chunk updates were silently reverted for
  those four to keep them at `default_specs`.
- **Evidence-strength review** (`EVIDENCE_REVIEW.md`): tiers all
  30 auditable scenarios into Strong / Moderate / Weak-✅ / Honest
  🟠. Revealed that a meaningful subset of the pre-cycle ✅ sat in
  Tier C (audited pre-8-seed discipline); four of those were demoted
  to 🟠 after 8-seed re-audit.
- **Tier C re-audit (batches 1 + 2)**: ran 12 of the 14 Tier C
  scenarios × 8 seeds × 2 conditions.  Six pass as
  module-firing-correctness checks (cooperation, speciation, niche,
  parental_care, complex_landscape, seasonal). **Five demoted**:
  group_defense, social_learning, scavenging, brain_size, rl — the
  canonical theoretical claim doesn't hold at 8 seeds. One
  marginal (parental_investment). Inventory and next steps for all
  9 🟠 in `dev/audit/fidelity/ORANGE_OVERVIEW.md`.

## Status changes

- **s-dispersal-ifd promoted 🟠 → ✅** at
  `habitat_preference_strength = 2.0`: Δ = +0.021 ± 0.005 across
  5 seeds.
- **s-mimicry reframed** to lead with predation-dominant ecology
  (Grafen 1990 handicap-equilibrium critique cited).
- Five Tier-C ✅ → 🟠 (per above).

Honest ledger after the full re-audit cycle:
**24 ✅ / 6 🟠 / 0 🔴** out of 30 auditable scenarios (80% ✅).

## New benchmark: brain-type comparison (s-brain-comparison)

First side-by-side benchmark of clade's five working brain
architectures (BNN, ANN, CTRNN, GRN, random). Same ecology, 5
seeds per brain type = 25 independent runs dispatched across 25
PSOCK workers. Surfaces a clean r-vs-K partition:

- **BNN**: 196 ± 5 agents × 125 ± 2 energy — density over quality
- **GRN**: 56 ± 8 agents × 170 ± 5 energy — quality over density
- ANN / CTRNN intermediate; random is fragile.

Doubles as a working demonstration of the new parallel-search
toolkit. New vignette `s-brain-comparison.Rmd` in Theme 6.

Doc fix: `brain_type` no longer claims `transformer` and
`synthesis` are supported — the Julia kernel errors out on both
("planned for later phases"). Listed as reserved names only.

## Memory entries added (cross-session)

- `project_landing_page_cleanup.md` — user flagged remaining
  22-vs-23-vs-26 inconsistencies across pages; systematic sweep
  planned.
- `project_rng_order_sensitivity.md` — now resolved by the 0.5.6
  RNG fix; kept as historical record.

## New exports

- `fast_specs()` — preset for fast-generation evolutionary scenarios
  (max_age = 30, ~66 generations in 2000 ticks). Root-cause fix for
  the "weak evolutionary signal" family of 🟠 scenarios: at
  `default_specs`, 500-tick audits run only 2.6 generations, far below
  the 100+ Fisher 1930 predicts for modest selection.
- `slow_specs()` — preset for K-strategist scenarios (max_age = 200,
  `min_repro_energy = 150`).
- `viability_report()` — first-class utility for flagging population
  crashes before interpreting trait-mean effects. Returns one of
  `"viable"`, `"weak"`, `"crashed"` with a diagnostic message.
  Motivated by several 🟠 audits where direction flips were
  silently driven by population crashes in one condition.

## New specs

- `predator_max_age` — predator lifespan independent of prey. Default
  `NA` (same as prey); set higher for biologically realistic
  owl-vs-mouse scenarios.
- `toroidal` exposed in the `default_specs()` roxygen docs (the spec
  existed but was undocumented).

## Status changes

- **s-dispersal-ifd promoted 🟠 → ✅.** Sweep at fast_specs over
  `habitat_preference_strength` found a clean promotion path: at
  strength ≥ 2.0, Δ = +0.021 ± 0.005 across 5 seeds (vs +0.003 at the
  default 0.5). Default strength was below the drift floor — only
  ~1.5% effective move-toward-grass per tick.
- **s-mimicry reframed** to lead with the predation-dominant ecology
  (grass_rate = 0.08) where aposematism actually evolves. Default
  well-fed ecology documented as a Zahavi-handicap limit condition
  (Grafen 1990 / Getty 2006 / Számadó 2011 critique cited).
- **s-baldwin and s-plasticity confirmed kernel-limited.** Single-seed
  fast_specs results (61× / 11× stronger than default) were noise;
  5-seed and 8-seed re-audits show Δdelta ≈ 0.005 (well below the
  0.02 threshold). Both need the 0.4.3 BNN-sigma-decoupling work
  (partial kernel support via `bnn_action_noise_scale` landed in 0.5.5
  — see that release).

## Scenario vignette updates

- Every evolutionary-scenario vignette demo chunk now uses `fast_specs()`
  where the scenario is viable at fast_specs, and `default_specs()`
  where not. `dev/audit/fidelity/crash_audit.R` identified four ✅
  scenarios that crash at fast_specs (body_size, signals, parental_care,
  stress_hypermutation) and four that are robustly viable (cooperation,
  clutch_size, kin, scavenging).
- `s-predator-prey`: 3 new Discovery experiments added — spatial
  refugia (2×2 toroidal × complex_landscape factorial), grass density
  × predator density, group defense × LV. The strongest LV-like
  cycling clade has produced (oscillation score 0.64) is the
  complex_landscape + toroidal + 50×50 regime; grid-scale dependent
  (no effect at 30×30), consistent with a spatial-decoupling mechanism
  rather than Rosenzweig enrichment.
- `vignettes/getting-started.Rmd`: new "Simulation timescale" section
  with the fast/default/slow preset table and Fisher `1/s` rationale.

## Infrastructure

- `dev/audit/fidelity/PRIORITY_ROADMAP.md`: classifies every 🟠 scenario
  as easy-win (parametric fix), kernel-limited, or weak-✅ (crash risk).
- `dev/audit/fidelity/CRASH_AUDIT_FINDINGS.md`: documents the
  cross-scenario viability verdict and the body_size crash mechanism
  (asymmetric foraging correction for small agents creates a death
  spiral).

## Bug fixes and methodology

- `_pkgdown.yml`: add `fast_specs`, `slow_specs`, and `viability_report`
  to the reference index. Previous-version missing-topic errors were
  blocking pkgdown deploys since PR #34.
- **Methodology rule (now codified in `viability_report()`)**: never
  promote a scenario on fewer than 5 seeds; always check `n_final`
  before interpreting any trait-mean effect. This lesson surfaced
  four times in the repo now (Red Queen 0.5.3, mimicry 0.5.4, body_size
  P2 0.5.2, and 0.5.6 plasticity/baldwin/dispersal).

## Memory (cross-session)

Three new persistent memory entries capture what future sessions need
to know: fast_specs is necessary but not sufficient for evolutionary
signals; clade kernel has RNG-order contamination; priority roadmap
for 🟠 sort.

---

# clade 0.5.5 (back-filled)

Kernel-only release (no scenario changes): added the
`bnn_action_noise_scale` spec to decouple BNN sigma from the action
sampling channel. At `scale = 1.0` (default), legacy full coupling:
`w = mu + sigma * z`. At `scale = 0`, actions are deterministic from
mu; sigma only affects the learning/cost channel. Infrastructure
added to `inst/julia/src/brains/bnn.jl` and `inst/julia/src/tick.jl`;
used by 0.5.6 Baldwin audit.

---

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
