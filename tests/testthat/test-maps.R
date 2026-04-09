# Tests for R/maps.R -- generate_map(), load_map(), prepare_map().
# These are pure-R functions requiring no Julia session.

library(testthat)

# ── generate_map() ────────────────────────────────────────────────────────────

# 1. Returns an integer matrix of the correct dimensions
test_that("generate_map() returns integer matrix of correct dimensions", {
  m <- generate_map("open", grid_rows = 10L, grid_cols = 12L)
  expect_true(is.matrix(m))
  expect_equal(nrow(m), 10L)
  expect_equal(ncol(m), 12L)
  expect_type(m, "integer")
})

# 2. 'open' type produces all zeros
test_that("generate_map('open') is all zeros", {
  m <- generate_map("open", grid_rows = 8L, grid_cols = 8L)
  expect_equal(sum(m), 0L)
})

# 3. Values are only 0 or 1
test_that("generate_map() values are 0 or 1", {
  for (type in c("open", "patchy", "corridors")) {
    m <- generate_map(type, grid_rows = 20L, grid_cols = 20L,
                      p_wall = 0.3, seed = 1L)
    expect_true(all(m %in% c(0L, 1L)),
                info = sprintf("type = '%s' should only have 0/1 values", type))
  }
})

# 4. 'patchy' with p_wall = 0 produces all zeros
test_that("generate_map('patchy', p_wall=0) produces all zeros", {
  m <- generate_map("patchy", grid_rows = 10L, grid_cols = 10L, p_wall = 0)
  expect_equal(sum(m), 0L)
})

# 5. 'corridors' produces walls AND open cells
test_that("generate_map('corridors') has both walls and open cells", {
  m <- generate_map("corridors", grid_rows = 20L, grid_cols = 20L,
                    p_wall = 0.5, corridor_width = 2L, seed = 7L)
  expect_gt(sum(m == 0L), 0L)
  expect_gt(sum(m == 1L), 0L)
})

# 6. generate_map() warns and forces open cells when p_wall is extreme
test_that("generate_map() warns and forces cells open when p_wall is extreme", {
  expect_warning(
    m <- generate_map("patchy", grid_rows = 20L, grid_cols = 20L, p_wall = 0.99),
    regexp = "open"
  )
})

# 7. seed gives reproducible results
test_that("generate_map() is reproducible with the same seed", {
  m1 <- generate_map("random_cluster", grid_rows = 15L, grid_cols = 15L,
                     p_wall = 0.3, seed = 42L)
  m2 <- generate_map("random_cluster", grid_rows = 15L, grid_cols = 15L,
                     p_wall = 0.3, seed = 42L)
  expect_identical(m1, m2)
})

# 8. invalid type argument errors
test_that("generate_map() errors on unknown type", {
  expect_error(generate_map("hexagonal"), regexp = "should be one of")
})

# ── prepare_map() ─────────────────────────────────────────────────────────────

# 9. Returns correct-dimension integer matrix when map already matches
test_that("prepare_map() returns correct dimensions", {
  specs <- default_specs()
  specs$grid_rows <- 10L; specs$grid_cols <- 10L
  raw_map <- generate_map("open", grid_rows = 10L, grid_cols = 10L)
  out     <- prepare_map(raw_map, specs)
  expect_equal(nrow(out), 10L)
  expect_equal(ncol(out), 10L)
  expect_type(out, "integer")
})

# 10. Rescales a mis-sized map with a warning
test_that("prepare_map() rescales and warns when dimensions mismatch", {
  specs <- default_specs()
  specs$grid_rows <- 10L; specs$grid_cols <- 10L
  big_map <- generate_map("patchy", grid_rows = 20L, grid_cols = 20L, seed = 1L)
  expect_warning(out <- prepare_map(big_map, specs), regexp = "rescaling")
  expect_equal(nrow(out), 10L)
  expect_equal(ncol(out), 10L)
})

# 11. Coerces non-zero values to 1
test_that("prepare_map() coerces any non-zero value to 1", {
  specs <- default_specs()
  specs$grid_rows <- 5L; specs$grid_cols <- 5L
  m <- matrix(c(0, 0.5, 2, -1, 0), nrow = 5L, ncol = 5L)
  out <- prepare_map(m, specs)
  expect_true(all(out %in% c(0L, 1L)))
})

# 12. prepare_map() on an open map returns all zeros
test_that("prepare_map() on open map returns all zeros", {
  specs <- default_specs()
  specs$grid_rows <- 8L; specs$grid_cols <- 8L
  m   <- generate_map("open", grid_rows = 8L, grid_cols = 8L)
  out <- prepare_map(m, specs)
  expect_equal(sum(out), 0L)
})

# ── load_map() ────────────────────────────────────────────────────────────────

# 13. load_map() errors gracefully on a non-existent name
test_that("load_map() errors on unknown name", {
  expect_error(load_map("nonexistent_map_xyz"), regexp = "not found")
})

# 14. load_map() can load a saved RDS file
test_that("load_map() can load a saved RDS file path", {
  tmp <- tempfile(fileext = ".rds")
  m   <- generate_map("open", grid_rows = 5L, grid_cols = 5L)
  saveRDS(m, tmp)
  out <- load_map(tmp)
  expect_identical(out, m)
  unlink(tmp)
})

# ── Integration: generate -> prepare ─────────────────────────────────────────

# 15. Full pipeline: generate + prepare produces valid map
test_that("generate_map() + prepare_map() pipeline works end to end", {
  specs <- default_specs()
  specs$grid_rows <- 12L; specs$grid_cols <- 14L
  m   <- generate_map("patchy", grid_rows = 12L, grid_cols = 14L, seed = 5L)
  out <- prepare_map(m, specs)
  expect_equal(dim(out), c(12L, 14L))
  expect_true(all(out %in% c(0L, 1L)))
  expect_gte(mean(out == 0L), 0.2)
})
