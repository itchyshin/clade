# Fidelity audit dashboard — updated 2026-04-18

One-page summary of all 35 scenarios after the 0.4.2→0.5.6 kernel
work, the Tier C re-audit cycle, and the 2026-04-18 `realistic_specs()`
re-audit cycle.

## Verdict counts

| Status | Count | Scenarios |
|---|---|---|
| ✅ passed | **26** | baseline, bad-science, predator-prey, body-size, brain-size, pop-genetics, complex-landscape, dispersal-ifd, niche, seasonal, scavenging, kin, cooperation, signals, speciation, parental-care, life-history, clutch-size, parental-investment, pace-of-life, mimicry, disease, social-learning, rl, map-elites, cephalopod |
| 🟠 passed-consistent | **6** | mating-systems, group-defense, plasticity, baldwin, predation-neural, **stress-hypermutation** |
| ⚪ N/A | **3** | module-comparison, kitchen-sink, cross-module |
| 🔴 contradicts | **0** | — |

**Net: 26 ✅ / 6 🟠 / 0 🔴 out of 32 auditable scenarios (81% ✅).**
Ledger confirmed under the 0.5.10 real-diploid-sex kernel (pre-0.5.10 was
structurally asex by default; 11 of 12 diploid-sensitive ✅ scenarios
survived re-audit, one demotion — see `post_0510_summary.md`).

**What moved in the BNN-decoupling cycle (2026-04-18 afternoon):**
- `s-rl` promoted 🟠 → ✅ at 16 seeds (realistic_specs + `bnn_action_noise_scale = 0.7`):
  Δn_agents(actor_critic − none) = +10.9 ± 4.9 at t = +2.20 (17% larger
  equilibrium population). Williams 1992 REINFORCE works once actions
  are allowed to exploit the learned posterior mean.
- `s-plasticity`, `s-baldwin`: decoupling insufficient. Trait-mode sigma
  source is non-viable at realistic scale; heterozygosity-mode makes
  plasticity trait a neutral marker (Δ = 0).

**What moved in the ultra_realistic cycle (2026-04-18 afternoon):**
- `s-mating-systems`: 32 seeds × ultra shows Δn = +2.4 at t = +0.41
  — the 16-seed ultra result (+7.6) was seed noise. Finite-size ~μN
  scaling hypothesis falsified; Red Queen magnitude is genuinely
  ~0.7% of population across all tested scales.
- `s-group-defense`: signal VANISHES at ultra scale (Δ = +0.66, t = +0.08).
  Correct interpretation: selfish-herd dilution (~1/√N) means larger
  herds need defense LESS, not more.

**What moved in the `realistic_specs()` re-audit cycle (2026-04-18):**
- `s-cephalopod` promoted ⚪ → ✅ (10 seeds × 4 lifespans at 60×60
  grid; slope(mean_lr ~ max_age) = −9.23e-05, t = −3.72 — Liedtke &
  Fromhage 2019 lifespan-vs-learning prediction reproduced).
- `s-scavenging` promoted 🟠 → ✅ (8 seeds × 2 conds with
  predator guild; Δenergy = +3.42 ± 0.71 at t = +4.83, Δpop =
  +14.9 at t = +2.46 — DeVault 2003 carrion-as-energy-channel
  holds when the predator guild supplies adequate carcasses).
- `s-predation-neural` promoted ⚪ → 🟠 (8 seeds × 2 conditions;
  predation reduces prey n by 21.1 at t = −3.64 — Williams 1966
  demographic prediction passes; diversity-increase claim retracted).
- `s-group-defense` reframed (still 🟠): the previous "defense
  inverts Hamilton 1971" verdict was a default-scale artifact.
  At realistic scale direction is now correct (Δpop = +10.1,
  t = +1.60) — sub-2σ so no promotion, but the inversion was
  kernel-scale-dependent.
- `s-mating-systems` confirmed 🟠 at 32 seeds × realistic scale
  (t = +1.32 direction correct, still sub-2σ — Red Queen advantage
  in clade's kernel is genuinely subtle).
- `s-rl`, `s-plasticity`, `s-baldwin` all confirmed 🟠 at realistic
  scale — kernel-limited, not scale-limited.

**What moved in the Tier C re-audit cycle (2026-04-17):**
- `s-dispersal-ifd` promoted 🟠 → ✅ (habitat_preference_strength = 2.0,
  Δ = +0.021 ± 0.005 across 5 seeds).
- `s-social-learning` re-confirmed ✅ at `social_learning_freq = 50`
  (144-run sweep).
- `s-mimicry` retained ✅ but reframed: aposematism evolves under
  predation-dominant ecology (`grass_rate = 0.08`). Zahavi handicap
  cost > benefit at default ecology is honestly flagged.
- Demoted ✅ → 🟠: `s-scavenging` (no DeVault energy benefit in the
  192-run sweep), `s-group-defense` (selfish-herd inverts under
  evolving predators + finite grass), `s-rl` (no canonical Δenergy
  in the 144-run sweep). All reframed to module-correctness.

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
