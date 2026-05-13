# Reproducing a paper — Kokko & Brooks 2003

*Worked example: take a published behavioural-ecology paper, turn its
core prediction into a clade experiment, report what reproduces and what
doesn’t. Uses the
[`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md) +
[`hypothesis_report()`](https://itchyshin.github.io/clade/reference/hypothesis_report.md)
helpers to keep the whole workflow inside clade’s vocabulary — no
separate scripts, no bespoke plumbing.*

![K&B 2003 — signals × grass rate, 0.6.4 kernel. Signals effect is weak
and non-monotonic; the interaction previously reported as PASS is now
null.](figures-papers/kokko-brooks-2003.png)

> **0.6.4 re-audit note.** Numbers on this page are from the 0.6.4
> kernel, which wires `mate_choice_mode` / `mate_choice_strength` for
> the first time (before 0.6.4 these were silently ignored —
> `signal_dims > 0` always produced hard argmax regardless of
> `strength`). This audit script sets `mate_choice_strength = 0.7`,
> which now actually runs as softmax sampling. The pre-0.6.4 numbers
> (clean monotonic `signals_effect` shrinking with stress, interaction
> `t = +2.81 PASS`) depended on the implicit argmax that the stub
> produced. Under honest softmax at `strength = 0.7`, the signals effect
> is weaker and the interaction goes null — clade can no longer
> adjudicate K&B’s interaction in this parameter regime. See `NEWS.md`
> 0.6.4 for the full migration note.

------------------------------------------------------------------------

## The paper

**Kokko, H. & Brooks, R. (2003).** *Sexy to die for? Sexual selection
and the risk of extinction.* *Annales Zoologici Fennici* 40, 207–219.

Core claim: **evolutionary “suicide” from costly sexual traits is
*unlikely* in stable environments, but becomes possible under
environmental stress**. The interaction — how the fitness effect of
signals scales with environmental pressure — is the paper’s distinctive
empirical prediction.

The prediction is qualitative in the original: populations carrying
costly sexual signals should face a steeper extinction-risk gradient as
environments deteriorate. For an in-silico test we need a quantitative
surrogate. The natural one is:

> At each resource level, measure `Δn = n(signals on) − n(signals off)`.
> Plot Δn as a function of resource level. K&B predict the slope is
> *negative*: as resources deteriorate, signals become an increasingly
> costly liability.

This is a clean 2 × k factorial (signals × resource level), and a clean
*interaction test* on the slope of `signals_effect`.

## Three-stage workflow

Same structure as the other paper reproductions (Griesser 2023, D&D
1999, Réale 2010, Emlen 1982):

1.  **Stage 1 — grid search.**
    [`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md) +
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
    across a wide `(signal_cost × grass_rate)` grid at single seeds to
    test whether the K&B interaction *ever* reproduces its predicted
    direction.
2.  **Stage 2 — multi-seed validation.**
    [`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
    at the chosen signal_cost with 8 seeds per condition.
3.  **Stage 3 — viability spot-check.**
    [`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)
    on the most-stressed cell to confirm populations are surviving, not
    sitting at a pathological fitness floor.

## Stage 1: grid search

Does the K&B interaction ever go negative at any tested cost level?

``` r

library(clade)

base <- default_specs()
base$grid_rows       <- 40L
base$grid_cols       <- 40L
base$n_agents_init   <- 120L
base$max_agents      <- 500L
base$max_ticks       <- 2000L
base$n_predators_init <- 0L

SIGNAL_DIMS  <- 3L
COST_LEVELS  <- c(0.0, 0.1, 0.2, 0.4, 0.8)
GRASS_LEVELS <- c(0.20, 0.12, 0.08, 0.05)

# Build one spec per (cost, grass) cell, signals-off when cost = 0
grid_spec_list <- list()
for (c in COST_LEVELS) for (g in GRASS_LEVELS) {
  s <- base
  if (c > 0) {
    s$signal_dims <- SIGNAL_DIMS; s$signal_cost <- c
    s$signal_evolution_drift <- TRUE; s$signal_drift_sd <- 0.01
    s$mate_choice_mode <- "preference"; s$mate_choice_strength <- 0.7
  } else {
    s$signal_dims <- 0L; s$signal_cost <- 0.0
    s$mate_choice_mode <- "random"
  }
  s$grass_rate  <- g
  s$random_seed <- 7L
  grid_spec_list[[sprintf("c%.1f_g%.2f", c, g)]] <- s
}
grid_envs <- batch_alife(grid_spec_list, n_cores = 20L)
```

