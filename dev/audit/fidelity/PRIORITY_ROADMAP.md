# Fidelity audit — priority roadmap for 🟠 and weak scenarios

*Written 2026-04-17 after the fast_specs + predator-prey discovery work.*

This is a snapshot of where each "not-yet-✅" scenario stands,
what the failure mode is, and what would move it to ✅. It is
meant to replace ad-hoc "what should we do next" conversations
with a prioritised list grounded in the audit evidence.

## 1. Today's net movement

Five ✅ findings came out of today that are worth recording before
we look at the 🟠 list:

1. **`fast_specs()` preset lands.** 66 generations in 2000 ticks
   (vs 2.6 generations at `default_specs` 500 ticks). The root
   cause of most "weak evolutionary signal" reports.
2. **~~Plasticity and Baldwin promotable~~.** CORRECTION: the
   single-seed numbers (61×, 11×) were lucky seeds. 5-seed
   `fast_specs_reaudit.R` (2026-04-17) shows direction flips to
   FAIL for both, because severe seasonality (amp=0.7) drives
   population crashes at the 30×30 / 80-agent density. See §2.1
   below.
3. **~~Dispersal-IFD promotable~~.** CORRECTION: 5-seed rerun
   preserved the direction (patchy > flat, P1 PASS) but the
   magnitude is +0.008, below the 0.02 threshold. Still 🟠.
4. **Mimicry got theoretical closure.** Grafen 1990 + Számadó
   2011 + Getty 2006 critique of Zahavi's handicap is now cited
   in the vignette; the weak Δtoxicity at default ecology is
   explained as a handicap-equilibrium limitation, not a kernel
   bug. Stays 🟠 because the theory it tests is itself fragile.
5. **s-predator-prey found a new LV-amplifying mechanism.**
   `complex_landscape + toroidal` at 50×50 doubles the
   oscillation score (0.30 → 0.65). Effect is grid-scale
   dependent — 30×30 shows no amplification — so the mechanism
   is spatial decoupling, not Rosenzweig enrichment. Suggests a
   dedicated `s-spatial-heterogeneity` scenario.

## 2. Current 🟠 scenarios (as of 2026-04-17)

Five scenarios remain 🟠 on `STATUS.md`. Three will promote on a
multi-seed re-audit; two are genuinely kernel- or
theory-limited.

### 2.1 Attempted easy wins — single-seed promotions did NOT hold

*Correction added 2026-04-17 after the 5-seed `fast_specs_reaudit.R`
run. The earlier "61×, 11×, 18× stronger" claims were single-seed
results that do not survive seed variation:*

| Scenario | Single seed | 5-seed mean Δdelta | 5-seed verdict |
|---|---|---|---|
| **s-plasticity** | +0.122 | **-0.084** | FAIL: direction reverses at multi-seed |
| **s-baldwin**    | +0.043 | **-0.017** | FAIL: direction reverses at multi-seed |
| **s-dispersal-ifd** | +0.018 | **+0.008** | Direction PASS, magnitude below 0.02 |

**What went wrong.** At `fast_specs()` + `seasonal_amplitude = 0.7`,
the seasonal trough drops grass below the starvation threshold for
the 30×30 / 80-agent default density. Several seasonal runs crash
to near-extinction (`n_final` = 0, 3, 5, 11 across seeds) while
stable runs maintain 14–39 agents. The plasticity / sigma averages
are then dominated by tiny surviving populations and by seed-
specific crash timing rather than by the selection gradient. The
single-seed "promotion" results were lucky seeds that happened not
to crash.

**v2 calibrated rerun — update 2026-04-17 (same session).**
`fast_specs_reaudit_v2.R` lifts the confound: 40×40 grid, 180
agents init, max_agents 800, `seasonal_amplitude = 0.35`,
`season_length = 100`, `grass_rate = 0.25`. All runs now end
with `n_final` in the healthy range (min 32, 45, 107 for the
three scenarios) — no crash artifacts. Multi-seed results:

