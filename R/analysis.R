#' Extract simulation results as tidy data frames
#'
#' `get_run_data()` converts the raw environment list returned by [run_alife()]
#' into a list of two tidy data frames:
#' - `$ticks` -- one row per logged tick, with population-level statistics.
#' - `$deaths` -- one row per agent death, with individual-level records.
#'
#' @param env An environment list returned by [run_alife()].
#'
#' @return A list with components:
#' \describe{
#'   \item{`$ticks`}{A data frame with one row per logged tick and ~60
#'     population-level columns. Core columns always present: `t`,
#'     `n_agents`, `n_births`, `n_deaths`, `n_starvations`,
#'     `n_age_deaths`, `mean_energy`, `sd_energy`, `mean_age`, `sd_age`,
#'     `mean_body_size`, `sd_body_size`, `genetic_diversity`, `n_species`,
#'     `grass_coverage`. Module-specific columns are present as zeros
#'     when the corresponding module is disabled (so the data frame
#'     shape is stable across specs), including
#'     `mean_cooperation_level`, `mean_immune_strength`, `sd_immune_strength`,
#'     `mean_metabolic_rate`, `mean_learning_rate`, `mean_prior_sigma`
#'     (BNN only), `n_infected`, `n_new_infections`, `n_altruistic_acts`,
#'     `n_shelters_built`, `n_predators`, `n_prey_killed`, `n_juveniles`,
#'     `n_helpers`, `mean_signal_magnitude`, `mean_preference_magnitude`,
#'     `mean_signal_preference_dist`, `sd_signal_magnitude`,
#'     `mean_toxicity`, `mean_plasticity`, `mean_helper_tendency`,
#'     `mean_habitat_preference`, `mean_brain_size`, `n_ground_agents`,
#'     `n_shrub_agents`, `n_canopy_agents`, `mean_wing_size`,
#'     `n_front_agents`, `mean_front_dispersal`, `n_iffolk_transfers`,
#'     `mean_relatedness`, `n_scavenge_events`, `n_gd_events`,
#'     `mean_shelter_depth`, `mean_mutation_rate`, `mean_clutch_size`,
#'     `mean_ann_weight_magnitude`. The authoritative full list is in
#'     `inst/julia/src/logging.jl::_init_progress`; use
#'     `colnames(get_run_data(env)$ticks)` to see every column for a
#'     specific run.}
#'   \item{`$deaths`}{A data frame with one row per agent death and columns:
#'     `id`, `t`, `age`, `energy`, `cause`, `body_size`, `num_offspring`.}
#'   \item{`$genomes`}{A long data frame with one row per (tick, agent) and
#'     columns `t`, `agent_id`, `trait_1`..`trait_N`. `NULL` unless
#'     `specs$log_genomes = TRUE` was set for the run. Consumed by
#'     [plot_tsne_genomes()].}
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
    ticks   = as.data.frame(lapply(env$progress, unlist)),
    deaths  = as.data.frame(lapply(env$deaths,   unlist)),
    # Optional: present iff specs$log_genomes was TRUE during the run.
    # NULL when log_genomes was off, matching plot_tsne_genomes()'s guard.
    genomes = .compose_genome_dataframe(env$genome_log)
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
#'   \item{`$genomes`}{A long data frame with one row per (tick, agent),
#'     columns `t`, `agent_id`, and `trait_1`..`trait_N` (N = number of
#'     scalar traits in the Julia kernel, currently 22). `NULL` when
#'     `specs$log_genomes = FALSE` or no snapshots were taken.}
#'   \item{`$heterozygosity`}{Reserved field — currently returns
#'     `numeric(0L)`. Future versions will compute mean per-locus
#'     heterozygosity across logged ticks.}
#'   \item{`$fst`}{Reserved field — currently returns `numeric(0L)`.
#'     Future versions will compute per-tick FST (Weir & Cockerham 1984)
#'     between species when `speciation = TRUE`.}
#' }
#'
#' @references
#' Weir, B.S. & Cockerham, C.C. (1984) Estimating F-statistics for the
#'   analysis of population structure. *Evolution* 38(6):1358-1370.
#'
#' @examples
#' \dontrun{
#' specs <- default_specs()
#' specs$log_genomes <- TRUE
#' env  <- run_alife(specs)
#' gdat <- get_genome_data(env)
#' head(gdat$genomes)   # tidy data.frame: t, agent_id, trait_1..trait_N
#' }
#'
#' @seealso [get_run_data()], [run_alife()]
#' @export
get_genome_data <- function(env) {
  stopifnot(is.list(env))
  glog <- env$genome_log
  list(
    genomes        = .compose_genome_dataframe(glog),
    heterozygosity = numeric(0L),
    fst            = numeric(0L)
  )
}

