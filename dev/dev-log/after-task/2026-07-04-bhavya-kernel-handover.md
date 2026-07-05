# After Task: Bhavya Julia/Kernel Handover

## Goal

Update the project after Sergio stepped away and Bhavya @b1805 became the
active Julia/kernel collaborator. Make the handover welcoming, preserve the
R<->Julia boundary guardrails, and close only housekeeping that is genuinely
done.

## Implemented

- Posted the approved coordination note on PR #170:
  <https://github.com/itchyshin/clade/pull/170#issuecomment-4882344544>.
- Closed issue #171 as a duplicate of PR #170.
- Updated `AGENTS.md` so Track A now names Bhavya @b1805 as the
  Julia/kernel continuity owner, while preserving the rule that
  `inst/julia/src/` changes need explicit coordination.
- Updated `dev/design/00-vision.md` so current method-development and
  v0.8-core follow-through language no longer points to Sergio as the
  active lane.
- Added a durable decision entry in `dev/dev-log/decisions.md`.

## Files Changed

- `AGENTS.md`
- `dev/design/00-vision.md`
- `dev/dev-log/decisions.md`
- `dev/dev-log/check-log.md`
- `dev/dev-log/after-task/2026-07-04-bhavya-kernel-handover.md`

`CLAUDE.md` was already locally modified with a Shinichi hub pointer before
this task and was not edited here. `AGENTS.md` also already had a Shinichi hub
pointer; this task preserved it while editing nearby ownership text.

## Checks Run

- `git status --short --branch`: confirmed `main` tracks `origin/main` and
  showed local documentation/process changes only.
- `git diff -- AGENTS.md dev/design/00-vision.md dev/dev-log/decisions.md`:
  reviewed the immediate ownership diff before writing this report.
- `git diff --check -- AGENTS.md dev/design/00-vision.md dev/dev-log/decisions.md`:
  exit 0, no whitespace errors.
- `rg -n "Sergio|Bhavya|b1805|pooherna|claude/v0.8-core|Track A|v0.8-core" AGENTS.md dev/design/00-vision.md dev/dev-log/decisions.md README.md NEWS.md R tests vignettes dev/audit dev/dev-log/check-log.md`:
  active coordination docs now point to Bhavya; remaining Sergio hits are
  historical audit/check-log records or intentional forbidden-token tests.

## Tests Of The Tests

No tests were added or changed. The only test-related check was that the
existing `tests/testthat/test-no-internal-leaks.R` hit for "Sergio" is an
intentional guard against leaking internal names into user-facing R/vignette
surfaces, not a stale ownership instruction.

## Consistency Audit

Tree check: the changed files tell one story: Bhavya @b1805 is the active
Track A collaborator, PR #122 is historical/scoping state until superseded,
and broad Julia/kernel work still needs explicit coordination.

Forest check: no R functions, Julia kernel files, tests, vignettes, generated
Rd, NAMESPACE, or pkgdown output were changed. No public API or biological
simulation behaviour changed.

Rose/generalisation check: the same stale-owner class appeared in both
`AGENTS.md` and `dev/design/00-vision.md`, so both were updated. Historical
audit notes mentioning Sergio were left intact because they were true when
written and are not active instructions.

## What Did Not Go Smoothly

The GitHub connector could read repository state but returned 403 when trying
to post comments. The browser fallback also stalled on GitHub. A local GitHub
credential was available, so the approved PR comment and duplicate closure
were completed through the GitHub REST API without printing credentials.

## Team Learning

Ownership changes need to live in repo files, not only in a PR comment. For
new collaborators, especially someone taking over a lane after another person
left, the best first move is warm welcome plus small focused PR boundaries.

## Known Limitations

- PR #170 remains open and should be split rather than merged as-is.
- PR #169 remains open and needs repair before it can close #166/#168.
- PR #122 still needs a deliberate decision: merge as historical inventory,
  close as superseded, or replace with a Bhavya-owned core checkpoint.
- Issues #111, #120, #164, #165, #167, and #172 remain real unresolved work.

## Next Actions

1. Repair PR #169 as the first small mergeable cleanup.
2. Keep #172 open as Bhavya's first native-Julia/default-normalization lane.
3. Ask Bhavya to split #170 into R-side post-run visualization, Julia default
   normalization, then native live visualization only after the interface is
   agreed.
4. Decide the fate of PR #122 under the new Track A ownership.
