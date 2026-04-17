# Articles

### Overview

- [Biological Scenarios: A Discovery
  Guide](https://itchyshin.github.io/clade/articles/scenarios.md):
- [Getting started with
  clade](https://itchyshin.github.io/clade/articles/getting-started.md):
- [Parameter
  Reference](https://itchyshin.github.io/clade/articles/parameter-reference.md):
- [Parameter-space search at scale (parallel, resumable,
  streaming)](https://itchyshin.github.io/clade/articles/parameter-space-search.md):
- [Custom Modules: Extending clade with Per-Tick
  Hooks](https://itchyshin.github.io/clade/articles/custom-modules.md):

### Parameter search

Automated tools for finding parameter combinations that produce target
evolutionary outcomes. Start with the introduction for when/why/which
algorithm; then pick the agent-level or environment-level guide
depending on what you’re tuning; or go straight to the algorithm
reference.

- [Parameter search —
  introduction](https://itchyshin.github.io/clade/articles/ps-introduction.md):
- [Parameter search — agent-level
  parameters](https://itchyshin.github.io/clade/articles/ps-agent-parameters.md):
- [Parameter search — environment-level
  parameters](https://itchyshin.github.io/clade/articles/ps-environment-parameters.md):
- [Parameter search —
  algorithms](https://itchyshin.github.io/clade/articles/ps-algorithms.md):

### Kernel as biology

Side-by-side reading of the simulation kernel — Julia code on the left,
plain-English explanation and biological rationale on the right. Read
these to understand the rules of the simulation as biology, spot
inconsistencies, and find places where the model could be more
realistic.

- [Kernel as biology —
  overview](https://itchyshin.github.io/clade/articles/k-README.md):
- [tick.jl — one tick in the life of an
  agent](https://itchyshin.github.io/clade/articles/k-tick.md):
- [Clade.jl — the main loop, in biological
  order](https://itchyshin.github.io/clade/articles/k-clade-main.md):
- [sense.jl — what an agent
  perceives](https://itchyshin.github.io/clade/articles/k-sense.md):
- [reproduce.jl — birth, inheritance, parental
  cost](https://itchyshin.github.io/clade/articles/k-reproduce.md):
- [death.jl — when agents die and
  why](https://itchyshin.github.io/clade/articles/k-death.md):
- [genome.jl — meiosis, traits,
  inheritance](https://itchyshin.github.io/clade/articles/k-genome.md):

### Theme 1 — How do traits evolve?

- [Baseline
  world](https://itchyshin.github.io/clade/articles/s-baseline.md):
- [Population genetics and
  heritability](https://itchyshin.github.io/clade/articles/s-pop-genetics.md):
- [Body size
  evolution](https://itchyshin.github.io/clade/articles/s-body-size.md):
- [Brain size
  evolution](https://itchyshin.github.io/clade/articles/s-brain-size.md):
- [Stress
  hypermutation](https://itchyshin.github.io/clade/articles/s-stress-hypermutation.md):

### Theme 2 — Ecology and adaptive landscapes

- [Complex
  landscape](https://itchyshin.github.io/clade/articles/s-complex-landscape.md):
- [Dispersal, IFD and spatial
  sorting](https://itchyshin.github.io/clade/articles/s-dispersal-ifd.md):
- [Niche
  construction](https://itchyshin.github.io/clade/articles/s-niche.md):
- [Seasonal
  dynamics](https://itchyshin.github.io/clade/articles/s-seasonal.md):
- [Scavenging and carrion
  dynamics](https://itchyshin.github.io/clade/articles/s-scavenging.md):

### Theme 3 — Social evolution

- [Kin selection](https://itchyshin.github.io/clade/articles/s-kin.md):
- [Cooperative breeding and public
  goods](https://itchyshin.github.io/clade/articles/s-cooperation.md):
- [Signals and mate
  choice](https://itchyshin.github.io/clade/articles/s-signals.md):
- [Speciation and genetic
  divergence](https://itchyshin.github.io/clade/articles/s-speciation.md):

### Theme 4 — Life history strategies

- [Parental
  care](https://itchyshin.github.io/clade/articles/s-parental-care.md):
- [Mating
  systems](https://itchyshin.github.io/clade/articles/s-mating-systems.md):
- [Life history
  strategies](https://itchyshin.github.io/clade/articles/s-life-history.md):
- [Clutch size
  evolution](https://itchyshin.github.io/clade/articles/s-clutch-size.md):
- [Parental
  investment](https://itchyshin.github.io/clade/articles/s-parental-investment.md):
- [Pace-of-life
  syndromes](https://itchyshin.github.io/clade/articles/s-pace-of-life.md):

### Theme 5 — Species interactions and arms races

- [Predator-prey
  dynamics](https://itchyshin.github.io/clade/articles/s-predator-prey.md):
- [Group
  defense](https://itchyshin.github.io/clade/articles/s-group-defense.md):
- [Mimicry and
  toxicity](https://itchyshin.github.io/clade/articles/s-mimicry.md):
- [SIR
  disease](https://itchyshin.github.io/clade/articles/s-disease.md):
- [Predation and neural
  evolution](https://itchyshin.github.io/clade/articles/s-predation-neural.md):

### Theme 6 — Learning, plasticity, and cognition

- [Within-lifetime reinforcement
  learning](https://itchyshin.github.io/clade/articles/s-rl.md):
- [Social
  learning](https://itchyshin.github.io/clade/articles/s-social-learning.md):
- [Phenotypic
  plasticity](https://itchyshin.github.io/clade/articles/s-plasticity.md):
- [BNN uncertainty canalization and the Baldwin
  Effect](https://itchyshin.github.io/clade/articles/s-baldwin.md):
- [The Baldwin Effect: within-lifetime learning accelerating
  evolution](https://itchyshin.github.io/clade/articles/baldwin-effect.md):
- [The cephalopod
  paradox](https://itchyshin.github.io/clade/articles/s-cephalopod.md):
- [Comparing brain architectures
  side-by-side](https://itchyshin.github.io/clade/articles/s-brain-comparison.md):

### Theme 7 — Discovery experiments

- [Module
  comparison](https://itchyshin.github.io/clade/articles/s-module-comparison.md):
- [MAP-Elites diversity
  search](https://itchyshin.github.io/clade/articles/s-map-elites.md):
- [Kitchen-sink
  run](https://itchyshin.github.io/clade/articles/s-kitchen-sink.md):
- [Evolution of bad
  science](https://itchyshin.github.io/clade/articles/s-bad-science.md):
- [Cross-module discovery
  gallery](https://itchyshin.github.io/clade/articles/s-cross-module.md):
