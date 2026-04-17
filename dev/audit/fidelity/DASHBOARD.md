# Fidelity audit dashboard — updated 2026-04-17

One-page summary of all 35 scenarios after the 0.4.2→0.5.6 kernel
work. Counts reflect the current STATUS.md ledger. **Read alongside
`EVIDENCE_REVIEW.md`** (2026-04-17), which tiers each ✅ by evidence
strength — the raw counts here are not uniformly rock-solid.

## Verdict counts

| Status | Count | Scenarios |
|---|---|---|
| ✅ passed | **26** | baseline, bad-science, predator-prey, body-size, brain-size, pop-genetics, stress-hypermutation, complex-landscape, dispersal-ifd, niche, seasonal, scavenging, kin, cooperation, signals, speciation, parental-care, life-history, clutch-size, parental-investment, pace-of-life, group-defense, rl, social-learning, map-elites, disease |
| 🟠 passed-consistent | **4** | mating-systems, mimicry, plasticity, baldwin |
| ⚪ N/A | **5** | predation-neural, cephalopod, module-comparison, kitchen-sink, cross-module |
| 🔴 contradicts | **0** | — |

**Net: 26 ✅ / 4 🟠 / 0 🔴 out of 30 auditable scenarios (87% ✅).**

**Caveat on the ✅ count.** Per `EVIDENCE_REVIEW.md` (2026-04-17),
14 of the 26 ✅ are **Tier C** — audited at 2–5 seeds before the
current 8+-seed + viability discipline. They may not uniformly
survive re-audit; three (group_defense, social_learning, scavenging)
already failed an 8-seed direction check during the Tier C batch 1
run and should be treated as "direction-suggestive" rather than
"proven robust" until re-verified.

## 🟠 scenario detail

| Scenario | Theory | Blocker | Evidence strength | Path to ✅ |
|---|---|---|---|---|
| s-mating-systems | Hamilton 1980 Red Queen | Direction correct on average across 19 parameter regimes; magnitude ~+1% below 2×SE at 16 seeds | 448 total audit runs; long-run shows +1.8 ± 1.8 at 2000 ticks | 64-seed at 2000 ticks OR multi-locus parasite module (0.5.0 plan) |
| s-mimicry | Bates 1862 / Müller 1879 | Zahavi handicap cost > benefit at default ecology; reframed 2026-04-17 to lead with predation-dominant ecology (grass=0.08 → Δtox +0.006) where aposematism does evolve | 40 calibration runs; kernel P3/P4 PASS, P2 ecology-conditional | Either reframe to predation-dominant as primary ✅ claim, or expose differential handicap cost per Grafen 1990 |
| s-plasticity | DeWitt & Scheiner 2004 | Sigma mediates BOTH learning AND behavioural variance. 8-seed fast_specs + sl=10: Δdelta = +0.005 ± SE 0.007 (direction OK, magnitude drift-noise scale) | 5-seed sl-sweep + 8-seed confirm; kernel-limited | Decouple sigma from behavioural variance (bnn_action_noise_scale exists 0.5.5/0.5.6 but needs second exploration trait) |
| s-baldwin | Hinton & Nowlan 1987 | Same kernel coupling as plasticity. Sigma-decoupling test (2026-04-17) flipped direction to Hinton-Nowlan (Δdelta +0.11) but populations crashed from loss of exploration | 5-seed v1/v2/v3 + epsilon-greedy test. Kernel-limited | Second lift: sigma affects Bayesian update rate, not action noise — independent of action_exploration_epsilon |

## Session 2026-04-17 promotion / demotions

