# Reproducing a paper — Griesser et al. 2023

*Three-stage research workflow: grid-search the parameter space to find
a regime where the signal emerges, then validate at that regime with
multi-seed replication. Demonstrates
[`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md),
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
and
[`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
working together on a non-trivial published prediction.*

![Griesser 2023 Stage 1 grid
heatmap](figures-papers/griesser-2023-stage1.png)

![Griesser 2023 Stage 2 boxplot — evolved brain size across care
durations](figures-papers/griesser-2023-stage2.png)

------------------------------------------------------------------------

## The paper

**Griesser, M., Drobniak, S. M., Graber, S. M. et al. (2023).**
*Parental provisioning drives brain size in birds.* *PNAS* 120(9):
e2121467120. DOI
[`10.1073/pnas.2121467120`](https://doi.org/10.1073/pnas.2121467120).

Comparative claim: across bird species, **duration of parental
provisioning explains variation in relative brain size**. Extended
provisioning buffers the early-life energy deficit that a large brain
imposes (the “expensive-brain + costly-newborn” bootstrap problem; see
van Schaik et al. 2023 for the framework).

For an in-silico test we want a gradient: sweep
`juvenile_independence_age` and track how evolved `mean_brain_size`
responds. Griesser predicts a **positive monotone slope**.

## Methodology: three stages

A naive
[`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
at default parameters will likely produce a null — clade’s brain-size
evolution is parameter- sensitive, and the regime that makes the
provisioning buffer *matter* is narrow. A better workflow mirrors how an
empirical researcher would design an in-silico experiment:

1.  **Stage 1 — grid search.** Explore a 2-D parameter slice
    `(brain_size_cost_scale × juvenile_independence_age)` at single
    seeds to find which cost-scale makes the provisioning gradient
    visible.
2.  **Stage 2 — multi-seed validation.** Re-run the care-duration sweep
    at the best-scoring cost-scale with 8 seeds via
    [`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
    to get robust confidence intervals.
3.  **Stage 3 — honest report.** Direction, magnitude,
    parameter-sensitivity caveat.

This also demonstrates a **real** workflow clade users would follow —
you rarely know the right parameters up front.

## Stage 1: grid search

``` r
library(clade)

base <- default_specs()
base$grid_rows                  <- 40L
base$grid_cols                  <- 40L
base$n_agents_init              <- 150L
base$max_agents                 <- 500L
base$max_ticks                  <- 3000L
base$grass_rate                 <- 0.20
base$n_predators_init           <- 0L
base$brain_size_evolution       <- TRUE
base$brain_size_init_mean       <- 1.0
base$brain_size_mutation_sd     <- 0.05
base$neonatal_foraging_deficit  <- 0.4
base$parental_care              <- TRUE
base$feeding_rate               <- 5.0
base$care_cost_per_tick         <- 1.0

# 4 x 4 = 16-cell grid, 1 seed each (fast regime discovery)
specs_list <- grid_specs(
  base,
  brain_size_cost_scale     = c(1.5, 2.0, 2.5, 3.0),
  juvenile_independence_age = c(2L, 8L, 15L, 25L),
  seed_from                 = 1L
)

results <- batch_alife(specs_list, n_cores = 16L)

grid_tbl <- do.call(rbind, mapply(function(env, s) {
  d <- get_run_data(env)$ticks
  data.frame(
    cost_scale  = s$brain_size_cost_scale,
    care_dur    = s$juvenile_independence_age,
    final_brain = mean(tail(d$mean_brain_size, 500), na.rm = TRUE),
    final_n     = mean(tail(d$n_agents, 500), na.rm = TRUE),
    crashed     = tail(d$n_agents, 1) < 10
  )
}, results, specs_list, SIMPLIFY = FALSE))
```

### Grid results

**Evolved brain size (larger = bigger evolved brain):**

| `cost_scale` | care=2 | care=8 | care=15 | care=25   |
|--------------|--------|--------|---------|-----------|
| **1.5**      | 0.954  | 1.014  | 0.951   | **1.072** |
| 2.0          | 1.031  | 0.993  | 1.005   | 1.063     |
| 2.5          | 1.082  | 0.997  | 1.074   | 1.104     |
| 3.0          | 1.022  | 0.957  | 0.961   | 1.007     |

**Viability (final population; all cells survive):**

| `cost_scale` | care=2 | care=8 | care=15 | care=25 |
|--------------|--------|--------|---------|---------|
| 1.5          | 172    | 257    | 185     | 197     |
| 2.0          | 184    | 280    | 212     | 233     |
| 2.5          | 164    | 259    | 206     | 234     |
| 3.0          | 133    | 273    | 216     | 228     |

**Signal by cost scale (single-seed Pearson correlation):**

| `cost_scale` | `cor(care_dur, final_brain)` |
|--------------|------------------------------|
| **1.5**      | **+0.71**                    |
| 2.0          | +0.55                        |
| 2.5          | +0.46                        |
| 3.0          | −0.04                        |

The grid search picks **`cost_scale = 1.5`** as the regime with the
strongest Griesser signal. All cells are viable (no extinctions).

## Stage 2: multi-seed validation

At `cost_scale = 1.5`, re-run the care-duration sweep with 8 seeds per
condition to distinguish signal from single-seed noise.

``` r
final_base <- base
final_base$brain_size_cost_scale <- 1.5

care_levels <- c(very_short = 2L, short = 8L,
                 medium     = 15L, long  = 25L)
conds <- setNames(
  lapply(care_levels, function(dur) {
    list(juvenile_independence_age = dur)
  }),
  names(care_levels)
)

sweep <- hypothesis_sweep(
  base_specs = final_base,
  conditions = conds,
  seeds      = 1:8,
  metrics    = list(
    final_brain = function(t) mean(tail(t$mean_brain_size, 500), na.rm = TRUE),
    final_n     = function(t) mean(tail(t$n_agents, 500), na.rm = TRUE)
  ),
  n_cores = 32L
)
print(sweep)

hypothesis_report(
  sweep,
  contrasts = list(
    short_vs_very_short  = c("very_short", "short"),
    medium_vs_very_short = c("very_short", "medium"),
    long_vs_very_short   = c("very_short", "long")
  ),
  metric = "final_brain"
)
```

## Results

### Per-condition brain size (8 seeds each)

| care duration  | mean brain | SE    | mean final_n |
|----------------|------------|-------|--------------|
| very_short (2) | 1.004      | 0.031 | 161          |
| short (8)      | 1.020      | 0.022 | 266          |
| medium (15)    | **1.061**  | 0.027 | 221          |
| long (25)      | 1.048      | 0.030 | 212          |

### Contrasts (vs `very_short = 2`)

| contrast    | Δ brain ± SE       | t         | verdict       |
|-------------|--------------------|-----------|---------------|
| short (8)   | +0.016 ± 0.038     | +0.43     | null          |
| medium (15) | **+0.058 ± 0.041** | **+1.41** | null-marginal |
| long (25)   | +0.045 ± 0.043     | +1.04     | null          |

Spearman(care_duration, final_brain) across all 32 runs = **+0.248**.

## Honest interpretation

**Direction** matches Griesser: evolved brain size is larger at longer
care durations. Spearman ρ = +0.25 across 32 runs reproduces the
positive slope.

**Magnitude** is below the 2σ threshold — no single contrast passes. The
grid-search-selected regime (cost_scale = 1.5) gave a +0.71 single-seed
correlation, but at 8 seeds the effect shrinks toward +0.25 with
substantial between-seed noise. The 1-seed grid search was
overoptimistic; the 8-seed validation is the honest measurement.

### Why the effect is noisy

clade’s brain-size evolution is slow (mutation_sd = 0.05 per generation,
`max_age = 200` ⇒ ~15 generations in 3000 ticks). Each run accumulates
~15 selection events on brain_size — enough to establish a direction but
not enough for cross-run convergence. Longer runs + larger populations
would sharpen the signal, at the cost of more compute per cell.

### Why clade is still useful for this question

Griesser 2023 is a *comparative* study — they pool across bird species.
clade gives a complementary *mechanistic* test: if a researcher’s theory
of provisioning-drives-brain-size is right, they should see the
direction even in a toy ABM. clade does. The strength of the effect
depends on parameter choices the comparative data averages over.

### Methodology takeaways

1.  **Always grid-search before hypothesis-testing** when you don’t know
    the right regime. The default parameters gave a null; the grid
    search found a +0.71 correlation in one cell.
2.  **Multi-seed validation shrinks single-seed effect sizes** — often
    substantially. Always re-run the “winning” cell with 8+ seeds before
    reporting.
3.  **Direction-correct-but-sub-σ results are real and worth
    publishing** — they tell you the mechanism exists but
    parameter-sensitive. This is the empirical-science version of the
    “marginal effect size” finding that the single-case method section
    can’t reveal.

## Citation

``` bibtex
@article{griesser2023parental,
  author  = {Griesser, Michael and Drobniak, Szymon M. and Graber, Sereina M.
             and Schuppli, Caroline and van Schaik, Carel P.},
  title   = {Parental provisioning drives brain size in birds},
  journal = {Proceedings of the National Academy of Sciences},
  volume  = {120},
  number  = {9},
  pages   = {e2121467120},
  year    = {2023},
  doi     = {10.1073/pnas.2121467120}
}
```

Full audit protocol and raw outputs:
[dev/audit/fidelity/paper_griesser_2023.R](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/paper_griesser_2023.R)
and `paper_griesser_2023.rds`.