# Internal: convert env$genome_log (a JuliaArrayProxy of per-tick Dicts)
# into a single long data.frame with cols (t, agent_id, trait_1..trait_N).
# Returns NULL when no snapshots were taken or Julia isn't running.
.compose_genome_dataframe <- function(glog) {
  if (is.null(glog) || length(glog) == 0L) return(NULL)
  # JuliaConnectoR returns Julia Dicts as JuliaStructProxy objects whose
  # native conversion (juliaGet) yields a list with $keys and $values.
  # Convert each entry to a named list keyed by field name.
  .unpack <- function(entry) {
    g <- tryCatch(JuliaConnectoR::juliaGet(entry), error = function(e) NULL)
    if (is.null(g) || is.null(g$keys) || is.null(g$values)) return(NULL)
    nm <- unlist(g$keys, use.names = FALSE)
    setNames(g$values, nm)
  }
  # `glog` is a JuliaArrayProxy; iterate via [[i]] (lapply/as.list both
  # try to coerce the proxy to a list and fail).
  per_tick <- vector("list", length(glog))
  for (i in seq_along(glog)) {
    e <- .unpack(glog[[i]])
    if (is.null(e)) next
    mat <- e$traits
    if (is.null(mat) || !is.matrix(mat) || nrow(mat) == 0L) next
    df  <- as.data.frame(mat)
    colnames(df) <- paste0("trait_", seq_len(ncol(mat)))
    df$t        <- as.integer(e$t)
    df$agent_id <- as.integer(e$agent_ids)
    per_tick[[i]] <- df[, c("t", "agent_id", paste0("trait_", seq_len(ncol(mat))))]
  }
  per_tick <- Filter(Negate(is.null), per_tick)
  if (length(per_tick) == 0L) return(NULL)
  do.call(rbind, per_tick)
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
#' Note that clade also exports [heritability_estimate()] — a different
#' function that computes h^2 by parent-offspring regression on
#' `get_run_data(env)$deaths` (the agent-death log), and so requires that
#' agents have died with recorded `parent_id` and the trait of interest.
#' `estimate_heritability()` is the population-level autocorrelation proxy
#' (works on any logged trait series); `heritability_estimate()` is the
#' individual-level regression (requires the deaths data frame).
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
#' @seealso [heritability_estimate()] for the parent-offspring regression
#'   approach. [get_run_data()], [compute_ld()], [species_tree()].
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
#'   polymorphisms. *Evolution* 14(4):458-472.
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

#' Inspect the brain structure of a single agent
#'
#' `inspect_brain()` extracts structural and statistical information from the
#' brain of a named agent in `env$agents`. It supports both ANN brains
#' (layers with `$W` and `$b`) and BNN brains (layers with `$mu` and
#' `$sigma`). When the brain structure is unavailable it returns a minimal
#' list with a note.
#'
#' @param env An environment list returned by [run_clade()].
#' @param agent_id Integer. The `$id` field of the agent to inspect.
#'   Defaults to `1L`.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{`$brain_type`}{Character. Value of `env$specs$brain_type`.}
#'   \item{`$n_layers`}{Integer. Number of layers in `brain$layers`.}
#'   \item{`$layer_sizes`}{List of integer vectors `c(nrow, ncol)` for each
#'     layer weight matrix.}
#'   \item{`$n_weights`}{Integer. Total number of weight values across all
#'     layers.}
#'   \item{`$weight_mean`}{Numeric. Mean of all weights.}
#'   \item{`$weight_sd`}{Numeric. Standard deviation of all weights.}
#'   \item{`$weight_min`}{Numeric. Minimum weight value.}
#'   \item{`$weight_max`}{Numeric. Maximum weight value.}
#'   \item{`$sigma_mean`, `$sigma_sd`, `$sigma_min`, `$sigma_max`}{Numeric.
#'     Statistics for the `$sigma` matrices (BNN brains only).}
#'   \item{`$note`}{Character. Present only when `brain$layers` is
#'     unavailable; explains why summary statistics are absent.}
#' }
#'
#' @examples
#' \dontrun{
#' env <- run_clade(default_specs())
#' inspect_brain(env, agent_id = 1L)
#' }
#'
#' @seealso [get_brain_weights()], [run_clade()]
#' @export
inspect_brain <- function(env, agent_id = 1L) {
  stopifnot(is.list(env), !is.null(env$agents))

  # Locate agent by $id
  idx <- NULL
  for (i in seq_along(env$agents)) {
    ag <- env$agents[[i]]
    if (!is.null(ag$id) && identical(as.integer(ag$id), as.integer(agent_id))) {
      idx <- i
      break
    }
  }
  if (is.null(idx))
    stop(sprintf("No agent with id = %d found in env$agents.", agent_id),
         call. = FALSE)

  brain_type <- env$specs$brain_type
  brain      <- env$agents[[idx]]$brain

  # Guard: brain$layers missing or NULL
  if (is.null(brain) || is.null(brain$layers) || length(brain$layers) == 0L) {
    return(list(
      brain_type = brain_type,
      note       = "brain$layers is NULL or empty; structural summary unavailable."
    ))
  }

  layers <- brain$layers
  is_bnn <- identical(brain_type, "bnn")

  # Weight matrix accessor: $W for ANN/CTRNN/GRN, $mu for BNN
  w_key <- if (is_bnn) "mu" else "W"

  layer_sizes <- lapply(layers, function(l) {
    W <- l[[w_key]]
    if (is.null(W)) return(c(NA_integer_, NA_integer_))
    c(nrow(W), ncol(W))
  })

  all_weights <- unlist(lapply(layers, function(l) as.numeric(l[[w_key]])))
  n_weights   <- length(all_weights)

  out <- list(
    brain_type  = brain_type,
    n_layers    = length(layers),
    layer_sizes = layer_sizes,
    n_weights   = n_weights,
    weight_mean = mean(all_weights),
    weight_sd   = stats::sd(all_weights),
    weight_min  = min(all_weights),
    weight_max  = max(all_weights)
  )

  # BNN: add sigma statistics
  if (is_bnn) {
    all_sigma <- unlist(lapply(layers, function(l) as.numeric(l$sigma)))
    out$sigma_mean <- mean(all_sigma)
    out$sigma_sd   <- stats::sd(all_sigma)
    out$sigma_min  <- min(all_sigma)
    out$sigma_max  <- max(all_sigma)
  }

  out
}

#' Extract weight values from an agent's brain
#'
#' `get_brain_weights()` returns either all weights concatenated across layers
#' (when `layer = NULL`) or the weight matrix for a single specified layer.
#' For ANN brains the weight matrix is `$W`; for BNN brains it is `$mu`.
#'
#' @param env An environment list returned by [run_clade()].
#' @param agent_id Integer. The `$id` field of the agent. Defaults to `1L`.
#' @param layer Integer or NULL. If `NULL` (default), all weights are returned
#'   as a named numeric vector. If an integer, the weight matrix for that layer
#'   index is returned.
#'
#' @return A named numeric vector (when `layer = NULL`) or a numeric matrix
#'   (when `layer` is specified).
#'
#' @examples
#' \dontrun{
#' env <- run_clade(default_specs())
#' get_brain_weights(env, agent_id = 1L)           # all weights
#' get_brain_weights(env, agent_id = 1L, layer = 1L) # layer-1 matrix
#' }
#'
#' @seealso [inspect_brain()], [run_clade()]
#' @export
get_brain_weights <- function(env, agent_id = 1L, layer = NULL) {
  stopifnot(is.list(env), !is.null(env$agents))

  # Locate agent by $id
  idx <- NULL
  for (i in seq_along(env$agents)) {
    ag <- env$agents[[i]]
    if (!is.null(ag$id) && identical(as.integer(ag$id), as.integer(agent_id))) {
      idx <- i
      break
    }
  }
  if (is.null(idx))
    stop(sprintf("No agent with id = %d found in env$agents.", agent_id),
         call. = FALSE)

  brain      <- env$agents[[idx]]$brain
  brain_type <- env$specs$brain_type
  is_bnn     <- identical(brain_type, "bnn")
  w_key      <- if (is_bnn) "mu" else "W"

  if (is.null(brain) || is.null(brain$layers) || length(brain$layers) == 0L)
    stop(sprintf("Agent %d has no brain$layers.", agent_id), call. = FALSE)

  if (is.null(layer)) {
    # Return all weights as a named numeric vector
    unlist(lapply(seq_along(brain$layers), function(i) {
      w <- as.numeric(brain$layers[[i]][[w_key]])
      stats::setNames(w, paste0("L", i, "_", seq_along(w)))
    }))
  } else {
    layer <- as.integer(layer)
    if (layer < 1L || layer > length(brain$layers))
      stop(sprintf("`layer` = %d is out of range (brain has %d layers).",
                   layer, length(brain$layers)), call. = FALSE)
    W <- brain$layers[[layer]][[w_key]]
    if (is.null(W))
      stop(sprintf("Layer %d has no `%s` matrix.", layer, w_key), call. = FALSE)
    as.matrix(W)
  }
}

#' Reconstruct a species tree from a logged simulation
#'
#' `species_tree()` is a placeholder. The speciation module
#' (`specs$speciation = TRUE`) assigns agents to clusters each tick and
#' logs a cluster count, but doesn't retain the pairwise genetic
#' distances or lineage-split history needed for phylogenetic
#' reconstruction. None of that extended machinery is in place yet, so
#' this function currently returns a stub for forward compatibility.
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
      "Species-tree reconstruction is not yet implemented. The speciation ",
      "module (`specs$speciation = TRUE`) produces a cluster count per tick ",
      "(`n_species`) but does not retain pairwise genetic distances or ",
      "parentage needed for a phylogenetic tree. `species_tree()` is a ",
      "forward-compatible stub; build trees from `$agents$parent_id` + ",
      "`compute_relatedness()` manually if needed."
    )
  )
}

