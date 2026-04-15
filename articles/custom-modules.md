# Custom Modules: Extending clade with Per-Tick Hooks

`clade` provides a module registry that lets you attach arbitrary R
functions to the simulation tick loop. Modules receive a snapshot of the
current environment at each tick, can read any field, and can modify
agent state before returning the snapshot for further processing.

This is the primary extension point for:

- **Custom logging** — record any quantity not tracked by the built-in
  progress columns.
- **Experimental interventions** — perturb the environment (inject
  energy, kill agents, add food patches) at specific ticks.
- **Post-hoc analysis** — accumulate per-tick statistics in an R object
  in the calling environment.

------------------------------------------------------------------------

## 1. The module API

``` r
register_module(fn, when = "post_tick", name = NULL)
list_modules()
clear_modules()
```

| Argument | Type                     | Description                                                                             |
|----------|--------------------------|-----------------------------------------------------------------------------------------|
| `fn`     | `function(snap) -> snap` | Hook function. Receives the current environment snapshot, returns it (modified or not). |
| `when`   | character                | Hook point. Currently `"post_tick"` is supported.                                       |
| `name`   | character or NULL        | Optional name for the module.                                                           |

The hook function receives a *snapshot* — a list with the same structure
as the `env` object returned by
[`run_alife()`](../reference/run_alife.md):

| `snap` field    | Contents                                 |
|-----------------|------------------------------------------|
| `snap$agents`   | List of agent lists (one per live agent) |
| `snap$t`        | Current tick number                      |
| `snap$specs`    | The simulation specs                     |
| `snap$grass`    | Grass coverage matrix                    |
| `snap$progress` | Accumulated progress data so far         |

------------------------------------------------------------------------

## 2. Example 1 — Tracking a custom statistic

Record the number of agents in the top energy quartile at every tick.

``` r
library(clade)

top_quartile_counts <- integer(0)

register_module(
  function(snap) {
    energies <- vapply(snap$agents, function(ag) ag$energy, numeric(1L))
    q75      <- quantile(energies, 0.75)
    # <<- writes into the parent environment (outside the hook)
    top_quartile_counts <<- c(top_quartile_counts, sum(energies >= q75))
    snap   # always return snap unchanged (or modified)
  },
  when = "post_tick",
  name = "top_quartile_tracker"
)

s <- default_specs()
s$max_ticks <- 100L
env <- run_alife(s)
clear_modules()   # always clear after the run

cat(sprintf("Mean top-quartile size: %.1f over %d ticks\n",
            mean(top_quartile_counts), length(top_quartile_counts)))

plot(top_quartile_counts, type = "l",
     xlab = "Tick", ylab = "Agents in top energy quartile")
```

The `<<-` super-assignment operator reaches into the calling environment
so that `top_quartile_counts` is updated outside the hook closure.

------------------------------------------------------------------------

## 3. Example 2 — Logging agent spatial spread

Record the spatial variance of agent positions as a proxy for population
dispersal each tick.

``` r
spread_log <- numeric(0)

register_module(
  function(snap) {
    if (length(snap$agents) == 0L) {
      spread_log <<- c(spread_log, NA_real_)
      return(snap)
    }
    xs <- vapply(snap$agents, function(ag) ag$x, numeric(1L))
    ys <- vapply(snap$agents, function(ag) ag$y, numeric(1L))
    # Toroidal variance: use circular formula for modular coordinates
    spread <- var(xs) + var(ys)
    spread_log <<- c(spread_log, spread)
    snap
  },
  when = "post_tick",
  name = "spatial_spread"
)

s <- default_specs()
s$dispersal_evolution <- TRUE
s$max_ticks           <- 200L
env <- run_alife(s)
clear_modules()

plot(spread_log, type = "l", xlab = "Tick",
     ylab = "Spatial variance (x + y)",
     main = "Population spatial spread over time")
```

------------------------------------------------------------------------

## 4. Example 3 — Experimental energy injection

Add 10 units of energy to all agents at tick 100, simulating a sudden
resource pulse.