| Scenario | 5-seed Δdelta (v2) | min n_final | Verdict |
|---|---|---|---|
| **s-plasticity** | +0.002 | 32 | P1 direction PASS, magnitude ≪ 0.02 |
| **s-baldwin** | −0.001 | 45 | P1 FAIL |
| **s-dispersal-ifd** | −0.001 | 107 | P1 FAIL (direction flips when patchy pops become large) |

**Conclusion.** Once population crashes are eliminated, *the
effects essentially vanish*. The single-seed fast_specs
"breakthroughs" (0.12 / 0.04 / 0.02) were lucky-seed artifacts,
not systematic signal. `fast_specs()` alone does not promote
these three scenarios. They are genuinely kernel-limited — the
selection gradient at default trait-cost coefficients is
comparable to the drift variance at 5-seed sample size.

**Honest path forward.** These scenarios need kernel changes to
sharpen the selection gradient, not longer runs or faster
generations:

- **s-plasticity**: ~~steeper sigma-to-energy-cost coupling~~.
  *Corrected 2026-04-17 afternoon:* not a cost-scale problem. A
  two-step sweep found (1) `brain_energy_sigma_scale` ramping
  just crashes populations (0.5 → min_n = 3, 2.0 → extinct), and
  (2) the *actual* fix is **`season_length ≤ max_age`**. The
  DeWitt-Scheiner prediction is about within-lifetime variability
  — if each agent lives through only one season, there's no
  selection gradient on plasticity. At `season_length = 10` with
  `fast_specs` (max_age = 30), Δdelta = +0.014 across 5 seeds,
  P1 PASS. **8-seed re-audit** (`plasticity_8seed.R`) shrank the
  magnitude to Δdelta = +0.005 ± SE 0.007 (*t* ≈ 0.74). Direction
  PASS is robust; magnitude is not enough to cross the 0.02
  threshold at the current plasticity-to-sigma coupling. Kernel
  limitation after all — decoupling plasticity cost from BNN
  sigma (the 0.4.3 plan item) is what this scenario actually
  needs. See `plasticity_within_lifetime_sweep.R` and
  `plasticity_8seed.R` for the full evidence.
- **s-baldwin**: decouple BNN sigma from behavioural variance
  (plan file 0.4.3 item — sigma should be a pure learning cost,
  not a noise term). *Season-length sweep (2026-04-17 afternoon)
  confirmed the plasticity fix does NOT work for Baldwin*: at every
  tested `season_length ∈ {10, 20, 30, 60, 100}`, stable `sigma`
  went UP not DOWN (opposite of Hinton-Nowlan canalisation). The
  baldwin.md report's "sigma couples to behavioural variance"
  diagnosis is the real block — canalising sigma means more
  deterministic actions, which has secondary costs that cancel
  the learning-cost savings. Script:
  `dev/audit/fidelity/baldwin_within_lifetime_sweep.R`.
- ~~**s-dispersal-ifd**: a genuine spatial-gradient in grass~~
  **s-dispersal-ifd: PROMOTED 🟠 → ✅ (2026-04-17 afternoon).**
  Turned out not to need a spatial gradient — inspection of
  `inst/julia/src/modules/habitat_preference.jl` showed the
  module reads `env.grass` directly (the stochastic per-cell
  variation around the mean), so Fretwell-Lucas IFD does have a
  selection substrate under uniform `grass_rate`. The real block
  was the default `habitat_preference_strength = 0.5` — only 1.5%
  effective move-toward-grass per tick per unit preference, below
  the drift floor at 5 seeds. Sweep at fast_specs:
  | strength | 5-seed Δ ± sd | min_n |
  |---|---|---|
  | 0.5 (default) | +0.003 ± 0.005 | 110 |
  | 1.0 | +0.007 ± 0.006 | 122 |
  | **2.0** | **+0.021 ± 0.005** | 117 |
  | **4.0** | **+0.027 ± 0.007** | 137 |
  Clean monotonic, crosses threshold at strength ≥ 2.0. Promoted
  on STATUS.md. Script:
  `dev/audit/fidelity/dispersal_ifd_strength_sweep.R`.