# ── compare_conditions() ──────────────────────────────────────────────────────

#' Compare evolutionary outcomes across simulation conditions
#'
#' @title Compare evolutionary outcomes across simulation conditions
#' @description
#' Takes a named list of `run_data` objects (one per condition) and computes
#' post-burn-in means and standard deviations for key outcome metrics. Returns
#' a tidy data frame for downstream analysis or plotting.
#'
#' Metrics included (when present in all runs):
#' `n_agents`, `genetic_diversity`, `mean_energy`, `n_births`, `n_deaths`,
#' `grass_coverage`, `n_species`, `mean_body_size`, `mean_toxicity`,
#' `mean_plasticity`, `n_predators`.
#'
#' @param conditions A named list of `run_data` objects, each from
#'   [get_run_data()]. Names are used as condition labels.
#' @param burn_in Integer. Ticks to discard as burn-in (default `100L`).
#' @param plot Logical. If `TRUE`, returns a ggplot2 bar-chart comparison.
#'   If `FALSE`, returns only the summary data frame.
#'
#' @return A data frame with one row per condition and columns `condition`,
#'   then mean and SD columns for each outcome metric (e.g. `genetic_diversity`,
#'   `genetic_diversity_sd`). If `plot = TRUE`, a `$plot` attribute is also
#'   attached.
#'
#' @examples
#' \dontrun{
#' s1 <- default_specs(); s1$mutation_sd <- 0.05
#' s2 <- default_specs(); s2$mutation_sd <- 0.30
#' env1 <- run_alife(s1); env2 <- run_alife(s2)
#' result <- compare_conditions(list(low_mut = get_run_data(env1),
#'                                   hi_mut  = get_run_data(env2)))
#' result
#' }
#'
#' @seealso [get_run_data()], [estimate_heritability()], [run_alife()]
#' @export
compare_conditions <- function(conditions, burn_in = 100L, plot = TRUE) {
  if (!is.list(conditions) || is.null(names(conditions)))
    stop("`conditions` must be a named list of run_data objects.", call. = FALSE)

  core_metrics <- c("n_agents", "genetic_diversity", "mean_energy",
                     "n_births", "n_deaths", "grass_coverage")
  opt_metrics  <- c("n_species", "mean_body_size", "mean_toxicity",
                     "mean_plasticity", "mean_helper_tendency",
                     "n_predators", "mean_signal_magnitude",
                     "mean_prior_sigma")

  rows <- lapply(names(conditions), function(cond) {
    rd <- conditions[[cond]]
    if (!is.list(rd) || is.null(rd$ticks))
      stop(sprintf("conditions[['%s']] is not a valid run_data list.", cond),
           call. = FALSE)
    d   <- rd$ticks
    d   <- d[d$t > burn_in, , drop = FALSE]

    present <- c(core_metrics,
                 intersect(opt_metrics, names(d)))
    means <- vapply(present, function(m)
      mean(d[[m]], na.rm = TRUE), numeric(1L))
    sds   <- vapply(present, function(m) {
      v <- d[[m]]
      if (sum(!is.na(v)) >= 2L) stats::sd(v, na.rm = TRUE) else NA_real_
    }, numeric(1L))

    out           <- as.data.frame(as.list(means))
    names(out)    <- present
    sd_df         <- as.data.frame(as.list(sds))
    names(sd_df)  <- paste0(present, "_sd")
    cbind(data.frame(condition = cond, stringsAsFactors = FALSE), out, sd_df)
  })
  result <- do.call(rbind, rows)

  if (isTRUE(plot) && requireNamespace("ggplot2", quietly = TRUE)) {
    plot_cols <- intersect(c("genetic_diversity", "mean_energy", "n_agents",
                              "n_species"), names(result))
    if (length(plot_cols) > 0L) {
      long <- do.call(rbind, lapply(plot_cols, function(m) {
        data.frame(
          condition = result$condition,
          metric    = m,
          mean      = result[[m]],
          sd        = result[[paste0(m, "_sd")]],
          stringsAsFactors = FALSE
        )
      }))
      p <- ggplot2::ggplot(
        long,
        ggplot2::aes(x = .data$condition, y = .data$mean, fill = .data$condition)
      ) +
        ggplot2::geom_col(show.legend = FALSE) +
        ggplot2::geom_errorbar(
          ggplot2::aes(ymin = .data$mean - .data$sd,
                       ymax = .data$mean + .data$sd),
          width = 0.25
        ) +
        ggplot2::facet_wrap(~ metric, scales = "free_y") +
        ggplot2::labs(x = "Condition", y = "Mean (post burn-in)") +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
      attr(result, "plot") <- p
    }
  }
  result
}

