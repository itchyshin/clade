# Competitive landscape — verbatim positioning quotes

*Evidence base for the "when clade fits / when it doesn't" fit-table
on `index.md`. Every tool below was fetched 2026-04-19 from its own
official documentation. Quotes are verbatim from the source docs.*

---

## Tools surveyed

| Tool | What its own docs say it is | Scope |
|---|---|---|
| **SLiM** | *"a free, open-source evolutionary simulation framework that combines a powerful engine for population genetic simulations with the capability of modeling arbitrarily complex evolutionary scenarios"* ([source](https://messerlab.org/slim/)) | Genome-scale population genetics; non-WF models; continuous space; multiple species; eco-evo dynamics |
| **NetLogo** | *"a programmable modeling environment for simulating natural and social phenomena"* ([source](https://docs.netlogo.org/)) | General ABM; education-oriented; extensions for GIS, networks, system dynamics |
| **Mesa** | *"an open-source Python library for agent-based modeling, ideal for simulating complex systems and exploring emergent behaviors"* + *"the Python-based alternative to NetLogo, Repast, or MASON"* ([source](https://github.com/projectmesa/mesa)) | General Python ABM; integrates with NumPy/pandas/matplotlib; browser-based viz |
| **msprime** | *"a population genetics simulator of ancestry and DNA sequence evolution based on tskit"* ([source](https://tskit.dev/msprime/docs/)) | Coalescent / tree-sequence simulation; backward-time; genomic inference |

---

## SLiM — detailed notes

### What SLiM claims

From `messerlab.org/slim/`:

> *"SLiM is a free, open-source evolutionary simulation framework that
> combines a powerful engine for population genetic simulations with
> the capability of modeling arbitrarily complex evolutionary
> scenarios."*

Key distinguishing claims SLiM makes about itself:

- **Flexibility via scripting**: *"Simulations are configured via the
  integrated Eidos scripting language that allows interactive control
  over practically every aspect of the simulated evolutionary
  scenarios."*
- **Performance**: *"The underlying individual-based simulation
  engine is highly optimized to enable modeling of entire chromosomes
  in large populations."*
- **Scope beyond pop-gen**: supports *"non-Wright–Fisher models and
  continuous space"*, *"multiple species"*, and *"eco-evolutionary
  dynamics and coevolution"*.
- **Platform**: GUI on macOS / Linux / Windows for *"easy simulation
  set-up, interactive runtime control, and dynamical visualization"*.

### What SLiM does NOT claim (from the same page)

No mention of:

- Neural-network brains or cognition
- Behaviour evolution *per se* (as opposed to allele-level selection)
- R integration
- Primary-literature audit of scenarios

### Implication for clade's positioning

**Honest**: clade covers a space SLiM explicitly does not aim at —
neural / cognitive / behavioural evolution with agent-level decisions
driven by evolvable brains. SLiM's "eco-evolutionary dynamics" claim
is at the allelic / fitness-coefficient level, not the neural-
architecture level.

**Honest**: SLiM covers a space clade is not in — genome-scale
population genetics with realistic linkage, sweeps, demographic
inference. clade's "genome" is neural-network weights, not
chromosomes.

**The fit-table row is defensible**:

> *"Genome-scale population genetics with realistic recombination and
> demography → SLiM. (clade's genome is neural-network weights, not
> chromosomal loci.)"*

---

## NetLogo — detailed notes

### What NetLogo claims

From `docs.netlogo.org`:

> *"a programmable modeling environment for simulating natural and
> social phenomena"*

Other positioning claims:

- **Audience breadth**: explicitly positions itself as accessible to
  *"learners at multiple levels"* — beginner tutorials, dictionaries,
  error-message guides. Also tools for advanced use (BehaviorSpace,
  extensions).
- **Education emphasis**: *"The documentation emphasizes NetLogo's
  role in education and research, particularly for modeling complex
  systems across natural and social science domains."*
- **Extension ecosystem**: GIS, networks, matrices, Arduino, Python.
- **Free + open-source** (commercial licenses also offered).

Also — the companion book:

> Railsback & Grimm, *Agent-based and Individual-based Modeling*
> (2nd ed 2019) is the canonical NetLogo textbook. The book's own
> site describes it as aimed at *"practitioners seeking to design
> models to solve specific problems of real systems"*. Uses the
> terms "agent-based" and "individual-based" *interchangeably* — no
> formal ABM vs. IBM typology proposed.

### What NetLogo does NOT claim

- No built-in support for neural networks (the `nw` extension is
  graph/network, not neural)
- No genome / mutation / selection primitives (users code these from
  scratch)
- No fidelity-audit framework

### Implication for clade's positioning

**Honest**: NetLogo is the **educational** ABM standard. clade is
*not* for classroom prototyping — Julia compile alone is 60–90s, and
the R+Julia toolchain excludes browser-based teaching. NetLogo wins
this category.

**Honest**: NetLogo users code evolutionary dynamics from scratch;
clade ships 32 audited scenarios ready to run. For a behavioural
ecologist who wants to test a mechanism *without* implementing the
simulator, clade saves weeks. For someone teaching "build an ABM
from first principles", NetLogo is the right pedagogical choice.

**Fit-table row**:

> *"Teaching discrete-generation IBMs in a classroom browser →
> NetLogo. (clade assumes a working R + Julia toolchain.)"*

---

## Mesa — detailed notes

### What Mesa claims

From the Mesa README on GitHub:

> *"Mesa is an open-source Python library for agent-based modeling,
> ideal for simulating complex systems and exploring emergent
> behaviors."*

And:

> *"the Python-based alternative to NetLogo, Repast, or MASON"*

Distinguishing features:

- Integrated components (spatial grids, schedulers, analysis tools)
- Browser-based visualization; Jupyter notebook integration
- Modular architecture (use pre-built or custom components)
- Leverages *"Python's data analysis tools"* (pandas, numpy, etc.)
- Active development (Mesa 4 in progress)

### What Mesa does NOT claim

- No evolutionary-biology primitives (genome, fitness, meiosis, mate
  choice) — user implements these
- No built-in neural networks (user plugs in PyTorch / TensorFlow)
- No fidelity-audit framework

### Implication for clade's positioning

**Honest**: Mesa is a general ABM framework. Someone wanting to
model traffic, markets, or opinion dynamics gets a clean Python
starting point. Someone wanting to model an *evolving population* of
neural-brained organisms spends weeks writing evolutionary machinery
from scratch.

clade provides those primitives out of the box. For a behavioural
ecologist who is not a Python veteran, R + clade is a shorter path.

**Fit-table row**:

> *"Generic ABM (markets, traffic, opinion dynamics) → Mesa.
> (clade's primitives — genome, fitness, meiosis — are evolutionary-
> biology-specific.)"*

---

## msprime — detailed notes

### What msprime claims

From `tskit.dev/msprime/docs/`:

> *"msprime is a population genetics simulator of ancestry and DNA
> sequence evolution based on tskit."*

And:

> *"msprime can simulate ancestral histories for a sample of
> individuals, consistent with a given demography under a range of
> different models and evolutionary processes."*

Capabilities:

- Simulate ancestral histories consistent with demographic parameters
- Simulate mutations on those histories
- Tree-sequence data structures (ancestral recombination graphs)
- Coalescent (backward-time) simulation

### What msprime does NOT claim

- Not a forward-time simulator (that's SLiM's niche)
- Not a behaviour / phenotype / cognition simulator
- Does not claim selection on behaviour as a first-class feature

### Implication for clade's positioning

**Honest**: msprime is in an entirely different modelling paradigm —
coalescent / backward-time simulation for inference from genomic
data. clade is forward-time, phenotype-first, single-locus genome in
neural-network form.

These tools are **complementary, not competitive** — someone studying
evolutionary history of a real population uses msprime; someone
testing mechanistic predictions about behaviour in silico uses clade.

**Fit-table row**:

> *"Coalescent / tree-sequence inference → msprime. (clade is
> forward-time, phenotype-first.)"*

---

## Neural-brain-evolution simulators — preliminary notes

This is a distinct genre the current fit-table **doesn't address**
and probably should. Known tools in this space:

- **Polyworld** (Yaeger 1994) — artificial-life neural simulator;
  visualisation-heavy, limited modularity.
- **Framsticks** (Komosinski & Ulatowski 1999) — 3D morphology-
  evolution simulator; has neural controllers; more morphology-
  focused than behaviour-ecology-focused.
- **Avida** (Ofria & Wilke 2004) — digital-organism simulator; agents
  are self-replicating programs, not neural-brained.
- **Evosphere** (Eiben et al. 2013) — robot / morphology co-evolution.
- **alifeR** — clade's predecessor (per `getting-started.Rmd`);
  Rcpp-based, limited to R-speed simulation.

**Open question for the research**: which of these is the closest
ecological / comparative-cognition analogue, and what do their docs
say they're for? clade's positioning claim "modular neural-brain
evolution with literature-audited scenarios" is only as strong as
what we can show these alternatives don't do.

*TODO*: fetch first-person positioning docs for Polyworld, Framsticks,
and any neural-brain-evolution frameworks still in active development.

---

## Provisional "when clade fits" summary (for future landing-page copy)

Based on the evidence above, these are the positioning claims we can
make with sources to back them:

1. **Not for genome-scale population genetics** — SLiM (source:
   SLiM's own framing as "population genetic simulations").
2. **Not for coalescent inference** — msprime (source: msprime's own
   framing as "ancestral histories ... coalescent").
3. **Not for classroom-browser teaching** — NetLogo (source:
   NetLogo's own "learners at multiple levels" emphasis and
   browser-first UI).
4. **Not for generic non-evolutionary ABM** — Mesa or custom code
   (source: Mesa's own framing as "complex systems and emergent
   behaviors", no evolutionary-biology primitives mentioned).
5. **For evolution of behaviour, cognition, and social
   interactions with literature-audited modules** — no surveyed
   tool makes this combination of claims. **But we should verify the
   neural-brain-evolution genre (TODO above) before asserting it's a
   unique niche.**

The user-facing copy that mentions these tools should link to the
sources and quote them when feasible — a behavioural ecologist
comparing options will appreciate verifiable statements over our
paraphrases.
