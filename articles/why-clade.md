# Why clade?

*A long-form companion to the landing page’s one-line pitch. Read this
if you’re deciding whether clade fits your research question, or if you
want to cite clade and need to explain to a collaborator what it is.*

------------------------------------------------------------------------

## What clade is

`clade` is a modular R + Julia simulator for the **three classes of
interaction that shape behaviour, cognition, and social evolution**:

1.  **Intraspecific** — between members of the same species (kin
    selection, sexual selection, cooperation, signalling, social
    learning, mating systems, group defence).
2.  **Interspecific** — between species (predator–prey dynamics,
    mimicry, coevolving parasites, speciation).
3.  **Environmental** — between organisms and their physical niche
    (niche construction, phenotypic plasticity, seasonal change, life
    history, the Baldwin effect).

Agents in clade carry **heritable neural-network genomes** (by default a
Bayesian neural network; optionally a multilayer perceptron,
continuous-time RNN, gene-regulatory network, transformer, or symbolic
rule synthesis). Selection acts on the phenotypes those genomes produce
in an explicit, spatially structured world. Every biological scenario is
cross-referenced to a primary-literature prediction and [multi-seed
audited](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md);
**all 32 of 32 auditable scenarios currently pass** at t \> 2σ.

------------------------------------------------------------------------

## Who clade is for

- **Behavioural ecologists** testing hypotheses *in silico* before
  designing animal experiments. The three-pillar framing makes it easy
  to isolate mechanisms (e.g. disable sexual selection by setting
  `mate_choice = FALSE`) or combine them (e.g. kin selection × sexual
  selection × parental care).
- **Evolutionary cognitive scientists** probing brain-size-vs-lifespan
  tradeoffs, brain-architecture comparisons, social learning, Baldwin
  effect, or within-lifetime reinforcement learning.
- **Social-evolution theorists** who want a canonical ABM testbed
  pre-loaded with Hamilton’s rule, Emlen’s cooperative-breeding
  framework, and Fisher–Kirkpatrick–Ryan signal coevolution.
- **Teachers** — the 36 scenario vignettes (all open-source, all cited)
  work as lecture companions or lab exercises. The audit makes it easy
  to say “run this and you will reproduce the Hamilton 1980 Red Queen
  result” with confidence.
- **Computational biologists** who want a *modular* simulator where
  flipping one flag adds disease, parasites, mimicry, sexual selection,
  parental care, cooperation, dispersal, or niche construction — and
  every flag is documented.

------------------------------------------------------------------------

## Why clade specifically

Three things rarely coexist in one simulator. clade sits at their
intersection:

### 1. Neural-brain evolution

