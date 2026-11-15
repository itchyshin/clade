# Stable food-by-threshold study

The preregistered design and candidate screen are in `plan.md`; see `findings.md` for results and limits. Source commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6` uses the isolated research patches listed in `dev/data/age-dose-pilot/README.md`. Copy the study driver and Julia checks into that patched source root. Totoro-specific output and source paths are in `results/raw-data.json`.

All individual cohorts, population records, source panels and pilot opportunity events remain on Totoro. The matching audit checks fingerprints within each threshold; `check-starts.jl` reconstructs each start and compares a second fingerprint after removing only the deliberately changed genomic threshold trait. The external check recomputes first-birth cumulative incidence using `survival::survfit`. Typical commands from the research source root are:

```sh
python3 audit.py FULL_DIRECTORY full prior-runs.csv.gz SELECTED_MAX_AGE
julia --project=inst/julia check-starts.jl FULL_DIRECTORY SELECTED_MAX_AGE 85001 85100
Rscript analyze.R FULL_DIRECTORY/audited SELECTED_MAX_AGE
Rscript plot.R FULL_DIRECTORY/audited
Rscript check-survival.R FULL_DIRECTORY SELECTED_MAX_AGE 85001 85002
```

Seed-level summaries use the source panel as the independent unit. Zero-cohort timing outcomes are recorded as undefined; population outcomes remain included. The selected assay lifespan is a change of world applied equally across treatments, so this study cannot attribute differences from prior worlds solely to avoiding bottlenecks.
