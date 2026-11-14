d <- read.csv("dev/data/diversity-vald/verified_results.csv", na.strings = "NA", stringsAsFactors = FALSE)
stopifnot(nrow(d) == 500L, ncol(d) == 22L)
params <- c("move_cost", "grass_max", "min_repro_energy", "energy_init", "mutation_sd")
seeds <- 101:105
pairs <- paste(d$env_id, d$seed, sep = ":")
expected <- as.vector(outer(1:100, seeds, paste, sep = ":"))
cat("rows_cols:", nrow(d), ncol(d), "\n")
cat("env_ids:", length(unique(d$env_id)), range(d$env_id), "seeds:", paste(sort(unique(d$seed)), collapse=","), "\n")
cat("unique_pairs:", length(unique(pairs)), "duplicates:", sum(duplicated(pairs)), "missing_pairs:", length(setdiff(expected, pairs)), "unexpected_pairs:", length(setdiff(pairs, expected)), "\n")
cat("rows_per_env:", paste(range(table(d$env_id)), collapse="-"), "env_parameter_constancy:")
for (v in params) {
  nuniq <- tapply(d[[v]], d$env_id, function(x) length(unique(x)))
  cat("", v, "max_unique=", max(nuniq), sep="")
  stopifnot(all(nuniq == 1L))
}
cat("\nparameter_ranges:\n")
for (v in params) cat(v, paste(range(d[[v]], na.rm=TRUE), collapse=" .. "), "\n")
stopifnot(all(d$move_cost >= 0 & d$move_cost <= 12), all(d$grass_max >= 5 & d$grass_max <= 50),
          all(d$min_repro_energy >= 50 & d$min_repro_energy <= 200),
          all(d$energy_init >= 10 & d$energy_init <= 100), all(d$mutation_sd >= .01 & d$mutation_sd <= .20))

extinct_flag <- tolower(as.character(d$extinct)) == "true"
stopifnot(all(!is.na(extinct_flag)), all(d$final_agents >= 0), all(d$final_agents == floor(d$final_agents)),
          all(extinct_flag == (d$final_agents == 0)))
cat("\nfinal_ticks:", paste(range(d$final_tick), collapse="-"), "at_1000:", sum(d$final_tick == 1000),
    "early_stop:", sum(d$final_tick < 1000), "extinct:", sum(extinct_flag),
    "survivors:", sum(d$final_agents > 0), "one_agent:", sum(d$final_agents == 1),
    "at_least_two:", sum(d$final_agents >= 2), "predators_nonzero:", sum(d$final_predators != 0), "\n")
cat("extinct_by_final_tick_relation:", all((d$final_tick < 1000) == extinct_flag), "\n")

snaps <- c(50, 100, 200, 500, 1000)
for (t in snaps) {
  ac <- d[[paste0("agents_", t)]]
  dv <- d[[paste0("div_", t)]]
  reached <- d$final_tick >= t
  stopifnot(all(!is.na(ac[reached])), all(is.na(ac[!reached])),
            all(!is.na(dv[reached])), all(is.na(dv[!reached])),
            all(ac[reached] >= 0), all(dv[reached] >= 0 & dv[reached] <= 1))
  cat("snapshot", t, "reached", sum(reached), "NA_after_stop", sum(!reached),
      "actual_zero_agents", sum(ac[reached] == 0), "actual_zero_diversity", sum(dv[reached] == 0), "\n")
}
end <- d$final_tick == 1000
stopifnot(all(d$agents_1000[end] == d$final_agents[end]),
          all(abs(d$div_1000[end] - d$final_genetic_diversity[end]) <= 0.00000051),
          all(is.na(d$agents_1000[!end])), all(is.na(d$div_1000[!end])))
cat("endpoint_match_at_1000:", sum(end), "max_diversity_rounding_error:",
    max(abs(d$div_1000[end] - d$final_genetic_diversity[end])), "\n")
cat("final_zero_diversity:", sum(d$final_genetic_diversity == 0),
    "among_extinct:", sum(d$final_genetic_diversity == 0 & extinct_flag),
    "among_survivors:", sum(d$final_genetic_diversity == 0 & !extinct_flag), "\n")

cat("\ncorrelations diversity vs population (associational summaries):\n")
for (t in snaps) {
  a <- d[[paste0("agents_", t)]]; v <- d[[paste0("div_", t)]]
  ok <- !is.na(a) & !is.na(v)
  cat(t, "n=", sum(ok), "Pearson=", cor(a[ok], v[ok]), "Spearman=", cor(a[ok], v[ok], method="spearman"), "\n")
}
surv <- d$final_agents > 0
cat("final among survivors: n=", sum(surv),
    "Pearson=", cor(d$final_agents[surv], d$final_genetic_diversity[surv]),
    "Spearman=", cor(d$final_agents[surv], d$final_genetic_diversity[surv], method="spearman"), "\n")

