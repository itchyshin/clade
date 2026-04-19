# Methods-review literature — survey

*What existing reviews of agent-based / individual-based modelling in
ecology (especially behavioural ecology) have to say. Goal: find a
typology clade can be placed within, rather than inventing one.*

*Survey started 2026-04-19. Search terms used: "review agent-based
simulation behavioural ecology 2020 2021 2022 typology methods";
"agent-based models review ecology framework Grimm 2020 2021 2022
typology". Results below are from WebSearch; full-text fetches
blocked by paywalls for some.*

---

## Core framework papers (established, pre-2020)

### Grimm et al. ODD protocol

- **Grimm, V., Berger, U., Bastiansen, F., Eliassen, S., et al.
  (2006).** *A standard protocol for describing individual-based and
  agent-based models.* Ecol. Model. 198, 115–126.
  [`10.1016/j.ecolmodel.2006.04.023`]
- **Grimm, V., Berger, U., DeAngelis, D. L., Polhill, J. G., Giske,
  J., & Railsback, S. F. (2010).** *The ODD protocol: a review and
  first update.* Ecol. Model. 221, 2760–2768.
  [`10.1016/j.ecolmodel.2010.08.019`]
- **Grimm, V., et al. (2020).** *The ODD Protocol for Describing
  Agent-Based and Other Simulation Models: A Second Update to Improve
  Clarity, Replication, and Structural Realism.* JASSS 23(2).

**What ODD gives us**: a standard documentation protocol —
*Overview, Design concepts, Details* — for describing any ABM.
**Relevant to clade**: if we write an ODD for a clade scenario, it
becomes immediately comparable to the thousands of published ABMs
using the same protocol. Could be a vignette (`vignette("odd")`)
or a per-scenario section.

*Open action*: pick 1–2 exemplar scenarios and write their ODD
descriptions as a trial. Good candidates: `s-kin` (simple, known
biology), `s-baldwin` (complex, fluctuating selection).

### Grimm's Pattern-Oriented Modelling (POM)

- **Grimm, V., Revilla, E., Berger, U., et al. (2005).**
  *Pattern-oriented modeling of agent-based complex systems: lessons
  from ecology.* Science 310, 987–991.
  [`10.1126/science.1116681`]
- **Railsback, S. F. & Grimm, V. (2019).** *Agent-based and
  Individual-based Modeling: A Practical Introduction*, 2nd ed.
  Princeton University Press.
  [site](https://www.railsback-grimm-abm-book.com/)

**What POM gives us**: a methodology where a model is validated
against *multiple observed patterns at different scales* — e.g.,
individual behaviour AND population-level dynamics AND evolutionary
trajectory. Stronger than single-statistic validation.

**Relevant to clade**: our fidelity audit partially instantiates
POM — each scenario checks population-level patterns (e.g.,
"genetic diversity increases under sex") that correspond to
published predictions. A full POM framing would also check
individual-level patterns (agent behaviour), which we sometimes do
(e.g., `s-kin` altruistic-act counts) but not systematically.

*Open action*: map each of the 32 passing scenarios onto the POM
pattern-types it tests. Many will be "one population-level pattern";
some (`s-baldwin`, `s-cephalopod`) will hit two or three levels.
This would strengthen the audit's framing.

### Pragmatic vs. paradigmatic

- **Grimm, V. (1999).** *Ten years of individual-based modelling in
  ecology: what have we learned and what could we learn in the
  future?* Ecol. Model. 115, 129–148.

**Typology**:
- **Pragmatic ABMs** — address applied problems (specific species,
  specific management question).
- **Paradigmatic ABMs** — aimed at theoretical understanding (test
  a general hypothesis about how nature works).

**Relevant to clade**: clade's 32 scenarios are **overwhelmingly
paradigmatic** — testing Hamilton's rule, Baldwin effect, Red Queen,
etc. This is a positioning claim we can make with the right citation:
"clade is explicitly a paradigmatic-ABM testbed, in Grimm's 1999
sense." That's precise and defensible.

---

## Targeted reviews — abstracts retrieved

### Murphy et al. 2025 — applied ecology ABMs

**Murphy, K. J. (2025).** *Agent-based models in applied ecology:
designing data-informed simulations for wildlife conservation and
management.* Ecosphere 16(9).
[`10.1002/ecs2.70342`] — CC-BY 4.0 open access (abstract retrieved
via Crossref 2026-04-19).

**Abstract (verbatim)**:

> *"Agent-based models (ABMs) are increasingly recognized as
> valuable tools in applied ecology for simulating species behavior,
> ecological interactions, and responses to management. However,
> their adoption in conservation and policy contexts has been
> limited by a reliance on simplified representations and a lack of
> integration with empirical data. This paper presents a structured,
> data-informed framework for developing applied ABMs using
> high-resolution spatial, behavioral, and environmental datasets.
> By incorporating telemetry data, remote sensing products, and
> site-level ecological monitoring, the framework enables realistic
> simulations of ecological systems that can be used to virtually
> test management strategies and policy interventions. These models
> support real-time scenario testing, guide field data collection
> by identifying knowledge gaps, and facilitate transparent
> communication with stakeholders. We demonstrate the utility of
> this framework using a published case study on badger movement
> and bovine tuberculosis risk in a disturbance-driven landscape,
> showing how it reveals emergent behavioral patterns with
> implications for disease management."*

**Typology proposed**: a **framework for applied / data-informed
ABMs** with three ingredients — (i) telemetry data, (ii) remote
sensing, (iii) site-level ecological monitoring — yielding models
that *"virtually test management strategies and policy
interventions"*.

**Implication for clade's positioning**: Murphy 2025 is
*unambiguously in the pragmatic ABM camp* (Grimm 1999 typology). The
paper's framework — telemetry + remote sensing + site monitoring for
a named management target — is exactly what clade is *not*. clade
has no telemetry pipeline, no remote-sensing coupling, no
single-species target, no management or policy claim. Instead clade
tests classical behavioural-ecology predictions at the mechanistic
level.

**Positioning claim this unlocks** (with this source as evidence):

> *"Applied / data-informed wildlife-management ABMs (Murphy 2025
> framework: telemetry + remote sensing + site monitoring for a
> management target) → not clade. clade is a paradigmatic testbed
> for mechanisms from the behavioural-ecology literature, not a
> conservation-decision tool."*

