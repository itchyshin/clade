# Stable-world reproductive timing

The design and analysis are in `plan.md`; results and limits are in `findings.md`. The simulation kernel comes from commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6` with the isolated patches listed in `dev/data/age-dose-pilot/README.md`. Copy `driver.jl` and `check-sources.jl` to that patched source root. The launcher and archived data paths are specific to Totoro.

The archived seed directories contain `source.csv`, serialized source policies, run totals, individual cohort records, death ledgers and, for the pilot, every gate opportunity. The audit uses the prior stable-world compressed runs for a 36-run sham replay:

```sh
python3 audit.py RESULTS_DIRECTORY pilot PRIOR_RUNS_CSV_GZ
python3 audit.py RESULTS_DIRECTORY full PRIOR_RUNS_CSV_GZ
Rscript analyze.R RESULTS_DIRECTORY/audited
Rscript plot.R RESULTS_DIRECTORY/audited
Rscript check-survival.R PILOT_DIRECTORY
```

The Python audit reconstructs pilot cohorts independently from individual event records and checks gate decisions, conservation and start-state matching. Its competing-risk calculations were also checked against `survival::survfit`. The final directory retains every source and run outcome, including weak, bottlenecked or extinct populations. Full data location and hashes are recorded in `results/`.
