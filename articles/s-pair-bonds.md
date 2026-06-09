# Persistent pair bonds (monogamous unions)

## Persistent pair bonds (0.8.0)

**What it models.** A persistent monogamous mating union: once two
opposite-sex agents reproduce together, the union persists across ticks
(both agents are excluded from re-mating with anyone else). Unions
dissolve when either partner dies or — with probability `divorce_rate`
per tick — stochastically. This replaces the default
`mating_system = "any"` regime in which every reproduction event scans
neighbours fresh.

Required for the upcoming Rees-Baylis 2026 Fig 4 reproduction (female
demographic dominance), which depends on the union-formation feedback
into total population size.

**Key parameters.**

| Parameter | Default | Effect |
|----|----|----|
| `mating_system` | `"any"` | `"any"` (legacy) or `"monogamous_pair"`. Setting `"mating_groups"` errors in 0.8.0 — planned for the next release. |
| `divorce_rate` | `0.0` | Per-tick probability that an existing union dissolves (returns both partners to the singles pool). 0 = lifelong monogamy. |
| `pair_bond_persistence` | `TRUE` | When `FALSE`, bonds dissolve after every clutch — equivalent to serial monogamy per reproduction event. |
| `sex_labels` | `FALSE` | Required to be `TRUE` for pair bonds to do anything (otherwise mate filter is sex-blind). |

**Expected behaviour.** With `divorce_rate = 0` and a finite `max_age`,
mean union duration scales with mean partner lifespan; the proportion of
agents in a current bond at any given tick depends on the rate at which
unions form vs the rate at which they dissolve via partner death. With
`divorce_rate > 0`, equilibrium-partnered fraction drops; the limit
`divorce_rate = 1` produces “serial monogamy” — partners pair only
within the tick of reproduction.

``` r

library(clade)

s <- default_specs()
s$grid_rows           <- 30L
s$grid_cols           <- 30L
s$n_agents_init       <- 100L
s$max_ticks           <- 500L
s$grass_rate          <- 0.15
s$random_seed         <- 42L
s$ploidy              <- 2L
s$sex_labels          <- TRUE
s$mating_system       <- "monogamous_pair"
s$divorce_rate        <- 0.0     # lifelong monogamy
s$pair_bond_persistence <- TRUE

env <- run_alife(s)
n   <- length(env$agents)
partner_ids <- vapply(seq_len(n),
                       function(i) as.numeric(env$agents[[i]]$union_partner_id),
                       numeric(1))
union_ticks <- vapply(seq_len(n),
                       function(i) as.numeric(env$agents[[i]]$union_ticks),
                       numeric(1))
cat("Population:", n,
    " | Partnered fraction:", round(mean(partner_ids > 0), 3),
    " | Mean union duration (ticks):",
    round(mean(union_ticks[partner_ids > 0]), 1), "\n")
```

``` r

# Divorce-rate sweep: lifelong → serial monogamy.
library(clade)
rates <- c(0.0, 0.05, 0.2, 0.5)
results <- lapply(rates, function(d) {
  s <- default_specs()
  s$grid_rows <- 30L; s$grid_cols <- 30L
  s$n_agents_init <- 100L; s$max_ticks <- 500L
  s$grass_rate <- 0.15
  s$ploidy <- 2L
  s$sex_labels <- TRUE
  s$mating_system <- "monogamous_pair"
  s$divorce_rate <- d
  s$random_seed <- 42L
  env <- run_alife(s)
  n <- length(env$agents)
  pid <- vapply(seq_len(n),
                function(i) as.numeric(env$agents[[i]]$union_partner_id),
                numeric(1))
  ut <- vapply(seq_len(n),
               function(i) as.numeric(env$agents[[i]]$union_ticks),
               numeric(1))
  list(divorce_rate = d, n = n,
       partnered = mean(pid > 0),
       mean_duration = if (any(pid > 0)) mean(ut[pid > 0]) else NA_real_)
})
do.call(rbind, lapply(results, as.data.frame))
```

## What changes inside the kernel when `mating_system = "monogamous_pair"`

Three behavioural changes activate; everything else remains as it was on
the sex-foundation release.

1.  **`_find_mate()` respects pair-bond state.** When the focal agent
    has `union_partner_id > 0`, only that exact partner (if present in
    the neighbourhood scan) is an eligible mate. When the focal is
    unpartnered, only unpartnered opposite-sex agents are eligible.
2.  **New `update_unions!()` hook in the tick loop** runs after
    `remove_dead!()` and before `create_offspring!()`. It dissolves
    unions whose partner is no longer alive and rolls a divorce check
    per current union.
3.  **Pair-bond formation at successful mating.** When a focal
    reproduces with an unpartnered neighbour and
    `pair_bond_persistence = TRUE`, both agents set `union_partner_id`
    to each other’s id and reset `union_ticks = 0`. When
    `pair_bond_persistence = FALSE`, the bond is dissolved immediately
    after the clutch.

## Honest discussion

What this scenario does NOT yet test:

- **Effects on evolved life-history.** With sex-blind survival (the
  default), persistent pair bonds change WHO reproduces with whom but
  not the average per-agent reproductive rate enough to detectably shift
  evolved traits over short runs. The interesting test is paired with
  `sex_specific_tradeoffs` + the upcoming `mating_groups` module, which
  together produce Rees-Baylis et al.’s demographic-asymmetry prediction
  (Fig 4). Tracked in the Rees-Baylis paper-reproduction vignette
  extensions.
- **`mating_system = "mating_groups"` (multi-male / multi-female
  groups).** Spec fields (`mating_group_n_males`,
  `mating_group_n_females`, `mating_group_fecundity_scaling`) are
  validated by the kernel but setting `mating_system = "mating_groups"`
  currently errors with “not yet implemented” — planned for the next
  0.8.x release.
- **Mate-finding under low spatial proximity.** Bonded partners that
  drift apart (outside each other’s `mate_search_radius`) fail to
  re-encounter and effectively skip mating that tick, with the bond
  persisting in state. This is biologically realistic but means observed
  “partnered” rates can be lower than the rate of bond formation
  suggests.

## Citation

``` bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```
