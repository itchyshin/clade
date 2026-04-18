# s-plasticity + s-baldwin: kernel bug fixed but full promotion pending

## The bug

Under default clade kernel behaviour, `mean_prior_sigma` (mean BNN
posterior sigma across all agents across all weights) pegs at
**exactly `bnn_sigma_init = 0.5`** within ~6 generations of any run
and stays there forever, regardless of seed, environment type, or
mutation rate:

| `bnn_sigma_init` | late `mean_prior_sigma` |
|---|---|
| 0.2 | **0.2000** |
| 0.5 | **0.5000** |
| 1.0 | **1.0000** |

That's not heterozygosity-driven evolution — that's the initial
constant tracking.

## Root cause

In `inst/julia/src/genome.jl:make_offspring_genome`:

```julia
if specs["ploidy"] == 2 && parent2 !== nothing
    pat_w = meiosis(parent2, specs, rng)
else
    pat_w = Float32[]     # <-- offspring is effectively haploid
end
```

When a diploid agent can't find a mate (low-density / Allee failure),
its offspring is assigned an empty paternal-weights vector. Then
`make_bnn_brain` takes the `is_haploid` branch and assigns
`sigma = fill(sigma_init, n)` — the constant `bnn_sigma_init = 0.5`.

On clade's standard 30×30 or 60×60 grid at equilibrium densities
(0.04–0.09 agent/cell), mate-finding fails in the 8-cell Moore
neighbourhood for a majority of reproductions. Within a few
generations, the entire population converts to "effectively haploid"
offspring with sigma pegged at init. The Hinton-Nowlan /
Baldwin canalization signal — selection purging heterozygosity
at useful loci in stable envs — cannot be observed because
heterozygosity has been silently reset.

## The fix (partial — 0.5.9)

New spec `self_fertilization_fallback` (default FALSE for backward
compatibility). When TRUE + `ploidy = 2` + no mate found:

```julia
pat_w = meiosis(parent1, specs, rng)    # second gamete from parent1
```

Offspring stays diploid with both gametes from the same parent
(self-fertilization), preserving heterozygosity (parent1's two
alleles differ at each locus). With selfing enabled:

| config | late `mean_prior_sigma` |
|---|---|
| selfing=FALSE | **0.5000** (pegged) |
| selfing=TRUE  | **0.0762** (real heterozygosity, evolves) |

## Why it doesn't promote plasticity/Baldwin yet

Selfing fallback works but inbreeding shrinks populations rapidly:
at `realistic_specs()` with selfing, equilibrium drops from ~120
agents to ~30-35 agents. Most seeds fall below the `viability_report`
threshold (`n < 0.2 × n_init = 30`) and are classified "crashed".

In the 1-2 seeds per condition that survive, **direction is correct**:

| condition | mean_prior_sigma | n viable |
|---|---|---|
| stable   | 0.0754 | 1/16 |
| seasonal | 0.0766 | 1/16 |

Δ(seasonal − stable) = +0.0012 — tiny but in the Baldwin-predicted
direction (seasonal env maintains heterozygosity).  Not statistically
distinguishable from zero at n = 1 per condition.

## What would unlock full promotion

Two options, either requiring non-trivial kernel work:

1. **Broader mate-finding** — extend search beyond the 8-cell Moore
   neighbourhood to a 5×5 or 7×7 window. Ecologically reasonable
   (agents often search a larger area for mates). Would reduce
   Allee-failure rate to near-zero at realistic densities, so
   selfing wouldn't be needed and full-diploid evolution would
   dominate.

2. **Outcrossed selfing** — when no mate found, use a randomly-chosen
   other agent from somewhere in the grid as the sperm donor,
   instead of parent1. This avoids inbreeding and preserves
   population viability. Biologically this is long-distance mating
   (e.g. pollen dispersal).

Either fix + re-running `plasticity_sigma.R` / `baldwin_sigma.R`
at 16 seeds should cross 2σ given the direction is correct.

## Lessons

- **"Kernel-limited" is specific.** My earlier diagnosis attributed
  the null to the `1/σ²` term in the REINFORCE score function.
  That's a real numerical issue for trait-mode sigma but wasn't
  what was blocking heterozygosity-mode sigma evolution.
- **Silent type-switching is a smell.** A diploid agent producing
  a "haploid" offspring via the `pat_w = Float32[]` fallback is
  surprising kernel behaviour that wasn't flagged in logs. A warning
  when this happens (or treating it as an error when
  `self_fertilization_fallback = TRUE`) would make this easier to
  catch.
- **Check the metric.** `mean_plasticity` was tracking a neutral
  genomic scalar; `mean_prior_sigma` was the right quantity.
  Both columns are logged, so this is just an audit-script choice.

## Files

- [plasticity_sigma.R](plasticity_sigma.R), [baldwin_sigma.R](baldwin_sigma.R):
  audits using the correct `mean_prior_sigma` metric.
- [plasticity_dense.R](plasticity_dense.R): 30×30 fast_specs variant
  (confirmed sigma still pegs without selfing even at higher density).
- Kernel change: [inst/julia/src/genome.jl:276-294](../../../inst/julia/src/genome.jl).
- Spec default: [R/config.R](../../../R/config.R) `self_fertilization_fallback = FALSE`.
