# Check Log

This is an append-only log for validation evidence, handoff notes, and
important project state. Keep entries concise and concrete.

## Template

```md
## YYYY-MM-DD - <short task title>

- Branch: `<branch>`
- Goal: <one sentence>
- Files changed: `<path>`, `<path>`
- Checks run:
  - `<command>`: <exact outcome>
  - `<command>`: <exact outcome>
- Stale-claim searches:
  - `<rg pattern>` over `<paths>`: <outcome>
- Not run: <commands or checks skipped, with reason>
- Next safest action: <one sentence>
```

## 2026-05-16 - Install Agent Operating Kit (drmTMB-kit, adapted for clade)

- Branch: `claude/track-B-kit-install` (off `main` at `2d364a1`).
- Goal: Install the drmTMB-derived agent operating kit, adapted for clade's
  R+Julia split, lab values, and Sergio's parallel kernel-review track. Establish
  the canonical AGENTS.md, vision doc, after-task protocol, check-log discipline,
  and local skills before starting the Track B R-API walk planned in
  `~/.claude/plans/purring-honking-dove.md`.
- Files changed (five commits, oldest first):
  - `d706e0c chore(agent-kit): install scaffolding (step 1 of 5)` — copied
    kit templates with `<PROJECT>` → `clade`, moved `docs/` → `dev/` to fit
    clade's existing convention (clade's `/docs/` is gitignored for pkgdown
    output), updated all internal cross-references.
  - `98723e8 docs(vision): fill in clade vision doc (step 2 of 5)` —
    `dev/design/00-vision.md` with purpose + 6 user categories + 4 lab
    values (transparency / reproducibility / accessibility / inclusiveness) +
    4 differentiators (R-Julia speed; evolvable worlds for mechanism AND
    climate prediction; paper-reproduction-driven structure; MATLAB-ancestor
    lineage) + 16-row Core Contracts table + evidence-standard rules tied
    back to values.
  - `984dcaf docs(agents): adapt AGENTS.md + reduce CLAUDE.md to a stub
    (step 3 of 5)` — created canonical AGENTS.md by merging current CLAUDE.md
    content (Karpathy 4 principles, repo map, conventions, resource limits)
    with kit template (design rules, standing roles, after-task pointer)
    plus clade-specific R+Julia split and Sergio's parallel-track flag.
    CLAUDE.md reduced to one-paragraph stub pointing at AGENTS.md.
    Standing roles narrowed to 6: Ada, Gauss, Noether, Fisher, Pat, Rose.
  - `ab89ee7 docs(after-task): absorb AFTER_TASK.md into
    dev/design/10-after-task-protocol.md (step 4 of 5)` — migrated the
    clade-specific work discipline (two-people framing, 5-step checklist,
    biology consistency, Do-NOT list, "don't start next task until user
    confirms") into the kit's after-task-protocol file. Root-level
    AFTER_TASK.md deleted.
  - (this commit) `step 5 of 5`: first real check-log entry.
- Files NOT changed: no R source, no Julia source, no tests, no vignettes,
  no `inst/`. This is documentation-discipline installation only.
- Checks run:
  - `git status --short --branch`: clean working tree on
    `claude/track-B-kit-install`.
  - `grep -rn "<PROJECT>" docs/ .agents/ MEMORY.seed.md`: no remaining
    placeholders (substitution succeeded in step 1).
  - `grep -rn "docs/design\|docs/dev-log" dev/ .agents/ MEMORY.seed.md`: no
    remaining `docs/` references (path migration succeeded in step 1).
- Stale-claim searches:
  - `rg "AFTER_TASK" -- R/ tests/ vignettes/ dev/ inst/`: only references in
    its absorbed migration commit; no orphaned mentions outside the new
    `dev/design/10-after-task-protocol.md` location.
- Not run:
  - `devtools::check()`: setup-only change; no R or Julia code touched.
  - `devtools::test()`: setup-only change.
  - `pkgdown::build_site()`: setup-only change; the new docs are in `dev/`
    (intentionally not part of pkgdown's article tree).
- Next safest action: open PR `feat(agent-kit): adopt drmTMB-derived
  operating kit (adapted for clade)`, merge to main, then start Phase A
  item 1 (`default_specs()` walk) on a fresh `claude/track-B-walk` branch
  off the new main, with after-task report under `dev/dev-log/after-task/`.
