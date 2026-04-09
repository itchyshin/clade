# Tests for the epigenetics (methylation + transgenerational inheritance)
# Julia module.
#
# The pure-R tests run unconditionally (no Julia toolchain needed). The
# integration tests skip gracefully when JuliaConnectoR / Julia are absent.
#
# IMPORTANT: per the Phase 3 protocol, Clade.jl must NOT include
# modules/epigenetics.jl in the live tick loop. The integration tests below
# therefore load epigenetics.jl manually via juliaEval(include(...)) so that
# the module's functions become callable inside the running Julia session
# without requiring any Clade.jl edit. This lets us exercise the mechanism
# end-to-end while keeping the wiring under separate review.

library(testthat)

JULIA_SRC <- system.file("julia", "src", package = "clade")

skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

.epi_specs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 30L
  s$grid_cols     <- 30L
  s$n_agents_init <- 30L
  s$max_agents    <- 200L
  s$max_ticks     <- 80L
  s$random_seed   <- 42L
  s$brain_type    <- "bnn"
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

# Manually load the epigenetics.jl source into the running Julia session.
# Idempotent: re-includes simply re-define the functions.
.load_epigenetics_jl <- function() {
  jl <- file.path(JULIA_SRC, "modules", "epigenetics.jl")
  stopifnot(file.exists(jl))
  JuliaConnectoR::juliaEval(sprintf(
    'Clade.eval(:(include("%s")))',
    gsub("\\\\", "/", jl)
  ))
  invisible(TRUE)
}

# ── 1. epigenetics is FALSE by default ───────────────────────────────────────
test_that("epigenetics defaults to FALSE in default_specs()", {
  s <- default_specs()
  expect_false(s$epigenetics)
})

# ── 2. epigenetic_inheritance default is in (0, 1) ───────────────────────────
test_that("epigenetic_inheritance default is in the open unit interval", {
  s <- default_specs()
  expect_true(is.numeric(s$epigenetic_inheritance))
  expect_gt(s$epigenetic_inheritance, 0)
  expect_lt(s$epigenetic_inheritance, 1)
})

# ── 3. epigenetic_effect_size default is in (0, 1) ───────────────────────────
test_that("epigenetic_effect_size default is in the open unit interval", {
  s <- default_specs()
  expect_true(is.numeric(s$epigenetic_effect_size))
  expect_gt(s$epigenetic_effect_size, 0)
  expect_lt(s$epigenetic_effect_size, 1)
})

# ── 4. methylation and demethylation rates are non-negative ──────────────────
test_that("methylation_rate and demethylation_rate are non-negative", {
  s <- default_specs()
  expect_gte(s$methylation_rate,   0)
  expect_gte(s$demethylation_rate, 0)
})

# ── 5. epigenetics.jl exists and is non-empty ────────────────────────────────
test_that("modules/epigenetics.jl is present in the bundled Julia source", {
  skip_if(!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC),
          "Julia source not installed")
  jl <- file.path(JULIA_SRC, "modules", "epigenetics.jl")
  expect_true(file.exists(jl))
  expect_gt(file.info(jl)$size, 100L)
})

# ── 6. Clade.jl actively includes epigenetics.jl ────────────────────────────
test_that("Clade.jl has an active include for modules/epigenetics.jl", {
  skip_if(!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC),
          "Julia source not installed")
  clade_jl <- readLines(file.path(JULIA_SRC, "Clade.jl"))
  # Match the active (uncommented) include
  pattern_active    <- '^\\s*include\\("modules/epigenetics\\.jl"\\)'
  pattern_tick_call <- 'apply_epigenetics!'
  expect_true(any(grepl(pattern_active, clade_jl)),
              info = "Clade.jl missing active include for epigenetics.jl")
  expect_true(any(grepl(pattern_tick_call, clade_jl)),
              info = "Clade.jl tick loop is missing apply_epigenetics!(env)")
})

# ── 6b. epigenetics.jl defines all required functions ────────────────────────
test_that("epigenetics.jl defines its public API functions", {
  skip_if(!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC),
          "Julia source not installed")
  jl <- paste(readLines(file.path(JULIA_SRC, "modules", "epigenetics.jl")),
              collapse = "\n")
  for (fn in c("init_methylome!", "update_methylome!",
               "inherit_methylome!", "apply_epigenetics!",
               "apply_epigenetic_inheritance!")) {
    expect_true(grepl(paste0("function ", fn), jl, fixed = TRUE),
                info = sprintf("epigenetics.jl missing function %s", fn))
  }
})

# ── 7. run_alife with epigenetics = TRUE, brain_type = "bnn" completes ───────
test_that("run_alife with epigenetics = TRUE (BNN) completes without error", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = TRUE, brain_type = "bnn", max_ticks = 30L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
  expect_true("mean_prior_sigma" %in% names(env$progress))
})