# ── load_specs() ──────────────────────────────────────────────────────────────

#' Load simulation specs from a JSON file
#'
#' @title Load simulation specs from a JSON file
#' @description
#' Reads a JSON file containing simulation parameters and merges it over the
#' defaults from [default_specs()]. Parameters not present in the JSON file
#' retain their defaults; parameters in the JSON that are not valid spec names
#' trigger a warning.
#'
#' @param path Character. Path to a JSON file. The file should contain a
#'   single JSON object whose keys are parameter names from [default_specs()].
#'   Numeric vectors of length 1 are read as scalars; longer vectors as
#'   R vectors.
#'
#' @return A specs list (same format as [default_specs()]).
#'
#' @examples
#' \dontrun{
#' # specs.json contains {"mutation_sd": 0.3, "grass_rate": 0.6}
#' specs <- load_specs("path/to/specs.json")
#' env   <- run_alife(specs)
#' }
#'
#' @seealso [default_specs()], [run_alife()]
#' @export
load_specs <- function(path) {
  if (!file.exists(path))
    stop(sprintf("File not found: '%s'", path), call. = FALSE)
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("Package 'jsonlite' is required for load_specs(). ",
         "Install it with: install.packages('jsonlite')", call. = FALSE)

  raw    <- jsonlite::read_json(path, simplifyVector = TRUE)
  specs  <- default_specs()
  known  <- names(specs)

  unknown <- setdiff(names(raw), known)
  if (length(unknown) > 0L)
    warning(sprintf(
      "load_specs(): ignoring unknown parameter(s): %s",
      paste(sprintf("'%s'", unknown), collapse = ", ")
    ), call. = FALSE)

  for (nm in intersect(names(raw), known)) {
    val <- raw[[nm]]
    # Preserve integer type when the default is integer
    if (is.integer(specs[[nm]]) && is.numeric(val))
      val <- as.integer(val)
    specs[[nm]] <- val
  }
  specs
}

