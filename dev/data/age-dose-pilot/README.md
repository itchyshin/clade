# Young-parent reproduction dose-response pilot

See `plan.md` for the pilot design and `findings.md` for results and limits. The source is commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. In an isolated source copy apply, in order, `dev/data/policy-stability/assay-final.patch`, `dev/data/policy-stability/unique-source.patch`, `dev/data/policy-density-factorial/dynamic-density.patch`, and the `repro-gate.patch` and `assay-observer.patch` in `dev/data/age-reproduction-causal/`. Copy this directory's `driver.jl` and `check-sources.jl` to the copy's root. The exact executed source hashes are recorded in `results/raw-data.json`.

The raw individual events, death ledgers, source panels and run records are on Totoro at the path in `results/raw-data.json`, with SHA-256 values in `results/raw.sha256`. The audit takes that full directory and the previous experiment's combined `runs.csv`:

```sh
python3 audit.py FULL_DIRECTORY PRIOR_RUNS_CSV
Rscript analyze.R FULL_DIRECTORY/audited
```

Run `check-sources.jl FULL_DIRECTORY` from the patched source root to validate source-policy distinctness. `results/` contains the audited run, individual, seed and paired-effect summaries. The 71001 rows are the earlier-seed sham replay; seed-level pilot summaries include only 81001 to 81005. The launch paths are Totoro-specific and the launcher refuses to overwrite the existing output directory.
