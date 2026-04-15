# Simulate the evolution of scientific practice

Implements the agent-based model from Smaldino & McElreath (2016).
"Labs" (agent groups) have heritable `research_power` (W; the
probability that a given study tests a true hypothesis) and
`research_effort` (e; investment in methodological rigour). The
false-positive rate per study is

## Usage

``` r
run_bad_science(
  n_labs = 200L,
  n_ticks = 500L,
  n_studies_per_tick = 5L,
  replication_rate = 0,
  research_power_init_mean = 0.3,
  research_effort_init_mean = 0.8,
  mutation_sd = 0.05,
  seed = NULL
)
```

## Arguments

- n_labs:

  Integer; number of labs. Default 200.

- n_ticks:

  Integer; number of evolutionary ticks to run. Default 500.

- n_studies_per_tick:

  Integer; studies produced per lab per tick. Default 5.

- replication_rate:

  Numeric in \[0, 1\]; probability per tick that a lab attempts to
  replicate one of a random neighbour's published findings. Replication
  does not penalise false positives; it only tracks `failed_reps`
  (attempts that fail because the original was a false positive).
  Default 0.

- research_power_init_mean:

  Numeric; initial mean research power W. Default 0.3.

- research_effort_init_mean:

  Numeric; initial mean research effort e. Default 0.8.

- mutation_sd:

  Numeric; standard deviation of Gaussian mutation applied to both
  traits at reproduction. Default 0.05.

- seed:

  Integer or `NULL`; random seed for reproducibility. Default `NULL`.

## Value

A data frame with one row per tick and columns:

- `t`:

  Tick number.

- `mean_power`:

  Mean `research_power` across labs.

- `mean_effort`:

  Mean `research_effort` across labs.

- `mean_fpr`:

  Mean false-positive rate `alpha` across labs.

- `total_publications`:

  Total publications produced this tick.

- `failed_replications`:

  Number of failed replication attempts.

## Details

alpha = W / (1 + (1 - W) \* e)

Each tick, each lab produces `n_studies_per_tick` studies yielding some
mix of true positives (probability W) and false positives (probability
alpha among studies that did not find a true effect). Labs with more
publications reproduce at higher rates. Optional replication attempts
slow but do not stop the deterioration of research standards.

## References

Smaldino, P.E. & McElreath, R. (2016) The natural selection of bad
science. Royal Society Open Science 3:160384. doi:10.1098/rsos.160384

## Examples

``` r
result <- run_bad_science(n_ticks = 200L, seed = 1L)
plot(result$t, result$mean_fpr, type = "l",
     xlab = "Tick", ylab = "Mean false-positive rate",
     main = "Evolution of bad science")
```
