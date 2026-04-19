# clade

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Fidelity audit: 32/32](https://img.shields.io/badge/fidelity-32%2F32-brightgreen.svg)](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md)

> **Evolve behaviour, minds, and brains in R — the intraspecific, interspecific, and environmental interactions that shape them. 32 / 32 scenarios audited against primary literature.**

Behaviour, cognition, and social evolution emerge from three classes of
interaction: between members of the same species, between species, and
between organisms and their environment. `clade` is a modular R + Julia
simulator for evolving digital organisms under any combination of those
interactions. Every biological scenario is cross-referenced to a
primary-literature prediction and multi-seed audited; the kernel runs
in Julia so long sweeps stay fast.

---

## Three pillars

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 1rem;">

<div markdown="1">

### 🤝 Intraspecific

How conspecifics shape each other — kin, mates, rivals, allies, tutors.

- Kin selection — [`s-kin`](articles/s-kin.html)
- Sexual selection (signals, mate choice) — [`s-signals`](articles/s-signals.html), [`s-mating-systems`](articles/s-mating-systems.html)
- Cooperation & parental care — [`s-cooperation`](articles/s-cooperation.html), [`s-parental-care`](articles/s-parental-care.html)
- Group defence & social learning — [`s-group-defense`](articles/s-group-defense.html), [`s-social-learning`](articles/s-social-learning.html)

</div>

<div markdown="1">

### 🦁 Interspecific

How other species shape evolution — predators, parasites, mimics, competitors.

- Predator–prey dynamics — [`s-predator-prey`](articles/s-predator-prey.html), [`s-predation-neural`](articles/s-predation-neural.html)
- Müllerian & Batesian mimicry — [`s-mimicry`](articles/s-mimicry.html)
- Coevolving parasites (Red Queen) — [`s-mating-systems`](articles/s-mating-systems.html)
- Speciation — [`s-speciation`](articles/s-speciation.html)

</div>

<div markdown="1">

### 🌱 Environment

How physical and ecological niches shape evolution — and how organisms reshape them back.

- Niche construction — [`s-niche`](articles/s-niche.html)
- Phenotypic plasticity & Baldwin effect — [`s-plasticity`](articles/s-plasticity.html), [`s-baldwin`](articles/s-baldwin.html)
- Complex landscapes & seasonal change — [`s-complex-landscape`](articles/s-complex-landscape.html), [`s-seasonal`](articles/s-seasonal.html)
- Life history & scavenging — [`s-life-history`](articles/s-life-history.html), [`s-scavenging`](articles/s-scavenging.html)

</div>

</div>

**Or combine them.** The Baldwin effect ([`s-baldwin`](articles/s-baldwin.html))
emerges from learning × genetic assimilation under fluctuating
environments. Cephalopod-style long-learning short-life tradeoffs
([`s-cephalopod`](articles/s-cephalopod.html)) require brain size ×
parental care × life history interacting at once. Pace-of-life
syndromes ([`s-pace-of-life`](articles/s-pace-of-life.html)) need
life-history × metabolism × cognition. clade is designed so the
modules compose freely.

---

## 32 of 32 scenarios pass

Every biological scenario is cross-referenced to a primary-literature
prediction — Hamilton 1964 (kin selection), Hamilton 1980 (Red Queen),
Williams 1966 (predation demography), Emlen 1982 (cooperative breeding),
Hinton & Nowlan 1987 (Baldwin effect), DeWitt & Scheiner 2004
(plasticity), Isler & van Schaik 2009 (brain cost), and more. All 32
currently pass at t > 2σ on multi-seed audits. See the
[fidelity dashboard](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md)
for the per-scenario ledger.

---

## Quick start

```r
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

---

## Is clade right for your question?

| You want to study… | Use | Why not clade |
|---|---|---|
| Behaviour, cognition, and social evolution with heritable neural genomes | **clade** | — |
| Genome-scale population genetics with realistic recombination and demography | **[SLiM](https://messerlab.org/slim/)** | clade's genome is neural-network weights, not chromosomal loci |
| Coalescent / tree-sequence inference | **[msprime](https://tskit.dev/msprime/)** | clade is forward-time, phenotype-first |
| Teaching discrete-generation IBMs in a classroom browser | **[NetLogo](https://ccl.northwestern.edu/netlogo/)** | clade assumes a working R + Julia toolchain |
| Generic ABM (markets, traffic, opinion dynamics) | **[Mesa](https://mesa.readthedocs.io/)** | clade's primitives (genome, fitness, meiosis) are evolutionary-biology-specific |
| Phenotype–environment-match models (e.g. Burke et al. 2020) | **custom NetLogo / Python** | clade's fitness is emergent from foraging + survival, not a matching function you define |
| Epidemiology as the primary modelling target | specialised epi frameworks | clade has a SIR `disease` module, but it's a tool, not the target |

---

## Go deeper

- [**Getting started**](articles/getting-started.html) — install, first run, extracting results
- [**Scenarios**](articles/scenarios.html) — all 36 vignettes by theme
- [**Parameter reference**](articles/parameter-reference.html) — every field in `default_specs()`
- [**Custom modules**](articles/custom-modules.html) — write your own per-tick R hooks with `register_module()`
- [**Kernel as biology**](articles/k-README.html) — how the Julia kernel maps onto biological mechanism

---

## Citation

```bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```

License: [MIT](https://opensource.org/licenses/MIT).
