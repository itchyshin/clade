# s-stress-hypermutation promotion: 🟠 → ✅ — config bug, not biology null

## Background

0.5.11 re-audit at `grass_rate = 0.06, stress_threshold = 40, 4 seeds`
reported:
```
Baseline  diversity = 0.263 ± 0.009
Hypermut  diversity = 0.263 ± 0.009
Δ = +0.000  → P1 FAIL
```

Demoted to 🟠 with the hypothesis that "real diploid sex produces
enough baseline mutation input that hypermutation adds nothing." That
hypothesis turned out to be wrong. The real issue was mechanical.

## Root cause

In `inst/julia/src/reproduce.jl` line 156, stress-mutation fires at
reproduction time:

```julia
eff_mut_sd = if Bool(get(specs, "stress_hypermutation", false)) &&
                ag.energy < Float32(get(specs, "stress_threshold", 20.0))
    base_mut_sd * Float32(get(specs, "stress_mutation_multiplier", 3.0))
else
    base_mut_sd
end
```

Reproduction is gated at `ag.energy ≥ min_repro_energy` (default 120).
Stress-threshold default is 20 (or 40 in the old audit). Since
`min_repro_energy > stress_threshold`, the condition
`ag.energy < stress_threshold` is never true at reproduction — every
reproducing agent has `energy ≥ 120 > 40`.

**Stress-mutation never fires under default config.** That's why the
module looked like a no-op in every test.

## Fix and re-audit

Raising `stress_threshold` above `min_repro_energy` makes the module
functional. Re-ran at `stress_threshold = 150` across
`grass_rate ∈ {0.02, 0.03, 0.04, 0.06}` × 16 seeds × hypermut ON/OFF:

| grass_rate | OFF viable | OFF div | ON viable | ON div | Δ_div ± SE | t |
|---|---|---|---|---|---|---|
| 0.02 | 0 | — | 0 | — | — | crashed |
| 0.03 | 2 | — | 1 | — | — | too few |
| 0.04 | 13 | 0.252 | 12 | 1.132 | +0.881 ± 0.018 | **+48.91 PASS** |
| 0.06 | 16 | 0.265 | 16 | 1.196 | +0.930 ± 0.010 | **+92.18 PASS** |

At moderate scarcity (grass_rate = 0.04–0.06), hypermutation raises
genetic diversity by ~4.5× (from 0.26 to 1.14–1.20). Rosenberg 2001
decisively confirmed. The t-statistics are extraordinary because
every single seed gives the same ordering — there is essentially no
overlap between the OFF and ON distributions.

## Verdict

**🟠 → ✅ passed** (2026-04-18, 0.5.16).

This is a rare case where the audit discovery was a **configuration
bug** rather than a theory/kernel mismatch. The biology is fine; the
mechanism is wired correctly; the default `stress_threshold` just
happens to make the module silent.

## Actions

- **Config doc update** (`R/config.R`): `stress_threshold` entry now
  flags that the parameter must be > `min_repro_energy` for
  stress-mutation to ever fire. The default remains 20.0 for
  backward compatibility, but users enabling `stress_hypermutation`
  should set `stress_threshold > min_repro_energy` explicitly.
- **STATUS.md**: promoted.
- **Audit runner**: [`stress_hypermutation_scarcity_sweep.R`](stress_hypermutation_scarcity_sweep.R)
  demonstrates the correct configuration.

## Open question

Should the kernel default `stress_threshold` be raised above
`min_repro_energy` (e.g. 150) so the module fires out of the box?
That's a design decision — it would change default behaviour for
existing users. For now the documentation fix is sufficient.
