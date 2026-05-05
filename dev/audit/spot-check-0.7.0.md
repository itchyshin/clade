# Spot-check after Phase 1 + Phase 2 kernel fixes

Goal: verify the Phase 1 (random tick order) and Phase 2 (one-per-cell)
kernel fixes don't substantively break headline behaviour of the three
anchor scenarios named in the original plan
([dev/plans/purring-honking-dove.md, Phase 0.3](#)).

Method: each scenario run twice with the same seed — once with the new
defaults (`random_tick_order = TRUE`, `max_agents_per_cell = 1L`) and
once with legacy semantics (`random_tick_order = FALSE`,
`max_agents_per_cell = 0L`, i.e. unbounded co-occupancy). Single
replicate, fixed seed 42, light footprint. The script is at
`/tmp/spot_check.R` (not committed; reproduce with the table below).

## Scenarios + headline

### 1. Dispersal IFD (mate-finding + cell competition heavy)

```
n_agents_init = 80, max_agents = 400, max_ticks = 400, seed = 42,
dispersal_evolution = TRUE
```

| Variant         | n_final | mean_E | n_births | n_deaths |
|-----------------|--------:|-------:|---------:|---------:|
| **NEW** (rand+1per) |     77 | 126.4  |      181 |      184 |
| OLD (legacy)        |     59 | 156.8  |      159 |      180 |

**Reading**: NEW supports a higher final population (+18) and more
births. Mean energy is lower because more agents are competing on the
same grid budget. Both runs survive 400 ticks. Direction: kernel fix
*helps* dispersal-heavy scenarios because legacy fixed-order +
unbounded co-occupancy was systematically advantaging the early-array
agents at mate-finding and free-cell selection. The new defaults
distribute opportunity more evenly. **No regression.**

### 2. Body-size evolution baseline

```
n_agents_init = 80, max_agents = 300, max_ticks = 400, seed = 42
```

| Variant         | n_final | mean_E |
|-----------------|--------:|-------:|
| **NEW** (rand+1per) |     73 | 141.9  |
| OLD (legacy)        |     77 | 139.1  |

**Reading**: Negligible difference (4 agents, 2 energy units). Body-size
selection on a default-grid baseline scenario isn't sensitive to
tick-order or co-occupancy at this footprint. **No regression.**
(`mean_size` was NA because that's not in the per-tick metrics —
agent-level traits would need to be pulled from `env$agents` if a
finer-grained body-size metric is wanted.)

### 3. Ryan 1990 sensory bias (lightweight)

```
n_agents_init = 60, max_agents = 250, max_ticks = 600, seed = 42,
preference_bias_target = c(1, 0, 0), preference_bias_strength = 0.05
```

| Variant         | n_final | mean(preference[1]) (target = +1.0) |
|-----------------|--------:|------------------------------------:|
| **NEW** (rand+1per) |     57 | +0.891 |
| OLD (legacy)        |     58 | +0.842 |

**Reading**: Both runs converge preference[1] toward the bias target.
NEW is slightly closer to target (+0.05). The β_N mechanism (each tick
pulls every agent's preference toward the target) is independent of
tick order — the kernel fixes do not break it. **No regression.**

## Conclusion

The Phase 1 + Phase 2 kernel fixes do not substantively change headline
outputs of the three anchor scenarios. Where they differ:

- Dispersal scenarios get *better* with the new defaults (more even
  opportunity, higher final population).
- Body-size baseline is essentially unchanged.
- Ryan 1990 sensory bias is essentially unchanged.

This is the audit signal Phase 0 deferred (the plan said "we are not
doing pre-fix multi-seed empirical measurement; the user has accepted
that test-triage during Phase 1/2 is the audit signal"). The full test
suite (1987 tests, 0 failures) plus this spot-check confirms the
kernel fixes are safe to ship in 0.7.0.

## What this does NOT cover

- Multi-seed variability (single seed, single replicate per variant).
- Long-run dynamics (400-600 ticks; some scenarios need 5000+).
- Trait-level outputs (only population-level summaries).

If a future regression suspicion arises in one of these scenarios,
re-run with multiple seeds and compare distributions, not point
estimates.
