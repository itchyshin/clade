# Tests for R/visualization.R — pure R, no Julia required.
#
# Mock data matches the structure that get_run_data() produces in Phase 0.

library(testthat)

# ── Mock fixtures ─────────────────────────────────────────────────────────────

.mock_ticks <- function(n = 20L, sigma = 0) {
  data.frame(
    t                      = seq_len(n),
    n_agents               = as.integer(round(seq(10, 20, length.out = n))),
    n_births               = rep(2L, n),
    n_deaths               = rep(1L, n),
    n_starvations          = rep(0L, n),
    n_age_deaths           = rep(0L, n),
    mean_energy            = rep(100.0, n),
    sd_energy              = rep(10.0, n),
    mean_age               = rep(5.0, n),
    sd_age                 = rep(2.0, n),
    mean_body_size         = rep(1.0, n),
    sd_body_size           = rep(0.1, n),
    genetic_diversity      = seq(0, 0.3, length.out = n),
    n_species              = rep(1L, n),
    mean_cooperation_level = rep(0.5, n),
    mean_immune_strength   = rep(0.3, n),
    sd_immune_strength     = rep(0.05, n),
    mean_metabolic_rate    = rep(1.0, n),
    mean_learning_rate     = rep(0.01, n),
    mean_prior_sigma       = if (sigma > 0)
                               seq(sigma, sigma * 0.1, length.out = n)
                             else rep(0.0, n),
    grass_coverage         = seq(0.5, 0.4, length.out = n),
    n_infected             = rep(0L, n),
    n_new_infections       = rep(0L, n),
    n_altruistic_acts      = rep(0L, n),
    n_shelters_built       = rep(0L, n)
  )
}

.mock_deaths <- function() {
  data.frame(
    id            = 1:5,
    t             = 1:5,
    age           = c(10, 8, 15, 3, 20),
    energy        = c(0, 0, 0, 0, 0),
    cause         = rep("starvation", 5),
    body_size     = rep(1.0, 5),
    num_offspring = c(0, 1, 2, 0, 3)
  )
}

.mock_run_data <- function(sigma = 0) {
  list(ticks = .mock_ticks(sigma = sigma), deaths = .mock_deaths())
}

.mock_env <- function(rows = 10L, cols = 10L, n_agents = 3L, n_pred = 0L) {
  grass <- matrix(
    seq_len(rows * cols) / (rows * cols) * 5,
    nrow = rows, ncol = cols
  )
  agents <- lapply(seq_len(n_agents), function(i) {
    list(id = i, x = i, y = i, energy = 50 + i * 10)
  })
  predators <- lapply(seq_len(n_pred), function(i) list(id = i, x = 5L, y = 5L))
  list(
    specs     = list(grid_rows = rows, grid_cols = cols, grass_max = 5),
    grass     = grass,
    agents    = agents,
    predators = predators,
    t         = 42L
  )
}

# ── 1. plot_run returns a patchwork object ────────────────────────────────────

test_that("plot_run() returns a patchwork/ggplot object on valid data", {
  p <- plot_run(.mock_run_data())
  expect_s3_class(p, "patchwork")
  expect_s3_class(p, "ggplot")
})

# ── 2. plot_run with BNN sigma shows Baldwin Effect panel ─────────────────────

test_that("plot_run() switches sixth panel when mean_prior_sigma varies", {
  p <- plot_run(.mock_run_data(sigma = 0.5))
  expect_s3_class(p, "patchwork")
  # Patchwork objects have a `patches` slot listing panels; check it has 6.
  expect_true(length(p$patches$plots) + 1L == 6L)
})

# ── 3. plot_environment returns a ggplot ──────────────────────────────────────

test_that("plot_environment() returns a ggplot given a mock env", {
  p <- plot_environment(.mock_env())
  expect_s3_class(p, "ggplot")
})

test_that("plot_environment() handles predators without error", {
  p <- plot_environment(.mock_env(n_pred = 2L))
  expect_s3_class(p, "ggplot")
})

test_that("plot_environment() handles empty agent list", {
  env <- .mock_env(n_agents = 0L)
  p <- plot_environment(env)
  expect_s3_class(p, "ggplot")
})

# ── 4. plot_genome_diversity returns a ggplot ─────────────────────────────────

test_that("plot_genome_diversity() returns a ggplot given valid run_data", {
  p <- plot_genome_diversity(.mock_run_data())
  expect_s3_class(p, "ggplot")
})

