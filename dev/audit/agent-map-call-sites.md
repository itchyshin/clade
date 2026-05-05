# agent_map call-sites catalogue (Phase 0.2)

Every use of `env.agent_map`, classified by intent. Phase 2 will fix only the sites that genuinely need multi-occupancy semantics; sites that just need a boolean "is anything here?" stay on `agent_map` (cheap, correct intent).

Generated: 2026-05-05. Plan reference: `~/.claude/plans/purring-honking-dove.md` Phase 0.2.

## Methodology

Read each call site's surrounding code. Classification:

- **"Is anything here?"** — boolean test (`> 0` or `== 0`). Lossy aggregation is fine; the answer just needs yes/no.
- **"Which agent is here?"** — looks up the index and dereferences `env.agents[idx]`. **Lossy under co-occupancy**: returns *an* agent, not all of them, and which one is biased by the rebuild order (Phase 1's tick-order bias compounded).
- **"How many agents are here?"** — currently impossible from `agent_map` alone. None present today; Wolf hawk-dove (Phase 3) and Trivers reciprocity (Phase 4) will need this.
- **Write (placement / move)** — sets `agent_map[x,y] = idx` on movement or birth. Has the same overwrite issue: if another agent was already on the target cell, that agent is silently erased from agent_map.
- **Construction / rebuild** — initialisation or per-tick rebuild of the whole map. Phase 2 keeps these but adds a parallel `cell_to_agents` rebuild.

## Catalogue

### Construction / rebuild (no semantic change in Phase 2; gain a parallel cell_to_agents rebuild)

| File:Line | Use |
|---|---|
| `inst/julia/src/Clade.jl:246-248` | initial allocation + first fill in `create_environment` |
| `inst/julia/src/Clade.jl:270` | passed to Environment constructor |
| `inst/julia/src/types.jl:339, 372` | type definition |
| `inst/julia/src/tick.jl:118` | `fill!(env.agent_map, 0)` before the move loop |
| `inst/julia/src/tick.jl:198` | rebuild after `tick_agents!` |
| `inst/julia/src/death.jl:109-111` | rebuild after `remove_dead!` |
| `inst/julia/src/modules/habitat_preference.jl:96-98` | rebuild after habitat moves |

### "Is anything here?" — boolean test, leave on agent_map

These are correct as-is (yes/no answer suffices). No Phase 2 change.

| File:Line | Function | Use |
|---|---|---|
| `inst/julia/src/sense.jl:87-90` | `sense_agent` | Cardinal-neighbour boolean sense input. |
| `inst/julia/src/modules/dispersal.jl:87` | `apply_dispersal!` | Free-cell check before claiming. |
| `inst/julia/src/modules/parental_care.jl:160` | graduate offspring | Free-cell check for juvenile placement. |
| `inst/julia/src/modules/habitat_preference.jl:70` | habitat moves | Free-cell check before claiming. |
| `inst/julia/src/modules/tick_predators.jl:259` | predator scan | Boolean prey-presence in scan range. |

**Caveat**: "free cell" semantics are biased — they report a cell as occupied when one or more agents are there, which is fine for "don't move into an occupied cell" *unless the user wants Policy B (one-per-cell) eventually* — at which point these become the enforcement points. Until then, no change.

### "Which agent is here?" — single-index dereference, **switch to cell_to_agents in Phase 2**

These lookups currently get one of the agents at a co-occupied cell, biased by rebuild order. Phase 2 will switch each to `cell_to_agents[x,y]` and choose explicitly: enumerate all (the multi-pair case for hawk-dove / reciprocity), or pick one at random (preserving current single-agent semantics without the order bias).

| File:Line | Function | What it does | Phase 2 treatment |
|---|---|---|---|
| `inst/julia/src/reproduce.jl:266` | mate-search neighbour lookup | Looks up potential mate at neighbour cell. | Pick at random from `cell_to_agents[nx,ny]`. |
| `inst/julia/src/modules/kin.jl:120, 207` | kin-altruism neighbour | Energy transfer between kin neighbours. | Enumerate all — current code only sees one of N kin on a co-occupied cell. |
| `inst/julia/src/modules/cooperation.jl:95` | cooperation game neighbour | Public-goods pool contribution. | Enumerate all. |
| `inst/julia/src/modules/disease.jl:153, 258` | disease transmission target | Infect a susceptible neighbour. | Enumerate all (each gets independent transmission roll). |
| `inst/julia/src/modules/social_learning.jl:158` | social-learning model neighbour | Copies model agent's brain. | Pick at random. |
| `inst/julia/src/modules/cooperative_breeding.jl:121` | helper neighbour | Alloparental energy transfer. | Enumerate all helpers. |
| `inst/julia/src/modules/tick_predators.jl:330` | `prey_idx = env.agent_map[pred.x, pred.y]` | Predator picks prey on its own cell. **If two prey on the cell, predator only ever sees one** — biased prey selection. | Pick at random from prey on the cell. |

### Counts via boolean accumulator — borderline; Phase 2 candidate

These count neighbours by counting non-zero cells. Will undercount whenever multiple agents share a cell. Probably a small effect at typical density but worth measuring.

| File:Line | Function | What it counts |
|---|---|---|
| `inst/julia/src/reproduce.jl:359` | mate availability count | Used to gate reproduction. |
| `inst/julia/src/modules/group_defense.jl:66` | live-prey count in defence radius | Used to dilute predator damage. |

**Phase 2 treatment**: switch to `length(env.cell_to_agents[nx,ny])` so counts reflect true multi-occupancy.

### Move-source clears — actual data corruption bugs

These set `agent_map[x,y] = 0` to vacate the source cell on a move. Under co-occupancy this **erases other agents from the map**: anyone else who was on the source cell becomes invisible to subsequent agent_map lookups until the next rebuild.

| File:Line | Function |
|---|---|
| `inst/julia/src/modules/dispersal.jl:99` | `apply_dispersal!` source-cell clear |
| `inst/julia/src/modules/habitat_preference.jl:84` | habitat-move source-cell clear |

**Phase 2 treatment**: replace with `cell_to_agents[x,y] = filter(!=(idx), cell_to_agents[x,y])` (and update agent_map only if the cell becomes empty). Also need to update `cell_to_agents[nx_new,ny_new]` — push the moving agent's idx.

### Move-target writes — silent overwrite

These set `agent_map[x,y] = idx` on placement, silently overwriting any existing occupant in agent_map.

| File:Line | Function |
|---|---|
| `inst/julia/src/reproduce.jl:202` | offspring placement |
| `inst/julia/src/modules/dispersal.jl:102` | dispersal target placement |
| `inst/julia/src/modules/habitat_preference.jl:89` | habitat target placement |
| `inst/julia/src/modules/parental_care.jl:164` | graduating-juvenile placement |

**Phase 2 treatment**: the `agent_map` write stays (last-rebuilt-wins is the legacy semantic and we don't want to break the "is anything here?" sites that now branch on it). The new `cell_to_agents[x,y]` push is the additional update — it captures the multi-occupancy that `agent_map` cannot.

## Phase 2 implementation summary

1. **Add `cell_to_agents::Matrix{Vector{Int32}}` field to `Environment`** (`inst/julia/src/types.jl`), allocated once at env construction (`inst/julia/src/Clade.jl:246` area).
2. **Add `max_agents_per_cell::Int` spec field** (default 0 = unbounded). Currently unused; reserved for the future Policy B (one-per-cell) switch.
3. **Rebuild `cell_to_agents` after `tick_agents!`** (in `Clade.jl`'s tick loop, immediately after the existing `agent_map` rebuild). Same after `remove_dead!` and habitat-preference rebuild — wherever `agent_map` gets rebuilt, `cell_to_agents` rebuilds too.
4. **Update the 7 "which agent is here?" sites** to use `cell_to_agents` (enumerate all, or pick at random — see table).
5. **Update the 2 count sites** (`reproduce.jl:359`, `group_defense.jl:66`) to use `length(cell_to_agents[...])`.
6. **Fix the 2 move-source clears** (`dispersal.jl:99`, `habitat_preference.jl:84`) to remove only the moving agent's id from the source cell's vector, not zero the agent_map slot blindly.
7. **Update the 4 move-target writes** to also push to `cell_to_agents[target]`.

Total: **~17 call-site changes** across 9 files. The "is anything here?" sites and construction/rebuild sites stay on `agent_map`.

## Rose generalisation: predator_map has the same problem

Searching for the *class* of "lossy per-cell map of population members" found that `env.predator_map` has identical (and worse) issues:

- **Even more lossy**: `env.predator_map[px, py] = 1` stores Int64(1) — pure boolean. It can't even tell which predator is on the cell. Multiple predators are silently collapsed.
- **Same move-source clear bug**: [tick_predators.jl:315](inst/julia/src/modules/tick_predators.jl) does `env.predator_map[pred.x, pred.y] = 0` on the source cell of a move. If two predators were co-occupying, the second is erased from the map.
- **Same construction/rebuild pattern**: [Clade.jl:271](inst/julia/src/Clade.jl) allocation, [tick_predators.jl:200-203](inst/julia/src/modules/tick_predators.jl) rebuild.

### Predator_map call-site catalogue

| File:Line | Use | Intent |
|---|---|---|
| `inst/julia/src/Clade.jl:271` | `zeros(Int64, rows, cols)` | construction — N/A |
| `inst/julia/src/types.jl:341, 373` | type definition |  |
| `inst/julia/src/sense.jl:138` | `env.predator_map[x, y] > 0` | "Is anything here?" — boolean predator-presence sense input. Lossy aggregation OK. |
| `inst/julia/src/modules/tick_predators.jl:131` | `env.predator_map[px, py] = 1` | placement |
| `inst/julia/src/modules/tick_predators.jl:201-203` | rebuild after predator moves |  |
| `inst/julia/src/modules/tick_predators.jl:315` | `env.predator_map[pred.x, pred.y] = 0` | move-source clear (**same data-corruption bug** as dispersal/habitat) |
| `inst/julia/src/modules/tick_predators.jl:318` | `env.predator_map[nx, ny] = 1` | move-target placement |
| `inst/julia/src/modules/tick_predators.jl:480` | `env.predator_map[off.x, off.y] = 1` | offspring placement |

**Phase 2 treatment**: add a parallel `cell_to_predators::Matrix{Vector{Int32}}` field on `Environment`, rebuilt the same way as `cell_to_agents`. Wire it into the move-source clear so co-occupying predators are not erased.

Total additional Phase 2 work: ~5 call-site changes for predator_map.

## Out-of-scope opportunistic findings

- The `agent_map` field is `Matrix{Int64}` (8 bytes per cell), but agent indices are `Int32`. For a 200×200 grid that's 320 KB vs 160 KB — small absolute saving, not worth a separate phase.
- The "free-cell check" sites in dispersal and habitat_preference become redundant under Policy B (which will reject the move at the movement code itself). Worth bundling with the eventual Policy B work; not worth touching now.
- `predator_map` storing Int64(1) where Int32 or Bool would do (since it's a boolean) — micro-optimisation, not worth a separate phase.
