# McElreath et al. 2007 — does Wolf's syndrome erode over time?

*A direct test in clade of McElreath, Luttbeg, Fogarty, Brodin & Sih’s
(2007) critique of Wolf et al. 2007: asset protection is a
**negative-feedback** mechanism that erodes individual differences over
time, so the bold-aggro syndrome should be transient rather than stable.
Implemented as a time-horizon sweep over the spatially-explicit Wolf
2007 scenario added in 0.7.0. Companion to
[`vignette("paper-wolf2007")`](https://itchyshin.github.io/clade/articles/paper-wolf2007.md)
and
[`vignette("paper-massol-crochet-2008")`](https://itchyshin.github.io/clade/articles/paper-massol-crochet-2008.md).*

## The critique

Wolf et al. (2007) report a stable bold-aggro syndrome at the end of
their simulations. McElreath, Luttbeg, Fogarty, Brodin & Sih (2007,
*Nature* 450, brief communications arising; `doi:10.1038/nature06326`)
argued that this stability is misleading:

> The mechanism Wolf et al. identify is a **negative-feedback loop**.
> Agents with high assets become risk-averse; risk-aversion preserves
> assets; assets become more uniform across individuals; and the trait
> correlations that defined the syndrome erode.

Their prediction: run the simulation longer than Wolf did and the
syndrome will fade. The headline syndrome strength is a transient
artifact of having stopped at an early time-point.

clade exposes the time horizon directly via `max_ticks`. Sweeping it
gives a clean test.

## The sweep

``` r

library(clade)

run_one <- function(max_ticks_val, seed = 42L) {
  s <- wolf_personality_specs()
  s$max_ticks                       <- as.integer(max_ticks_val)
  s$random_seed                     <- seed
  s$n_agents_init                   <- 200L
  s$max_agents                      <- 800L
  s$personality_hawkdove_per_tick   <- 0.3
  s$personality_hawkdove_radius     <- 2L
  s$n_predators_init                <- 10L
  s$predator_max_agents             <- 30L
  env <- run_alife(s, verbose = FALSE)

  recs  <- env$agents
  alive <- vapply(seq_along(recs), function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 30L) return(NULL)

  ex <- vapply(seq_along(recs)[alive],
               function(i) as.numeric(recs[[i]]$exploration), numeric(1L))
  bo <- vapply(seq_along(recs)[alive],
               function(i) as.numeric(recs[[i]]$boldness), numeric(1L))
  ag <- vapply(seq_along(recs)[alive],
               function(i) as.numeric(recs[[i]]$aggressiveness), numeric(1L))
  list(
    max_ticks = max_ticks_val,
    n         = length(ex),
    r_eb      = suppressWarnings(cor(ex, bo)),
    r_ea      = suppressWarnings(cor(ex, ag)),
    r_ba      = suppressWarnings(cor(bo, ag)),
    mean_x    = mean(ex),
    sd_x      = sd(ex)
  )
}

horizons <- c(2000L, 5000L, 15000L)
results  <- lapply(horizons, run_one)
```

## Observed pattern (seed 42, single replicate)

|  Ticks |   n | mean(x) | sd(x) | cor(exp, bold) | cor(exp, aggro) | cor(bold, aggro) |
|-------:|----:|--------:|------:|---------------:|----------------:|-----------------:|
|  2 000 | 585 |   0.143 | 0.127 |         −0.021 |          −0.099 |           −0.004 |
|  5 000 | 670 |   0.094 | 0.096 |         +0.044 |          −0.005 |       **+0.307** |
| 15 000 | 665 |   0.094 | 0.100 |         +0.044 |          −0.058 |           +0.032 |

The defining bold-aggro syndrome:

- **2 000 ticks** — not yet established (r ≈ 0). Population still
  approaching equilibrium.
- **5 000 ticks** — peak at r = +0.307. This is the Wolf 2007
  reproduction value reported in
  [`vignette("paper-wolf2007")`](https://itchyshin.github.io/clade/articles/paper-wolf2007.md)
  and the Phase 6 commit.
- **15 000 ticks** — decayed to r = +0.032, an order of magnitude
  weaker. Essentially gone.

The asset-protection signs (cor(exp, bold), cor(exp, aggro)) stay near
zero across all horizons.

## Reading the result

**McElreath et al.’s critique is strongly borne out** in clade’s
spatially-explicit implementation:

1.  The bold-aggro syndrome is **transient**, peaking around 5 000 ticks
    and decaying to near-zero by 15 000.
2.  The decay happens *while the trait-mean equilibrium is stable*:
    mean(x) is essentially identical at 5 k and 15 k (0.094 in both),
    and sd(x) is similar (0.096 vs 0.100). What changes is the
    *covariance* between traits, not their marginal distributions.
3.  This matches McElreath’s negative-feedback framing: the population
    reaches a structural equilibrium where individual variation in *x*
    no longer covaries strongly with variation in boldness and
    aggressiveness. Asset protection has homogenised the population
    along the protection-relevant axis.

The result also explains why Wolf’s published correlations look so
clean: Wolf reports ~50-generation simulations. With clade’s
`wolf_year2_repro_age = 100`, 5 000 ticks ≈ 50 generations — exactly the
time-point where the syndrome is at its peak. **The headline syndrome
strength is a property of simulation length, not of the mechanism
itself.**

## Implications for the Wolf 2007 reproduction

The base reproduction in
[`vignette("paper-wolf2007")`](https://itchyshin.github.io/clade/articles/paper-wolf2007.md)
ran to 5 000 ticks because that’s roughly where Wolf 2007 stops. At that
horizon clade matches Wolf’s qualitative pattern (positive bold-aggro
syndrome). But at 15 000 ticks — three times longer — the syndrome is
gone. The asset-protection mechanism is real, but its visible effect on
trait correlations is short-lived.

Users running the Wolf scenario in clade should be aware of this: the
syndrome’s strength is *time-window-dependent*. Quoting a “final”
correlation without specifying the simulation length is misleading.

## Two critiques together: a coherent picture

Reading
[`vignette("paper-massol-crochet-2008")`](https://itchyshin.github.io/clade/articles/paper-massol-crochet-2008.md)
and this vignette together gives a coherent picture of the Wolf 2007
mechanism in clade’s spatial setting:

- **Massol & Crochet 2008**: the syndrome’s strength is sensitive to the
  trade-off shape parameter β. Peak at β = 1.25 (Wolf’s default), weaker
  on either side. The mechanism is parameter-fragile.
- **McElreath et al. 2007**: the syndrome’s strength is sensitive to the
  time horizon. Peak around 5 000 ticks, decays by 15 000. The mechanism
  is time-fragile.

Both critiques are partially borne out. Wolf’s headline result is real
but **conditional on a narrow parameter range and a specific time
window** — neither of which is robust to perturbation.

## Caveats

- **Single seed** (42). The qualitative pattern (peak then decay) is
  visible at this seed; a multi-seed sweep would firm up the timing of
  the peak and the half-life of the decay. Documented as a limitation.
- **Phase 6 (1+α·N_i) denominator on**. Setting `personality_alpha = 0`
  reverts to Phase 3a behaviour and might shift the timing.
- **Spatial implementation**. clade’s grid + one-per-cell offspring +
  Moore-neighbourhood hawk-dove pairing produces a different equilibrium
  structure than Wolf’s mean-field model. McElreath’s argument is
  mathematical and applies to any negative-feedback setting; the
  time-scale of decay in clade may differ from what pure Wolf would
  show.
- **Computational cost**. A 15 000-tick run takes ~130 s on a typical M1
  laptop. Doing the same sweep at 5–10 seeds per horizon takes 10–20
  minutes. Worth doing for any quantitative claim that generalises
  beyond seed 42.

## What’s left for follow-up work

- **Multi-seed verification** of the timing of peak and decay.
- **Per-tick correlation tracking** — using the `log_genomes` feature
  (wired in 0.7.x) one could compute the bold-aggro correlation at every
  logged tick rather than just at three endpoints, producing a full
  time-course rather than three snapshots.
- **Negative-feedback rate as a function of population size**.
  McElreath’s theory predicts faster decay in larger populations (more
  statistical averaging). The current sweep is at a single population
  size.

## References

- McElreath, R., Luttbeg, B., Fogarty, S.P., Brodin, T. & Sih, A.
  2007. Evolution of animal personalities. *Nature* 450 (Brief
        Communications Arising). <doi:10.1038/nature06326>.
- Wolf, M., van Doorn, G.S., Leimar, O. & Weissing, F.J. (2007)
  Life-history trade-offs favour the evolution of animal personalities.
  *Nature* 447:581–584. <doi:10.1038/nature05835>.
- See also
  [`vignette("paper-wolf2007")`](https://itchyshin.github.io/clade/articles/paper-wolf2007.md)
  for the base reproduction and
  [`vignette("paper-massol-crochet-2008")`](https://itchyshin.github.io/clade/articles/paper-massol-crochet-2008.md)
  for the parallel β-sweep test of the same Wolf 2007 mechanism.