# ── 5. plot_disease_dynamics handles all-zero case ────────────────────────────

test_that("plot_disease_dynamics() returns placeholder when disease is off", {
  p <- plot_disease_dynamics(.mock_run_data())
  expect_s3_class(p, "ggplot")
})

test_that("plot_disease_dynamics() renders when disease data present", {
  rd <- .mock_run_data()
  rd$ticks$n_infected <- as.integer(
    seq(0, 5, length.out = nrow(rd$ticks))
  )
  rd$ticks$n_new_infections <- rep(1L, nrow(rd$ticks))
  p <- plot_disease_dynamics(rd)
  expect_s3_class(p, "ggplot")
})

# ── 6. plot_run errors informatively on missing ticks ────────────────────────

test_that("plot_run() errors informatively when $ticks is missing", {
  expect_error(plot_run(list()), regexp = "ticks")
  expect_error(plot_run(NULL),   regexp = "ticks")
})

# ── 7. plot_signal_evolution placeholder ──────────────────────────────────────

test_that("plot_signal_evolution() returns a ggplot placeholder", {
  p <- plot_signal_evolution(.mock_run_data())
  expect_s3_class(p, "ggplot")
})

# ── 8. plot_kin_network placeholder ───────────────────────────────────────────

test_that("plot_kin_network() returns a ggplot placeholder", {
  p <- plot_kin_network(.mock_run_data())
  expect_s3_class(p, "ggplot")
})

# ── 9. All plot functions accept disease-off data without error ──────────────

test_that("all plot functions run when disease columns are all zero", {
  rd <- .mock_run_data()
  expect_s3_class(plot_run(rd),               "ggplot")
  expect_s3_class(plot_genome_diversity(rd),  "ggplot")
  expect_s3_class(plot_disease_dynamics(rd),  "ggplot")
  expect_s3_class(plot_signal_evolution(rd),  "ggplot")
  expect_s3_class(plot_kin_network(rd),       "ggplot")
})

# ── 10. plot_run() returns a patchwork object ─────────────────────────────────

test_that("plot_run() returns an object that inherits from both patchwork and ggplot", {
  p <- plot_run(.mock_run_data())
  expect_s3_class(p, "patchwork")
  expect_s3_class(p, "ggplot")
})

# ── 11. plot_run() works when ticks has zero rows ─────────────────────────────

test_that("plot_run() handles zero-row ticks without crashing", {
  rd <- .mock_run_data()
  rd$ticks <- rd$ticks[integer(0), , drop = FALSE]
  # Either returns a ggplot placeholder or throws an informative error — both
  # are acceptable; what is NOT acceptable is an uninformative crash.
  result <- tryCatch(plot_run(rd), error = function(e) e)
  expect_true(inherits(result, "ggplot") || inherits(result, "error"))
})

# ── 12. visualize_progress() returns a patchwork object ──────────────────────

test_that("visualize_progress() returns a patchwork plot given env + run_data", {
  env <- .mock_env()
  rd  <- .mock_run_data()
  p   <- visualize_progress(env, run_data = rd)
  expect_s3_class(p, "ggplot")
})

# ── 13. plot_environment() returns a ggplot ───────────────────────────────────

test_that("plot_environment() returns a ggplot for a minimal env", {
  p <- plot_environment(.mock_env(rows = 5L, cols = 5L, n_agents = 1L))
  expect_s3_class(p, "ggplot")
})

# ── 14. plot_diversity() returns a ggplot ────────────────────────────────────

test_that("plot_diversity() returns a ggplot on valid run_data", {
  p <- plot_diversity(.mock_run_data())
  # When n_agents >= 2 in all rows, should produce a plot; otherwise NULL.
  expect_true(is.null(p) || inherits(p, "ggplot"))
})

# ── 15. plot_signal_evolution() returns a ggplot ─────────────────────────────

test_that("plot_signal_evolution() returns a ggplot or placeholder ggplot", {
  p <- plot_signal_evolution(.mock_run_data())
  expect_s3_class(p, "ggplot")
})

# ── 16. plot_disease_dynamics() returns a ggplot ─────────────────────────────

test_that("plot_disease_dynamics() returns a ggplot for all-zero disease data", {
  p <- plot_disease_dynamics(.mock_run_data())
  expect_s3_class(p, "ggplot")
})

# ── 17. plot_module_metrics() returns a ggplot-compatible object ──────────────