Agents carry Bayesian / feedforward / recurrent / gene-regulatory /
transformer / symbolic brains that evolve under selection. Classical
population-genetics simulators (SLiM, fwdpy, msprime, slendr) don’t
model brains; generic ABM frameworks (NetLogo, Mesa) can, but without
the rigorous evolutionary substrate. See [Brain
architectures](https://itchyshin.github.io/clade/articles/s-brain-comparison.html)
for the comparison.

### 2. Literature-audited scenarios

32 biological scenarios, each cross-referenced to a primary paper:
Hamilton 1964 (kin selection), Hamilton 1980 (Red Queen), Williams 1966
(predation demography), Emlen 1982 (cooperative breeding), Hinton &
Nowlan 1987 (Baldwin effect), DeWitt & Scheiner 2004 (plasticity),
Aiello & Wheeler 1995 / Isler & van Schaik 2009 (brain cost),
Odling-Smee et al. 2003 (niche construction), and more. Audits are
multi-seed and the ledger distinguishes “PASS”, “direction-correct but
sub-2σ”, and “contradicts theory”. You can cite the simulator *and* the
paper it reproduces in the same breath.

### 3. R + Julia ergonomics

Specs are named R lists. The Julia kernel is crossed once per
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
call — not once per tick — so large populations and long simulations
stay fast. Output is a tidy R environment with
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
giving you a `data.frame` ready for `ggplot2`, `tidyr`, or `dplyr`. No
Python, no notebook gymnastics, no glue code.

------------------------------------------------------------------------

## When clade is *not* the right tool

Being honest about this matters. If your question falls into any of the
categories below, use the tool we recommend instead.

| You want to study…                                                                                   | Use                                                                                                                           | Why not clade                                                                                                                                                                                                                                                |
|------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Genome-scale population genetics with realistic recombination, demography, or selection coefficients | [SLiM](https://messerlab.org/slim/)                                                                                           | clade’s genome is neural-network weights, not chromosomal loci. You cannot model linkage disequilibrium, selective sweeps on SNPs, or introgression at the gene level.                                                                                       |
| Coalescent simulation, tree-sequence recording, inference from genomic data                          | [msprime](https://tskit.dev/msprime/), [slendr](https://github.com/bodkan/slendr)                                             | clade is forward-time and phenotype-first; it does not emit tree sequences.                                                                                                                                                                                  |
| Discrete-generation IBMs for teaching in a classroom browser                                         | [NetLogo](https://ccl.northwestern.edu/netlogo/)                                                                              | clade assumes a working R + Julia toolchain (first-run Julia compile ≈ 60–90 s). Fine for research machines; heavy for a three-hour class.                                                                                                                   |
| Generic agent-based modelling (markets, traffic, opinion dynamics)                                   | [Mesa](https://mesa.readthedocs.io/) (Python), [AgentBasedModels.jl](https://github.com/dsanmart/AgentBasedModels.jl) (Julia) | clade’s primitives — genome, fitness, meiosis, mate choice — are evolutionary-biology-specific. Using clade for non-evolutionary ABMs is fighting the kernel.                                                                                                |
| Epidemiology as the primary modelling target (beyond SIR-on-an-agent-grid)                           | Specialised epidemiological frameworks                                                                                        | clade has a `disease` module with SIR dynamics, but the kernel’s selection pressure comes from foraging and reproduction, not epidemic transmission. clade can model disease *as a selection pressure on behaviour*, but it’s not an epi-specific simulator. |

A short honest note: clade was designed from the start as a behavioural
/ cognitive / social-evolution testbed. Its kernel (continuous-time,
continuous-trait, neural-brain-based, energy-based fitness) is
opinionated. Where that kernel fits your question, clade is probably the
best tool available. Where it doesn’t fit, please use the alternative —
we’d rather you use the right tool than force clade into a role it
wasn’t built for.

------------------------------------------------------------------------

## What it looks like in practice

Concrete pitches that actually describe clade papers:

- *“I want to test whether Hamilton’s rule still holds when offspring
  can’t forage efficiently at first, and parental care is the only way
  to bridge the deficit.”* →
  [`s-kin`](https://itchyshin.github.io/clade/articles/s-kin.md) +
  `parental_care` + `neonatal_foraging_deficit`. A single specs list, a
  single
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
  call.

- *“I want to compare how Bayesian, recurrent, and transformer brains
  cope with the same foraging task.”* →
  [`s-brain-comparison`](https://itchyshin.github.io/clade/articles/s-brain-comparison.md)
  with `brain_type` swept across values.

- *“I want to combine cooperative breeding + disease + parental care and
  see what emerges.”* → Turn on three flags. That’s the pitch.

- *“I want a canonical Red Queen testbed I can cite in a review.”* →
  [`s-mating-systems`](https://itchyshin.github.io/clade/articles/s-mating-systems.md)
  with `coevolving_parasites = TRUE`. Audit report describes the exact
  2×2 design (parasites on/off × sex/asex) that isolates the Red Queen
  signal from the cost of sex.

- *“I want to run 64 seeds × 1 000 ticks and have the output in a tidy
  data frame by lunch.”* → `batch_alife(specs, n = 64)` with PSOCK
  parallel backend;
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  gives you the frame.

------------------------------------------------------------------------

## Honest weaknesses

- **Learning curve.** 32 modules × a flat specs list means first-time
  users get lost. Start with [Getting
  started](https://itchyshin.github.io/clade/articles/getting-started.md)
  and then [First research
  project](https://itchyshin.github.io/clade/articles/first-research-project.md)
  — don’t try to read the parameter reference linearly.
- **Julia first-compile cost.** 60–90 s on the first
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
  in a fresh R session. Fine for research, annoying for a one-off demo.
- **Opinionated kernel.** Continuous-time, continuous-trait,
  neural-brained, energy-fitness-based. Excellent within its design
  centre; rigid outside it (see the “not the right tool” table above).
- **Fidelity ≠ realism.** “32 of 32 auditable scenarios pass” means *the
  simulator reproduces the paper’s qualitative prediction*, not *the
  simulation matches any real species quantitatively*. The audits are
  about theoretical fidelity to published canon, not ecological realism.

------------------------------------------------------------------------

## Next steps

- Already convinced? Jump to [Getting
  started](https://itchyshin.github.io/clade/articles/getting-started.md).
- Want to see an end-to-end research workflow? Read [First research
  project](https://itchyshin.github.io/clade/articles/first-research-project.md).
- Hit a snag? The
  [Troubleshooting](https://itchyshin.github.io/clade/articles/troubleshooting.md)
  page covers Julia compile issues, PSOCK parallel gotchas, and
  viability failures.
- Want to explore all 36 scenarios by theme? See
  [Scenarios](https://itchyshin.github.io/clade/articles/scenarios.md).

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
