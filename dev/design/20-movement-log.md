# Movement log: opt-in per-tick agent-position logging + post-hoc playback

**Status**: design proposal, not implemented.
**Authored**: 2026-05-16
**Scope**: 1 new spec field + 1 Julia logging path + 1 new R-side
plotting function + 1 vignette section. No changes to existing kernel
behaviour; opt-in only.

## Motivation

The alifeR R-port ancestor offered a per-tick live visualisation of
agent movement — every tick was already in R memory, so a plot was
just a `points()` call. clade made the opposite design choice (cross
the R-Julia boundary once per `run_alife()` call, gain ~50× speed)
and lost that capability.

The right way to bring it back is **not** to re-introduce per-tick
crossings (which would forfeit the speed). Instead: log per-tick
positions *inside Julia* during the run, return them as part of the
env at the end, and replay them *in R* as a scrubbable artefact
post-hoc.

This is arguably better than alifeR's live view: a saved trajectory
is pausable, scrubbable, shareable, and embeddable in a paper
supplement. The trade-off is "movie comes after the run, not during"
— fine for thinking and great for sharing.

## Lab value alignment

- **Accessibility** (one of the four core values): a 30-second movie
  of a clade run is the most accessible form of model output. A
  static dashboard hides emergent spatial structure; a movie reveals
  it.
- **Reproducibility**: the same `run_alife(specs)` call with
  `log_movement = TRUE` produces the same movie. Build it once,
  share the gif, others reproduce by re-running.
- **Differentiator vs ML/stats-focused ABMs**: most evolutionary
  ABMs don't expose post-hoc movies. clade would.

## Architecture

```
R user
  │
  ▼
  specs$log_movement <- TRUE
  env <- run_alife(specs)         ← per-tick positions logged on Julia side
  movie <- plot_run_movie(env)    ← gganimate replay; gif/mp4 output
```

Two new surfaces:

1. **Julia**: one new spec field + one logging function call inside
   `log_tick!`.
2. **R**: one new exported function `plot_run_movie()`.

### Julia side (`inst/julia/src/logging.jl`)

Add the spec key:

```r
# R/config.R::default_specs(), under "Logging" section:
log_movement = FALSE,        # opt-in per-tick agent-position log
log_movement_freq = 1L,      # log every N ticks; 1 = every tick
```

Wire in Julia's `_init_progress` to allocate the movement buffer
when enabled:

```julia
# inst/julia/src/logging.jl::_init_progress
if Bool(get(specs, "log_movement", false))
    d["_movement_log"] = Tuple{Int, Int, Int, Int, Bool, Float64, Int}[]
    # (t, agent_id, x, y, alive, energy, age)
end
```

Add the per-tick logging in `log_tick!`:

```julia
# inst/julia/src/logging.jl::log_tick!
if Bool(get(env.specs, "log_movement", false))
    freq = Int(get(env.specs, "log_movement_freq", 1))
    if (t % freq) == 0
        for ag in env.agents
            push!(env.progress["_movement_log"],
                  (t, ag.id, ag.x, ag.y, ag.alive, ag.energy, ag.age))
        end
    end
end
```

Return path: `env.progress["_movement_log"]` reaches R via the
existing `.julia_env_to_r()` machinery; no new boundary-crossing
code needed.

### R side (`R/visualization.R`)

Two new R-level surfaces:

1. **`get_movement_data(env)`** — extractor (parallel to
   `get_run_data()`). Returns a tidy `data.frame` with columns
   `t`, `agent_id`, `x`, `y`, `alive`, `energy`, `age`.

2. **`plot_run_movie(env, colour_by = "energy", fps = 10)`** — the
   gif producer. Wraps `gganimate::transition_states()` over the
   tick dimension. Returns the `gganim` object (the user calls
   `animate()` or `anim_save()` to render).

`gganimate` and its backend (`magick` or `gifski`) go in **Suggests**
(not Imports) — most clade users don't need them. The function
errors with an informative message if Suggests aren't installed.

### Wall-clock + storage cost

Storage per run, conservative upper bound: 8 bytes × 7 columns ×
~100 avg agents × 2000 ticks = 11.2 MB per run. For long runs
(15 000 ticks at 200 agents) it grows to ~170 MB — `log_movement_freq`
lets users dial down to e.g. every 10 ticks (~17 MB).

