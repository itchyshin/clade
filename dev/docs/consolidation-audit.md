# Consolidation audit — clade vs alifeR vs MATLAB ancestor

**Date**: 2026-05-05
**Triggered by**: Sergio flagged tick-order and cell-occupancy bugs in clade. Tracing the bugs revealed they are **regressions** from the original Bulitko/MATLAB design that successive ports lost. This doc systematically diffs clade against the two ancestor codebases for the core tick loop and the modules touched in Phase 1.

## Codebases

| Name | Path | Author | Role |
|---|---|---|---|
| **MATLAB ancestor** | `~/Dropbox/Github Local/alifeR/alife_matlab/codebase/` | Vadim Bulitko (Aug 2023) | Canonical reference design |
| **alifeR** | `~/Dropbox/Github Local/alifeR/` | The user (R port, Rcpp tick) | First port; intermediate ancestor |
| **clade** | `~/Dropbox/Github Local/clade/` (this repo) | The user (Julia port + extensions) | Current codebase; many added modules |

Existing per-file consolidation docs live in [dev/docs/kernel-as-biology/](kernel-as-biology/) and version-specific ones in [dev/docs/kernel-0.X.Y.md](.). This audit produces a single cross-codebase summary that the previous docs lack.

## Methodology

For each behaviour, ask:

1. What does MATLAB do? (file:line citation)
2. What does alifeR do? (file:line citation)
3. What does clade do? (file:line citation)
4. Classify the difference:
   - **Intentional (biology)** — keep, document the rationale.
   - **Intentional (architecture/perf)** — keep, document.
   - **Regression** — fix, restoring ancestor behaviour.
   - **Ambiguous** — flag for user decision.

## Summary table

| Behaviour | MATLAB | alifeR | clade | Class | Action |
|---|---|---|---|---|---|
| Random tick scheduling | ✅ once per tick at top of loop | ❌ array order | ❌ array order | **Regression** | **Phase 1 done** (restored — but per-site, see ★ below) |
| One-agent-per-cell at movement | ✅ enforced at movement | ✅ enforced at movement (Rcpp) | ❌ unrestricted | **Regression** | **Phase 2 (revised)**: restore movement-time check |
| `max_bite` handling time | ✅ | ✅ | ✅ (restored 0.4.0) | Already consolidated | none |
| Energy cap on eating | `min(1, prev + eaten)` | `min(energy_init, prev + eaten)` | `min(energy_max, prev + eaten)` | **Intentional (scale)** | none |
| In-tick teach+learn (social) | ✅ inline at end of takeAction | ❌ removed | ❌ moved to optional `apply_social_learning!` module | **Intentional (architecture)** | none |
| In-tick self-reflect | ✅ inline | ❌ removed | ❌ removed | Likely **intentional**; user confirm | flag |
| Brain types | ANN only | ANN only | ANN, BNN, CTRNN, GRN | **Intentional (extension)** | none |
| Body size as trait | ✗ none | ✗ none | ✅ added | **Intentional (extension)** | none |
| Many added modules (kin, mimicry, signals, ...) | ✗ none | ✗ none | ✅ added | **Intentional (extension)** | none |
| Sensing radius | radius 1 cardinal (5 cells) | parameterised `input_radius` (default 1) | radius 1 cardinal (hardcoded) | **Ambiguous** — was alifeR's parameter dropped intentionally? | flag |
| `_brain_energy_cost` model | size-only (sum |W|) × coefficient | size-only | activity / size / sigma / prediction_error modes | **Intentional (extension)** | none |

### ★ Phase 1 architectural sub-finding

MATLAB shuffles **once per tick at the top of the loop** ([alife.m:324](alife_matlab/codebase/alife.m)) by *reordering* `env.agent`. All subsequent per-agent operations within that tick (RL update, takeAction) iterate `1:length(env.agent)` in the **already-shuffled** array, so they share the same order.

My Phase 1 implementation calls `randperm` separately at each of 9 order-sensitive sites. This is functionally equivalent (random asynchronous scheduling) but uses more RNG draws per tick than MATLAB. Functional impact is zero; provenance is slightly different. **Recommend: leave as-is** — clade has more dispatched modules than MATLAB, so a single-shuffle-at-top would have to cross many module boundaries to remain coherent. The per-site shuffle is a clean adaptation.

## Detailed findings

### 1. Random tick scheduling (✅ Phase 1 fixed)

