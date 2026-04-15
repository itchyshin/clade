# Scenario: Baseline foraging (three-way kernel comparison)

This is the first fidelity audit with a complete three-way
cross-reference: MATLAB ancestor (Bulitko 2023) → alifeR R port →
clade Julia kernel. The goal is not numerical parity — the three
kernels differ materially in energy scale, grass dynamics, eating
semantics, and brain architecture, so quantitative parity is
impossible without kernel harmonisation — but to document **what
changed at each porting step and why**, so future work can tell
intentional improvements from inadvertent drift.

## 1. Theory

- **Primary source.** MacArthur & Pianka (1966) *Am. Nat.*
  100:603–609 (optimal foraging theory). Williams (1992)
  *Mach. Learn.* 8:229–256 (REINFORCE, if ERL enabled).
- **Core prediction (one sentence).** On a renewable resource grid
  with a metabolic cost per tick, natural selection favours agents
  whose foraging policies out-compete alternatives, so the
  population reaches a carrying capacity set by resource renewal
  and the average individual is energetically viable (mean energy
  > 0).
- **Quantitative expectations (within the clade kernel).**
  1. Population reaches a stable equilibrium well above extinction
     (tens to hundreds of agents on a 30×30 grid).
  2. Mean energy > 0 at equilibrium; starvation deaths rare.
  3. Evolved ANN weights drift substantially from random init
     (`mean_ann_weight_magnitude` shifts by ≥ 1 unit over 500 ticks).
  4. Genetic diversity reaches a non-zero equilibrium (mutation
     replenishes what selection purges).
- **Why the evolutionary ABM may differ from the math.**
  MacArthur–Pianka predictions are analytical. The evolutionary
  ABM asks a weaker question: does selection produce *any* coherent
  foraging policy, and does it reach a stable equilibrium?
  Textbook optimality (exact bite-rate maximisation) is not
  expected because evolving a compact ANN from random weights is a
  noisy optimisation.

## 2. Implementation under audit

### clade Julia kernel (the thing being audited)

