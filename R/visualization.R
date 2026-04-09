#' Visualisation layer for clade simulation output
#'
#' Functions in this file construct ggplot2 (Wickham 2016) and patchwork
#' (Pedersen 2020) objects from the tidy data returned by [get_run_data()].
#' All plots use a minimal theme and are safe to print, save, or combine.
#'
#' @references
#' Wickham, H. (2016) *ggplot2: Elegant Graphics for Data Analysis.* 2nd ed.
#'   Springer-Verlag, New York.
#' Pedersen, T.L. (2020) *patchwork: The Composer of Plots.* R package version
#'   1.1.0. https://patchwork.data-imaginist.com
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_tile geom_point geom_ribbon
#' @importFrom ggplot2 geom_histogram geom_bar geom_col geom_hline
#' @importFrom ggplot2 theme_minimal theme theme_void labs
#' @importFrom ggplot2 scale_fill_viridis_c scale_fill_gradient scale_fill_gradient2
#' @importFrom ggplot2 scale_fill_manual scale_colour_gradient scale_colour_viridis_c
#' @importFrom ggplot2 scale_colour_manual scale_linetype_manual scale_linewidth_manual
#' @importFrom ggplot2 scale_size_continuous
#' @importFrom ggplot2 annotate coord_fixed coord_flip element_text element_blank
#' @importFrom ggplot2 element_rect margin
#' @importFrom ggplot2 .data
#' @importFrom patchwork wrap_plots
#' @importFrom stats sd
#' @name clade-visualization
NULL

# ── Internal helper ───────────────────────────────────────────────────────────
.clade_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title   = ggplot2::element_text(face = "bold", size = 11),
      panel.grid.minor = ggplot2::element_blank()
    )
}

.check_run_data <- function(run_data) {
  if (!is.list(run_data) || is.null(run_data$ticks)) {
    stop("`run_data` must be a list with a `$ticks` component. ",
         "Did you forget to call get_run_data(env)?", call. = FALSE)
  }
  invisible(TRUE)
}

# ── plot_run() ────────────────────────────────────────────────────────────────

#' Dashboard plot summarising a clade simulation run
#'
#' @title Dashboard plot summarising a clade simulation run
#' @description
#' Constructs a 2x3 patchwork grid of time-series diagnostics from the output
#' of [get_run_data()]: population size, mean energy with variability ribbon,
#' genetic diversity, births vs deaths per tick, grass coverage, and a sixth
#' panel that switches between body size (ANN brain) and BNN prior sigma (the
#' Baldwin Effect panel; Baldwin 1896, Hinton & Nowlan 1987) depending on the
#' active brain type.
#'
#' @param run_data A list as returned by [get_run_data()]. Must contain a
#'   `$ticks` data frame with columns `t`, `n_agents`, `mean_energy`,
#'   `sd_energy`, `genetic_diversity`, `n_births`, `n_deaths`, `grass_coverage`,
#'   `mean_body_size`, and `mean_prior_sigma`.
#' @param ... Currently unused. Reserved for future plotting options.
#'
#' @return A [patchwork::wrap_plots()] object composed of six ggplot panels.
#'
#' @references
#' Baldwin, J.M. (1896) A new factor in evolution. *American Naturalist*
#'   30(354):441--451.
#' Hinton, G.E. & Nowlan, S.J. (1987) How learning can guide evolution.
#'   *Complex Systems* 1(3):495--502.
#'
#' @examples
#' \dontrun{
#' env  <- run_clade(default_specs())
#' data <- get_run_data(env)
#' plot_run(data)
#' }
#'
#' @seealso [get_run_data()], [plot_environment()], [plot_genome_diversity()]
#' @export
plot_run <- function(run_data, ...) {
  .check_run_data(run_data)
  d <- run_data$ticks

  # Filter out unlogged rows (t == 0) in case max_ticks > actual length
  if ("t" %in% names(d)) d <- d[d$t > 0L, , drop = FALSE]
  if (nrow(d) == 0L) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0.5, y = 0.5,
                          label = "No logged ticks") +
        ggplot2::theme_void()
    )
  }

  # 1. Population size
  p_pop <- ggplot2::ggplot(d, ggplot2::aes(x = .data$t, y = .data$n_agents)) +
    ggplot2::geom_line(colour = "#2b6cb0", linewidth = 0.6) +
    ggplot2::labs(title = "Population size", x = "Tick", y = "n agents") +
    .clade_theme()

  # 2. Mean energy with +/- 1 SD ribbon
  d$energy_lo <- d$mean_energy - d$sd_energy
  d$energy_hi <- d$mean_energy + d$sd_energy
  p_energy <- ggplot2::ggplot(d, ggplot2::aes(x = .data$t)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$energy_lo, ymax = .data$energy_hi),
      fill = "#c6dbef", alpha = 0.6
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$mean_energy),
      colour = "#08519c", linewidth = 0.6
    ) +
    ggplot2::labs(title = "Mean energy (+/- 1 SD)",
                  x = "Tick", y = "Energy") +
    .clade_theme()

  # 3. Genetic diversity
  p_div <- ggplot2::ggplot(
    d, ggplot2::aes(x = .data$t, y = .data$genetic_diversity)
  ) +
    ggplot2::geom_line(colour = "#6a51a3", linewidth = 0.6) +
    ggplot2::labs(title = "Genetic diversity",
                  x = "Tick", y = "Mean pairwise distance") +
    .clade_theme()

  # 4. Births vs deaths per tick (two lines)
  d_long <- data.frame(
    t     = rep(d$t, 2L),
    count = c(d$n_births, d$n_deaths),
    event = factor(rep(c("Births", "Deaths"), each = nrow(d)),
                   levels = c("Births", "Deaths"))
  )
  p_bd <- ggplot2::ggplot(
    d_long,
    ggplot2::aes(x = .data$t, y = .data$count, colour = .data$event)
  ) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::scale_colour_manual(values = c("Births" = "#2ca02c",
                                            "Deaths" = "#d62728"),
                                 name = NULL) +
    ggplot2::labs(title = "Births and deaths",
                  x = "Tick", y = "Count / tick") +
    .clade_theme() +
    ggplot2::theme(legend.position = "bottom")

  # 5. Grass coverage
  p_grass <- ggplot2::ggplot(
    d, ggplot2::aes(x = .data$t, y = .data$grass_coverage)
  ) +
    ggplot2::geom_line(colour = "#238b45", linewidth = 0.6) +
    ggplot2::labs(title = "Grass coverage",
                  x = "Tick", y = "Fraction of grid") +
    .clade_theme()

  # 6. Brain-type panel: BNN sigma decay (Baldwin Effect) or body size
  sigma_col <- if ("mean_prior_sigma" %in% names(d)) "mean_prior_sigma" else NULL
  sigma_vec <- if (!is.null(sigma_col)) d[[sigma_col]] else rep(0, nrow(d))
  if (any(sigma_vec > 0) && stats::sd(sigma_vec) > 1e-8) {
    p_sixth <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data$t, y = .data$mean_prior_sigma)
    ) +
      ggplot2::geom_line(colour = "#b45309", linewidth = 0.6) +
      ggplot2::labs(title = "BNN prior sigma (Baldwin Effect)",
                    x = "Tick", y = "Mean prior sigma") +
      .clade_theme()
  } else if ("mean_body_size" %in% names(d)) {
    p_sixth <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data$t, y = .data$mean_body_size)
    ) +
      ggplot2::geom_line(colour = "#525252", linewidth = 0.6) +
      ggplot2::labs(title = "Mean body size",
                    x = "Tick", y = "Body size") +
      .clade_theme()
  } else {
    p_sixth <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0.5, y = 0.5,
                        label = "No sixth-panel data") +
      ggplot2::theme_void()
  }

  patchwork::wrap_plots(
    p_pop, p_energy, p_div,
    p_bd,  p_grass,  p_sixth,
    ncol = 3L
  )
}

