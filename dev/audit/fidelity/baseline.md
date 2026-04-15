# Scenario: Baseline world (foraging)

## 1. Theory

- **Primary source.** No single paper — this is the package's own sanity
  check. The implicit model is a renewable-resource foraging system
  (MacArthur & Pianka 1966 for optimal foraging; logistic population
  dynamics for density-dependent regulation).
- **Core prediction (one sentence).** Agents foraging on a renewable
  grass resource should reach a stable carrying capacity, with genetic
  diversity maintained and mean energy stable or weakly rising as
  selection improves foraging strategies.
- **Quantitative expectations.**
  - Population: approach a carrying capacity set by resource
    regrowth × grid size, then fluctuate modestly (±20%).
  - Mean energy: stable or weakly rising over evolutionary time as
    better foraging genomes replace worse ones.
  - Genetic diversity: non-zero and maintained (not swept to
    fixation; not unbounded growth).
  - Grass coverage: stable at the grazing-equilibrium value (below
    the ungrazed ceiling).
- **Null/edge expectations.** At very low `grass_rate`, overshoot-
  and-crash cycles are expected; at high `grass_rate`, populations
  hit the agent density cap.

## 2. Implementation under audit

- **`default_specs()` values that matter here:**

  ```r
  list(
    grid_rows     = 20L,   # (vignette override — default is 40L)
    grid_cols     = 20L,   # (vignette override)
    n_agents_init = 40L,   # (vignette override — default is 30L)
    max_ticks     = 300L,  # (vignette override — default is 500L)
    grass_rate    = 0.10,  # package default
    mutation_sd   = 0.05,  # package default
    brain_type    = "bnn", # package default
    ploidy        = 2L     # package default
  )
  ```

- **R entry points.**
  - [R/run.R](R/run.R) — `run_alife()`, `batch_alife()`.
  - [R/analysis.R](R/analysis.R) — `get_run_data()` (returns
    `list(ticks=, deaths=)`, **not** a flat data frame — this
    tripped the first draft of the audit runner).
- **Julia kernel.**
  - [inst/julia/src/Clade.jl](inst/julia/src/Clade.jl) — entry
    point, logs per-tick metrics to `ticks` table.
  - [inst/julia/src/tick.jl](inst/julia/src/tick.jl) — per-tick
    sense/act/energy/reproduce/death loop.
- **Formula fidelity.** Baseline is not a paper reproduction, so
  the question is internal consistency: do the numbers that the
  displayed code produces match the numbers the prose claims?
  **No** — see §4.

## 3. Run protocol

- **Seeds.** `1L:10L`.
- **Ticks.** 300 (matches vignette displayed code).
- **Agents.** 40 initial (matches vignette displayed code).
- **Grid.** 20×20 (matches vignette displayed code).
- **grass_rate.** 0.10 (package default).
- **Exact command.** `Rscript dev/audit/fidelity/baseline.R`.
- **Cross-check run.** A second script
  `dev/audit/fidelity/baseline_prose_check.R` reruns the parameters
  the vignette's "What we found" prose actually reports
  (seed 42, 500 ticks, 100 agents, 30×30, grass_rate = 0.15).

## 4. Observed dynamics

### Run A — vignette's displayed code (10 seeds × 300 ticks × 20×20 × 40 agents × grass_rate 0.10)

| Tick | n_agents (mean ± SD) | mean_energy | genetic_diversity | grass_coverage |
|---|---|---|---|---|
| 1   | 58.4 ± 2.2   | 85.0  ± 1.2  | 0.130 ± 0.006 | 0.48 ± 0.02 |
| 50  | 89.0 ± 3.4   | 100.1 ± 3.4  | 0.166 ± 0.007 | 0.23 ± 0.02 |
| 100 | 88.7 ± 2.7   | 92.6  ± 3.6  | 0.166 ± 0.006 | 0.23 ± 0.02 |
| 150 | 83.7 ± 2.7   | 89.4  ± 3.7  | 0.159 ± 0.006 | 0.24 ± 0.03 |
| 200 | 38.8 ± 5.3   | 59.2  ± 6.2  | 0.208 ± 0.008 | 0.26 ± 0.04 |
| 250 | 8.0  ± 4.5   | 101.2 ± 14.8 | 0.163 ± 0.093 | 0.80 ± 0.06 |
| 300 | 18.1 ± 5.3*  | 155.9 ± 9.9  | 0.261 ± 0.025 | 0.71 ± 0.09 |

