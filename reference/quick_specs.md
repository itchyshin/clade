# Quick preset specs for fast exploratory runs

Returns
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
with a smaller grid, fewer agents, and shorter run length. Use for rapid
prototyping and parameter sweeps where exact biological accuracy is less
important than turnaround time.

## Usage

``` r
quick_specs()
```

## Value

A specs list identical to
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
except:

- `n_agents_init`:

  50L

- `max_ticks`:

  200L

- `grid_rows`, `grid_cols`:

  20L × 20L

## Details

Typical wall time: ~30 seconds per run (Julia warm-up excluded).

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`full_specs()`](https://itchyshin.github.io/clade/reference/full_specs.md)
