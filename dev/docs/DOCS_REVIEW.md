# Documentation review cadence

*A short process doc for keeping clade's user-facing documentation in sync
with the code. Read this before cutting a release or merging any PR that
adds a scenario, module, or kernel feature.*

---

## Why this exists

clade's docs drift. The audit that motivated the Phase 1–4 cleanup
(PRs #73–#76) found:

- Scenario counts had drifted from 36 to "35 pre-packaged scenarios" in
  two places.
- A new scenario (`s-brain-comparison`) existed on disk but was missing
  from both the `scenarios.Rmd` table and the `_pkgdown.yml` navbar.
- Three build scripts (`generate_figures.R`, `gen_fixed_patch_fig.R`,
  `gen_hn_fig.R`) were shipping as user-facing "vignettes" because they
  lived in `vignettes/`.
- The fidelity ledger count ("26 of 30") on one page contradicted the
  headline ("all 32 of 32 auditable scenarios pass") on another.

These are all preventable. This doc says what to check, when, and how.

---

## Pre-release checklist

Run before cutting any versioned release (0.5.x → 0.5.x+1, etc.).

### 1. Scenario counts agree

**Two distinct counts exist — don't confuse them:**

- **Total scenarios** (currently 36) — every `s-*.Rmd`, including
  discovery experiments (`s-module-comparison`, `s-kitchen-sink`,
  `s-cross-module`, `s-bad-science`) that are marked ⚪ N/A in the
  audit.
- **Auditable scenarios** (currently 32) — the subset that has a
  single literature-grounded prediction the audit can verify. Used
  for the "32 of 32 pass" ledger headline.

```bash
# Current totals
N_TOTAL=$(ls vignettes/s-*.Rmd | wc -l); echo "total: $N_TOTAL"
# Auditable count comes from dev/audit/fidelity/STATUS.md — manual check

# Every two-digit scenario-count reference — inspect each
grep -rn "[0-9][0-9] scenarios\|[0-9][0-9] pre-packaged" \
  README.md index.md vignettes/*.Rmd
```

For each line in the output, identify whether it refers to the total
or the auditable count, and confirm it matches. Lines about CMA-ES
concurrency (`"< 20 scenarios"`, `"50 scenarios × 50 cores"` in
`parameter-space-search.Rmd`) are prose examples, not package counts
— ignore those.

### 2. Fidelity ledger counts agree

The ledger count appears in at least four places. They must match.

```bash
# Headline count (e.g. "32 of 32")
grep -n "of 32\|of 33\|of 34\|of 35\|of 36" \
  README.md index.md \
  dev/audit/fidelity/DASHBOARD.md \
  dev/audit/fidelity/STATUS.md

# Badge (https://img.shields.io/badge/fidelity-NN%2FNN-...)
grep -n "img.shields.io/badge/fidelity" README.md index.md
```

If the ledger moved (promotion, demotion, new auditable scenario),
update all four.

### 3. Every scenario is surfaced in the three navigation paths

Every `s-*.Rmd` must appear in:

- `vignettes/scenarios.Rmd` (Theme N table)
- `_pkgdown.yml` navbar `scenarios` menu
- `_pkgdown.yml` articles-section `Theme N` contents list

```bash
# Files on disk
ls vignettes/s-*.Rmd | sed 's|vignettes/||;s|\.Rmd$||' | sort > /tmp/scen_files.txt

# Files in articles section of _pkgdown.yml
grep -oE "^\s+-\s+s-[a-z-]+$" _pkgdown.yml | awk '{print $2}' | sort -u > /tmp/scen_pkgdown.txt

# Files listed as links in scenarios.Rmd
grep -oE "\(s-[a-z-]+\.html\)" vignettes/scenarios.Rmd | sed 's|[()]||g;s|\.html||' | sort -u > /tmp/scen_table.txt

# Expect all three sets to be identical
diff /tmp/scen_files.txt /tmp/scen_pkgdown.txt
diff /tmp/scen_files.txt /tmp/scen_table.txt
```

### 4. Every scenario has a Citation footer

```bash
# Expect zero output — every s-*.Rmd should have "## Citation"
grep -L "^## Citation" vignettes/s-*.Rmd
```

### 5. README modules table points to existing scenarios

```bash
# Every "See [...s-*](URL)" link in README should resolve to a real file
grep -oE "articles/s-[a-z-]+\.html" README.md | \
  sed 's|articles/||;s|\.html|.Rmd|' | sort -u | \
  while read f; do test -f "vignettes/$f" || echo "MISSING: $f"; done
```

### 6. No build scripts leaking into vignettes/

```bash
# Expect only .Rmd files in vignettes/
ls vignettes/*.R 2>/dev/null && echo "WARN: build scripts in vignettes/" || echo "OK"
```

### 7. DESCRIPTION Title ≤ 65 chars (CRAN guideline)

```bash
awk -F': ' '/^Title:/ {print length($2), "chars:", $2}' DESCRIPTION
```

### 8. Landing page scenario links resolve

```bash
# Every articles/s-*.html link in index.md → vignettes/s-*.Rmd must exist
grep -oE "articles/s-[a-z-]+\.html" index.md | \
  sed 's|articles/||;s|\.html|.Rmd|' | sort -u | \
  while read f; do test -f "vignettes/$f" || echo "MISSING: $f"; done
```

### 9. pkgdown site builds clean

```r
pkgdown::build_site()
# Expect: no errors; no "article not found" warnings; all vignettes rendered
```

---

## Update triggers

When you do X, update Y.

| Change | Update |
|---|---|
| Add new `s-*.Rmd` scenario | (1) `scenarios.Rmd` Theme N table row; (2) `_pkgdown.yml` navbar scenarios menu; (3) `_pkgdown.yml` articles `Theme N` contents list; (4) `## Citation` footer appended to the new vignette; (5) scenario count bumped in README / index.md / `getting-started.Rmd` / `scenarios.Rmd` intro; (6) if a new module was added alongside, add a row to the README biological-modules table with "See" column |
| Add new module (Julia kernel) | README modules table row with flag + domain emoji + scenario link (or `—` if no dedicated scenario yet); `default_specs()` doc + example |
| Promote / demote a scenario's fidelity verdict | `dev/audit/fidelity/STATUS.md` per-scenario line; `dev/audit/fidelity/DASHBOARD.md` counts + verdict table; README headline count if the ledger total moved; `index.md` 32/32 trust block if the total moved |
| Add a new brain type | README brain-architectures table; `s-brain-comparison` scenario vignette; `?default_specs` doc for `brain_type` enum |
| Bump package version (e.g. 0.5.18 → 0.6.0) | `DESCRIPTION:3`; `NEWS.md` new section; `CITATION`; consider whether the `clade2026` BibTeX entry's `year` needs updating across `index.md` + 36 `s-*.Rmd` Citation footers (annual — do it at the January release if possible) |
| Add a new textbook anchor (e.g. an open-access teaching resource) | `index.md` "The three-pillar framing" footnote; `why-clade.Rmd` "Recommended reading" section |
| Retire / rename a module | Grep for the module flag in vignettes + README + `_pkgdown.yml` + `default_specs()`; either swap to the new name everywhere or add a deprecation notice |

---

## Patterns that warn you of drift

If any of these commands produce output, something is stale.

```bash
# 1. Stale scenario counts
grep -rn "all [0-9][0-9] scenarios\|[0-9][0-9] pre-packaged scenarios" \
  README.md index.md vignettes/*.Rmd

# 2. References to moved build scripts
grep -rn "vignettes/generate_figures\|vignettes/gen_fixed_patch\|vignettes/gen_hn_fig" \
  --include="*.md" --include="*.R" --include="*.Rmd" --include="*.yml" . \
  | grep -v "^./docs/" | grep -v "^./inst/" | grep -v "DOCS_REVIEW.md"

# 3. Scenarios missing from the three surfaces (uses /tmp setup from §3 above)
diff /tmp/scen_files.txt /tmp/scen_pkgdown.txt
diff /tmp/scen_files.txt /tmp/scen_table.txt

# 4. Scenarios missing Citation footer
grep -L "^## Citation" vignettes/s-*.Rmd

# 5. Broken cross-links in README modules table
grep -oE "articles/s-[a-z-]+\.html" README.md | \
  sed 's|articles/||;s|\.html|.Rmd|' | sort -u | \
  while read f; do test -f "vignettes/$f" || echo "MISSING: $f"; done

# 6. DESCRIPTION Title length
awk -F': ' '/^Title:/ {if (length($2) > 65) print "OVERLENGTH:", length($2), "chars"}' DESCRIPTION
```

Consider scripting these as a single `dev/audit/docs_lint.R` eventually.
For now, the grep commands above plus `pkgdown::build_site()` catch the
most common drift patterns.

---

## What **not** to worry about

These things look like drift but aren't:

- Non-ASCII characters in `R/run.R`, `R/search.R`, `R/visualization.R` —
  long-standing, tracked as a separate issue, not a release-blocker.
- Pre-existing `check_man` LaTeX-escape note on `default_specs.Rd` —
  roxygen quirk, not our text.
- `NLMR` dependency warning — conditional import, documented in
  DESCRIPTION `Suggests:`.
- `vignettes/baldwin-effect.Rmd` appearing in the nav but not in the
  `scenarios.Rmd` table — intentional; it's a long-form article
  companion to `s-baldwin`, not a scenario per se.
- `docs/` being dirty after a local `pkgdown::build_site()` — gitignored
  per `.gitignore`; never commit.

---

## When to run this checklist

- **Before every release** (versioned bump to `DESCRIPTION` / `NEWS.md`).
- **After merging a PR that adds a scenario or module**, as a
  follow-up commit if the author missed updates.
- **Once a quarter** as a scheduled sweep, even if no release is
  planned — counts and ledger drift silently.

---

## Related files

- `README.md` — modules table, headline, ledger count
- `index.md` — pkgdown landing page; three-pillar grid + fit table
- `_pkgdown.yml` — navbar + articles index; scenario organisation
- `vignettes/scenarios.Rmd` — per-theme scenario discovery tables
- `vignettes/getting-started.Rmd` — scenario count in "Where to go next"
- `vignettes/why-clade.Rmd` — positioning copy; recommended reading
- `vignettes/first-research-project.Rmd` — workflow template
- `vignettes/troubleshooting.Rmd` — FAQ / symptom index
- `dev/audit/fidelity/STATUS.md` — per-scenario ledger
- `dev/audit/fidelity/DASHBOARD.md` — ledger summary + verdict counts
- `DESCRIPTION` — package Title, Description, Version
- `CITATION` — cite-me metadata for R's `citation()` function