# ── plot_environment() ────────────────────────────────────────────────────────

#' Plot the current state of a clade environment
#'
#' @title Plot the current state of a clade environment
#' @description
#' Renders a snapshot of the grid world: grass density as a green tile
#' heatmap, agents as points coloured by energy, and (when present) predators
#' as red triangles. Uses the toroidal coordinate system (1:grid_rows,
#' 1:grid_cols).
#'
#' @param env An environment list returned by [run_clade()]. Must contain
#'   `$specs`, `$grass` (numeric matrix), and `$agents` (list of per-agent
#'   records with `x`, `y`, and `energy` fields).
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' \dontrun{
#' env <- run_clade(default_specs())
#' plot_environment(env)
#' }
#'
#' @seealso [plot_run()], [run_clade()]
#' @export
plot_environment <- function(env) {
  if (!is.list(env) || is.null(env$specs)) {
    stop("`env` must be a list with a `$specs` component.", call. = FALSE)
  }
  specs <- env$specs
  nr <- as.integer(specs$grid_rows)
  nc <- as.integer(specs$grid_cols)

  # Grass: accept either a matrix or a vector; fall back to zeros.
  grass_mat <- env$grass
  if (is.null(grass_mat)) {
    grass_mat <- matrix(0, nrow = nr, ncol = nc)
  }
  grass_df <- data.frame(
    row   = rep(seq_len(nr), times = nc),
    col   = rep(seq_len(nc), each = nr),
    grass = as.vector(grass_mat)
  )

  grass_max <- if (!is.null(specs$grass_max)) as.numeric(specs$grass_max) else 5

  # Agents — JuliaConnectoR proxies require index-based iteration
  agents <- env$agents
  n_agents <- if (!is.null(agents)) as.integer(length(agents)) else 0L
  if (n_agents > 0L) {
    agents_df <- data.frame(
      row    = vapply(seq_len(n_agents),
                      function(i) as.numeric(agents[[i]]$x), numeric(1L)),
      col    = vapply(seq_len(n_agents),
                      function(i) as.numeric(agents[[i]]$y), numeric(1L)),
      energy = vapply(seq_len(n_agents),
                      function(i) as.numeric(agents[[i]]$energy), numeric(1L))
    )
  } else {
    agents_df <- data.frame(row = integer(0), col = integer(0),
                            energy = numeric(0))
  }

  # Predators (optional)
  preds <- env$predators
  n_preds <- if (!is.null(preds)) as.integer(length(preds)) else 0L
  pred_df <- if (n_preds > 0L) {
    .safe_num <- function(x) {
      v <- suppressWarnings(as.numeric(x))
      if (length(v) == 1L && is.finite(v)) v else 2.0
    }
    data.frame(
      row    = vapply(seq_len(n_preds),
                      function(i) .safe_num(preds[[i]]$x), numeric(1L)),
      col    = vapply(seq_len(n_preds),
                      function(i) .safe_num(preds[[i]]$y), numeric(1L)),
      energy = vapply(seq_len(n_preds),
                      function(i) .safe_num(preds[[i]]$energy), numeric(1L))
    )
  } else {
    data.frame(row = integer(0), col = integer(0), energy = numeric(0))
  }

  tick <- if (!is.null(env$t)) as.integer(env$t) else 0L
  title_str <- if (n_preds > 0L) {
    sprintf("Tick %d  |  Prey: %d  |  Predators: %d", tick, n_agents, n_preds)
  } else {
    sprintf("Tick %d  |  Agents: %d", tick, n_agents)
  }

  p <- ggplot2::ggplot(
    grass_df,
    ggplot2::aes(x = .data$col, y = .data$row, fill = .data$grass)
  ) +
    ggplot2::geom_tile(show.legend = TRUE) +
    ggplot2::scale_fill_gradient(
      low = "#1a3d0a", high = "#7cfc00",
      limits = c(0, grass_max), name = "Grass"
    )

  if (nrow(agents_df) > 0L) {
    p <- p +
      ggplot2::geom_point(
        data = agents_df,
        ggplot2::aes(x = .data$col, y = .data$row,
                     size = .data$energy),
        colour = "white", alpha = 0.85, inherit.aes = FALSE
      ) +
      ggplot2::scale_size_continuous(range = c(1.5, 5), name = "Energy")
  }

  if (nrow(pred_df) > 0L) {
    p <- p +
      ggplot2::geom_point(
        data = pred_df,
        ggplot2::aes(x = .data$col, y = .data$row,
                     size = .data$energy),
        shape = 17, colour = "#d62728", alpha = 0.9, inherit.aes = FALSE
      )
  }

  p +
    ggplot2::coord_fixed(xlim = c(0.5, nc + 0.5),
                         ylim = c(0.5, nr + 0.5), expand = FALSE) +
    ggplot2::labs(title = title_str, x = NULL, y = NULL) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = "#0d1117", colour = NA),
      panel.background = ggplot2::element_rect(fill = "#0d1117", colour = NA),
      plot.title       = ggplot2::element_text(colour = "grey90", hjust = 0.5,
                                               margin = ggplot2::margin(b = 6)),
      legend.text      = ggplot2::element_text(colour = "grey80"),
      legend.title     = ggplot2::element_text(colour = "grey80"),
      plot.margin      = ggplot2::margin(8, 8, 8, 8)
    )
}

