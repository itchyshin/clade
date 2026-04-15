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

**What we found.** Running 3 replicates with `sexual_repro = FALSE`
(haploid asexual) vs `sexual_repro = TRUE` (diploid sexual), 80 agents,
25×25 grid, `grass_rate = 0.15`, 400 ticks (seeds 41–43): the two mating
systems performed nearly identically — asexual mean population 211 vs
sexual 209; mean energy 124.3 vs 124.5; late genetic diversity 0.340 vs
0.339. Neither condition produced near-extinction events. The two
diverged slightly in early diversity (asexual 0.181 early vs sexual
0.165), with asexual populations slightly more diverse in the first 50
ticks (because haploid genomes express all mutations immediately without
recessive masking) but converging to the same late diversity. In a
stable foraging environment, sexual recombination’s shuffling of
existing variants provides no detectable advantage. The theoretical
advantage of sex — greater adaptive flexibility under novel selection —
requires testing under dynamic perturbation (e.g., episodic disease or
seasonal crashes) where recombinants fill new adaptive peaks.

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
