# Spec preset for the Wolf 2008 responsive-personalities reproduction

Returns a specs list configured to test the
negative-frequency-dependent- selection mechanism from Wolf, van Doorn &
Weissing (2008) PNAS 105:15825-15830, in clade's spatially-explicit
framework. See the vignette `paper-wolf2008.Rmd` for the full
reproduction context.

## Usage

``` r
wolf2008_responsiveness_specs()
```

## Value

A specs list ready for
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Details

Key parameter choices vs
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md):

- `responsive_personalities = TRUE`:

  Enable the module.

- `grid_rows`/`grid_cols = 30L`:

  Standard grid; rich-cell competition emerges naturally from clade's
  grass economy.

- `n_agents_init = 200L`:

  Density 22% — high enough that responsiveness's frequency-dependent
  cost actually bites.

- `max_agents = 800L`:

  Room for population growth; the regulator is grass + handling time,
  not max_agents.

- `max_ticks = 3000L`:

  30 generations at default max_age = 100. Long enough for the
  responsiveness trait to evolve to its equilibrium frequency.

- `ploidy = 1L`:

  Haploid asexual; cleaner trait dynamics.

Wolf 2008-specific parameters (responsiveness_init_mean, mutation_sd,
responsiveness_cost) inherit from
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
To probe the density-dependent benefit (Wolf's headline mechanism):

    for (n_init in c(50L, 100L, 200L, 400L)) {
      s <- wolf2008_responsiveness_specs()
      s$n_agents_init <- n_init
      env <- run_alife(s)
      # ... compute mean responsiveness at end and plot vs n_init
    }

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
[`wolf_personality_specs()`](https://itchyshin.github.io/clade/reference/wolf_personality_specs.md).
