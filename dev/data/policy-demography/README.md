# Policy birth and death accounting

See [findings.md](findings.md), [plan.md](plan.md), and [research-plan.md](research-plan.md). The execution source is `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. The copied callback patch is applied only to an isolated research source. Founder state files are inherited from the preceding policy-switch experiment.

Uncompress `results/runs.csv.gz` and `results/prior-runs.csv.gz` into a working directory, then run from the repository root:

```sh
Rscript dev/data/policy-demography/analyze.R WORKDIR
Rscript dev/data/policy-demography/viability.R WORKDIR
python3 dev/data/policy-demography/audit.py WORKDIR
```

Birth age is parent age after the tick's increment. Death age uses the same point; exposure is pre-mortality agent-ticks. Each event record covers the interval ending at its checkpoint.
