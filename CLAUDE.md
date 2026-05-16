# Claude Code Instructions For clade

Read `AGENTS.md` first. Follow the same scope, coding principles, design
rules, standard commands, definition of done, conventions, standing
review roles, after-task protocol, check-log discipline, and recovery
checkpoints as Codex and any other agent.

Then read for context:

- `dev/design/00-vision.md` — vision, lab values, scope, core contracts,
  evidence standard.
- `dev/design/10-after-task-protocol.md` — closure ritual for every
  meaningful task.
- `dev/dev-log/check-log.md` — newest entries describe the latest state
  of main.
- `dev/dev-log/after-task/` — recent task closures.

Do not introduce a parallel agent configuration system. Durable
decisions belong in repository files:

- `AGENTS.md` for operating rules.
- `dev/design/` for vision and protocols.
- `dev/dev-log/check-log.md` for validation evidence and handoff notes.
- `dev/dev-log/after-task/` for closure reports.
- `dev/dev-log/decisions.md` for architectural decisions broader than
  one task.
- GitHub issues and pull requests for discussions that need review.

Before editing after a handoff or crash:

``` sh
git status --short --branch
git diff --stat
git diff
```

Then read the newest check-log entry and the latest after-task reports
before doing anything else.
