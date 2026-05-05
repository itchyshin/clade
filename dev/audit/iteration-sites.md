# Iteration-sites catalogue (Phase 0.1)

Every iteration over `env.agents` in the kernel + modules, classified by whether the order in which agents are processed materially changes outcomes. Order-sensitive sites get the `randperm(env.rng, n)` treatment in Phase 1; order-insensitive sites are left alone.

Generated: 2026-05-05. Plan reference: `~/.claude/plans/purring-honking-dove.md` Phase 0.1.

## Methodology

Read the body of each `for ag in env.agents` / `enumerate(env.agents)` loop. Classification rule:

- **Order-sensitive**: loop reads/writes shared state (env.grass, env.carrion_map, env.agent_map, agents not equal to `ag`) in a way that changes downstream agents' outcomes. First-array-position agents get systematically better access.
- **Order-insensitive**: loop only reads/writes per-agent state of `ag` itself, OR uses an accumulator pattern that yields the same answer regardless of order, OR is a pure read-only pass.

The agent_map rebuild loops (tick.jl:197, death.jl:110, habitat_preference.jl:97) are tagged separately — they don't change outcomes within their own tick but they decide who "wins" the agent_map slot at co-occupied cells, which is a Phase-2 (cell-occupancy) issue, not a Phase-1 (tick-order) issue.

## Catalogue

### Order-sensitive (Phase 1 will shuffle)

| File:Line | Function | Why order matters |
|---|---|---|
| `inst/julia/src/tick.jl:120` | `tick_agents!` | **The main bias.** First agent eats first from `env.grass[x,y]` (handling-time bite cap means subsequent agents get less from the same cell). |
| `inst/julia/src/reproduce.jl:59` | mate-search loop | First agent picks first available mate; later agents have a smaller pool. Affects mate-choice outcomes. |
| `inst/julia/src/modules/dispersal.jl:66` | `apply_dispersal!` | Reads `agent_map == 0` for free-cell check, then claims the cell. First agent claims best free cardinal neighbour; later agents must pick from leftovers. |
| `inst/julia/src/modules/habitat_preference.jl:53` | habitat moves | Same pattern as dispersal — first agent claims best free habitat-preferred cell. |
| `inst/julia/src/modules/scavenging.jl:88` | `apply_scavenging!` | First scavenger on a carrion cell takes `min(available, eat_gain)`; later scavengers get the residual. |
| `inst/julia/src/modules/brain_size_evolution.jl:92` | `apply_brain_size_evolution!` | Large-brained agents take extra `delta = eat_gain * (bs - 1)` from `env.grass[x,y]`. First large-brained agent on a cell gets the full bonus; subsequent ones get less. |
| `inst/julia/src/modules/niche.jl:61` | `apply_niche_construction!` | Multiple agents on the same cell can all try to build shelter — but the per-cell shelter cap means later agents are blocked. Minor compared to the above. |
| `inst/julia/src/modules/tick_predators.jl:170` | `tick_predators!` main loop | First predator senses, moves, attacks first; later predators face a depleted prey field. Direct analogue of `tick_agents!` for predators (Rose finding). |
| `inst/julia/src/modules/tick_predators.jl:418` | `_predator_reproduction!` | Order-sensitive cap: `length(env.predators) + length(new_preds) >= max_preds && break`. First eligible predator reproduces; later ones may be cut off (Rose finding). |

### Order-insensitive (no change needed)

These iterate over agents but only modify per-agent state, use accumulator patterns, or are read-only. Order does not change outcomes.

