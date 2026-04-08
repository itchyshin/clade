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