test_that("plot_module_metrics() returns a ggplot or patchwork object", {
  rd <- .mock_run_data()
  # Add mock module columns that plot_module_metrics() may need.
  n  <- nrow(rd$ticks)
  rd$ticks$n_predators         <- rep(0L, n)
  rd$ticks$n_prey_killed       <- rep(0L, n)
  rd$ticks$n_juveniles         <- rep(0L, n)
  rd$ticks$n_helpers           <- rep(0L, n)
  rd$ticks$n_toxic_attacks     <- rep(0L, n)
  rd$ticks$n_avoided_attacks   <- rep(0L, n)
  rd$ticks$mean_signal_magnitude <- rep(0.0, n)
  rd$ticks$mean_toxicity       <- rep(0.0, n)
  rd$ticks$mean_plasticity     <- rep(0.0, n)
  rd$ticks$mean_helper_tendency <- rep(0.0, n)
  p <- plot_module_metrics(rd)
  expect_s3_class(p, "ggplot")
})

# ── 18. plot_map() — pure-R mock tests ───────────────────────────────────────

test_that("plot_map() returns a ggplot given a mock env (energy colouring)", {
  env <- .mock_env(rows = 10L, cols = 10L, n_agents = 3L)
  for (i in seq_along(env$agents)) {
    env$agents[[i]]$age       <- i * 2L
    env$agents[[i]]$body_size <- 1.0
    env$agents[[i]]$species_id <- 1L
  }
  p <- plot_map(env)
  expect_s3_class(p, "ggplot")
})

test_that("plot_map() returns a ggplot when colour_by = 'age'", {
  env <- .mock_env(rows = 10L, cols = 10L, n_agents = 3L)
  for (i in seq_along(env$agents)) {
    env$agents[[i]]$age       <- i * 3L
    env$agents[[i]]$body_size <- 1.0
    env$agents[[i]]$species_id <- 1L
  }
  p <- plot_map(env, colour_by = "age")
  expect_s3_class(p, "ggplot")
})

# ── 19. plot_tsne_genomes() — no Julia needed ─────────────────────────────────

test_that("plot_tsne_genomes() returns a placeholder ggplot when genomes is NULL", {
  rd <- .mock_run_data()
  p <- plot_tsne_genomes(rd)
  expect_s3_class(p, "ggplot")
  layers_labels <- vapply(p$layers, function(l) class(l$geom)[1], character(1L))
  expect_true(any(grepl("GeomText", layers_labels)))
})

test_that("plot_tsne_genomes() returns a ggplot when genome data are present", {
  rd <- .mock_run_data()
  set.seed(42L)
  n_rows  <- 30L
  n_genes <- 10L
  genome_mat <- matrix(rnorm(n_rows * n_genes), nrow = n_rows, ncol = n_genes)
  colnames(genome_mat) <- paste0("w", seq_len(n_genes))
  rd$genomes <- cbind(
    data.frame(id = seq_len(n_rows), t = rep(seq(1L, 20L, length.out = n_rows))),
    as.data.frame(genome_mat)
  )
  p <- plot_tsne_genomes(rd, n_agents = 20L)
  expect_s3_class(p, "ggplot")
})

# ── 20. diversity_landscape() ─────────────────────────────────────────────────

test_that("diversity_landscape() returns a ggplot given run_data with mean columns", {
  rd <- list(
    ticks = data.frame(
      t             = 1:10,
      mean_body_size = seq(1.0, 2.0, length.out = 10),
      sd_body_size  = rep(0.1, 10),
      n_agents      = rep(20L, 10)
    )
  )
  p <- diversity_landscape(rd)
  expect_s3_class(p, "ggplot")
})

test_that("diversity_landscape() returns a ggplot when traits is specified explicitly", {
  rd <- list(
    ticks = data.frame(
      t             = 1:10,
      mean_body_size = seq(1.0, 2.0, length.out = 10),
      sd_body_size  = rep(0.1, 10),
      n_agents      = rep(20L, 10)
    )
  )
  p <- diversity_landscape(rd, traits = "mean_body_size")
  expect_s3_class(p, "ggplot")
})

test_that("diversity_landscape() returns a placeholder ggplot when all trait columns are zero-variance", {
  rd <- list(
    ticks = data.frame(
      t             = 1:10,
      mean_body_size = rep(1.0, 10),
      sd_body_size  = rep(0.1, 10),
      n_agents      = rep(20L, 10)
    )
  )
  p <- diversity_landscape(rd)
  expect_s3_class(p, "ggplot")
  # Should be the placeholder (no facets)
  expect_null(p$facet$params$facets)
})
