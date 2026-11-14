# Matched founder-density and reproduction factorial

See `plan.md` for the prespecified comparisons and `findings.md` for results and limitations. The source commit is `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. In an isolated source copy, apply `dev/data/policy-stability/assay-final.patch`, `dev/data/policy-stability/unique-source.patch`, then `dynamic-density.patch`, and copy `driver.jl` and `launch.py` into its root. Execution paths and worker limits are recorded in `launch.py` and the receipts. Source-state files remain on Totoro and are indexed by the included SHA-256 manifest.

Decompress `results/runs.csv.gz` and `results/windows.csv.gz` and copy `results/sources.csv` into a working directory. From the repository root:

```sh
Rscript dev/data/policy-density-factorial/analyze.R WORKDIR
python3 dev/data/policy-density-factorial/audit.py WORKDIR
Rscript dev/data/policy-density-factorial/stability.R WORKDIR
Rscript dev/data/policy-density-factorial/plot.R WORKDIR
```

Every-tick minimum, peak and cap counts are separate from the endpoint viability verdict. Missing or insufficient source populations are recorded rather than replaced.
