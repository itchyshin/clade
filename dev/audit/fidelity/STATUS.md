# Scenario fidelity audit — status tracker

One row per scenario. Update when a scenario's fidelity audit progresses.

Statuses:

- ⬜ **pending**: not yet audited.
- 🟡 **in progress**: runner written, audit not yet complete.
- ✅ **passed**: multi-seed run confirms the vignette's scientific claim;
  code, figure, and prose are unified; report committed.
- 🟠 **passed-consistent**: runs are consistent with the cited theory at
  the scenario's scale (e.g. damped LV in a spatial ABM), even if the
  strict quantitative prediction (e.g. sustained sinusoidal LV) is not
  reproduced. Prose is honest about the limitation.
- 🔴 **failed**: kernel or formula bug found — figure contradicts cited
  theory and the scenario cannot be recovered by parameter tuning alone.
- ⚪ **N/A**: scenario does not claim a primary-source match
  (e.g. discovery / kitchen-sink demos).

## fast_specs viability annotations (2026-04-17)

From `dev/audit/fidelity/CRASH_AUDIT_FINDINGS.md`, with 5 seeds × 2000
ticks at fast_specs:

- 💥 **fast-crash**: scenario's demo parameters crash at `fast_specs()`
  (mean `frac_final < 0.20`). Use `default_specs()` for the vignette
  demo; keep fast_specs for any scenario-specific variant only if a
  targeted viability check passes. Four scenarios: body_size, signals,
  parental_care, stress_hypermutation.
- ⚠️  **fast-weak**: viable at fast_specs but population shrinks to
  20–50% of init. Either is OK; trait-mean audits at fast_specs should
  always call `viability_report()` before interpreting. Nine scenarios.
- 💪 **fast-viable**: robustly viable or growing at fast_specs. Safe
  to default to fast_specs in audits. Four scenarios: cooperation,
  clutch_size, kin, scavenging.

## 2026-04-17 session summary

- **Promoted 🟠 → ✅**: s-dispersal-ifd (at `habitat_preference_strength
  = 2.0` under fast_specs; 5-seed Δ = +0.021 ± 0.005); s-social-learning
  re-confirmed at `social_learning_freq = 50` regime (144-run sweep).
- **Reframed to 🟠**: s-mimicry (predation-dominant ecology as primary
  claim), s-group-defense (inverts Hamilton 1971 in evolving-predator
  ABM), s-scavenging (module-correctness only, no DeVault energy benefit).
- **Confirmed kernel-limited**: s-baldwin, s-plasticity (both need
  sigma canalisation to engage the 0.5.5/0.5.6 decoupling levers).
- **New utility**: `viability_report()` — check crash risk before
  interpreting trait means.
- **New infrastructure**: `dev/audit/fidelity/crash_audit.R`,
  `PRIORITY_ROADMAP.md`, `CRASH_AUDIT_FINDINGS.md`,
  `EVIDENCE_REVIEW.md`, `ORANGE_OVERVIEW.md`.

**Net after all today's audit work:** ~12 defensible-✅ / ~11 🟠 (with
honest reframed claims) / 1 marginal / 2 untouched / 0 🔴 out of 30
auditable scenarios.

## 2026-04-18 update — realistic_specs() re-audits

New preset `realistic_specs()` (60×60 grid, fast_specs-based, explicit
`predator_max_age = 60`) adds ecological-realism to audits. Two
previously-NA scenarios are now auditable:

- **s-cephalopod ⚪ → ✅**: 10 seeds × 4 lifespans at realistic scale.
  Slope(mean_lr ~ max_age) = −9.23e-05 ± 2.48e-05 (t = −3.72).
  Short-lived agents evolve higher learning rates, matching
  Liedtke & Fromhage 2019.
- **s-predation-neural ⚪ → 🟠**: 8 seeds × 2 conditions at realistic
  scale. Predation reduces prey population by 21.1 agents (t = −3.64,
  PASS) but does NOT increase genetic diversity (t = −0.90, null).
  Reframed: the Williams 1966 demographic prediction passes; the
  diversity-preservation claim is retracted.

