# clade

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Fidelity audit:
32/32](https://img.shields.io/badge/fidelity-32%2F32-brightgreen.svg)](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md)

> **Evolve behaviour, minds, and brains in R — the intraspecific,
> interspecific, and environmental interactions that shape them. 32 / 32
> scenarios audited against primary literature.**

Behaviour, cognition, and social evolution emerge from three classes of
interaction: between members of the same species, between species, and
between organisms and their environment. `clade` is a modular R + Julia
simulator for evolving digital organisms under any combination of those
interactions. Every biological scenario is cross-referenced to a
primary-literature prediction and multi-seed audited; the kernel runs in
Julia so long sweeps stay fast.

------------------------------------------------------------------------

## Three pillars

### 🤝 Intraspecific

How conspecifics shape each other — kin, mates, rivals, allies, tutors.

- Kin selection —
  [`s-kin`](https://itchyshin.github.io/clade/articles/s-kin.md)
- Sexual selection (signals, mate choice) —
  [`s-signals`](https://itchyshin.github.io/clade/articles/s-signals.md),
  [`s-mating-systems`](https://itchyshin.github.io/clade/articles/s-mating-systems.md)
- Cooperation & parental care —
  [`s-cooperation`](https://itchyshin.github.io/clade/articles/s-cooperation.md),
  [`s-parental-care`](https://itchyshin.github.io/clade/articles/s-parental-care.md)
- Group defence & social learning —
  [`s-group-defense`](https://itchyshin.github.io/clade/articles/s-group-defense.md),
  [`s-social-learning`](https://itchyshin.github.io/clade/articles/s-social-learning.md)

### 🦁 Interspecific

How other species shape evolution — predators, parasites, mimics,
competitors.

- Predator–prey dynamics —
  [`s-predator-prey`](https://itchyshin.github.io/clade/articles/s-predator-prey.md),
  [`s-predation-neural`](https://itchyshin.github.io/clade/articles/s-predation-neural.md)
- Müllerian & Batesian mimicry —
  [`s-mimicry`](https://itchyshin.github.io/clade/articles/s-mimicry.md)
- Coevolving parasites (Red Queen) —
  [`s-mating-systems`](https://itchyshin.github.io/clade/articles/s-mating-systems.md)
- Speciation —
  [`s-speciation`](https://itchyshin.github.io/clade/articles/s-speciation.md)

### 🌱 Environment

How physical and ecological niches shape evolution — and how organisms
reshape them back.

- Niche construction —
  [`s-niche`](https://itchyshin.github.io/clade/articles/s-niche.md)
- Phenotypic plasticity & Baldwin effect —
  [`s-plasticity`](https://itchyshin.github.io/clade/articles/s-plasticity.md),
  [`s-baldwin`](https://itchyshin.github.io/clade/articles/s-baldwin.md)
- Complex landscapes & seasonal change —
  [`s-complex-landscape`](https://itchyshin.github.io/clade/articles/s-complex-landscape.md),
  [`s-seasonal`](https://itchyshin.github.io/clade/articles/s-seasonal.md)
- Life history & scavenging —
  [`s-life-history`](https://itchyshin.github.io/clade/articles/s-life-history.md),
  [`s-scavenging`](https://itchyshin.github.io/clade/articles/s-scavenging.md)

**Or combine them.** The Baldwin effect
([`s-baldwin`](https://itchyshin.github.io/clade/articles/s-baldwin.md))
emerges from learning × genetic assimilation under fluctuating
environments. Cephalopod-style long-learning short-life tradeoffs
([`s-cephalopod`](https://itchyshin.github.io/clade/articles/s-cephalopod.md))
require brain size × parental care × life history interacting at once.
Pace-of-life syndromes
([`s-pace-of-life`](https://itchyshin.github.io/clade/articles/s-pace-of-life.md))
need life-history × metabolism × cognition. clade is designed so the
modules compose freely.

------------------------------------------------------------------------

## 32 of 32 scenarios pass

Every biological scenario is cross-referenced to a primary-literature
prediction — Hamilton 1964 (kin selection), Hamilton 1980 (Red Queen),
Williams 1966 (predation demography), Emlen 1982 (cooperative breeding),
Hinton & Nowlan 1987 (Baldwin effect), DeWitt & Scheiner 2004
(plasticity), Isler & van Schaik 2009 (brain cost), and more. All 32
currently pass at t \> 2σ on multi-seed audits. See the [fidelity
dashboard](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md)
for the per-scenario ledger.

------------------------------------------------------------------------

## Quick start

``` r
# install.packages("remotes")
remotes::install_github("itchyshin/clade")

library(clade)
julia_is_ready()              # first call compiles the Julia kernel (~60–90 s)

specs <- default_specs()
specs$n_agents_init <- 40L
specs$max_ticks     <- 300L

env  <- run_alife(specs)
plot_run(get_run_data(env))   # population × energy × diversity dashboard
```

------------------------------------------------------------------------

## Is clade right for your question?

| You want to study…                                                           | Use                                                  | Why not clade                                                                            |
|------------------------------------------------------------------------------|------------------------------------------------------|------------------------------------------------------------------------------------------|
| Behaviour, cognition, and social evolution with heritable neural genomes     | **clade**                                            | —                                                                                        |
| Genome-scale population genetics with realistic recombination and demography | **[SLiM](https://messerlab.org/slim/)**              | clade’s genome is neural-network weights, not chromosomal loci                           |
| Coalescent / tree-sequence inference                                         | **[msprime](https://tskit.dev/msprime/)**            | clade is forward-time, phenotype-first                                                   |
| Teaching discrete-generation IBMs in a classroom browser                     | **[NetLogo](https://ccl.northwestern.edu/netlogo/)** | clade assumes a working R + Julia toolchain                                              |
| Generic ABM (markets, traffic, opinion dynamics)                             | **[Mesa](https://mesa.readthedocs.io/)**             | clade’s primitives (genome, fitness, meiosis) are evolutionary-biology-specific          |
| Phenotype–environment-match models (e.g. Burke et al. 2020)                  | **custom NetLogo / Python**                          | clade’s fitness is emergent from foraging + survival, not a matching function you define |
| Epidemiology as the primary modelling target                                 | specialised epi frameworks                           | clade has a SIR `disease` module, but it’s a tool, not the target                        |

------------------------------------------------------------------------

## Go deeper

- [**Getting
  started**](https://itchyshin.github.io/clade/articles/getting-started.md)
  — install, first run, extracting results
- [**Scenarios**](https://itchyshin.github.io/clade/articles/scenarios.md)
  — all 36 vignettes by theme
- [**Parameter
  reference**](https://itchyshin.github.io/clade/articles/parameter-reference.md)
  — every field in
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
- [**Custom
  modules**](https://itchyshin.github.io/clade/articles/custom-modules.md)
  — write your own per-tick R hooks with
  [`register_module()`](https://itchyshin.github.io/clade/reference/register_module.md)
- [**Kernel as
  biology**](https://itchyshin.github.io/clade/articles/k-README.md) —
  how the Julia kernel maps onto biological mechanism

------------------------------------------------------------------------

## Citation

``` bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```

License: [MIT](https://opensource.org/licenses/MIT).
