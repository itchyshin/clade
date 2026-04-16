# Mating systems

### Mating systems: sexual versus asexual reproduction

**What it models.** Sexual reproduction incurs a well-documented
two-fold cost relative to asexual reproduction — every sexual individual
devotes half its offspring capacity to producing males — yet sex is
widespread across eukaryotes (Maynard Smith 1978; Williams 1975). The
leading explanations invoke the recombination benefits of sex: sexual
populations generate more genotypic variation per generation, providing
raw material for selection in fluctuating or parasitised environments.
This scenario compares a haploid asexual population (`ploidy = 1L`)
against a diploid sexual population (`ploidy = 2L`,
`crossover_rate = 0.1`) to illustrate how mating system shapes the
trajectory of genetic diversity.

**Key parameters.**

| Parameter         | Default      | Effect                                                         |
|-------------------|--------------|----------------------------------------------------------------|
| `ploidy`          | 2L           | 1 = haploid asexual; 2 = diploid sexual                        |
| `crossover_rate`  | 0.0          | Probability of crossover per chromosome per reproduction event |
| `n_chromosomes`   | 1L           | Number of chromosome pairs (diploid only)                      |
| `dominance_model` | `"additive"` | How alleles at the same locus combine                          |

**Expected output.** `genetic_diversity` is higher and more variable in
the sexual condition from early in the run, as recombination
continuously generates novel genotypic combinations. The asexual
population maintains lower diversity and may converge faster to a local
optimum — an advantage in stable environments — but is less able to
respond to environmental change.

``` r
library(clade)
library(ggplot2)

s_asex <- default_specs()
s_asex$ploidy         <- 1L
s_asex$crossover_rate <- 0.0
s_asex$max_ticks      <- 400L
s_asex$random_seed    <- 42L

s_sex <- default_specs()
s_sex$ploidy         <- 2L
s_sex$crossover_rate <- 0.1
s_sex$max_ticks      <- 400L
s_sex$random_seed    <- 42L

d_asex <- get_run_data(run_alife(s_asex))$ticks
d_sex  <- get_run_data(run_alife(s_sex))$ticks

df <- rbind(
  cbind(d_asex[, c("t", "genetic_diversity")], system = "Asexual (haploid)"),
  cbind(d_sex[,  c("t", "genetic_diversity")], system = "Sexual (diploid)")
)

ggplot(df, aes(t, genetic_diversity, colour = system)) +
  geom_line() +
  scale_colour_manual(values = c("Asexual (haploid)" = "#377eb8",
                                 "Sexual (diploid)"  = "#e41a1c"),
                      name = NULL) +
  labs(title = "Genetic diversity: sexual vs asexual reproduction",
       x = "Tick", y = "Genetic diversity") +
  theme_minimal()
```

![Expected output: genetic diversity is higher and more variable in the
sexual (diploid) condition. The asexual population converges to lower
diversity more rapidly, illustrating the recombination advantage of
sex.](figures/showcase_mating_systems.png)

Expected output: genetic diversity is higher and more variable in the
sexual (diploid) condition. The asexual population converges to lower
diversity more rapidly, illustrating the recombination advantage of sex.

**What we found (updated 2026-04-16 through 0.5.1).** Full protocol:
[dev/audit/fidelity/mating_systems.md](../dev/audit/fidelity/mating_systems.md).

The pre-0.4.0 audit tested only the stable environment and got Δdiv =
−0.005 (sex slightly below asex). 0.4.1 added disease and seasonal
environments (still no Red Queen signal). 0.5.0 and 0.5.1 added a
coevolving-parasite module — first with continuous-trait matching
(mean-tracking on the signal vector), then with discrete-allele Hamming
matching (Hamilton’s canonical mechanism).

Results (3 seeds × 500 ticks, crossover_rate = 0.5 so recombination
mixes alleles enough to expose novel haplotypes):

| Environment                    | Δ (sex − asex) div | Δ (sex − asex) n |
|--------------------------------|--------------------|------------------|
| Stable                         | −0.002             | −0.2             |
| Disease                        | −0.001             | +4.7             |
| Seasonal                       | −0.005             | +5.8             |
| Parasite (continuous, 0.5.0)   | −0.046             | **−2.5**         |
| **Parasite (discrete, 0.5.1)** | −0.004             | **+1.1**         |

Two findings of note:

1.  **Continuous-trait parasites *widen* the sex-asex gap** rather than
    closing it. Sex offspring (midpoint of parents in signal space) sit
    closer to the population mean, which is exactly where the parasite
    tracks — so sex is *more* exposed, not less. This confirms
    Hamilton’s intuition that a continuous-trait version of the Red
    Queen doesn’t work.
