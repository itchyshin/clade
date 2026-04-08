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
#' @importFrom ggplot2 theme_minimal theme theme_void labs
#' @importFrom ggplot2 scale_fill_viridis_c scale_colour_gradient
#' @importFrom ggplot2 scale_colour_manual scale_linetype_manual
#' @importFrom ggplot2 annotate coord_fixed element_text element_blank element_rect margin
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
  sigma_vec <- if ("mean_prior_sigma" %in% names(d)) d$mean_prior_sigma
               else rep(0, nrow(d))
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

  grass_max <- if (!is.null(specs$grass_max)) specs$grass_max else 5

  # Agents
  agents <- env$agents
  if (is.null(agents) || length(agents) == 0L) {
    agents_df <- data.frame(row = integer(0), col = integer(0),
                            energy = numeric(0))
  } else {
    agents_df <- data.frame(
      row    = vapply(agents, function(a) as.numeric(a$x), numeric(1)),
      col    = vapply(agents, function(a) as.numeric(a$y), numeric(1)),
      energy = vapply(agents, function(a) as.numeric(a$energy), numeric(1))
    )
  }

  # Predators (optional)
  preds <- env$predators
  pred_df <- if (is.null(preds) || length(preds) == 0L) {
    data.frame(row = integer(0), col = integer(0))
  } else {
    data.frame(
      row = vapply(preds, function(a) as.numeric(a$x), numeric(1)),
      col = vapply(preds, function(a) as.numeric(a$y), numeric(1))
    )
  }

  tick <- if (!is.null(env$t)) env$t else 0L
  title_str <- sprintf("Tick %d  |  Agents: %d", tick, nrow(agents_df))

  p <- ggplot2::ggplot(
    grass_df,
    ggplot2::aes(x = .data$col, y = .data$row, fill = .data$grass)
  ) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_viridis_c(
      option = "D", direction = 1, limits = c(0, grass_max),
      name = "Grass"
    )

  if (nrow(agents_df) > 0L) {
    p <- p +
      ggplot2::geom_point(
        data = agents_df,
        ggplot2::aes(x = .data$col, y = .data$row, colour = .data$energy),
        size = 2, inherit.aes = FALSE
      ) +
      ggplot2::scale_colour_gradient(
        low = "#fde0dd", high = "#fdbb84", name = "Energy"
      )
  }

  if (nrow(pred_df) > 0L) {
    p <- p +
      ggplot2::geom_point(
        data = pred_df,
        ggplot2::aes(x = .data$col, y = .data$row),
        shape = 17, colour = "#d62728", size = 2.5, inherit.aes = FALSE
      )
  }

  p +
    ggplot2::coord_fixed(xlim = c(0.5, nc + 0.5),
                         ylim = c(0.5, nr + 0.5), expand = FALSE) +
    ggplot2::labs(title = title_str, x = NULL, y = NULL) +
    .clade_theme() +
    ggplot2::theme(
      axis.text  = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
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
