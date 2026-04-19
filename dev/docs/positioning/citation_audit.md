---
name: Primary-citation audit
description: Per-scenario verification that clade's cited primary literature actually predicts what clade reproduces. Multi-session. Sessions 1+2+3 complete (24/32).
type: research
---

# Primary-citation audit — per-scenario ledger

*Audit of whether each clade scenario's cited primary literature
actually predicts the specific outcome clade reproduces. Begun
2026-04-19 under the plan in
[`primary_citation_audit_plan.md`](primary_citation_audit_plan.md).*

**Progress: Sessions 1 + 2 + 3 complete — 24 of 32 auditable
scenarios audited** (plus 1 marked ⚪ N/A).

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

## Session 3 — ecology and species-interactions (11 scenarios)

| Scenario | Primary citation(s) in vignette | Specific claim tested | clade's result | Verdict |
|---|---|---|---|---|
| **s-predator-prey** | Lotka (1925); Volterra (1926); Huffaker (1958) for patchy-spatial version | Sustained sinusoidal predator-prey oscillations with quarter-cycle lag | **NOT reproduced** — predators saturate at cap; quarter-cycle lag muted by evolving pursuit traits. Vignette explicitly states "this single change [evolving predators] is enough to break the textbook LV signature" | 🟠 *See §s-predator-prey* |
| **s-predation-neural** | Williams (1966); Lotka-Volterra | (a) Predation reduces prey equilibrium population (demographic top-down control); (b) predation preserves cognitive diversity (RETRACTED) | Claim (a): t = −3.64 PASS. Claim (b): t = −0.90, honestly retracted in-vignette at 2026-04-17 | ✅ *See §s-predation-neural* |
| **s-mimicry** | Ruxton, Sherratt & Speed (2004) *Avoiding Attack*; Bates (1862); Grafen (1990); Getty (2006); Számadó (2011) | Aposematism evolves under predation; handicap cost > predation benefit in well-fed regimes | Conditional PASS at predation-dominant ecology (grass_rate=0.08: +0.006); null at default (grass_rate=0.20: −0.001) | ⚠️ *See §s-mimicry* |
| **s-disease** | *(none cited)* | SIR epidemic dynamics — canonical framework is Kermack & McKendrick (1927) | Module implements SIR; epidemic curves track theory | ⚠️ *See §s-disease* |
| **s-group-defense** | Hamilton (1971) J Theor Biol 10.1016/0022-5193(71)90189-5 — "Geometry for the selfish herd" | Group aggregation reduces per-capita predation risk via dilution | **INVERSION**: group_defense ON consistently *lowers* prey population (Δn = −10.3, t = −2.85, wrong direction). Vignette explains: evolving predators adapt to grouped prey; clustered prey deplete local grass | 🟠 *See §s-group-defense* |
| **s-speciation** | Dieckmann & Doebeli (1999) Nature 10.1038/22521; Coyne & Orr (2004) *Speciation* | Disruptive selection + assortative mating → sympatric speciation; reproductive isolation accumulates with genetic distance | n_species rises from 1 to multiple clusters at `isolation_threshold = 0.15`; within-cluster diversity < between-cluster diversity | ✅ *See §s-speciation* |
| **s-niche** | Odling-Smee, Laland & Feldman (2003) *Niche Construction: The Neglected Process in Evolution* | Organisms that modify their environment create novel selection pressures (ecosystem engineering) | Shelter construction module fires; predator damage reduced in sheltered cells; `shelter_occupancy_bonus` needed for population-level heritable-niche-construction effect | ⚠️ *See §s-niche* |
| **s-complex-landscape** | Liedtke & Fromhage (2019) *by structural analogy* to cephalopod paradox | Rich resource accessible only to agents with the right morphology; wing_size evolves upward to access canopy | `mean_wing_size` rises; `n_canopy_agents` increases after threshold crossed | ⚠️ *See §s-complex-landscape* |
| **s-seasonal** | Boyce (1979) Am Nat 10.1086/283503 — "Seasonality and Patterns of Natural Selection for Life Histories" | Periodic resource variation produces boom-bust dynamics | Population tracks grass coverage with short lag; winter crashes + spring recoveries visible across `season_length`-cycle | ✅ *See §s-seasonal* |
| **s-scavenging** | DeVault, Rhodes & Shivik (2003) Oikos — "Scavenging by vertebrates" | Scavenging provides energy buffer under scarcity | **NOT reproduced quantitatively**: 192-run parameter sweep found no cell giving Δenergy > 0 at \|t\| ≥ 2 in the canonical direction. Module fires correctly; mean-energy claim does not survive the evolutionary-ABM setting | 🟠 *See §s-scavenging* |
| **s-dispersal-ifd** | Fretwell & Lucas (1970) Acta Biotheor 10.1007/BF01601953; Shine, Brown & Phillips (2011) for spatial sorting | IFD: distribute proportional to resources; dispersal-enhancing alleles surf invasion fronts | Δ = +0.021 ± 0.005 at `habitat_preference_strength = 2.0` (PASS, 4× within-seed sd); spatial sorting demonstrated at invasion fronts | ✅ *See §s-dispersal-ifd* |

