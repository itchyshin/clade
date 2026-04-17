# Honest evidence-strength review of all 30 auditable scenarios

*Written 2026-04-17 in response to the user asking:*

> *"For the 4 🟠 and the 26 ✅ — are you sure they are really passed?
> Are you sure the evidence is strong enough? We really want to know
> that as well."*

Short answer: **no, for a meaningful subset of the 26 ✅, the evidence
is not as strong as the green check implies.** Some were audited at
2–5 seeds before this repo adopted the 8+-seed rule; some have known
kernel caveats that are documented in the per-scenario report but not
surfaced in `STATUS.md`. The ✅ label should be read as "at the audit
run that produced the report, the direction and magnitude matched the
primary source", not "this would survive any re-audit."

## Tiers

- **Tier A — Strong evidence.** ≥ 8 seeds with *t* > 2.5 OR a
  canonical quantitative cross-check (SIR, Hamilton's *rB/C*, allele
  frequency) that leaves no room for direction flips.
- **Tier B — Moderate evidence.** 5–7 seeds, direction clear,
  magnitude near but above threshold. Would likely survive an 8-seed
  re-audit but has not been tested.
- **Tier C — Weak-✅ (at-risk).** 2–5 seeds with modest effect size,
  or audited before a known kernel quirk was found. Needs re-audit
  at 8+ seeds before the ✅ should be treated as load-bearing.
- **Tier D — Honest 🟠.** Direction is correct but magnitude or
  stability is known to be compromised. The 4 current 🟠 scenarios
  all live here.

## Per-scenario assignment

### Tier A (strong) — 8 scenarios

| Scenario | Evidence |
|---|---|
| **s-body-size** | 16-seed audit (0.5.2) confirmed P1 robust, P2 NULL. P1 survived the 16-seed scrutiny pattern. |
| **s-clutch-size** | 2026-04-17 8-seed: Δ(rich−scarce) = +1.68, **t = 33**. Unambiguous. |
| **s-life-history** | 2026-04-17 8-seed: Δ(itero−semel) = +62.9, **t = 47**. Unambiguous. |
| **s-kin** | Spearman ρ = 0.97 between Hamilton's *rB/C* ratio and mean population — one of the strongest theoretical signals in the repo. |
| **s-dispersal-ifd** | 2026-04-17 strength sweep: Δ = +0.021 ± 0.005 across 5 seeds at strength=2.0 — mean is ~4× within-seed SD. |
| **s-disease** | Canonical SIR cross-check against Kermack & McKendrick 1927 analytic solution. |
| **s-bad-science** | Pure-R reproduction of Smaldino & McElreath 2016; canonical result, not a stochastic audit. |
| **s-pop-genetics** | Parent-offspring regression slope estimate; direction + magnitude are a built-in check. |

### Tier B (moderate) — 4 scenarios

