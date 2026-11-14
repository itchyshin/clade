# Matched policy-switch experiment

See [findings.md](findings.md) and [plan.md](plan.md). Source commit: `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. In an isolated source copy, apply `intervention-hook.patch` and put `intervene.jl` at its root. The driver uses the founder states from the preceding policy-frequency experiment. `run_totoro.py` records the full worker setup.

Decompress `results/runs.csv.gz` and `results/prior-blocks.csv.gz` into a working directory, then from the repository root run:

```sh
Rscript dev/data/policy-switches/analyze.R WORKDIR
Rscript dev/data/policy-switches/policy-summary.R WORKDIR
Rscript dev/data/policy-switches/viability.R WORKDIR
python3 dev/data/policy-switches/audit.py WORKDIR
```

The tick-600 policy counts in the checkpoint rows are pre-intervention. The `counts_after` column records the manipulated distribution. All age bins are measured after each tick; density is population divided by 900 cells.
