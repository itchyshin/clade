# Spec preset for the Trivers 1971 reciprocal-altruism reproduction

Returns a specs list configured to demonstrate the conditions Trivers
(1971) identified for the evolution of conditional cooperation: long
lifespan, low dispersal, partner recognition, cheater discrimination.
See the vignette `paper-trivers1971.Rmd` for the full discussion and the
dispersal sweep that maps the cooperation-vs-defection regime boundary.

## Usage

``` r
trivers_reciprocity_specs()
```

## Value

A specs list ready for
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Details

Key parameter choices vs
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md):

- `reciprocal_altruism = TRUE`:

  Enable the module.

- `max_age = 500L`:

  Long lifespan (Trivers condition 1) — many opportunities for repeat
  encounters.

- `dispersal_evolution = FALSE`:

  Low dispersal (Trivers condition 2) — partners stay nearby, so
  re-encounter rate is high.

- `grid_rows`/`grid_cols = 30L`:

  Standard density. The reciprocity radius defaults to 1 (Moore
  neighborhood).

- `n_agents_init = 200L`:

  Higher density (~22%) → more frequent adjacency encounters.

- `max_agents = 800L`:

  Room for the population to grow under mutual cooperation.

- `max_ticks = 2000L`:

  Long enough for selection on the three reciprocity traits to act.

- `ploidy = 1L`:

  Haploid asexual; cleaner trait dynamics.

Trivers-specific parameters (cost, benefit ratio, interaction rate,
partner memory size, encounter radius, trait init means/SDs) inherit
their defaults from
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
To run the dispersal-rate sweep that demonstrates the regime boundary:

    for (rate in c(0, 0.1, 0.3, 0.5)) {
      s <- trivers_reciprocity_specs()
      s$dispersal_evolution    <- TRUE
      s$dispersal_init_mean    <- rate
      s$dispersal_mutation_sd  <- 0   # lock dispersal at this rate
      env <- run_alife(s)
      # ... compute mean cooperation rate from final agent traits
    }

## See also

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).
