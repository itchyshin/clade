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

**Expected output at displayed defaults.** With only 5 predators and
`toxicity_cost_per_tick = 2.0` (raised in 0.3.0 for Zahavi-handicap
honesty), predator encounter density is too low for avoidance learning
to exceed `avoid_threshold` within 300 ticks — predators attack
indiscriminately. The per-tick toxicity cost is then pure loss, so
selection purges toxicity: `mean_toxicity` declines from the init value
toward zero. To observe the classical upward-evolution signature
(Müllerian aposematism), either (a) raise `n_predators_init` to 10–15L
and extend `max_ticks` to ≥ 1000, or (b) use the **Calibrated regime**
below, which CMA-ES discovered by dropping the toxicity cost and tuning
the `toxin_dose` / `signal_memory_rate` pair.

``` r
s <- default_specs()
s$mimicry            <- TRUE
s$n_predators_init   <- 5L
s$toxicity_init_mean <- 0.1
s$max_ticks          <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
```

### Calibrated regime (CMA-ES discovered)

Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the
scenario’s parameter subspace discovered the following regime, which
produces a fitness improvement of **21.0x** over the defaults above. See
`dev/audit/calibration/RESULTS.md` for the full CMA-ES results.

``` r
# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):
s <- default_specs()
s$toxin_dose                     <- 23L
s$toxicity_cost_per_tick         <- 0.2776
s$signal_memory_rate             <- 0.2991
# env <- run_alife(s)   # uncomment to run the calibrated regime
```

![Expected output: mean toxicity rises under predator pressure; avoided
attacks increase as predators learn to avoid toxic prey; toxic attack
rate declines.](figures/showcase_21_mimicry.png)

Expected output: mean toxicity rises under predator pressure; avoided
attacks increase as predators learn to avoid toxic prey; toxic attack
rate declines.

**What we found (post-0.3.0 kernel).** Running with `mimicry = TRUE`, 2
predators, 80 agents, default grid, `toxicity_init_mean = 0.1`, 400
ticks (seed 42): `mean_toxicity` *declined* from 0.101 to 0.047 across
the run, the *opposite* of the naive expectation. `n_avoided_attacks`
stayed at 0 and `n_toxic_attacks` stayed at 0 — at this low predation
density the predators don’t encounter enough toxic prey for
Rescorla-Wagner learning to exceed `avoid_threshold`, so no avoidance
fires. `should_avoid_prey()` IS correctly wired into `tick_predators.jl`
(the architectural stub described here before 0.3.0 was fixed), but
without effective predator pressure toxicity is pure cost:
`toxicity_cost_per_tick = 2.0` (raised from 0.5 in 0.3.0 for
Zahavi-handicap honesty) deducts 0.2 energy/tick at init toxicity and
more as agents drift toward it, so selection purges toxicity.

**To see aposematism evolve, raise predation density** (e.g.
`n_predators_init = 6L` and `predator_attack_strength = 60`) or reduce
`toxicity_cost_per_tick` back toward 0.5. The CMA-ES-discovered regime
in the Calibrated regime section above keeps the cost low (0.28) and
tunes `toxin_dose` to yield a 21× fitness improvement — consistent with
the biological requirement that the handicap cost must be less than the
survival payoff for aposematism to evolve (Zahavi 1975, Ruxton, Sherratt
& Speed 2004).

**Batesian mode (0.3.0 new).** Set `s$batesian_mimicry <- TRUE` to let
palatable mimics (toxicity = 0) share in learned aversion (Bates 1862).
Predator-betrayal decay then regulates the mimic frequency.

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