---

## Per-scenario notes — Session 3

### s-predator-prey — Lotka (1925) + Volterra (1926) 🟠

**Citations (all verified)**:

- Lotka, A. J. (1925). *Elements of Physical Biology*. Williams & Wilkins.
- Volterra, V. (1926). Variazioni e fluttuazioni del numero d'individui
  in specie animali conviventi. *Mem. R. Accad. Lincei* 2:31-113.
- Huffaker, C. B. (1958). Experimental studies on predation:
  dispersion factors and predator-prey oscillations. *Hilgardia* 27,
  343–383.

**What Lotka-Volterra predicts**: sustained sinusoidal oscillations
with predator abundance tracking prey with a quarter-cycle lag.

**What clade reproduces**: **not** the LV signature. Evolving
predators adapt to prey density, saturating at `predator_max_agents`
and maintaining that level even as prey oscillate. The classic
quarter-cycle lag is muted.

**Audit call**: 🟠. Citations correct. The vignette explicitly
documents the mismatch — "This single change [evolving predators]
is enough to break the textbook LV signature, in a specific and
well-documented way." The scenario is framed as a demonstration of
evolutionary-ABM *departing* from mean-field LV, which is a
legitimate scientific framing but means clade does not reproduce
the cited prediction directly.

### s-predation-neural — Williams (1966) ✅

**Citations (verified)**:

- Williams, G. C. (1966). *Adaptation and Natural Selection*.
  Princeton University Press. (For "demographic top-down control"
  framing.)
- Lotka-Volterra (as above).

**What is claimed**: (a) predation reduces prey equilibrium
population through mortality; (b) *(retracted in-vignette 2026-04-17)*
predation preserves cognitive genetic diversity.

**What clade reproduces**: (a) t = −3.64 PASS across 8 seeds × 2
conditions; (b) t = −0.90 null — mutation-bounded diversity floor
prevents directional selection from pushing diversity above the
mutation-noise bar. Retracted honestly.

**Audit call**: ✅. Citation and remaining claim direction-correct.
The honest retraction of claim (b) is exemplary audit hygiene.

### s-mimicry — Ruxton et al. (2004) + Bates (1862) + Grafen (1990) + Getty (2006) + Számadó (2011) ⚠️

**Citations (verified; key ones)**:

- Ruxton, G. D., Sherratt, T. N. & Speed, M. P. (2004). *Avoiding
  Attack: The Evolutionary Ecology of Crypsis, Warning Signals and
  Mimicry*. Oxford University Press.
  [`10.1093/acprof:oso/9780198528609.001.0001`]
- Bates, H. W. (1862). Contributions to an insect fauna of the
  Amazon valley. *Trans. Linn. Soc. London* 23, 495–566.

**What the literature predicts**: aposematism evolves when
predation selection outweighs the handicap cost of toxicity.
Grafen (1990) and the handicap-principle followups (Getty 2006;
Számadó 2011) specify when the handicap-equilibrium fails.

**What clade reproduces**: conditional PASS at predation-dominant
ecology (grass_rate=0.08: +0.006 toxicity rise over 600 ticks).
Null at default well-fed regime (grass_rate=0.20: −0.001), because
the Zahavi handicap cost exceeds the benefit — *exactly* the
condition Grafen/Getty/Számadó describe.

**Audit call**: ⚠️. Citations correct. The conditional-PASS result
is honest and the failure regime is correctly attributed to
theoretical caveats in the handicap literature. Relevant user
memory: Zahavi-handicap may not work in realistic settings
(`reference_zahavi_critique`).

### s-disease — (no primary citation) ⚠️

**No explicit primary-literature citation in the vignette**.

**What clade implements**: textbook SIR model (Susceptible,
Infected, Recovered states; per-tick transmission probability;
recovery duration; immune period). The canonical source is

> Kermack, W. O. & McKendrick, A. G. (1927). A contribution to the
> mathematical theory of epidemics. *Proc. R. Soc. A* 115, 700–721.

but this paper is not cited anywhere in the vignette.

**What clade reproduces**: epidemic curves with rise during
first 10-30 ticks and decline as recovery + immunity reduce the
susceptible pool. Qualitatively matches Kermack-McKendrick.

**Audit call**: ⚠️. Module implementation is correct and
direction-correct for the SIR framework. Missing citation for the
canonical SIR paper. Scenario prose should add Kermack & McKendrick
1927 or the equivalent textbook attribution.