**MATLAB** ([alife.m:324](alife_matlab/codebase/alife.m)):
```matlab
% randomize the agent sequence
env.agent = env.agent(randperm(length(env.agent)));
```
Done once per tick before the RL update and the agent action loop.

**alifeR** ([R/run_alife.R](R/run_alife.R), [src/tick_agents.cpp](src/tick_agents.cpp)): no shuffle. The Rcpp tick iterates `for (int i = 0; i < n; i++)` in array order. **Regression introduced when porting to R.**

**clade** (pre-Phase-1): same — array-order iteration in [tick.jl:120](inst/julia/src/tick.jl), [reproduce.jl:59](inst/julia/src/reproduce.jl), [tick_predators.jl:170](inst/julia/src/modules/tick_predators.jl), and 6 other apply_*! modules. **Regression inherited from alifeR.**

**clade (post-Phase-1)**: 9 order-sensitive sites wrap iteration in `randperm(env.rng, n)` when `random_tick_order = TRUE` (new default). Spec field flips to legacy fixed-order for reproducibility audits. Tests in [tests/testthat/test-tick-order.R](tests/testthat/test-tick-order.R).

**Status**: ✅ regression fixed.

### 2. One-agent-per-cell at movement (Phase 2, revised)

**MATLAB** ([takeAction.m:79, :91, :103, :115](alife_matlab/codebase/takeAction.m)) — for each cardinal direction:
```matlab
% see if we can go there (i.e., not out of bounds, no walls, and no other agents there)
if (newx > 0 && ~env.walls(newy,newx) && env.agents(newy,newx) == 0)
    env = moveAgent(env,i,newx,newy);
else
    env = moveAgent(env,i,env.agent(i).state.x,env.agent(i).state.y);  % stay put
end
```
Movement into a cell occupied by another agent is **rejected**; the agent stays in place.

**alifeR** ([src/tick_agents.cpp:254-258](src/tick_agents.cpp)):
```cpp
bool can_move = (act == 5) || (
  nx >= 0 && nx < nr && ny >= 0 && ny < nc &&
  walls(nx, ny)     == 0 &&
  agent_map(nx, ny) == 0
);
```
Same enforcement, in C++. Preserved from MATLAB.

**clade** ([inst/julia/src/tick.jl:138-157](inst/julia/src/tick.jl)) — movement code is unrestricted:
```julia
elseif action == 1      # N
    x = wrap_or_clamp(x - 1, rows, toroidal)
    ag.energy -= move_cost * ag.metabolic_rate
# ... etc, no agent_map check
```
**Regression introduced when porting to Julia.**

