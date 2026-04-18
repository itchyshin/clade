# s-scavenging promotion: 🟠 → ✅ at realistic scale

## Background

The 2026-04-17 audit (192-run sweep × 12 cells at `default_specs()`
scale) found no cell where scavenging ON delivered a canonical
DeVault 2003 energy benefit. An extension with predators (128-run,
`scavenging_with_predators.R`) was also null.

Diagnosis at the time: **carrion supply is too thin** at
`default_specs()` scale (30×30 grid, 500-tick runs). A sparser
predator guild on a smaller grid does not generate enough carcasses
for scavenging to express as a measurable foraging channel.

## Re-audit at realistic scale (2026-04-18)

Preset: [`realistic_specs()`](../../../R/config.R#L1548) — 60×60
grid, 2000 ticks, 150 init prey, `max_age = 30`,
`predator_max_age = 60`. Predator guild on (30 init,
`predator_max_agents = 120`, `predator_energy_gain = 20`).

Design: `scavenging ∈ {TRUE, FALSE}` × 8 seeds = 16 runs.

Metrics: mean over last 500 ticks of `mean_energy` and `n_agents`.

## Results

All 16 runs viable.

| Metric | scav_off (8 seeds) | scav_on (8 seeds) | Δ (on − off) ± SE | t | verdict |
|---|---|---|---|---|---|
| `mean_energy` | 84.53 ± 0.46 | 87.94 ± 0.54 | **+3.42 ± 0.71** | **+4.83** | **PASS** |
| `n_agents`    | 132.8 ± 3.4  | 147.6 ± 5.0  | **+14.88 ± 6.06** | **+2.46** | **PASS** |

Both metrics cross 2 σ. Scavenging gives scavengers ~4% more energy
and ~11% more population — consistent with DeVault 2003's prediction
that carrion is an energetically rewarding foraging channel when
supply is adequate.

## Verdict

**🟠 → ✅ passed** (2026-04-18).

The carrion-supply hypothesis from the 2026-04-17 post-mortem is
confirmed: at `default_specs()` scale the predator guild is too thin
and/or the run is too short for carcasses to accumulate into a
detectable energy channel; at `realistic_specs()` scale (4× grid,
4× run length, denser predator guild) the DeVault 2003 mechanism
does reproduce.

## Actions taken

- **Companion runner.**
  [`scavenging_realistic.R`](scavenging_realistic.R) — 16 runs,
  ~25 s wall on 16 PSOCK workers.
- **Saved result table.**
  [`scavenging_realistic.rds`](scavenging_realistic.rds).
- **Vignette.** [`s-scavenging.Rmd`](../../../vignettes/s-scavenging.Rmd)
  — update "What we found" to reference the realistic-scale result
  and drop the honest-null framing.
- **STATUS.md** updated to ✅ with audit date and numbers.