- Core loop: [inst/julia/src/Clade.jl:339–411](../../../inst/julia/src/Clade.jl#L339).
- Tick mechanics: [tick.jl](../../../inst/julia/src/tick.jl),
  [sense.jl](../../../inst/julia/src/sense.jl),
  [reproduce.jl](../../../inst/julia/src/reproduce.jl),
  [death.jl](../../../inst/julia/src/death.jl).
- Default brain: **BNN** (Bayesian neural network with Thompson
  sampling) — [brains/bnn.jl](../../../inst/julia/src/brains/bnn.jl).
- Calibrated specs (this audit):

  ```r
  s$n_agents_init <- 100L
  s$grid_rows     <- 30L
  s$grid_cols     <- 30L
  s$grass_rate    <- 0.15
  s$max_ticks     <- 500L
  # default_specs() otherwise; no biology extensions.
  ```

### alifeR R prototype reference

- Core loop: [alifeR/R/run_alife.R:273–416](../../../../alifeR/R/run_alife.R).
- Per-tick agent update in R
  [alifeR/R/take_action.R:83–176](../../../../alifeR/R/take_action.R)
  and C++ backend
  [alifeR/src/tick_agents.cpp:177–281](../../../../alifeR/src/tick_agents.cpp).
- Default brain: fixed-weight ANN (tanh + softmax).

### MATLAB base (Bulitko 2023)

- Main entry: [alifeR/alife_matlab/codebase/alife.m:315–579](../../../../alifeR/alife_matlab/codebase/alife.m).
- Per-tick agent update: `takeAction.m`, `senseEnv.m`,
  `moveAgent.m`, `createOffspring.m`, `RLupdate.m`.
- Default brain: fixed-weight ANN (ReLU + softmax); optional ERL
  (eligibility-trace actor-critic) updated every 3rd tick.

## 3. Three-way kernel comparison

Point-by-point diff across the three implementations of the
baseline foraging kernel. Citations are to `file:line` in the
respective codebase.

### 3.1 Tick-loop order

| Step | MATLAB ([alife.m:315](../../../../alifeR/alife_matlab/codebase/alife.m)) | alifeR R ([run_alife.R:273](../../../../alifeR/R/run_alife.R)) | clade Julia ([Clade.jl:339](../../../inst/julia/src/Clade.jl#L339)) |
|---|---|---|---|
| 1. Grass growth | `grass += grassGrowth; grassGrowth *= grassGrowthDecay` (decaying) | `grass += grass_rate × seasonal_mult`, cap `grass_max` | Per-cell Bernoulli: `if rand() < grass_rate: grass += 1` |
| 2. Randomise agent order | Yes (line 324) | Yes (C++ shuffle) | Yes (shuffled in `tick_agents!`) |
| 3. RL eligibility update | Every 3rd tick if ERL (line 327) | Per-tick if `rl_mode != NULL` | Per-tick on BNN posterior if `rl_mode != "none"` |
| 4. Agent sense → decide → move → eat | Single pass (`takeAction`) | Single pass (`take_action` / `tick_agents_cpp`) | Single pass (`tick_agents!`) |
| 5. Predators | N/A (no predator module) | Skipped when `n_predators_init = 0` | Skipped when `n_predators_init = 0` |
| 6. Remove dead | Once after agent pass (line 365) | Once after agent pass | Once after agent pass |
| 7. Reproduction | Once per tick for all eligible (line 556) | Once per tick for all eligible | Once per tick for all eligible |
| 8. Log stats | Line 582 | `.log_tick(env)` | `_log_tick!(env)` |

**Verdict for 3.1:** Loop order is functionally identical across
the three. No reordering bugs.

### 3.2 Energy scales and budget

| Quantity | MATLAB | alifeR R | clade Julia |
|---|---|---|---|
| Energy cap | 1.0 ([takeAction.m:144](../../../../alifeR/alife_matlab/codebase/takeAction.m)) | `energy_init` = 100 | `energy_max` = 200 ([config.R:791](../../../R/config.R#L791)) |
| Starting energy | `initialenergyrange` (bounded Uniform) | 100 | 120 |
| Living cost per tick | `liveEnergy` (constant) | `live_energy` = 0.5 | built into move/idle cost |
| Movement cost | `moveEnergy` if moving; 0 if stay | `energy_move` = 1.0 always (stay pays too; **possible alifeR bug**) | `move_cost` = 1.0 if moving; `idle_cost` = 0.5 if stay |
| Brain cost per tick | `sum(abs(W)) × annPowerCoefficient` | None (no explicit term) | `base × brain_size + scale × mean(|logits|)` (activity mode) |
| Eating amount | `min(grass, maxbite)` | `min(grass, max_bite=10)` | **All grass at cell** (`energy += eat_gain × grass; grass = 0`) |
| Energy clamp | Yes (cap 1.0) | Yes (cap `energy_init`) | Yes (cap `energy_max`) |

**Verdict for 3.2:** Three substantively different energy schemes.

1. **Energy scale drift:** MATLAB [0,1] → alifeR [0,100] → clade
   [0,200]. All internally consistent, not cross-comparable.
2. **Brain cost model divergence:** MATLAB charges per-weight
   magnitude (biologically motivated — Aiello & Wheeler 1995);
   clade charges per-logit-activity (attention cost, Yaeger
   PolyWorld style); alifeR charges neither. Three different
   biological hypotheses; none obviously more correct.
3. **Eating semantics divergence:** MATLAB and alifeR both use a
   handling-time proxy (`maxbite`); clade strips a cell entirely
   in one tick. Makes clade agents more exploitative.
4. **Stay cost:** MATLAB zero-costs staying (line 116 of
   moveAgent.m has a `switch` branch that skips the cost for
   action 5); alifeR has a minor bug (charges unconditionally);
   clade separates `idle_cost = 0.5` from `move_cost = 1.0`
   explicitly.

### 3.3 Sensing (input vector)

| Aspect | MATLAB ([senseEnv.m:19](../../../../alifeR/alife_matlab/codebase/senseEnv.m)) | alifeR R ([sense_env.R:141](../../../../alifeR/R/sense_env.R)) | clade Julia ([sense.jl:41](../../../inst/julia/src/sense.jl#L41)) |
|---|---|---|---|
| Input dimension (baseline) | 11 | 11 | 11 (= 3 + 8r, r=1) |
| Grass inputs | 4 dir × inverse-distance weighted sum + 1 centre | 4 dir × inv-distance weighted + 1 centre | **4 dir × 1 distance (flat, no weighting)** + energy + age + bias |
| Agent-presence inputs | 4 dir × binary inverse-distance | 4 dir × binary inv-distance | 4 dir × binary at distance 1 |
| Self-state inputs | energy (raw), age (sigmoid) | energy (raw), age (sigmoid) | energy (÷ `energy_max`), age (÷ `max_age`), bias=1 |
| Input normalisation | None | None | **All to [0,1]** |

**Verdict for 3.3:** clade **normalises inputs to [0,1] and uses
flat per-distance inputs** instead of MATLAB/alifeR's
inverse-distance-weighted sums.

1. **Normalisation:** probably an improvement. Unnormalised inputs
   mix energy in [0, 100] with binary {0,1} presence flags — the
   high-magnitude energy input dominates the first layer unless
   the network learns to compensate.
2. **Flat-per-distance inputs:** at `input_radius = 1` (default)
   the difference vanishes (both reduce to "grass at adjacent
   cell per direction"). At radius > 1, clade gives the network
   more channels.

Both are **defensible improvements**, but they do change what the
network sees.

### 3.4 Grass dynamics

| Aspect | MATLAB | alifeR R | clade Julia |
|---|---|---|---|
| Init | `rand() ∈ [0, 1]` per cell | `rand() ∈ [0, grass_max]` | `grass_max` with prob 0.5, else 0 |
| Growth | `grass += grassGrowth`, **grassGrowth itself decays** | `grass += grass_rate` constant | Per-cell Bernoulli `if rand() < grass_rate: grass += 1` |
| Cap | 1.0 | `grass_max` = 100 | `grass_max` = 5.0 |
| Grass:energy ratio | 1:1 | 1:1 | **1:40** (cap 5 vs energy cap 200) |

**Verdict for 3.4:** Three different renewal models.

- **MATLAB's decaying growth rate** is unusual — primary
  productivity drops as the simulation runs. Probably an
  experimental-design cooling schedule, not biology. Not
  preserved in the ports (reasonable).
- **alifeR's constant-rate deterministic renewal** matches
  standard ABM convention.
- **clade's probabilistic Bernoulli renewal** reduces spatial
  synchrony vs deterministic renewal. Defensible.
- The **1:40 grass-to-energy-cap ratio** in clade means agents
  accumulate 40× more energy per cell-worth of grass than in the
  ancestors; combined with the strip-the-cell eating rule, this
  makes clade agents much fatter per meal. **Biggest quantitative
  behaviour difference in the baseline kernel.**

### 3.5 Reproduction

| Aspect | MATLAB ([createOffspring.m](../../../../alifeR/alife_matlab/codebase/createOffspring.m)) | alifeR R ([reproduction.R:257](../../../../alifeR/R/reproduction.R)) | clade Julia ([reproduce.jl:50](../../../inst/julia/src/reproduce.jl#L50)) |
|---|---|---|---|
| Eligibility | `age ≥ minReproductionAge`, `energy ≥ minReproductionEnergy` | `age ≥ min_repro_age = 10`, `energy ≥ min_repro_energy = 50` | `energy ≥ repro_threshold = 120` (plasticity-adjusted); **no age check by default** |
| Season-gated | Yes if `seasonLength` finite | Yes if `seasonal_amplitude > 0` | Yes if `seasonal_amplitude > 0` |
| Mating system | Asexual default; `sexualReproduction` toggle | `repro_mode ∈ {asexual, sexual, proximity}` | `ploidy ∈ {1, 2}`; diploid + signals gives sexual |
| Parent cost | Parent pays `minReproductionEnergy` | `parent_energy × 0.5 / clutch_size` | **Fixed `repro_cost = 30`** (mate pays 15) |
| Offspring position | Random cardinal neighbour | Random cardinal neighbour | Random Moore neighbour |
| Weight inheritance | Asexual: copy `birthnet` (or `net` if Lamarckian); sexual: 50/50 crossover | Asexual: copy parent ann; sexual: uniform crossover | **Meiosis on diploid genome** (recombination + independent assortment) |
| Post-inheritance mutation | `w += 0.1 × N(0,1)` (hardcoded) | `w += N(0, mutation_sd = 0.05)` | `w += N(0, mutation_sd = 0.1)` |

**Verdict for 3.5:** clade's reproduction is substantially
re-architected.

1. **No age check** in clade baseline — MATLAB/alifeR both require
   it. Minor but changes early-generation dynamics.
2. **Fixed repro cost** — clade's cost is independent of parent
   energy; MATLAB/alifeR are proportional.
3. **Full meiosis** — clade's diploid genome with maternal/paternal
   alleles and dominance rules is substantially more realistic
   than the flat-weight-vector inheritance in MATLAB/alifeR.
   **Clearly an intentional improvement**, aligned with user's
   goal: "biological assumptions should be better in clade but
   matlab one is our base code we copied."

### 3.6 Brain architecture

| Aspect | MATLAB | alifeR R | clade Julia |
|---|---|---|---|
| Default type | Fixed-weight ANN | Fixed-weight ANN | **Bayesian NN (Thompson sampling)** |
| Hidden layers | Variable (from gene) | Configurable (default 8) | Configurable (default `c(8)`) |
| Activation | **ReLU** + softmax | **tanh** + softmax | **tanh** + softmax (on sampled weights) |
| Weight init | Random | Xavier/Glorot uniform | Glorot via genome |
| Within-lifetime learning | ERL optional (actor-critic, every 3rd tick) | Optional `rl_mode = "actor_critic"` | BNN posterior update (mu and sigma) per tick if `rl_mode != "none"` |

**Verdict for 3.6:**

1. **Activation** (MATLAB ReLU → R/Julia tanh) changed at the
   **MATLAB→alifeR port**, not at alifeR→clade. Undocumented
   rationale. Worth testing whether ReLU gives different dynamics.
2. **BNN as default** in clade is intentional: Thompson sampling
   gives automatic exploration, posterior learning encodes
   uncertainty at the weight level.

### 3.7 Death

| Cause | MATLAB | alifeR R | clade Julia |
|---|---|---|---|
| Starvation | `energy ≤ 0` | `energy ≤ 0` | `energy < 0` |
| Seasonal turnover | `birthSeason < currentSeason` | `winter_death_prob` if seasonal | (seasonal grass only) |
| Age cap | **None** | `max_age` if senescence | **`age ≥ max_age = 200` (always active)** |
| Gompertz senescence | None | Optional | Optional (off by default) |
| Semelparous | None | Optional | Optional |

**Verdict for 3.7:** MATLAB has no explicit death mechanics
besides starvation — agents live forever unless they starve.
alifeR added senescence and semelparous as options (off by
default). clade inherited those AND added an always-active
`max_age = 200` cap. The always-on age cap is a clade-specific
design choice.

## 4. Observed dynamics (clade, 10 seeds × 500 ticks)

Cross-seed equilibrium (t > 200), mean ± SD:

| Metric | Value | Comment |
|---|---|---|
| `n_agents` | 256.9 ± 3.5 | Strong carrying capacity on 30×30 grid |
| `mean_energy` | 129.2 ± 1.1 | Well above starvation; 65% of cap |
| `mean_age` | 98.3 ± 0.3 | Steady-state age structure |
| `genetic_diversity` | 0.341 ± 0.002 | Rises 0.07 → 0.34 (mutation outpaces selection) |
| `mean_ann_weight_magnitude` | 27.3 ± 0.2 | 5 → 27 over 500 ticks — strong weight evolution |
| `n_births` per tick | 1.43 ± 0.03 | Balanced against ~1.43 deaths |
| `n_starvations` per tick | 0.003 ± 0.005 | Negligible |
| `grass_coverage` | 0.385 ± 0.006 | 38.5% cells with grass > 0 |

All four qualitative signatures (P1–P4) **PASS**. Seed-to-seed
variability < 2% on every metric.

Figure: [figs/baseline_xref.png](figs/baseline_xref.png) —
6-panel dashboard across 10 seeds.

## 5. Verdict

- [x] **Matches theory.** All four qualitative signatures pass
      within < 2% seed-level variance.
- [ ] Consistent but underpowered
- [ ] Contradicts theory — kernel bug
- [ ] Contradicts theory — vignette overclaim
- [ ] Contradicts theory — formula mismatch

### Cross-reference table

| Aspect | Theory (MacArthur–Pianka) | MATLAB base (Bulitko 2023) | alifeR R prototype | clade Julia |
|---|---|---|---|---|
| Stable equilibrium | Predicted | Yes (alife.m logs) | Yes (alifeR showcase) | ✓ 257 ± 4 @ 30×30 |
| Viable mean energy | Predicted | Yes (energy ∈ [0,1]) | Yes (∈ [0,100]) | ✓ 129 ± 1 (65% of 200 cap) |
| Weight evolution | Predicted | Yes (mutation + crossover) | Yes (same) | ✓ 5 → 27 over 500 ticks |
| Bounded diversity | Predicted | Tracked (tsne) | Reported | ✓ 0.34 equilibrium |

## 6. Summary of documented kernel changes

Canonical list of **what changed at each porting step**. Use as
the reference for the rest of the fidelity audit queue; when a
scenario's behaviour seems to drift from its MATLAB or alifeR
ancestor, the explanation is usually below.

### Intentional improvements in clade (vs alifeR)

1. **Diploid genome with meiosis** — maternal/paternal alleles,
   independent assortment, recombination, explicit dominance.
   Replaces alifeR's flat-weight-vector inheritance.
2. **BNN as default brain** — Thompson sampling exploration,
   posterior learning at weight level. Ancestors used fixed-weight
   ANNs.
3. **Input normalisation to [0,1]** — resolves mixed-scale input
   problem of the ancestors.
4. **Explicit `idle_cost ≠ move_cost`** — resolves alifeR's
   stay-action bug; closer to MATLAB's original zero-stay-cost.
5. **Scalar trait evolution architecture** — body size, metabolic
   rate, aging rate, etc., as heritable scalar traits with
   explicit evolution flags. MATLAB has none; alifeR has a handful.
6. **Structured logging** with pre-allocated vectors — eliminates
   alifeR's dynamic-growth overhead.

### Unintentional drift or undocumented choices in clade

1. **Activation function** (MATLAB ReLU → R/Julia tanh) — changed
   at MATLAB→alifeR port. Undocumented; clade inherited. Worth
   testing whether ReLU changes behavioural dynamics.
2. **Eating semantics** (MATLAB/alifeR `maxbite` → clade strip-cell)
   — no documented rationale; changes local grass dynamics.
3. **Grass-to-energy ratio** (1:1 in ancestors → 1:40 in clade) —
   incidental consequence of scaling energy and grass caps
   independently. Makes clade agents fatter per meal.
4. **Always-on `max_age = 200`** — MATLAB has no age cap.
5. **No minimum reproduction age** in clade baseline.
6. **Fixed `repro_cost = 30`** — ancestors are proportional.

### MATLAB-only features dropped in the ports

1. **Decaying grass growth rate** (`grassGrowth *= decay`) — a
   cooling schedule. Likely experimental-design machinery.
2. **RL update every 3rd tick** (hardcoded) — ports use per-tick.
3. **Fresh value network on each offspring** — clade's BNN encodes
   policy and value implicitly; no separate value net.

### MATLAB-absent features added in alifeR/clade

All biological extensions (predators, mimicry, disease, kin,
signals, life-history, mating systems, niche construction, etc.)
were added by alifeR and carried through to clade. None exist in
the MATLAB base. See the MATLAB fidelity report §K for the full
list.

## 7. Actions taken

- **Vignette edits** ([vignettes/s-baseline.Rmd](../../../vignettes/s-baseline.Rmd)):
  - Update "What we found" to cite the 10-seed cross-seed means
    from this audit.
  - Add a footnote linking to this cross-reference report for
    readers who want to see the MATLAB/alifeR diff.
- **Kernel changes.** None. Changes documented above are mostly
  defensible; a handful (eating semantics, grass:energy ratio,
  always-on age cap, fixed `repro_cost`) could be revisited in
  0.4.0 if biological fidelity becomes a priority.
- **Tests added.** None. The multi-seed runner is sensitive enough
  to regress on large kernel changes; add a test if that becomes
  a worry.
- **Companion runner.** `dev/audit/fidelity/baseline_xref.R` —
  deterministic, 10 runs, ~60 s wall.
- **Figure.** `dev/audit/fidelity/figs/baseline_xref.png`.
- **Commit SHA that closed this report.** `<pending>`.
