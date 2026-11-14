# Policy-frequency intervention

See [findings.md](findings.md) for design, results and limitations. `plan.md` records the primary comparison. The `results/` directory contains the 300-run checkpoint data, prior control blocks, summaries and receipts. The source is commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`; apply `intervention-hook.patch` to an isolated copy and place `intervene.jl` at its root as `intervene-v2.jl`. The driver requires the original eight founder-policy states from the preceding policy-reversal experiment. `run_totoro.py` records the executed worker setup and environment.

To reproduce the summaries, decompress `results/runs.csv.gz` and `results/prior-blocks.csv.gz` to a working directory as `runs.csv` and `prior-blocks.csv`, then run:

```sh
Rscript dev/data/policy-frequency/analyze.R WORKDIR
Rscript dev/data/policy-frequency/policy-summary.R WORKDIR
python3 dev/data/policy-frequency/audit.py WORKDIR
```

The experimental callback does not alter the package's checked-in kernel. The analysis retains all runs, including an extinction-output safeguard, and uses 100 matched seed blocks. Endpoint viability does not establish a within-run minimum.
