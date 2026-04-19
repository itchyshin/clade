# Kokko & Brooks 2003 reproduction — honest-null on the interaction

*2026-04-19. Protocol: `kokko_brooks_2003.R`. Output:
`kokko_brooks_2003.rds`. Vignette:
`vignettes/paper-kokko-brooks-2003.Rmd`.*

First paper-reproduction vignette — demonstrates the
`hypothesis_sweep()` + `hypothesis_report()` researcher workflow
introduced in the same session (PR #94).

## Paper

Kokko, H. & Brooks, R. (2003). Sexy to die for? Sexual selection
and the risk of extinction. *Annales Zoologici Fennici* 40,
207–219.

## Design

8 conditions × 8 seeds × 2000 ticks = 64 runs on a 40×40 grid,
no predators. `signal_dims ∈ {0, 3}` × `grass_rate ∈ {0.20, 0.12,
0.08, 0.05}`.

## Results

| grass | no signals | with signals | Δ (signals effect) | t |
|---|---|---|---|---|
| abundant (0.20) | 237.7 ± 5.3 | 210.8 ± 3.7 | **−26.9 ± 6.5** | **−4.17 PASS** |
| mid (0.12) | 157.8 ± 3.2 | 150.4 ± 3.9 | −7.4 ± 5.1 | −1.46 null |
| scarce (0.08) | 120.6 ± 2.3 | 109.9 ± 1.6 | **−10.8 ± 2.8** | **−3.82 PASS** |
| very_scarce (0.05) | 70.2 ± 4.9 | 67.1 ± 2.6 | −3.1 ± 5.5 | −0.57 null |

K&B interaction test:

```
signals_effect @ abundant    = -26.90 ± 6.46
signals_effect @ very_scarce =  -3.11 ± 5.49
Δ(very_scarce − abundant)    = +23.79 ± 8.48, t = +2.81  [PASS]
```

**Direction is opposite to K&B's prediction.** K&B expected the
signals-effect curve to steepen as resources deteriorate; clade
shows it *flattens*. Zero extinctions in any of 64 runs.

## Interpretation

clade's `signal_cost = 0.2` is a per-tick per-agent linear energy
drain. At abundant-resource equilibrium the population is larger,
so the linear cost extracts more total energy from the system; at
stressed equilibrium the cost drag is proportionally smaller in
absolute terms. K&B's theoretical framework assumes costs that
interact multiplicatively with stress (e.g. signals reducing
fasting tolerance) — these are different mechanisms despite the
shared "costly trait" language.

## Scientific reading

Honest null on K&B's distinctive interaction claim. clade does
reproduce:
- Main effect of signals: direction-correct cost
- Main effect of stress: large (Δn = −117 at bare-stress level)

clade does NOT reproduce:
- K&B's interaction sign (clade gets the opposite direction)
- Extinction at any tested condition

Documenting where a canonical prediction fails to carry through is
the audit methodology's core contribution. A researcher asking
"does my empirical system match K&B's story?" can use this vignette
as a template for checking.

## Paths to a K&B-matching regime (not attempted here)

1. **Stress-multiplicative cost** — signal load raises
   `disease_death_prob`-equivalent mortality at low energy, not
   just flat energy tax. Requires `tick.jl` kernel change.
2. **Longer + harsher** — `max_ticks = 8000`, `grass_rate = 0.03`.
   Might force extinctions. Parameter-only, no kernel work.
3. **Sex-specific mortality** — K&B's sexual-dimorphism paradox
   needs male-specific signal cost that raises male-only mortality.
   Not implemented in the current kernel.

## Files

- `kokko_brooks_2003.R` — sweep script
- `kokko_brooks_2003.md` — this report
- `kokko_brooks_2003.rds` — per-run + aggregate results
- `vignettes/paper-kokko-brooks-2003.Rmd` — user-facing vignette
- 64 runs, 8 conditions × 8 seeds × 2000 ticks each, ~30 s on 32
  PSOCK cores
