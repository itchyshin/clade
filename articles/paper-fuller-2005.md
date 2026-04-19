# Reproducing a paper — Fuller, Houle & Travis 2005 (sensory bias synthesis)

*Kernel-level honest null: clade’s current signal machinery is
drift-dominated, and cannot differentiate the sensory-bias vs
Fisherian-runaway vs Zahavi-handicap mechanisms that Fuller 2005’s
theoretical synthesis unifies. This vignette demonstrates the “try to
reproduce and find clade CAN’T differentiate the mechanisms” outcome as
its own research finding.*

![Fuller 2005 — all mate choice x cost combinations converge to the same
signal magnitude (~1.05), with only the signals-off null at
zero](figures-papers/fuller-2005.png)

------------------------------------------------------------------------

## The paper cluster

**Fuller, R. C., Houle, D. & Travis, J. (2005).** *Sensory bias as an
explanation for the evolution of mate preferences.* *American
Naturalist* 166(4), 437–446.

A theoretical synthesis that ties together:

- **Ryan, M. J. (1990).** *Sexual selection, sensory systems and sensory
  exploitation.* *Oxford Surveys in Evolutionary Biology* 7, 157–195. —
  The sensory-exploitation concept paper.
- **Ryan, M. J., Fox, J. H., Wilczynski, W. & Rand, A. S. (1990).**
  *Sexual selection for sensory exploitation in the frog Physalaemus
  pustulosus.* *Nature* 343, 66–67. — The túngara frog empirical
  landmark.
- **Endler, J. A. & Basolo, A. L. (1998).** *Sensory ecology, receiver
  biases and sexual selection.* *Trends in Ecology & Evolution* 13,
  415–420.

Fuller et al.’s distinctive contribution is **theoretical**: they argue
that “sensory bias” and “Fisherian coevolution” have been framed as
rival explanations when in fact **both mechanisms can operate
simultaneously**. Genetic correlations between sensory systems and mate
preferences mean that direct selection on the sensory apparatus for
non-mating functions (foraging, predator detection) spills over into
mate-preference evolution, while preferences also coevolve with signals
in the classic Fisherian sense. The two are a continuum, not a
dichotomy.

## What clade can (and cannot) test directly

**Can test**: whether preference-based mate choice drives signal
elaboration beyond what drift alone produces. If it does, clade would be
providing a substrate for the Fuller-synthesized family of mechanisms to
operate.

**Cannot test**: the specific Fuller distinction between pre-existing
bias and coevolving preference. clade logs a scalar
`mean_signal_magnitude` but not signal-direction or
preference-direction, so we can’t measure the signal-preference
alignment over time that would distinguish the mechanisms.

That limit is important up front: even a clean positive result in this
vignette wouldn’t settle Fuller’s question. What *can* happen is that
clade shows **no** differentiation — a kernel-level honest null that
tells us the substrate is too coarse to carry the question.

## Experiment

Six conditions × 8 seeds = 48 runs, 40×40 grid, 3000 ticks,
`signal_drift_sd = 0.05`, `mate_choice_strength = 1.0` (fully greedy
preference).

``` r
library(clade)

base <- default_specs()
base$grid_rows              <- 40L
base$grid_cols              <- 40L
base$n_agents_init          <- 120L
base$max_agents             <- 500L
base$max_ticks              <- 3000L
base$grass_rate             <- 0.15
base$signal_dims            <- 3L
base$signal_evolution_drift <- TRUE
base$signal_drift_sd        <- 0.05

sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = list(
    null_no_signals    = list(signal_dims      = 0L,
                              signal_cost      = 0.0,
                              mate_choice_mode = "random"),
    random_no_cost     = list(signal_cost      = 0.0,
                              mate_choice_mode = "random"),
    random_with_cost   = list(signal_cost      = 0.2,
                              mate_choice_mode = "random"),
    preference_no_cost = list(signal_cost          = 0.0,
                              mate_choice_mode     = "preference",
                              mate_choice_strength = 1.0),
    preference_mild    = list(signal_cost          = 0.1,
                              mate_choice_mode     = "preference",
                              mate_choice_strength = 1.0),
    preference_strong  = list(signal_cost          = 0.3,
                              mate_choice_mode     = "preference",
                              mate_choice_strength = 1.0)
  ),
  seeds = 1:8,
  metrics = list(
    final_signal = function(t) mean(tail(t$mean_signal_magnitude, 500),
                                    na.rm = TRUE),
    final_n      = function(t) mean(tail(t$n_agents, 500), na.rm = TRUE)
  ),
  n_cores = 48L
)
print(sweep)
```

## Results

### Per-condition signal magnitudes (8 seeds each)

| condition              | final_signal ± SE |
|------------------------|-------------------|
| null (signal_dims = 0) | **0.000** ± 0.000 |
| random, cost = 0       | 1.054 ± 0.005     |
| random, cost = 0.2     | 1.049 ± 0.006     |
| preference, cost = 0   | 1.054 ± 0.005     |
| preference, cost = 0.1 | 1.063 ± 0.006     |
| preference, cost = 0.3 | 1.049 ± 0.006     |

### Contrasts

| contrast                        | Δ                 | t        | verdict  |
|---------------------------------|-------------------|----------|----------|
| preference vs random, no cost   | **0.000 ± 0.008** | **0.00** | **null** |
| preference vs random, mild cost | +0.015 ± 0.009    | +1.63    | marginal |