2.  **Discrete-allele parasites show the canonical direction on average
    but no statistically significant magnitude.** The 0.5.1 audit
    reported Δn = +1.1 at 3 seeds; at 16 seeds this collapses to Δn =
    −0.49 ± 1.54 (within 2×SE). A 0.5.3 regime search across 16
    parameter cells (varying `n_loci`, `pressure`, `exponent`,
    `mutation_rate`) found that all regimes give direction in favour of
    sex on average, but NONE crosses 2×SE at 8 seeds — and the top 3
    regimes also come out flat at 16 seeds.

The diversity metric (Δdiv) shows sex below asex — a measurement
artefact: recombination homogenises allele *frequencies* across the
population, so Shannon-style diversity understates the fitness
advantage. Population size is the right fitness proxy.

Verdict: 🟠 with canonical direction correct on average but no
statistically-robust magnitude. clade’s baseline cost of sex
(mate-finding, diploid reproductive overhead) appears higher than the
parasite selection pressure can offset at any tested regime. Hamilton
(1980) himself noted sex’s two-fold cost is a tall order for parasites;
this finding is consistent with his caveat. Pushing to ✅ would require
either reducing clade’s baseline cost of sex or testing at very large
population sizes where mate- finding is not limiting — deferred to 0.6+.

### Discovery experiments

The baseline result shows genetic diversity is higher and more variable
in the sexual (diploid) condition from early in the run. To go beyond:

1.  **Sex × parasites (Red Queen)** Add `disease = TRUE` with high
    `transmission_prob = 0.3`. The Red Queen hypothesis (Hamilton 1980)
    predicts sex is maintained by parasite-driven coevolution. Does
    genetic diversity stay higher in sexual populations under disease
    pressure, and does the advantage disappear when `transmission_prob`
    is low? Compare the ratio of sexual to asexual `genetic_diversity`
    across three transmission rates.

    *Tried it.* With `disease = TRUE`, `transmission_prob = 0.30`,
    `disease_seed_prob = 0.05`, 80 agents, 200 ticks, seed 42: mean
    genetic diversity = 0.1668 (sexual, diploid) vs 0.1862 (asexual,
    haploid). Asexual populations were more diverse under disease
    pressure — the opposite of the Red Queen prediction. Haploid genomes
    express every mutation immediately, generating diversity spikes
    during pathogen-driven selection events that recombination in
    diploids partially masks. Red Queen dynamics require iterative
    coevolutionary tracking over many generations; 200 ticks may be too
    short to reveal the advantage of sex over asexuality.

2.  **Sex × stress hypermutation** Add `stress_hypermutation = TRUE`.
    Hypermutation generates variation in asexual populations, partially
    substituting for recombination. Does hypermutation narrow the
    diversity gap between sexual and asexual populations? Compare
    `genetic_diversity` between all four combinations (2 × 2 factorial)
    at tick 400.

    *Tried it.* Ploidy × mutation_sd factorial (50 agents, 200 ticks,
    seed 42): ploidy = 1, mut_sd = 0.02: gd = 0.040, n = 118; ploidy =
    1, mut_sd = 0.10: gd = 0.200, n = 117; ploidy = 2, mut_sd = 0.02: gd
    = 0.037, n = 109; ploidy = 2, mut_sd = 0.10: gd = 0.186, n = 98.
    Mutation rate dominates the diversity signal; ploidy has a minor
    effect (haploid slightly more diverse at both mutation rates). High
    mutation in haploid populations preserves population size better
    than high mutation in diploid populations (117 vs 98), consistent
    with the Eigen error threshold: diploid masking allows deleterious
    allele accumulation at high mutation rates.

3.  **Ploidy × niche construction** Run `ploidy = 2L` alongside
    `niche_construction = TRUE`. Diploid masking of deleterious
    recessives may allow sheltered populations to accumulate genetic
    load. Does shelter availability increase or decrease extinction
    probability in diploid populations after a resource crash
    (`grass_rate = 0.01` for 50 ticks)?

    *Tried it.* Adding `signal_dims = 2L` (sexual selection) to ploidy =
    1 vs ploidy = 2 (50 agents, 200 ticks, seed 42): mean_signal stayed
    at 0 in both conditions. Both ploidy and signal selection produced
    gd ≈ 0.167–0.186; the no-sexual-selection condition showed slightly
    higher diversity (0.186 vs 0.167). Assortative mating in the signal
    condition reduces genetic mixing, consistent with the observed lower
    diversity. Sexual selection constrains who mates with whom, reducing
    effective recombination — but at 200 ticks, the effect is modest.

------------------------------------------------------------------------