#' Estimate narrow-sense heritability from parent-offspring data
#'
#' `heritability_estimate()` computes h2 by regressing offspring trait values
#' on parent trait values using the `$deaths` data frame returned by
#' [get_run_data()]. This is the parent-offspring regression method, as
#' distinct from the lag-1 autocorrelation approach used by
#' [estimate_heritability()].
#'
#' The deaths data frame must contain `parent_id` and the requested `trait`
#' column. Run the simulation long enough that agents die and are recorded.
#'
#' @param data A list from [get_run_data()], specifically using `data$deaths`.
#' @param trait Character; column name in `data$deaths` to use as the trait.
#'   Default `"num_offspring"`.
#'
#' @return A list with:
#' \describe{
#'   \item{`$h2`}{Estimated heritability (slope of parent-offspring regression).
#'     `NA` when fewer than 5 matched pairs are found.}
#'   \item{`$n_pairs`}{Number of matched parent-offspring pairs.}
#'   \item{`$method`}{`"parent_offspring_regression"`.}
#'   \item{`$trait`}{The trait used.}
#' }
#'
#' @seealso [estimate_heritability()] for the lag-1 autocorrelation approach.
#' @examples
#' \dontrun{
#' env  <- run_alife(default_specs())
#' data <- get_run_data(env)
#' h    <- heritability_estimate(data, trait = "num_offspring")
#' h$h2
#' }
#' @export
heritability_estimate <- function(data, trait = "num_offspring") {
  d <- data$deaths
  if (!is.data.frame(d) || nrow(d) == 0L)
    stop("'data$deaths' is empty. Run a longer simulation so agents die.",
         call. = FALSE)
  if (!trait %in% names(d))
    stop(sprintf("Trait '%s' not found in data$deaths. Available: %s",
                 trait, paste(names(d), collapse = ", ")),
         call. = FALSE)
  if (!"parent_id" %in% names(d))
    stop("'data$deaths' has no 'parent_id' column.", call. = FALSE)

  offspring <- d[!is.na(d$parent_id), c("id", "parent_id", trait)]
  parents   <- d[, c("id", trait)]
  names(parents) <- c("parent_id", "parent_trait")
  pairs     <- merge(offspring, parents, by = "parent_id", all.x = FALSE)
  pairs     <- pairs[!is.na(pairs[[trait]]) & !is.na(pairs$parent_trait), ]

  n_pairs <- nrow(pairs)
  if (n_pairs < 5L) {
    message(sprintf(
      "heritability_estimate(): only %d matched parent-offspring pairs; h2 = NA.",
      n_pairs
    ))
    return(list(h2 = NA_real_, n_pairs = n_pairs,
                method = "parent_offspring_regression", trait = trait))
  }

  fit <- stats::lm(pairs[[trait]] ~ pairs$parent_trait)
  h2  <- unname(stats::coef(fit)[2L])
  list(h2 = h2, n_pairs = n_pairs,
       method = "parent_offspring_regression", trait = trait)
}

#' Compute normalised Euclidean genome distance between two agents
#'
#' `genome_distance()` quantifies how different two agents are by computing the
#' normalised Euclidean distance between their flattened brain weight vectors.
#' For BNN brains, the `mu` (mean) weights are used; for all other brain types,
#' the `W` weight matrices are used.
#'
#' @param agent_a,agent_b Agent lists from `env$agents`. Each must have a
#'   `$brain$layers` component.
#'
#' @return A non-negative numeric scalar. Zero means the two brains are
#'   identical; values near 1 indicate substantial divergence.
#'
#' @examples
#' \dontrun{
#' env <- run_alife(default_specs())
#' if (length(env$agents) >= 2L)
#'   genome_distance(env$agents[[1]], env$agents[[2]])
#' }
#' @export
genome_distance <- function(agent_a, agent_b) {
  .flatten_brain <- function(ag, w_key) {
    if (is.null(ag$brain) || is.null(ag$brain$layers)) return(numeric(0))
    unlist(lapply(ag$brain$layers, function(l) as.numeric(l[[w_key]])))
  }

  is_bnn <- function(ag) {
    !is.null(ag$brain) && !is.null(ag$brain$layers) &&
      !is.null(ag$brain$layers[[1L]]$mu)
  }

  w_key <- if (is_bnn(agent_a) || is_bnn(agent_b)) "mu" else "W"
  va    <- .flatten_brain(agent_a, w_key)
  vb    <- .flatten_brain(agent_b, w_key)

  n <- min(length(va), length(vb))
  if (n == 0L) return(NA_real_)

  diff  <- va[seq_len(n)] - vb[seq_len(n)]
  denom <- max(1.0, sqrt(sum(va[seq_len(n)]^2) + sum(vb[seq_len(n)]^2)) / 2.0)
  sqrt(sum(diff^2)) / denom
}

