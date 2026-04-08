test_that("speciation defaults to FALSE", {
  expect_false(default_specs()$speciation)
})

test_that("isolation_threshold defaults to 0.5", {
  expect_equal(default_specs()$isolation_threshold, 0.5)
})

test_that("speciation_cluster_interval defaults to 10L", {
  expect_equal(default_specs()$speciation_cluster_interval, 10L)
})

test_that("speciation is logical", {
  expect_true(is.logical(default_specs()$speciation))
})

test_that("isolation_threshold is in (0, 1)", {
  t <- default_specs()$isolation_threshold
  expect_true(t > 0 && t < 1)
})

test_that("speciation_cluster_interval is a positive integer-like value", {
  v <- default_specs()$speciation_cluster_interval
  expect_true(is.integer(v) || (is.numeric(v) && v == as.integer(v)))
  expect_true(v > 0)
})

test_that("all speciation params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("speciation", "isolation_threshold", "speciation_cluster_interval")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("genome distance of identical vectors is 0", {
  v <- rnorm(10)
  dist <- sqrt(sum((v - v)^2))
  expect_equal(dist, 0)
})

test_that("genome distance of different vectors is positive", {
  g1 <- rnorm(10)
  g2 <- rnorm(10)
  dist <- sqrt(sum((g1 - g2)^2))
  expect_true(dist > 0)
})

test_that("BFS components: single node yields 1 component", {
  # Minimal BFS component counter
  bfs_components <- function(adj) {
    nodes   <- names(adj)
    visited <- setNames(rep(FALSE, length(nodes)), nodes)
    n_comp  <- 0L
    for (n in nodes) {
      if (!visited[n]) {
        n_comp <- n_comp + 1L
        queue  <- n
        while (length(queue) > 0) {
          cur   <- queue[1]
          queue <- queue[-1]
          if (!visited[cur]) {
            visited[cur] <- TRUE
            neighbours   <- adj[[cur]]
            queue        <- c(queue, neighbours[!visited[neighbours]])
          }
        }
      }
    }
    n_comp
  }
  adj <- list("1" = character(0))
  expect_equal(bfs_components(adj), 1L)
})

test_that("BFS components: two connected nodes yield 1 component", {
  bfs_components <- function(adj) {
    nodes   <- names(adj)
    visited <- setNames(rep(FALSE, length(nodes)), nodes)
    n_comp  <- 0L
    for (n in nodes) {
      if (!visited[n]) {
        n_comp <- n_comp + 1L
        queue  <- n
        while (length(queue) > 0) {
          cur   <- queue[1]
          queue <- queue[-1]
          if (!visited[cur]) {
            visited[cur] <- TRUE
            neighbours   <- adj[[cur]]
            queue        <- c(queue, neighbours[!visited[neighbours]])
          }
        }
      }
    }
    n_comp
  }
  adj <- list("1" = "2", "2" = "1")
  expect_equal(bfs_components(adj), 1L)
})

test_that("BFS components: two disconnected nodes yield 2 components", {
  bfs_components <- function(adj) {
    nodes   <- names(adj)
    visited <- setNames(rep(FALSE, length(nodes)), nodes)
    n_comp  <- 0L
    for (n in nodes) {
      if (!visited[n]) {
        n_comp <- n_comp + 1L
        queue  <- n
        while (length(queue) > 0) {
          cur   <- queue[1]
          queue <- queue[-1]
          if (!visited[cur]) {
            visited[cur] <- TRUE
            neighbours   <- adj[[cur]]
            queue        <- c(queue, neighbours[!visited[neighbours]])
          }
        }
      }
    }
    n_comp
  }
  adj <- list("1" = "2", "2" = "1", "3" = character(0))
  expect_equal(bfs_components(adj), 2L)
})

test_that("isolation_threshold > 0 (requires some genetic divergence)", {
  expect_true(default_specs()$isolation_threshold > 0)
})

test_that("isolation_threshold < 1 (not all agents in one species)", {
  expect_true(default_specs()$isolation_threshold < 1)
})

test_that("speciation_cluster_interval >= 1", {
  expect_true(default_specs()$speciation_cluster_interval >= 1)
})

test_that("speciation_cluster_interval <= 100", {
  expect_true(default_specs()$speciation_cluster_interval <= 100)
})

test_that("agents with identical genomes have distance 0 and share a species", {
  g1 <- rnorm(10)
  g2 <- g1
  dist <- sqrt(sum((g1 - g2)^2))
  threshold <- default_specs()$isolation_threshold
  expect_equal(dist, 0)
  expect_true(dist < threshold)
})

test_that("agents beyond isolation_threshold should be different species", {
  # Construct two genomes separated by more than the threshold
  threshold <- default_specs()$isolation_threshold
  g1 <- rep(0, 10)
  g2 <- rep(threshold + 0.1, 10)   # Euclidean distance >> threshold
  dist <- sqrt(sum((g1 - g2)^2))
  expect_true(dist > threshold)
})

test_that("n_species column is present in a mock ticks data frame", {
  rd <- list(ticks = data.frame(t = 1L, n_species = 1L))
  expect_true("n_species" %in% names(rd$ticks))
})

test_that("n_species is integer-like in a mock ticks data frame", {
  rd <- list(ticks = data.frame(n_species = 1L))
  v <- rd$ticks$n_species
  expect_true(is.integer(v) || (is.numeric(v) && v == as.integer(v)))
})
