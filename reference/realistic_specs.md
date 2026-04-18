# Realistic-scale specs for ecologically meaningful audits

Returns
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
scaled up to a larger grid and an explicit predator age structure.
Designed for re-auditing scenarios where the default 30×30 grid is too
small to let genuine spatial dynamics (dispersal gradients,
predator–prey waves, metapopulation structure) express themselves.

## Usage

``` r
realistic_specs()
```

## Value

A specs list calibrated for larger-grid, predator-aware audit runs.

## Details

Built on top of
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
because 2000-tick / 66-generation runs are the longest the BNN kernel
stays stable without trait drift degrading the population. A 5000-tick
scale-up was tested but produced a systematic population decline after t
≈ 1500 across seeds.

All
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
settings are preserved (`max_age = 30`, `min_repro_energy = 60`,
`min_repro_age = 3`, `grass_rate = 0.20`). Additional changes:

- `grid_rows`, `grid_cols`:

  60L × 60L (4× the default area). Enough room for metapopulation
  structure, dispersal gradients, and predator–prey waves.

- `n_agents_init`:

  150L. Right-sized to the post-boom equilibrium on the 60×60 grid; all
  5 tested seeds report `viability_report() = viable`.

- `max_agents`:

  1500L. Supports the transient population peak (~280) before the
  equilibrium sets in.

- `max_ticks`:

  2000L. 66 generations at `max_age = 30`.

- `predator_max_agents`:

  150L. 3× default; room for a predator guild on the larger map.

- `predator_max_age`:

  60L. Predators outlive prey by 2× (owl \> mouse) — biologically
  realistic age structure when predation is engaged.

Typical wall time: 30–60 seconds per run depending on modules; 8 seeds
in parallel on 16–32 PSOCK workers easily fit under the 200-core /
300-GB machine budget.

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md),
[`slow_specs()`](https://itchyshin.github.io/clade/reference/slow_specs.md)
