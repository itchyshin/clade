# Independent policy-mixture replication

See [findings.md](findings.md) and [plan.md](plan.md). The research source is commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. Apply `age-treatment.patch` to an isolated source copy, then place `driver.jl` and `launch.py` at its root. The pilot and full worker commands are recorded in the launcher and execution receipts. The 100 source-state files remain in the Totoro archive at `/home/snakagaw/sim-archive/clade/2026-11-14-policy-replication/`, with their hashes in `results/state-manifest.sha256`.

For analysis, decompress `results/runs.csv.gz` and `results/windows.csv.gz` into a working directory and copy `results/sources.csv` there. From the repository root run:

```sh
Rscript dev/data/policy-replication/analyze.R WORKDIR
python3 dev/data/policy-replication/audit.py WORKDIR
Rscript dev/data/policy-replication/viable-sensitivity.R WORKDIR
Rscript dev/data/policy-replication/prior-reference.R WORKDIR
Rscript dev/data/policy-replication/plot.R WORKDIR
```

The independent prior reference uses the earlier tracked factorial window data. Minimum population is measured every tick; endpoint viability is a separate verdict.
