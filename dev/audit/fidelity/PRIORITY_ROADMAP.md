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
2. **Plasticity and Baldwin are promotable 🟠 → ✅.** Δdelta grew
   61× (0.002 → 0.122) and 11× (0.004 → 0.043) respectively
   under fast_specs. Both now exceed the 0.02 threshold at single
   seeds; still needs multi-seed re-audit to lock in ✅.
3. **Dispersal-IFD is promotable 🟠 → ✅.** Δhp grew 18× (0.001
   → 0.018) under fast_specs. Same caveat: multi-seed re-audit
   needed.
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

### 2.1 Easy wins (multi-seed fast_specs re-audit should promote)

| Scenario | Current verdict | fast_specs single-seed result | Blocker |
|---|---|---|---|
| **s-plasticity** | 🟠 Δdelta +0.003 at 1500 t | +0.122 (61× stronger) | Need 5-seed re-audit at 2000 t |
| **s-baldwin** | 🟠 Δdelta −0.005 at 1500 t, direction flipped | +0.043 (11× stronger, direction now consistent) | Need 5-seed re-audit at 2000 t |
| **s-dispersal-ifd** | 🟠 Δhp +0.006 at best grid cell | +0.018 (18× stronger) | Need 5-seed re-audit at 2000 t |

Estimated effort: one runner rewrite + one 3-seed-×-3-cond run per scenario ≈ **2-3 hours total, all three**.

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

## 4. Recommended priority order

Cheapest-first, so that each round produces a visible promotion:

1. **Multi-seed re-audit of plasticity, baldwin, dispersal-ifd**
   at `fast_specs()`. One day. Expected: three 🟠 → ✅.
2. **s-mimicry vignette reframing** to predation-dominant regime
   as the primary claim. Half day. Expected: 🟠 → ✅ or a clean
   "conditionally passes" framing.
3. **s-cooperation vignette clarification** of the drift-without-
   structure null. Half day. Expected: explicit null, no status
   change, but user trust improves.
4. **s-kin / s-cooperative-breeding parameter sweep** for a regime
   that produces detectable helper-tendency drift. Half day.
   Expected: a calibrated example regime added to the vignette.
5. **s-predation-neural re-audit or reframe**. Half day.
6. **s-mating-systems multi-locus parasite module** (0.5.0 plan
   item). 2 days. Expected: 🟠 → ✅.

Items 1-5 are all "this week" scope; item 6 is "next release" scope.

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
