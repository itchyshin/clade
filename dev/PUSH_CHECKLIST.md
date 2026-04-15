# Push + deploy checklist (run on your authenticated machine)

Everything below assumes you've `git pull`-ed this repo on the machine
where `git push` works (e.g. your second machine, or any machine with
your GitHub credentials set up).

## 1. Push the branch

```bash
cd ~/Documents/clade
git fetch origin
git log --oneline origin/main..scenario-audit-0.2.0 | wc -l   # should be 43
git push -u origin scenario-audit-0.2.0
```

## 2. Open the PR

Two paths:

### Path A — GitHub CLI

```bash
gh pr create \
  --base main \
  --head scenario-audit-0.2.0 \
  --title "clade 0.3.0 — scenario audit, kernel biology fixes, CMA-ES calibration, Batesian + heritable niche, CI" \
  --body-file dev/SESSION_SUMMARY.md
```

### Path B — Web UI

Open in browser:
<https://github.com/itchyshin/clade/compare/main...scenario-audit-0.2.0?quick_pull=1>

Paste the body from `dev/SESSION_SUMMARY.md` (or summarize).

## 3. What will the CI do on push

Two workflows run automatically:

- **`.github/workflows/R-CMD-check.yaml`** — runs on every push and on
  the PR. R CMD check against R release on ubuntu; tests + vignettes
  skipped (they need Julia). Should pass — it's already clean locally.

- **`.github/workflows/pkgdown.yaml`** — runs **only on push to
  `main` / `master` and on release publication**. So pushing the
  feature branch will NOT update the pkgdown site yet. Two routes
  to update the site:

  1. **Merge the PR into main.** The pkgdown workflow fires and
     deploys `docs/` to the `gh-pages` branch. GitHub Pages serves
     from `gh-pages` → <https://itchyshin.github.io/clade/>.

  2. **Manually dispatch the workflow from the branch.** Go to
     Actions → pkgdown → Run workflow → choose
     `scenario-audit-0.2.0`. The workflow has
     `workflow_dispatch:` enabled so this works without merging.

## 4. GitHub Pages one-time setup (if not already done)

Settings → Pages:
- **Source**: Deploy from a branch
- **Branch**: `gh-pages` / `(root)`
- Save.

After the first successful pkgdown deploy, the site at
<https://itchyshin.github.io/clade/> will be live with the 0.3.0
content.

## 5. Tag the release (optional but recommended)

After the PR merges:

```bash
git checkout main
git pull origin main
git tag -a v0.3.0 -m "clade 0.3.0"
git push origin v0.3.0
```

This also triggers the pkgdown workflow (a second time) because it
watches for release events.

## 6. Verify

After the merge + deploy completes (5–15 min):

- <https://itchyshin.github.io/clade/> — landing page should show
  the new module table including Batesian and heritable niche rows.
- <https://itchyshin.github.io/clade/articles/baldwin-effect.html>
  — bottom of the article should have the "Addendum: calibrated
  regime where canalization emerges" section.
- <https://itchyshin.github.io/clade/reference/default_specs.html>
  — full parameter reference should include `batesian_mimicry`,
  `shelter_occupancy_bonus`, and the raised
  `toxicity_cost_per_tick = 2.0`.

## Shortcuts if you want the site deployed immediately without merging

Option 1: from your authenticated machine, push the locally-built
site directly:

```bash
cd ~/Documents/clade
# The docs/ dir already contains a freshly built pkgdown site.
# Deploy it manually to gh-pages:
Rscript -e 'pkgdown::deploy_to_branch(".", commit_message = "clade 0.3.0 docs", branch = "gh-pages", verbose = TRUE)'
```

Option 2: after pushing scenario-audit-0.2.0, trigger the workflow
manually via GitHub Actions UI (step 3 option 2 above).

## Nothing else to do locally

Branch state is clean. All commits are at
`scenario-audit-0.2.0` (43 commits). No unstaged changes. No
untracked files of significance (Rplots.pdf and pkgdown logs are
gitignored).

See also:
- `dev/SESSION_SUMMARY.md` — everything this session did
- `dev/audit/REVIEW.md` — what the audit produced
- `dev/audit/calibration/RESULTS.md` — CMA-ES findings
- `NEWS.md` — user-facing 0.3.0 change list
