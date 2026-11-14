# Stable policy-mixture experiment

See `plan.md` for the prespecified screens, documented revisions and independent final seed set, and `findings.md` for results and limits. The simulation source is commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. In an isolated source copy, apply `assay-final.patch` and `unique-source.patch`, then copy `driver-headroom.jl` as `driver.jl` and `launch.py` to the source root. The launcher records Totoro paths and resource limits. Other driver and patch files reproduce the earlier diagnostic screens.

For the final analysis, decompress `results/runs.csv.gz` and `results/windows.csv.gz` and copy `results/sources.csv` into a working directory. From the repository root run:

```sh
Rscript dev/data/policy-stability/analyze.R WORKDIR
python3 dev/data/policy-stability/audit.py WORKDIR
Rscript dev/data/policy-stability/stability.R WORKDIR
Rscript dev/data/policy-stability/plot.R WORKDIR
```

Population minima and cap counts are observed every tick; endpoint viability is a separate package verdict. Founder-policy state files remain in the Totoro archive and are indexed by their SHA-256 manifest.

The pilot directories contain compressed `sources`, `runs` and `windows` tables. Decompress a pilot into a working directory and reproduce its decision with `python3 dev/data/policy-stability/screen.py WORKDIR THRESHOLDS INITIAL_N SOURCE_VIABLE_FRACTION ASSAY_VIABLE_FRACTION`. The gate arguments for each screen are recorded in its `audit.txt` and in `plan.md`; the earlier screening designs did not impose the later endpoint-viability gate. The final source cells use the separate placement RNG shown in `unique-source.patch`.