# ── plot_genome_diversity() ───────────────────────────────────────────────────

#' Plot genetic diversity over time
#'
#' @title Plot genetic diversity over time
#' @description
#' Draws the trajectory of the mean pairwise genome distance logged by
#' [get_run_data()]. When `specs$speciation = TRUE` the maximum observed
#' `n_species` is annotated in the upper-left corner.
#'
#' @param run_data A list returned by [get_run_data()]. Must contain a
#'   `$ticks` data frame with at minimum `t` and `genetic_diversity`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' \dontrun{
#' env  <- run_clade(default_specs())
#' data <- get_run_data(env)
#' plot_genome_diversity(data)
#' }
#'
#' @seealso [plot_run()], [get_run_data()]
#' @export
plot_genome_diversity <- function(run_data) {
  .check_run_data(run_data)
  d <- run_data$ticks
  if ("t" %in% names(d)) d <- d[d$t > 0L, , drop = FALSE]

  if (nrow(d) == 0L) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0.5, y = 0.5,
                          label = "No diversity data logged") +
        ggplot2::theme_void()
    )
  }

  p <- ggplot2::ggplot(
    d, ggplot2::aes(x = .data$t, y = .data$genetic_diversity)
  ) +
    ggplot2::geom_line(colour = "#6a51a3", linewidth = 0.6) +
    ggplot2::labs(
      title = "Genetic diversity over time",
      x = "Tick",
      y = "Mean pairwise genome distance"
    ) +
    .clade_theme()

  # Annotate number of species when speciation data is present
  if ("n_species" %in% names(d)) {
    n_sp <- max(d$n_species, na.rm = TRUE)
    if (is.finite(n_sp) && n_sp > 0L) {
      p <- p +
        ggplot2::annotate(
          "text",
          x = min(d$t), y = max(d$genetic_diversity, na.rm = TRUE),
          label = sprintf("max n_species = %d", as.integer(n_sp)),
          hjust = 0, vjust = 1, size = 3, colour = "grey40"
        )
    }
  }
  p
}

# ── plot_disease_dynamics() ───────────────────────────────────────────────────

#' Plot disease dynamics over time
#'
#' @title Plot disease dynamics over time
#' @description
#' Plots `n_infected` (solid red line) and `n_new_infections` (dashed orange
#' line) from a clade run. When both series are zero (disease module off) the
#' function returns an informative empty placeholder plot.
#'
#' @param run_data A list returned by [get_run_data()]. Must contain
#'   `$ticks` with the columns `t`, `n_infected`, `n_new_infections`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' \dontrun{
#' specs <- default_specs(); specs$disease <- TRUE
#' env   <- run_clade(specs)
#' data  <- get_run_data(env)
#' plot_disease_dynamics(data)
#' }
#'
#' @seealso [plot_run()], [get_run_data()]
#' @export
plot_disease_dynamics <- function(run_data) {
  .check_run_data(run_data)
  d <- run_data$ticks
  if ("t" %in% names(d)) d <- d[d$t > 0L, , drop = FALSE]

  has_cols <- all(c("n_infected", "n_new_infections") %in% names(d))
  if (!has_cols || nrow(d) == 0L ||
      (all(d$n_infected == 0L) && all(d$n_new_infections == 0L))) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate(
          "text", x = 0.5, y = 0.5,
          label = "Disease module inactive (all zeros)"
        ) +
        ggplot2::theme_void()
    )
  }

  long <- data.frame(
    t      = rep(d$t, 2L),
    count  = c(d$n_infected, d$n_new_infections),
    series = factor(rep(c("Infected", "New infections"), each = nrow(d)),
                    levels = c("Infected", "New infections"))
  )

  ggplot2::ggplot(
    long, ggplot2::aes(x = .data$t, y = .data$count,
                       colour = .data$series, linetype = .data$series)
  ) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::scale_colour_manual(
      values = c("Infected" = "#d62728", "New infections" = "#ff7f0e"),
      name = NULL
    ) +
    ggplot2::scale_linetype_manual(
      values = c("Infected" = "solid", "New infections" = "dashed"),
      name = NULL
    ) +
    ggplot2::labs(title = "Disease dynamics (SIR)",
                  x = "Tick", y = "Agents") +
    .clade_theme() +
    ggplot2::theme(legend.position = "bottom")
}

# ── plot_signal_evolution() ───────────────────────────────────────────────────

#' Plot signal evolution (Phase 2 placeholder)
#'
#' @title Plot signal evolution (Phase 2 placeholder)
#' @description
#' Placeholder returning a ggplot with a note that signal evolution plotting
#' is scheduled for Phase 2. Kept here so downstream code can rely on a stable
#' API while the feature is implemented.
#'
#' @param run_data A list returned by [get_run_data()]. Currently unused.
#'
#' @return A [ggplot2::ggplot()] object with a single annotation.
#'
#' @examples
#' \dontrun{
#' plot_signal_evolution(get_run_data(run_clade(default_specs())))
#' }
#'
#' @seealso [plot_run()]
#' @export
plot_signal_evolution <- function(run_data) {
  ggplot2::ggplot() +
    ggplot2::annotate(
      "text", x = 0.5, y = 0.5,
      label = "Signal evolution: Phase 2"
    ) +
    ggplot2::theme_void()
}

