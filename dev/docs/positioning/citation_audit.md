---
name: Primary-citation audit
description: Per-scenario verification that clade's cited primary literature actually predicts what clade reproduces. Multi-session. Currently Session 1 complete (6/32).
type: research
---

# Primary-citation audit — per-scenario ledger

*Audit of whether each clade scenario's cited primary literature
actually predicts the specific outcome clade reproduces. Begun
2026-04-19 under the plan in
[`primary_citation_audit_plan.md`](primary_citation_audit_plan.md).*

**Progress: Session 1 complete — 6 of 32 auditable scenarios
audited.**

Verdicts:
- ✅ **Citation correct, claim correct** — the cited paper does
  make the prediction clade reproduces, in the direction clade
  reproduces, with no material gap between the paper's claim and
  clade's implementation.
- ⚠️ **Citation correct, caveat needed** — cited paper is relevant
  and direction-correct, but the clade scenario tests a *corollary*
  or *subset* of the paper's claim, or omits important caveats the
  paper itself raised. Documented here so vignette authors can
  decide whether to extend the prose.
- 🟠 **Citation approximate, better citation exists** — the cited
  paper is in the right ballpark but another paper would be a more
  precise match for the specific mechanism or claim being
  reproduced.
- ❌ **Citation incorrect or unsupported** — the cited paper does
  not make the claim attributed to it, or clade's result
  contradicts the cited paper's direction. (Zero entries expected;
  any hits should trigger immediate scenario-prose correction.)

---

## Ledger