## Honest interpretation

**All six active conditions converge to the same drift equilibrium** at
signal magnitude ≈ 1.05. Mate-choice mode (random vs preference) makes
no difference. Signal cost (0, 0.1, 0.2, 0.3) makes no difference. Only
the “signal_dims = 0” null is visibly different — signals that don’t
exist don’t drift.

Also replicated at the earlier parameter regime
(`signal_drift_sd = 0.01, mate_choice_strength = 0.7`) with essentially
identical result: all conditions converged to magnitude ≈ 0.22, no
differentiation. The finding is robust across two parameter regimes.

### Why this happens — kernel diagnosis

clade’s per-agent signal vector drifts at rate `signal_drift_sd` per
tick via `signal_evolution_drift = TRUE`. The equilibrium magnitude is
set by the balance of (a) per-tick mutational variance and (b) the
signal-dimensional L1 norm convergence — both independent of mate
choice. Mate-choice by preference *selects* which signals survive to
reproduce, but can’t push the population mean away from the drift
attractor faster than drift itself.

The same pattern was independently documented in the `s-signals`
fidelity audit (Session 1 of the primary-citation audit): signal
magnitude was flat across the whole tested cost range. This Fuller
reproduction confirms it from a second angle.

### What this means for Fuller 2005’s question

clade’s current kernel cannot provide quantitative evidence for or
against Fuller’s sensory-bias-vs-Fisher synthesis, because **no
mechanism we tested produces measurable signal elaboration**. That’s an
honest kernel-level limit, not a Fuller-is-wrong-in-clade finding.

### What clade would need to test Fuller directly

Three kernel changes that would enable a proper Fuller 2005
reproduction:

1.  **Per-agent signal trait logging** — expose signal and preference
    vectors in
    [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
    so direction-alignment can be measured over time.
2.  **Cost-selected drift** — replace uniform per-tick `signal_drift_sd`
    with cost-modulated drift so `signal_cost > 0` measurably compresses
    the drift kernel.
3.  **Correlated sensory-preference trait** — Fuller’s central claim
    needs an explicit genetic-correlation parameter between the sensory
    apparatus (foraging-relevant) and preference (mating-relevant)
    traits. clade’s BNN brain treats these as domain-general —
    pre-Fuller in design.

None of the three are prohibitive. A 0.7+ kernel pass could enable the
full reproduction. Until then, the Fuller vignette remains a documented
honest null.

## Methodology takeaway

This vignette models the **third common outcome** catalogued in the
[paper-reproduction
template](https://itchyshin.github.io/clade/articles/paper-template.md)
and the pattern of outcomes across the showcase:

> When clade’s kernel can’t differentiate the mechanisms the paper
> describes, the honest null IS the finding. Don’t force a clean ✅ by
> cherry-picking parameters that separate conditions for spurious
> reasons.

It pairs nicely with the s-signals ⚠️ verdict (same underlying finding,
documented earlier) and with the Courchamp 1999 vignette’s “check what
clade already does before building custom extensions” advice: both
highlight that the first step of an in-silico reproduction is verifying
the substrate can carry the question.

## Pattern across the 7-paper showcase

| Outcome                         | Examples                        |
|---------------------------------|---------------------------------|
| Clean ✅                        | Dieckmann & Doebeli 1999        |
| Conditional ✅                  | Réale 2010 (lifespan-only)      |
| Direction-correct sub-threshold | Griesser 2023, Courchamp 1999   |
| Raw-inverts-on-per-capita       | Emlen 1982                      |
| Mechanism-level contradiction   | K&B 2003                        |
| **Kernel-level honest null**    | **Fuller 2005** (this vignette) |

Seven papers × six outcome patterns = researchers can template-match
their own paper to the closest example and follow that workflow.

## Citation

``` bibtex
@article{fuller2005sensory,
  author  = {Fuller, Rebecca C. and Houle, David and Travis, Joseph},
  title   = {Sensory bias as an explanation for the evolution of mate preferences},
  journal = {American Naturalist},
  volume  = {166},
  number  = {4},
  pages   = {437--446},
  year    = {2005},
  doi     = {10.1086/444443}
}

@article{ryan1990sexual,
  author  = {Ryan, M. J.},
  title   = {Sexual selection, sensory systems and sensory exploitation},
  journal = {Oxford Surveys in Evolutionary Biology},
  volume  = {7},
  pages   = {157--195},
  year    = {1990}
}

@article{ryan1990tungara,
  author  = {Ryan, M. J. and Fox, J. H. and Wilczynski, W. and Rand, A. S.},
  title   = {Sexual selection for sensory exploitation in the frog
             {\emph{Physalaemus pustulosus}}},
  journal = {Nature},
  volume  = {343},
  pages   = {66--67},
  year    = {1990},
  doi     = {10.1038/343066a0}
}

@article{endler1998sensory,
  author  = {Endler, J. A. and Basolo, A. L.},
  title   = {Sensory ecology, receiver biases and sexual selection},
  journal = {Trends in Ecology \& Evolution},
  volume  = {13},
  number  = {10},
  pages   = {415--420},
  year    = {1998},
  doi     = {10.1016/S0169-5347(98)01471-2}
}
```

Full audit protocol and raw outputs:
[dev/audit/fidelity/paper_fuller_2005.R](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/paper_fuller_2005.R)
and `paper_fuller_2005.rds`.
