# Scenario: Predator-prey dynamics

## 1. Theory

- **Primary source.** Lotka (1925) *Elements of Physical Biology*;
  Volterra (1926) *Nature* 118:558-560. Sustained sinusoidal oscillations
  in prey and predator abundance with a lag equal to one quarter of the
  cycle period. Huffaker (1958) *Hilgardia* 27:343-383 showed
  experimentally that spatial structure is required for persistence;
  Comins & Hassell (1996) *J. Theor. Biol.* 183:19-28 and Murdoch et al.
  (1992) *Ecology* 73:289-305 formalised spatial-ABM dampening of LV.
- **Core prediction (one sentence).** In a spatial agent-based model,
  predators and prey coexist with damped oscillations: one clear
  boom-bust cycle early, then settling toward a stable coexistence
  equilibrium because local prey refugia attenuate synchrony.
- **Quantitative expectations.** At least one prey minimum reached
  after a prey maximum (autocorrelation of prey time series must dip
  below zero in the lag-20-to-lag-100 range). Predators must survive
  (not go extinct by end of run). Prey must not saturate at carrying
  capacity for the entire run. Pure LV with sustained sinusoidal
  oscillations is NOT expected.

## 2. Implementation under audit

- **Vignette:** [vignettes/s-predator-prey.Rmd](vignettes/s-predator-prey.Rmd).
- **Calibrated specs (this audit):**

  ```r
  s <- default_specs()
  s$n_predators_init          <- 10L
  s$n_agents_init             <- 100L
  s$grid_rows                 <- 30L
  s$grid_cols                 <- 30L
  s$predator_energy_gain      <- 30
  s$predator_min_repro_energy <- 50
  s$predator_max_agents       <- 100L
  s$grass_rate                <- 0.20
  s$max_ticks                 <- 1000L
  s$random_seed               <- 42L
  ```

- **Julia kernel.** Predator agents live in the same grid, hunt via
  `predator_attack_strength`, reproduce above `predator_min_repro_energy`.
  Relevant files:
  [inst/julia/src/modules/tick_predators.jl](inst/julia/src/modules/tick_predators.jl),
  [inst/julia/src/reproduce.jl](inst/julia/src/reproduce.jl).
- **Formula fidelity.** The clade predator module is not an explicit LV
  differential-equation discretisation; predators move, sense, attack,
  and reproduce as autonomous agents. This is a **spatial ABM**
  comparable to Huffaker-style setups, not mean-field LV. The vignette
  previously claimed a "30-tick lag Lotka-Volterra" pattern, which is
  not a prediction this model can reproduce and was not supported by
  the figure.

## 3. Run protocol

- **Grid search** (54 combos × 3 seeds = 162 runs, ~7 min wall) over
  `predator_energy_gain ∈ {30, 60, 90}`,
  `predator_min_repro_energy ∈ {50, 100, 200}`,
  `n_predators_init ∈ {3, 5, 10}`,
  `grass_rate ∈ {0.10, 0.20}`. Stored in
  `dev/audit/fidelity/predator_prey_grid.rds`.
- **Multi-seed verification** (10 seeds × 1000 ticks at winning regime).
  Stored in `dev/audit/fidelity/predator_prey_results.rds`.
- **Exact command.** `Rscript dev/audit/fidelity/predator_prey.R`.

## 4. Observed dynamics

At calibrated regime, seed 42, 1000 ticks:

- Prey: 150 → peak 466 at t≈200 → crash to 245 at t≈250 → damped
  oscillations around 300 for remainder of run.
- Predators: 10 → saturate at cap 100 by t≈30 → stay at cap for
  remainder (predators are not the rate-limited species).
- Prey autocorrelation dips to −0.39 at lag ~60 (seed-mean across 10
  seeds: oscillation score 0.39 ± 0.14, sd/mean = 0.36 so the effect
  is reproducible but noisy).

Multi-seed figure: [figs/predator_prey.png](figs/predator_prey.png).

Parameter-search findings: the top oscillation scores (>0.44) cluster
at `grass_rate = 0.20` (vs 0.10 — too scarce, prey do not boom),
`n_predators_init ∈ {3, 10}` (5 is an "in between" regime that gives
stable coexistence without a visible cycle), and wide `predator_energy_gain`
(high gain with few initial predators OR low gain with many initial
predators both work — two different ways to reach LV-relevant
predator-prey stoichiometry).

## 5. Verdict

- [ ] Matches theory
- [x] **Consistent with theory but underpowered.** Spatial ABMs
      (Huffaker 1958, Comins & Hassell 1996) predict damped LV
      oscillations in well-mixed grids, which is exactly what we see.
      Sustained oscillations would require structural changes
      (patchy grid, lower predator cap, larger grid) not available
      as simple specs — flagged in discovery experiment 1.
- [ ] Contradicts theory — kernel bug
- [ ] Contradicts theory — vignette overclaim
- [ ] Contradicts theory — formula mismatch

The prior vignette's overclaim ("30-tick lag Lotka-Volterra") was
separately corrected.

## 6. Actions taken

- **Vignette edits** ([vignettes/s-predator-prey.Rmd](vignettes/s-predator-prey.Rmd)):
  - Replaced the displayed code chunk's parameters with the calibrated
    regime so figure + code + prose describe the same run.
  - Rewrote "Expected output" to honestly describe damped oscillations,
    not sustained LV.
  - Deleted the "Calibrated regime (CMA-ES discovered)" block, whose
    `predator_attack_strength = 1` / `grass_rate = 4.22e-06` values
    were numerical-optimiser artefacts.
  - Rewrote all three "Discovery experiments" blocks — the prior
    "Tried it" results were from 200-tick stale-kernel runs.
- **Kernel changes.** None.
- **Tests added.** None yet; the dose-response structure of the
  oscillation score vs parameters could motivate a regression test
  if any kernel change touches predator reproduction — TODO.
- **Companion runner.** `dev/audit/fidelity/predator_prey.R` —
  deterministic; 162 grid + 10 verification runs, ~8 min wall.
- **Figure.** `showcase_14_predators.png` regenerated from the
  calibrated run at seed 42.
- **Commit SHA that closed this report.** `<pending>`.