### Stage 1 result — final_n across the cost × grass grid (0.6.4)

| `signal_cost` | grass=0.20 | grass=0.12 | grass=0.08 | grass=0.05 |
|---------------|------------|------------|------------|------------|
| **0.0**       | **238.0**  | **169.2**  | **120.8**  | **73.3**   |
| 0.1           | 232.2      | 154.5      | 111.8      | 68.5       |
| 0.2           | 238.8      | 151.9      | 115.3      | 74.3       |
| 0.4           | 230.2      | 138.5      | 108.6      | 63.4       |
| 0.8           | 241.4      | 150.7      | 101.9      | 60.8       |

### Signals-effect per grass level (cost\>0 mean − cost=0)

| `grass_rate`       | signals_effect |
|--------------------|----------------|
| 0.20 (abundant)    | −2.4           |
| 0.12               | −20.3          |
| 0.08               | −11.4          |
| 0.05 (very scarce) | −6.5           |

**The signals-effect is non-monotonic and weak.** The biggest drag
appears at mid-grass (0.12), not at either extreme. This is a regime
where clade’s mate choice does not produce robust distinguishable signal
costs across the stress gradient. Compare to the pre-0.6.4 numbers in
git history (commit `3ede433`), where the implicit-argmax stub produced
a clean monotonic shrinking pattern at roughly 3× the magnitude — a
result we now know was partly an artifact of `mate_choice_strength`
being ignored.

## Stage 2: multi-seed validation

``` r

library(clade)

base <- default_specs()
base$grid_rows       <- 40L
base$grid_cols       <- 40L
base$n_agents_init   <- 120L
base$max_agents      <- 500L
base$max_ticks       <- 2000L
base$n_predators_init <- 0L   # isolate resource stress

SIGNAL_COST  <- 0.2
SIGNAL_DIMS  <- 3L
GRASS_LEVELS <- c(abundant = 0.20, mid = 0.12,
                  scarce   = 0.08, very_scarce = 0.05)

make_cond <- function(grass, signals_on) {
  if (signals_on) list(
      signal_dims            = SIGNAL_DIMS,
      signal_cost            = SIGNAL_COST,
      signal_evolution_drift = TRUE,
      signal_drift_sd        = 0.01,
      mate_choice_mode       = "preference",
      mate_choice_strength   = 0.7,
      grass_rate             = grass
    )
  else list(
      signal_dims      = 0L,
      signal_cost      = 0.0,
      mate_choice_mode = "random",
      grass_rate       = grass
    )
}

conds <- list()
for (ln in names(GRASS_LEVELS)) {
  g <- GRASS_LEVELS[[ln]]
  conds[[paste0(ln, "_no_signals")]]   <- make_cond(g, FALSE)
  conds[[paste0(ln, "_with_signals")]] <- make_cond(g, TRUE)
}

sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = conds,
  seeds = 1:8,
  metrics = list(
    final_n     = function(ticks) mean(tail(ticks$n_agents, 500), na.rm = TRUE),
    crashed     = function(ticks) tail(ticks$n_agents, 1) < 10,
    mean_energy = function(ticks) mean(tail(ticks$mean_energy, 500), na.rm = TRUE)
  ),
  n_cores = 32L
)
print(sweep)

# Contrasts: one signals-effect test per resource level
signals_contrasts <- setNames(
  lapply(names(GRASS_LEVELS), function(ln) {
    c(paste0(ln, "_no_signals"), paste0(ln, "_with_signals"))
  }),
  paste0("signals_effect_", names(GRASS_LEVELS))
)
rpt <- hypothesis_report(sweep, signals_contrasts, metric = "final_n")
print(rpt)
```