**Methodology note.** This is now the **fourth** time in this
repo that 3-5-seed direction claims have reversed under proper
scrutiny (prior: Red Queen, mimicry, body-size P2). New rules:

1. Never promote a scenario on fewer than 5 seeds.
2. Always inspect `n_final` before trusting any trait-mean effect
   — near-extinct conditions produce misleading averages.
3. When single-seed and multi-seed results disagree by 50×+, the
   single-seed was almost certainly an outlier seed.

### 2.2 Kernel-limited (need a kernel change to promote)

#### s-mating-systems (Red Queen, Hamilton 1980)

**Current state.** 16-seed discrete-env parasite module, 19-cell
grid audit: direction is correct on average across all cells, no
cell crosses 2×SE. The Δn_sex - Δn_asex signal is ~+1.1 agents,
the detection threshold is ~±3 agents at 16 seeds.

**Why weak.** clade's parasite module matches genotype-to-virulence
in a simple one-dimensional axis. Real Hamiltonian Red Queen needs
multi-locus host-parasite co-evolution where sexual recombination
*breaks up* parasite-locked genotypes and asexual lineages cannot.
The one-axis simplification makes sex and asex nearly interchangeable
because there is no linkage for sex to disrupt.

**Path to ✅.** Multi-locus virulence module (e.g. `parasite_loci`
with epistatic virulence `v = sum(h_i * p_i) + interaction_term`).
Medium effort — new module, ~2 days of kernel + audit work.
Listed in the 0.5.0 plan (`prancy-inventing-balloon.md`).

#### s-mimicry (Bates 1862 / Müller 1879)

**Current state.** 0.4.4 kernel has correct machinery: vector-signal
predator memory, Widrow-Hoff delta rule, aposematic pleiotropy.
P3 (avoidance fires) and P4 (dose-response) PASS. P2 (Δtoxicity >
0) remains direction-sensitive in ±0.002 noise at default ecology;
only predation-dominant ecology (`grass_rate ≈ 0.08`) produces
a clear positive Δtoxicity.

**Why weak.** This is a Zahavi-handicap problem, not a kernel
problem. Grafen 1990 + Getty 2006 + Számadó 2011 showed the
handicap equilibrium requires very specific cost-benefit structures
(differential cost across quality classes). clade's flat
`toxicity_cost_per_tick` doesn't supply that structure.

**Path to ✅.** Either (a) expose differential handicap cost
(`toxicity_cost ∝ energy^−α`: cheap when rich, expensive when
poor) or (b) re-frame the vignette's primary prediction to the
predation-dominant regime where clade *does* reproduce positive
aposematism. Option (b) is cheaper; option (a) is more faithful to
Zahavi. Low effort either way.

## 3. "Weak ✅" scenarios (passed but fast_specs exposed weakness)

These are currently ✅ on `STATUS.md` but today's fast_specs
re-runs showed the evolutionary signal is weaker than the vignette
narrative suggests. They are not 🔴 but they are also not as solid
as the ✅ implies.

### 3.1 s-cooperation (Nowak & May 1992)

**Observation.** At fast_specs 66 generations, `mean_cooperation_level`
drifts around the 0.5 init value with wide excursions (0.40 to
0.58). Cooperation acts decline from ~200/tick to ~80/tick, but
this tracks declining population, not declining per-capita acts.
No structural mechanism (kin, reciprocity, group structure) is
turned on in the default cooperation scenario, so drift around
init is the expected null.

**Path.** Vignette should note that cooperation without a structural
mechanism drifts, and direct users to `s-kin` or
`s-cooperative-breeding` for scenarios where cooperation actually
evolves. Low effort.

