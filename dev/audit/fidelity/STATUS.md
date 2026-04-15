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

| Scenario                              | Primary source                                | Status              | Report                                              | Commit  |
|---|---|---|---|---|
| s-baseline                            | MacArthur & Pianka 1966; Bulitko 2023 (MATLAB)| ✅ passed (three-way xref) | [baseline.md](baseline.md)                   | pending |
| s-bad-science                         | Smaldino & McElreath 2016                     | ✅ passed           | inline in commit                                    | 91cc1a9 |
| s-predator-prey                       | Lotka 1925, Volterra 1926, Huffaker 1958      | ✅ passed           | [predator_prey.md](predator_prey.md)                | pending |
| s-body-size                           | Cope's rule; Shine et al. 2011                | 🟠 passed-consistent | [body_size.md](body_size.md)                        | pending |
| s-brain-size                          | Parental provisioning hypothesis              | 🟠 passed-consistent | [brain_size.md](brain_size.md)                      | pending |
| s-pop-genetics                        | Fisher-Wright; parent-offspring regression    | ⬜ pending          |                                                     |         |
| s-stress-hypermutation                | Rosenberg 2001; Foster 2007                   | ⬜ pending          |                                                     |         |
| s-complex-landscape                   | —                                             | ⬜ pending          |                                                     |         |
| s-dispersal-ifd                       | Fretwell & Lucas 1970; Shine et al. 2011      | 🟠 passed-consistent | [dispersal_ifd.md](dispersal_ifd.md)                | pending |
| s-niche                               | Odling-Smee et al. 2003                       | ⬜ pending          |                                                     |         |
| s-seasonal                            | —                                             | ⬜ pending          |                                                     |         |
| s-scavenging                          | DeVault et al. 2003                           | ⬜ pending          |                                                     |         |
| s-kin                                 | Hamilton 1964                                 | ✅ passed           | [kin.md](kin.md)                                    | pending |
| s-cooperation                         | Nowak & May 1992                              | ✅ passed           | [cooperation.md](cooperation.md)                    | pending |
| s-signals                             | Zahavi 1975; Iwasa & Pomiankowski 1994        | ✅ passed           | [signals.md](signals.md)                            | pending |
| s-speciation                          | Dieckmann & Doebeli 1999                      | ✅ passed           | [speciation.md](speciation.md)                      | pending |
| s-parental-care                       | Clutton-Brock 1991                            | ✅ passed           | [parental_care.md](parental_care.md)                | pending |
| s-mating-systems                      | Maynard Smith 1978                            | 🟠 passed-consistent | [mating_systems.md](mating_systems.md)              | pending |
| s-life-history                        | Cole 1954; Williams 1966                      | ✅ passed           | [life_history.md](life_history.md)                  | pending |
| s-clutch-size                         | Lack 1947; r/K (MacArthur & Wilson 1967)      | ✅ passed           | [clutch_size.md](clutch_size.md)                    | pending |
| s-parental-investment                 | Trivers 1972                                  | 🟠 passed-consistent | [parental_investment.md](parental_investment.md)    | pending |
| s-pace-of-life                        | Réale et al. 2010                             | 🟠 passed-consistent | [pace_of_life.md](pace_of_life.md)                  | pending |
| s-group-defense                       | Hamilton 1971 (selfish herd)                  | ⬜ pending          |                                                     |         |
| s-mimicry                             | Bates 1862; Müller 1879                       | 🟠 passed-consistent | [mimicry.md](mimicry.md)                            | pending |
| s-disease                             | Kermack & McKendrick 1927 (SIR)               | ✅ passed           | [disease.md](disease.md)                            | pending |
| s-predation-neural                    | —                                             | ⬜ pending          |                                                     |         |
| s-rl                                  | Williams 1992 (REINFORCE)                     | ⬜ pending          |                                                     |         |
| s-social-learning                     | Boyd & Richerson 1985                         | ⬜ pending          |                                                     |         |
| s-plasticity                          | Pigliucci 2001                                | 🟠 passed-consistent | [plasticity.md](plasticity.md)                      | pending |
| s-baldwin                             | Hinton & Nowlan 1987                          | 🔴 contradicts       | [baldwin.md](baldwin.md)                            | pending |
| s-cephalopod                          | —                                             | ⬜ pending          |                                                     |         |
| s-module-comparison                   | —                                             | ⚪ N/A              |                                                     |         |
| s-map-elites                          | Mouret & Clune 2015                           | ⬜ pending          |                                                     |         |
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
