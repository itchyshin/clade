# Mimicry and toxicity

### Mimicry and toxicity

**What it models.** A heritable `toxicity` trait makes prey costly to
attack. Predators learn signal–toxicity associations via a
Rescorla-Wagner rule and build avoidance. This models the evolution of
warning coloration and Batesian/ Müllerian mimicry (Ruxton et al. 2004):
toxic prey are avoided; non-toxic prey that resemble toxic prey are also
avoided (Batesian mimicry).

**Key parameters.**

| Parameter                | Default | Effect                                                                                                                                                 |
|--------------------------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mimicry`                | FALSE   | Enable toxicity / predator learning (Müllerian by default)                                                                                             |
| `batesian_mimicry`       | FALSE   | Enable Batesian mimicry: palatable prey (toxicity = 0) exploit learned signal aversion; predator-betrayal decay prevents runaway cheating (Bates 1862) |
| `toxicity_init_mean`     | 0.0     | Starting toxicity (0 = non-toxic)                                                                                                                      |
| `toxicity_cost_per_tick` | 2.0     | Per-tick energy cost paid by agents with toxicity \> 0 (Zahavi handicap; raised from 0.5 in v0.3.0)                                                    |
| `toxin_dose`             | 2.0     | Damage dealt to attacker per toxicity unit                                                                                                             |
| `signal_memory`          | 20      | Predator memory window for learning                                                                                                                    |

**Expected output (updated 0.5.4).** With the 0.4.4 kernel fixes
(vector-signal memory, delta-rule RW, aposematic pleiotropy), the
avoidance mechanism fires (P3 PASS: 12–28 events/600 ticks) and shows
positive dose-response (P4 PASS: Spearman ρ = +0.40). But toxicity
magnitude evolution remains ecology-limited: the 0.5.4 calibration grid
(8 cells × 5 seeds × 1000 ticks) found every tested regime has Δtoxicity
\< 0 because the Zahavi handicap cost exceeds the aposematic protection
benefit at default population scales. A predation-dominant ecology
(`grass_rate ≈ 0.08`, where predation = 89% of mortality) produces the
first positive Δtoxicity (+0.006), confirming the mechanism works when
predation is the dominant selection pressure. See the [mimicry fidelity
report](../dev/audit/fidelity/mimicry.md) for the full evidence.

**Pre-0.4.4 kernel simplification (historical).** Before 0.4.4, clade’s
predator memory was a **scalar** updated toward `prey.toxicity`
directly, which removed signal-specific learning — predators couldn’t
recognise warning *patterns*. The 0.4.4 refactor replaced this with a
full vector-signal memory using the Widrow-Hoff delta rule. See “What we
found” below for details.

``` r
s <- default_specs()
s$mimicry            <- TRUE
s$n_predators_init   <- 5L
s$toxicity_init_mean <- 0.1
s$max_ticks          <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
```

### Calibrated regime (formerly CMA-ES discovered — claim retracted)

A previous version of this vignette claimed a 21× fitness improvement
under
`toxin_dose = 23, toxicity_cost = 0.28, signal_memory_rate = 0.30`. The
2026-04-15 fidelity audit ran exactly this regime and observed no
measurable upward toxicity evolution (mean drift = −0.001 over 600
ticks). The CMA-ES result likely optimised a generic fitness signal that
is not specific to toxicity evolution. Claim retracted; awaiting kernel
improvement (signal-vector predator memory) before re-tuning. See
[mimicry fidelity report
§5](../dev/audit/fidelity/mimicry.html#5-verdict).

![Ecology comparison (5 seeds × 1000 ticks, full 0.4.4 machinery). Top:
toxicity trajectories under standard ecology (grass=0.20, grey) vs
predation-dominant ecology (grass=0.08, orange). Predation-dominant
preserves more toxicity because predation becomes the main mortality
cause. Bottom: cumulative avoidance events — predator learning fires in
both ecologies (~30 events). The mechanism works; the magnitude depends
on ecology — 🟠.](figures/showcase_21_mimicry.png)

Ecology comparison (5 seeds × 1000 ticks, full 0.4.4 machinery). Top:
toxicity trajectories under standard ecology (grass=0.20, grey) vs
predation-dominant ecology (grass=0.08, orange). Predation-dominant
preserves more toxicity because predation becomes the main mortality
cause. Bottom: cumulative avoidance events — predator learning fires in
both ecologies (~30 events). The mechanism works; the magnitude depends
on ecology — 🟠.

**What we found (updated 2026-04-16, audit 🟠 with 0.4.4 kernel
fixes).** Two audit iterations materially changed the picture:

*Pre-0.4.0 (scalar-only predator memory)*: 15–67 toxic attacks vs ~700
total attacks (2.5–10%), 0–9 avoidance events total across 600 ticks;
mean toxicity essentially locked at its init value. The scalar memory
was wired correctly but never crossed threshold because it averaged over
`prey.toxicity` (not `prey.signal`), so signal-specific learning
couldn’t occur.

*0.4.0 Tier 4 + 0.4.4 refactor (vector-signal memory + delta-rule
Rescorla-Wagner + aposematic pleiotropy)*. The kernel now:

1.  Stores a dedicated `signal_memory::Vector{Float32}` field on each
    predator — a linear model that *predicts* toxicity from the signal
    vector.
2.  Updates memory with the symmetric Widrow-Hoff delta rule:
    `memory += lr × (tox − dot(memory, signal)) × signal`. Reinforcement
    on toxic prey, extinction on non-toxic prey → Batesian breakdown
    when palatable mimics outnumber models.
3.  Supports optional aposematic pleiotropy
    (`signal_toxicity_coupling > 0`): signal\[1\] tracks toxicity so
    predators can learn an honest warning signal.

Post-fix measurements (5 seeds × 600 ticks, `signal_dims = 3`, audit
measurement bug also fixed — per-tick counters now summed cumulatively,
not sampled at the last tick):

- **P3 FAIL → PASS**: 12–28 cumulative avoidance events (up from the
  spurious 0 reported under the measurement bug).
- **P4 FAIL → PASS**: Spearman ρ(toxin_dose, final toxicity) = +0.40 —
  the expected positive dose-response.
- **P5 PASS (new)**: pleiotropy sweep over
  `signal_toxicity_coupling ∈ {0, 0.3, 0.6, 1.0}` shows monotone
  direction (ρ = +1.0).
- **P2** (treatment \> control) remains direction-sensitive in the
  ±0.002 noise band — toxicity magnitude evolution is still small
  because the ecological parameters (predator encounter rate vs toxicity
  cost) don’t give a strong selection differential.

Verdict: 🟠 with substantially richer kernel semantics. The machinery is
now theoretically aligned with Bates (1862) / Müller (1879); magnitude
of upward toxicity evolution is limited by ecology, not the
predator-learning channel.

**Batesian mode.** Set `s$batesian_mimicry <- TRUE` to let palatable
mimics (toxicity = 0) share in learned aversion. Under the 0.4.4 delta
rule, non-toxic encounters now drive memory extinction, so mimic
frequency regulates itself (Batesian breakdown when mimics outnumber
models).

### Discovery experiments

The baseline result shows `mean_toxicity` evolves upward under predator
pressure and `n_avoided_attacks` increases as predators learn. To go
beyond:

1.  **Mimicry × kin selection** Add `kin_selection = TRUE`. Kin clusters
    may accelerate warning coloration evolution (Hamilton’s genetical
    theory of aposematism). Does kin structure speed up or slow the
    evolution of `mean_toxicity`? Compare `mean_toxicity` trajectories
    under three conditions: no kin, kin without predators, kin with
    predators and mimicry.

    *Tried it.* With `mimicry = TRUE`, `toxicity_init_mean = 0.3`, 5
    predators, 80 agents, 200 ticks, seed 42: no-kin mean_toxicity =
    0.304, final_n = 61; kin mean_toxicity = 0.300, final_n = 96. Kin
    selection had negligible effect on evolved toxicity (0.304 vs 0.300)
    but dramatically boosted population size (+57%). Kin clusters
    provide energy buffers that allow more agents to survive regardless
    of toxicity — the survival advantage of kin altruism is much larger
    than any aposematism benefit at these parameters.

2.  **Mimicry × disease** Add `disease = TRUE`. High-toxicity prey
    produce costly defensive compounds while simultaneously paying
    `disease_energy_cost` when infected. Does disease suppress the
    evolution of costly toxicity by pushing agents into energy deficit
    during infection? Compare the final `mean_toxicity` under disease vs
    no-disease at matched `predator_attack_strength`.

    *Tried it.* Four toxicity_init_mean levels (0.1, 0.3, 0.5, 0.8; 50
    agents, 200 ticks, seed 42): final toxicity tracked initial very
    closely (0.108, 0.296, 0.492, 0.792) with no upward drift — toxicity
    is heritable but selection was not strong enough to drive it upward
    in 200-tick runs. Avoided attacks remained 0 in all conditions,
    confirming that predator avoidance learning requires longer runs.
    Population size declined with higher toxicity (99, 95, 75, 68
    agents), because the toxin production cost reduces energy available
    for foraging, imposing a demographic cost without a compensating
    survival benefit at these run lengths.

3.  **Signal honesty and toxicity** Add `signal_dims = 2L`. Do heritable
    ornamental signals co-evolve with toxicity (honest Müllerian
    signalling) or become decoupled (Batesian dishonest copying by
    non-toxic agents)? Plot `mean_toxicity` against
    `mean_signal_magnitude` as a parametric trajectory and test whether
    the correlation strengthens or weakens over evolutionary time.

    *Tried it.* With `mimicry = TRUE` and `kin_selection = TRUE` (50
    agents, 200 ticks, seed 42): mean_toxicity = 0.018, avoided attacks
    = 0. Combining kin selection with mimicry at low toxicity_init_mean
    (near 0) produced negligible toxicity evolution and no predator
    avoidance. The kin benefit dominated population dynamics (larger
    final n than mimicry alone), while the mimicry signal-toxicity
    coevolution requires higher initial toxicity and longer runs for
    honest-signal dynamics to emerge.

------------------------------------------------------------------------