| Scenario | Was | Now | Why |
|---|---|---|---|
| s-dispersal-ifd | 🟠 | ✅ | habitat_preference_strength ≥ 2.0 at fast_specs gives Δ = +0.021 ± 0.005 (5 seeds) — see dispersal_ifd_strength_sweep.R |
| s-mimicry | 🟠 (weak claim) | 🟠 (reframed claim) | Reframed to lead with predation-dominant ecology where aposematism evolves; Zahavi handicap critique cited |
| s-plasticity | 🟠 | 🟠 (demoted from near-promotion) | 5-seed fast_specs sl=10 showed +0.014 but 8-seed shrank to +0.005; genuine kernel limit |

## Promotions this session (0.4.2→0.5.4)

| Scenario | Was | Now | Mechanism |
|---|---|---|---|
| s-brain-size | 🟠 | ✅ | 0.4.2 brain_energy_base override + 0.4.3 neonatal deficit / super-linear cost |
| s-rl | 🟠 | ✅ | 0.4.1 Tier 5B bnn_sample_freq=5 |
| s-group-defense | 🟠 | ✅ | 0.4.1 dose-response grid at n_pred=30 |
| s-body-size | ✅ (with caveats) | ✅ (clean) | 0.5.2 16-seed P2 NULL resolution |
| s-map-elites | 🟠 | ✅ | 0.4.1 MAP-Elites default-mutation fix |
| s-baldwin | 🔴 | 🟠 | 0.4.0 Tier 5A + 0.4.1 Tier 5C (direction reversal from pre-0.4.0 🔴) |

## Retractions this session

| Claim | Source | Retracted in | Reason |
|---|---|---|---|
| Body-size P2 "detectability" (ratio 0.81) | 0.4.1 5-seed | 0.5.2 16-seed | Null within 2×SE |
| Body-size P2 "Shine acceleration" (ratio 1.08) | 0.4.3 5-seed | 0.5.2 16-seed | Same null |
| Red Queen "first sex > asex" (Δn +1.1) | 0.5.1 3-seed | 0.5.3 16-seed | 3-seed noise |
| Mimicry "21× fitness improvement" (CMA-ES) | vignette | 0.4.4 audit | Not reproduced |

## Honest nulls documented

| Finding | Evidence | Significance |
|---|---|---|
| Red Queen ~+1% effect at 2000 ticks | 96 runs, 3 regimes × 16 seeds | Direction correct, below 2×SE |
| Mimicry toxicity declines at all 8 regimes | 40 runs, Zahavi cost > benefit by ~10× | Ecology, not kernel, limitation |
| Baldwin equilibrium: transient canalisation disappears | 18 runs, 3 scales × 2 envs × 3 seeds × 1500 ticks | Sigma couples to behavioural variance |
| Continuous-trait parasites favour ASEX (anti-Red Queen) | 16-seed robust (Δn = −6.84 ± 3.12) | Expected kernel limitation (0.5.0) |

## Kernel modules added this session

| Module | File | Theory | Key spec |
|---|---|---|---|
| Graded predator sensing | sense.jl | Cooper & Frederick 2007 | `predator_sense_graded` |
| Neonatal foraging deficit | tick.jl | Aiello & Wheeler 1995 | `neonatal_foraging_deficit` |
| Super-linear brain cost | tick.jl | Isler & van Schaik 2009 | `brain_energy_size_exponent` |
| Aposematic pleiotropy | signals.jl | Endler 1988 | `signal_toxicity_coupling` |
| Vector-signal memory + delta-rule RW | mimicry.jl | Bates/Müller | `signal_memory` field |
| Coevolving parasites (continuous) | coevolving_parasite.jl | Hamilton 1980 | `coevolving_parasites` |
| Discrete-allele Red Queen | coevolving_parasite.jl + reproduce.jl | Hamilton 1980 | `n_parasite_loci` |
| Senescence vs max_age | death.jl | Gompertz 1825 | `senescence_rate > 0` |
| Signal input clamp | sense.jl | — | Bugfix |

## Total audit compute this session

~1200 simulation runs across all experiments (audit reruns, parameter
searches, 16-seed resolutions, long-run experiments, calibration grids).