*Tick-300 mean is over 9 seeds — one seed went extinct before tick 300.

**What this shows.** Population grows to ~89, holds for ~150 ticks,
then **crashes to ~8 around tick 250** as grass is over-grazed;
energy recovers afterward because fewer agents share the regrown
grass. This is an overshoot-and-crash cycle, not a stable carrying
capacity. Figure: [figs/baseline.png](figs/baseline.png) — the
crash is visually unmistakable at tick ~200.

### Run B — prose's "What we found" parameters (seed 42 × 500 ticks × 30×30 × 100 agents × grass_rate 0.15)

| Claim in vignette                          | Vignette number | Reproduced | Match? |
|---|---|---|---|
| Population range                            | 155–401         | 143–402      | ✓ |
| Population mean                             | 285             | 283.0        | ✓ |
| Mean energy tick 50 → tick 450              | 115 → 131       | 129.6 → 130.6 | **✗** — energy is stable at 130, not rising from 115 |
| Genetic diversity tick 50 → 450             | 0.17 → 0.39     | 0.178 → 0.386 | ✓ |
| Total births                                | 727             | 727          | ✓ |
| Total deaths                                | 591             | 587          | ✓ |
| Grass coverage range                        | 0.39–0.41       | 0.23–0.52    | **✗** — range is 2× wider than reported |

### Gap between Run A and Run B

The vignette has **three different parameter sets in one page**:

| Source | Grid | Agents | Ticks | Seed | grass_rate |
|---|---|---|---|---|---|
| Displayed code chunk                                              | 20×20 | 40  | 300 | 1  | 0.10 |
| Figure generator (`vignettes/generate_figures.R` §1, line 38-50) | 40×40 | 30  | 500 | 42 | 0.10 |
| "What we found" prose                                             | 30×30 | 100 | 500 | 42 | 0.15 |

Readers who copy the displayed code see a population crash. The
figure they see was produced by a third, never-mentioned
parameter set. The prose describes yet another run.

## 5. Verdict

- [ ] Matches theory
- [ ] Consistent with theory but underpowered
- [ ] Contradicts theory (kernel bug)
- [x] **Contradicts theory — vignette overclaim.** The code runs
  correctly; the vignette text is internally inconsistent:
    1. Displayed code produces population crash, not stable
       carrying capacity.
    2. "Mean energy rose from 115 to 131 as foraging strategies
       improved under selection" — data at the prose parameters
       shows energy flat at ~130, no rise attributable to
       selection.
    3. "Grass coverage was stable at 0.39–0.41" — actual range
       is 0.23–0.52.
- [ ] Contradicts theory — formula mismatch

## 6. Actions taken

Pending commit on branch `fidelity-audit-baseline`:

- **Vignette edits** (planned):
  - Unify parameters: make the displayed code chunk reproduce the
    same run as `figures/showcase_01_run_dashboard.png` (which is
    what the figure shows anyway), OR change the figure generator
    to produce what the displayed code describes.
  - Recommendation: align displayed code with the prose-cited run
    (seed 42, 500 ticks, 100 agents, 30×30, grass_rate 0.15) so
    readers who run the code see the same dynamics the prose
    describes.
  - Rewrite "Mean energy rose from 115 to 131" → "Mean energy was
    stable near 130".
  - Rewrite "Grass coverage was stable at 0.39–0.41" → "Grass
    coverage oscillated in 0.23–0.52 as agents grazed down and
    resources regrew".
- **Kernel changes.** None — the kernel is fine. The issue is
  purely vignette/prose fidelity.
- **Tests added.** None yet; a regression test that the default
  displayed-code parameters do not cause a population crash (or
  that the vignette is honest about the crash) could be added
  when the prose is rewritten.
- **Commit SHA that closed this report.** `<pending>`