| Scenario | Primary citation(s) in vignette | Specific claim tested | Direction predicted | clade's result | Verdict |
|---|---|---|---|---|---|
| **s-kin** | Hamilton (1964); Fromhage & Jennions (2019) for IFfolk; Hardin (1968) for tragedy-of-commons framing | Altruism to kin increases population-level carrying capacity when rB/C > 1; direction reverses when rB/C < 1 | Population rises with rB/C | Spearman ρ = 0.97 between rB/C and equilibrium population across 9 regimes; default rB/C = 1.25 gives +16%, rB/C = 2.5 gives +27%, rB/C = 0.1 gives −7.7% | ⚠️ *See §s-kin* |
| **s-cooperation** | Nowak & May (1992); Hauert et al. (2002); Hardin (1968) | Spatial clustering sustains cooperation in a public-goods dilemma above a multiplier threshold; free-rider invasion erodes cooperation level even as population size rises | Sharp population transition at critical multiplier; cooperation level drifts downward | ρ = 1.00 between `cooperation_multiplier` and population; sharp transition at M ≈ 2.0; cooperation level drifts 0.500 → 0.486 over 400 ticks | 🟠 *See §s-cooperation* |
| **s-signals** | Zahavi (1975); Fisher (1930) | Condition-dependent costly signals correlate positively with bearer condition (Zahavi); alternatively, runaway mate preference + signal coevolution drives both to fixation (Fisher) | Positive signal–condition correlation (Zahavi); runaway signal divergence without condition match (Fisher) | Within-run Spearman ρ = 0.25 between `mean_energy` and `mean_signal_magnitude` across 5 seeds (direction correct, weak); signal magnitude *flat* at ~1.0 across cost 0.0–0.20 (contradicts strict Zahavi magnitude prediction) | ⚠️ *See §s-signals* |
| **s-mating-systems** | Maynard Smith (1978); Williams (1975); Hamilton (1980) | Sex's two-fold cost is offset by parasite-driven coevolution (Red Queen) in sufficiently harsh regimes | Sex > asex in genetic diversity or population size under parasite pressure | 0.5.3 regime search across 16 cells: all regimes show direction correct on average, *none* crosses 2×SE at 8 seeds; top 3 go flat at 16 seeds. Vignette verdict: 🟠 direction-correct, sub-2σ | 🟠 *See §s-mating-systems* |
| **s-parental-care** | Smith & Fretwell (1974); Clutton-Brock (no year) | Parental care trades offspring quantity for offspring quality (Smith & Fretwell); care buffers population against demographic shocks (Clutton-Brock) | Non-zero juvenile count; lower population variance with care | Juveniles persist at 1.24/tick with care vs 0 without (P1 PASS); population variance 4625 vs 4548 — no measurable buffering (P2 FAIL) | ⚠️ *See §s-parental-care* |
| **s-life-history** | Cole (1954); Williams (1966); Roff (1992) | Semelparity trades longevity for reproductive burst; iteroparity sustains smoother birth rates and higher mean age; fitness gap is small (Cole's paradox) | sem `mean_age` < iter; sem `n_births` > iter; sem `mean_energy` < iter | All three sign predictions hold across 5 seeds (sem 13.0 vs iter 101.5 age; sem 4.2 vs iter 0.89 births/tick; sem 84.7 vs iter 127.1 energy). Emergent finding: sem is 674× more stable than iter (*not* predicted by the cited literature) | ✅ *See §s-life-history* |

---

## Per-scenario notes

### s-kin — Hamilton (1964) ⚠️

**Full citation (need to confirm exact wording in vignette prose
against a published edition)**:

> Hamilton, W. D. (1964). The genetical evolution of social
> behaviour. I & II. *Journal of Theoretical Biology* 7, 1–52.

**What Hamilton actually predicts**: an allele for altruistic
behaviour invades and fixes when the inclusive-fitness condition
*rB > C* holds, where r is genetic relatedness, B is the benefit
to the recipient, and C is the cost to the actor.

**What clade reproduces**: at the *population* level, carrying
capacity rises monotonically with rB/C (Spearman ρ = 0.97 across a
9-cell C×B grid). A regime with rB/C < 1 produces a measurable
population *decrease*.

**The material gap**: clade's kin altruism module performs altruism
*deterministically* when gates (relatedness threshold, donor-energy
floor) fire — there is no heritable altruism allele in this module.
Hamilton's original proof is about *invasion dynamics of an
altruistic allele*; clade tests the *demographic consequence of
imposed altruism*. The vignette itself notes this
([`vignettes/s-kin.Rmd:127-133`](../../vignettes/s-kin.Rmd#L127)):
"this audit tests the population-level consequences of Hamilton's
rule, not the invasion dynamics of an altruistic mutant. For the
evolutionary dynamics (heritable `helper_tendency`), see the
cooperative-breeding and IFfolk modules below."

**Audit call**: citation is correct; vignette already flags the
gap. No prose change needed. **⚠️ kept as ⚠️ rather than ✅
because the ledger entry for s-kin should cite the scope
limitation explicitly — landing-page copy that says "clade
reproduces Hamilton's rule" without the demographic-vs-invasion
nuance would be overclaiming.**

### s-cooperation — Nowak & May (1992) + Hauert et al. (2002) 🟠

**Citations in vignette**:

> Nowak, M. A. & May, R. M. (1992). Evolutionary games and spatial
> chaos. *Nature* 359, 826–829.

> Hauert, C., De Monte, S., Hofbauer, J. & Sigmund, K. (2002).
> Volunteering as Red Queen mechanism for cooperation in public
> goods games. *Science* 296, 1129–1132.

**What each paper actually predicts**:

- *Nowak & May 1992*: in spatial Prisoner's Dilemma, cooperators
  and defectors coexist (sometimes chaotically) because
  cluster-boundary dynamics protect cooperator interiors. Sharp
  payoff-matrix thresholds separate regimes.
- *Hauert et al. 2002*: adding *voluntary participation* ("loner"
  strategy) produces Rock-Paper-Scissors cycling (cooperator →
  defector → loner → cooperator) that maintains cooperation in
  public-goods games.

**What clade reproduces**: sharp population transition at
`cooperation_multiplier` ≈ 2.0 (Spearman ρ = 1.00); cooperation
level drifts downward while population rises (public-goods benefit
> individual-level selection, tragedy-of-commons signature).

**The material gap**: clade implements a **spatial public-goods
game with continuous cooperation strategies**. Nowak & May 1992 is
a pairwise PD, not public goods — the citation is directionally
correct (spatial structure enables cooperation) but not a precise
mechanism match. Hauert et al. 2002 is *public goods with
volunteering*, but clade does not implement volunteering/loner
strategies. A **better primary citation for clade's implemented
mechanism** would be:

> Hauert, C., Michor, F., Nowak, M. A. & Doebeli, M. (2006).
> Synergy and discounting of cooperation in social dilemmas.
> *Journal of Theoretical Biology* 239, 195–202.

or

> Killingback, T., Doebeli, M. & Knowlton, N. (1999). Variable
> investment, the Continuous Prisoner's Dilemma, and the origin of
> cooperation. *Proceedings of the Royal Society B* 266, 1723–1728.

Both are closer to clade's *continuous-strategy spatial public
goods* setup.

**Audit call**: 🟠. Vignette prose should be tightened to cite the
more precise continuous-strategy spatial-PD reference. Keep Nowak
& May 1992 as the general spatial-cooperation progenitor, but
demote it from "Nowak & May established ... clade reproduces" to
"following Nowak & May's spatial framework, extended to continuous
public-goods strategies by Killingback et al. (1999) / Hauert et
al. (2006), clade reproduces ...".

### s-signals — Zahavi (1975) + Fisher (1930) ⚠️

**Citations in vignette**:

> Zahavi, A. (1975). Mate selection — a selection for a handicap.
> *Journal of Theoretical Biology* 53, 205–214.

> Fisher, R. A. (1930). *The Genetical Theory of Natural
> Selection*. Oxford: Clarendon Press.

**What each paper predicts**:

- *Zahavi 1975*: costly signals honestly reveal bearer condition;
  signal magnitude should *vary with cost* (more able bearers pay
  the handicap, less able bearers cannot).
- *Fisher 1930*: runaway signal–preference coevolution once a
  female preference is established; signal can decouple from
  condition.

**What clade reproduces**:
- Within-run ρ = 0.25 between `mean_energy` and `mean_signal_magnitude`
  — direction-correct Zahavi result, but **modest effect size**.
- **Signal magnitude is flat at ~1.0 across cost 0.0–0.20** — this
  is *the opposite* of Zahavi's central prediction that higher cost
  should reduce signal magnitude. Cost in clade manifests as
  demographic attrition, not signal compression.
- The vignette explicitly says: *"drift determines signal stationary
  distribution, while cost manifests as demographic attrition rather
  than signal reduction. For strict textbook Zahavi dynamics (cost
  reduces signal magnitude) a kernel extension with heritable
  individual-level preferences would be needed."*

**Material gap with Fisher 1930**: runaway dynamics are *not*
demonstrated in the current audit. clade has the structural
capacity (signal + preference + mate choice) but no 5-seed audit
has shown signal divergence decoupled from condition.

**Audit call**: ⚠️. The Zahavi citation is defensible for the
direction-correct correlation but **overclaims** if read as "clade
reproduces the handicap principle". clade reproduces *a weak
positive condition-signal correlation*, which is the *minimum*
Zahavi prediction; the *diagnostic* Zahavi prediction (cost scales
signal magnitude) is contradicted. The vignette is already honest
about this — propose tightening landing-page and `why-clade.Rmd`
prose accordingly. The Fisher citation should be marked as
"structural capacity, not currently audited" until a dedicated
runaway-dynamics audit is added. Relevant user memory: Zahavi's
handicap may not work in realistic settings
([reference_zahavi_critique](../../../.claude/.../reference_zahavi_critique.md)).

### s-mating-systems — Hamilton (1980) ⚠️ citation-precision

**Citations in vignette**:

> Maynard Smith, J. (1978). *The Evolution of Sex*. Cambridge
> University Press.
> Williams, G. C. (1975). *Sex and Evolution*. Princeton University
> Press.
> Hamilton, W. D. (1980). Sex versus non-sex versus parasite.
> *Oikos* 35, 282–290.

**What the papers predict**:
- Maynard Smith 1978 / Williams 1975: sex's two-fold cost requires
  a substantial benefit to be maintained; parasites are a candidate.
- Hamilton 1980: in a continuous-trait coevolving-parasite system,
  recombination maintains rare genotypes that parasites cannot
  track — but Hamilton himself notes this is "a tall order" because
  the benefit must exceed sex's two-fold cost.

**What clade reproduces**: 0.5.1 module implements
**discrete-allele Hamming matching** (parasites track host haplotype
hash; match inflicts mortality). Direction-correct on average
across 16 regimes; no regime crosses 2×SE at 8 seeds or 16 seeds.
Vignette verdict 🟠.

**Material gap**: the *specific mechanism* clade implements
(haploid discrete-allele + Hamming + frequency-dependent parasite
tracking) is a cleaner match to

> Hamilton, W. D., Axelrod, R. & Tanese, R. (1990). Sexual
> reproduction as an adaptation to resist parasites (a review).
> *PNAS* 87, 3566–3573.

which formalises the discrete-allele Red Queen. Hamilton 1980 is
the conceptual progenitor; Hamilton, Axelrod & Tanese 1990 is the
specific-mechanism match.

**Audit call**: ⚠️. Hamilton 1980 is correct as the conceptual
reference. For a reader to find the *exact* mechanism clade
implements, Hamilton, Axelrod & Tanese 1990 should be cited
alongside. The honest 🟠 verdict clade already reports aligns with
Hamilton 1980's own caveat (sex's two-fold cost is a tall order) —
the vignette prose is already honest about this.

### s-parental-care — Smith & Fretwell (1974) + Clutton-Brock ⚠️

**Citations in vignette**:

> Smith, C. C. & Fretwell, S. D. (1974). The optimal balance
> between size and number of offspring. *American Naturalist* 108,
> 499–506.

> "Clutton-Brock" — no year. Most likely:
> Clutton-Brock, T. H. (1991). *The Evolution of Parental Care*.
> Princeton University Press.

**What each predicts**:
- Smith & Fretwell 1974: parents choose *offspring size* to
  maximise *offspring fitness × offspring count*. The core
  prediction is about optimal offspring *size*, not about
  population-level variance.
- Clutton-Brock 1991: parental care buffers offspring against
  environmental stochasticity, reducing variance in fledging
  success.

**What clade reproduces**:
- Juveniles persist at 1.24/tick with care vs 0 without — a basic
  **graduation pathway** test, not an offspring-size test.
- Population variance 4625 (care) vs 4548 (no-care) — effectively
  no measurable buffering. **The Clutton-Brock variance-buffering
  prediction is not reproduced at default parameters.**

**Material gaps**:
1. Smith & Fretwell 1974's *specific* prediction (offspring size
   trade-off) is not directly tested — the scenario instead tests
   presence/absence of offspring graduation, which is a weaker
   demonstration.
2. The Clutton-Brock buffering prediction is explicitly a FAIL at
   default parameters, yet the citation remains. The vignette
   notes this honestly ("tighter resource scarcity or higher
   care_cost_per_tick needed").

**Audit call**: ⚠️. The Smith & Fretwell citation is approximately
correct (both papers are in the parental-care-trade-off family)
but the specific claim tested (juvenile graduation) is not what
Smith & Fretwell predicted. Suggest either:

- (a) Tightening the scenario to actually measure the quality-
  quantity trade-off Smith & Fretwell predicted (mean offspring
  energy vs parent clutch size), *or*
- (b) Replacing Smith & Fretwell citation with a specific paper
  that predicts the graduation pathway (Trivers 1972 "Parental
  investment and sexual selection" is closer in spirit but still
  doesn't predict graduation per se; Lack 1947 "The significance
  of clutch size" is another candidate).

The Clutton-Brock citation needs a year pinned and the 🟠 FAIL on
buffering needs to be surfaced in the vignette header, not only
buried in the results table.

### s-life-history — Cole (1954) + Williams (1966) + Roff (1992) ✅

**Citations in vignette**:

> Cole, L. C. (1954). The population consequences of life history
> phenomena. *Quarterly Review of Biology* 29, 103–137.
> Williams, G. C. (1966). Natural selection, the costs of
> reproduction, and a refinement of Lack's principle. *American
> Naturalist* 100, 687–690.
> Roff, D. A. (1992). *The Evolution of Life Histories*. Chapman
> & Hall.

**What the papers predict**:
- Cole 1954: iteroparity's advantage over semelparity is small —
  "one extra surviving offspring" equalises the two strategies
  under simple demography.
- Williams 1966: semelparous organisms pay a full reproductive
  cost in their single event; iteroparous organisms can spread
  the cost.
- Roff 1992: divergence between strategies is driven by relative
  juvenile/adult survival, resource reliability, and seasonality.

**What clade reproduces**:
- sem `mean_age` 13.0 < iter 101.5 ✓
- sem `n_births`/tick 4.20 > iter 0.89 ✓
- sem `mean_energy` 84.7 < iter 127.1 (Williams 1966 cost of
  reproduction) ✓

**Emergent finding** (not attributed to cited literature): sem
population variance is 674× *lower* than iter. Vignette handles
this honestly — marks it as emergent, not predicted.

**Audit call**: ✅. All three sign predictions match. The
emergent variance finding is appropriately flagged as a novel
scientific observation. Consider adding a brief note that
Stearns (1992) *The Evolution of Life Histories* also covers the
sem/iter comparison — the plan document had listed Stearns as the
expected citation; Roff 1992 covers the same ground and is the
vignette's choice. Both are defensible textbooks.

---

## Session 1 summary

- **6 scenarios audited** (s-kin, s-cooperation, s-signals,
  s-mating-systems, s-parental-care, s-life-history).
- **1 ✅, 4 ⚠️, 1 🟠, 0 ❌**. Zero scenarios have outright-wrong
  citations; all cited papers are at minimum in the right research
  programme.
- **Common pattern across ⚠️ entries**: the scenario tests a
  *corollary* or *weaker version* of the cited paper's prediction.
  Vignette prose is usually honest about this, but landing-page
  and `why-clade.Rmd` aggregate copy could easily overclaim "clade
  reproduces Hamilton's rule / Zahavi's handicap / Smith &
  Fretwell's trade-off" without the caveats.
- **One specific swap recommended**: s-cooperation should cite a
  continuous-strategy spatial-PD paper (Hauert et al. 2006 or
  Killingback et al. 1999) as the primary mechanism reference;
  keep Nowak & May 1992 as the spatial-cooperation progenitor.
- **One specific addition recommended**: s-mating-systems should
  cite Hamilton, Axelrod & Tanese (1990) alongside Hamilton 1980
  as the specific discrete-allele mechanism reference.
- **One missing year**: s-parental-care's "Clutton-Brock" needs a
  specific year/edition pinned.

**No scenario needs an outright citation retraction** as a result
of Session 1 — but the aggregate-landing-page copy should be
tempered accordingly once Sessions 2–4 complete.

---

## Log

- **2026-04-19** — Session 1 complete. 6 scenarios audited; 1 ✅,
  4 ⚠️, 1 🟠. No retractions. Three specific citation-precision
  recommendations surfaced (Hauert swap, Hamilton-Axelrod-Tanese
  addition, Clutton-Brock year pin). Sessions 2–4 pending.