# ── 8. run_alife with epigenetics = TRUE, brain_type = "ann" completes ───────
# ANN has no posterior sigma, so the module is effectively a no-op for it.
# We still verify the run completes without error.
test_that("run_alife with epigenetics = TRUE (ANN) completes without error", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = TRUE, brain_type = "ann", max_ticks = 30L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
})

# ── 9. apply_epigenetics! canalises BNN sigma when invoked directly ─────────
# Because epigenetics.jl is not yet wired into Clade.jl's tick loop (Phase 3
# protocol), we exercise the canalization mechanism by loading the module
# manually and invoking apply_epigenetics! on a freshly built environment.
# We give every agent a positive energy delta so the methylation rule
# should consistently lay marks down, and we use a large epigenetic_effect_size
# so that the per-call sigma reduction is unmistakable.
test_that("apply_epigenetics! reduces BNN sigma when reward is positive", {
  skip_no_julia()
  s <- .epi_specs(
    epigenetics              = TRUE,
    brain_type               = "bnn",
    max_ticks                = 5L,
    epigenetic_effect_size   = 0.5,
    epigenetic_learning_coupling = 1.0,
    methylation_rate         = 0.5,
    demethylation_rate       = 0.0
  )
  # Spin up Julia and create an env (single-tick run is the cheapest way).
  env <- run_alife(s, verbose = FALSE)
  expect_no_error(.load_epigenetics_jl())

  # Build a fresh Julia env directly so we can hold onto the live struct.
  JuliaConnectoR::juliaEval('
    function _epi_test_canalization(specs)
        env = Clade.create_environment(specs)
        # Give every agent a clearly positive energy delta to drive methylation
        for ag in env.agents
            ag.energy_last_tick = ag.energy - 50.0f0
        end
        # Capture mean prior sigma BEFORE applying epigenetics
        sigmas_before = Float64[]
        for ag in env.agents
            if ag.brain isa Clade.BNNBrain
                push!(sigmas_before, Float64(sum(ag.brain.sigma) / length(ag.brain.sigma)))
            end
        end
        mean_before = isempty(sigmas_before) ? 0.0 : sum(sigmas_before) / length(sigmas_before)

        # Apply once: this lazy-inits the methylome, draws methylation marks,
        # and multiplies sigma by (1 - effect_size) at every methylated locus.
        Clade.apply_epigenetics!(env)
        # Apply a second time so methylated marks accumulate and the second
        # application multiplies sigma again, giving the test more headroom.
        Clade.apply_epigenetics!(env)

        sigmas_after = Float64[]
        n_methylated = 0
        for ag in env.agents
            if ag.brain isa Clade.BNNBrain
                push!(sigmas_after, Float64(sum(ag.brain.sigma) / length(ag.brain.sigma)))
                n_methylated += count(identity, ag.methylome)
            end
        end
        mean_after = isempty(sigmas_after) ? 0.0 : sum(sigmas_after) / length(sigmas_after)
        (mean_before, mean_after, n_methylated)
    end
  ')
  res <- JuliaConnectoR::juliaCall("_epi_test_canalization",
                                    .specs_to_julia(s))
  before     <- as.numeric(res[[1]])
  after      <- as.numeric(res[[2]])
  n_methyl   <- as.integer(res[[3]])

  expect_gt(before, 0)
  expect_gt(n_methyl, 0L)            # methylation actually fired
  expect_lt(after, before)            # canalization happened
})

# ── 10. With epigenetics = FALSE, mean_prior_sigma is still recorded ─────────
test_that("epigenetics = FALSE: mean_prior_sigma is logged and finite", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = FALSE, brain_type = "bnn", max_ticks = 30L)
  env <- run_alife(s, verbose = FALSE)
  sig <- env$progress$mean_prior_sigma
  expect_true(is.numeric(sig))
  expect_true(all(is.finite(sig)))
  expect_true(any(sig > 0))   # BNN populates this; non-BNN would log 0
})

# ── 11. Diploid + epigenetics run completes ──────────────────────────────────
test_that("epigenetics = TRUE with ploidy = 2 completes", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = TRUE, brain_type = "bnn",
                  ploidy = 2L, max_ticks = 30L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
})

# ── 13. epigenetics = FALSE by default ───────────────────────────────────────
test_that("epigenetics is FALSE in default_specs()", {
  expect_false(default_specs()$epigenetics)
})

# ── 14. epigenetic_learning_coupling defaults to 0.1 ─────────────────────────
test_that("epigenetic_learning_coupling defaults to 0.1", {
  expect_equal(default_specs()$epigenetic_learning_coupling, 0.10)
})

# ── 15. epigenetic_inheritance defaults to 0.5 ───────────────────────────────
test_that("epigenetic_inheritance defaults to 0.5", {
  expect_equal(default_specs()$epigenetic_inheritance, 0.50)
})