### s-group-defense — Hamilton (1971) 🟠

**Citation (verified)**:

> Hamilton, W. D. (1971). Geometry for the selfish herd. *Journal
> of Theoretical Biology* 31, 295–311.
> [`10.1016/0022-5193(71)90189-5`]

**What Hamilton 1971 predicts**: in groups, per-capita predation
risk declines as 1/n (dilution) because the predator can attack
only one agent per encounter. Prediction assumes *fixed-strategy*
predators and *unlimited* food.

**What clade reproduces**: the attack-reduction *mechanism* fires
(pooled damage reduction within `group_defense_radius`), but
population-level outcome **inverts** — group_defense ON gives Δn =
−10.3, t = −2.85 (significant, wrong direction).

**Why the inversion**: (a) evolving predators adapt to the grouped
prey distribution faster than the defense reduces per-prey risk,
and (b) clustered prey deplete local grass, so defense-induced
aggregation starves the group. Both violate Hamilton 1971's
assumptions.

**Audit call**: 🟠. Citation correct. Prediction NOT reproduced —
contradicted at the population level under clade's evolving-
predator + limited-food ABM setting. Vignette honestly documents
this as an honest null where a canonical-theory assumption doesn't
survive the ABM setting. Direction-correct *mechanism* (attack
reduction fires) co-exists with direction-incorrect *population
outcome*.

### s-speciation — Dieckmann & Doebeli (1999) + Coyne & Orr (2004) ✅

**Citations (verified)**:

- Dieckmann, U. & Doebeli, M. (1999). On the origin of species by
  sympatric speciation. *Nature* 400, 354–357. [`10.1038/22521`]
- Coyne, J. A. & Orr, H. A. (2004). *Speciation*. Sinauer
  Associates.

**What the papers predict**:

- *Dieckmann & Doebeli 1999*: disruptive selection on a
  resource-use trait, combined with assortative mating, splits a
  single population into reproductively isolated lineages — the
  canonical sympatric-speciation model.
- *Coyne & Orr 2004*: reproductive isolation accumulates
  approximately linearly with genetic distance.

**What clade reproduces**: `n_species` rises from 1 to multiple
clusters under `isolation_threshold = 0.15`, with within-cluster
diversity consistently below between-cluster divergence.

**Audit call**: ✅. Both citations correct, direction-correct, no
material gap.

### s-niche — Odling-Smee, Laland & Feldman (2003) ⚠️

**Citation (verified)**:

> Odling-Smee, F. J., Laland, K. N. & Feldman, M. W. (2003). *Niche
> Construction: The Neglected Process in Evolution*. Princeton
> University Press.

**What the book predicts**: organisms that modify their selective
environment can drive evolutionary change — the ecosystem-engineer
principle. Formal predictions include *ecological inheritance* and
*genuine feedback between constructed niches and gene-frequency
dynamics*.

**What clade reproduces**: `n_shelters_built > 0`; predator damage
reduced in sheltered cells. The heritable-feedback loop requires
`shelter_occupancy_bonus > 0` to close — without it, shelter
construction is phenotypically visible but doesn't alter selection
on the builder trait.

**Material gap**: the canonical Odling-Smee et al. 2003 claim
involves a *heritable* feedback between environment construction
and gene-frequency dynamics. clade's default parameters fire the
construction module but don't create the heritable feedback
explicitly (bonus = 0 by default). Scenario reproduces the
*mechanism* of niche construction but tests only a subset of the
*evolutionary* prediction.

**Audit call**: ⚠️. Citation correct. Reproduction at the
mechanism level; the heritable-feedback-loop prediction requires
non-default parameter settings.

### s-complex-landscape — Liedtke & Fromhage (2019) by analogy ⚠️

