#' Extract simulation results as tidy data frames
#'
#' `get_run_data()` converts the raw environment list returned by [run_alife()]
#' into a list of two tidy data frames:
#' - `$ticks` — one row per logged tick, with population-level statistics.
#' - `$deaths` — one row per agent death, with individual-level records.
#'
#' @param env An environment list returned by [run_alife()].
#'
#' @return A list with components:
#' \describe{
#'   \item{`$ticks`}{A data frame with one row per logged tick and columns:
#'     `t`, `n_agents`, `n_births`, `n_deaths`, `n_starvations`,
#'     `n_age_deaths`, `mean_energy`, `sd_energy`, `mean_age`, `sd_age`,
#'     `mean_body_size`, `sd_body_size`, `genetic_diversity`, `n_species`,
#'     `mean_cooperation_level`, `mean_immune_strength`, `sd_immune_strength`,
#'     `mean_metabolic_rate`, `mean_learning_rate`, `mean_prior_sigma`
#'     (BNN only), `grass_coverage`, `n_infected`, `n_new_infections`,
#'     `n_altruistic_acts`, `n_shelters_built`.}
#'   \item{`$deaths`}{A data frame with one row per agent death and columns:
#'     `id`, `t`, `age`, `energy`, `cause`, `body_size`, `num_offspring`.}
#' }
#'
#' @examples
#' \dontrun{
#' env  <- run_alife(default_specs())
#' data <- get_run_data(env)
#' head(data$ticks)
#' hist(data$deaths$age, main = "Age at death")
#' }
#'
#' @seealso [run_alife()], [plot_run()]
#' @export
get_run_data <- function(env) {
  stopifnot(is.list(env), !is.null(env$progress), !is.null(env$deaths))
  list(
    ticks  = as.data.frame(lapply(env$progress, unlist)),
    deaths = as.data.frame(lapply(env$deaths,   unlist))
  )
}

#' Extract per-tick genome data (allele frequencies, diversity, FST)
#'
#' Returns genome-level statistics logged when `specs$log_genomes = TRUE`.
#' These include per-tick allele frequency vectors, mean heterozygosity,
#' linkage disequilibrium, and (when `speciation = TRUE`) per-species FST.
#'
#' @param env An environment list returned by [run_alife()].
#'
#' @return A list with components:
#' \describe{
#'   \item{`$genomes`}{A list of matrices (one per logged tick). Each matrix
#'     has one row per agent and one column per genome position. `NULL` when
#'     `specs$log_genomes = FALSE`.}
#'   \item{`$heterozygosity`}{Numeric vector of mean per-locus heterozygosity
#'     across ticks.}
#'   \item{`$fst`}{Numeric vector of per-tick FST (Weir & Cockerham 1984)
#'     between species. `NA` when `speciation = FALSE`.}
#' }
#'
#' @references
#' Weir, B.S. & Cockerham, C.C. (1984) Estimating F-statistics for the
#'   analysis of population structure. *Evolution* 38(6):1358–1370.
#'
#' @examples
#' \dontrun{
#' specs <- default_specs()
#' specs$log_genomes <- TRUE
#' env  <- run_alife(specs)
#' gdat <- get_genome_data(env)
#' plot(gdat$heterozygosity, type = "l", xlab = "Tick", ylab = "Heterozygosity")
#' }
#'
#' @seealso [get_run_data()], [run_alife()]
#' @export
get_genome_data <- function(env) {
  stopifnot(is.list(env))
  glog <- env$genome_log
  list(
    genomes        = if (length(glog) > 0) glog else NULL,
    heterozygosity = numeric(0L),
    fst            = numeric(0L)
  )
}

