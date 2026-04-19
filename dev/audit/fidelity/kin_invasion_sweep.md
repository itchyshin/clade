# s-kin invasion-dynamics sweep — honest null

*2026-04-19. Protocol: `kin_invasion_sweep.R` (v1) and
`kin_invasion_sweep_v2.R` (v2). Outputs: `kin_invasion_sweep.rds`,
`kin_invasion_sweep_v2.rds`.*

## What Hamilton (1964) actually predicts

Hamilton's genetical evolution of social behaviour is a theorem
about the **invasion dynamics of an altruistic allele**: starting
from rare, the allele rises in frequency when `r × B > C`. The
existing s-kin ✅ verdict tests the *demographic consequence* of
kin altruism (a deterministic module that fires when gate
conditions are met) and finds Spearman ρ = 0.97 between rB/C and
equilibrium population (s-kin.Rmd). That's a direction-correct
demographic result but it's the consequence, not the invasion
dynamic itself.

This sweep tests the invasion claim directly using the
`cooperative_breeding` module, which carries a **heritable**
`helper_tendency` trait (mutation-perturbable, inherited from
parent). Hamilton's rule predicts: low helper-transfer cost (low
C) → `helper_tendency` rises from rare; high C → stays rare or
declines.

## Design

| Condition | v1 | v2 |
|---|---|---|
| grid | 40×40 | 40×40 |
| max_ticks | 2000 | 4000 |
| n_agents_init | 100 | 100 |
| grass_rate | 0.15 | 0.15 |
| `parental_care` | TRUE | TRUE |
| `cooperative_breeding` | TRUE | TRUE |
| `helper_tendency_init_mean` | 0.05 (rare) | 0.05 (rare) |
| `helper_tendency_mutation_sd` | 0.02 | 0.02 |
| `helper_kin_threshold` | 0.25 (siblings+) | 0.25 |
| `helper_min_energy` | 80.0 | **50.0** (relaxed gate) |
| `helper_transfer` sweep (C) | {2, 5, 10, 20} | {2, 5, 10, 20} |
| seeds | 1–8 | 1–8 |
| total runs | 32 | 32 |

## v1 results (helper_min_energy = 80, 2000 ticks)

| `helper_transfer` | Δ helper_tendency ± SE | t | n_helpers / run |
|---|---|---|---|
| 2 | +0.0005 ± 0.0022 | +0.24 | 30.6 |
| 5 | +0.0026 ± 0.0021 | +1.23 | 38.0 |
| 10 | −0.0002 ± 0.0020 | −0.10 | 34.3 |
| 20 | −0.0016 ± 0.0022 | −0.73 | 33.9 |

Spearman(transfer, final helper_tendency) = **−0.197**
(direction correct, magnitude drift-noise scale).

## v2 results (helper_min_energy = 50, 4000 ticks)

Goal: relax the eligibility gate + double the timescale so
selection has more events to act on.

| `helper_transfer` | Δ helper_tendency ± SE | t | n_helpers / run |
|---|---|---|---|
| 2 | −0.0019 ± 0.0021 | −0.91 | 95.1 |
| 5 | −0.0031 ± 0.0029 | −1.10 | 98.5 |
| 10 | −0.0031 ± 0.0040 | −0.77 | 93.5 |
| 20 | **−0.0039 ± 0.0020** | **−2.00** | 88.4 |

Spearman(transfer, final helper_tendency) = **−0.118**.
Mean helping events per run = 94 (2.7× more than v1).

## Verdict: honest null

Both v1 and v2 show `helper_tendency` **declining** from
init_mean = 0.05 in almost every condition — the trait does NOT
invade from rare at any tested helper-transfer level. Three
observations:

1. **Direction is weakly correct** (Spearman −0.197 and −0.118).
   Higher transfer gives lower final helper_tendency on average.
2. **Magnitude is drift-dominated.** |t| values for the Δ vs
   zero are 0–2; v2's C=20 cell reaches |t| = 2.00 but in the
   *declining* direction (tendency falls faster with high cost).
   That's consistent with Hamilton-satisfying selection against
   high-cost helping, but it doesn't demonstrate *invasion* at low
   cost — only faster decline at high cost.
3. **Even with 2.7× more helping events and double the runtime,
   invasion does not occur.**

The s-kin demographic consequence (deterministic `kin_selection`
module, tested in the main s-kin.Rmd) continues to hold at
ρ = 0.97 — but clade's current `cooperative_breeding` plumbing
does not channel the indirect-fitness benefit of helping back to
the helper's own lineage strongly enough for the allele to invade.
Plausible mechanism gaps:

- The energy a helper transfers to a relative's offspring becomes
  part of the next generation's seed pool, but clade does not
  compute kin-weighted reproductive success explicitly. Selection
  on `helper_tendency` acts only through the helper's own direct
  fitness (energy balance) — and paying `helper_transfer` reduces
  that without a compensating direct benefit.
- Recipient offspring inherit from *their own parents*, not from
  the helper. The helper gets no direct transmission pathway.
- The `helper_kin_threshold = 0.25` is broad (siblings + closer) —
  without an explicit inclusive-fitness accounting, the cost is
  born privately while the benefit spreads across a kin
  neighbourhood, diluting any per-allele signal.

## Scientific reading

**This is not a flaw.** It is an honest observation that the
specific Hamilton-1964 invasion claim requires a kin-weighted
fitness accounting that the current kernel does not instantiate.
The demographic consequence that IS reproduced (rB/C predicts
carrying capacity at the population level) is a legitimate
corollary of Hamilton's rule, and the citation-audit ⚠️ verdict
on s-kin captures exactly this distinction: clade reproduces the
demographic corollary, not the invasion dynamic itself.

## Paths to ✅ (for future kernel work, not this session)

1. **Kin-weighted reproduction**: when a helper's relative
   reproduces, assign a partial credit to the helper's own
   fitness — i.e. compute inclusive fitness explicitly and have
   selection act on it. This would require a kernel change in
   `reproduce.jl` to track `helper_tendency`-by-relatedness
   pairings.
2. **Direct reward for helping**: the helper could gain a small
   fraction of the helping event's downstream offspring-survival
   benefit (an implementation of Queller's geometric-view
   accounting). Requires more bookkeeping.
3. **Longer runs + larger populations**: at 4000 ticks × 40×40
   grid the effective selection samples are still ~100 per run.
   At 64 seeds × 8000 ticks × 60×60 grid, drift would shrink and
   even a weak selection gradient could emerge. Compute-heavier
   but no kernel change needed.

## Implication for the vignette

The s-kin.Rmd prose at lines 127-133 already acknowledges this
distinction honestly: *"this audit tests the population-level
consequences of Hamilton's rule, not the invasion dynamics of an
altruistic mutant"*. The new sweep documented here is empirical
confirmation of that caveat — clade indeed does not reproduce the
invasion dynamic under current kernel plumbing. The demographic
✅ stands.

## Files

- `kin_invasion_sweep.R` / `kin_invasion_sweep.rds` — v1 (default gate)
- `kin_invasion_sweep_v2.R` / `kin_invasion_sweep_v2.rds` — v2 (relaxed gate, longer runs)