Compute overhead: in Julia, the push is O(N_alive) per logged tick.
At ~100 agents × 2000 ticks that's ~200 000 tuple pushes — well
below the per-tick cost of the actual simulation step. Estimated
overhead: < 5 % wall time when `log_movement_freq = 1`.

### Default OFF

`log_movement = FALSE` by default. All existing behaviour preserved.
Existing tests don't change; existing vignettes don't change.

## Why this design and not alternatives

| Alternative | Why not chosen |
|---|---|
| Per-tick R-Julia crossings (alifeR-style) | forfeits clade's 50× speed advantage |
| Stream positions to disk during run | adds I/O on the Julia side, complicates resumability, doesn't compose with `batch_alife()`'s in-memory return |
| Interactive HTML via Shiny / observable / plotly | useful but heavier dependency (Shiny is `Suggests` too but more involved); a gif is shareable in Slack/Twitter/etc. without a server. Worth a follow-up `plot_run_dashboard()` later. |
| Always-on movement log | wastes 11 MB+ on every run, including the millions of single-seed exploratory runs that don't care |
| Subsample to every Nth agent | loses spatial completeness; user might miss the lone explorer that founds a new patch |

## Connection to v0.8-core

This is a **post-Sergio's-merge** task. The Julia changes touch
`inst/julia/src/logging.jl`, which is Sergio's territory. Doing this
now would conflict with v0.8-core. Defer until his branch settles,
then add as a small standalone PR.

## Connection to the Wolf 2007 saga

Phase B (specifically PRs #138-#142) found that the Wolf 2007
personality syndrome does not robustly emerge at 8 seeds × 5000 ticks
in clade's current kernel. **A movie of one of these runs would help
diagnose the gap.** If the spatial pairing structure is breaking the
mean-field signal (as one of the three explanations in
`paper-wolf2007.Rmd`'s Multi-seed section suggests), a movie of agent
clustering / dispersal would make it visible. That's an extra
reason to ship the feature once v0.8-core lands.

## Out of scope (separate proposals)

- **Interactive scrubbing** (Shiny + plotly): separate
  `plot_run_dashboard()` proposal. Different dependency footprint.
- **Logging additional per-tick agent fields** (full genome, full
  brain weights): out of scope here; users who need them already
  have `log_genomes = TRUE`.
- **Movie of `env$grass`**: separate proposal. Movement log is just
  agents; environment dynamics are a different visualisation.

## Cost summary

- **Design**: this doc.
- **Implementation**: ~50 lines Julia + ~80 lines R + 1 test file +
  1 vignette section. Estimated 2–3 hours of focused work.
- **Recurring cost**: ~5 % wall-time overhead when enabled; 11+ MB
  per run stored in memory; opt-in so unaffected users pay nothing.
- **CRAN concern**: gganimate is on CRAN; magick + gifski are on
  CRAN. All in `Suggests`, not `Imports`. R CMD check unaffected
  for users without Suggests installed.

## Recommended next step

Wait for Sergio's v0.8-core merge. Then:

1. New PR: Julia-side wiring (`logging.jl` + `default_specs()` two
   new fields).
2. New PR: R-side `get_movement_data()` + `plot_run_movie()`.
3. New PR: `vignettes/basics.Rmd` adds a movement-log paragraph in
   section 5 ("What next?"). One sentence in
   `vignette("getting-started")` too.

Splitting into three PRs keeps each surgical (Karpathy 3). Estimated
1–2 weeks calendar time after v0.8-core merge.

## Open questions

- **Storage format**: in-memory R data.frame (proposed) vs serialised
  rds saved alongside env. Default proposal is in-memory for
  composability with `batch_alife()`; users who need persistence can
  `saveRDS(env$movement_log, ...)` themselves.
- **gganimate as Suggests vs Imports**: proposed as Suggests
  (consistent with how the package treats e.g. JuliaConnectoR — soft
  rather than hard dep). Re-evaluate if the feature becomes
  central enough to clade's identity that we want it always
  available.
- **`log_movement_freq` API shape**: integer divisor (every Nth
  tick) is the simplest. Alternative: time-window (only ticks
  `[start, end]`) for users who want to focus on a specific phase.
  Defer time-window to a v2 if anyone asks; integer-divisor handles
  the common case.
