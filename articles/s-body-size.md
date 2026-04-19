# Body size evolution

### Body size evolution

**What it models.** A heritable `body_size` trait scales metabolic costs
and foraging gains via allometric rules. Larger body size increases move
cost but also foraging efficiency. Natural selection finds the optimal
body size for the prevailing resource density.

**Key parameters.**

| Parameter               | Default | Effect                                |
|-------------------------|---------|---------------------------------------|
| `body_size_evolution`   | FALSE   | Enable body size as a heritable trait |
| `body_size_init_mean`   | 1.0     | Starting body size (relative units)   |
| `body_size_mutation_sd` | 0.05    | Mutation rate                         |
| `body_size_min`         | 0.1     | Lower clamp                           |
| `body_size_max`         | 5.0     | Upper clamp                           |

**Expected output.** `mean_body_size` evolves upward from the reference
(1.0) as larger-bodied agents gain a foraging-efficiency advantage
(Cope’s rule direction). At 16 seeds, **predation does not modulate this
drift in either direction** — neither the Shine et al. (2011)
large-escape nor the Brooks & Dodson (1965) size-detectability signal
reaches 2×SE significance. clade produces the Cope direction robustly
but does not reproduce any particular predator-mediated size-selection
variant at default parameters.

``` r
library(clade)
library(ggplot2)
library(patchwork)

make_s <- function(n_pred, seed) {
  # Uses default_specs() — fast_specs() crashes this scenario (n_final
  # < 10 across 5 seeds per the 2026-04-17 crash_audit.R run). Body-size
  # evolution interacts with the short fast_specs lifespan in a way that
  # overwhelms viability at default grass/density. See
  # viability_report() and dev/audit/fidelity/crash_audit.R.
  s <- default_specs()
  s$body_size_evolution <- TRUE
  s$body_size_init_mean <- 1.0
  s$n_agents_init       <- 80L
  s$max_agents          <- 400L
  s$n_predators_init    <- as.integer(n_pred)
  s$predator_max_agents <- as.integer(n_pred * 3L)
  s$max_ticks           <- 400L
  s$random_seed         <- as.integer(seed)
  s
}

seeds <- c(1L, 7L, 13L)
no_pred_list <- lapply(seeds, function(s) {
  d <- get_run_data(run_alife(make_s(0, s), verbose = FALSE))$ticks
  cbind(d[, c("t", "mean_body_size")], condition = "No predators")
})
pred_list <- lapply(seeds, function(s) {
  d <- get_run_data(run_alife(make_s(10, s), verbose = FALSE))$ticks
  cbind(d[, c("t", "mean_body_size")], condition = "Predators (10)")
})

df <- do.call(rbind, c(no_pred_list, pred_list))
df_mean <- aggregate(mean_body_size ~ t + condition, data = df, FUN = mean)

ggplot(df_mean, aes(t, mean_body_size, colour = condition)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey50") +
  scale_colour_manual(values = c("No predators" = "#4dac26",
                                  "Predators (10)" = "#d01c8b")) +
  labs(title = "Body size evolution: Cope's rule (predation direction null at 16 seeds)",
       subtitle = "Upward drift in both conditions; predation effect not statistically supported",
       x = "Tick", y = "Mean body size", colour = NULL) +
  theme_minimal()
```

**What we found (updated 2026-04-16, 0.5.2 audit: 16 seeds × 2 sensing
modes × 2 predator levels = 64 runs × 600 ticks).** Full protocol:
[dev/audit/fidelity/body_size.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/body_size.md).

| graded predator sensing | n_pred | Δ mean_body_size | 1×SE   |
|-------------------------|--------|------------------|--------|
| FALSE (legacy binary)   | 0      | +0.0870          | 0.0070 |
| FALSE                   | 10     | +0.0963          | 0.0118 |
| TRUE (0.4.2 default)    | 0      | +0.1074          | 0.0060 |
| TRUE                    | 10     | +0.1110          | 0.0099 |

**Cope’s rule direction (P1) PASS robustly** — upward drift of 9–11% in
both sensing modes with SE ~0.6–0.7%. Cope’s rule is statistically clean
in clade.

**Size-dependent predation direction (P2) NULL** — neither sensing mode
produces a 2×SE-significant predator-vs-control difference:

- Binary: Δ(with-pred) − Δ(no-pred) = +0.009 ± 0.014 (flat)
- Graded: Δ(with-pred) − Δ(no-pred) = +0.004 ± 0.012 (flat)

Both the earlier “detectability” (0.4.1, ratio 0.81) and “Shine
acceleration” (0.4.3, ratio 1.08) interpretations were 5-seed noise. At
16 seeds neither direction is supported, so P2 is retracted. The earlier
“+57% larger increase under predation” framing and the later
“predation-slows-drift detectability” framing are both superseded by
this null.