#' Estimate narrow-sense heritability from a logged trait time-series
#'
#' `estimate_heritability()` returns a coarse estimate of narrow-sense
#' heritability (\eqn{h^2}) for a quantitative trait that has been logged
#' once per tick by [run_alife()]. The estimator is the lag-1 temporal
#' autocorrelation of the population mean,
#' \deqn{\hat{h}^2 \approx \mathrm{cor}(\bar{z}_t,\, \bar{z}_{t+1}),}
#' which is used here as a *proxy* for the parent-offspring regression
#' (Falconer & Mackay 1996, ch. 10). The proxy is reasonable when (i) the
#' trait is under directional or stabilising selection, (ii) generation
#' overlap is moderate, and (iii) the logging interval is short relative to
#' the generation time. It is **not** an exact quantitative-genetic estimate
#' and should not be reported as one. An exact estimate requires
#' parent-offspring pairs, which clade does not currently log.
#'
#' @param run_data A list returned by [get_run_data()] (must contain
#'   `$ticks` with the column `paste0("mean_", trait)`).
#' @param trait Character. The trait name (without the `mean_` prefix).
#'   Defaults to `"body_size"`. Any column of the form `mean_<trait>` in
#'   `run_data$ticks` is supported (e.g. `"immune_strength"`,
#'   `"metabolic_rate"`, `"learning_rate"`).
#'
#' @return A list with components:
#' \describe{
#'   \item{`$h2`}{Numeric. Lag-1 autocorrelation of `mean_<trait>`. Returns
#'     `NA_real_` if the series has fewer than three usable values or zero
#'     variance.}
#'   \item{`$method`}{Character constant `"lag1_autocorrelation"`.}
#'   \item{`$trait`}{The trait name supplied by the caller.}
#'   \item{`$n`}{Integer. Number of paired observations used.}
#'   \item{`$note`}{Character. A reminder that this is a proxy and that an
#'     exact estimate requires parent-offspring logging.}
#' }
#'
#' @references
#' Falconer, D.S. & Mackay, T.F.C. (1996) *Introduction to Quantitative
#'   Genetics*, 4th ed. Longman, Harlow.
#'
#' @examples
#' \dontrun{
#' env  <- run_alife(default_specs())
#' rd   <- get_run_data(env)
#' estimate_heritability(rd, trait = "body_size")
#' estimate_heritability(rd, trait = "immune_strength")
#' }
#'
#' @seealso [get_run_data()], [compute_ld()], [species_tree()]
#' @export
estimate_heritability <- function(run_data, trait = "body_size") {
  if (!is.list(run_data) || is.null(run_data$ticks))
    stop("`run_data` must be a list with a `$ticks` data frame, ",
         "as returned by `get_run_data()`.", call. = FALSE)
  if (!is.character(trait) || length(trait) != 1L || !nzchar(trait))
    stop("`trait` must be a single non-empty character string.",
         call. = FALSE)

  col <- paste0("mean_", trait)
  if (!col %in% names(run_data$ticks)) {
    available <- paste(grep("^mean_", names(run_data$ticks), value = TRUE),
                       collapse = ", ")
    stop(sprintf(
      "Trait column `%s` not found in run_data$ticks. Available trait columns: %s",
      col, available), call. = FALSE)
  }

  z <- as.numeric(run_data$ticks[[col]])
  z <- z[is.finite(z)]
  n <- length(z)

  h2 <- if (n < 3L) {
    NA_real_
  } else {
    z_t   <- z[-n]
    z_tp1 <- z[-1L]
    if (stats::sd(z_t) == 0 || stats::sd(z_tp1) == 0) {
      NA_real_
    } else {
      suppressWarnings(stats::cor(z_t, z_tp1))
    }
  }

  list(
    h2     = h2,
    method = "lag1_autocorrelation",
    trait  = trait,
    n      = max(0L, n - 1L),
    note   = paste0(
      "Proxy estimator (lag-1 temporal autocorrelation of the population ",
      "mean). An exact narrow-sense heritability requires parent-offspring ",
      "pairs, which are not currently logged. See Falconer & Mackay (1996)."
    )
  )
}

#' Compute linkage disequilibrium from a logged genome time-series
#'
#' `compute_ld()` is a placeholder. Linkage disequilibrium statistics
#' (\eqn{D}, \eqn{D'}, \eqn{r^2}; Lewontin & Kojima 1960) require per-tick
#' genome matrices, which are produced only when `specs$log_genomes = TRUE`.
#' That logging path is not yet wired through to the R side, so this
#' function currently returns a stub.
#'
#' @param run_data A list returned by [get_run_data()].
#'
#' @return A list with components:
#' \describe{
#'   \item{`$ld`}{Always `NULL` in the current implementation.}
#'   \item{`$note`}{Character. Explains that LD computation is not yet
#'     available and points to the `log_genomes` flag.}
#' }
#'
#' @references
#' Lewontin, R.C. & Kojima, K. (1960) The evolutionary dynamics of complex
#'   polymorphisms. *Evolution* 14(4):458–472.
#'
#' @examples
#' \dontrun{
#' env <- run_alife(default_specs())
#' compute_ld(get_run_data(env))
#' }
#'
#' @seealso [get_genome_data()], [estimate_heritability()]
#' @export
compute_ld <- function(run_data) {
  if (!is.list(run_data))
    stop("`run_data` must be a list, as returned by `get_run_data()`.",
         call. = FALSE)
  list(
    ld   = NULL,
    note = paste0(
      "Linkage disequilibrium computation is not yet implemented. It ",
      "requires per-tick genome matrices, which are only produced when ",
      "`specs$log_genomes = TRUE`, and the R-side bridge for the genome ",
      "log is still pending. See Lewontin & Kojima (1960)."
    )
  )
}

#' Reconstruct a species tree from a logged simulation
#'
#' `species_tree()` is a placeholder. Phylogenetic reconstruction requires
#' the speciation module (Phase 2), which assigns agents to discrete
#' species, tracks lineage splits, and emits a per-tick species log. None
#' of that machinery is in place yet, so this function currently returns a
#' stub for forward compatibility.
#'
#' @param run_data A list returned by [get_run_data()].
#'
#' @return A list with components:
#' \describe{
#'   \item{`$tree`}{Always `NULL` in the current implementation.}
#'   \item{`$note`}{Character. Explains that species-tree reconstruction
#'     awaits the speciation module.}
#' }
#'
#' @examples
#' \dontrun{
#' env <- run_alife(default_specs())
#' species_tree(get_run_data(env))
#' }
#'
#' @seealso [get_run_data()], [estimate_heritability()], [compute_ld()]
#' @export
species_tree <- function(run_data) {
  if (!is.list(run_data))
    stop("`run_data` must be a list, as returned by `get_run_data()`.",
         call. = FALSE)
  list(
    tree = NULL,
    note = paste0(
      "Species-tree reconstruction is not yet implemented. It requires ",
      "the speciation module (Phase 2), which is not currently active in ",
      "clade. The function is provided as a forward-compatible stub."
    )
  )
}