After the full 2026-04-18 realistic_specs() re-audit cycle:

| Scenario | Old verdict | New verdict | Key number |
|---|---|---|---|
| s-cephalopod         | ⚪ | **✅** | slope(mean_lr ~ max_age) = −9.23e-05, t = −3.72 (10 seeds × 4) |
| s-scavenging         | 🟠 | **✅** | Δenergy = +3.42, t = +4.83 with predators (8 seeds × 2) |
| s-predation-neural   | ⚪ | **🟠** | Δpop = −21.1, t = −3.64 (8 × 2); diversity null |
| s-group-defense      | 🟠 (inverted) | 🟠 (direction correct) | Δpop = +10.1, t = +1.60 (8 × 2) |
| s-mating-systems     | 🟠 | 🟠 | Δn_sex−asex = +4.1, t = +1.32 (32 × 2) |
| s-rl                 | 🟠 | 🟠 | Δenergy = −1.6, t = −1.21 (8 × 2) |
| s-plasticity         | 🟠 | 🟠 | Δdelta = −0.002, t = −0.40 (8 × 2) |
| s-baldwin            | 🟠 | 🟠 | Δdelta = −0.003, t = −0.47 (8 × 2) |

Count change: **24 ✅ / 6 🟠 / 5 ⚪ → 26 ✅ / 6 🟠 / 3 ⚪** out of
32 auditable scenarios (**81% ✅**, up from 80%).