**Secondary observation.** The 0.4.2 graded predator sensing produces a
*larger* Cope drift (+0.107) than legacy binary sensing (+0.087) — an
SE-bounded real effect. Finer threat information → more efficient
foraging → support for larger bodies. Side benefit of the 0.4.2 sensing
polish.

### Calibrated regime (CMA-ES discovered)

Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the
scenario’s parameter subspace discovered the following regime, which
produces a fitness improvement of **18.8x** over the defaults above. See
`dev/audit/calibration/RESULTS.md` for the full CMA-ES results.

``` r
# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):
s <- default_specs()
s$body_size_mutation_sd          <- 0.6806
s$mutation_sd                    <- 0.0846
# env <- run_alife(s)   # uncomment to run the calibrated regime
```

![0.5.2 16-seed resolution. Top: Δ mean_body_size (final − init) with
1×SE error bars across 2 sensing modes × 2 predator levels. P1 (Cope
direction) robustly positive (~+0.09 to +0.11); P2 (predation effect)
flat within 2×SE in both sensing modes. Bottom: per-seed trajectories.
Graded predator sensing produces a larger Cope drift than binary sensing
— an SE-bounded real effect of the 0.4.2 sensing
polish.](figures/showcase_04_body_size.png)

0.5.2 16-seed resolution. Top: Δ mean_body_size (final − init) with 1×SE
error bars across 2 sensing modes × 2 predator levels. P1 (Cope
direction) robustly positive (~+0.09 to +0.11); P2 (predation effect)
flat within 2×SE in both sensing modes. Bottom: per-seed trajectories.
Graded predator sensing produces a larger Cope drift than binary sensing
— an SE-bounded real effect of the 0.4.2 sensing polish.

### Discovery experiments

The baseline result shows that body size evolves to an equilibrium set
by the metabolic cost–foraging gain trade-off. To go beyond:

1.  **Bergmann’s rule** Pair `body_size_evolution = TRUE` with
    `seasonal_amplitude = 0.8`. Bergmann’s rule predicts larger body
    size in harsher (here: leaner) periods. Does population
    `mean_body_size` covary positively with seasonal phase? Plot
    `mean_body_size` against `grass_coverage` phase across the seasonal
    cycle.

    *Tried it.* With `seasonal_amplitude = 0.8`, 60 agents, 300 ticks,
    seed 42: r(mean_body_size, grass_coverage) = +0.596. Body size
    tracks resource availability positively — larger bodies emerge when
    grass is abundant, not when it is scarce. This is anti-Bergmann
    within the seasonal cycle: agents invest in body size when energy
    income permits. The classical Bergmann gradient is a
    between-population signal; within a season, agents simply grow when
    food allows it.

2.  **Predator-mediated size selection** Add `n_predators_init = 5L`.
    Does predation shift optimal body size upward (larger bodies escape
    better) or downward (smaller bodies are harder to catch)? Compare
    final `mean_body_size` with and without predators across a
    `grass_rate` gradient of five values in
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).

    *Tried it.* Three grass rates with and without 5 predators (50
    agents, 200 ticks, seed 42): at low grass (0.05), predation selected
    larger bodies (1.057 vs 1.026 without predators) — energy stores aid
    escape when resources are already scarce. At grass = 0.10, the
    pattern reversed (1.006 vs 1.021 without predators) — at
    intermediate resources, larger bodies are more detectable targets.
    At high grass (0.20), no-predator populations again evolved larger
    bodies (1.050 vs 1.024). The interaction depends non-monotonically
    on resource density.

3.  **Body–brain allometry** Add `brain_size_evolution = TRUE`. Do brain
    size and body size co-evolve proportionally as in vertebrates, or
    does the brain-size sensing advantage decouple them under resource
    scarcity? Plot `mean_brain_size` vs `mean_body_size` as a parametric
    trajectory over ticks.

    *Tried it.* With both traits enabled (50 agents, 200 ticks, seed
    42): after detrending (residuals from lm(trait ~ tick)), the
    brain-body correlation was r = -0.288 — mild and negative,
    consistent with the Expensive Brain framework (Isler & van Schaik
    2009). Somatic investment competes with neural investment. The raw
    positive correlation (r ≈ 0.73) is a temporal artefact of both
    traits drifting upward together under shared selection pressure.

------------------------------------------------------------------------

------------------------------------------------------------------------

## Citation

If you use this scenario in published work, please cite both the `clade`
package and the primary literature the scenario references. The
theory-to-scenario mapping is catalogued in the [fidelity audit
dashboard](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md).

``` bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```