# ── plot_kin_network() ────────────────────────────────────────────────────────

#' Plot kin network (Phase 2 placeholder)
#'
#' @title Plot kin network (Phase 2 placeholder)
#' @description
#' Placeholder returning a ggplot noting that kin network visualisation
#' requires the igraph package and is scheduled for Phase 2. Matches the
#' alifeR API.
#'
#' @param run_data A list returned by [get_run_data()]. Currently unused.
#'
#' @return A [ggplot2::ggplot()] object with a single annotation.
#'
#' @examples
#' \dontrun{
#' plot_kin_network(get_run_data(run_clade(default_specs())))
#' }
#'
#' @seealso [plot_run()]
#' @export
plot_kin_network <- function(run_data) {
  ggplot2::ggplot() +
    ggplot2::annotate(
      "text", x = 0.5, y = 0.5,
      label = "Kin network: requires igraph (Phase 2)"
    ) +
    ggplot2::theme_void()
}

# ── plot_dead_agents() ────────────────────────────────────────────────────────

#' Plot lifetime statistics of dead agents
#'
#' @title Plot lifetime statistics of dead agents
#' @description
#' Produces two panels summarising agents that died during a run. The
#' **left panel** plots age at death against energy at death, coloured by
#' body size (when body-size evolution is active) or number of offspring,
#' and sized by offspring count. The **right panel** shows a bar chart of
#' cause-of-death counts (starvation, predation, disease, old age). Together
#' these reveal which life-history strategies were rewarded by selection.
#'
#' @param run_data A list returned by [get_run_data()]. Must contain a
#'   `$deaths` data frame with columns `age`, `energy`, `cause`,
#'   `num_offspring`, and optionally `body_size`.
#'
#' @return A two-panel [patchwork::wrap_plots()] object, or `NULL` invisibly
#'   if no agents died.
#'
#' @examples
#' \dontrun{
#' env  <- run_clade(default_specs())
#' data <- get_run_data(env)
#' plot_dead_agents(data)
#' }
#'
#' @seealso [get_run_data()], [visualize_progress()]
#' @export
plot_dead_agents <- function(run_data) {
  .check_run_data(run_data)
  d <- run_data$deaths
  if (is.null(d) || nrow(d) == 0L) {
    message("No dead agents to plot.")
    return(invisible(NULL))
  }

  # Use body_size if available and varied; otherwise colour by offspring count
  has_bs <- "body_size" %in% names(d) && stats::sd(d$body_size, na.rm = TRUE) > 1e-6
  colour_var  <- if (has_bs) d$body_size else d$num_offspring
  colour_name <- if (has_bs) "Body size" else "Offspring"

  p_scatter <- ggplot2::ggplot(
    d,
    ggplot2::aes(x = .data$age, y = .data$energy,
                 size   = .data$num_offspring,
                 colour = colour_var)
  ) +
    ggplot2::geom_point(alpha = 0.65) +
    ggplot2::scale_colour_viridis_c(option = if (has_bs) "plasma" else "viridis",
                                    name = colour_name) +
    ggplot2::scale_size_continuous(range = c(0.8, 5), name = "Offspring") +
    ggplot2::labs(
      title = "Lifespan vs energy at death",
      x     = "Age at death (ticks)",
      y     = "Energy at death"
    ) +
    .clade_theme() +
    ggplot2::theme(legend.position = "right")

  # Cause-of-death breakdown
  if ("cause" %in% names(d)) {
    cause_tbl <- as.data.frame(table(cause = d$cause), stringsAsFactors = FALSE)
    cause_tbl <- cause_tbl[order(-cause_tbl$Freq), ]
    cause_tbl$cause <- factor(cause_tbl$cause,
                              levels = rev(cause_tbl$cause))

    p_cause <- ggplot2::ggplot(
      cause_tbl,
      ggplot2::aes(x = .data$cause, y = .data$Freq, fill = .data$cause)
    ) +
      ggplot2::geom_col(show.legend = FALSE, width = 0.7) +
      ggplot2::scale_fill_viridis_c(begin = 0.2, end = 0.8) +
      ggplot2::coord_flip() +
      ggplot2::labs(
        title = "Cause of death",
        x     = NULL,
        y     = "Count"
      ) +
      .clade_theme()
  } else {
    # Lifespan histogram as fallback
    p_cause <- ggplot2::ggplot(d, ggplot2::aes(x = .data$age)) +
      ggplot2::geom_histogram(bins = 25, fill = "#92c5de", colour = "white") +
      ggplot2::labs(title = "Lifespan distribution",
                    x = "Age at death", y = "Count") +
      .clade_theme()
  }

  patchwork::wrap_plots(p_scatter, p_cause, ncol = 2L)
}

# ── plot_diversity() ──────────────────────────────────────────────────────────

