# Decision Log

Record durable project decisions here when they are broader than one task but
do not need a full design document yet.

## Template

```md
## YYYY-MM-DD - <decision title>

- Decision: <what changed or what rule was adopted>
- Reason: <why this is better for users, maintainers, validation, or release>
- Alternatives considered: <short list>
- Consequences: <what future work must respect>
- Evidence: <issue, PR, check-log entry, paper, benchmark, or design doc>
```

## 2026-06-08 — Decouple `female_investment` role contract from focal-agent convention

- Decision: When `sex_labels = TRUE`, the `parental_investment_evolution`
  cost-split is decoupled from which partner happens to initiate the
  reproductive event. `female_investment` now denotes the *mother's* share
  regardless of focal/mate roles; the father pays the complement; the
  `male_repro_cost` extra likewise targets whichever partner is male.
  When `sex_labels = FALSE`, the legacy "focal-agent = implicit mother"
  semantics are preserved exactly.
- Reason: The legacy contract was implicit and only meaningful when
  every reproductive event was assumed to be initiated by a female. Once
  agents have a sticky biological sex, the kernel can iterate over agents
  in any order (random tick scheduling has been on since 0.7.0) and a
  male can validly be the focal reproducer. Hard-binding the
  female-investment label to the focal agent would introduce a silent
  bias toward whichever sex happens to draw an earlier iteration index.
- Alternatives considered:
  - "Skip male focals when `sex_labels = TRUE`" — preserves the legacy
    label but wastes half the iteration steps and locks out future
    male-parental-care scenarios.
  - "Always have focal = female regardless of order" — would require
    re-sorting the agent iteration order at every tick, breaking the
    random-tick-order contract from 0.7.0.
- Consequences: `female_investment` is no longer "the focal agent's
  share" — it is "the mother's share". Vignettes that previously used
  `female_investment` in the legacy sense are unaffected because the
  legacy code path is preserved under `sex_labels = FALSE`. Any future
  feature that reads the cost-split must respect the sex-conditional
  branch: legacy semantics under FALSE, mother-based semantics under
  TRUE.
- Evidence: this entry; after-task report at
  [dev/dev-log/after-task/2026-06-08-sex-foundation.md](https://github.com/itchyshin/clade/blob/main/dev/dev-log/after-task/2026-06-08-sex-foundation.md);
  Rees-Baylis et al. 2026, *Nat. Commun.*, "Asymmetric life-history
  trade-offs shape sex-biased longevity patterns" (the analytical model
  this work is preparing to reproduce).