| Scenario                              | Primary source                                | Status              | Report                                              | Commit  |
|---|---|---|---|---|
| s-baseline                            | MacArthur & Pianka 1966; Bulitko 2023 (MATLAB)| ✅ passed (three-way xref) | [baseline.md](baseline.md)                   | pending |
| s-bad-science                         | Smaldino & McElreath 2016                     | ✅ passed           | inline in commit                                    | 91cc1a9 |
| s-predator-prey                       | Lotka 1925, Volterra 1926, Huffaker 1958      | ✅ passed           | [predator_prey.md](predator_prey.md)                | pending |
| s-body-size                           | Cope's rule (Stanley 1973)                    | ✅ passed (0.5.2: P1 robust @ 16 seeds; P2 NULL, no predator-direction signal) 💥 fast-crash | [body_size.md](body_size.md)                        | pending |
| s-brain-size                          | Parental provisioning hypothesis              | ✅ passed (0.4.2 brain_energy_base=0.010) | [brain_size.md](brain_size.md)                      | pending |
| s-pop-genetics                        | Fisher-Wright; parent-offspring regression    | ✅ passed           | [pop_genetics.md](pop_genetics.md)                  | pending |
| s-stress-hypermutation                | Rosenberg 2001; Foster 2007                   | ✅ passed 💥 fast-crash | [stress_hypermutation.md](stress_hypermutation.md)  | pending |
| s-complex-landscape                   | Multi-layer habitat                           | ✅ passed           | [complex_landscape.md](complex_landscape.md)        | pending |
| s-dispersal-ifd                       | Fretwell & Lucas 1970; Shine et al. 2011      | ✅ passed (2026-04-17: fast_specs + habitat_preference_strength = 2.0, Δ = +0.021 ± 0.005 across 5 seeds) | [dispersal_ifd.md](dispersal_ifd.md)                | pending |
| s-niche                               | Odling-Smee et al. 2003                       | ✅ passed           | [niche.md](niche.md)                                | pending |
| s-seasonal                            | Sinusoidal resource variation                 | ✅ passed           | [seasonal.md](seasonal.md)                          | pending |
| s-scavenging                          | DeVault et al. 2003                           | ✅ passed (2026-04-18 realistic_specs + predators: Δenergy = +3.42 ± 0.71 at t = +4.83, Δpop = +14.9 ± 6.1 at t = +2.46 — DeVault 2003 holds when predator guild supplies adequate carrion) | [scavenging.md](scavenging.md)                      | pending |
| s-kin                                 | Hamilton 1964                                 | ✅ passed           | [kin.md](kin.md)                                    | pending |
| s-cooperation                         | Nowak & May 1992                              | ✅ passed           | [cooperation.md](cooperation.md)                    | pending |
| s-signals                             | Zahavi 1975; Iwasa & Pomiankowski 1994        | ✅ passed 💥 fast-crash | [signals.md](signals.md)                            | pending |
| s-speciation                          | Dieckmann & Doebeli 1999                      | ✅ passed           | [speciation.md](speciation.md)                      | pending |
| s-parental-care                       | Clutton-Brock 1991                            | ✅ passed 💥 fast-crash | [parental_care.md](parental_care.md)                | pending |
| s-mating-systems                      | Maynard Smith 1978; Hamilton 1980             | 🟠 passed-consistent (0.5.3 16-seed retraction + 2026-04-18 32-seed realistic_specs confirm: Δn_sex−asex = +4.1 at t = +1.32, direction correct but magnitude sub-2σ even at 32 seeds — Red Queen advantage is genuinely subtle in clade's kernel) | [mating_systems.md](mating_systems.md)              | pending |
| s-life-history                        | Cole 1954; Williams 1966                      | ✅ passed           | [life_history.md](life_history.md)                  | pending |
| s-clutch-size                         | Lack 1947; r/K (MacArthur & Wilson 1967)      | ✅ passed           | [clutch_size.md](clutch_size.md)                    | pending |
| s-parental-investment                 | Trivers 1972                                  | ✅ passed (0.4.0 Tier 3) | [parental_investment.md](parental_investment.md) | 9b21f66 |
| s-pace-of-life                        | Réale et al. 2010                             | ✅ passed (0.4.0 Tier 2) | [pace_of_life.md](pace_of_life.md)               | 9b21f66 |
| s-group-defense                       | Hamilton 1971 (selfish herd)                  | 🟠 passed-consistent (2026-04-18 realistic_specs: direction now CORRECT at Δpop = +10.1 ± 6.4 at t = +1.60 — the 2026-04-17 inversion was a default-scale artifact. Magnitude still sub-2σ so no promotion.) | [group_defense.md](group_defense.md)                | pending |
| s-mimicry                             | Bates 1862; Müller 1879                       | ✅ passed (conditional, 2026-04-18: aposematism evolves at `grass_rate = 0.08` predation-dominant ecology; same classification pattern as s-dispersal-ifd / s-social-learning) | [mimicry.md](mimicry.md)                            | pending |
| s-disease                             | Kermack & McKendrick 1927 (SIR)               | ✅ passed           | [disease.md](disease.md)                            | pending |
| s-predation-neural                    | Williams 1966                                 | 🟠 passed-consistent (2026-04-18 realistic_specs: 8 seeds × 2 conditions, predation reduces prey n by 21.1 ± 5.8 at t = −3.64; diversity-increase claim retracted at t = −0.90) | [predation_neural.md](predation_neural.md)          | pending |
| s-rl                                  | Williams 1992 (REINFORCE)                     | 🟠 passed-consistent (2026-04-17 144-run sweep + 2026-04-18 8-seed realistic_specs + complex_landscape: no canonical Δenergy > 0 at any tested cell; reframed to module-correctness) | [rl.md](rl.md)                                      | pending |
| s-social-learning                     | Boyd & Richerson 1985                         | ✅ passed (2026-04-17: 144-run freq × density sweep found `freq = 50` regime with Δenergy = +3.3, t = 2.27) | [social_learning.md](social_learning.md)            | pending |
| s-plasticity                          | Pigliucci 2001                                | 🟠 passed-consistent (0.4.2 1500-tick, direction correct) | [plasticity.md](plasticity.md)                      | pending |
| s-baldwin                             | Hinton & Nowlan 1987                          | 🟠 passed-consistent (kernel-limited: sigma couples to behavioural variance) | [baldwin.md](baldwin.md)                            | pending |
| s-cephalopod                          | Liedtke & Fromhage 2019                       | ✅ passed (2026-04-18 realistic_specs: 10 seeds × 4 lifespans; slope(mean_lr ~ max_age) = −9.23e-05, t = −3.72 — short lifespan selects for faster learning) | [cephalopod.md](cephalopod.md)                      | pending |
| s-module-comparison                   | —                                             | ⚪ N/A              |                                                     |         |
| s-map-elites                          | Mouret & Clune 2015                           | ✅ passed (0.4.1 default-mutation fix) | [map_elites.md](map_elites.md)                      | pending |
| s-kitchen-sink                        | —                                             | ⚪ N/A              |                                                     |         |
| s-cross-module                        | —                                             | ⚪ N/A              |                                                     |         |

## Audit queue (recommended order)

Ordered by "most user-facing claims that need verification":

1. ~~s-life-history — user explicitly flagged.~~ ✅ done.
2. ~~s-mimicry — Batesian + Müllerian.~~ 🟠 done; flagged kernel
   limitation (scalar predator memory vs alifeR's vector signal
   memory). Recommendation: port alifeR's vector-signal memory to
   Julia in 0.4.0.
3. ~~s-kin — Hamilton's rule is the textbook quantitative
   prediction.~~ ✅ done. Spearman ρ = 0.97 between rB/C and
   mean population — one of the strongest theoretical signals
   observed so far.
4. s-signals — Zahavi handicap + sexual selection equilibrium.
5. s-cooperation — Nowak & May 1992 grid dynamics.
6. s-speciation — Dieckmann & Doebeli bimodality.
7. s-disease — SIR analytic solution is easy to cross-check.
8. s-clutch-size — Lack's clutch is a canonical result.
9. s-body-size — Cope's rule.
10. s-brain-size — expensive-tissue / parental-provisioning.
11. All remaining scenarios in any order.

## Process

Each scenario gets:

1. Read the primary paper(s) — what does the math (mean-field, non-
   spatial, non-evolving) predict?
2. **Cross-reference the alifeR R prototype** at `~/Documents/alifeR/`
   — does the direct ancestor already document what the
   evolutionary-ABM produces here, and why it differs from the math?
   (Look in `alifeR/vignettes/showcase.Rmd` and the relevant
   `alifeR/R/<module>.R` first; many scenarios have explicit "why this
   differs from theory" prose written by the package author.)
3. **Cross-reference the MATLAB base code** at
   `~/Documents/alifeR/alife_matlab/codebase/` (Bulitko 2023, 232
   `.m` files). The MATLAB base implements only the **foundational
   neural-evolution kernel** — agents on a grass grid with evolving
   ANN brains, sexual reproduction (`createOffspring.m`,
   `crossoverWeights.m`), embedded RL (`RLupdate.m`), and Lamarckian
   inheritance. **Most biological scenarios have no MATLAB ancestor**
   (no predators, no life-history flag, no mimicry, no kin
   selection, no signals, etc.) — these were added in the alifeR R
   port. Mark those scenarios "N/A — biological extension first
   appearing in alifeR." Cross-reference is most useful for:
   `s-baldwin` (BNN ↔ `gene2net.m`), `s-rl` (↔ `RLupdate.m`),
   `s-mating-systems` (sexual repro ↔ `crossoverWeights.m`), and any
   brain-architecture work.
4. `dev/audit/fidelity/<scenario>.R` — multi-seed runner + parameter
   search if needed.
5. `dev/audit/fidelity/<scenario>.md` — fidelity report with explicit
   cross-reference table (theory ↔ alifeR ↔ MATLAB ↔ clade).
6. Vignette prose + figure updated to match what clade actually
   produces, with honest framing about which prediction is being
   validated (mean-field vs evolutionary-ABM).
7. One PR per scenario (keeps review scope small).

See `predator_prey.md` §7 for the canonical example of this protocol.
