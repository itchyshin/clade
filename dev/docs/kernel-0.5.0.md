# Kernel 0.5.0 — coevolving parasite module (Hamilton 1980 Red Queen)

Released 2026-04-16.

## Motivation

s-mating-systems has been 🟠 since the 0.4.0 audit because clade has
no mechanism for the Hamilton (1980) Red Queen dynamic that drives
the classical explanation for the evolution of sex. Maynard Smith
(1978) identified the two-fold cost of sex; Hamilton (1980) proposed
that coevolving parasites with genotype-matched virulence can offset
it — novel host-genotype combinations (which sex produces) escape
current parasite pressure, giving sexual lineages a fitness edge.

Prior clade kernels could not test this mechanism because:

- The `disease` module produces generic, non-coevolving mortality
  (a scalar infection rate); no genotype matching.
- Seasonal environments select on phenotype/behaviour, not on the
  recombination axis.

0.5.0 adds a new module that models the parasite population
collectively and lets parasite genotype track host population mean
with lag — the canonical Hamilton 1980 formulation.

## Changes

### Coevolving parasite module

**New file:** `inst/julia/src/modules/coevolving_parasite.jl`.

**Wired into:** `inst/julia/src/Clade.jl` main tick loop (after
`apply_signal_toxicity_pleiotropy!`).

The parasite "population" is represented collectively as a single
virulence-genotype vector `parasite_optimum` of length `signal_dims`,
cached on `env.specs["_parasite_optimum"]` to avoid modifying the
`Environment` struct. Per tick:

1. Compute the host signal centroid over live prey.
2. Adapt the parasite optimum toward the centroid with rate
   `parasite_virulence_rate` (exponential tracking with lag
   ≈ `1 / rate` ticks).
3. Each host computes its Euclidean distance `d` from the optimum
   and pays a Gaussian-falloff energy penalty
   `parasite_pressure × exp(−d² / parasite_distance_scale²)`. Hosts
   close to the optimum (common genotypes) pay the full penalty;
   hosts far from it (rare genotypes) escape almost entirely.
4. The penalty is an energy drain, not instant death. Starving
   hosts die via the normal mortality path.

**Signal vector reused as the genotype-match channel.** Scenarios
needing both mimicry and parasites let the signal serve both
purposes — biologically reasonable (warning-coloured toxic prey
*do* share parasite pressure within their signal morph).

### Specs

New defaults in `R/config.R`:

```r
coevolving_parasites       = FALSE,   # opt-in
parasite_virulence_rate    = 0.1,     # tracking speed
parasite_pressure          = 0.5,     # per-tick energy drain peak
parasite_distance_scale    = 1.0,     # Gaussian falloff width
```

All defaults preserve legacy behaviour. Module is a no-op unless
`coevolving_parasites = TRUE AND signal_dims > 0`.

## Audit impact: s-mating-systems

**Surprise finding: mean-tracking parasites favour asex, not sex.**

The 0.5.0 mating-systems audit (3 seeds × 4 envs: stable, disease,
seasonal, parasite) gives:

| env | asex div | sex div | Δdiv (sex−asex) | asex n | sex n |
|---|---|---|---|---|---|
| stable   | 0.2890 | 0.2861 | −0.003 | 236.5 | 235.2 |
| disease  | 0.2909 | 0.2895 | −0.001 | 237.2 | 236.8 |
| seasonal | 0.2938 | 0.2896 | −0.004 | 223.1 | 223.0 |
| **parasite** | 0.2859 | **0.2387** | **−0.047** | 94.3 | **84.5** |

Under the new parasite condition, sex does *substantially worse*
than asex — the opposite of Hamilton's (1980) Red Queen prediction.

**Why** — the canonical Red Queen requires DISCRETE-allele matching
(haplotype AA vs aa vs Aa): parasites fix on common haplotypes, and
recombination produces *novel* haplotype combinations that escape.
Our 0.5.0 module uses the continuous `signal` vector as the
genotype-match channel and tracks the population *mean* with lag.
Sex offspring = mixture of parents ≈ population mean ≈ parasite
optimum → sex offspring are *more* exposed to parasites, not less.
Asex clones near a parent that drifted away from the centroid retain
that distance advantage across generations.

This is a real biological subtlety: continuous-trait parasite
pressure does NOT reproduce Hamilton's discrete-locus Red Queen.
The two mechanisms differ in how genetic novelty maps to parasite
escape. Continuous: mixture → close-to-mean. Discrete: mixture →
genuinely new haplotype.

**Verdict**: s-mating-systems stays 🟠 with richer but still-
incomplete machinery. The 0.5.0 module demonstrates the mean-tracking
form of Red Queen (which is itself biologically interesting —
parasites selecting *against* genetic convergence is a real
phenomenon). The canonical Hamilton 1980 dynamic needs discrete-locus
matching, deferred to a 0.5.1+ follow-up that would:

- Add a discrete `parasite_match::Vector{Int32}` host trait
  (binary alleles).
- Compute Hamming-distance matching instead of Euclidean.
- Inherit discrete alleles via Mendelian segregation with
  recombination so sex produces genuinely novel haplotypes.

With those three additions the classical Red Queen advantage of sex
should emerge cleanly.

## Files touched

- `inst/julia/src/modules/coevolving_parasite.jl` (new)
- `inst/julia/src/Clade.jl` (include + wire into tick loop)
- `R/config.R` (4 new specs + roxygen docs)
- `dev/audit/fidelity/mating_systems.R` (4th env condition:
  `"parasite"`)
- `dev/audit/fidelity/mating_systems.md` (updated verdict)
- `dev/audit/fidelity/STATUS.md` (scenario note)

## Out of scope for 0.5.0

- Explicit individual-parasite population (parasites as agents).
  The current collective model is biologically equivalent under
  mean-field dynamics and avoids a second agent-management loop.
- Sex-specific cost accounting (two-fold cost, mate-finding time,
  meiotic recombination disruption). Deferred to 0.5.1+ if the
  mating-systems audit remains important.
- Parasite-host coevolution of *virulence itself* (the parasite
  evolving its damage function). Current module fixes virulence
  and tracks host mean genotype.
- Signal-separate parasite-match trait. Current module reuses
  the signal vector; users who want both aposematism AND parasites
  will have the signal channel doing double duty. A future
  refactor could add a dedicated `parasite_match::Vector{Float32}`
  trait.
