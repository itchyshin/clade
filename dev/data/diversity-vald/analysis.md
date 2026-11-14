# Exploratory review of the verified rerun

> **Kernel qualification, 14 November 2026.** These results describe a
> pinned legacy implementation that limited each agent to one focal
> reproductive episode in its lifetime, including the default iteroparous
> mode. Mate contributions were not restricted by that flag. The numbers
> remain historical source-bound results and require rerunning before
> interpreting the corrected iteroparous model. See the
> [reproduction reset report](../../dev-log/after-task/2026-11-14-iteroparous-reset.md).

The 500 runs comprise 100 sampled environments with five seeds each.
There are 309 survivors and 191 extinctions. Four survivors have one agent,
so the conditional diversity model uses 305 runs with at least two agents.
The zero convention for extinction and singletons is kept out of that model.

`Rscript dev/data/diversity-vald/analyze_verified.R` reproduces the data
checks and two models from the repository root (requires lme4; review used
version 2.0.1). Captured output is in `analysis-output.txt`.

## Models and reported scale

Stage one is a binomial model of survival with an environment random
intercept. Stage two models raw genetic diversity among surviving runs
with at least two agents, also with an environment random intercept.
Both include the five sampled environmental parameters and seed as a fixed
factor. Stage two also includes log(final_agents). Continuous predictors
are standardised within each model's dataset; the scales therefore differ
between stages. Intervals below are approximate Wald 95% intervals.

| Stage and predictor | Estimate per predictor SD | Approximate 95% interval |
| --- | ---: | ---: |
| Survival log odds: move_cost | -3.698 | -5.159 to -2.238 |
| Survival log odds: min_repro_energy | 3.371 | 2.018 to 4.724 |
| Conditional diversity: mutation_sd | 0.1424 | 0.1260 to 0.1588 |
| Conditional diversity: log(final_agents) | 0.1241 | 0.1024 to 0.1458 |

Both models converged without warnings and were nonsingular. The corrected
reproduction parameter is associated with survival in this sampled design;
the original legacy column was an unused key. Among surviving populations,
mutation and final population size are associated with genetic diversity.
These associations do not establish a general environmental optimum.

## Limits of interpretation

The genetic metric is the mean of sampled root-mean-square distances between
expressed genome weight vectors. It is nonnegative, without a fixed upper
bound of one. The Gaussian model predicts a small negative value at its
minimum (-0.029), and residuals are asymmetric. Treat its coefficients as
exploratory. Survivor selection and adjustment for final population size
also prevent interpreting the conditional environmental coefficients as
causal effects beyond demography. The five fixed seeds are a small set of
shared random-number conditions.

The new distinct-pair estimator changes random draws and trajectories.
Comparing old and new files therefore does not isolate a measurement-only
correction. Neither this study nor the implementation tests establish
biological calibration or reproduce a published prediction.