| Scenario | Evidence |
|---|---|
| **s-pace-of-life** | 2026-04-17 8-seed: Δ(slow−fast) = +8.9, *t* = 4.5. *Caveat*: initial audit silently wrong because `metabolic_rate_evolution = FALSE` hardcodes rate to 1.0 at birth (bug documented in today's commit); Tier A after the fix is in 0.5.6. |
| **s-baseline** | Three-way xref (MATLAB / alifeR / clade). Qualitative agreement strong; no quantitative seed check needed for the "stable population forms" claim. |
| **s-predator-prey** | 10-seed oscillation-score audit at the calibrated regime gave 0.39 ± 0.14. Direction is robust but the "damped LV" framing replaces the textbook "sustained sinusoidal" claim — documented in the vignette. |
| **s-map-elites** | Algorithm-level correctness (coverage, QD score monotone); easy to verify at any seed. |

### Tier C (weak-✅, at-risk) — 14 scenarios

These passed their original audit at 2–5 seeds before the 2026-04-17
viability discipline. None have obviously failed, but **none have
been stress-tested at 8+ seeds under `viability_report()` guard**
either. User should treat them as "likely direction-correct" rather
than "proven robust".

| Scenario | Concern |
|---|---|
| **s-brain-size** | Passed at 0.4.2 `brain_energy_base = 0.010`. Single regime; no multi-seed re-audit since. |
| **s-stress-hypermutation** | 💥 fast-crash + original audit at `default_specs`. Low-grass condition is near-extinction even at default_specs. |
| **s-complex-landscape** | Passed on shrub/canopy-use fraction; no direction-test at 8 seeds. |
| **s-niche** | Shelter-building count; drift-vs-selection not distinguished. |
| **s-seasonal** | Passed on "population tracks grass". True but mostly a demographic, not evolutionary, claim. |
| **s-scavenging** | Two-condition Δmean_energy check at modest seeds. |
| **s-cooperation** | Today's fast_specs observation: `mean_cooperation_level` drifts around 0.5 with no structural mechanism. The ✅ is direction-correct but the default demo does not show evolution *toward* cooperation — drift around init. |
| **s-signals** | 2026-04-17 8-seed: init 0.024 → final 0.220 (magnitude grows). Direction PASS but not a magnitude-significance test; 💥 fast-crash. |
| **s-speciation** | `n_species` rises from 1 when `isolation_threshold` is low. Qualitative pass; not directionally tested vs a null. |
| **s-parental-care** | 💥 fast-crash. Original audit at `default_specs` showed juvenile buffering; no multi-seed robustness test. |
| **s-parental-investment** | 0.4.0 Tier 3 introduced quality-quantity trade-off; seed count not documented in the report. |
| **s-group-defense** | Population-stability contrast (defense ON vs OFF); magnitude modest. |
| **s-rl** | 0.4.1 + Tier 5B `freq > 1` fix. RL update correctness tested at the algorithm level; scenario-level seed count low. |
| **s-social-learning** | ANN-brain result documented; multi-seed direction not verified. |

### Tier D (honest 🟠) — 4 scenarios

| Scenario | Known limitation |
|---|---|
| **s-plasticity** | 2026-04-17 8-seed (season_length=10, fast_specs): Δdelta = +0.005 ± SE 0.007, *t* = 0.74. Direction is robust (seasonal > stable), magnitude is at drift-noise scale. Kernel-limited — needs sigma decoupling from behavioural variance (0.4.3 plan; partial infra landed in 0.5.5 + 0.5.6 epsilon-greedy but magnitude still below threshold). |
| **s-baldwin** | Same kernel limitation as plasticity. 2026-04-17 `bnn_action_noise_scale = 0` + `action_exploration_epsilon = 0.10`: Hinton-Nowlan direction emerges (stable Δ = -0.019, seasonal = +0.009) but populations crash without exploration; buffered-world rerun lost the signal. Promotable only with a deeper lift (sigma as Bayesian update rate, not just noise). |
| **s-mimicry** | Kernel machinery correct (vector-signal predator memory, delta-rule RW, aposematic pleiotropy). Δtoxicity is ecology-dependent: default grass = 0.20 gives Δ < 0 (Zahavi handicap cost > protection benefit); grass = 0.08 gives Δ > 0. The 🟠 is theoretical, not mechanical — Grafen 1990 / Getty 2006 / Számadó 2011 critique of Zahavi's handicap shows the equilibrium needs specific cost structures that clade doesn't supply at default. |
| **s-mating-systems** | 16-seed 19-regime audit (0.5.3): direction correct on average, no individual cell crosses 2×SE. Kernel-limited — one-axis parasite virulence can't reproduce Hamilton 1980 multi-locus Red Queen. Needs a multi-locus parasite module (0.5.0 plan item, deferred). |

## Recommended re-audit queue

If the goal is to get a defensible 26-of-30 ✅ (rather than "probably
26"), here is the queue in cheapest-first order:

1. **Tier C scenarios with simple Δ claims at default_specs × 8
   seeds** — the same pattern that worked for `direction_8seed.R`.
   Covers: s-cooperation, s-speciation, s-group-defense,
   s-social-learning, s-niche, s-scavenging. Half-day each,
   shared runner.
2. **Tier C scenarios with viability concerns** —
   s-stress-hypermutation, s-parental-care (both 💥 fast-crash).
   Need to re-audit at `default_specs` with `viability_report()`
   guard to confirm the original direction holds.
3. **Tier C algorithm-level ✅** — s-brain-size, s-rl, s-parental-
   investment, s-complex-landscape. These have per-component checks
   but need a scenario-level direction test.
4. **Tier C claims that may be heuristic** — s-seasonal,
   s-predation-neural. Might reframe rather than re-audit.

Expected outcome after this queue:
- Most Tier C scenarios promote to Tier A or B on re-audit.
- Some may reveal silent bugs (like pace_of_life's
  `metabolic_rate_evolution` spec pitfall today) or direction flips
  (like plasticity/baldwin/dispersal-ifd-at-default-strength earlier
  today). Those would move to Tier D, growing the 🟠 count.

## Bottom line

The current **26 ✅ / 4 🟠 / 0 🔴** ledger is an optimistic read.
A defensible ledger after the re-audit queue would likely look like:

- 8 Tier A (strong)
- 10 Tier B (moderate, held up on re-audit)
- 4–8 Tier D (🟠, currently weak-✅ that reveal caveats)
- 0 🔴

That is still a strong result for a young package, but it is the
honest one. The review queue above would take ~2 working days.
