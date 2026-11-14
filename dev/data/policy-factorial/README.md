# Matched food and founder-age experiment

[Findings](findings.md) report the factorial effects on the policy-mixture
population advantage. The complete design, estimands and limits are in
[plan.md](plan.md). The figure and raw data are in results/.

The simulation source is commit 2b6ea12bbbccf06f62e700edf5653eeb7c950cc6.
The one-line age-treatment patch was applied to an isolated source copy.
The driver and launcher use Totoro archive paths recorded in results/run.json.
To reproduce a single seed, extract that source archive in a fresh directory,
apply age-treatment.patch there, copy driver.jl to the source root as
factorial.jl, and run with Julia 1.10.0:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia +1.10.0 --project=inst/julia \
  factorial.jl /tmp/clade-factorial-replay 20001 1
```

To reproduce analysis, decompress runs.csv.gz and windows.csv.gz into a fresh
OUTDIR, then run:

```sh
Rscript dev/data/policy-factorial/analyze.R OUTDIR
python3 dev/data/policy-factorial/audit.py OUTDIR
Rscript dev/data/policy-factorial/timecourse.R OUTDIR
Rscript dev/data/policy-factorial/viable-sensitivity.R OUTDIR
Rscript dev/data/policy-factorial/plot.R OUTDIR
```

The previous 300-tick baseline check and exact earlier limited-food replay
are recorded separately. Source endpoint brains remain on Totoro and are
Julia Serialization files bound to Julia 1.10.0.