#' Plot genetic diversity over the run
#'
#' @title Plot genetic diversity over the run
#' @description
#' Draws the trajectory of mean pairwise genome distance (genetic diversity)
#' and, when body-size evolution is active, the coefficient of variation of
#' body size as a proxy for phenotypic diversity. All series are scaled to the
#' same 0–1 range for visual comparison.
#'
#' A common pattern is high diversity in the founders, a selective sweep that
#' reduces diversity as the best foraging strategy spreads, then a partial
#' recovery as the population niches. Permanent low diversity indicates
#' genetic drift or clonal selection; permanently high diversity indicates
#' balancing selection or frequency-dependent dynamics.
#'
#' @param run_data A list returned by [get_run_data()]. Must contain a
#'   `$ticks` data frame with at minimum `t`, `n_agents`, and
#'   `genetic_diversity`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' \dontrun{
#' env  <- run_clade(default_specs())
#' data <- get_run_data(env)
#' plot_diversity(data)
#' }
#'
#' @seealso [plot_genome_diversity()], [visualize_progress()]
#' @export
plot_diversity <- function(run_data) {
  .check_run_data(run_data)
  tk <- run_data$ticks
  tk <- tk[!is.na(tk$n_agents) & tk$n_agents >= 2L & tk$t > 0L, , drop = FALSE]

  if (nrow(tk) == 0L) {
    message("Not enough data to plot diversity (need >= 2 agents per tick).")
    return(invisible(NULL))
  }

  .scale01 <- function(x) {
    mx <- max(x, na.rm = TRUE)
    if (is.finite(mx) && mx > 0) x / mx else x
  }

  plot_df <- data.frame(
    t      = tk$t,
    value  = .scale01(tk$genetic_diversity),
    metric = "Genetic diversity"
  )

  # Add body-size CV if available and varied
  has_bs <- "sd_body_size" %in% names(tk) && "mean_body_size" %in% names(tk)
  if (has_bs) {
    bs_cv <- tk$sd_body_size / pmax(tk$mean_body_size, 1e-6)
    if (any(is.finite(bs_cv) & bs_cv > 0, na.rm = TRUE)) {
      plot_df <- rbind(
        plot_df,
        data.frame(t = tk$t, value = .scale01(bs_cv),
                   metric = "Body-size CV")
      )
    }
  }

  col_vals <- c("Genetic diversity" = "#6a51a3",
                "Body-size CV"      = "#d95f02")

  ggplot2::ggplot(
    plot_df,
    ggplot2::aes(x = .data$t, y = .data$value,
                 colour = .data$metric, linetype = .data$metric)
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_colour_manual(
      values = col_vals[names(col_vals) %in% unique(plot_df$metric)],
      name = NULL
    ) +
    ggplot2::scale_linetype_manual(
      values = c("Genetic diversity" = "solid", "Body-size CV" = "dashed")[
        names(c("Genetic diversity" = "solid", "Body-size CV" = "dashed")) %in%
          unique(plot_df$metric)],
      name = NULL
    ) +
    ggplot2::labs(
      title = "Population diversity over time (scaled 0\u20131)",
      x     = "Tick",
      y     = "Diversity (scaled)"
    ) +
    .clade_theme() +
    ggplot2::theme(legend.position = "bottom",
                   legend.key.width = ggplot2::unit(1.2, "cm"))
}

# ── plot_body_size_evolution() ────────────────────────────────────────────────

#' Plot body-size evolution over time
#'
#' @title Plot body-size evolution over time
#' @description
#' Draws the trajectory of mean body size with a ± 1 SD ribbon. When
#' `body_size_evolution = FALSE` this produces a flat line at 1.0. When
#' evolution is active the population mean drifts toward a size that balances
#' metabolic cost against foraging gain (the metabolic optimum; Kleiber 1947).
#'
#' @param run_data A list returned by [get_run_data()]. Must contain a
#'   `$ticks` data frame with columns `t`, `mean_body_size`, and
#'   `sd_body_size`.
#'
#' @return A [ggplot2::ggplot()] object, or `NULL` invisibly when body-size
#'   data are absent.
#'
#' @references
#' Kleiber, M. (1947) Body size and metabolic rate. *Physiological Reviews*
#'   27(4):511--541.
#'
#' @examples
#' \dontrun{
#' specs <- default_specs(); specs$body_size_evolution <- TRUE
#' env   <- run_clade(specs)
#' data  <- get_run_data(env)
#' plot_body_size_evolution(data)
#' }
#'
#' @seealso [plot_run()], [get_run_data()]
#' @export
plot_body_size_evolution <- function(run_data) {
  .check_run_data(run_data)
  d <- run_data$ticks
  d <- d[d$t > 0L, , drop = FALSE]

  if (!all(c("mean_body_size", "sd_body_size") %in% names(d))) {
    message("Body-size columns not found in run_data$ticks.")
    return(invisible(NULL))
  }

  d$bs_lo <- d$mean_body_size - d$sd_body_size
  d$bs_hi <- d$mean_body_size + d$sd_body_size

  ggplot2::ggplot(d, ggplot2::aes(x = .data$t)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$bs_lo, ymax = .data$bs_hi),
      fill = "#d9d9d9", alpha = 0.6
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$mean_body_size),
      colour = "#525252", linewidth = 0.7
    ) +
    ggplot2::geom_hline(yintercept = 1.0, linetype = "dashed",
                        colour = "grey60", linewidth = 0.4) +
    ggplot2::labs(
      title = "Body-size evolution (mean \u00b1 1 SD)",
      x     = "Tick",
      y     = "Body size (reference = 1.0)"
    ) +
    .clade_theme()
}

# ── plot_dispersal_events() ───────────────────────────────────────────────────

#' Plot natal dispersal events over time
#'
#' @title Plot natal dispersal events over time
#' @description
#' Draws the count of natal dispersal moves per tick as a bar chart overlaid
#' with a smoothed trend line. Each bar represents the number of agents that
#' moved away from their birthplace during that tick. When
#' `dispersal_evolution = FALSE` all bars are zero.
#'
#' @param run_data A list returned by [get_run_data()]. Must contain a
#'   `$ticks` data frame with columns `t` and `n_dispersal_events`.
#'
#' @return A [ggplot2::ggplot()] object, or `NULL` invisibly when the
#'   dispersal column is absent.
#'
#' @examples
#' \dontrun{
#' specs <- default_specs(); specs$dispersal_evolution <- TRUE
#' env   <- run_clade(specs)
#' data  <- get_run_data(env)
#' plot_dispersal_events(data)
#' }
#'
#' @seealso [plot_run()], [get_run_data()]
#' @export
plot_dispersal_events <- function(run_data) {
  .check_run_data(run_data)
  d <- run_data$ticks
  d <- d[d$t > 0L, , drop = FALSE]

  if (!"n_dispersal_events" %in% names(d)) {
    message("n_dispersal_events column not found in run_data$ticks.")
    return(invisible(NULL))
  }

  ggplot2::ggplot(d, ggplot2::aes(x = .data$t, y = .data$n_dispersal_events)) +
    ggplot2::geom_col(fill = "#74c476", alpha = 0.7, width = 1) +
    ggplot2::geom_line(colour = "#238b45", linewidth = 0.5) +
    ggplot2::labs(
      title = "Natal dispersal events per tick",
      x     = "Tick",
      y     = "N dispersal moves"
    ) +
    .clade_theme()
}

# ── plot_weight_heatmap() ─────────────────────────────────────────────────────

