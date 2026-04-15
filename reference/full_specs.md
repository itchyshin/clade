# Full preset specs for publication-quality runs

Returns [`default_specs()`](default_specs.md) with a larger grid, more
agents, and a longer run to allow evolutionary dynamics to stabilise.
Use for final experiments and vignette figures.

## Usage

``` r
full_specs()
```

## Value

A specs list identical to [`default_specs()`](default_specs.md) except:

- `n_agents_init`:

  200L

- `max_ticks`:

  1000L

- `grid_rows`, `grid_cols`:

  30L × 30L

## Details

Typical wall time: ~10–20 minutes per run (Julia warm-up excluded).

## See also

[`default_specs()`](default_specs.md), [`quick_specs()`](quick_specs.md)
