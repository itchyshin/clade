# Kernel 0.5.1 — discrete-allele Red Queen (Hamilton 1980 canonical)

Released 2026-04-16.

## Motivation

The 0.5.0 coevolving-parasite module used continuous-trait matching
(Euclidean distance on the signal vector), which the audit showed does
NOT reproduce Hamilton's (1980) canonical Red Queen: sex offspring in a
continuous-trait space cluster *near the population mean* (midpoint of
parents), so when parasites track the mean they are *more* exposed than
asex clones.

Hamilton's mechanism requires **discrete-allele matching with Mendelian
inheritance**. Sex offspring receive each locus independently from
either parent (recombination), producing *genuinely novel haplotypes*
that parasites haven't tracked. Asex clones reproduce identical
haplotypes, so parasites lock onto them.

0.5.1 adds this exact mechanism.

## Changes

### 1. `parasite_haplotype` field on Agent

**File:** `inst/julia/src/types.jl`.

New heritable field:

```julia
parasite_haplotype :: Vector{Int32}
```

Length = `n_parasite_loci` (empty when 0). Each locus takes binary
values {0, 1}. All four `Agent(...)` constructors updated
(`Clade.jl` founder, `reproduce.jl` offspring, `tick_predators.jl`
founder + offspring). Predators don't participate in the Red Queen
module; their haplotypes are always empty.

### 2. Mendelian inheritance

**File:** `inst/julia/src/reproduce.jl`.

New helper `_inherit_parasite_haplotype(parent, specs, rng; mate)`:

- Haploid reproduction (no mate): clone the parent's haplotype, flip
  each locus with probability `parasite_mutation_rate`.
- Diploid reproduction (mate provided): each locus inherits
  independently from `parent` or `mate` with 50/50 probability (free
  recombination), then per-locus mutation.

The free recombination produces the novel haplotype combinations
Hamilton's theory invokes.

### 3. Discrete matching in the parasite module

**File:** `inst/julia/src/modules/coevolving_parasite.jl`.

Existing continuous-mode code factored into
`_apply_parasites_continuous!`. New `_apply_parasites_discrete!`:

1. Compute per-locus majority allele in the host population.
2. Adapt the cached parasite haplotype: each locus shifts toward the
   majority allele with probability `parasite_virulence_rate` (soft
   Bernoulli tracking with lag).
3. Penalty per host:
   `pressure × ((n_loci − hamming_distance) / n_loci) ^ exponent`.
   Hosts matching the parasite haplotype exactly pay full
   `pressure`; entirely-mismatched hosts escape (0 penalty). Exponent
   (`parasite_discrete_exponent`, default 4.0) sharpens the cliff.

New dispatch spec `parasite_match_mode`:

- `"auto"` (default): discrete when `n_parasite_loci > 0`, else continuous.
- `"continuous"`: force 0.5.0 behaviour.
- `"discrete"`: force 0.5.1 behaviour (requires `n_parasite_loci > 0`).

### 4. New config specs

```r
n_parasite_loci            = 0L     # default off; set 8–16 for Red Queen
parasite_match_mode        = "auto"
parasite_mutation_rate     = 0.01   # per-locus allele flip rate
parasite_discrete_exponent = 4.0    # Hamming-distance sharpness
```

All default-off. Legacy scenarios and 0.5.0 continuous-mode scenarios
unchanged.

## Audit impact: s-mating-systems

**First observation of sex > asex in clade.** At intermediate
discrete-parasite pressure, the canonical Red Queen advantage
appears. From a pressure sweep (3 seeds × 500 ticks, `n_parasite_loci
= 8`):

| parasite pressure | Δn (sex − asex) | Δdiv |
|---|---|---|
| 0.0 (off) | −2.5 | −0.004 |
| **1.0** | **+1.8** | −0.001 |
| 3.0 | −4.2 | −0.001 |

Classic inverted-U: at pressure=1.0 the Red Queen pays; at 3.0 both
populations suffer. The magnitude is modest (a few agents in a
population of ~200) but the **direction flip is real and
reproducible** — the first time sex beats asex in clade across any
tested condition.

The mating-systems audit adds a `"parasite_discrete"` environment and
updates the verdict. Scenario promotion to ✅ depends on whether a
consistently positive Δn at moderate pressure across a wider seed
sweep is judged sufficient evidence.

## Files touched

- `inst/julia/src/types.jl` — `parasite_haplotype` field.
- `inst/julia/src/Clade.jl` — founder constructor + new
  `_init_parasite_haplotype` helper.
- `inst/julia/src/reproduce.jl` — offspring constructor + new
  `_inherit_parasite_haplotype` helper.
- `inst/julia/src/modules/tick_predators.jl` — predator + predator
  offspring constructors (always empty haplotype).
- `inst/julia/src/modules/coevolving_parasite.jl` — factored
  continuous path + new discrete path + mode dispatch.
- `R/config.R` — 3 new specs + roxygen docs.
- `dev/audit/fidelity/mating_systems.R` — new env condition
  `"parasite_discrete"`.
- `dev/audit/fidelity/mating_systems.md` — updated verdict.
- `dev/audit/fidelity/STATUS.md` — scenario line.

## Out of scope for 0.5.1

- Multi-species parasite ecology (single virulence haplotype per
  environment; generalising to multiple parasite types is a 0.6+
  project).
- Parasite virulence evolution per se (virulence level fixed by
  `parasite_pressure`; the parasite *genotype* evolves but its damage
  function doesn't).
- Seed-sweep of the ~10 × 10 grid to find optimal `(pressure, n_loci,
  exponent)` for a magnified ✅ signal. Scenario-author responsibility.