### 3.2 s-kin / s-cooperative-breeding (helper tendency)

**Observation.** Helper tendency drifts 0.201 → 0.199 across 2000
ticks even with `iffolk_selection = TRUE` and
`parliament_suppression = TRUE`. The mechanism should produce
upward selection on helping, but we see essentially flat.

**Likely cause.** `iffolk_transfer = 3.0` energy per help is small
relative to typical adult energy (~150). Needs either a larger
transfer, a harsher environment where the transfer matters
proportionally more, or a kin-cluster formation mechanism so that
`r` between helper and recipient is reliably high.

**Path.** Parameter sweep on `iffolk_transfer`, `iffolk_r_min`,
and `grass_rate` to find a regime with detectable helper-tendency
upward drift. Medium effort (~4 hours).

### 3.3 s-predation-neural (vadim_experiment)

**Observation.** Neural genetic diversity trajectories for 0 vs
10 predators are effectively identical at 2000 ticks. This
contradicts the vignette's narrative that predation should shape
neural evolution.

**Path.** Honest rewrite — the vignette's claim was always
heuristic. Either narrow the claim ("predation at these densities
doesn't visibly modulate ANN diversity") or find a regime where
the effect is real (e.g. much higher predator pressure,
`n_predators_init = 40`). Medium effort.

## 4. Recommended priority order (revised 2026-04-17 after v2 audit)

The v2 calibrated re-audit changed the picture: fast_specs alone
does not promote plasticity / baldwin / dispersal-ifd. They need
kernel changes, not longer runs. The priority order is now:

1. **s-mimicry vignette reframing** to predation-dominant regime
   as the primary claim. Half day. Expected: 🟠 → ✅ or a clean
   "conditionally passes" framing. *Cheapest item that actually
   moves status.*
2. **s-cooperation vignette clarification** — explicit "drift
   without structural mechanism" null. Half day. No status change
   but fixes narrative mismatch.
3. **s-plasticity kernel lift** — steeper `brain_energy_sigma_scale`
   or dedicated "plasticity_cost" trait. Half day kernel + one day
   audit. Expected: 🟠 → ✅ *if* the cost gradient is actually the
   missing piece.
4. **s-baldwin kernel lift** — decouple BNN sigma from behavioural
   variance (0.4.3 plan item). One-two days. Expected: 🟠 → ✅.
5. **s-dispersal-ifd kernel lift** — expose a true spatial grass
   gradient (not just resource layers). Half day kernel + one day
   audit. Expected: 🟠 → ✅.
6. **s-mating-systems multi-locus parasite module** (0.5.0 plan
   item). 2 days. Expected: 🟠 → ✅.

Items 1-2 are this-week polish; 3-5 are ~0.4.3 kernel work; 6 is
~0.5.0.

## 5. Meta-observations worth keeping

Two cross-scenario patterns surfaced today that are worth writing
down before we forget them:

1. **Predator arms-race absorption.** Across the s-predator-prey
   discovery experiments, every manipulation that should reduce
   predator efficiency (group defense, reduced predator density,
   bounded boundaries) gets absorbed by the evolving predator
   brains. The only manipulation that defeats this absorption is
   the complex_landscape spatial decoupling at 50×50. This is a
   general feature of evolutionary predator-prey ABMs — predators
   adapt faster than ecological manipulations can shape the system.
   Worth flagging in a future meta-vignette.

2. **Generation time was the hidden killer.** At `default_specs`
   (~190 ticks/generation) a 500-tick audit runs 2.6 generations;
   Fisher 1930 predicts 20-100 generations to see selection.
   Every scenario labelled 🟠 in 0.4.x-0.5.x was running on 2-3
   generations of selection. `fast_specs()` (66 generations in
   2000 ticks) changed the game for evolutionary scenarios; it is
   the single biggest improvement any audit cycle has produced.
