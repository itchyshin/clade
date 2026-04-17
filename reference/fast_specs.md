# Fast-generation specs for evolutionary scenarios

Returns
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
calibrated for **fast generational turnover** — 66 generations in 2000
ticks (vs ~2.6 at defaults). Use this preset whenever the scenario tests
a prediction about **trait evolution across generations** (plasticity,
Baldwin effect, mimicry, mating systems, dispersal evolution, etc.).

## Usage

``` r
fast_specs()
```

## Value

A specs list calibrated for fast evolutionary dynamics.

## Details

The timescale calibration is based on the MATLAB ancestor's parameters
(Bulitko 2023), which ran ~40x faster generations than clade's defaults
because agents started at reproduction energy with short
`minReproductionAge`. See `dev/docs/timescale-analysis.md` for the full
analysis.

Key changes from
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md):

- `max_age`:

  30L (vs 200L). Short lifespan forces generational turnover at a
  biologically realistic rate for a small organism (e.g., Drosophila,
  small rodent).

- `min_repro_energy`:

  60 (vs 120). Lower threshold means agents breed after ~10 ticks of
  foraging, not ~100.

- `min_repro_age`:

  3L (vs 0L). Minimum maturation age prevents
  newborn-immediately-reproducing artefacts.

- `grass_rate`:

  0.20 (vs 0.05). Adequate food to sustain a viable population of ~65
  agents with fast turnover.

- `max_ticks`:

  2000L. At gen time ~30 ticks, this gives ~66 generations — adequate
  for most evolutionary predictions.

- `n_agents_init`:

  80L. Moderate starting population.

- `max_agents`:

  400L. Room for population growth.

- `grid_rows`, `grid_cols`:

  30L. Standard grid.

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`slow_specs()`](https://itchyshin.github.io/clade/reference/slow_specs.md),
[`quick_specs()`](https://itchyshin.github.io/clade/reference/quick_specs.md)