## Stage 3: viability spot-check

Confirm the most-stressed cell (very_scarce + signals) isn’t sitting at
a pathological fitness cliff that would invalidate the Δ statistics.

``` r

s_check <- base
s_check$signal_dims            <- SIGNAL_DIMS
s_check$signal_cost            <- 0.2
s_check$signal_evolution_drift <- TRUE
s_check$mate_choice_mode       <- "preference"
s_check$grass_rate             <- 0.05
env_check <- run_alife(s_check, verbose = FALSE)
viability_report(get_run_data(env_check))
#> <clade viability report>
#>  viable: n_init=120, n_final=64 (53%), n_min=35 at tick 232 (29%)
```

Population drops to 29% of init at its minimum but stays above the
“crashed” threshold — the stressed+signals condition is viable, so the
Stage 2 null on extinctions reflects real sustained populations, not
dying-out runs.

## Stage 2 results

### Per-condition equilibrium populations (8 seeds each, 0.6.4)

| grass_rate         | signals OFF | signals ON  |
|--------------------|-------------|-------------|
| abundant (0.20)    | 237.7 ± 5.3 | 229.1 ± 5.2 |
| mid (0.12)         | 157.8 ± 3.2 | 160.6 ± 3.2 |
| scarce (0.08)      | 120.6 ± 2.3 | 110.2 ± 1.4 |
| very_scarce (0.05) | 70.2 ± 4.9  | 68.8 ± 1.9  |

Main effect of resource: massive. Going from abundant to very_scarce
cuts equilibrium population by ~70% regardless of signals.

### Signals effect per resource level

| resource level | Δ (signals − no signals) ± SE | t         | verdict  |
|----------------|-------------------------------|-----------|----------|
| abundant       | −8.66 ± 7.41                  | −1.17     | null     |
| mid            | +2.86 ± 4.49                  | +0.64     | null     |
| scarce         | **−10.43 ± 2.72**             | **−3.83** | **PASS** |
| very_scarce    | −1.43 ± 5.22                  | −0.27     | null     |

### The K&B interaction

K&B predict: `signals_effect @ very_scarce` should be *more negative*
than `signals_effect @ abundant` — the sexual-selection drag gets worse
under stress.

Under 0.6.4 (softmax-sampled preference mating at `strength = 0.7`):

    signals_effect @ abundant    = -8.66 ± 7.41
    signals_effect @ very_scarce = -1.43 ± 5.22
    Δ(very_scarce - abundant)    = +7.22 ± 9.07, t = +0.80  [null]

**The interaction is null.** The direction trend is still positive
(wrong way for K&B) but no longer statistically distinguishable from
zero. The pre-0.6.4 “PASS” verdict on direction-wrong interaction
(`t = +2.81`) depended on the implicit-argmax stub and does not survive
honest softmax mate choice.

### Extinction rates

Zero extinctions across all 64 runs. clade’s 2000-tick ceiling +
500-agent cap + resource-limited dynamics produce stable equilibria at
every tested condition; K&B’s primary outcome (extinction risk) is not
expressible in this regime.

## What this tells us — honest interpretation

Three observations stand apart:

1.  **Signal effects are weak or null at most resource levels.** Only
    `scarce` (grass=0.08) shows a significant signals drag
    (`t = −3.83`). abundant, mid, and very_scarce are all null. Under
    honest softmax mate choice, `signal_cost = 0.2` produces only
    marginal demographic drag at most stress levels.

2.  **The interaction direction is no longer distinguishable from
    zero.** Pre-0.6.4 this audit reported `t = +2.81 PASS` on a
    direction-wrong interaction (“clade contradicts K&B direction”).
    That verdict was specific to the implicit-argmax mate choice that
    the `mate_choice_mode` stub produced. With the wiring fixed,
    `t = +0.80 null` — clade can’t adjudicate K&B’s interaction in this
    parameter regime.