Full reference extraction to do when time permits: the paper cites
64 works; relevant prior reviews among them likely inform the
broader ABM-in-ecology typology landscape.

### Stillman et al. 2015 — individual-based ecology (IBE)

**Stillman, R. A., Railsback, S. F., Giske, J., Berger, U. & Grimm,
V. (2015).** *Making predictions in a changing world: the benefits
of individual-based ecology.* BioScience 65, 140–150.
[`10.1093/biosci/biu192`](https://academic.oup.com/bioscience/article/65/2/140/2754218)
— open access (abstract + key quotes retrieved 2026-04-19).

**Abstract (verbatim)**:

> *"Ecologists urgently need a better ability to predict how
> environmental change affects biodiversity. We examine
> individual-based ecology (IBE), a research paradigm that promises
> better a predictive ability by using individual-based models
> (IBMs) to represent ecological dynamics as arising from how
> individuals interact with their environment and with each other."*

**Definition of IBM**: models that *"explicitly represent discrete
individuals within a population and their individual life cycles"*;
*"the behavior underlying demographic rates results from the
individuals' behavioral decisions, which are based on fitness-
related decision rules."*

**Three-phase typology Stillman et al. propose**:

1. **Conceptualization** — identifying research questions and
   framework appropriateness.
2. **Implementation** — developing and validating the initial IBM.
3. **Diversification** — simplification, generalization, validation
   across systems.

**Exemplar application systems named**: stream trout (`inSTREAM`),
coastal birds (`MORPH`), forest dynamics (mangroves, gap models),
plant competition (`KiWi`), microbial populations. All are
*prediction tasks for named species/systems* — applied-ecology,
not paradigmatic.

**Platforms mentioned**: *"General IBM platforms, such as
NetLogo…have evolved with the practice of IBE"*. Also custom
platforms (`MORPH`, `inSTREAM`, `KiWi`, `IBU`).

**On behavioural ecology**: *"In behavioral ecology, the theory for
risk-growth trade-offs was well established but only for situations
in which the future is known."* IBE uses behavioural-ecology theory
as a *substrate* for individual decision rules, so IBMs can predict
novel situations via fitness-maximising logic.

**Implication for clade's positioning**: Stillman et al. is the
closest single paper to where clade could claim a position — they
legitimise IBMs that use behavioural-ecology decision rules as
their core mechanism. But the paper's *goal* is prediction for
environmental-change management (ecological forecasting), whereas
clade's goal is *mechanism testing* (does the simulator reproduce
Hamilton's prediction given his assumptions?).

The distinction that matters:

- **IBE (Stillman et al. 2015)**: behavioural theory → IBM → predict
  real-world system response. Validation via match to observed
  ecological dynamics.
- **clade**: behavioural theory → IBM → verify the theory's
  mechanism reproduces under simulation. Validation via match to
  published theoretical prediction (direction-correct, |t| ≥ 2).

These are complementary, not competitive. A citation to Stillman et
al. in a `why-clade` vignette would be appropriate *if* we frame
clade as a paradigmatic-IBE testbed — Stillman's paradigmatic
sibling — rather than part of the IBE-for-prediction tradition.

**Positioning claim this unlocks**:

> *"Individual-based ecology (Stillman et al. 2015) uses IBMs to
> predict real-world ecological dynamics under environmental change.
> clade shares the IBM mechanics but uses them paradigmatically —
> to verify whether canonical behavioural-ecology predictions
> reproduce from first principles. The two traditions are
> complementary: Stillman IBMs consume theory for forecasting; clade
> consumes theory for mechanism-level verification."*

### JASSS 2017 — social-ecological systems

**An, L., et al. (2017).** *Agent-Based Modelling of Social-
Ecological Systems: Achievements, Challenges, and a Way Forward.*
JASSS 20(2).
[`10.18564/jasss.3387`](https://www.jasss.org/20/2/8.html)

- **Why relevant**: open-access review of SES ABMs. Has typology
  sections.
- **Open action**: full fetch + extract typology.

### Plant ecology ABMs

**DeAngelis, D. L. & Grimm, V. (2014), and more recent (2020).**
*An overview of agent-based models in plant biology and ecology.*
PMC [`PMC7489105`](https://pmc.ncbi.nlm.nih.gov/articles/PMC7489105/).

- **Why relevant**: reasonable paradigm comparison — plants don't
  have neural brains, clade does, so comparison is useful for
  positioning.
- **Open action**: fetch + extract typology.

---

## Neural-evolution / digital-organism reviews (separate thread)

clade sits at the intersection of behavioural-ecology IBMs AND
neural-evolution / artificial-life. Reviews from the latter genre:

- **Komosinski, M. & Adamatzky, A. (eds., 2009).** *Artificial Life
  Models in Software*, 2nd ed. Springer. (Chapter on Polyworld,
  Framsticks, Tierra, Avida — may provide a typology.)
- **Eiben, A. E. & Smith, J. E. (2015).** *From evolutionary
  computation to the evolution of things.* Nature 521, 476–482.
  (Broader evolutionary-computation perspective; may cite Avida,
  Polyworld.)
- **Channon, A. (2019).** *Unbounded evolutionary dynamics in a
  system of agents that actively press against the boundary of their
  niches.* Artif. Life 25, 341–367. (Discusses open-ended-evolution
  simulators; good for neural-genre context.)

**Open action**: find a review paper that surveys the neural-brain-
evolution simulator genre. clade's niche claim strength depends on
what Polyworld / Framsticks / Evosphere actually do in 2026 and how
they compare.

---

## Candidate typology positions for clade

Given the above, these are the typology placements that are **most
defensible** with current evidence:

1. **"Paradigmatic ABM" (Grimm 1999)** — clade tests general
   hypotheses, not specific species or applied management problems.
   Well-supported.
2. **"Neural-brain individual-based model"** — distinguishing from
   purely rule-based ABMs (NetLogo models) and from allele-only
   evolutionary simulators (SLiM). Needs verification against
   Polyworld / Framsticks genre.
3. **"Forward-time, phenotype-first evolutionary IBM"** —
   distinguishing from msprime (coalescent / backward-time) and
   from SLiM-style allele-centric forward-time.
4. **"Literature-audited testbed"** — the 32/32 fidelity-audit
   framing. Novel as a systematic feature; I have not (yet) found
   another ABM simulator that ships with paper-grounded multi-seed
   audits baked into every scenario.

(4) is the most distinctive positioning claim we can make and the
hardest to attack if the primary-citation audit (see
[`primary_citation_audit_plan.md`](primary_citation_audit_plan.md))
holds up.

---

## What's missing from this research so far

- **Polyworld / Framsticks / Evosphere current positioning** — need
  first-person fetches when user has time to guide which are worth
  comparing in detail.
- **Is there a systematic review of "evolutionary ABMs in
  behavioural ecology" specifically?** Initial search didn't surface
  one. If none exists, clade's own documentation could itself
  become such a reference over time.

---

## Log

- **2026-04-19** — initial survey. Established Grimm's ODD/POM
  frameworks, pragmatic-vs-paradigmatic typology. Identified Murphy
  2025 and Stillman 2015 as highest-priority targets for full-text
  review. Paywalled — deferred until user can pull the PDFs.
- **2026-04-19 (later)** — user provided open-access URLs.
  **Murphy 2025** abstract retrieved via Crossref (paper is CC-BY
  4.0; Wiley's site bot-blocks so Crossref was the working route).
  Paper is firmly pragmatic / applied — telemetry + remote sensing
  + site monitoring → management tool. Sharpens clade's
  not-clade column. **Stillman 2015** abstract + key quotes
  retrieved from BioScience (Oxford Academic). Paper is a
  behavioural-ecology-substrate IBM framework for *ecological
  forecasting* (environmental-change prediction). clade is the
  paradigmatic sibling — same IBM mechanics, different goal
  (mechanism verification). Both entries above updated with
  verbatim quotes and positioning implications.
