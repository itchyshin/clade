# Long policy mixtures under food limitation

The [findings](findings.md) compare 1,000-tick populations with staggered
founder ages and reduced food. Each mixture is compared with the balanced
mean of eight single-policy controls. Raw run and 50-tick window tables,
seed-block contrasts, intervals, timings and checksums are in results/.

The simulation source is commit 2b6ea12bbbccf06f62e700edf5653eeb7c950cc6.
The single-line age change in staggered-ages.patch was applied only to an
isolated source copy. Initial grass probability .25 and regrowth .025/.0125
are specified by the driver. It reads the corrected endpoint brains retained
on Totoro at the path recorded in results/run.json.

To reproduce a seed block on Totoro, extract that source into a fresh directory,
apply the patch there, copy driver.jl to the source root as long-full.jl, then
run the following from that root with Julia 1.10.0:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia +1.10.0 --project=inst/julia \
  long-full.jl /tmp/clade-long-replay 20001 1
```

For the complete campaign, run the four seed shards shown in run_totoro.py.
The analyzer takes the combined output directory and expects all 100 seeds:

```sh
Rscript dev/data/policy-long/analyze.R OUTDIR
python3 dev/data/policy-long/audit.py OUTDIR
Rscript dev/data/policy-long/plot.R OUTDIR
```

Decompress runs.csv.gz and windows.csv.gz into OUTDIR to rerun analysis.
The launcher is the original Totoro-specific receipt and uses absolute paths;
choose a new output directory when adapting it. The source policies are Julia
Serialization files bound to Julia 1.10.0, with no cross-version guarantee.
