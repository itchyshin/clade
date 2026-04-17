# Parallelism audit — `batch_alife(n_cores > 1)` silently deadlocks

*2026-04-17. Discovered while running a 50-core POC for the user's
parameter-space-exploration workflow.*

## Summary

The current `batch_alife(specs_list, n_cores = N)` API calls
`parallel::mclapply(..., mc.cores = N)` on Unix/macOS. `mclapply`
forks the R process, producing N child workers that inherit the
parent's memory (including file descriptors). The child R workers
then each call `JuliaConnectoR::juliaCall()`.

**The problem**: `JuliaConnectoR` maintains a single Julia server
process with a single socket. When forked R workers all try to send
requests concurrently, they all block on the same socket lock.
Observed behaviour at 50 forked workers: **all R workers idle at 0%
CPU, the Julia process idle at 0% CPU, no progress for > 10 minutes**.
The batch hangs indefinitely.

This is a known fork-unsafe pattern for RPC-based R-to-language
bridges. It is silently broken rather than noisily broken, which is
worse — audit scripts that use `n_cores = 8` have been silently
serialising or hanging this whole time.

## Scope of the bug

Affected entry points:

- `batch_alife(specs_list, n_cores = N)` — directly calls `mclapply`
- `batch_seeds(specs, seeds, n_cores = N)` — wrapper over `batch_alife`
- `search_cmaes(..., n_cores = N)` — uses `mclapply` for population eval
- `search_map_elites(..., n_cores = N)` — uses `mclapply` for candidate eval

All currently effectively single-core.

Running a `n_cores = 1` batch works fine — this bug is specifically
about the parallel path.

## Why this compounds with the architecture

The root cause is the mismatch between R's fork() model and
JuliaConnectoR's client/server singleton model. You cannot safely
share a Julia socket between forked R children. The fix is to
**avoid fork entirely** and use process-level workers, each of which
starts its own Julia session.

## Fix options

### A. Swap `mclapply` for `parallel::makeCluster("PSOCK")`

PSOCK workers are separate R processes launched via `Rscript`, not
forks. Each worker starts its own Julia (~60s compile cost per
worker, once). After that, each worker runs scenarios independently
of all others — true parallelism.

**Cost analysis**: for a 1000-scenario sweep with 50 workers:

- Julia startup: 50 × 60s ≈ 50 min of compile (workers boot in
  parallel, so wall-clock is ~60s)
- Per-scenario cost: 5s × (1000 / 50) = 100s per worker
- Total wall-clock: ≈ 160s (vs 5000s serial)
- **30× speedup** even with the Julia-startup tax

For smaller batches (< 50 scenarios), the startup tax dominates and
serial is faster. Breakeven is around 20 scenarios × 5s each = 100s
run time per worker, which exceeds the 60s Julia startup cost.

### B. Use `callr::r_bg()` for async workers

Launches a fresh R process for each worker. More ergonomic than
`makeCluster` for small worker counts; higher per-worker overhead
(full package load each call). Works for the same cost class as A
but with a different API.

### C. Cluster scheduler (SLURM / PBS array jobs)

For real "millions of scenarios" scale. Each scenario (or batch of
scenarios) becomes a SLURM job; the scheduler fans out across the
cluster. Requires `future.batchtools` or `rslurm` integration — not
currently in `clade`.

### D. Julia-side parallelism (Threads.@threads)

Keep one R process, one Julia session; parallelise _within_ Julia
using `Threads.@threads`. Useful for large single-run scenarios (e.g.
MAP-Elites with many candidates per step) but doesn't help with the
"50 independent simulations" use case unless Julia is started with
`JULIA_NUM_THREADS=N` and clade's kernel is thread-safe.

Current clade kernel is NOT thread-safe for this — each run uses
its own RNG state, but the `env` struct is not designed for
concurrent access.

## Recommended path

1. **Replace `mclapply` with `makeCluster("PSOCK")`** in the four
   affected functions. Keep the `n_cores` API unchanged; users
   opt-in to the new behaviour transparently.
2. **Document the Julia-startup tax** so users set `n_cores`
   sensibly for batch size.
3. **Add a cluster adapter** (option C) as a follow-up when someone
   has a SLURM target to test against.

## How to reproduce the deadlock

```r
specs_list <- lapply(1:50, function(i) {
  s <- fast_specs()
  s$random_seed <- i
  s$max_ticks   <- 300L
  s
})
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 50L)
# ... never returns
```

Compared to single-core serial:

```r
results <- batch_alife(specs_list, n_cores = 1L)
# ... returns in ~250s
```

## Consequences for prior audits

Any historical claim of the form *"N-seed audit × M cores"* where
M > 1 was likely running single-threaded (or hanging). Good news:
audit results themselves don't depend on the execution strategy
— the runs are deterministic given the seed. The cost was wall-clock
time, not correctness. But future sweeps should use a working
parallelism path.

## Status as of this doc

- Fix: not yet landed. POC (`/tmp/poc_parallel_v2.R`) validated the
  PSOCK approach on 4 workers; productionisation is a follow-up PR.
- Docs: this file is the record. Users running `n_cores > 1` should
  be warned until the fix lands.
