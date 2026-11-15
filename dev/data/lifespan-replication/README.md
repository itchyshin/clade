# Independent lifespan replication

The prespecified design and validation gates are in `plan.md`; see `findings.md` for the results. This experiment reuses the exact research driver and isolated patches recorded in `dev/data/stable-food-threshold/README.md`, with assay maximum age 400. Source training remains at age 200. The two 100-seed result groups are a matched repeat of the earlier source blocks and a separate new-source replication.

Raw source panels, individual cohorts, death records and validation opportunity events are archived on Totoro at the location in `results/raw-data.json`. The study-specific scripts provide replay, stability and cohort audits; source-panel and normalized-start checks reuse `dev/data/stable-food-threshold/check-starts.jl` and `dev/data/stable-time-birth/check-sources.jl`. The previous source run table and seed-summary table are required to check and analyze the direct lifespan pairing.

```sh
python3 audit.py FULL_DIRECTORY full unused 400
python3 check-paired.py FULL_DIRECTORY/audited/400-runs.csv PRIOR_RUNS_CSV_GZ FULL_DIRECTORY PRIOR_FULL_DIRECTORY
Rscript analyze.R FULL_DIRECTORY/audited 400 paired
Rscript analyze.R FULL_DIRECTORY/audited 400 fresh
Rscript compare.R FULL_DIRECTORY/audited PRIOR_SEED_SUMMARY_CSV
```

The parent-age categories are the same as in the earlier study. In the 400-tick setting, the 150-or-older category additionally includes parents aged 300–399. Cohorts conditional on young eligibility are post-treatment selected, and the new-source replication is distinct from the seed-matched comparison.