#' Visualise a neural genome as a weight heatmap
#'
#' @title Visualise a neural genome as a weight heatmap
#' @description
#' Renders each weight matrix in an ANN-format brain (a list with a `layers`
#' element, each layer having `$W` and `$b`) as a diverging blue-white-red
#' tile heatmap. Blue = strong inhibitory connections, red = strong excitatory
#' connections, white = near-zero weights. One panel per layer.
#'
#' Agents under strong selection often show structured weight matrices (certain
#' input-to-hidden connections consistently strong) compared to the near-random
#' patterns of newly initialised founders.
#'
#' @param ann A brain list with a `$layers` element, as returned by
#'   `env$agents[[i]]$brain` for ANN brain types. Must be an R list (not a
#'   JuliaConnectoR proxy).
#' @param title Character scalar prepended to each panel title.
#'   Default: `"Neural genome"`.
#'
#' @return A [patchwork::wrap_plots()] object with one panel per layer.
#'
#' @examples
#' \dontrun{
#' env <- run_clade(default_specs())
#' # Access brain data (requires converting from Julia proxy first)
#' # plot_weight_heatmap(brain_list)
#' }
#'
#' @seealso [visualize_progress()]
#' @export
plot_weight_heatmap <- function(ann, title = "Neural genome") {
  if (is.null(ann$layers)) {
    stop("`ann` must be a list with a `$layers` element.", call. = FALSE)
  }
  layers <- ann$layers
  L      <- length(layers)

  .mat_to_long <- function(mat, label) {
    nr <- nrow(mat); nc <- ncol(mat)
    data.frame(
      row   = rep(seq_len(nr), times = nc),
      col   = rep(seq_len(nc), each  = nr),
      value = as.vector(mat),
      layer = label,
      stringsAsFactors = FALSE
    )
  }

  all_weights <- unlist(lapply(layers, function(l) as.vector(l$W)))
  w_lim       <- max(abs(all_weights))

  make_panel <- function(mat, layer_label) {
    df <- .mat_to_long(mat, layer_label)
    ggplot2::ggplot(df, ggplot2::aes(x = .data$col, y = .data$row,
                                     fill = .data$value)) +
      ggplot2::geom_tile() +
      ggplot2::scale_fill_gradient2(
        low      = "#2166ac", mid  = "white", high = "#d6604d",
        midpoint = 0, limits = c(-w_lim, w_lim), name = "Weight"
      ) +
      ggplot2::labs(
        title = paste(title, ":", layer_label),
        x     = "Input neuron",
        y     = "Output neuron"
      ) +
      .clade_theme() +
      ggplot2::coord_fixed()
  }

  panels <- lapply(seq_len(L), function(k) {
    lbl <- if (k < L) sprintf("W%d (hidden %d)", k, k) else
                      sprintf("W%d (\u2192 output)", k)
    make_panel(layers[[k]]$W, lbl)
  })

  patchwork::wrap_plots(panels, ncol = min(L, 3L))
}

# ── visualize_progress() ─────────────────────────────────────────────────────

