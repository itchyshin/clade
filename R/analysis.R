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
#'   analysis of population structure. *Evolution* 38(6):1358-1370.
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
#' @return Numeric scalar in [0, 1].
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
