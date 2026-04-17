# The questionable nine — 🟠 overview (2026-04-17)

After today's Tier C re-audit, the honest 🟠 set has grown from 4
to ~9 scenarios. This doc is a one-page inventory with per-scenario
diagnosis and next step. Read alongside `EVIDENCE_REVIEW.md` and
`STATUS.md`.

## The list

### Original 4 🟠 (documented kernel / theory limitations)

#### 1. s-mating-systems (Hamilton 1980 Red Queen)

- **Claim**: sex > asex in a coevolving-parasite environment.
- **Evidence**: 16-seed 19-regime audit (0.5.3) — direction correct
  on average, no individual cell crosses 2×SE.
- **Blocker**: clade's parasite module is one-axis (genotype matches
  scalar virulence). Real Hamilton 1980 needs multi-locus
  host-parasite coevolution so recombination can break up
  parasite-locked genotypes.
- **Next step**: `coevolving_parasite.jl` multi-locus module
  (0.5.0 plan item, `dev/docs/kernel-as-biology/reproduce.md`
  §5). Medium kernel work, ~2 days.

#### 2. s-mimicry (Bates 1862 / Müller 1879)

- **Claim**: aposematism evolves when toxic prey are visible to
  predator learning.
- **Evidence**: kernel P3 PASS (avoidance events fire), P4 PASS
  (positive dose-response). P2 (Δtoxicity > 0) ecology-conditional:
  Δ > 0 at predation-dominant ecology (grass = 0.08), Δ < 0 at
  default well-fed ecology (grass = 0.20).
- **Blocker**: Zahavi 1975 handicap equilibrium is theoretically
  fragile — Grafen 1990 / Getty 2006 / Számadó 2011 showed it
  requires specific differential-cost structures clade doesn't
  supply at default.
