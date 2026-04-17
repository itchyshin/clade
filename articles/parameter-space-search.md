# Parameter-space search at scale (parallel, resumable, streaming)

## Why this article exists

clade is an agent-based simulation. Interesting science usually requires
varying a parameter, varying *several* parameters, or doing evolutionary
search in the joint parameter space — and doing it at sufficient scale
that the result distribution is informative, not just a handful of runs.

This article is the practical guide to running **tens of thousands or
millions of
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
scenarios** across CPU cores without running out of memory, deadlocking
the Julia backend, or losing state when a job dies overnight. Every
helper it introduces is exported from the `clade` R package as of 0.5.6.

The four problems this article solves:

1.  **Generating parameter combinations** — grids, random draws, or
    user-supplied distributions.
2.  **Running them in parallel** — across R worker processes, each with
    its own Julia session (the non-deadlocking path).
3.  **Streaming results to disk** — so 1 M runs doesn’t mean 1 M copies
    of `env$progress` in RAM.
4.  **Resuming a killed job** — so a crash at run 800 k of 1 M isn’t
    fatal.

## Important fix: parallelism at `n_cores > 1` was silently broken

Before 0.5.6, `batch_alife(specs_list, n_cores = N > 1)` used
[`parallel::mclapply`](https://rdrr.io/r/parallel/mclapply.html), which
forks the R process. The forked R children inherited the parent’s
`JuliaConnectoR` socket but couldn’t safely multiplex it — in practice,
all workers and the Julia server went idle and the batch hung forever.

**0.5.6 fixes this** by swapping to `parallel::makeCluster("PSOCK")` —
separate R processes, each with its own Julia session, no shared socket.
If you were running parallel sweeps before and getting mysterious hangs
or single-core speeds, this is why; update to 0.5.6+ and it will
parallelise.

Cost to know about: each PSOCK worker boots its own Julia session on
first call, which is a ~60 s compile hit. For small batches (\< 20
scenarios) serial is faster; for 50+ scenarios the parallel speedup is
near-linear. See `dev/docs/parallelism-audit.md` for the full
post-mortem.

## Step 1 — Build a list of specs

You have three building blocks.

### `grid_specs()` — factorial exploration

Systematic coverage of a small number of parameters:

``` r
library(clade)

specs_list <- grid_specs(fast_specs(),
                         grass_rate  = c(0.1, 0.2, 0.3),
                         mutation_sd = c(0.02, 0.05))
length(specs_list)  # 3 × 2 = 6
```

Each element is a full specs list inheriting from the `base` argument
(here
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md))
with one parameter combination substituted. Names encode the cell:
`"grass_rate=0.1;mutation_sd=0.02"`.

### `sample_specs()` — random draws

For stochastic search over continuous or mixed parameter spaces:

``` r
specs_list <- sample_specs(
  fast_specs(),
  n                    = 1000L,
  grass_rate           = list(0.05, 0.45),           # uniform [lo, hi]
  mutation_sd          = c(0.05, 0.1, 0.2),          # sample w/ replacement
  plasticity_init_mean = function(n) rbeta(n, 2, 2), # user function
  cooperation_evolution = c(TRUE, FALSE),
  seed                 = 2026L                        # reproducible draw
)
```

Three distribution forms per parameter, mix freely:

- **Vector**: sampled with replacement (`c(0.1, 0.2, 0.3)`)
- **Range**: `list(min, max)` → `runif` on that interval
- **Function**: `function(n)` → your function returning `n` values

Each resulting specs inherits from the `base` argument and has its own
`random_seed` so the runs are reproducible.

### Hand-built lists