if (!requireNamespace("lme4", quietly=TRUE)) stop("lme4 unavailable")
for (v in params) d[[paste0(v, "_z")]] <- as.numeric(scale(d[[v]]))
zvars <- paste0(params, "_z")
cat("\npredictor correlation matrix:\n"); print(round(cor(d[zvars]), 3))
cat("predictor correlation kappa:", kappa(cor(d[zvars])), "\n")

capture_fit <- function(expr) {
  warns <- character()
  fit <- withCallingHandlers(expr, warning=function(w) {
    warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning")
  })
  list(fit=fit, warnings=unique(warns))
}
ctrl <- lme4::glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5))
stage1 <- capture_fit(lme4::glmer(
  survived ~ move_cost_z + grass_max_z + min_repro_energy_z + energy_init_z + mutation_sd_z + factor(seed) + (1 | env_id),
  data=transform(d, survived=as.integer(!extinct_flag)), family=binomial, control=ctrl))
cat("\nstage1 model (scaled predictor estimates, SE, approximate Wald 95% CI, and OR):\n")
c1 <- coef(summary(stage1$fit))[zvars, , drop=FALSE]
print(cbind(estimate=c1[,"Estimate"], SE=c1[,"Std. Error"],
            lower=c1[,"Estimate"]-1.96*c1[,"Std. Error"],
            upper=c1[,"Estimate"]+1.96*c1[,"Std. Error"],
            OR=exp(c1[,"Estimate"]), OR_lower=exp(c1[,"Estimate"]-1.96*c1[,"Std. Error"]),
            OR_upper=exp(c1[,"Estimate"]+1.96*c1[,"Std. Error"])))
cat("stage1 converged_messages:", paste(stage1$fit@optinfo$conv$lme4$messages, collapse=" | "),
    "singular:", lme4::isSingular(stage1$fit), "random_variance:",
    as.data.frame(lme4::VarCorr(stage1$fit))$vcov[1], "captured_warnings:", paste(stage1$warnings, collapse=" | "), "\n")

s2 <- d[d$final_agents >= 2, ]
for (v in params) s2[[paste0(v, "_z")]] <- as.numeric(scale(s2[[v]]))
s2$log_final_agents_z <- as.numeric(scale(log(s2$final_agents)))
stage2 <- capture_fit(lme4::lmer(
  final_genetic_diversity ~ move_cost_z + grass_max_z + min_repro_energy_z + energy_init_z + mutation_sd_z + log_final_agents_z + factor(seed) + (1 | env_id),
  data=s2, REML=TRUE))
cat("\nstage2 n:", nrow(s2), "outcome_mean_sd:", mean(s2$final_genetic_diversity), sd(s2$final_genetic_diversity),
    "zero_one_counts:", sum(s2$final_genetic_diversity == 0), sum(s2$final_genetic_diversity == 1), "\n")
cat("stage2 model (scaled predictor estimates, SE, approximate Wald 95% CI):\n")
c2 <- coef(summary(stage2$fit))[c(zvars, "log_final_agents_z"), , drop=FALSE]
print(cbind(estimate=c2[,"Estimate"], SE=c2[,"Std. Error"],
            lower=c2[,"Estimate"]-1.96*c2[,"Std. Error"],
            upper=c2[,"Estimate"]+1.96*c2[,"Std. Error"]))
cat("stage2 predictor correlation kappa:", kappa(cor(s2[zvars])), "\n")
r2 <- residuals(stage2$fit)
cat("stage2 residual quantiles:", paste(round(quantile(r2, c(0,.05,.25,.5,.75,.95,1)), 3), collapse=", "),
    "resid_fitted_cor:", cor(r2, fitted(stage2$fit)),
    "normal_qq_correlation:", cor(sort(r2), qnorm(ppoints(length(r2)))),
    "fitted_range:", paste(round(range(fitted(stage2$fit)), 3), collapse=" .. "), "\n")
cat("stage2 converged_messages:", paste(stage2$fit@optinfo$conv$lme4$messages, collapse=" | "),
    "singular:", lme4::isSingular(stage2$fit), "random_variance:",
    as.data.frame(lme4::VarCorr(stage2$fit))$vcov[1], "captured_warnings:", paste(stage2$warnings, collapse=" | "), "\n")