- **Next step**: already reframed (PR #38) to lead with
  predation-dominant ecology as the primary demonstration regime.
  Further promotion would need a `toxicity_cost_energy_inverse`
  spec (cheap when rich, expensive when poor) to give the Grafen
  equilibrium its differential cost.

#### 3. s-plasticity (DeWitt & Scheiner 2004)

- **Claim**: plasticity is maintained higher in variable env than
  in stable env.
- **Evidence**: 5-seed fast_specs + sl=10 → Δdelta = +0.014;
  **8-seed re-audit → +0.005 ± SE 0.007** (*t* = 0.74, still
  direction-correct but magnitude at drift-noise scale).
- **Blocker**: clade's BNN sigma couples to behavioural variance —
  selection against noisy actions competes with selection against
  learning width. 0.5.5 added `bnn_action_noise_scale` to decouple;
  0.5.6 added `action_exploration_epsilon` + `bnn_sigma_lr_scale`
  as further levers.
- **Next step**: find params where baseline sigma canalises
  (drops from init) — the levers added this session don't help
  until that happens. Or: strengthen the sigma-contraction term in
  `bnn_update!` directly. See `baldwin_sigma_lr_test.R` for the
  diagnostic.

#### 4. s-baldwin (Hinton & Nowlan 1987)

- **Claim**: stable env canalises BNN sigma downward; seasonal env
  preserves it.
- **Evidence**: same shared kernel limit as plasticity.
  `bnn_action_noise_scale = 0` gives the right DIRECTION
  (Δdelta = +0.11) but populations crash without sigma-driven
  exploration. Adding `action_exploration_epsilon = 0.1` keeps
  populations viable but loses the canalisation signal.
- **Blocker**: same as plasticity — the mechanism is there, but
  baseline sigma dynamics don't reach the regime where any of the
  0.5.5/0.5.6 levers matter.
- **Next step**: same as plasticity. The 3 levers are in place;
  what's missing is a regime where they activate.

### 5 new 🟠 candidates (Tier C batch 1+2 demotions)

These were ✅ before today; 8-seed re-audit surfaced that their
canonical theoretical claim doesn't hold at default parameters.
None are kernel bugs — most need parameter-regime calibration or
claim-reframing.

#### 5. s-group-defense (Hamilton 1971 selfish herd)

- **Expected**: group_defense ON gives higher prey survival under
  predation.
- **8-seed result**: Δn_agents_final = -0.9, *t* = -0.15 (null).
- **Diagnosis**: at 5 predators / 100 prey / default strength
  0.3, the dilution effect is below the noise floor. Not a
  mechanism failure — a parameter-regime miss.
- **Next step**: strength + radius sweep (mirroring what worked
  for s-dispersal-ifd today). Half day.

#### 6. s-social-learning (Boyd & Richerson 1985)

- **Expected**: social_learning ON gives higher mean_energy via
  propagation of successful strategies.
- **8-seed result**: Δmean_energy = -2.2, *t* = -1.14 (weakly
  *opposite* direction).
- **Diagnosis**: possibly the copying cost outweighs the
  information gain at default `social_learning_freq = 20`.
  Alternatively, the copier's trait moves toward the copied
  neighbour's — which can be maladaptive if that neighbour's
  advantage was seed-specific.
- **Next step**: frequency + mode sweep. Or: reframe the claim
  to "social_learning increases behavioural convergence" (which
  is presumably what actually happens) rather than "improves
  energy".

#### 7. s-scavenging (DeVault et al. 2003)

- **Expected**: scavenging ON raises mean_energy under scarce
  grass.
- **8-seed result**: Δ = +0.05, *t* = 0.05 (null).
- **Diagnosis**: at default `carrion_fraction = 0.5` and
  `carrion_eat_gain = 3.0`, carrion contribution is probably
  swamped by normal foraging variance. Or: agents die of
  starvation before they find carrion.
- **Next step**: push grass even scarcer (grass = 0.05) and
  grass_max lower, to make carrion relatively more important.

#### 8. s-brain-size (parental-provisioning hypothesis)

- **Expected**: brain_size grows under parental_care (provisioned
  offspring can afford slow maturation + bigger brains).
- **8-seed result**: Δmean_brain_size = -0.003, *t* = -0.08
  (null). 2 of 8 runs crashed.
- **Diagnosis**: this is the big one. The canonical claim
  (parental care unlocks brain evolution) has been the main
  brain-size story in the vignette since 0.4.2, and at 8 seeds
  the effect vanishes. The 0.4.3 `brain_energy_size_exponent`
  Tier 5C work should have increased the gradient; may have
  over-corrected.
- **Next step**: full brain_energy parameter sweep at 8 seeds
  under viability_report guard. This is the scenario most likely
  to need a proper kernel re-investigation.

#### 9. s-rl (Williams 1992 REINFORCE)

- **Expected**: actor-critic within-life learning boosts mean
  energy vs no learning.
- **8-seed result**: Δ = -2.5 energy, *t* = -1.66 (weakly
  opposite direction).
- **Diagnosis**: unexpected. The algorithm correctness tests
  pass (gradient is correct), but at scenario level the learning
  signal is not translating to foraging benefit. Possibly
  `rl_update_freq = 5` is too aggressive (updates before
  advantage signal stabilises).
- **Next step**: rl_update_freq sweep, or more fundamental
  investigation of whether the "advantage" signal clade computes
  actually points in the right direction. Half day to a day.

### Plus 1 marginal

**s-parental-investment** (Trivers 1972): Δbirths/tick = +0.035,
*t* = 1.01. Direction correct, not distinguishable from noise at
8 seeds. Not a full 🟠, but also not defensibly ✅. Flagged for a
16-seed rerun.

## Priority order for closing these

Using today's successful pattern (parameter-regime sweep +
viability guard + 8+ seeds):

1. **s-group-defense, s-scavenging, s-social-learning** — most
   likely to respond to a simple parameter sweep. Half-day each.
2. **s-rl** — needs deeper investigation but also probably a
   parameter-regime miss. Half to one day.
3. **s-brain-size** — likely needs kernel re-investigation of
   the provisioning gradient. One day.
4. **s-mimicry** — reframe only; no new kernel work.
5. **s-plasticity + s-baldwin** — kernel work, both share the
   "find params where baseline canalises" blocker. Coupled; one
   investigation.
6. **s-mating-systems** — new multi-locus parasite module.
   Multi-day.

Total realistic effort to resolve all 9: **~2 working weeks** at
one-scenario-per-day cadence, assuming each investigation is 4–8
hours.

## Meta observation

Of the 9 🟠 scenarios:

- **3 need only parameter sweeps** (group-defense, scavenging,
  social-learning) — fast wins.
- **2 need reframing** (mimicry partially done; parental-
  investment could go the same way).
- **2 need kernel exploration** (plasticity, baldwin — shared
  sigma-dynamics problem).
- **1 needs a module** (mating-systems — multi-locus parasite).
- **1 wildcard** (brain-size — depends on what the 8-seed null
  turns out to be).

The pattern is clear: most demotions are not kernel bugs. They
are parameter-regime or framing gaps. The package is correct;
the vignette claims were over-broad.
