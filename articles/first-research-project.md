# Your first research project with clade

*An end-to-end walkthrough: hypothesis → baseline → modifications →
multi-seed sweep → viability check → analysis → publication-quality
plot. Read this after [Getting
started](https://itchyshin.github.io/clade/articles/getting-started.md)
when you want to move from “ran the baseline” to “produced a result I
could cite”.*

------------------------------------------------------------------------

## A worked example: Hamilton’s rule under neonatal foraging deficit

Let’s say you have a specific question: **does Hamilton’s rule for
cooperation still predict the evolution of helping when offspring are
unable to forage at full efficiency at birth?** The neonatal foraging
deficit hypothesis (Aiello & Wheeler 1995; Isler & van Schaik 2009)
argues that altricial offspring create an energetic crisis that makes
parental or kin-based provisioning essential. So the empirical question
becomes: does helping evolve *more readily* when the neonatal deficit is
active?

This is the kind of mechanistic question clade is built for. Here’s how
you’d answer it.

------------------------------------------------------------------------

## Step 1 — Pick a baseline scenario

Every research project should start from an audited baseline. Browse
[Scenarios](https://itchyshin.github.io/clade/articles/scenarios.md) and
find the closest match to your question. For our kin-selection question,
start with
[`s-kin`](https://itchyshin.github.io/clade/articles/s-kin.md) — which
already reproduces Hamilton’s rule under default conditions.

``` r
library(clade)

# The baseline: audited to reproduce Hamilton 1964 / Hamilton's rule
specs <- default_specs()
specs$kin_selection       <- TRUE
specs$cooperation_evolution <- TRUE
```

Always confirm the baseline runs and reproduces the expected result
before modifying it. Copy the audit script from the
`dev/audit/fidelity/` directory on GitHub if you want the exact
published configuration.

------------------------------------------------------------------------

## Step 2 — Define your modification

For this question, add the neonatal foraging deficit. Consult the
[Parameter
reference](https://itchyshin.github.io/clade/articles/parameter-reference.md)
for the exact flag name:

``` r
# Active neonatal foraging deficit: young agents forage at 50% of adult rate
# until they graduate at t_graduation ticks old
specs$neonatal_foraging_deficit <- 0.5
specs$parental_care             <- TRUE    # required for offspring to survive the deficit
```

Now create a second specs list for the null comparison (deficit off):

``` r
specs_null            <- specs
specs_null$neonatal_foraging_deficit <- 0.0
# `parental_care` can stay on to hold that variable constant
```

------------------------------------------------------------------------

## Step 3 — Run a multi-seed sweep

A single run is never evidence. Use
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
with at least 8 seeds for a pilot, 16–64 for publication. Keep runs
short while you debug, then scale up once the pipeline is working.

``` r
# Pilot: 8 seeds × 500 ticks per condition — takes a few minutes
pilot_deficit <- batch_alife(
  specs   = specs,
  n_reps  = 8,
  seeds   = 1:8,
  n_cores = 8    # PSOCK backend; see `?batch_alife`
)

pilot_null <- batch_alife(
  specs   = specs_null,
  n_reps  = 8,
  seeds   = 1:8,
  n_cores = 8
)
```

**Important:** mclapply and the Julia kernel don’t compose — PSOCK is
the safe choice.
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
handles this internally; just set `n_cores`. If you see *“all
connections are in use”*, drop `n_cores` below 64.

------------------------------------------------------------------------

## Step 4 — Check viability

Before interpreting any result, confirm both conditions produced
populations that actually persisted and reproduced. A simulation that
crashed after 50 ticks has no signal to report.

``` r
# Attach run data and check
rd_deficit <- lapply(pilot_deficit, get_run_data)
rd_null    <- lapply(pilot_null, get_run_data)

via_deficit <- viability_report(rd_deficit)
via_null    <- viability_report(rd_null)

print(via_deficit)
print(via_null)
```

What to look for:

- **Populations survive**: final `n_agents` \> 10 in most seeds.
- **Heritability is nonzero**: trait variance didn’t collapse.
- **Diversity is positive**: at least a few genetic lineages remain.

If
[`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)
flags failures, your specs are probably too harsh (mortality too high,
food too scarce) or inconsistent (disease on without recovery rate, kin
selection without diploidy). See
[Troubleshooting](https://itchyshin.github.io/clade/articles/troubleshooting.md)
for common fixes.

------------------------------------------------------------------------

## Step 5 — Compute the differential

Hamilton’s rule is about *cooperation evolving* — measure the frequency
of helping-tendency alleles at the end of each run, and compare between
conditions.

``` r
helper_freq <- function(rd) {
  tail(rd$helper_tendency_mean, 1)  # final-tick mean of helper allele freq
}

end_deficit <- sapply(rd_deficit, helper_freq)
end_null    <- sapply(rd_null,    helper_freq)

# Welch's t-test across seeds
t_result <- t.test(end_deficit, end_null)
print(t_result)

# Effect size: Δ ± 2×SE
delta <- mean(end_deficit) - mean(end_null)
se_d  <- sqrt(var(end_deficit)/length(end_deficit) +
              var(end_null)/length(end_null))
cat(sprintf("Δ helper-allele frequency = %+.3f ± %.3f (t = %+.2f)\n",
            delta, 2 * se_d, t_result$statistic))
```

For a Tier-C audit-style report, you want **\|t\| \> 2 at 16+ seeds** in
the predicted direction. If you see \|t\| \< 2 with a pilot of 8, scale
to 16; if it’s still borderline, scale to 32. If the direction is wrong,
the model is telling you something — don’t just chase a bigger sample.

------------------------------------------------------------------------

## Step 6 — Make one clean plot

Publication-quality figures should show the distribution, not just
means. Boxplots + jittered points beat bar charts.

``` r
library(ggplot2)

df <- data.frame(
  helper_freq = c(end_deficit, end_null),
  condition   = rep(c("neonatal deficit", "no deficit"),
                    each = length(end_deficit))
)

ggplot(df, aes(condition, helper_freq)) +
  geom_boxplot(width = 0.3, outlier.shape = NA) +
  geom_jitter(width = 0.08, alpha = 0.6) +
  labs(
    y = "Final helper-tendency allele frequency",
    x = NULL,
    title = "Does neonatal foraging deficit promote the evolution of helping?",
    subtitle = sprintf("8 seeds per condition; Δ = %+.3f ± %.3f (t = %+.2f)",
                       delta, 2 * se_d, t_result$statistic),
    caption = "clade v0.5.18; specs: default_specs() + kin_selection + cooperation + parental_care"
  ) +
  theme_minimal(base_size = 12)
```

Save with
`ggsave("hamiltons_rule_neonatal_deficit.pdf", width = 5, height = 4)`.

------------------------------------------------------------------------

## Step 7 — Write it up

Three sentences is enough for a paper’s methods section:

> *We used clade (v0.5.18; Nakagawa 2026) to simulate populations of
> heritable-genome agents with kin selection, cooperative tendency, and
> parental care enabled. To test whether the neonatal foraging deficit
> (Aiello & Wheeler 1995) promotes the evolution of helping, we ran two
> conditions — `neonatal_foraging_deficit = 0.5` (altricial offspring)
> vs. 0 (no deficit) — each for 8 seeds of 500 ticks. Final
> helper-tendency allele frequencies differed by Δ = +X.XX ± Y.YY (t =
> +Z.Z; p \< 0.05), supporting the prediction that altriciality
> amplifies selection for kin-based provisioning.*

Cite the package:

``` bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```

And — importantly — cite the biological theory you’re testing (Hamilton
1964; Aiello & Wheeler 1995). clade is the instrument; the theory is the
question.

------------------------------------------------------------------------

## What changed from Getting started?

[Getting
started](https://itchyshin.github.io/clade/articles/getting-started.md)
gets you to “ran the baseline”. This walkthrough added:

- **Hypothesis framing**: picking a specific mechanism to test before
  writing any code.
- **Paired conditions**: always have a null to compute a differential.
- **Multi-seed sweep**:
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
  with ≥ 8 seeds; scale up for publication.
- **Viability check**: never interpret a simulation that didn’t actually
  persist.
- **Differential statistic**: Δ ± 2×SE with a t-statistic. Reporting
  “\|t\| \> 2 in the predicted direction across N seeds” is what the
  fidelity audits use, and it’s a defensible standard for your papers.
- **Honest plotting**: show the distribution, not just the mean.

For the next level — parameter sweeps, MAP-Elites, CMA-ES — see the
[Parameter
search](https://itchyshin.github.io/clade/articles/ps-introduction.md)
guides. For deeper modifications (custom per-tick R hooks), see [Custom
modules](https://itchyshin.github.io/clade/articles/custom-modules.md).

------------------------------------------------------------------------

## Common variations of this workflow

- **Compare three conditions** (e.g. low / medium / high deficit): three
  specs lists, three
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
  calls, an ANOVA or a continuous regression. Use `seasonal_amplitude`
  if you want a continuous environmental gradient.
- **Ask a parameter-search question** (“*what deficit intensity
  maximally selects for helping?*”): use
  [`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
  with the helper frequency as the fitness function.
- **Explore a trait space** (“*what combinations of deficit, care, and
  clutch size produce helping?*”): use
  [`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)
  to tile the trait space.
- **Run in a worktree**: for reproducibility, tag your specs list +
  clade version in the output `.rds` filename. Future-you will thank
  you.
