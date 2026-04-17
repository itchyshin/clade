# Viability report for an evolutionary-audit run

Checks whether a
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
result is viable enough to support claims about *evolved* trait values.
Population crashes (agents dying faster than they reproduce) silently
corrupt trait-mean audits by over-weighting a few lucky survivors. This
function quantifies crash risk via three metrics and returns a tidy
report together with a verdict in `{"viable", "weak", "crashed"}`.

## Usage

``` r
viability_report(
  run_data,
  n_agents_init = NULL,
  crashed_frac = 0.2,
  weak_frac = 0.5,
  min_n = 20L
)
```

## Arguments

- run_data:

  A list from
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  — either a single `$ticks` data frame or the full
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  output.

- n_agents_init:

  Integer. The initial agent count used to seed the run. Required
  because `run_data` does not carry the spec. Pass `NULL` (default) to
  use the first-tick `n_agents` (which approximates init-mean after the
  first wave of births, and is usually close enough).

- crashed_frac:

  Numeric in (0, 1). A run is declared `"crashed"` if
  `n_final < crashed_frac * n_agents_init`. Default 0.2 (final
  population less than 20% of init).

- weak_frac:

  Numeric in (0, 1). A run is declared `"weak"` (viable but with low
  confidence) if `n_final < weak_frac * n_agents_init`. Default 0.5.

- min_n:

  Integer. Absolute minimum n_final below which the run is `"crashed"`
  regardless of `crashed_frac`. Default 20 (at fewer than 20 agents, any
  trait mean is dominated by a handful of individuals). Set to `0` to
  disable this floor.

## Value

A list with:

- `verdict`:

  One of `"viable"`, `"weak"`, `"crashed"`.

- `n_init`:

  First-tick n_agents used as the reference.

- `n_final`:

  Last-tick n_agents.

- `n_min`:

  Minimum n_agents across the whole run.

- `frac_final`:

  `n_final / n_init`.

- `frac_min`:

  `n_min / n_init`.

- `tick_of_min`:

  First tick where `n_min` was reached.

- `message`:

  A one-line diagnostic suitable for logging.

## Details

Motivation: during the 2026-04-17 fast_specs re-audit of s-plasticity
and s-dispersal-ifd, direction flips in the 5-seed multi-seed results
were traced to seasonal runs where `n_final < 20` while stable runs
maintained healthy populations. The trait-mean average over 0-5
surviving agents is dominated by the specific crash trajectory rather
than by any evolutionary signal. This utility codifies the "check
n_final before trusting trait-mean effects" rule into a reusable check.

## See also

[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_alife(fast_specs())
vr   <- viability_report(get_run_data(env))
print(vr)
# Guard audit claims on viability:
if (vr$verdict == "crashed") {
  warning("crash-driven result; trait means are unreliable")
}
} # }
```