**Phase 2 (revised) action**: add `agent_map[nx,ny] == 0` gate to the movement code in `tick.jl`. If the target cell is occupied (and it's not the stay action), the agent stays put (energy still consumed). Same change in `tick_predators.jl` for predator movement (using `predator_map`). This makes the previous Policy A `cell_to_agents` lookup unnecessary — once movement enforces uniqueness, all existing `agent_map`-based lookups are correct.

The forward-compat `max_agents_per_cell` spec field becomes redundant under Policy B; can be added later if scenarios ever need *bounded* multi-occupancy (e.g. 2 agents per cell to model nesting), but not now per Karpathy 2 (no speculative configurability).

**Action**: **Phase 2 implementation** below.

### 3. Energy cap on eating (intentional scale difference)

**MATLAB** ([takeAction.m:142-144](alife_matlab/codebase/takeAction.m)): `min(1, prevEnergy + amountEaten)` — energy is in [0,1].

**alifeR** ([src/tick_agents.cpp:279](src/tick_agents.cpp)): `min(energy_init, prev_e + eaten)` — energy capped at the initial value (default 100).

**clade** ([inst/julia/src/tick.jl:188](inst/julia/src/tick.jl)): `min(ag.energy, energy_max)` — energy_max defaults to 200.

**Class**: Intentional. The scales differ (1 vs 100 vs 200) but the structure is the same. clade allows agents to *gain* energy above the initial 100 by eating well (up to energy_max=200), which is more biologically sensible (a well-fed animal has reserves above its starting level) and supports body-size-driven energy capacity (agents with body_size > 1 get a higher cap).

**Action**: none.

### 4. In-tick teach+learn (intentional architectural difference)

**MATLAB** ([takeAction.m:153-163](alife_matlab/codebase/takeAction.m)): at the END of each agent's tick, picks a random other agent and calls `teachlearn(env.agent(i), env.agent(j), env.teachlearn)`.

**alifeR**: removed; teaching/learning is not present in alifeR's Rcpp tick.

**clade**: refactored as `apply_social_learning!` ([inst/julia/src/modules/social_learning.jl](inst/julia/src/modules/social_learning.jl)), called from the main tick loop every `social_learning_freq` ticks (when enabled).

**Class**: Intentional architectural change. Decoupling teach+learn from per-agent tick is the right modular pattern (it can be enabled/disabled, frequency-tuned, replaced with other learning algorithms). The MATLAB version was a single fixed mechanism baked into the per-agent loop.

**Action**: none. Should be documented as a known architectural divergence.

### 5. In-tick self-reflect (intentional? confirm)

**MATLAB** ([takeAction.m:151](alife_matlab/codebase/takeAction.m)): `env.agent(i) = selfReflect(env.agent(i), env.selfreflect);`

**alifeR**: removed.

**clade**: no equivalent.

**Class**: Likely intentional (alifeR also dropped it). But what was `selfReflect` doing? Potentially a per-agent state self-update (epsilon-greedy decay, exploration-exploitation balance, internal state machine). If clade has nothing equivalent, that's a feature gap, not just a removal.

**Action**: **flag** — user confirms this is intentional. If yes, document. If not, investigate what selfReflect did and whether clade should have an equivalent.

### 6. Sensing radius parameter (ambiguous)

**alifeR** ([src/tick_agents.cpp:155](src/tick_agents.cpp)): `int input_radius` is a parameter, used in `dir_signal_num/bin` — sensing range is configurable.

**clade** ([inst/julia/src/sense.jl](inst/julia/src/sense.jl)): cardinal-neighbour sensing at radius 1 only (cardinal cells `[xN,y]`, `[x,yE]`, `[xS,y]`, `[x,yW]`). Hardcoded.

**Class**: Ambiguous. clade's hardcoded radius-1 simplification might be intentional (uniform model across scenarios) or might be a port shortcut.

**Action**: **flag** — user decides. Parameterising sensing radius is a small change with possible biological implications (visual range varies between species).

### 7. Other clade extensions (intentional, no action needed)

These are **clade-only features** added on top of the alifeR base — all intentional, no consolidation needed:

- BNN, CTRNN, GRN brain types (clade only; alifeR is ANN-only)
- Body size as evolved trait
- Mimicry/toxicity module
- Signal evolution (Lande, Fisher runaway, Zahavi handicap, Ryan sensory bias)
- Coevolving parasites (Hamilton 1980 Red Queen)
- Iffolk inclusive-fitness parliament
- Cooperative breeding
- Many others — see [README.md](../../README.md) module table

These are documented per-module in [dev/docs/kernel-as-biology/](kernel-as-biology/) and [README.md](../../README.md).

## What was NOT yet audited

This audit covers the **core tick loop** and the **modules touched in Phase 1**. The following are **not audited** in this round (Rose-class candidates for future work):

- **death.jl vs removeDeadAgents.m** — likely consistent (alifeR ports it cleanly).
- **reproduce.jl vs MATLAB produceOffspring*** — likely many differences (clade has clutch size evolution, body-size-coupled offspring energy, etc., all 0.4.0+ extensions). Worth a focused audit before Wolf 2007 (Phase 3).
- **sense.jl vs senseEnv.m** — radius parameter (item 6 above) is the main known divergence; might be others.
- **The 30+ optional modules** in `inst/julia/src/modules/` — most are clade extensions with no MATLAB equivalent, but some (kin.jl, cooperation.jl, dispersal.jl, parental_care.jl) have alifeR predecessors. Worth a per-module micro-audit when those modules are next touched.
- **R-side spec wiring** — the 0.6.4 incident class. Phase 6 in the main plan covers this; not duplicated here.

## Conclusion + recommendations

1. **Two regressions confirmed**: scheduling (Phase 1 done), occupancy (Phase 2 revised — see below).
2. **Two flags for user decision**: in-tick self-reflect (item 5), sensing radius parameter (item 6).
3. **Major intentional divergences**: brain types, body size, signal evolution, optional-module architecture. All clade-only extensions, all documented elsewhere; no consolidation action needed.
4. **The alifeR-vs-MATLAB regressions audit was incomplete** — we systematically checked tick scheduling and movement occupancy because those were known bugs, but other regressions of the same class may exist. Recommend a per-module micro-audit as each module is next touched (especially `reproduce.jl` before Phase 3 Wolf 2007).
