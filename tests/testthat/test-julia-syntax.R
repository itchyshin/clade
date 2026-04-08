# Tests for Julia source file syntax and module structure.
# These tests parse but do NOT execute the Julia code (no Julia session).
# A running Julia session is required only for integration tests.

library(testthat)

JULIA_SRC <- system.file("julia", "src", package = "clade")

skip_no_julia_src <- function() {
  if (!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC)) {
    skip("Julia source directory not found (package not installed)")
  }
}

# ── 1. All expected Julia files exist ────────────────────────────────────────
test_that("all expected Julia source files are present", {
  skip_no_julia_src()
  expected <- c(
    "Clade.jl",
    "types.jl",
    "genome.jl",
    "sense.jl",
    "tick.jl",
    "reproduce.jl",
    "death.jl",
    "logging.jl",
    "brains/ann.jl",
    "brains/bnn.jl"
  )
  missing <- character(0L)
  for (f in expected) {
    path <- file.path(JULIA_SRC, f)
    if (!file.exists(path)) missing <- c(missing, f)
  }
  expect_equal(missing, character(0L),
               info = paste("Missing Julia files:", paste(missing, collapse = ", ")))
})

# ── 2. Julia files are non-empty ──────────────────────────────────────────────
test_that("Julia source files are non-empty", {
  skip_no_julia_src()
  files <- list.files(JULIA_SRC, pattern = "\\.jl$", recursive = TRUE,
                      full.names = TRUE)
  expect_gt(length(files), 0L)
  for (f in files) {
    sz <- file.info(f)$size
    expect_true(sz > 100L,
                label = sprintf("%s has size %d (should be > 100 bytes)", f, sz))
  }
})

# ── 3. Project.toml is valid ──────────────────────────────────────────────────
test_that("Project.toml exists and has required fields", {
  skip_no_julia_src()
  toml_path <- file.path(dirname(JULIA_SRC), "Project.toml")
  expect_true(file.exists(toml_path))
  content <- readLines(toml_path)
  expect_true(any(grepl("^name", content)), info = "Project.toml missing 'name'")
  expect_true(any(grepl("^uuid", content)), info = "Project.toml missing 'uuid'")
  expect_true(any(grepl("^version", content)), info = "Project.toml missing 'version'")
})

# ── 4. Clade.jl includes all required sub-files ───────────────────────────────
test_that("Clade.jl includes types.jl, genome.jl, and brain files", {
  skip_no_julia_src()
  clade_jl <- readLines(file.path(JULIA_SRC, "Clade.jl"))
  for (required_include in c("types.jl", "genome.jl", "brains/ann.jl",
                              "brains/bnn.jl", "sense.jl", "tick.jl",
                              "reproduce.jl", "death.jl", "logging.jl")) {
    pattern <- paste0('include\\("', basename(required_include))
    # also check subdirectory form
    expect_true(
      any(grepl(gsub("brains/", "", required_include), clade_jl, fixed = TRUE)),
      info = sprintf("Clade.jl does not include %s", required_include)
    )
  }
})

# ── 5. types.jl defines AbstractBrain, DiploidGenome, Agent, Environment ─────
test_that("types.jl defines the four core types", {
  skip_no_julia_src()
  types_jl <- paste(readLines(file.path(JULIA_SRC, "types.jl")), collapse = "\n")
  for (typename in c("AbstractBrain", "DiploidGenome", "Agent", "Environment")) {
    expect_true(grepl(typename, types_jl, fixed = TRUE),
                info = sprintf("types.jl does not define %s", typename))
  }
})

# ── 6. genome.jl defines meiosis and express_weights ─────────────────────────
test_that("genome.jl defines meiosis() and express_weights()", {
  skip_no_julia_src()
  genome_jl <- paste(readLines(file.path(JULIA_SRC, "genome.jl")), collapse = "\n")
  for (fn in c("meiosis", "express_weights", "genome_distance",
               "make_offspring_genome", "make_genome")) {
    expect_true(grepl(paste0("function ", fn), genome_jl),
                info = sprintf("genome.jl missing function %s", fn))
  }
})

# ── 7. bnn.jl defines BNNBrain struct and forward() ──────────────────────────
test_that("bnn.jl defines BNNBrain and forward()", {
  skip_no_julia_src()
  bnn_jl <- paste(readLines(file.path(JULIA_SRC, "brains", "bnn.jl")),
                  collapse = "\n")
  expect_true(grepl("BNNBrain", bnn_jl, fixed = TRUE))
  expect_true(grepl("function forward", bnn_jl, fixed = TRUE))
  expect_true(grepl("function bnn_update!", bnn_jl, fixed = TRUE))
})

# ── 8. ann.jl defines ANNBrain and _softmax ───────────────────────────────────
test_that("ann.jl defines ANNBrain and _softmax()", {
  skip_no_julia_src()
  ann_jl <- paste(readLines(file.path(JULIA_SRC, "brains", "ann.jl")),
                  collapse = "\n")
  expect_true(grepl("ANNBrain", ann_jl, fixed = TRUE))
  expect_true(grepl("function _softmax", ann_jl, fixed = TRUE))
})

# ── 9. N_SCALAR_TRAITS constant matches expected count ─────────────────────────
test_that("N_SCALAR_TRAITS is defined as 9 in types.jl", {
  skip_no_julia_src()
  types_jl <- paste(readLines(file.path(JULIA_SRC, "types.jl")), collapse = "\n")
  expect_true(grepl("N_SCALAR_TRAITS = 9", types_jl, fixed = TRUE))
})

# ── 10. Trait indices are all distinct 1..9 ────────────────────────────────────
test_that("TRAIT_* indices in types.jl are distinct and cover 1..9", {
  skip_no_julia_src()
  types_jl <- readLines(file.path(JULIA_SRC, "types.jl"))
  trait_lines <- grep("^const TRAIT_", types_jl, value = TRUE)
  expect_equal(length(trait_lines), 9L,
               info = paste("Expected 9 TRAIT_ constants, got", length(trait_lines)))
  indices <- as.integer(sub(".*= (\\d+)$", "\\1", trait_lines))
  expect_equal(sort(indices), 1L:9L)
})
