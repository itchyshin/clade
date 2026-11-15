# Age-specific reproduction interventions

See `plan.md` for the prespecified factorial and `findings.md` for the results and limits. The simulation source is commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. In an isolated source copy, apply the earlier research patches `dev/data/policy-stability/assay-final.patch`, `dev/data/policy-stability/unique-source.patch` and `dev/data/policy-density-factorial/dynamic-density.patch`, followed by `repro-gate.patch` and `assay-observer.patch` from this directory. Copy `driver.jl` and `launch.py` into the source root. The gate does not consume the simulation RNG. Execution receipts and source-file hashes identify the exact run.

The full raw 50-tick tables and source states are archived on Totoro; their paths and SHA-256 hashes are in `results/raw-data.json` and the state manifest. The tracked aggregate blocks and summaries support inspection. Copy and decompress `runs.csv`, `sources.csv` and `windows.csv` to a working directory to recompute:

```sh
python3 dev/data/age-reproduction-causal/reduce.py WORKDIR
Rscript dev/data/age-reproduction-causal/analyze.R WORKDIR
Rscript dev/data/age-reproduction-causal/gate-birth-effects.R WORKDIR
Rscript dev/data/age-reproduction-causal/multiplicity.R WORKDIR
python3 dev/data/age-reproduction-causal/audit.py WORKDIR
Rscript dev/data/age-reproduction-causal/plot.R WORKDIR
```

The gate blocks approximately half of energy-, age- and cap-eligible opportunities in the targeted band before local-space, mate and reproductive-cost checks. The recorded opportunity is not necessarily a birth that would otherwise have occurred. Parents whose opportunity is blocked retain the associated potential cost. Gate-specific viability and bottlenecks are outcomes; no run is filtered from the primary contrasts.