**Citation (verified via PR #84 for s-cephalopod)**:

> Liedtke, J. & Fromhage, L. (2019). Need for speed: Short
> lifespan selects for increased learning ability. *Scientific
> Reports* 9, 15199. [`10.1038/s41598-019-51652-5`]

**What Liedtke & Fromhage predict**: short-lifespan agents evolve
faster within-lifetime learning. The paper is about
*cognition-vs-lifespan*, not *morphology-for-niche-access*.

**What clade reproduces**: `mean_wing_size` evolves upward to
access the high-energy canopy niche; `n_canopy_agents` rises after
the wing-size threshold is crossed.

**Material gap**: the vignette cites Liedtke & Fromhage 2019 "by
structural analogy" — the analogy being "rich resource accessible
only to agents that have evolved the morphology to exploit it".
This is a *paraphrase* of a general ecological principle, not a
direct reproduction of Liedtke & Fromhage's specific
lifespan-learning prediction. A better primary citation would be a
canonical niche-exploitation or adaptive-radiation paper (e.g.,
Simpson's *Tempo and Mode in Evolution*, 1944; or any specific
adaptive-radiation-on-trait paper).

**Audit call**: ⚠️. Citation is in the right research programme
(evolution of a morphological trait opens a new niche) but by
analogy rather than direct prediction match. This is a style
choice rather than an error.

### s-seasonal — Boyce (1979) ✅

**Citation (verified)**:

> Boyce, M. S. (1979). Seasonality and Patterns of Natural
> Selection for Life Histories. *American Naturalist* 114, 569-583.
> [`10.1086/283503`]

**What Boyce 1979 predicts**: periodic environmental variation
produces boom-bust population dynamics and shapes life-history
strategy. Winter mortality + spring recovery cycle.

**What clade reproduces**: population (`n_agents`) tracks grass
coverage with short lag; multiple complete cycles visible over 500
ticks at `season_length = 100`.

**Audit call**: ✅. Citation correct, direction correct, claim
directly matched.

### s-scavenging — DeVault et al. (2003) 🟠

**Citation**:

> DeVault, T. L., Rhodes, O. E. & Shivik, J. A. (2003). Scavenging
> by vertebrates: behavioral, ecological, and evolutionary
> perspectives on an important energy transfer pathway in
> vertebrate communities. *Oikos* 102, 225–234.

**What DeVault et al. predict**: scavenging is an important energy
transfer pathway; agents with scavenging behaviour gain an energy
buffer during primary-productivity troughs.

**What clade reproduces**: the module fires (`n_scavenging_events >
0`) but the *mean_energy* benefit under scarcity does not appear.
192-run sweep found no cell giving Δenergy > 0 at \|t\| ≥ 2 in
the canonical direction.

**Audit call**: 🟠. Citation correct. Mechanism present;
quantitative prediction not reproduced. Vignette honestly
documents the null; uses the scenario as a module-firing demo
rather than as evidence that scavenging quantitatively improves
energy budgets in the clade ABM setting.

### s-dispersal-ifd — Fretwell & Lucas (1970) + Shine et al. (2011) ✅

**Citations (verified)**:

> Fretwell, S. D. & Lucas, H. L. (1970). On territorial behavior
> and other factors influencing habitat distribution in birds.
> *Acta Biotheoretica* 19, 16-36.
> [`10.1007/BF01601953`] (DOI dates from 1969 publication year.)

> Shine, R., Brown, G. P. & Phillips, B. L. (2011). Reply to Lee:
> Spatial sorting, assortative mating, and natural selection.
> *PNAS* 108, E29. [`10.1073/pnas.1108240108`]

**What the papers predict**:

- *Fretwell & Lucas 1970*: under perfect information and free
  movement, individuals distribute across habitat patches
  proportional to resource availability — the Ideal Free
  Distribution.
- *Shine et al. 2011*: at expanding invasion fronts, high-dispersal
  genotypes co-occur with other high-dispersal genotypes through
  spatial assortment alone — non-adaptive spatial sorting.

**What clade reproduces**: Δhabitat_preference = +0.021 ± 0.005 at
`habitat_preference_strength = 2.0` across 5 seeds (PASS, 4×
within-seed sd). Spatial sorting demonstrated at invasion fronts.

**Audit call**: ✅. Both citations correct, both claims reproduced
direction-correct.

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
  addition, Clutton-Brock year pin).
- **2026-04-19 (same day, later)** — Session 2 complete. 7
  cognitive-evolution scenarios audited; 2 ✅, 3 ⚠️, 1 🟠, 1 ⚪. One
  verification failure ("Song 2025" on s-brain-size — Crossref
  cannot locate). Two citation-attribution precisions for
  consideration (s-social-learning mechanism specificity; s-rl
  Baldwin-framework attribution).
- **2026-04-19 (later still)** — Session 3 complete. 11
  ecology/species-interaction scenarios audited; 4 ✅, 4 ⚠️, 3 🟠.
  Notable findings: **s-predator-prey** and **s-group-defense**
  are both 🟠 honest-nulls where canonical predictions (Lotka-
  Volterra oscillations; Hamilton 1971 selfish-herd dilution) do
  NOT survive the evolving-ABM setting — both vignettes document
  this honestly. **s-scavenging** is a 🟠 where the module fires
  but the mean_energy advantage under scarcity doesn't reproduce.
  **s-disease** is missing a citation for the SIR framework
  (Kermack & McKendrick 1927) entirely. **s-complex-landscape**
  cites Liedtke & Fromhage 2019 by structural analogy rather than
  direct prediction match. Session 4 pending.

**Aggregate after Sessions 1 + 2 + 3** (24 scenarios audited plus
1 ⚪ N/A): 7 ✅, 11 ⚠️, 5 🟠, 1 ⚪, 0 ❌. Zero outright retractions
across three sessions.
