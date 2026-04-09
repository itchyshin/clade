# clade

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pkgdown](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://itchyshin.github.io/clade/)

**Agent-based evolutionary simulation with a Julia backend and R interface.**

`clade` runs populations of digital organisms on a renewable resource grid.
Each agent carries a heritable neural-network genome; natural selection acts on
brain weights, life-history traits, and — with optional modules — body size,
dispersal tendency, wing morphology, cooperative behaviour, and more.

The simulation kernel is written in Julia for performance. R is the interface:
you set parameters, call `run_alife()` once, and receive the full simulation
environment back for analysis and visualisation. The R–Julia boundary is
crossed **once per run**, not once per tick, so large populations and long
simulations stay fast.

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

| Module | Flag | What it models |
|---|---|---|
| Baseline | — | Foraging and neural evolution on a toroidal grass grid |
| Complex landscape | `complex_landscape` | 3-layer forest; wing size evolves for canopy access |
| Spatial sorting | `spatial_sorting` + `dispersal_evolution` | Invasion-front dispersal assortment (Shine et al. 2011) |
| IFfolk + parliament | `iffolk_selection` | Inclusive fitness transfers + defector suppression |
| Kin selection | `kin_selection` | Hamilton's rule, pedigree-based relatedness |
| SIR disease | `disease` | Susceptible-Infected-Recovered epidemic dynamics |
| Niche construction | `niche_construction` | Shelter building modifies the selection environment |
| Body size | `body_size_evolution` | Allometric metabolic scaling |
| Dispersal | `dispersal_evolution` | Heritable dispersal tendency |
| Social learning | `social_learning` | Copy successful neighbours' brain weights |
| Parental care | `parental_care` | Carried offspring, obligate altriciality |
| Mimicry / toxicity | `mimicry` | Predator learning + warning colouration |
| Within-lifetime RL | `rl_mode = "actor_critic"` | REINFORCE-with-baseline; Baldwin effect |
| Phenotypic plasticity | `phenotypic_plasticity` | Heritable sensory gain |

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

## Documentation

Full documentation is available at **<https://itchyshin.github.io/clade/>**.

| Article | Contents |
|---|---|
| [Getting Started](https://itchyshin.github.io/clade/articles/getting-started.html) | Installation, first run, extracting results, batch runs |
| [Biological Scenarios](https://itchyshin.github.io/clade/articles/scenarios.html) | Code and expected outputs for every module |
| [Custom Modules](https://itchyshin.github.io/clade/articles/custom-modules.html) | Write your own per-tick hooks with `register_module()` |
| [Parameter Reference](https://itchyshin.github.io/clade/articles/parameter-reference.html) | Every parameter in `default_specs()`, grouped by theme |
| [Diversity Search](https://itchyshin.github.io/clade/articles/diversity-search.html) | CMA-ES, MAP-Elites, viability mapping, and scenario-specific tuning |
| [Showcase](https://itchyshin.github.io/clade/articles/showcase.html) | Figures from all simulation scenarios |

---

## Citation

If you use clade in published work, please cite:

```bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: Agent-based evolutionary simulation with a Julia backend},
  year    = {2026},
  url     = {https://github.com/itchyshin/clade}
}
```

---

## License

MIT — see [LICENSE](LICENSE).
