# Policy- and age-specific demographic replay

See `plan.md` for the observational design and `findings.md` for results. The source commit is `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. In an isolated source copy, apply `dev/data/policy-stability/assay-final.patch`, `dev/data/policy-stability/unique-source.patch`, `dev/data/policy-density-factorial/dynamic-density.patch` and `intake-observer.patch`, then copy `driver.jl` and `launch.py` to its root. Source states are the archived files from the preceding density factorial, identified by its SHA-256 manifest.

The full raw 50-tick table is archived on Totoro at the path and SHA-256 in `results/raw-windows.json`; the aggregate policy-by-age blocks and summaries are tracked here. Copy and decompress the archive to `WORKDIR/windows.csv`, then from the repository root run:

```sh
python3 dev/data/policy-pathways/reduce.py WORKDIR dev/data/policy-density-factorial/results
Rscript dev/data/policy-pathways/analyze.R WORKDIR
Rscript dev/data/policy-pathways/policy-analysis.R WORKDIR
python3 dev/data/policy-pathways/audit.py WORKDIR
python3 dev/data/policy-pathways/audit-dominance.py WORKDIR
python3 dev/data/policy-pathways/audit-rates.py WORKDIR
python3 dev/data/policy-pathways/check-factorial.py WORKDIR dev/data/policy-density-factorial/results
Rscript dev/data/policy-pathways/plot.R WORKDIR
```

The 32-entry vectors use policy as the fastest-changing index and four age bands as the slower index. Births use parent age and policy, deaths use the individual's age and policy, and intake records grass consumed. Food and demographic rates divide within-run totals by pre-mortality agent-ticks; control rates pool the eight controls. Undefined rates retain their missing denominators in the summary.
