# Spec preset for the Wolf 2007 personality reproduction

Returns a specs list configured to reproduce the boldness-aggressiveness
syndrome from Wolf, van Doorn, Leimar & Weissing (2007) Nature
447:581-584, implemented in clade's spatially-explicit framework. See
the vignette `paper-wolf2007.Rmd` for the full reproduction context and
discussion of the spatially-explicit interpretation (vs Wolf's
mean-field model).

## Usage

``` r
wolf_personality_specs()
```

## Value

A specs list ready for
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Details

Key parameter choices vs
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md):

- `personality_syndrome = TRUE`:

  Enable the module.

- `min_repro_energy = 1e9`:

  Disable clade's standard energy-triggered reproduction so only Wolf
  age-windowed reproduction fires.

- `min_repro_age = 0L`:

  Defer reproduction control to the personality module's age windows.

- `max_age = 999L`:

  Defer death control to the personality module (year-2 reproduction
  kills the parent).

- `grid_rows`/`grid_cols = 30L`:

  Standard density (Wolf used a non-spatial population; clade needs a
  grid large enough for one-per-cell + neighborhood encounters).

- `n_agents_init = 60L`:

  Initial density ~7%.

- `max_agents = 500L`:

  Standard cap.

- `max_ticks = 2000L`:

  20 generations at the default `wolf_year2_repro_age = 100`. Wolf used
  50,000 generations for his paper figures — for an exact reproduction,
  scale much higher.

- `ploidy = 1L`:

  Haploid asexual genetics, matching Wolf's basic model (Methods §"Basic
  model"). The diploid quantitative-genetics extension (Wolf's Fig 4)
  can be enabled by setting `ploidy = 2L`.

Wolf-specific parameters (β, f_high, f_low, V, δ, b, γ, year ages,
per-tick game frequencies) inherit their defaults from
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
Override individual fields after calling this function:

    s <- wolf_personality_specs()
    s$personality_hawkdove_radius <- 2L   # widen pairing neighborhood
    s$max_ticks <- 5000L                   # longer evolution
    env <- run_alife(s)

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).
