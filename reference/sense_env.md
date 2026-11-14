# Build the sensory input vector for an agent

For results from
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
return the Julia kernel's sensory input computed from the final
environment state in the agent brain's input order. This snapshot
reflects the selected `sense_mode`. It is not the input to the agent's
last decision: the environment may have changed since that decision, and
a stochastic brain may choose differently on another forward pass.

## Usage

``` r
sense_env(env, i = 1L)
```

## Arguments

- env:

  Environment list from
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

- i:

  Integer; index into `env$agents` (1-based).

## Value

A named numeric vector. For a saved snapshot, names follow the kernel
order: energy, age, directional grass and agent occupancy, bias, then
optional predator, parental-care, and signal channels. Per-cell
directional names include the distance; weighted sums use one per
direction.

## Details

Older results or manually constructed environments without a snapshot
use a legacy 11-value approximation in `per_cell` mode. It does not
reproduce the current kernel's layout. In `weighted_sum` mode a snapshot
is required; rerun the simulation if it is absent.

## See also

[`take_action()`](https://itchyshin.github.io/clade/reference/take_action.md),
[`inspect_brain()`](https://itchyshin.github.io/clade/reference/inspect_brain.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_alife(default_specs())
v   <- sense_env(env, 1L)
barplot(v, las = 2, main = "Sensory input, agent 1")
} # }
```