3.  **No extinctions.** K&B’s primary outcome is not observed because
    clade’s dynamics produce stable low-density equilibria rather than
    demographic collapse even at the most extreme tested resource level.

### Why weaker signals effects now?

Two reasons compound:

- **Softmax vs argmax mate choice.** Pre-0.6.4, the kernel silently did
  argmax (always pick the single best preference-matching mate). Argmax
  creates strong selection: only the best-match signals propagate. With
  `strength = 0.7` softmax (the documented intent of this audit), many
  partial matches also reproduce, dramatically diluting the selective
  pressure on signals. Less selection → smaller demographic drag from
  `signal_cost`.

- **Mechanistic framework gap.** clade’s signal cost is a **per-tick
  per-agent linear energy drain**. K&B’s theoretical framework (built on
  allele-dynamic models) assumes costs that interact *multiplicatively*
  with stress — signal-maintenance costs reducing fasting tolerance
  under scarcity. These are different mechanistic claims dressed in the
  same surface “costly trait” vocabulary.

Both findings are scientifically informative — the audit methodology
surfaced both the framework-level mismatch (still true) and the
stub-artifact bonus that had previously made the direction-contradiction
look more decisive than it actually was.

### Paths to a clade-side K&B reproduction

Three extensions would likely reproduce the K&B pattern:

- **Stress-multiplicative costs**: replace `signal_cost` with a
  mechanism where signal-bearing agents face higher starvation
  probability at low energy (not just a flat energy tax). Requires a
  kernel change in `tick.jl` — signal load → fasting-tolerance penalty.

- **Longer runs + harder stress**: 8000 ticks × `grass_rate = 0.03`
  might produce extinctions; K&B’s outcome is extinction probability,
  not equilibrium Δ. Pure parameter-space change, no kernel work.
  Deferred; not attempted here.

- **Sexual dimorphism**: clade does not currently implement sex-specific
  mortality. K&B predict that sexual dimorphism can *raise* carrying
  capacity when high male mortality relaxes density-dependence on
  females. Implementing sex-specific survival would let clade test both
  the extinction-risk and dimorphism-paradox halves of the paper’s
  argument.

## Takeaway for empirical researchers

The workflow this vignette demonstrates is the common shape of an
in-silico verification study:

1.  **Read the paper** carefully enough to extract a *quantitative*
    prediction (not a paraphrase). K&B’s is “signals_effect slope is
    negative with resource deterioration”.
2.  **Translate to clade terms**: which parameters encode the mechanism,
    which encode the environment, which outcome measures the prediction.
3.  **Use
    [`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)**
    to cross the relevant parameters across enough seeds to distinguish
    signal from drift.
4.  **Use
    [`hypothesis_report()`](https://itchyshin.github.io/clade/reference/hypothesis_report.md)**
    to compute the specific contrasts your prediction requires,
    including interactions.
5.  **Report the result honestly** — including when the kernel’s
    mechanistic realisation of the cited theory differs from the paper’s
    own framework, producing a different prediction direction.

Zero code was written outside of spec lists + the two helpers. Total
compute: ~30 s on 32 PSOCK cores for 64 runs × 2000 ticks.

## Citation

If you use this scenario or workflow in published work, cite both the
paper and clade:

``` bibtex
@article{kokko2003sexy,
  author  = {Kokko, Hanna and Brooks, Robert},
  title   = {Sexy to die for? Sexual selection and the risk of extinction},
  journal = {Annales Zoologici Fennici},
  year    = {2003},
  volume  = {40},
  pages   = {207--219}
}

@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```

Audit protocol and raw outputs:
[dev/audit/fidelity/kokko_brooks_2003.R](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/kokko_brooks_2003.R)
and `kokko_brooks_2003.rds`.
