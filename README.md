# clade

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Fidelity audit: 32/32](https://img.shields.io/badge/fidelity-32%2F32-brightgreen.svg)](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md)
[![pkgdown](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://itchyshin.github.io/clade/)

**Evolve behaviour, minds, and brains in R — the intraspecific, interspecific, and environmental interactions that shape them. 32 / 32 scenarios audited against primary literature.**

`clade` is a modular R + Julia simulator for the three classes of
interaction that shape behaviour, cognition, and social evolution:
between conspecifics (kin, mates, rivals, allies, tutors), between
species (predators, parasites, mimics, competitors), and with the
physical environment (niche construction, plasticity, seasonal change).
Every biological scenario is cross-referenced to a primary-literature
prediction and multi-seed audited — all **32 of 32** currently pass,
with 0 sub-2σ and 0 contradicting theory
([dashboard](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md)).

> Is clade for you? See the [landing page](https://itchyshin.github.io/clade/)
> for the three-pillar overview and a "when clade fits / when it doesn't"
> fit-table comparing it to SLiM, msprime, NetLogo, and Mesa.

The framing follows the *Introduction to Behavioural Ecology* (Davies /
Krebs / West, Wiley) canon, with the cognitive-ecology spine from
Shettleworth's *Cognition, Evolution, and Behavior* (OUP).

The simulation kernel is written in Julia for performance. R is the
interface: you set parameters, call `run_alife()` once, and receive the
full simulation environment back for analysis and visualisation. The
R–Julia boundary is crossed **once per run**, not once per tick, so
large populations and long simulations stay fast.

---

## Installation

### R package

```r
# From GitHub (development version)
remotes::install_github("itchyshin/clade")
```

### Julia

clade requires Julia ≥ 1.9. The easiest way to install it is via
[juliaup](https://github.com/JuliaLang/juliaup):

```bash
curl -fsSL https://install.julialang.org | sh
```

Or download directly from [julialang.org/downloads](https://julialang.org/downloads/).

### First-run compilation

On the first call to `run_alife()`, Julia compiles the simulation kernel. This
takes **60–90 seconds** and is cached for all subsequent runs in the same Julia
environment.

---

## Quick start

```r
library(clade)

# Confirm Julia is ready (compiles kernel on first call — ~60-90 s once)
julia_is_ready()

# Set up a baseline run
specs <- default_specs()
specs$n_agents_init <- 40L
specs$max_ticks     <- 300L

# Run the simulation
env  <- run_alife(specs)

# Extract and plot results
data <- get_run_data(env)
plot_run(data)   # population, energy, genetic diversity dashboard
```

---

## Biological modules

All modules are disabled by default and enabled with a single flag in the specs
list. Modules can be freely combined.

**Domain tags**: 🤝 intraspecific · 🦁 interspecific · 🌱 environment ·
🧠 cognition · 🐣 life history · 🧬 genetics layer.

| Module | Flag(s) | What it models |
|---|---|---|
| Baseline | — | Foraging and neural evolution on a toroidal grass grid |
| 🐣 Body size | `body_size_evolution` | Metabolic scaling (approximate Kleiber); size-foraging trade-off |
| 🧠 Brain size | `brain_size_evolution` | Cognitive-bonus × metabolic-cost; bootstrapping under `parental_care` |
| 🐣 Clutch size | `clutch_size_evolution` | r/K-style trade-off between clutch count and offspring quality |
| 🌱 Complex landscape | `complex_landscape` | 3-layer forest (grass / shrubs / canopy); wing-size evolves for canopy access |
| 🤝 Cooperation | `cooperation_evolution` | Public-goods games with helper-tendency evolution |
| 🤝 Cooperative breeding | `cooperative_breeding` | Helpers at the nest (Emlen 1982) |
| 🌱 Dispersal | `dispersal_evolution` | Heritable dispersal tendency |
| 🌱 Habitat preference | `habitat_preference_evolution` | Agents move toward preferred grass density |
| 🤝 IFfolk + parliament | `iffolk_selection`, `parliament_suppression` | Inclusive-fitness transfers + intragenomic-conflict suppression (Haig 2000; Fromhage & Jennions 2019) |
| 🤝 Kin selection | `kin_selection` | Hamilton's rule, pedigree-based relatedness (r = 0.5 / 0.25 / 0) |
| 🐣 Life history / pace of life | `metabolic_rate_evolution`, `aging_rate_evolution` | Metabolic rate ↔ lifespan trade-off |
| 🤝 Mating systems | `ploidy = 2`, `mate_choice` | Haploid / diploid; signal-preference assortative mating |
| 🦁 Mimicry | `mimicry` | Predator signal-vector memory + delta-rule Rescorla-Wagner + aposematic pleiotropy (`signal_toxicity_coupling`). Müllerian by default; Batesian via `batesian_mimicry = TRUE` |
| 🧬 Mutation-rate evolution | `mutation_rate_evolution` | Per-agent heritable `mutation_sd` |
| 🌱 Niche construction | `niche_construction` | Shelter-building modifies the selection environment (local public good). With `shelter_occupancy_bonus > 0`: shelters confer a heritable metabolic benefit to occupants (Odling-Smee et al. 2003) |
| 🤝 Parental care | `parental_care` | Obligate altriciality — offspring carried, fed, and graduated |
| 🐣 Neonatal foraging deficit | `neonatal_foraging_deficit > 0` | Young agents can't forage at adult efficiency; parental care bridges the gap (Aiello & Wheeler 1995; Isler & van Schaik 2009) |
| 🤝 Parental investment | `parental_investment_evolution` | Evolved male / offspring-quality investment |
| 🌱 Phenotypic plasticity | `phenotypic_plasticity` | Environment-dependent reproduction threshold |
| 🦁 Predation | `predators`, `n_predators_init > 0` | Co-evolving predator guild with dedicated 15-input sensory brain |
| 🤝 Predator group defence | `group_defense` | Coordinated anti-predator behaviour |
| 🌱 Scavenging | `scavenging` | Carcass consumption; decay-based carcass lifetime |
| 🌱 Seasonal dynamics | `seasonal_amplitude > 0`, `winter_death_prob` | Resource oscillation + winter mortality |
| 🦁 SIR disease | `disease` | Susceptible–Infected–Recovered epidemic dynamics |
| 🤝 Signals / sexual selection | `signal_mating`, `signal_evolution_drift` | Signal-preference coevolution (Fisher 1915; Kirkpatrick & Ryan 1991) |
| 🤝 Social learning | `social_learning` | Copy successful neighbours' brain weights |
| 🌱 Spatial sorting | `spatial_sorting` + `dispersal_evolution` + `toroidal = FALSE` | Invasion-front dispersal assortment (Shine et al. 2011; needs bounded grid) |
| 🦁 Speciation | `speciation` | Genome-distance clustering + reproductive isolation |
| 🧬 Stress hypermutation | `stress_hypermutation` | SOS-style mutation-rate spike below `stress_threshold` |
| 🧬 Transgenerational epigenetics | `epigenetics` | Methylation inheritance on BNN sigma (Jablonka & Lamb 2005) |
| 🦁 Coevolving parasites | `coevolving_parasites` | Hamilton 1980 Red Queen. Continuous-trait (signal centroid tracking) and discrete-allele (Hamming haplotype matching with Mendelian inheritance) modes |
| 🧠 Within-lifetime RL | `rl_mode = "actor_critic"` | REINFORCE score-function update on BNN posterior (Williams 1992; Blundell et al. 2015). Use `bnn_sample_freq = 5` with BNN brains. |
| 🧬 Lamarckian inheritance | `lamarckian = TRUE` | RL-learned weights written back to genome before meiosis |
| 🧠 Quantised weights | `ann_weight_values` | Snap weights to a discrete set (e.g. ternary) after expression |

See the [Parameter Reference](https://itchyshin.github.io/clade/articles/parameter-reference.html) article for the complete parameter list.

---

## Brain architectures

The `brain_type` parameter selects the neural architecture. All types share the
same R interface; only the forward pass and learning dynamics differ.

| Type | Description |
|---|---|
| `"bnn"` | Bayesian neural network — learns a distribution over weights (default) |
| `"ann"` | Standard multilayer perceptron |
| `"ctrnn"` | Continuous-time recurrent network; suited for temporally extended tasks |
| `"grn"` | Gene regulatory network topology; sparse and biologically motivated |
| `"transformer"` | Self-attention architecture; highest capacity, slowest |
| `"synthesis"` | Symbolic rule extraction from evolved weights |

---

## Fidelity audit

Every biological scenario is backed by a multi-seed fidelity audit that
cross-references the primary literature, the alifeR R prototype, and
(where applicable) the MATLAB ancestor codebase. Current ledger
(as of 0.5.6):

| Status | Count |
|---|---|
| ✅ Passed | **32** of 32 auditable scenarios |
| 🟠 Passed-consistent (direction correct, magnitude limited) | **0** |
| 🔴 Contradicts | **0** |

(3 scenarios — module-comparison, kitchen-sink, cross-module — are
demo/discovery vignettes with no primary-source quantitative claim
and are marked ⚪ N/A in
[`STATUS.md`](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/STATUS.md);
they are excluded from the 32 auditable count.)

As of 0.5.18 every scenario passes. The last two 🟠 (plasticity,
Baldwin effect) were promoted by adding a
`seasonal_spatial_bias` kernel spec that creates phenotype-
dependent fluctuating selection — DeWitt 2004 / Hinton-Nowlan 1987
canonical predictions then hold at t > 4σ. The ledger was
confirmed end-to-end under the 0.5.10 real-diploid-sex kernel —
see [`post_0510_summary.md`](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/post_0510_summary.md). See the
[priority roadmap](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/PRIORITY_ROADMAP.md)
for each scenario's diagnosis and promotion path, and the
[crash-audit findings](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/CRASH_AUDIT_FINDINGS.md)
for the scenarios that need `default_specs()` (not `fast_specs()`) for
viability. All audit reports, runners, and figures live under
[`dev/audit/fidelity/`](https://github.com/itchyshin/clade/tree/main/dev/audit/fidelity);
`STATUS.md` there is the per-scenario ledger.

---

## Documentation

Full documentation is available at **<https://itchyshin.github.io/clade/>**.

| Article | Contents |
|---|---|
| [Getting Started](https://itchyshin.github.io/clade/articles/getting-started.html) | Installation, first run, extracting results, batch runs |
| [Biological Scenarios](https://itchyshin.github.io/clade/articles/scenarios.html) | Code and expected outputs for every module |
| [Custom Modules](https://itchyshin.github.io/clade/articles/custom-modules.html) | Write your own per-tick hooks with `register_module()` |
| [Parameter Reference](https://itchyshin.github.io/clade/articles/parameter-reference.html) | Every parameter in `default_specs()`, grouped by theme |

---

## Citation

If you use clade in published work, please cite:

```bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: Agent-based evolutionary simulation with a Julia backend},
  year    = {2026},
  note    = {R package version 0.5.6},
  url     = {https://github.com/itchyshin/clade}
}
```

---

## License

MIT — see [LICENSE](LICENSE).
