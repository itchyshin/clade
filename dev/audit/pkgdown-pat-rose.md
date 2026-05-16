# Pkgdown audit — Pat + Rose read (accessibility & readability)

**Date**: 2026-05-16
**Auditor lenses** (per `AGENTS.md` §"Standing Review Roles"):

- **Pat** — applied user tester: can a new behavioural ecologist
  install clade, follow a vignette, interpret the output, and recover
  from errors *without hidden context*?
- **Rose** — systems auditor: what stale wording, repeated mistakes,
  unsupported claims, missing feedback loops, or unfinished handoffs
  are accumulating? When one issue surfaces, ask "what class is it
  and where else does it live?"

**Scope**: `_pkgdown.yml`, `index.md`, `README.md`, all 70
`vignettes/*.Rmd`, and the roxygen surface of `R/*.R` that becomes
the rendered reference pages. Built site at `docs/` is from
2026-04-10 (pre-Phase A); audit is against current source.

---

## Top-line verdict

**Structurally sound, contextually leaky.** The information
architecture (themed scenarios, paper reproductions, parameter
search, kernel-as-biology) is unusually thoughtful for an R package
this size. The two recurring problems are (a) developer-process
artefacts (CLAUDE.md, PR numbers, `~/.claude/` plan files, "Phase A",
"Sergio") leaking into rendered HTML/Rd, and (b) figure
accessibility inconsistent across vignette generations (paper-*
vignettes set `fig.alt`; the 36 s-* and most core vignettes don't).

Both are easy structural fixes plus one new drift-guard test. The
core writing voice — direct, biologically grounded, honest about
nulls — is good.

---

## Pat findings (per-page, ranked by user-impact)

### P1. Developer-process leakage into rendered Rd/HTML — CRITICAL

A new user installing clade and reading `?batch_alife` sees:

> *"...see CLAUDE.md for this machine's 200-core cap"*

`CLAUDE.md` is the package author's private agent-config file. It
isn't in the source tarball. It isn't on the pkgdown site. The
sentence is unactionable. Same pattern in `?hypothesis_sweep`.

The basics vignette (the canonical "5-minute intro" added in Phase A)
opens with a developer callout:

> *"This vignette is built incrementally across the Phase A foundation
> walk (`~/.claude/plans/purring-honking-dove.md`, items 1–4)..."*

To a new user this reads as project-internal alpha-state — directly
undermines the "five minutes to a clade run" promise the rest of the
vignette delivers.

Sites of the same leak class:

| File | Line | Leak |
|---|---|---|
| `R/run.R` | 122 | "see CLAUDE.md" |
| `R/hypothesis.R` | 45 | "see CLAUDE.md" |
| `R/run.R` | 114 | bare `dev/docs/parallelism-audit.md` |
| `R/search.R` | 325 | bare `dev/docs/parallelism-audit.md` |
| `R/search.R` | 134 | bare `dev/audit/fidelity/map_elites.md` |
| `R/config.R` | 30, 853, 1696 | bare `dev/docs/...`, `dev/audit/fidelity/...` |
| `vignettes/basics.Rmd` | 29–31 | `~/.claude/plans/...md` + "Phase A foundation walk" |
| `vignettes/basics.Rmd` | 173 | bare `dev/design/00-vision.md` |
| `vignettes/getting-started.Rmd` | 227 | bare `dev/docs/timescale-analysis.md` |
| `vignettes/k-README.Rmd` | 31, 80 | bare `dev/audit/fidelity/STATUS.md` (one wrapped, one not) |
| `vignettes/k-genome.Rmd` | 468 | bare `dev/audit/fidelity/post_0510_summary.md` |
| `vignettes/k-tick.Rmd` | 102 | bare `dev/docs/kernel-0.4.0.md` |
| `vignettes/first-research-project.Rmd` | 62 | bare `dev/audit/fidelity/` |
| `vignettes/paper-emlen-1982.Rmd` | 22, 118, 171, 201 | "PR #90" |
| `vignettes/paper-fuller-2005.Rmd` | 85 | "0.6.2 (PR #106)" |
| `vignettes/paper-mcelreath-2007.Rmd` | 164 | "Candidate for Sergio's..." |

The paper-* vignettes are partly inconsistent with themselves: some
wrap `dev/audit/fidelity/*.R` in proper GitHub links (paper-courchamp,
paper-fuller, paper-dieckmann-doebeli, paper-griesser,
paper-kokko-brooks, paper-emlen, paper-reale), so the right pattern
exists in the repo — it just isn't enforced.

### P2. Figure accessibility — `fig.alt` missing in 29/37 vignettes

Of the 37 vignettes that include images, only 8 set `fig.alt`
(WCAG 1.1.1 — text alternative). Newer knitr (≥ 1.45) falls back to
`fig.cap` when `fig.alt` is unset, but the captions are typically
long paragraphs ("plot_run() produces a six-panel dashboard:
population size, mean energy (±SD ribbon), genetic diversity, births
and deaths per tick, grass coverage, and BNN prior sigma") that
aren't ideal screen-reader announcements when an image is reached
via heading-tab navigation.

The 8 paper-* vignettes that do set `fig.alt` (paper-courchamp,
paper-dieckmann-doebeli, paper-griesser, paper-emlen,
paper-kokko-brooks, paper-reale, paper-fuller, paper-ryan) have
the right pattern: short, semantic alt text for screen readers +
detailed caption for sighted readers. That same idiom should be
copied into the remaining ~29 vignettes.

### P3. Heading hierarchy violation — all 36 s-* vignettes start at H3

Every `vignettes/s-*.Rmd` begins its body with `### ` (H3), e.g.:

```
### Baseline world
```

pkgdown renders the YAML `title:` as H1, so the body should start
at H2. Skipping H1 → H3 violates WCAG 2.4.6 (Headings and Labels) and
WCAG 1.3.1 (Info and Relationships): screen-reader heading navigation
shows a gap (level 1, then level 3 with nothing between). Visually
the H3 also renders smaller than expected, making each scenario look
like a subsection of nothing.

Fix is structural: bulk-promote `^### ` → `## ` and `^#### ` → `### `
in all 36 s-* files. The `paper-*` and core vignettes do this
correctly already.

### P4. Numerical claims drift across pages

Three sets of mismatched counts in user-facing prose:

**"Worked paper reproductions" count**:
- `index.md` L148 → "5 worked examples"
- `index.md` L97-103 → lists **seven** bulleted papers in the same section
- `README.md` L38 → "5 worked paper reproductions"
- `vignettes/paper-template.Rmd` L58 → "5 worked reproductions"
- `_pkgdown.yml` papers menu → **14** paper-* vignettes (incl. template)
- Truth: 13 reproductions + 1 template.

**"Parameters in `default_specs()`" count**:
- `vignettes/getting-started.Rmd` L149 → "roughly 90 parameters in 0.4.0"
- `vignettes/basics.Rmd` L40 → "~300 fields"
- Both describe the same `default_specs()` return value; the 0.4.0
  framing is stale. Current count is closer to ~300.

**"Scenario vignettes" count** (correct, but verify when the
catalogue changes):
- index.md L147, getting-started.Rmd L439, why-clade.Rmd L63 + L190,
  scenarios.Rmd L21 → "36 scenarios" / "all 36" — all consistent
  with the Tier B2 audit's 36 `s-*.Rmd` files.

### P5. `_pkgdown.yml` editorial bugs

| Line | Issue |
|---|---|
| 360–363 | Hypothesis-testing `desc:` contains a **duplicated sentence**: "Helpers for the sweep->test->report workflow common in fidelity audits and paper reproductions. Helpers for the sweep->test->report workflow used in fidelity audits and paper reproductions." |
| 403 | Typo: "the complex landscape, spatial sorting, and **IFfolk** modules" — should be `iffolk` or `IFD-folk`. |
| 200 | `articles:` Overview section lists `basics` as first item, but the navbar `Guides` dropdown (L57–68) omits it. New users land on the Articles index and find `basics`; users using the navbar shortcut don't. |
| 17–22 | Navbar has both `intro: "Get Started" → getting-started.html` AND `articles: "Guides" → menu → "Getting started" → getting-started.html`. Two navbar entries for the same destination, two different labels. |
| 99–191 | The `scenarios` navbar dropdown re-lists every scenario already listed in `articles:` Theme groupings (L267–330). Two independently-maintained lists for the same items → drift risk (confirmed: `basics` already drifted). |
| 29–54 | Paper-reproductions menu mixes verdict tags inconsistently: `(contradiction)`, `(clean ✅)`, `(0.7.0)`, `(Zahavi leg PASS)`, `(β_N leg PASS; signal downstream null)`. A new user can't decode "(0.7.0)" or "Zahavi leg PASS" from the dropdown alone. |

### P6. Emoji in headings — `index.md`

`index.md` uses emoji as the first character of three H3 headings
(`🤝 Intraspecific`, `🦁 Interspecific`, `🌱 Environment`). Most
screen readers announce these as "handshake", "lion face", "seedling"
before the actual heading text — pleasant for sighted users but
adds noise to assistive tech. Two paper-* vignettes also use ✅/❌/⚠️
in H3s. Fix: keep emoji in section bodies; wrap heading emoji in
`<span aria-hidden="true">…</span>` or drop them from headings.

### P7. Inline-CSS grid in `index.md` (L21–62)

The "Three pillars" section uses inline `<div style="display: grid;
...">` to lay out three cards. This works in modern Bootstrap-5
themes but: (a) inline styles fight the flatly theme's dark-mode
toggle; (b) `<div markdown="1">` is GitHub-Flavoured Markdown — pkgdown
relies on Pandoc, which may or may not honour the attribute depending
on the renderer config; (c) no semantic structure (no `<section>`,
no aria-labels). Idiomatic Bootstrap-5 replacement: `.row` +
`.col-md-4` with `.card`. Lower priority because it visually works
today, but it's fragile across pkgdown theme changes.

### P8. Other Pat-eye observations

- `vignettes/getting-started.Rmd` L73–76 silently shows
  `install_github(...)` without mentioning the package is not yet on
  CRAN. A note ("CRAN release pending — install from GitHub for now")
  would set expectations.
- `vignettes/basics.Rmd` L111 references `inst/julia/src/logging.jl::_init_progress`
  as the canonical schema source. For a *basics* vignette this is
  arguably too deep — a `?get_run_data` pointer is enough; the kernel
  path belongs in `k-clade-main`.
- `_pkgdown.yml` L7–13 home description ends with "32 of 32
  biological scenarios audited against primary literature." Good
  headline number — but the same claim is repeated in the index.md
  blockquote at L7, then again at L75 ("32 of 32 scenarios pass"),
  then again at L82 ("All 32 currently pass at t > 2σ"), then again
  in `why-clade.Rmd` L46 and L174. Repetition is a feature for new
  users; the risk is one of these going stale next time the count
  changes. See ROSE-5.

---

## Rose patterns (cross-cutting; what class is each finding,
where else does it live)

| # | Class | Where it lives | Suggested guard |
|---|---|---|---|
| **ROSE-1** | **Developer-process artefacts in rendered user-facing surfaces** (CLAUDE.md, PR numbers, plan-file paths, "Phase A", "Sergio", branch names) | Cluster of 17+ sites across `R/*.R` and `vignettes/*.Rmd` (see P1 table) | New test `tests/testthat/test-no-internal-leaks.R` that scans `R/**/*.R` + `vignettes/*.Rmd` for forbidden tokens: `\bCLAUDE\.md\b`, `~/\.claude/`, `Phase [AB]\b`, `Tier [AB][0-5]?\b`, `\bPR #\d+\b`, `\bSergio\b`. Allowlist `dev/`, `NEWS.md`, and changelog files. |
| **ROSE-2** | **Internal repo paths cited in prose without GitHub-URL wrappers** | Same site cluster as ROSE-1 (subset). Several paper-* vignettes already do the right thing (`[label](https://github.com/itchyshin/clade/blob/main/...)`), so the right idiom is in the repo — it's just not enforced. | Extend ROSE-1 lint: flag bare `dev/(docs\|design\|audit)/.*\.(md\|R)\b` or `inst/julia/src/.*\.jl\b` that aren't inside a markdown link target. |
| **ROSE-3** | **Heading hierarchy starting at H3 across a whole family of vignettes** | All 36 `vignettes/s-*.Rmd` files (universal). Core and paper vignettes do not have this. | Bulk-promote `^### ` → `## ` and `^#### ` → `### ` in s-* vignettes (single commit). Optional: add a lint that asserts the first `^#+ ` in every `*.Rmd` is at level 2. |
| **ROSE-4** | **`fig.alt` missing on figure-bearing vignettes** | 29/37 figure-bearing vignettes. The 8 paper-* vignettes set it correctly, so the idiom exists. | Bulk addition of `fig.alt = "..."` (short version of `fig.cap`) to each `knitr::include_graphics`-bearing chunk in core + s-* vignettes. Optional lint: assert every `fig.cap` chunk also has `fig.alt`. |
| **ROSE-5** | **Cross-document numerical-claim drift** | "5 worked examples" (stale; actual = 14) in 3 files; "~90 parameters in 0.4.0" (stale; actual ~300) in 1 file. Risk: every other count cited in prose. | Mid-effort: a single canonical "claims snapshot" doc (`dev/audit/site-claim-snapshot.md`) listing every quantitative claim and its location; a periodic refresh is faster than a drift-guard. Low-effort: at least pin "N paper reproductions" and "N scenario vignettes" to single canonical strings sourced from `_pkgdown.yml` length(). |
| **ROSE-6** | **Navbar / articles list duplication and divergence** | `_pkgdown.yml` `navbar.menu.scenarios` (44 entries) re-lists everything already in `articles:` Theme groupings. The `basics` omission in the `Guides` navbar is exactly this drift in action. | Drop the per-scenario items from the navbar dropdown; keep only "All scenarios (index)" + the seven Theme group headers as plain text. The articles index page is already the better surface for a 36-item catalogue on mobile. |
| **ROSE-7** | **Emoji in headings** | `index.md` (3 H3s) + 2 paper-* vignettes (3 H3s). | Style guideline + lint: emoji belong in body text or wrap with `aria-hidden="true"` spans when in headings. |

---

## Recommended action plan (sequenced, low-risk → high-risk)

### Tier 1 — single commit, ~30 min, no behaviour change

1. **Fix ROSE-1 P1-class CLAUDE.md leaks** in `R/run.R:122`,
   `R/hypothesis.R:45`. Replace with concrete numbers ("on a machine
   with N cores") or drop the qualifier.
2. **Remove the Phase-A callout from `vignettes/basics.Rmd:29–31`**.
3. **De-Sergio `vignettes/paper-mcelreath-2007.Rmd:164`** and
   de-PR-number paper-emlen + paper-fuller.
4. **Wrap bare `dev/docs/...md` and `dev/audit/...` paths** in the
   identified vignette + roxygen sites as GitHub URLs (use existing
   paper-* idiom).
5. **`_pkgdown.yml` fixes**: deduplicate L360 sentence, fix L403
   "IFfolk" typo, add `basics` to the Guides navbar dropdown.

### Tier 2 — single commit, ~20 min, structural

6. **Bulk-promote H3 → H2** in all 36 `vignettes/s-*.Rmd` (ROSE-3).
   `sed -i '' 's/^### /## /; s/^#### /### /' vignettes/s-*.Rmd`,
   verify each file's first heading is now H2.
7. **Refresh stale numerical claims**: "5 worked" → "14 paper
   reproductions" (or "13 + template") in index.md L148, README.md
   L38, paper-template.Rmd L58; "~90 parameters in 0.4.0" → "~300
   parameters" in getting-started.Rmd L149.

### Tier 3 — separate commit, ~1 h, accessibility

8. **Bulk-add `fig.alt`** to all figure chunks in s-* + core
   vignettes (ROSE-4). Copy idiom from any paper-* vignette.

### Tier 4 — deferred, ~2 h

9. **Add `tests/testthat/test-no-internal-leaks.R`** drift-guard
   for ROSE-1 + ROSE-2 (forbidden-token + bare-path scan).
10. **Audit + simplify navbar** (ROSE-6): drop per-scenario items
    from `scenarios` dropdown; keep only "All scenarios (index)" +
    seven theme group headers.

### Out of scope (separate concerns)

- `index.md` inline-CSS grid (P7) — works today, refactor only if
  flatly theme breaks it.
- pkgdown theme / branding (P6 emoji) — style decision, not bug.
- README.md ↔ index.md duplication overall — both serve different
  audiences; align numbers only.

---

## Out of scope for this audit

- Rendering the site (the `docs/` directory is 5 weeks stale; that's
  a `pkgdown::build_site()` job, not an audit).
- Changing any spec field, Julia kernel, or simulation behaviour
  (Track A territory).
- Re-running multi-seed fidelity scripts (Phase B is complete; this
  is a docs-only pass).

---

## Provenance

- Pat / Rose definitions: `AGENTS.md` L255–256.
- Source files inspected: `_pkgdown.yml` (full); `index.md` (full);
  sample reads of `vignettes/{basics, getting-started, baldwin-effect,
  paper-mcelreath-2007, paper-wolf2007, s-baseline}.Rmd`; `R/run.R`
  L1–160; `R/{config,hypothesis,search}.R` (grep targets); first-
  heading scan over all 36 `vignettes/s-*.Rmd`; figure-chunk pattern
  scan over all 70 vignettes.
- Built site spot-checks: `docs/index.html`,
  `docs/reference/default_specs.html`, `docs/reference/batch_alife.html`.
