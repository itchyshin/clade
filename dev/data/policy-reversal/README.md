# Policy frequencies, density and the mixture reversal

The [findings](findings.md) trace the original haploid policy mixtures and
balanced controls, investigate demographic waves and compare a matched
higher-regrowth intervention. [plan.md](plan.md) records the estimands,
causal limits and cap sensitivity. Raw traces, summaries, figures, timing and
checksums are under results/.

The simulation source is commit 2b6ea12bbbccf06f62e700edf5653eeb7c950cc6.
All three private drivers use its canonical loop and existing mixture
initializer. They are derived from the earlier mixture assay. They do not
modify the public kernel. The endpoint brain archive and Totoro paths are
recorded in results/run.json. The source archive is Julia 1.10.0-specific.

To replay one seed, extract that source into a fresh directory, copy trace.jl
there as trace.jl, then run on Totoro:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia +1.10.0 --project=inst/julia \
  trace.jl 1 20001 OUTDIR STATE_DIR
```

trace-high.jl changes only grass regrowth and adds capacity monitoring.
trace-age.jl adds a passive pre-reproduction age/energy observer. The three
launcher files record the exact eight-worker runs and use named Totoro paths;
adapt paths and use fresh output directories for a repeat.

To repeat analysis, decompress the three trace CSVs into OUTDIR and decompress
the preceding factorial study's windows.csv.gz to FACTORIAL_WINDOWS. From
the repository root run:

```sh
python3 dev/data/policy-reversal/analyze.py OUTDIR/trace.csv FACTORIAL_WINDOWS OUTDIR
Rscript dev/data/policy-reversal/summarize.R OUTDIR
python3 dev/data/policy-reversal/demography.py OUTDIR
Rscript dev/data/policy-reversal/demography.R OUTDIR
python3 dev/data/policy-reversal/audit-changes.py OUTDIR
python3 dev/data/policy-reversal/analyze-high.py OUTDIR/high-trace.csv OUTDIR/trace.csv OUTDIR
Rscript dev/data/policy-reversal/compare-food.R OUTDIR
Rscript dev/data/policy-reversal/viability-high.R OUTDIR
python3 dev/data/policy-reversal/analyze-age.py OUTDIR/age-trace.csv OUTDIR/trace.csv OUTDIR
Rscript dev/data/policy-reversal/age-summary.R OUTDIR
python3 dev/data/policy-reversal/audit-effects.py OUTDIR
python3 dev/data/policy-reversal/forage.py OUTDIR/trace.csv OUTDIR/baseline-forage-blocks.csv
Rscript dev/data/policy-reversal/forage.R OUTDIR baseline
python3 dev/data/policy-reversal/forage.py OUTDIR/high-trace.csv OUTDIR/high-forage-blocks.csv
Rscript dev/data/policy-reversal/forage.R OUTDIR high
python3 dev/data/policy-reversal/age-wave.py FACTORIAL_WINDOWS OUTDIR/age-wave-blocks.csv
Rscript dev/data/policy-reversal/age-wave.R OUTDIR
Rscript dev/data/policy-reversal/changes.R OUTDIR
Rscript dev/data/policy-reversal/plot.R OUTDIR
Rscript dev/data/policy-reversal/diagnostic-plot.R OUTDIR
```

The forensic accounting is descriptive. The regrowth manipulation changes
resource renewal but can also change density, policy frequencies and cap
exposure. It does not separately intervene on those downstream processes.
