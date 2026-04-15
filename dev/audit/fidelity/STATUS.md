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
| s-baseline                            | MacArthur & Pianka 1966 (optimal foraging)    | ✅ passed           | [baseline.md](baseline.md)                          | 91cc1a9 |
| s-bad-science                         | Smaldino & McElreath 2016                     | ✅ passed           | inline in commit                                    | 91cc1a9 |
| s-predator-prey                       | Lotka 1925, Volterra 1926, Huffaker 1958      | 🟠 passed-consistent | [predator_prey.md](predator_prey.md)                | pending |
| s-body-size                           | Cope's rule; Shine et al. 2011                | ⬜ pending          |                                                     |         |
| s-brain-size                          | Parental provisioning hypothesis              | ⬜ pending          |                                                     |         |
| s-pop-genetics                        | Fisher-Wright; parent-offspring regression    | ⬜ pending          |                                                     |         |
| s-stress-hypermutation                | Rosenberg 2001; Foster 2007                   | ⬜ pending          |                                                     |         |
| s-complex-landscape                   | —                                             | ⬜ pending          |                                                     |         |
| s-dispersal-ifd                       | Fretwell & Lucas 1970; Shine et al. 2011      | ⬜ pending          |                                                     |         |
| s-niche                               | Odling-Smee et al. 2003                       | ⬜ pending          |                                                     |         |
| s-seasonal                            | —                                             | ⬜ pending          |                                                     |         |
| s-scavenging                          | DeVault et al. 2003                           | ⬜ pending          |                                                     |         |
| s-kin                                 | Hamilton 1964                                 | ⬜ pending          |                                                     |         |
| s-cooperation                         | Nowak & May 1992                              | ⬜ pending          |                                                     |         |
| s-signals                             | Zahavi 1975; Iwasa & Pomiankowski 1994        | ⬜ pending          |                                                     |         |
| s-speciation                          | Dieckmann & Doebeli 1999                      | ⬜ pending          |                                                     |         |
| s-parental-care                       | Clutton-Brock 1991                            | ⬜ pending          |                                                     |         |
| s-mating-systems                      | Maynard Smith 1978                            | ⬜ pending          |                                                     |         |
| s-life-history                        | Cole 1954; Williams 1966                      | ⬜ pending          |                                                     |         |
| s-clutch-size                         | Lack 1947                                     | ⬜ pending          |                                                     |         |
| s-parental-investment                 | Trivers 1972                                  | ⬜ pending          |                                                     |         |
| s-pace-of-life                        | Réale et al. 2010                             | ⬜ pending          |                                                     |         |
| s-group-defense                       | Hamilton 1971 (selfish herd)                  | ⬜ pending          |                                                     |         |
| s-mimicry                             | Bates 1862; Müller 1879                       | ⬜ pending          |                                                     |         |
| s-disease                             | Kermack & McKendrick 1927 (SIR)               | ⬜ pending          |                                                     |         |
| s-predation-neural                    | —                                             | ⬜ pending          |                                                     |         |
| s-rl                                  | Williams 1992 (REINFORCE)                     | ⬜ pending          |                                                     |         |
| s-social-learning                     | Boyd & Richerson 1985                         | ⬜ pending          |                                                     |         |
| s-plasticity                          | Pigliucci 2001                                | ⬜ pending          |                                                     |         |
| s-baldwin                             | Hinton & Nowlan 1987                          | ⬜ pending          |                                                     |         |
| s-cephalopod                          | —                                             | ⬜ pending          |                                                     |         |
| s-module-comparison                   | —                                             | ⚪ N/A              |                                                     |         |
| s-map-elites                          | Mouret & Clune 2015                           | ⬜ pending          |                                                     |         |
| s-kitchen-sink                        | —                                             | ⚪ N/A              |                                                     |         |
| s-cross-module                        | —                                             | ⚪ N/A              |                                                     |         |

## Audit queue (recommended order)

Ordered by "most user-facing claims that need verification":

1. s-life-history — user explicitly flagged.
2. s-mimicry — Batesian + Müllerian, two papers to match.
3. s-kin — Hamilton's rule is the textbook quantitative prediction.
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

1. Read the primary paper(s).
2. `dev/audit/fidelity/<scenario>.R` — multi-seed runner + parameter
   search if needed.
3. `dev/audit/fidelity/<scenario>.md` — fidelity report.
4. Vignette prose + figure updated to match.
5. One PR per scenario (keeps review scope small).