#' Compute pedigree-based relatedness between two agents
#'
#' `compute_relatedness()` estimates the coefficient of relatedness (r) between
#' two agents using parent-ID pedigree chains stored in `env$agents`. The
#' algorithm returns r = 0.5 for parent-offspring, r = 0.25 for full siblings
#' (shared parent), and r = 0 otherwise. This matches Hamilton's rule
#' coefficients used by the kin selection module.
#'
#' @param id_a,id_b Integer; `$id` values of the two agents to compare.
#' @param env Environment list from [run_alife()].
#'
#' @return Numeric scalar in the range 0--1.
#'
#' @examples
#' \dontrun{
#' env <- run_alife(default_specs())
#' ids <- sapply(env$agents, `[[`, "id")
#' compute_relatedness(ids[1], ids[2], env)
#' }
#' @export
compute_relatedness <- function(id_a, id_b, env) {
  stopifnot(is.list(env), !is.null(env$agents))
  id_a <- as.integer(id_a)
  id_b <- as.integer(id_b)

  if (id_a == id_b) return(1.0)

  # Build id -> parent_id lookup from surviving agents
  parent_map <- list()
  for (ag in env$agents) {
    if (!is.null(ag$id) && !is.null(ag$parent_id))
      parent_map[[as.character(ag$id)]] <- as.integer(ag$parent_id)
  }

  # Ancestors of an id up to depth d
  ancestors <- function(id, depth = 3L) {
    ids <- integer(0)
    current <- as.integer(id)
    for (i in seq_len(depth)) {
      p <- parent_map[[as.character(current)]]
      if (is.null(p) || p == 0L) break
      ids <- c(ids, p)
      current <- p
    }
    ids
  }

  pid_a <- parent_map[[as.character(id_a)]]
  pid_b <- parent_map[[as.character(id_b)]]

  # Direct parent-offspring
  if (!is.null(pid_a) && !is.null(pid_b)) {
    if (pid_a == id_b || pid_b == id_a) return(0.5)
    # Siblings: same parent
    if (pid_a != 0L && pid_a == pid_b) return(0.25)
  }

  # Grandparent-offspring or first cousins
  anc_a <- ancestors(id_a)
  anc_b <- ancestors(id_b)
  if (any(anc_a %in% anc_b) || any(anc_b %in% anc_a)) return(0.125)

  0.0
}

#' Build the sensory input vector for an agent
#'
#' `sense_env()` reconstructs the 11-element (or longer, when predators or
#' parental care are active) sensory input vector that the agent's brain would
#' receive on the current tick. It mirrors the Julia-side sensing logic so that
#' you can inspect, plot, or replay individual agent decisions from R.
#'
#' The function requires `env$grass` (returned automatically by [run_alife()])
#' and `env$agents`. Agent-map occupancy is reconstructed from agent positions.
#' When `env$grass` is `NULL` (e.g. from a mock env), grass slots are set to 0.
#'
#' @param env Environment list from [run_alife()].
#' @param i Integer; index into `env$agents` (1-based). Use `agent_id` to
#'   locate the index by ID: `which(sapply(env$agents, \(a) a$id) == agent_id)`.
#'
#' @return A named numeric vector. Slots:
#' \describe{
#'   \item{`grass_L/U/R/D/C`}{Grass value in left, up, right, down, centre.}
#'   \item{`agent_L/U/R/D`}{Agent presence (0/1) in four cardinal directions.}
#'   \item{`energy`}{Agent's current energy.}
#'   \item{`age_norm`}{Agent age normalised by `specs$max_age`.}
#' }
#'
#' @examples
#' \dontrun{
#' env <- run_alife(default_specs())
#' v   <- sense_env(env, 1L)
#' barplot(v, las = 2, main = "Sensory input, agent 1")
#' }
#'
#' @seealso [take_action()], [inspect_brain()]
#' @export
sense_env <- function(env, i = 1L) {
  stopifnot(is.list(env), !is.null(env$agents))
  i <- as.integer(i)
  if (i < 1L || i > length(env$agents))
    stop(sprintf("Agent index %d is out of range (env has %d agents).",
                 i, length(env$agents)), call. = FALSE)

  ag    <- env$agents[[i]]
  specs <- env$specs
  nr    <- as.integer(specs$grid_rows)
  nc    <- as.integer(specs$grid_cols)
  rad   <- if (!is.null(specs$input_radius)) as.integer(specs$input_radius) else 1L

  ax <- as.integer(ag$x)
  ay <- as.integer(ag$y)

  # Reconstruct agent occupancy map from agent positions
  agent_map <- matrix(0L, nrow = nr, ncol = nc)
  for (j in seq_along(env$agents)) {
    jx <- as.integer(env$agents[[j]]$x)
    jy <- as.integer(env$agents[[j]]$y)
    if (jx >= 1L && jx <= nr && jy >= 1L && jy <= nc)
      agent_map[jx, jy] <- 1L
  }

  # Grass (use env$grass if present, else zeros)
  grass_mat <- if (!is.null(env$grass)) env$grass else matrix(0, nr, nc)

  # Helper: directional look-up with toroidal wrap
  wrap <- function(x, n) ((x - 1L) %% n) + 1L
  look_grass <- function(dx, dy) {
    gx <- wrap(ax + dx * rad, nr)
    gy <- wrap(ay + dy * rad, nc)
    grass_mat[gx, gy]
  }
  look_agent <- function(dx, dy) {
    gx <- wrap(ax + dx * rad, nr)
    gy <- wrap(ay + dy * rad, nc)
    as.numeric(agent_map[gx, gy] > 0L && !(gx == ax && gy == ay))
  }

  max_age <- if (!is.null(specs$max_age)) as.numeric(specs$max_age) else 200.0

  in_vec <- c(
    grass_L  = look_grass(-1L,  0L),
    grass_U  = look_grass( 0L, -1L),
    grass_R  = look_grass( 1L,  0L),
    grass_D  = look_grass( 0L,  1L),
    grass_C  = look_grass( 0L,  0L),
    agent_L  = look_agent(-1L,  0L),
    agent_U  = look_agent( 0L, -1L),
    agent_R  = look_agent( 1L,  0L),
    agent_D  = look_agent( 0L,  1L),
    energy   = as.numeric(ag$energy),
    age_norm = min(1.0, as.numeric(ag$age) / max_age)
  )

  in_vec
}

