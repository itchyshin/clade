# Ultra-realistic specs for finite-size-sensitive audits

Returns
[`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md)
scaled up further for scenarios whose theoretical signal is dominated by
finite-population corrections — notably the Red Queen (Otto & Michalakis
1998: advantage scales as ~μN) and Hamilton 1971 selfish herd (risk
dilution scales as ~1/√N). At
[`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md)
equilibrium N ≈ 120, these signals are 5–10× below analytical limits.

## Usage

``` r
ultra_realistic_specs()
```

## Value

A specs list at ecological-theory scale (N ≈ 400 equilibrium, ~80
generations).

## Details

Preserves all
[`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md)
settings except:

- `grid_rows`, `grid_cols`:

  120L × 120L (16× the default area, 4× realistic).

- `n_agents_init`:

  500L. Right-sized to the ~400 equilibrium on the 120×120 grid (an
  earlier audit at 800L overshot and occasionally hit `max_agents`).

- `max_agents`:

  5000L. Supports the larger carrying capacity.

- `max_ticks`:

  2500L. ~80 generations at `max_age = 30`. Longer runs destabilise the
  BNN kernel.

- `predator_max_agents`:

  400L.

Typical wall time: 3–6 minutes per run (15M agent-ticks); 8 seeds in
parallel on 16 PSOCK workers finish in one coffee break. Fits
comfortably under the 200-core / 300-GB machine budget.

## See also

[`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md),
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
