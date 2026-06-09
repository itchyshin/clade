# Decision Log

Record durable project decisions here when they are broader than one task but
do not need a full design document yet.

## Template

```md
## YYYY-MM-DD - <decision title>

- Decision: <what changed or what rule was adopted>
- Reason: <why this is better for users, maintainers, validation, or release>
- Alternatives considered: <short list>
- Consequences: <what future work must respect>
- Evidence: <issue, PR, check-log entry, paper, benchmark, or design doc>
```

## 2026-06-08 — Decouple `female_investment` role contract from focal-agent convention

- Decision: When `sex_labels = TRUE`, the `parental_investment_evolution`
  cost-split is decoupled from which partner happens to initiate the
  reproductive event. `female_investment` now denotes the *mother's* share
  regardless of focal/mate roles; the father pays the complement; the
  `male_repro_cost` extra likewise targets whichever partner is male.
  When `sex_labels = FALSE`, the legacy "focal-agent = implicit mother"
  semantics are preserved exactly.
- Reason: The legacy contract was implicit and only meaningful when
  every reproductive event was assumed to be initiated by a female. Once
  agents have a sticky biological sex, the kernel can iterate over agents
  in any order (random tick scheduling has been on since 0.7.0) and a
  male can validly be the focal reproducer. Hard-binding the
  female-investment label to the focal agent would introduce a silent
  bias toward whichever sex happens to draw an earlier iteration index.
- Alternatives considered:
  - "Skip male focals when `sex_labels = TRUE`" — preserves the legacy
    label but wastes half the iteration steps and locks out future
    male-parental-care scenarios.
  - "Always have focal = female regardless of order" — would require
    re-sorting the agent iteration order at every tick, breaking the
    random-tick-order contract from 0.7.0.
- Consequences: `female_investment` is no longer "the focal agent's
  share" — it is "the mother's share". Vignettes that previously used
  `female_investment` in the legacy sense are unaffected because the
  legacy code path is preserved under `sex_labels = FALSE`. Any future
  feature that reads the cost-split must respect the sex-conditional
  branch: legacy semantics under FALSE, mother-based semantics under
  TRUE.
- Evidence: this entry; after-task report at
  [dev/dev-log/after-task/2026-06-08-sex-foundation.md](https://github.com/itchyshin/clade/blob/main/dev/dev-log/after-task/2026-06-08-sex-foundation.md);
  Rees-Baylis et al. 2026, *Nat. Commun.*, "Asymmetric life-history
  trade-offs shape sex-biased longevity patterns" (the analytical model
  this work is preparing to reproduce).

## 2026-06-08 — Sex-specific trait expression via duplicated gene slots (mechanism X)

- Decision: Sex-specific trait expression is implemented by adding new
  entries to the scalar-trait table (one female-expressed gene and one
  male-expressed gene per sex-specific trait), each diploid and
  expressed via clade's existing dominance model. The agent's expressed
  phenotype is read from the sex-matching gene at birth. The shared
  gene slot is retained as the inactive fallback so behaviour is
  unchanged when sex-specific expression is off.
- Reason: matches the Rees-Baylis 2026 Methods footnote ("two unlinked
  loci with sex-specifically expressed genes") within clade's diploid
  framework without introducing a haploid special case or sex-linkage
  of segregation. The new genes evolve independently — males and females
  can settle on different optima.
- Alternatives considered:
  - "Sex-of-expression flag on the single shared gene": cheaper but
    cannot model true intra-locus sexual independence — alleles would
    still be shared.
  - "Sex-linked chromosome": new locus inherited only from same-sex
    parent. More biological but requires a substantial genome-machinery
    overhaul.
  - "Reuse diploid alleles as the two sex copies" (treat maternal as
    female-expressed, paternal as male-expressed): zero new code but
    biologically wrong — forces matrilineal/patrilineal inheritance of
    sex-specific traits.
- Consequences: every new sex-specific trait costs two slots in the
  trait table (cheap, ~4 bytes each per haplotype) and requires Julia
  wiring in `_make_offspring()`, `_make_founder_agent()`,
  `_sample_traits()`, and `_mutate_traits()`. The `sex_specific_traits`
  spec lists which traits get the treatment per run.
- Evidence: this entry; `inst/julia/src/types.jl` (new `TRAIT_*` slots
  and `N_SCALAR_TRAITS = 24`); `inst/julia/src/genome.jl`
  (`_sample_traits`, `_mutate_traits` extensions);
  `vignettes/paper-rees-baylis-2026.Rmd`.

## 2026-06-08 — Hard-graft Rees-Baylis trade-off (B1, not B2)

- Decision: The Rees-Baylis et al. 2026 exponential survival↔
  reproduction trade-off is implemented as a modelled (hard-grafted)
  multiplicative modifier on male mating probability and female
  clutch size, rather than as an emergent property of clade's
  existing dynamics. The trade-off strength parameters live in the
  `sex_specific_tradeoffs` spec; both default to zero so no
  behaviour change occurs without explicit opt-in.
- Reason: the paper's predictions are framed around specific
  functional forms (eqs 7-9). An emergent-only reproduction
  ("aging_rate evolution + reproductive lifespan") would not deliver
  the directional Fig 2 / Fig 3 / Fig 4 patterns at clade's typical
  parameter regimes — the analytical model needs the exponential
  trade-off to produce its equilibria.
- Alternatives considered:
  - "Emergent only" (B2): more honest about clade as an ABM but
    unlikely to qualitatively reproduce Rees-Baylis Fig 2.
  - "Generic trade-off framework" (any trait × any phenotype):
    more flexible but bigger blast radius and defers the paper
    reproduction by another release.
- Consequences: the paper-reproduction vignette must honestly label
  the trade-off as modelled, not emergent. Future trade-off forms
  (linear, saturating, etc.) for other papers would require similar
  hard-grafts.
- Evidence: this entry; `inst/julia/src/reproduce.jl`
  (`_find_mate()` and `create_offspring!()` modifier blocks);
  `vignettes/paper-rees-baylis-2026.Rmd` "Honest discussion"
  section.

## 2026-06-08 — Persistent pair bonds tied to spatial proximity

- Decision: `mating_system = "monogamous_pair"` bonds are persistent
  in agent state (`union_partner_id`, `union_ticks`) but the rendez-
  vous for re-reproduction requires the bonded partner to be within
  `mate_search_radius` at the relevant tick. Distance-separated
  partners simply fail to mate that tick; the bond persists until
  partner death or stochastic divorce.
- Reason: clade is a local-interaction simulator with no global agent
  index. Maintaining a population-wide id→position lookup just for
  partner rendez-vous would couple every mating attempt to the full
  agent vector. Tying bonds to spatial proximity also models the
  biology — separated pairs in real species do fail to reproduce.
- Alternatives considered:
  - "Global partner lookup" (find partner anywhere): O(N) per
    attempt, breaks the local-interaction principle.
  - "Bonds dissolve when partners separate beyond radius":
    biologically reasonable but harder to test and would conflict
    with `divorce_rate` semantics.
- Consequences: union duration distributions will be sensitive to
  `mate_search_radius` and to agent mobility. Honest-discussion
  sections of pair-bond vignettes must own this.
- Evidence: this entry; `inst/julia/src/reproduce.jl`
  (`update_unions!`, `_find_mate` monogamous-pair filter, bond
  formation at successful mating); `vignettes/s-pair-bonds.Rmd`.
