# Custom Modules: Extending clade with Per-Tick Hooks

## 1. Concept — when to reach for a custom module

`clade` exposes a module registry that lets you attach your own R
functions into the Julia tick loop at named points. The function
receives a snapshot of the environment, can read any field it needs, can
modify agent state, and returns the snapshot for the next step to use.

Use custom modules when you need one of:

- **Bespoke logging.** Record a quantity that isn’t in the built-in
  `progress` columns — for example, the per-cell variance of agent
  energy, the pedigree depth of the oldest agent, or the spatial
  auto-correlation of some trait.
- **Experimental interventions.** Perturb the environment or agent state
  at specific ticks. Classic designs: injecting energy at tick 100 to
  simulate a food pulse, removing a random third of agents at tick 200
  to simulate a disaster, switching `seasonal_amplitude` mid-run.
- **Post-hoc analysis.** Accumulate a user-defined statistic in an R
  closure variable during the run, then inspect it after.

### When NOT to use a custom module

Don’t reach for custom modules if a built-in module flag does the job.
Every `*_evolution` flag and every biological module in
[`vignette("parameter-reference")`](../articles/parameter-reference.md)
is implemented in Julia with no R↔︎Julia round-trip per tick. Enabling
those is both faster and more thoroughly audited than writing your own.

A rough decision rule:

| Your need                                                                                         | Right tool                                   |
|---------------------------------------------------------------------------------------------------|----------------------------------------------|
| Toggle a biological mechanism (disease, kin selection, cooperation, niche construction, …)        | Existing module flag in `specs`              |
| Evolve a heritable trait that already lives on `Agent` (body size, metabolic rate, plasticity, …) | Existing `*_evolution` flag                  |
| Compute a new derived statistic each tick                                                         | Custom module (`post_tick`)                  |
| Intervene on agent state mid-run                                                                  | Custom module (`post_agents` or `post_tick`) |
| Change *how* reproduction or death works                                                          | Fork the Julia kernel — not a module         |

Custom modules cannot add new fields to the `Agent` struct (it’s fixed
at Julia compile time) and cannot introduce new biological mechanics
that don’t fit in “read/modify agent energy and alive status,
read/modify the grass matrix, accumulate a statistic”.

------------------------------------------------------------------------

## 2. The four hook points

clade calls the custom module registry at four named hook points inside
each tick. Choosing the right hook point is the main design decision.

    ┌──────────── tick(t) ────────────────────────────────────────────────┐
    │                                                                      │
    │  "pre_tick"       ← fires FIRST                                      │
    │       │                                                              │
    │       ▼                                                              │
    │  grow_grass! + other resource regrowth                               │
    │       │                                                              │
    │       ▼                                                              │
    │  tick_agents!  (agents sense → decide → move → eat)                  │
    │       │                                                              │
    │       ▼                                                              │
    │  "post_agents"    ← fires after movement and eating                  │
    │       │                                                              │
    │       ▼                                                              │
    │  apply_*!  (body size, dispersal, signals, predators, disease, …)    │
    │       │                                                              │
    │       ▼                                                              │
    │  "post_tick"      ← fires after all trait/module corrections          │
    │       │                                                              │
    │       ▼                                                              │
    │  kill_dead! + remove_dead!                                           │
    │       │                                                              │
    │       ▼                                                              │
    │  create_offspring!                                                   │
    │       │                                                              │
    │       ▼                                                              │
    │  "post_reproduce" ← fires LAST, just before log_tick!                │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘

Which hook to pick:

| Goal                                                    | Hook                    | Why                                                                                                                                 |
|---------------------------------------------------------|-------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| Modify the initial state of the world before agents act | `"pre_tick"`            | Changes are visible when agents sense this tick                                                                                     |
| Score agent decisions / log what agents did this tick   | `"post_agents"`         | Movement and eating have completed, death and reproduction have not                                                                 |
| Standard user-level logging and analysis                | `"post_tick"` (default) | The world is in its “end of biological activity” state; death and reproduction still come but the tick’s action is done             |
| Track births and deaths explicitly                      | `"post_reproduce"`      | Newborn agents are in the population; dead agents have been removed; this is as late as you can observe before the next tick starts |

