# clade: Agent-Based Evolutionary Simulation with Julia Backend

`clade` provides agent-based simulations of evolution, foraging ecology,
and social behaviour. The R layer is an interface; the per-tick
simulation kernel runs in Julia via
[JuliaConnectoR](https://rdrr.io/pkg/JuliaConnectoR/man/juliaEval.html),
so the R↔Julia boundary is crossed exactly once per
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
call.

## Details

### Getting started

    specs <- default_specs()
    specs$n_agents_init <- 40L
    specs$max_ticks     <- 300L
    env  <- run_alife(specs)
    data <- get_run_data(env)
    plot_run(data)

First call to
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
precompiles the Julia kernel (~60–90 s, once per Julia session).

### Key entry points

- [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
  — canonical parameter list; modify and pass to
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

- [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
  /
  [`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md)
  — run a single simulation.

- [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
  — run many specs lists (parallel via
  [parallel::mclapply](https://rdrr.io/r/parallel/mclapply.html)).

- [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  — extract `$ticks` and `$deaths` data frames from an env.

- [`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md)
  — population / energy / diversity dashboard.

- [`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
  /
  [`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)
  /
  [`search_gradient()`](https://itchyshin.github.io/clade/reference/search_gradient.md)
  — parameter search driven by a user-supplied fitness function.

- [`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
  /
  [`hypothesis_report()`](https://itchyshin.github.io/clade/reference/hypothesis_report.md)
  — researcher- facing wrappers for the sweep-\>test-\>report workflow.

### Biological modules

All modules are disabled by default and enabled with a single flag in
the specs list. See the `README.md` module table and
[vignettes/parameter-reference.Rmd](https://itchyshin.github.io/clade/doc/parameter-reference.md)
for the full list with defaults and expected effects.

### Brain architectures

Set `specs$brain_type`:

- `"bnn"` (default) — Bayesian neural network with Thompson-sampled
  weights and REINFORCE posterior updates (Williams 1992; Blundell et
  al. 2015).

- `"ann"` — standard multilayer perceptron.

- `"ctrnn"` — continuous-time recurrent network (Beer 1995).

- `"grn"` — sparse gene-regulatory network topology.

- `"random"` — null-baseline architecture for sanity checks.

Two further names are reserved for future implementation and currently
error if requested: `"transformer"` (self-attention) and `"synthesis"`
(symbolic rule extraction from evolved weights).

### Citation

Nakagawa, S. (2026). clade: Agent-based evolutionary simulation with a
Julia backend. R package version 0.7.0.
<https://github.com/itchyshin/clade>

## See also

Useful links:

- <https://itchyshin.github.io/clade/>

- <https://github.com/itchyshin/clade>

- Report bugs at <https://github.com/itchyshin/clade/issues>

## Author

**Maintainer**: Shinichi Nakagawa <s.nakagawa@unsw.edu.au>

Authors:

- Shinichi Nakagawa <s.nakagawa@unsw.edu.au>