# ── 16. epigenetic_effect_size defaults to 0.2 ───────────────────────────────
test_that("epigenetic_effect_size defaults to 0.2", {
  expect_equal(default_specs()$epigenetic_effect_size, 0.20)
})

# ── 17. methylation_rate defaults to 0.001 ───────────────────────────────────
test_that("methylation_rate defaults to 0.001", {
  expect_equal(default_specs()$methylation_rate, 0.001)
})

# ── 18. demethylation_rate defaults to 0.002 ─────────────────────────────────
test_that("demethylation_rate defaults to 0.002", {
  expect_equal(default_specs()$demethylation_rate, 0.002)
})

# ── 19. methylation_rate < demethylation_rate (net demethylation pressure) ───
test_that("methylation_rate < demethylation_rate in defaults", {
  s <- default_specs()
  expect_lt(s$methylation_rate, s$demethylation_rate)
})

# ── 20. Epigenetics params are positive numerics ──────────────────────────────
test_that("all numeric epigenetics params are positive in defaults", {
  s <- default_specs()
  for (param in c("epigenetic_learning_coupling", "epigenetic_inheritance",
                  "epigenetic_effect_size", "methylation_rate",
                  "demethylation_rate")) {
    expect_true(is.numeric(s[[param]]),
                info = sprintf("%s should be numeric", param))
    expect_gt(s[[param]], 0,
              label = sprintf("default_specs()$%s > 0", param))
  }
})

# ── 21. epigenetic_learning_coupling is in [0, 1] range ──────────────────────
test_that("epigenetic_learning_coupling default is in [0, 1]", {
  elc <- default_specs()$epigenetic_learning_coupling
  expect_gte(elc, 0)
  expect_lte(elc, 1)
})

# ── 22. All epigenetics params round-trip through default_specs() ────────────
test_that("epigenetics params all present and named correctly in default_specs()", {
  s <- default_specs()
  expected_params <- c("epigenetics", "epigenetic_learning_coupling",
                       "epigenetic_inheritance", "epigenetic_effect_size",
                       "methylation_rate", "demethylation_rate")
  for (param in expected_params) {
    expect_true(param %in% names(s),
                info = sprintf("default_specs() missing '%s'", param))
  }
})

# ── 23. epigenetics = TRUE run completes ─────────────────────────────────────
test_that("run_alife with epigenetics = TRUE completes without error", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = TRUE, brain_type = "bnn", max_ticks = 20L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 24. epigenetics = TRUE with rl_mode = "actor_critic" completes ───────────
test_that("epigenetics = TRUE with rl_mode = 'actor_critic' completes", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = TRUE, brain_type = "bnn",
                  rl_mode = "actor_critic", max_ticks = 20L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 12. inherit_methylome! transmits ~half the marks at default settings ─────
# Pure-Julia unit test: build two agents, set the parent's methylome to all
# TRUE, run inherit_methylome! and check that the offspring has roughly
# epigenetic_inheritance fraction of marks.
test_that("inherit_methylome! transmits about half the marks at p = 0.5", {
  skip_no_julia()
  s <- .epi_specs(epigenetics = TRUE, brain_type = "bnn",
                  epigenetic_inheritance = 0.5)
  env <- run_alife(s, verbose = FALSE)   # ensure Julia + Clade are loaded
  expect_no_error(.load_epigenetics_jl())

  JuliaConnectoR::juliaEval('
    function _epi_test_inheritance(specs)
        env  = Clade.create_environment(specs)
        ag1  = env.agents[1]
        ag2  = env.agents[2]
        # Allocate the parent methylome and methylate every locus.
        Clade.init_methylome!(ag1, specs)
        for i in eachindex(ag1.methylome)
            ag1.methylome[i] = true
        end
        # Inherit into ag2 (treated as offspring).
        Clade.inherit_methylome!(ag2, ag1, specs)
        n_parent    = count(identity, ag1.methylome)
        n_offspring = count(identity, ag2.methylome)
        (n_parent, n_offspring, length(ag2.methylome))
    end
  ')
  res        <- JuliaConnectoR::juliaCall("_epi_test_inheritance",
                                           .specs_to_julia(s))
  n_parent   <- as.integer(res[[1]])
  n_off      <- as.integer(res[[2]])
  n_total    <- as.integer(res[[3]])

  expect_gt(n_parent, 0L)
  expect_equal(n_total, n_parent)         # offspring methylome length matches
  # With inheritance prob = 0.5 and ~hundreds of loci, n_off should fall
  # well within [0.25, 0.75] of n_parent. Generous bounds avoid flakiness.
  ratio <- n_off / n_parent
  expect_gt(ratio, 0.25)
  expect_lt(ratio, 0.75)
})