#' Choose an action for an agent given its sensory input
#'
#' `take_action()` runs the agent's brain forward pass on its current sensory
#' input and returns the chosen action index (1-indexed). Action indices match
#' the Julia convention: 1 = left, 2 = up, 3 = right, 4 = down, 5 = eat,
#' 6 = reproduce (where 5 and 6 may not be available for all brain types).
#'
#' For BNN brains the mean weights (`mu`) are used (the agent acts on the mode
#' of its weight posterior). For other brain types, `W` weights are used.
#'
#' @param env Environment list from [run_alife()].
#' @param i Integer; index into `env$agents` (1-based).
#' @param input Numeric vector. Sensory input (from [sense_env()]). If `NULL`,
#'   `sense_env(env, i)` is called automatically.
#'
#' @return A named list:
#' \describe{
#'   \item{`$action`}{Integer action index (1-based).}
#'   \item{`$logits`}{Raw output values from the final brain layer.}
#'   \item{`$probs`}{Softmax probabilities over actions.}
#'   \item{`$action_names`}{Character vector of action labels.}
#' }
#'
#' @examples
#' \dontrun{
#' env <- run_alife(default_specs())
#' res <- take_action(env, 1L)
#' res$action        # which action was chosen
#' res$probs         # probability distribution over actions
#' }
#'
#' @seealso [sense_env()], [inspect_brain()]
#' @export
take_action <- function(env, i = 1L, input = NULL) {
  stopifnot(is.list(env), !is.null(env$agents))
  i <- as.integer(i)

  if (is.null(input))
    input <- sense_env(env, i)

  ag         <- env$agents[[i]]
  brain      <- ag$brain
  brain_type <- if (!is.null(env$specs$brain_type)) env$specs$brain_type else "ann"
  w_key      <- if (identical(brain_type, "bnn")) "mu" else "W"

  if (is.null(brain) || is.null(brain$layers) || length(brain$layers) == 0L)
    stop(sprintf("Agent %d has no brain$layers; cannot take action.", i),
         call. = FALSE)

  # Forward pass through all layers with ReLU hidden activations
  h <- as.numeric(input)
  n_layers <- length(brain$layers)
  for (l in seq_len(n_layers)) {
    lay  <- brain$layers[[l]]
    # Fall back: try w_key (mu / W), then the other key
    W_raw <- lay[[w_key]]
    if (is.null(W_raw)) W_raw <- lay[["W"]]
    if (is.null(W_raw)) W_raw <- lay[["mu"]]
    if (is.null(W_raw)) next
    W   <- as.matrix(W_raw)
    b   <- as.numeric(lay$b)
    if (is.null(W) || is.null(b)) next
    h <- W %*% h + b
    if (l < n_layers) h <- pmax(h, 0)  # ReLU on hidden layers
  }

  logits <- as.numeric(h)
  # Numerically stable softmax
  logits_s <- logits - max(logits)
  probs    <- exp(logits_s) / sum(exp(logits_s))
  action   <- which.max(probs)

  action_names <- c("move_left", "move_up", "move_right", "move_down",
                    "eat", "reproduce")
  action_names <- action_names[seq_len(length(probs))]

  list(
    action       = as.integer(action),
    logits       = logits,
    probs        = probs,
    action_names = action_names
  )
}

