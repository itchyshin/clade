# Articles

### Overview

- [Biological Scenarios: A Discovery Guide](scenarios.md):
- [Getting started with clade](getting-started.md):
- [Parameter Reference](parameter-reference.md):
- [Custom Modules: Extending clade with Per-Tick
  Hooks](custom-modules.md):

### Parameter search

Automated tools for finding parameter combinations that produce target
evolutionary outcomes. Start with the introduction for when/why/which
algorithm; then pick the agent-level or environment-level guide
depending on what you’re tuning; or go straight to the algorithm
reference.

- [Parameter search — introduction](ps-introduction.md):
- [Parameter search — agent-level parameters](ps-agent-parameters.md):
- [Parameter search — environment-level
  parameters](ps-environment-parameters.md):
- [Parameter search — algorithms](ps-algorithms.md):

### Kernel as biology

Side-by-side reading of the simulation kernel — Julia code on the left,
plain-English explanation and biological rationale on the right. Read
these to understand the rules of the simulation as biology, spot
inconsistencies, and find places where the model could be more
realistic.

- [Kernel as biology — overview](k-README.md):
- [tick.jl — one tick in the life of an agent](k-tick.md):
- [Clade.jl — the main loop, in biological order](k-clade-main.md):
- [sense.jl — what an agent perceives](k-sense.md):
- [reproduce.jl — birth, inheritance, parental cost](k-reproduce.md):
- [death.jl — when agents die and why](k-death.md):
- [genome.jl — meiosis, traits, inheritance](k-genome.md):

### Theme 1 — How do traits evolve?

- [Baseline world](s-baseline.md):
- [Population genetics and heritability](s-pop-genetics.md):
- [Body size evolution](s-body-size.md):
- [Brain size evolution](s-brain-size.md):
- [Stress hypermutation](s-stress-hypermutation.md):

### Theme 2 — Ecology and adaptive landscapes

- [Complex landscape](s-complex-landscape.md):
- [Dispersal, IFD and spatial sorting](s-dispersal-ifd.md):
- [Niche construction](s-niche.md):
- [Seasonal dynamics](s-seasonal.md):
- [Scavenging and carrion dynamics](s-scavenging.md):

### Theme 3 — Social evolution

- [Kin selection](s-kin.md):
- [Cooperative breeding and public goods](s-cooperation.md):
- [Signals and mate choice](s-signals.md):
- [Speciation and genetic divergence](s-speciation.md):

### Theme 4 — Life history strategies

- [Parental care](s-parental-care.md):
- [Mating systems](s-mating-systems.md):
- [Life history strategies](s-life-history.md):
- [Clutch size evolution](s-clutch-size.md):
- [Parental investment](s-parental-investment.md):
- [Pace-of-life syndromes](s-pace-of-life.md):

### Theme 5 — Species interactions and arms races

- [Predator-prey dynamics](s-predator-prey.md):
- [Group defense](s-group-defense.md):
- [Mimicry and toxicity](s-mimicry.md):
- [SIR disease](s-disease.md):
- [Predation and neural evolution](s-predation-neural.md):

### Theme 6 — Learning, plasticity, and cognition

- [Within-lifetime reinforcement learning](s-rl.md):
- [Social learning](s-social-learning.md):
- [Phenotypic plasticity](s-plasticity.md):
- [BNN uncertainty canalization and the Baldwin Effect](s-baldwin.md):
- [The Baldwin Effect: within-lifetime learning accelerating
  evolution](baldwin-effect.md):
- [The cephalopod paradox](s-cephalopod.md):

### Theme 7 — Discovery experiments

- [Module comparison](s-module-comparison.md):
- [MAP-Elites diversity search](s-map-elites.md):
- [Kitchen-sink run](s-kitchen-sink.md):
- [Evolution of bad science](s-bad-science.md):
- [Cross-module discovery gallery](s-cross-module.md):
