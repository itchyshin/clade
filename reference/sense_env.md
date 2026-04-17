# Build the sensory input vector for an agent

`sense_env()` reconstructs the 11-element (or longer, when predators or
parental care are active) sensory input vector that the agent's brain
would receive on the current tick. It mirrors the Julia-side sensing
logic so that you can inspect, plot, or replay individual agent
decisions from R.

## Usage

``` r
sense_env(env, i = 1L)
```

## Arguments

- env:

  Environment list from
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

- i:

  Integer; index into `env$agents` (1-based). Use `agent_id` to locate
  the index by ID: `which(sapply(env$agents, \(a) a$id) == agent_id)`.

## Value

A named numeric vector. Slots:

- `grass_L/U/R/D/C`:

  Grass value in left, up, right, down, centre.

- `agent_L/U/R/D`:

  Agent presence (0/1) in four cardinal directions.

- `energy`:

  Agent's current energy.

- `age_norm`:

  Agent age normalised by `specs$max_age`.

## Details

The function requires `env$grass` (returned automatically by
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md))
and `env$agents`. Agent-map occupancy is reconstructed from agent
positions. When `env$grass` is `NULL` (e.g. from a mock env), grass
slots are set to 0.

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
