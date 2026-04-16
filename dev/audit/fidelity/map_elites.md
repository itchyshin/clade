# Scenario: MAP-Elites (Mouret & Clune 2015)

## 1. Theory
- **Primary source.** Mouret, J.-B. & Clune, J. (2015)
  Illuminating search spaces by mapping elites. arXiv:1504.04909.
- **Core prediction.** MAP-Elites fills a behavioural archive with
  diverse high-fitness parameter configurations instead of
  converging on a single optimum.

## 2. Implementation
- clade R: `search_map_elites()` in `R/search.R`. Dispatches to
  Julia kernel for each iteration.

## 3. Protocol
- 150 iterations × 150-tick simulations, archive dims =
  {genetic_diversity, n_agents}.

## 4. Observed dynamics

| Metric | Value |
|---|---|
| Archive cells | 121 total (11 × 11 grid) |
| Cells filled | **1 / 121 (0.8%)** |
| History length | 2 iterations (requested 150) |
| Score range | 0.163 – 0.166 |

MAP-Elites filled only **one** cell and ran only two iterations
despite requesting 150. All candidate simulations produced nearly
identical genetic_diversity values (0.163–0.166), landing them in
the same archive bin.

### Diagnosis

Likely root causes (not investigated in depth here):
1. Default parameter mutation generates only small changes in
   behavioural descriptors — at 150-tick runs, genetic_diversity
   converges to ~0.16 regardless of most parameter perturbations.
2. The iteration loop may be early-stopping (history has 2 rows
   but 150 requested) — possibly a bug worth investigating.
3. Archive bins (11 × 11 = 121) may be too fine for the signal
   range (≈0.003 wide in this pilot).

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered.** The function runs and
  populates the archive (not a total failure), but at default
  mutation parameters and 150-tick simulations it does not
  illuminate the behavioural space as Mouret-Clune predicts.
  Longer runs (500+ ticks), wider archive bins (5 per dim), and
  `mutation_params` set to influential parameters (`grass_rate`,
  `move_cost`) would sharpen the exploration.

Cross-reference:
| Aspect | Theory (Mouret-Clune) | clade |
|---|---|---|
| Archive fills with diverse elites | Yes | ✗ 1 cell at default |
| History shows growing fill | Yes | ✗ stuck at 1 |

## 6. Actions
- Known issue flagged: `search_map_elites()` default settings
  produce an uninformative archive for typical clade runs.
  Tuning guidance would improve the vignette.
- Runner: `map_elites.R`.
- Figure: `figs/map_elites.png` (single-cell archive).