| File:Line | Function | Why it's safe |
|---|---|---|
| `inst/julia/src/death.jl:48` | `kill_dead!` | Each agent's death is an independent draw against its own state. |
| `inst/julia/src/modules/ann_regularization.jl:111` | `apply_ann_regularization!` | Per-agent energy deduction only. |
| `inst/julia/src/modules/parental_care.jl:47` | `apply_care_costs!` | Per-agent energy only. |
| `inst/julia/src/modules/parental_care.jl:80` | `feed_offspring!` | Parent feeds own carried_offspring only. |
| `inst/julia/src/modules/parental_care.jl:207` | `age_juveniles!` | Parent ages own carried_offspring only. |
| `inst/julia/src/modules/cooperation.jl:81` | cooperation game | Accumulator pattern: `deltas[]` is summed across all focal agents; final state is order-independent. (Reads agent_map for neighbours — that's a Phase-2 issue, not Phase-1.) |
| `inst/julia/src/modules/seasonal.jl:57` | winter mortality | Independent per-agent random death. |
| `inst/julia/src/modules/disease.jl:67` | `seed_disease!` | Independent per-agent infection roll. |
| `inst/julia/src/modules/body_size.jl:61` | `apply_body_size!` | Per-agent metabolic surcharge only. |
| `inst/julia/src/modules/rl.jl:140` | `apply_rl!` | Per-agent brain weight update. |
| `inst/julia/src/modules/mimicry.jl:66` | `apply_toxicity_costs!` | Per-agent energy. |
| `inst/julia/src/modules/coevolving_parasite.jl:110` | centroid calc | Read-only over agents. |
| `inst/julia/src/modules/coevolving_parasite.jl:127` | parasite penalty | Per-agent penalty from shared `opt[]` (which was computed read-only). |
| `inst/julia/src/modules/coevolving_parasite.jl:179` | freq accumulation | Read-only. |
| `inst/julia/src/modules/coevolving_parasite.jl:205` | Hamming penalty | Per-agent from shared `par_hap[]`. |
| `inst/julia/src/modules/epigenetics.jl:236` | `apply_epigenetics!` | Per-agent methylome + brain. |
| `inst/julia/src/modules/group_defense.jl:56` | damage rescaling | Modifies pre-computed `damage[i]`; reads agent_map for neighbour count (Phase-2 issue, not Phase-1). |
| `inst/julia/src/modules/signals.jl:65` | `apply_signal_costs!` | Per-agent energy. |
| `inst/julia/src/modules/signals.jl:104` | `apply_signal_mortality!` | Independent per-agent mortality roll. |
| `inst/julia/src/modules/signals.jl:160` | `apply_preference_bias!` | Per-agent preference vector. |
| `inst/julia/src/modules/signals.jl:197` | `apply_signal_evolution!` | Per-agent drift. |
| `inst/julia/src/modules/signals.jl:245` | `apply_signal_toxicity_pleiotropy!` | Per-agent signal[1]. |
| `inst/julia/src/modules/niche.jl:137` | shelter feeding bonus | Per-agent energy from shared (read-only) shelter_map. |
| `inst/julia/src/modules/tick_predators.jl:385` | per-cell prey gain pass | Each predator on a kill cell receives `energy_gain` independently. Order-insensitive. |

### Rebuild loops (no Phase-1 change; Phase-2 affects)

These rebuild `env.agent_map` after a movement pass. The order in which agents are inserted determines who "wins" the slot at co-occupied cells. Phase 2 will replace the lossy per-cell `idx` storage with `cell_to_agents`; the rebuild loops themselves stay as-is.

| File:Line | Function |
|---|---|
| `inst/julia/src/tick.jl:197` | `tick_agents!` rebuild |
| `inst/julia/src/death.jl:110` | `remove_dead!` rebuild |
| `inst/julia/src/modules/habitat_preference.jl:97` | habitat rebuild |
| `inst/julia/src/modules/tick_predators.jl:202` | predator_map rebuild |

## Phase 1 implementation summary

Add `random_tick_order::Bool` spec field (default TRUE). At each of the **nine** order-sensitive sites above (seven agents + two predators), replace the iteration with:

```julia
n = length(env.agents)
order = Bool(get(env.specs, "random_tick_order", true)) ? randperm(env.rng, n) : (1:n)
for i in order
    ag = env.agents[i]
    # ... existing body
end
```

For sites that use `enumerate(env.agents)` to track index (reproduce.jl, group_defense.jl), the same shuffle applies but `idx` becomes `i` from the order. Predator sites (`for pred in env.predators`) use `env.predators` instead of `env.agents` but identical pattern.

Total: **9 call-site changes** across 8 files (7 agents + 2 predators).

## Rose generalisation findings

Investigated the *class* of "fixed-order iteration over a population" beyond `env.agents`:

- **`env.predators` has the same bias** — added 2 predator iteration sites above (tick_predators.jl:170 main loop, :418 reproduction). Originally missed because the audit grep only matched `env.agents`. Lesson: any per-population iteration is suspect.
- **No `1:length(env.agents)` patterns found** — clean iteration style overall.
- **No global-RNG calls (`rand()` without `env.rng`)** — RNG hygiene is good.

## Out-of-scope opportunistic findings

Logged here for the user's consideration after Phase 0; not changed in Phase 1.

- `dispersal.jl:99` and `habitat_preference.jl:84` clear `env.agent_map[ax,ay] = 0` on the source cell of a move, which silently erases any *other* agent that was co-occupying that cell. This is the cell-occupancy bug manifesting as actual data corruption (not just lossy lookup). Phase 2 will replace these with `cell_to_agents` updates that respect multi-occupancy.
- `tick_predators.jl:315` does the same source-cell clear for `predator_map`. Same data-corruption class — predators co-occupying a cell get erased on a move.