#' Render the full simulation dashboard
#'
#' @title Render the full simulation dashboard
#' @description
#' Assembles a 2 × 3 panel dashboard from a completed clade run:
#'
#' \describe{
#'   \item{Top-left}{Grid snapshot — landscape and agent positions at the
#'     final tick ([plot_environment()]).}
#'   \item{Top-centre}{Population dynamics — agent count, mean and best
#'     energy over time.}
#'   \item{Top-right}{Diversity trajectory ([plot_diversity()]).}
#'   \item{Bottom-left}{Lifespan vs energy scatter by cause of death.}
#'   \item{Bottom-centre}{Lifespan histogram.}
#'   \item{Bottom-right}{Body-size evolution ribbon (or genetic diversity
#'     when body-size evolution is off).}
#' }
#'
#' @param env An environment list returned by [run_clade()].
#' @param run_data A list returned by [get_run_data()]. If `NULL`, computed
#'   from `env` automatically.
#' @param title Character scalar super-title. If `NULL`, auto-generated from
#'   tick count and final population size.
#'
#' @return A [patchwork::wrap_plots()] composite ggplot object.
#'
#' @examples
#' \dontrun{
#' env  <- run_clade(default_specs())
#' data <- get_run_data(env)
#' visualize_progress(env, data)
#' }
#'
#' @seealso [plot_environment()], [plot_dead_agents()], [plot_diversity()],
#'   [plot_body_size_evolution()], [get_run_data()]
#' @export
visualize_progress <- function(env, run_data = NULL, title = NULL) {
  if (is.null(run_data)) run_data <- get_run_data(env)
  tk <- run_data$ticks
  d  <- run_data$deaths

  # ── Top-left: grid snapshot ────────────────────────────────────────────────
  p_grid <- plot_environment(env)

  # ── Top-centre: population + energy ───────────────────────────────────────
  tk_live <- tk[tk$t > 0L, , drop = FALSE]
  has_best <- "best_energy" %in% names(tk_live)

  pop_lines <- rbind(
    data.frame(t = tk_live$t, y = tk_live$n_agents,
               series = "Pop. size",    lty = "solid",  lwd = 1),
    data.frame(t = tk_live$t, y = tk_live$mean_energy,
               series = "Mean energy",  lty = "dashed", lwd = 0.7)
  )
  if (has_best) {
    pop_lines <- rbind(
      pop_lines,
      data.frame(t = tk_live$t, y = tk_live$best_energy,
                 series = "Best energy", lty = "dashed", lwd = 0.7)
    )
  }
  col_map <- c("Pop. size" = "#2166ac", "Mean energy" = "#4dac26",
               "Best energy" = "#d01c8b")

  p_pop <- ggplot2::ggplot(
    pop_lines,
    ggplot2::aes(x = .data$t, y = .data$y,
                 colour   = .data$series,
                 linetype = .data$series)
  ) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::scale_colour_manual(
      values = col_map[names(col_map) %in% unique(pop_lines$series)],
      name = NULL
    ) +
    ggplot2::scale_linetype_manual(
      values = c("Pop. size" = "solid", "Mean energy" = "dashed",
                 "Best energy" = "dashed")[
        names(c("Pop. size" = "solid", "Mean energy" = "dashed",
                "Best energy" = "dashed")) %in% unique(pop_lines$series)],
      name = NULL
    ) +
    ggplot2::labs(title = "Population & energy", x = "Tick",
                  y = "N / Energy") +
    .clade_theme() +
    ggplot2::theme(legend.position = "bottom",
                   legend.text = ggplot2::element_text(size = 8))

  # ── Top-right: diversity ───────────────────────────────────────────────────
  p_div_obj <- plot_diversity(run_data)
  p_div <- if (is.null(p_div_obj)) {
    ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0.5, y = 0.5, label = "No diversity data") +
      ggplot2::theme_void()
  } else {
    p_div_obj
  }

  # ── Bottom-left: deaths scatter ────────────────────────────────────────────
  if (!is.null(d) && nrow(d) > 0L) {
    has_cause <- "cause" %in% names(d)
    if (has_cause) {
      p_scatter <- ggplot2::ggplot(
        d,
        ggplot2::aes(x = .data$age, y = .data$energy,
                     colour = .data$cause,
                     size   = .data$num_offspring)
      ) +
        ggplot2::geom_point(alpha = 0.55) +
        ggplot2::scale_size_continuous(range = c(0.6, 4), guide = "none") +
        ggplot2::labs(title = "Lifespan vs energy (by cause)",
                      x = "Age at death", y = "Energy at death") +
        .clade_theme() +
        ggplot2::theme(legend.position  = "bottom",
                       legend.text      = ggplot2::element_text(size = 7))
    } else {
      p_scatter <- ggplot2::ggplot(
        d,
        ggplot2::aes(x = .data$age, y = .data$energy,
                     size   = .data$num_offspring)
      ) +
        ggplot2::geom_point(colour = "#6a51a3", alpha = 0.55) +
        ggplot2::scale_size_continuous(range = c(0.6, 4), guide = "none") +
        ggplot2::labs(title = "Lifespan vs energy at death",
                      x = "Age at death", y = "Energy at death") +
        .clade_theme()
    }

    # ── Bottom-centre: lifespan histogram ─────────────────────────────────
    p_hist <- ggplot2::ggplot(d, ggplot2::aes(x = .data$age)) +
      ggplot2::geom_histogram(bins = 25, fill = "#92c5de", colour = "white") +
      ggplot2::labs(title = "Lifespan distribution",
                    x = "Age at death", y = "Count") +
      .clade_theme()
  } else {
    blank <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0.5, y = 0.5, label = "No deaths yet") +
      ggplot2::theme_void()
    p_scatter <- blank
    p_hist    <- blank
  }

  # ── Bottom-right: body size or genetic diversity ───────────────────────────
  has_bs_var <- "sd_body_size" %in% names(tk_live) &&
    any(tk_live$sd_body_size > 0, na.rm = TRUE)
  has_bs_col <- "mean_body_size" %in% names(tk_live)

  if (has_bs_col && has_bs_var) {
    p_sixth <- plot_body_size_evolution(run_data)
  } else {
    p_sixth <- plot_genome_diversity(run_data)
  }

  # ── Assemble title ─────────────────────────────────────────────────────────
  n_final <- as.integer(length(env$agents))
  t_final <- if (!is.null(env$t)) as.integer(env$t) else max(tk$t)
  n_dead  <- if (!is.null(d)) nrow(d) else 0L
  if (is.null(title)) {
    title <- sprintf(
      "clade dashboard  |  tick %d  |  %d surviving  |  %d total deaths",
      t_final, n_final, n_dead
    )
  }

  patchwork::wrap_plots(p_grid, p_pop, p_div,
                        p_scatter, p_hist, p_sixth,
                        ncol = 3L) +
    patchwork::plot_annotation(title = title)
}

# ── plot_module_metrics() ─────────────────────────────────────────────────────