#' Viability report for an evolutionary-audit run
#'
#' Checks whether a `run_alife()` result is viable enough to support
#' claims about *evolved* trait values. Population crashes (agents
#' dying faster than they reproduce) silently corrupt trait-mean
#' audits by over-weighting a few lucky survivors. This function
#' quantifies crash risk via three metrics and returns a tidy report
#' together with a verdict in `{"viable", "weak", "crashed"}`.
#'
#' Motivation: during the 2026-04-17 fast_specs re-audit of
#' s-plasticity and s-dispersal-ifd, direction flips in the
#' 5-seed multi-seed results were traced to seasonal runs where
#' `n_final < 20` while stable runs maintained healthy populations.
#' The trait-mean average over 0-5 surviving agents is dominated by
#' the specific crash trajectory rather than by any evolutionary
#' signal. This utility codifies the "check n_final before trusting
#' trait-mean effects" rule into a reusable check.
#'
#' @param run_data A list from [get_run_data()] — either a single
#'   `$ticks` data frame or the full `get_run_data()` output.
#' @param n_agents_init Integer. The initial agent count used to
#'   seed the run. Required because `run_data` does not carry the
#'   spec. Pass `NULL` (default) to use the first-tick `n_agents`
#'   (which approximates init-mean after the first wave of births,
#'   and is usually close enough).
#' @param crashed_frac Numeric in (0, 1). A run is declared
#'   `"crashed"` if `n_final < crashed_frac * n_agents_init`.
#'   Default 0.2 (final population less than 20% of init).
#' @param weak_frac Numeric in (0, 1). A run is declared `"weak"`
#'   (viable but with low confidence) if
#'   `n_final < weak_frac * n_agents_init`. Default 0.5.
#' @param min_n Integer. Absolute minimum n_final below which the
#'   run is `"crashed"` regardless of `crashed_frac`. Default 20
#'   (at fewer than 20 agents, any trait mean is dominated by a
#'   handful of individuals). Set to `0` to disable this floor.
#'
#' @return A list with:
#' \describe{
#'   \item{`verdict`}{One of `"viable"`, `"weak"`, `"crashed"`.}
#'   \item{`n_init`}{First-tick n_agents used as the reference.}
#'   \item{`n_final`}{Last-tick n_agents.}
#'   \item{`n_min`}{Minimum n_agents across the whole run.}
#'   \item{`frac_final`}{`n_final / n_init`.}
#'   \item{`frac_min`}{`n_min / n_init`.}
#'   \item{`tick_of_min`}{First tick where `n_min` was reached.}
#'   \item{`message`}{A one-line diagnostic suitable for logging.}
#' }
#'
#' @note [hypothesis_sweep()]'s default `crashed` metric uses a
#' *different* threshold (absolute floor of 10 agents at run end)
#' for a *different* question. Use `viability_report()` to gate
#' interpretability (Hamilton-rule-style "is this trait mean
#' meaningful?"); use the sweep's `crashed` metric to count
#' per-condition extinctions in a sweep summary.
#'
#' @examples
#' \dontrun{
#' env  <- run_alife(fast_specs())
#' vr   <- viability_report(get_run_data(env))
#' print(vr)
#' # Guard audit claims on viability:
#' if (vr$verdict == "crashed") {
#'   warning("crash-driven result; trait means are unreliable")
#' }
#' }
#'
#' @seealso [run_alife()], [get_run_data()], [hypothesis_sweep()].
#' @export
viability_report <- function(run_data,
                             n_agents_init = NULL,
                             crashed_frac  = 0.2,
                             weak_frac     = 0.5,
                             min_n         = 20L) {
  stopifnot(is.numeric(crashed_frac), crashed_frac > 0, crashed_frac < 1,
            is.numeric(weak_frac),    weak_frac    > crashed_frac,
            weak_frac    < 1,
            is.numeric(min_n), min_n >= 0)

  # Accept either full get_run_data() output or the $ticks df directly.
  ticks <- if (is.list(run_data) && !is.null(run_data$ticks))
             run_data$ticks
           else run_data
  stopifnot(is.data.frame(ticks), "n_agents" %in% names(ticks),
            "t" %in% names(ticks))

  n_init  <- if (is.null(n_agents_init)) ticks$n_agents[1L]
             else as.integer(n_agents_init)
  n_final <- tail(ticks$n_agents, 1L)
  n_min   <- min(ticks$n_agents, na.rm = TRUE)
  tick_of_min <- ticks$t[which.min(ticks$n_agents)]
  frac_final  <- n_final / max(1L, n_init)
  frac_min    <- n_min   / max(1L, n_init)

  # 0.7.0: only apply the absolute `min_n` threshold when the run STARTED
  # above it. A run that started small (e.g. n_init = 5 in a unit test)
  # and stayed small is *stable*, not crashed; the fractional check
  # (`frac_final < crashed_frac`) handles actual collapse correctly.
  # Pre-0.7.0, viability_report flagged every small-population test as
  # "crashed" regardless of dynamics, producing spurious warnings that
  # broke `expect_silent` / `expect_no_error` tests in test-brains.R and
  # elsewhere.
  abs_check_applies <- n_init >= min_n
  verdict <- if ((abs_check_applies && n_final < min_n) ||
                 frac_final < crashed_frac) {
    "crashed"
  } else if (frac_final < weak_frac) {
    "weak"
  } else {
    "viable"
  }

  msg <- sprintf(
    "%s: n_init=%d, n_final=%d (%.0f%%), n_min=%d at tick %d (%.0f%%)",
    verdict, n_init, n_final, 100 * frac_final,
    n_min, tick_of_min, 100 * frac_min)

  structure(
    list(verdict     = verdict,
         n_init      = as.integer(n_init),
         n_final     = as.integer(n_final),
         n_min       = as.integer(n_min),
         frac_final  = frac_final,
         frac_min    = frac_min,
         tick_of_min = as.integer(tick_of_min),
         message     = msg),
    class = "clade_viability_report")
}

#' @export
print.clade_viability_report <- function(x, ...) {
  cat("<clade viability report>\n ", x$message, "\n", sep = "")
  invisible(x)
}