``` r
register_module(
  function(snap) {
    if (snap$t == 100L) {
      snap$agents <- lapply(snap$agents, function(ag) {
        ag$energy <- ag$energy + 10.0
        ag
      })
      message("[module] Energy pulse applied at tick ", snap$t)
    }
    snap
  },
  when = "post_tick",
  name = "energy_pulse_t100"
)

s <- default_specs()
s$max_ticks <- 200L
env <- run_alife(s)
clear_modules()

# The energy spike should be visible in env$progress at tick 100
data <- get_run_data(env)
plot(data$ticks$t, data$ticks$mean_energy, type = "l",
     xlab = "Tick", ylab = "Mean energy",
     main = "Energy pulse at tick 100")
abline(v = 100, col = "red", lty = 2)
```

------------------------------------------------------------------------

## 5. Running multiple modules

Multiple modules can be registered and will run in registration order:

``` r
counts_a <- integer(0)
counts_b <- numeric(0)

register_module(
  function(snap) {
    counts_a <<- c(counts_a, length(snap$agents))
    snap
  },
  name = "pop_counter"
)

register_module(
  function(snap) {
    energies <- vapply(snap$agents, function(ag) ag$energy, numeric(1L))
    counts_b <<- c(counts_b, mean(energies))
    snap
  },
  name = "energy_tracker"
)

cat("Registered modules:\n")
print(list_modules())   # shows name and when for each module

s <- default_specs()
s$max_ticks <- 50L
env <- run_alife(s)
clear_modules()
```

------------------------------------------------------------------------

## 6. Best practices

**Always call [`clear_modules()`](../reference/clear_modules.md) after
each run.** Registered modules persist across calls to
[`run_alife()`](../reference/run_alife.md) within the same R session.
Forgetting to clear them causes modules to accumulate and run on
subsequent simulations unexpectedly.

``` r
# Safe pattern: register, run, clear
register_module(my_hook, name = "my_hook")
env <- run_alife(specs)
clear_modules()   # <- never skip this
```

**Keep hooks fast.** Modules run at every tick. If your hook is slow
(e.g. writes to disk, does a complex computation), it can dominate total
runtime. Profile with a short run before using long simulations.

**Use `<<-` for accumulation.** Because hooks are closures, use `<<-`
(or `assign(..., envir = parent.env())`) to write results into a
container defined outside the hook.

**Return `snap` unmodified if you only want to observe.** The hook must
always return `snap`. If you are only logging, return it unchanged. If
you modify `snap$agents`, the changes propagate to subsequent modules
and to the simulation state.

**Module execution order.** Modules run in the order they were
registered. If module B depends on state set by module A, register A
first.

------------------------------------------------------------------------

## 7. Hook points

| `when`        | When it runs                                                    |
|---------------|-----------------------------------------------------------------|
| `"post_tick"` | After all agent actions, deaths, and reproduction for the tick. |

Additional hook points (`"pre_tick"`, `"post_reproduction"`) are planned
for future releases. Watch the changelog.

------------------------------------------------------------------------

## 8. Accessing agent fields

Each element of `snap$agents` is a named list. Common fields:

| Field                 | Type    | Description                                 |
|-----------------------|---------|---------------------------------------------|
| `$id`                 | integer | Unique agent ID                             |
| `$x`, `$y`            | integer | Grid position (1-indexed)                   |
| `$energy`             | numeric | Current energy                              |
| `$age`                | integer | Age in ticks                                |
| `$alive`              | logical | Always TRUE at post_tick (dead removed)     |
| `$num_offspring`      | integer | Lifetime offspring count                    |
| `$body_size`          | numeric | Body size (1.0 if evolution disabled)       |
| `$dispersal_tendency` | numeric | Dispersal probability (0 if disabled)       |
| `$wing_size`          | numeric | Wing size (0 if complex_landscape disabled) |
| `$helper_tendency`    | numeric | Helper tendency (0 if module disabled)      |
| `$toxicity`           | numeric | Toxicity level (0 if mimicry disabled)      |
| `$infected`           | logical | SIR infection status                        |
| `$immune`             | logical | SIR immunity status                         |

Fields for disabled modules are present but have their zero/FALSE
default. Check `snap$specs$<module_flag>` to determine which modules are
active.
