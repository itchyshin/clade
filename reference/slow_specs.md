# Slow-generation specs for long-lived organism scenarios

Returns [`default_specs()`](default_specs.md) calibrated for
**long-lived organisms** (elephant, whale, large primate). Generation
time ~50 ticks; requires longer runs (10000+ ticks) for meaningful
evolution.

## Usage

``` r
slow_specs()
```

## Value

A specs list calibrated for K-strategist organisms.

## Details

- `max_age`:

  200L (same as default). Long lifespan.

- `min_repro_energy`:

  150 (vs 120). High parental investment.

- `min_repro_age`:

  20L. Late maturation.

- `max_ticks`:

  10000L. At gen time ~200, gives ~50 generations.

## See also

[`default_specs()`](default_specs.md), [`fast_specs()`](fast_specs.md)