#' Plot module-specific metrics from a clade simulation run
#'
#' @title Plot module-specific metrics from a clade simulation run
#' @description
#' Detects which optional simulation modules were active during a run by
#' inspecting the logged tick columns in `run_data$ticks`, then assembles up
#' to six panels into a patchwork grid. Only panels for modules that produced
#' non-zero data are included:
#'
#' \describe{
#'   \item{Predators}{`n_predators` — line plot of predator population over
#'     time.}
#'   \item{Species}{`n_species` — step plot of species count; shown only when
#'     speciation was active (max > 1).}
#'   \item{Traits}{Overlay of `mean_toxicity`, `mean_plasticity`, and
#'     `mean_helper_tendency` as three coloured lines.}
#'   \item{Signals}{`mean_signal_magnitude` — line plot; shown only when
#'     signal evolution was active (max > 0).}
#'   \item{Parental care}{`n_juveniles` — line plot of juveniles under care;
#'     shown only when max > 0.}
#'   \item{Mimicry}{`n_toxic_attacks` and `n_avoided_attacks` — two lines
#'     showing attacks versus avoidance events; shown only when mimicry attacks
#'     occurred (max n_toxic_attacks > 0).}
#' }
#'
#' If fewer than two panels are active, a single informative placeholder plot
#' is returned instead.
#'
#' @param run_data A list as returned by [get_run_data()]. Must contain a
#'   `$ticks` data frame. The new module columns (`n_predators`, `n_helpers`,
#'   `mean_signal_magnitude`, `mean_toxicity`, `mean_plasticity`,
#'   `mean_helper_tendency`, `n_species`, `n_juveniles`, `n_toxic_attacks`,
#'   `n_avoided_attacks`) are used when present; absent columns are silently
#'   skipped.
#'
#' @return A [patchwork::wrap_plots()] object with up to six panels arranged in
#'   at most three columns, or a single [ggplot2::ggplot()] placeholder when
#'   fewer than two panels are active.
#'
#' @examples
#' \dontrun{
#' specs <- default_specs()
#' specs$n_predators_init  <- 10L
#' specs$mimicry           <- TRUE
#' env  <- run_clade(specs)
#' data <- get_run_data(env)
#' plot_module_metrics(data)
#' }
#'
#' @seealso [plot_run()], [visualize_progress()], [get_run_data()]
#' @export
plot_module_metrics <- function(run_data) {
  .check_run_data(run_data)
  d <- run_data$ticks
  if ("t" %in% names(d)) d <- d[d$t > 0L, , drop = FALSE]

  if (nrow(d) == 0L) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0.5, y = 0.5,
                          label = "No module-specific metrics to display") +
        ggplot2::theme_void()
    )
  }

  panels <- list()

  # ── 1. Predators ─────────────────────────────────────────────────────────────
  if ("n_predators" %in% names(d) && !all(d$n_predators == 0L)) {
    panels[["predators"]] <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data$t, y = .data$n_predators)
    ) +
      ggplot2::geom_line(colour = "#d62728", linewidth = 0.6) +
      ggplot2::labs(title = "Predator population",
                    x = "Tick", y = "n predators") +
      .clade_theme()
  }

  # ── 2. Species (only when speciation active) ──────────────────────────────────
  if ("n_species" %in% names(d) && max(d$n_species, na.rm = TRUE) > 1L) {
    panels[["species"]] <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data$t, y = .data$n_species)
    ) +
      ggplot2::geom_step(colour = "#6a3d9a", linewidth = 0.6) +
      ggplot2::labs(title = "Number of species",
                    x = "Tick", y = "n species") +
      .clade_theme()
  }

  # ── 3. Heritable trait means (toxicity / plasticity / helper tendency) ────────
  trait_cols <- c(
    "mean_toxicity"        = "#e6550d",
    "mean_plasticity"      = "#3182bd",
    "mean_helper_tendency" = "#31a354"
  )
  active_traits <- intersect(names(trait_cols), names(d))
  active_traits <- active_traits[
    vapply(active_traits, function(col) !all(d[[col]] == 0), logical(1L))
  ]
  if (length(active_traits) >= 1L) {
    trait_label <- c(
      "mean_toxicity"        = "Toxicity",
      "mean_plasticity"      = "Plasticity",
      "mean_helper_tendency" = "Helper tendency"
    )
    trait_long <- do.call(rbind, lapply(active_traits, function(col) {
      data.frame(
        t      = d$t,
        value  = d[[col]],
        trait  = trait_label[[col]],
        stringsAsFactors = FALSE
      )
    }))
    trait_long$trait <- factor(trait_long$trait,
                               levels = trait_label[active_traits])

    col_vals <- trait_cols[active_traits]
    names(col_vals) <- trait_label[active_traits]

    panels[["traits"]] <- ggplot2::ggplot(
      trait_long,
      ggplot2::aes(x = .data$t, y = .data$value, colour = .data$trait)
    ) +
      ggplot2::geom_line(linewidth = 0.6) +
      ggplot2::scale_colour_manual(values = col_vals, name = NULL) +
      ggplot2::labs(title = "Heritable trait means",
                    x = "Tick", y = "Mean trait value") +
      .clade_theme() +
      ggplot2::theme(legend.position = "bottom",
                     legend.text = ggplot2::element_text(size = 8))
  }

  # ── 4. Signal magnitude ───────────────────────────────────────────────────────
  if ("mean_signal_magnitude" %in% names(d) &&
      max(d$mean_signal_magnitude, na.rm = TRUE) > 0) {
    panels[["signals"]] <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data$t, y = .data$mean_signal_magnitude)
    ) +
      ggplot2::geom_line(colour = "#f768a1", linewidth = 0.6) +
      ggplot2::labs(title = "Mean signal magnitude",
                    x = "Tick", y = "L1 norm (mean)") +
      .clade_theme()
  }

  # ── 5. Parental care — juveniles ──────────────────────────────────────────────
  if ("n_juveniles" %in% names(d) && max(d$n_juveniles, na.rm = TRUE) > 0L) {
    panels[["care"]] <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data$t, y = .data$n_juveniles)
    ) +
      ggplot2::geom_line(colour = "#74c476", linewidth = 0.6) +
      ggplot2::labs(title = "Juveniles in care",
                    x = "Tick", y = "n juveniles") +
      .clade_theme()
  }

  # ── 6. Mimicry: attacks vs avoidance ─────────────────────────────────────────
  has_toxic  <- "n_toxic_attacks"   %in% names(d)
  has_avoid  <- "n_avoided_attacks" %in% names(d)
  if (has_toxic && max(d$n_toxic_attacks, na.rm = TRUE) > 0L) {
    mim_cols <- c("n_toxic_attacks", if (has_avoid) "n_avoided_attacks")
    mim_label <- c("n_toxic_attacks" = "Toxic attacks",
                   "n_avoided_attacks" = "Avoided attacks")
    mim_long <- do.call(rbind, lapply(mim_cols, function(col) {
      data.frame(
        t      = d$t,
        count  = d[[col]],
        series = mim_label[[col]],
        stringsAsFactors = FALSE
      )
    }))
    mim_long$series <- factor(mim_long$series,
                              levels = mim_label[mim_cols])

    mim_col_vals <- c("Toxic attacks" = "#d62728",
                      "Avoided attacks" = "#2ca02c")
    mim_col_vals <- mim_col_vals[mim_col_vals %in% levels(mim_long$series) |
                                   names(mim_col_vals) %in% levels(mim_long$series)]

    panels[["mimicry"]] <- ggplot2::ggplot(
      mim_long,
      ggplot2::aes(x = .data$t, y = .data$count, colour = .data$series)
    ) +
      ggplot2::geom_line(linewidth = 0.6) +
      ggplot2::scale_colour_manual(
        values = c("Toxic attacks" = "#d62728", "Avoided attacks" = "#2ca02c"),
        name = NULL
      ) +
      ggplot2::labs(title = "Mimicry: attacks vs avoidance",
                    x = "Tick", y = "Count / tick") +
      .clade_theme() +
      ggplot2::theme(legend.position = "bottom",
                     legend.text = ggplot2::element_text(size = 8))
  }

  # ── Assemble ──────────────────────────────────────────────────────────────────
  n_panels <- length(panels)
  if (n_panels < 2L) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0.5, y = 0.5,
                          label = "No module-specific metrics to display") +
        ggplot2::theme_void()
    )
  }

  patchwork::wrap_plots(panels, ncol = min(3L, n_panels))
}
