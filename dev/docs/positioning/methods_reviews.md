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

## Targeted reviews (need to locate full text)

### Murphy et al. 2025 — applied ecology ABMs

**Murphy, S. M., et al. (2025).** *Agent-based models in applied
ecology: designing data-informed simulations for wildlife
conservation and management.* Ecosphere 16.
[`10.1002/ecs2.70342`]

- **Abstract**: not retrieved (Wiley paywall blocks WebFetch from
  this repo). Institutional access needed.
- **Why relevant**: if the paper proposes a typology of applied-
  ecology ABMs, clade can be placed outside it (clade is
  paradigmatic, not applied).
- **Open action**: acquire PDF; extract typology + cited prior
  reviews.

### Stillman et al. 2015 — behavioural-ecology IBMs

**Stillman, R. A., Railsback, S. F., Giske, J., Berger, U. & Grimm,
V. (2015).** *Making predictions in a changing world: the benefits
of individual-based ecology.* BioScience 65, 140–150.

- **Why relevant**: single closest paper to clade's positioning
  claim. Co-authored by Grimm. Title explicitly invokes
  "behavioural" / "individual-based ecology".
- **Open action**: acquire full text; check what typology they
  propose and whether they identify a software gap clade fills.

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

- **Murphy 2025 abstract + typology** — institutional access needed.
- **Stillman 2015 typology** — institutional access needed.
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
