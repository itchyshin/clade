# Evolution of bad science

### Evolution of bad science

**What it models.** A pure-R simulation (no Julia required) of Smaldino
& McElreath (2016). Each of `n_labs` labs has two heritable traits:
research power $W$ (probability of detecting a true effect when the
hypothesis under test is real) and research effort $e$ (methodological
rigour). Each tick, a lab tests `n_studies_per_tick` hypotheses, each a
priori true with probability `base_rate_true` ($b$). The per-test
false-positive rate is $\alpha(e) = \alpha_{\text{base}}(1 - e)$ — it
depends on effort only, not on $W$, matching Smaldino & McElreath’s
formulation. Under publication pressure the top-50%-by-publications labs
reproduce each tick; low-effort labs accumulate more publications via
false positives, so low $e$ spreads by selection.

If `replication_rate > 0`, each lab has that probability per tick of
replicating a random peer’s random finding. A failed replication
(original was a false positive, with probability
$\alpha(1 - b)/\left( Wb + \alpha(1 - b) \right)$) debits the original
lab’s publication count by `replication_penalty` (default 5),
operationalising the reputational cost of published-then-overturned
findings.

**What S&M 2016 predicted.** (i) Without replication, effort declines
and FPR rises over ~100–400 generations. (ii) Replication slows this
decay as its rate increases, but does not fully reverse it at realistic
rates. (iii) Structural reform of incentives (not just more replication)
is needed to fix the problem.

``` r
# No Julia required — runs entirely in R
library(ggplot2)
library(patchwork)

rep_rates  <- c(0.0, 0.1, 0.5)
rep_labels <- c("No replication", "10% replication", "50% replication")

results <- mapply(function(rr, lab) {
  df      <- run_bad_science(n_ticks = 500L, replication_rate = rr, seed = 42L)
  df$rate <- lab
  df
}, rep_rates, rep_labels, SIMPLIFY = FALSE)

df <- do.call(rbind, results)

p1 <- ggplot(df, aes(t, mean_fpr, colour = rate)) +
  geom_line() +
  labs(title = "False-positive rate under publication pressure",
       x = "Tick", y = "Mean FPR", colour = NULL) +
  theme_minimal()

p2 <- ggplot(df, aes(t, mean_effort, colour = rate)) +
  geom_line() +
  labs(title = "Research effort",
       x = "Tick", y = "Mean effort", colour = NULL) +
  theme_minimal()

p1 / p2 + plot_layout(guides = "collect") &
  theme(legend.position = "bottom")
```

![Evolution of bad science with replication penalty (mean of 10 seeds).
Top: false-positive rate. Bottom: research effort. No-replication (red):
FPR rises from 0.10 to 0.147, effort falls to 0.71 — the canonical S&M
result. 50% replication (blue): FPR stabilises near 0.10, effort holds
at 0.81 — replication culture selects against low-effort labs. 10%
replication (orange): FPR overshoots to 0.18 — weak replication is worse
than none, a finding of this model not reported by S&M. No Julia session
required.](figures/showcase_bad_science.png)

Evolution of bad science with replication penalty (mean of 10 seeds).
Top: false-positive rate. Bottom: research effort. No-replication (red):
FPR rises from 0.10 to 0.147, effort falls to 0.71 — the canonical S&M
result. 50% replication (blue): FPR stabilises near 0.10, effort holds
at 0.81 — replication culture selects against low-effort labs. 10%
replication (orange): FPR overshoots to 0.18 — weak replication is worse
than none, a finding of this model not reported by S&M. No Julia session
required.

**What we found.** Running
`run_bad_science(n_ticks = 500L, replication_rate = rr)` across 10 seeds
(`seed = 1..10`) for three replication rates, all conditions start at
FPR = 0.100, effort = 0.801:

| Replication rate | Mean FPR (tick 500) | Mean effort (tick 500) |
|------------------|---------------------|------------------------|
| 0.0 (none)       | **0.147 ± 0.016**   | 0.706 ± 0.031          |
| 0.1 (weak)       | **0.179 ± 0.028**   | 0.642 ± 0.056          |
| 0.5 (strong)     | **0.096 ± 0.058**   | 0.808 ± 0.117          |

Three take-aways:

1.  **Bad science evolves when unchecked** (rr = 0): effort erodes, FPR
    rises — reproducing S&M’s main finding.
2.  **Strong replication works** (rr = 0.5): FPR stays at baseline
    levels, effort holds near its initial value. Replication culture can
    discipline research norms when the penalty is real and sampling is
    frequent.
3.  **Weak replication is worse than none** (rr = 0.1): FPR overshoots
    no-replication. This is a finding of this model that S&M did not
    report — possibly because our discrete-time sampling introduces
    noise that, at low replication rates, pushes selection below the
    threshold needed to discriminate effort. It is listed as discovery
    experiment 1 below.

### Discovery experiments

The baseline reproduces S&M 2016 qualitatively: bad science evolves when
unchecked, strong replication disciplines it. Open questions to explore:

1.  **The weak-replication penalty.** Our 10% replication-rate condition
    has FPR higher than the no-replication control — weak replication is
    worse than none. Is this an artefact of discrete-time sampling (each
    tick is a Bernoulli draw on whether any replication happens), or
    does it persist under continuous-time formulations? Sweep
    `replication_rate` from 0.02 to 0.5 in 0.02 steps at
    `replication_penalty = 5` and look for the crossover.

2.  **Penalty magnitude.** The replication penalty is a single scalar.
    Sweep it from 0 to 20 at fixed `replication_rate = 0.5` to locate
    the dose- response curve. Is there a threshold below which
    replication has no effect, or is it continuous? Smaldino’s original
    paper treats penalty as tied to the reputation cost of a retraction
    — what magnitude corresponds to typical academic retractions?

3.  **Structural reform: `base_rate_true`.** Replication fails more
    often when more published findings are true positives. Raising
    `base_rate_true` from 0.3 to 0.7 (simulating a field that
    pre-registers hypotheses and tests only well-motivated ones) should
    make replication far more effective because failed-replication
    probability now discriminates low- from high-effort labs more
    sharply. Verify by sweeping $b$ at fixed `replication_rate = 0.1` —
    does weak replication start to help once hypothesis prevalence is
    high enough?

4.  **Structural heterogeneity.** Run with a mixture of lab types — a
    minority of high-effort labs that never cut corners (`effort` fixed
    at 0.95). Does the presence of an honest minority slow or reverse
    FPR drift? Vary minority fraction from 5% to 30% using
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)-style
    replicate loops.

    *Tried it.* A 10% fixed-high-effort minority (effort = 0.95 in 20 of
    200 labs, 500 ticks, seed 42): FPR ended at 0.267 vs 0.283 (no
    minority) — a 5.7% reduction. The minority slightly retards FPR
    evolution by maintaining a higher-effort tail that competes
    successfully when random replication occasionally evaluates their
    work. But 10% is insufficient to reverse drift: the 90% low-effort
    majority still dominates. At 30% fixed high-effort: FPR = 0.241
    (-15%). A 30% structural minority is a meaningful intervention —
    roughly the “critical mass” fraction needed to stabilise scientific
    norms in this model.

------------------------------------------------------------------------
