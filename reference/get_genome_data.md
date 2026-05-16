# Extract per-tick genome data (allele frequencies, diversity, FST)

Returns genome-level statistics logged when `specs$log_genomes = TRUE`.
These include per-tick allele frequency vectors, mean heterozygosity,
linkage disequilibrium, and (when `speciation = TRUE`) per-species FST.

## Usage

``` r
get_genome_data(env)
```

## Arguments

- env:

  An environment list returned by
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Value

A list with components:

- `$genomes`:

  A long data frame with one row per (tick, agent), columns `t`,
  `agent_id`, and `trait_1`..`trait_N` (N = number of scalar traits in
  the Julia kernel, currently 22). `NULL` when
  `specs$log_genomes = FALSE` or no snapshots were taken.

- `$heterozygosity`:

  Reserved field — currently returns `numeric(0L)`. Future versions will
  compute mean per-locus heterozygosity across logged ticks.

- `$fst`:

  Reserved field — currently returns `numeric(0L)`. Future versions will
  compute per-tick FST (Weir & Cockerham 1984) between species when
  `speciation = TRUE`.

## References

Weir, B.S. & Cockerham, C.C. (1984) Estimating F-statistics for the
analysis of population structure. *Evolution* 38(6):1358-1370.

## See also

[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs()
specs$log_genomes <- TRUE
env  <- run_alife(specs)
gdat <- get_genome_data(env)
head(gdat$genomes)   # tidy data.frame: t, agent_id, trait_1..trait_N
} # }
```
