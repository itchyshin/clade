# Self-hosted GitHub Actions runner — setup guide

*For the clade repo maintainer only. This doc explains how to run
clade’s CI on your own machine instead of burning the 3 000 min/month
Actions budget of the GitHub Free plan.*

------------------------------------------------------------------------

## Why

- clade is a **private repo** on the Free plan, which caps Actions at
  **3 000 min/month**. Public repos have unlimited minutes, but making
  clade public pre-publication isn’t on the table.
- CI on a self-hosted runner uses **zero GitHub minutes**. The runner is
  a small Docker-free agent that runs on your own Linux machine (≈ 1 TB
  RAM, 200+ cores per `CLAUDE.md`). Capacity dwarfs anything GitHub’s
  shared runners offer.
- Combined with the `paths-ignore` already added to `R-CMD-check.yaml`
  (docs-only PRs skip CI entirely), self-hosted brings the monthly bill
  to effectively zero.

## Trust caveat — why self-hosted is OK for a private repo

GitHub explicitly recommends **against** self-hosted runners on public
repos, because any user who can open a PR could run arbitrary code on
your machine via the CI. clade is private, so only collaborators can
trigger the runner — the threat model is acceptable.

------------------------------------------------------------------------

## Setup (≈ 20 minutes, one-time)

### 1. Get a registration token

1.  Go to `https://github.com/itchyshin/clade/settings/actions/runners`.
2.  Click **New self-hosted runner** → **Linux** → **x64**.
3.  Note the `--token XXXX…` value shown — you’ll use it in step 3.
    (Token expires in 1 hour; generate fresh if needed.)

### 2. Download the runner

On your machine (pick a directory that isn’t inside the repo — e.g.
`~/gh-runner-clade`):

``` bash
mkdir -p ~/gh-runner-clade && cd ~/gh-runner-clade

# Version pinned to 2.319.1 as of 2026-04-19 — GitHub shows the
# current version on the runner-setup page; copy-paste that instead
# if it's newer.
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz

tar xzf actions-runner-linux-x64.tar.gz
```

### 3. Register the runner

``` bash
./config.sh \
  --url https://github.com/itchyshin/clade \
  --token <paste token from step 1> \
  --name clade-self-hosted \
  --labels self-hosted,linux,x64,clade \
  --work _work \
  --unattended
```

You should see `✓ Runner successfully added` and
`✓ Runner connection is good`.

### 4. Start the runner

**For a quick test — foreground:**

``` bash
./run.sh
# keeps running until you Ctrl-C
```

**Or as a systemd service (recommended for “always on”):**

``` bash
sudo ./svc.sh install
sudo ./svc.sh start

# check status:
sudo ./svc.sh status
```

This registers a
`actions.runner.itchyshin-clade.clade-self-hosted.service` systemd unit.
It starts at boot; `sudo ./svc.sh stop` pauses it;
`sudo ./svc.sh uninstall` removes it entirely.

### 5. Switch CI to self-hosted

Once the runner is registered and shown as **Idle** in the GitHub
Actions → Runners page, edit `.github/workflows/R-CMD-check.yaml`:

``` yaml
jobs:
  R-CMD-check:
    runs-on: self-hosted     # was: ubuntu-latest
```

And similarly in `.github/workflows/pkgdown.yaml` if you want pkgdown
builds to stop using GitHub minutes too. (pkgdown requires a bit more
setup — Pandoc, R, system deps — so you might leave it GitHub-hosted
initially and only move it over once R-CMD-check has proven reliable.)

Commit and push; next PR or push will run on your box.

------------------------------------------------------------------------

## Health-check commands (run on the runner machine)

``` bash
# Is the runner service alive?
sudo ./svc.sh status

# Recent activity (workflow-run logs):
ls -lt ~/gh-runner-clade/_diag/Runner_*.log | head -3
tail -50 $(ls -t ~/gh-runner-clade/_diag/Runner_*.log | head -1)

# Disk space for artifacts (can grow over time):
du -sh ~/gh-runner-clade/_work/
```

Periodically prune `_work/` if it fills: each workflow run leaves a
scratch directory. Safe to delete the contents of `_work/` when no
workflow is running.

------------------------------------------------------------------------

## Dependencies the runner needs installed locally

R-CMD-check on clade needs (once-per-machine, installed outside the
runner):

- **R ≥ 4.1**. Install via your distro’s package manager or
  [`rig`](https://github.com/r-lib/rig).
- **Pandoc** (`sudo apt-get install pandoc`).
- **System libs** matching the ones `R-CMD-check.yaml` installs in CI:
  `libcurl4-openssl-dev libssl-dev libxml2-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev`.
- **R packages**: `rcmdcheck`, `devtools`, `testthat`, `jsonlite`.
  Install with `install.packages(...)` once; subsequent CI runs reuse
  the user library.
- **Julia** is NOT needed — R-CMD-check is configured to skip Julia-
  dependent tests and vignettes.

If you later move `pkgdown.yaml` over too, the same deps apply plus
`pkgdown` itself.

------------------------------------------------------------------------

## If things go wrong

| Symptom | Likely cause | Fix |
|----|----|----|
| Workflow queued forever, never starts | Runner offline, or workflow `runs-on: self-hosted` but runner registered with different labels | Check runner page shows **Idle**; verify labels match |
| Runner shows **Offline** on GitHub | Service died / machine rebooted | `sudo ./svc.sh start`, or `./run.sh` manually to see errors |
| `./run.sh` errors with “Missing: libicu” etc. | System deps not installed | Install deps per “Dependencies” section above |
| Permission denied on `svc.sh install` | systemd needs root | `sudo` the command; or run `./run.sh` manually instead |
| R package install fails in CI | Missing system dep or Rtools | `R -e 'install.packages("<pkg>")'` locally to see the actual error |
| Want to delete the runner entirely | — | `sudo ./svc.sh uninstall && ./config.sh remove --token <fresh-token>` |

------------------------------------------------------------------------

## When to revert to GitHub-hosted

If you ever want to flip back (e.g., machine is down for a long holiday,
or you go public and minutes are unlimited):

``` yaml
runs-on: ubuntu-latest   # was: self-hosted
```

That’s it. The runner binary keeps running harmlessly in the background
until you uninstall it.
