# Kernel 0.4.3 — expensive-brain mechanisms

Released 2026-04-16.

## Motivation

0.4.2 promoted s-brain-size to ✅ by overriding
`brain_energy_base = 0.010` in the scenario runner — a 10×
multiplier from the default 0.001. The biologically more principled
way to get the parental-provisioning signal is to implement the
actual mechanisms the theory invokes:

- **Aiello & Wheeler (1995) expensive tissue hypothesis** — brains
  are metabolically costly, and the cost scales super-linearly
  with size (Kleiber's law in reverse).
- **Isler & van Schaik (2009) expensive brain framework** —
  developing brains need a parental-provisioning buffer because
  neonates can't forage effectively while the brain is still
  training.

0.4.3 adds both mechanisms as opt-in kernel features so that
scenarios can demonstrate the parental-provisioning signal at the
DEFAULT `brain_energy_base` without scenario-specific overrides.

## Changes

### 1. Neonatal foraging deficit

**Files:** `inst/julia/src/tick.jl`, `R/config.R`.

Two new specs:

- `neonatal_foraging_deficit` (numeric, 0.0 default) — reduction
  in effective `max_bite` for newborns.
- `neonatal_deficit_duration` (integer, 10 default) — how many
  ticks of life the deficit applies for.

When both are non-default, agents in their first
`neonatal_deficit_duration` ticks extract at most
`max_bite × (1 - neonatal_foraging_deficit)` units of grass per
tick. Parental care compensates directly: cared-for offspring eat
via the parent's `feeding_rate` channel, bypassing the deficit.

**Biology.** Altricial offspring (mammals, primates, birds of prey)
cannot forage at adult efficiency until motor coordination and
perceptual learning mature. In some species this takes weeks; in
others, months or years. Without parental provisioning the mortality
is ~100%. This is the central selective pressure for the evolution
of parental care in vertebrates.

### 2. Super-linear brain-size cost exponent

**Files:** `inst/julia/src/tick.jl`, `R/config.R`.

New spec `brain_energy_size_exponent` (numeric, 1.0 default). The
brain-size energy cost becomes:

```
size_cost = brain_energy_base × n_weights ^ brain_energy_size_exponent
```

At the default `size_exp = 1.0`, behaviour is unchanged (linear cost
as before). At `size_exp = 1.5`, each additional weight costs
disproportionately more — the Kleiber-style scaling Isler & van
Schaik (2009) identify for the "expensive brain". This sharpens the
selection gradient enough for parental-provisioning scenarios to
produce visible contrast at the default `brain_energy_base = 0.001`.

**Interaction with 0.4.1 Tier 5C sigma cost.** The size-exponent
applies only to the structural size term. The Tier 5C
`brain_energy_sigma_scale` log-cost on BNN sigma is independent and
stacks additively.

## Audit impact

**s-brain-size** was already ✅ from 0.4.2 via the base override.
0.4.3 adds a second (biologically-principled) route to the same
promotion:

| Route | Setting | Δdelta | Care n | No-care n |
|---|---|---|---|---|
| 0.4.2 base override | `brain_energy_base=0.010` | +0.118 | 41 | 30 |
| 0.4.3 mechanisms (moderate) | `deficit=0.3, exp=1.5` | +0.049 | 13 | 8 |
| 0.4.3 mechanisms (strong) | `deficit=0.6, exp=1.5` | +1.088 | 12 | 0 (extinct) |

Both routes work. The 0.4.2 route is more population-stable; the
0.4.3 route is more biologically principled. Scenario authors can
pick either.

**s-body-size** regression under 0.4.2's graded predator sensing:
P1 (Cope direction) holds (Δ = +0.103 / +0.110 over 5 seeds); P2
(predation direction) flips from 0.4.1's detectability direction
(ratio 0.81) to 0.4.3's Shine-escape direction (ratio 1.08). Both
are within 5-seed noise; a 16-seed audit is on the 0.4.4 backlog
to resolve direction robustly. Verdict stays ✅ with a seed-noise
caveat noted in `body_size.md`.

## Known limitations carried forward

- The pre-existing roxygen "mismatched braces or quotes" warning in
  `config.R:7` still truncates `man/default_specs.Rd` on
  regeneration. 0.4.3 does not fix this; the new specs are
  documented in the R source (visible via the GitHub pkgdown
  reference page once the warning is fixed) but not in the
  currently-committed `.Rd` file.

## Files touched

- `inst/julia/src/tick.jl` — neonatal deficit + size exponent in
  `_brain_energy_cost`.
- `R/config.R` — `neonatal_foraging_deficit`,
  `neonatal_deficit_duration`, `brain_energy_size_exponent`
  defaults + roxygen docs.
- `dev/audit/fidelity/brain_size.R` — 0.4.3 grid (deficit × exp).
- `dev/audit/fidelity/brain_size.md` — updated with two-route ✅.
- `dev/audit/fidelity/body_size.md` — P2 seed-noise note.

## Out of scope for 0.4.3 (deferred to 0.4.4 / 0.5)

- Body-size P2 direction resolution (needs 16-seed sweep).
- Super-linear cost at default `size_exp = 1.5` — changing the
  default would affect all scenarios; currently opt-in.
- Coevolving parasite module (s-mating-systems Red Queen).
- Vector-signal predator memory (s-mimicry).
- `max_bite ↔ body_size` Kleiber scaling — current linear form
  kept for alifeR ancestor compatibility.