### Example — one module per hook

Each hook receives the same snapshot type
(`list(agents, grass, t, specs)`), so the function signature is
identical across hooks. What differs is *when* it fires and therefore
what state the snapshot reflects.

``` r
library(clade)
clear_modules()

# pre_tick: freeze grass growth every 10 ticks to create a drought pulse
register_module(
  when = "pre_tick",
  name = "drought_pulse",
  fn   = function(env) {
    if (env$t %% 10 == 0) env$grass[] <- 0
    env
  }
)

# post_agents: record the spatial variance of post-move agent positions
spatial_var <- numeric(0)
register_module(
  when = "post_agents",
  name = "position_variance",
  fn   = function(env) {
    if (length(env$agents) > 1L) {
      xs <- vapply(env$agents, `[[`, numeric(1L), "x")
      ys <- vapply(env$agents, `[[`, numeric(1L), "y")
      spatial_var <<- c(spatial_var, var(xs) + var(ys))
    }
    env
  }
)

# post_tick: accumulate top-quartile energy (standard logging)
top_quartile <- numeric(0)
register_module(
  when = "post_tick",
  name = "top_quartile_energy",
  fn   = function(env) {
    if (length(env$agents) > 0L) {
      es <- vapply(env$agents, `[[`, numeric(1L), "energy")
      top_quartile <<- c(top_quartile, quantile(es, 0.75))
    }
    env
  }
)

# post_reproduce: record births actually realised this tick
births_per_tick <- integer(0)
register_module(
  when = "post_reproduce",
  name = "births",
  fn   = function(env) {
    # Note: newborns carry t_birth == env$t
    n_new <- sum(vapply(env$agents,
                        function(a) isTRUE(a$t_birth == env$t),
                        logical(1L)))
    births_per_tick <<- c(births_per_tick, n_new)
    env
  }
)

specs <- default_specs(); specs$max_ticks <- 300L
env <- run_alife(specs)
# spatial_var, top_quartile, births_per_tick are now populated

clear_modules()
```

The four closure variables (`spatial_var`, `top_quartile`,
`births_per_tick`, plus the drought pulse which has no closure) now hold
the per-tick logs. You can plot, summarise, or save them alongside the
standard output.

------------------------------------------------------------------------

## 3. API reference

``` r
register_module(fn, when = "post_tick", name = NULL)
list_modules()
clear_modules()
```

**`register_module(fn, when, name)`**

- `fn`: a function with signature `function(env) -> env`. It must
  *return* the (possibly modified) snapshot — if you return `NULL` or
  something else, the simulation will error on the next hook.
- `when`: one of `"pre_tick"`, `"post_agents"`, `"post_tick"`,
  `"post_reproduce"`. Default `"post_tick"`.
- `name`: label used in [`list_modules()`](../reference/list_modules.md)
  output. If omitted, modules are auto-named `"module_1"`, `"module_2"`,
  etc.

**[`list_modules()`](../reference/list_modules.md)** returns a character
vector of `"name (when)"` entries in registration order. Multiple
modules at the same hook run in that order.

**[`clear_modules()`](../reference/clear_modules.md)** empties the
registry. Calling it between runs is essential if you don’t want the
last run’s modules applied to the next one.

### The snapshot

`env` inside a module is a minimal R list, not the full `clade_env`:

| Field        | Type           | What it is                                                                      |
|--------------|----------------|---------------------------------------------------------------------------------|
| `env$t`      | integer        | Current tick index                                                              |
| `env$specs`  | named list     | The specs list passed to [`run_alife()`](../reference/run_alife.md) (read-only) |
| `env$agents` | list of lists  | One entry per live agent; see agent-field table below                           |
| `env$grass`  | numeric matrix | Rows × cols of grass units per cell                                             |

Modifying `env$agents[[i]]$energy` changes that agent’s energy. Setting
`env$agents[[i]]$alive <- FALSE` kills the agent; it will be removed at
the next `remove_dead!` step. Modifying `env$grass[x, y]` changes the
resource available at that cell for the next tick.

You cannot add new fields to the agent records — the Julia struct has a
fixed schema. You can read any existing field.

------------------------------------------------------------------------

## 4. Worked example — top-quartile energy tracker

The most common pattern: accumulate a per-tick statistic into a closure
variable and inspect it after the run.

``` r
library(clade)
library(ggplot2)

clear_modules()

top_quartile_energy <- numeric(0)

register_module(
  when = "post_tick",
  name = "top_quartile",
  fn   = function(env) {
    if (length(env$agents) > 0L) {
      es <- vapply(env$agents, `[[`, numeric(1L), "energy")
      top_quartile_energy <<- c(top_quartile_energy, quantile(es, 0.75))
    }
    env
  }
)

specs <- default_specs(); specs$max_ticks <- 400L
env <- run_alife(specs)

data <- get_run_data(env)
data$ticks$top_quartile_energy <- c(NA, top_quartile_energy)[seq_len(nrow(data$ticks))]

ggplot(data$ticks, aes(t, top_quartile_energy)) +
  geom_line() +
  labs(title = "75th percentile of agent energy over time",
       x = "Tick", y = "Q75(energy)") +
  theme_minimal()

clear_modules()
```

The `<<-` is what makes this pattern work: it assigns to the
`top_quartile_energy` vector in the enclosing scope, not a local copy.
Without `<<-` the module would populate a local variable that is
discarded when the function returns. This is the single most common
mistake in custom modules.

------------------------------------------------------------------------

## 5. Worked example — mid-run intervention

This module injects energy into every agent at exactly one tick —
modelling an experimental food pulse:

``` r
clear_modules()

register_module(
  when = "post_tick",
  name = "food_pulse",
  fn   = function(env) {
    if (env$t == 100L) {
      for (i in seq_along(env$agents)) {
        env$agents[[i]]$energy <- env$agents[[i]]$energy + 50
      }
    }
    env
  }
)

specs <- default_specs(); specs$max_ticks <- 300L
env  <- run_alife(specs)
data <- get_run_data(env)

clear_modules()
```

The effect should be visible as a step change in
`data$ticks$mean_energy` at tick 100. Compare against a paired control
run with [`clear_modules()`](../reference/clear_modules.md) to quantify
the perturbation’s downstream effect.

------------------------------------------------------------------------

## 6. Worked example — spatial spread logger

Record the spatial variance of agent positions each tick — a measure of
how tightly agents aggregate:

``` r
library(clade)

clear_modules()

spatial_variance <- numeric(0)

register_module(
  when = "post_agents",
  name = "spatial_variance",
  fn   = function(env) {
    if (length(env$agents) > 1L) {
      xs <- vapply(env$agents, `[[`, numeric(1L), "x")
      ys <- vapply(env$agents, `[[`, numeric(1L), "y")
      spatial_variance <<- c(spatial_variance, var(xs) + var(ys))
    }
    env
  }
)

specs <- default_specs(); specs$max_ticks <- 400L
env <- run_alife(specs)

# spatial_variance is a numeric vector indexed by tick
plot(spatial_variance, type = "l",
     xlab = "Tick", ylab = "Spatial variance",
     main = "Dispersion of agent positions")

clear_modules()
```

`"post_agents"` is the right hook here because movement has just
happened and no deaths have yet been applied — we see the positions of
*all live agents after their moves*, which is the biologically
meaningful snapshot for spatial dispersion.

------------------------------------------------------------------------

## 7. Error handling

Custom modules are called inside a `tryCatch` wrapper
([`R/modules.R:126-134`](../R/modules.R#L126)). Any error raised by your
function is converted into an R warning and the simulation continues
with the unmodified snapshot. This is deliberately forgiving — you can’t
accidentally crash a 500-tick run by writing a bad module — but it means
silent data-loss bugs are possible.

### Pattern: defensive sub-steps

For long-running analyses, wrap the risky part in your own `tryCatch` so
you can log which tick failed:

``` r
clear_modules()

error_log <- list()

register_module(
  when = "post_tick",
  name = "safe_pairwise",
  fn   = function(env) {
    result <- tryCatch({
      # Anything risky — matrix ops, I/O, external calls
      pairwise_distance_matrix(env$agents)   # hypothetical helper
    }, error = function(e) {
      error_log[[length(error_log) + 1L]] <<- list(t = env$t, msg = conditionMessage(e))
      NULL
    })
    # ... use result, possibly skipping this tick
    env
  }
)
```

### Pattern: assertions that halt early

If your module’s output must be valid for the analysis to make sense,
throw a stop that breaks the run:

``` r
register_module(
  when = "post_tick",
  name = "invariant_check",
  fn   = function(env) {
    if (length(env$agents) == 0L)
      stop("Population extinct at tick ", env$t)
    env
  }
)
```

Because the wrapper catches this and only warns, the run won’t stop. But
you’ll get a readable warning stream that tells you when extinction
occurred without having to grep through per-tick output.

### Debugging tips

- Start by running your module on a very short run (`max_ticks = 50L`).
  A 50-tick R↔︎Julia dry run is ~2 s and will surface type errors fast.
- [`print()`](https://rdrr.io/r/base/print.html) inside the module is
  flushed to the R console via the regular Julia `@info` channel — your
  debug prints will appear interleaved with the simulation’s own logs.
- Use [`list_modules()`](../reference/list_modules.md) before a run to
  confirm the expected hooks are registered.

------------------------------------------------------------------------

## 8. Performance

Each custom-module call crosses the Julia↔︎R boundary once per agent
tick. The marshalling cost scales with population size because each
agent’s fields are serialised into R-readable form before your function
runs.

**Concrete benchmark** (documented inline in
[`R/modules.R:19-21`](../R/modules.R#L19)): a 200-agent × 500-tick run
with one `post_tick` custom module adds ~0.5–1 s of overhead compared to
the same run with no modules. For 1,000 agents × 1,000 ticks, overhead
climbs to ~5–10 s. Several registered modules are approximately
additive.

**Guidelines:**

- Keep the function body under ~1 ms per call. Vectorise with `vapply`,
  `sapply`, and `sum`/`mean`/`var` rather than `for` loops over agents.
- Avoid object creation inside the function. Prefer `<<-` on a
  pre-allocated vector over `c(x, new_value)` which reallocates every
  tick.
- Don’t do file I/O inside a module — batch writes to after the run
  completes.
- If you need per-agent computation heavier than a few microseconds per
  agent, you’re likely better off modifying the Julia kernel and
  recompiling, rather than using a custom module. See the
  [kernel-as-biology](k-tick.md) chapters for the hot path.

**Hooks fire even with no modules registered** — but the registry lookup
is trivial and the Julia↔︎R boundary crossing is skipped entirely if
[`list_modules()`](../reference/list_modules.md) is empty.

------------------------------------------------------------------------

## 9. Agent fields reference

The agent records inside `env$agents[[i]]` are named lists mirroring the
`Agent` struct in `inst/julia/src/types.jl`. All fields are readable; a
subset are safely writable (see the notes below the table).

| Field                | Type           | What it is                                                                                |
|----------------------|----------------|-------------------------------------------------------------------------------------------|
| `id`                 | integer        | Unique identifier                                                                         |
| `parent_id`          | integer        | Parent’s id (0 for founders)                                                              |
| `x`, `y`             | integer        | Grid position (1-indexed)                                                                 |
| `age`                | integer        | Ticks since birth                                                                         |
| `t_birth`            | integer        | Tick at which agent was created                                                           |
| `energy`             | numeric        | Current energy (writable)                                                                 |
| `energy_last_tick`   | numeric        | Energy at the end of the previous tick                                                    |
| `alive`              | logical        | `TRUE` for living agents; set `FALSE` to kill (writable)                                  |
| `reproduced`         | logical        | Whether this agent reproduced this tick                                                   |
| `num_offspring`      | integer        | Cumulative offspring count                                                                |
| `body_size`          | numeric        | Expressed trait value                                                                     |
| `metabolic_rate`     | numeric        | Expressed trait value                                                                     |
| `aging_rate`         | numeric        | Expressed trait value                                                                     |
| `cooperation_level`  | numeric        | Expressed trait value                                                                     |
| `dispersal_tendency` | numeric        | Expressed trait value                                                                     |
| `immune_strength`    | numeric        | Expressed trait value                                                                     |
| `mutation_sd`        | numeric        | Per-agent mutation rate (if `mutation_rate_evolution`)                                    |
| `learning_rate`      | numeric        | Per-agent RL step size                                                                    |
| `habitat_preference` | numeric        | Expressed trait value                                                                     |
| `helper_tendency`    | numeric        | Expressed trait value                                                                     |
| `plasticity`         | numeric        | Expressed trait value (0.4.0: now also sets BNN sigma under `bnn_sigma_source = "trait"`) |
| `toxicity`           | numeric        | Expressed trait value                                                                     |
| `wing_size`          | numeric        | Expressed trait value                                                                     |
| `brain_size`         | numeric        | Expressed trait value                                                                     |
| `repro_threshold`    | numeric        | Energy threshold for reproduction                                                         |
| `signal`             | numeric vector | Per-agent mating/warning signal                                                           |
| `care_load`          | integer        | Number of carried offspring                                                               |
| `infected`           | logical        | Disease state (when `disease = TRUE`)                                                     |
| `species_id`         | integer        | Assigned by the speciation module                                                         |

**Writable fields — modify with care:**

- `energy` — changing this is the standard intervention pattern (food
  pulses, costs).
- `alive` — setting `FALSE` removes the agent at the next
  `remove_dead!`.
- `grass[x, y]` — the grass matrix is an R view of the Julia array;
  assigning into it changes the resource landscape.

**Read-only in practice.** Everything else. You can assign to it inside
the R list, but on the next hook the snapshot is rebuilt from the Julia
state so your write is silently discarded. Stick to the three
biologically meaningful mutations above.

------------------------------------------------------------------------

## 10. Interaction with 0.4.0 kernel changes

The hook points themselves are unchanged since 0.3.x, but some of the
fields in `env$agents[[i]]` carry new semantics in 0.4.0:

- `plasticity` now also determines BNN prior width when
  `bnn_sigma_source = "trait"` (see
  [`vignette("k-genome")`](../articles/k-genome.md)).
- `energy` dynamics changed due to handling time (`max_bite`) and
  proportional reproduction costs. If you intervene on energy in a
  `post_tick` module, the baseline consumption from the tick’s eating
  step has already applied, and it respects the new `max_bite`-bounded
  intake.
- Predator agents use the `preference` field as signal-specific memory
  (0.4.0 Tier 4). Don’t repurpose it in modules if predators are active.

No existing custom modules should break, but you may see different
absolute energy numbers in `env$agents[[i]]$energy` at the same tick
compared to pre-0.4.0 runs.

------------------------------------------------------------------------

## See also

- [`?register_module`](../reference/register_module.md),
  [`?list_modules`](../reference/list_modules.md),
  [`?clear_modules`](../reference/clear_modules.md) — full R help.
- [`k-tick`](k-tick.md) — the hot path `tick.jl` with biological
  commentary. Read this before modifying agent behaviour, so you know
  what’s already done in Julia at each hook point.
- [`k-clade-main`](k-clade-main.md) — the main loop orchestration,
  showing where each hook fires relative to built-in modules.
- [`parameter-reference`](parameter-reference.md) — every built-in
  module flag. Check here before writing a custom module; if a flag
  already does the job, use it.