Nothing stops you from writing
[`lapply()`](https://rdrr.io/r/base/lapply.html) yourself. The helpers
are conveniences, not mandates.

## Step 2 — Run them in parallel

Two entry points, both using the new PSOCK parallel path.

### `batch_alife(specs_list, n_cores)` — run and collect all results

Appropriate when the full result objects fit in RAM (maybe 50 to 1000
runs depending on how much you log):

``` r
# 50 scenarios × 50 cores (one per scenario, 1:1)
results <- batch_alife(specs_list[1:50], n_cores = 50L)

# Pull out summary rows into a tidy data frame
tbl <- summarize_batch(results, specs_list[1:50],
                       param_names = c("grass_rate", "mutation_sd"))
# tbl: 50 rows × (parameters + metrics + viability)
```

[`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)
extracts per-run metrics — population at the end, mean energy, genetic
diversity, viability verdict — plus the parameters you specified.
Override the `metrics` argument to log custom statistics.

### `stream_specs_to_csv()` — stream results to disk

Appropriate when the full result objects would not fit in RAM (10 k to 1
M runs) or when you want to survive a crash:

``` r
stream_specs_to_csv(
  specs_list,
  out_path   = "/data/sweeps/grass_mutation_sweep.csv",
  n_cores    = 50L,
  resume     = TRUE   # default
)

# Reads back as a regular CSV
tbl <- read.csv("/data/sweeps/grass_mutation_sweep.csv")
```

Flow per run: call
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
call the `summary_fn` (default writes varied parameters + `n_final` +
`mean_energy_final` + `diversity_final` + viability), append one CSV
row, **discard the env object**. 1 M runs stays in a few hundred MB of
RAM.

**Resumability**: `resume = TRUE` checks the CSV on disk for existing
`run_id` values and skips those. Each run in a named `specs_list` gets
its list-name as the `run_id`; otherwise it gets `run_000001`,
`run_000002`, etc. So a crashed-and-restarted overnight job just runs
`stream_specs_to_csv(...)` with the same `out_path` and picks up where
it left off.

**Custom summary function**:

``` r
stream_specs_to_csv(specs_list, "/data/custom.csv", n_cores = 50L,
  summary_fn = function(env, specs) {
    d <- get_run_data(env)$ticks
    list(
      cycling_amplitude = diff(range(d$n_agents)),
      final_mean_age    = tail(d$mean_age, 1L),
      n_starvations    = sum(d$n_starvations)
    )
  })
```

## Step 3 — CMA-ES and MAP-Elites

For search-driven parameter exploration (gradient-free optimisation or
quality-diversity search) use the built-in adaptive algorithms:

``` r
# CMA-ES: minimise a user-defined loss over the parameter space
res_cma <- search_cmaes(
  base_specs = fast_specs(),
  params     = list(grass_rate = c(0.05, 0.45),
                    mutation_sd = c(0.02, 0.2)),
  fitness_fn = function(env) -tail(env$progress$n_agents, 1L),
  n_gens     = 20L,
  pop_size   = 20L,
  n_cores    = 20L
)

# MAP-Elites: quality-diversity search
res_me <- search_map_elites(
  base_specs = fast_specs(),
  params     = list(grass_rate = c(0.05, 0.45),
                    predator_energy_gain = c(10, 60)),
  descriptors = c("grass_rate", "predator_energy_gain"),
  fitness_fn = function(env) tail(env$progress$mean_energy, 1L),
  archive_res = c(10L, 10L),
  n_evals    = 1000L,
  n_cores    = 20L
)
```

Both algorithms use the PSOCK path internally in 0.5.6+.

**Checkpoint/resume for long MAP-Elites runs** (new in 0.5.6): pass
`checkpoint_path` and the current archive + history + iteration index
are saved as an RDS every `checkpoint_every` iterations (and once more
at the end). If the process dies, re-running the *same call* picks up
from the saved iteration:

``` r
res_me <- search_map_elites(
  base_specs       = fast_specs(),
  archive_dims     = list(mean_energy = seq(40, 120, length.out = 10L),
                          genetic_diversity = seq(0.1, 1, length.out = 10L)),
  n_iterations     = 100000L,
  mutation_sd      = 0.2,
  n_cores          = 20L,
  checkpoint_path  = "/scratch/me_archive.rds",
  checkpoint_every = 500L
)
# If this dies at iter 73,421, just run the same call again — it
# resumes at 73,421 + 1 and runs to 100,000.
```

The checkpoint RDS is also useful mid-run for exploratory analysis — you
can [`readRDS()`](https://rdrr.io/r/base/readRDS.html) the file from
another R session and plot the current archive without interrupting the
search.

## How big can I go on one machine?

Rough numbers (assumes
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
500-tick probe ≈ 5 s/run):

| Scale      | Wall clock on 50 cores | Disk (CSV summary) |
|------------|------------------------|--------------------|
| 100 runs   | 65 s                   | ~10 KB             |
| 10 k runs  | 15 min                 | ~1 MB              |
| 100 k runs | 2.5 h                  | ~10 MB             |
| 1 M runs   | 24 h                   | ~100 MB            |

The `n_cores` cap on this machine is 200 (see `CLAUDE.md`). Beyond ~1 M
runs per machine-day you want a cluster.

## How big can I go on a cluster?

[`submit_sweep_slurm()`](https://itchyshin.github.io/clade/reference/submit_sweep_slurm.md)
(new in 0.5.6) writes a SLURM array-job template for you. It does not
submit — you run `sbatch` yourself — but it handles the mechanical
parts: splitting `specs_list` into chunks, writing a per-task R script
that reads `SLURM_ARRAY_TASK_ID` and processes the right slice, and
pointing every task at the same resume-safe CSV.

``` r
specs_list <- sample_specs(fast_specs(), n = 100000L,
                           grass_rate  = list(0.05, 0.45),
                           mutation_sd = c(0.05, 0.1, 0.2))

submit_sweep_slurm(
  specs_list,
  out_path         = "/shared/sweeps/big_sweep.csv",
  script_path      = "/shared/sweeps/submit.sh",
  rds_path         = "/shared/sweeps/specs.rds",
  n_array_tasks    = 200L,
  n_cores_per_task = 8L,
  time             = "12:00:00",
  mem              = "16G"
)
# prints:  sbatch /shared/sweeps/submit.sh
```

Each array task:

1.  Reads the task index from `SLURM_ARRAY_TASK_ID`.
2.  Loads its slice of `specs_list` from the shared RDS.
3.  Runs
    [`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md)
    on that slice at `n_cores_per_task` cores with `resume = TRUE`.

Resume-safe CSV + chunked specs means preempted or stalled tasks can be
re-run without re-processing completed specs. For a 100 k-run sweep
split 200 ways, each task processes 500 specs — at 5 s/run × 8 cores =
~5 min per task if everything goes right, so even a 10-minute SLURM slot
per task with a re-queue is tolerant.

Not currently wired: `future.batchtools` (alternative backend
abstraction) and a `clustermq` adapter. Open an issue if you’d rather
use those.

## Viability guard

[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
now attaches an `env$viability` report to every run and `warn()`s if the
population crashed. When streaming thousands of runs, crashed runs still
produce a summary row (with `viability = "crashed"`) — you can filter or
re-run them afterwards:

``` r
tbl <- read.csv("/data/sweeps/big_sweep.csv")
table(tbl$viability)
#>  viable  weak  crashed
#>   78341 15822     5837

# Re-run only the crashed cases at a tamer parameter regime:
to_rerun <- as.character(tbl$run_id[tbl$viability == "crashed"])
retry_specs <- specs_list[to_rerun]
for (i in seq_along(retry_specs))
  retry_specs[[i]]$grass_rate <- retry_specs[[i]]$grass_rate * 1.3
stream_specs_to_csv(retry_specs, "/data/sweeps/big_sweep_retry.csv",
                    n_cores = 50L, resume = TRUE)
```

## Worked example: brain-type benchmark

The `dev/benchmarks/brain_comparison.R` script in the repo is a compact,
reproducible end-to-end use of the tooling. It runs
`5 brain types × 5 seeds = 25` independent clade simulations in parallel
and produces a faceted comparison figure. The full code:

``` r
library(clade)
library(ggplot2); library(patchwork)

BRAIN_TYPES <- c("bnn", "ann", "ctrnn", "grn", "random")
SEEDS       <- c(1L, 7L, 13L, 19L, 25L)

base <- default_specs()
base$grid_rows     <- 30L; base$grid_cols <- 30L
base$n_agents_init <- 80L; base$max_agents <- 400L
base$grass_rate    <- 0.15
base$max_ticks     <- 500L

specs_list <- grid_specs(base,
                         brain_type  = BRAIN_TYPES,
                         random_seed = SEEDS)
# 25 PSOCK workers, each with its own Julia; Julia compile
# happens in parallel so wall clock is ~60 s startup + run time.
results <- batch_alife(specs_list, n_cores = length(specs_list))

# Pull out summary + full trajectories
tbl <- summarize_batch(results, specs_list,
                       param_names = c("brain_type", "random_seed"))
traj <- do.call(rbind, Map(function(env, specs) {
  d <- get_run_data(env)$ticks
  d$brain_type <- specs$brain_type
  d$seed       <- specs$random_seed
  d[, c("t", "n_agents", "mean_energy", "brain_type", "seed")]
}, results, specs_list))
```

See
[`vignette("s-brain-comparison")`](https://itchyshin.github.io/clade/articles/s-brain-comparison.md)
for the full analysis + the saved figure. Takeaways that map cleanly to
canonical life-history theory:

- BNN → **density strategy** (196 agents × 125 energy)
- GRN → **quality strategy** (56 agents × 170 energy)
- ANN / CTRNN intermediate; random is the most fragile

## Summary

| Task                    | Function                                                                                      | Scale                                                                              |
|-------------------------|-----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| Make specs (systematic) | [`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md)                   | any                                                                                |
| Make specs (random)     | [`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md)               | any                                                                                |
| Run + collect in RAM    | [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)                 | ≤ few k runs                                                                       |
| Run + stream to disk    | [`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md) | unlimited                                                                          |
| Summarize to tibble     | [`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)         | from [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md) |
| Search (CMA-ES)         | [`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)               | any                                                                                |
| Search (MAP-Elites)     | [`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)     | any                                                                                |
| Dispatch to SLURM       | [`submit_sweep_slurm()`](https://itchyshin.github.io/clade/reference/submit_sweep_slurm.md)   | multi-node                                                                         |

All of these use the PSOCK parallel path; pass `n_cores = N` to fan out
across `N` separate R+Julia worker processes on one machine.
