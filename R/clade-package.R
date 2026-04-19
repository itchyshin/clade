#' clade: Agent-Based Evolutionary Simulation with Julia Backend
#'
#' `clade` provides agent-based simulations of evolution, foraging ecology,
#' and social behaviour. The R layer is an interface; the per-tick
#' simulation kernel runs in Julia via [JuliaConnectoR][JuliaConnectoR::juliaEval],
#' so the R↔Julia boundary is crossed exactly once per [run_alife()] call.
#'
#' ## Getting started
#'
#' ```r
#' specs <- default_specs()
#' specs$n_agents_init <- 40L
#' specs$max_ticks     <- 300L
#' env  <- run_alife(specs)
#' data <- get_run_data(env)
#' plot_run(data)
#' ```
#'
#' First call to [run_alife()] precompiles the Julia kernel (~10–90 s,
#' once per Julia session).
#'
#' ## Key entry points
#'
#' - [default_specs()] — canonical parameter list; modify and pass to
#'   [run_alife()].
#' - [run_alife()] / [run_clade()] — run a single simulation.
#' - [batch_alife()] — run many specs lists (parallel via
#'   [parallel::mclapply]).
#' - [get_run_data()] — extract `$ticks` and `$deaths` data frames from
#'   an env.
#' - [plot_run()] — population / energy / diversity dashboard.
#' - [search_cmaes()] / [search_map_elites()] / [search_gradient()] —
#'   parameter search driven by a user-supplied fitness function.
#' - [hypothesis_sweep()] / [hypothesis_report()] — researcher-
#'   facing wrappers for the sweep->test->report workflow.
#'
#' ## Biological modules
#'
#' All modules are disabled by default and enabled with a single flag in
#' the specs list. See the `README.md` module table and
#' [vignettes/parameter-reference.Rmd](../doc/parameter-reference.html)
#' for the full list with defaults and expected effects.
#'
#' ## Brain architectures
#'
#' Set `specs$brain_type`:
#'
#' - `"bnn"` (default) — Bayesian neural network with Thompson-sampled
#'   weights and REINFORCE posterior updates (Williams 1992; Blundell et
#'   al. 2015).
#' - `"ann"` — standard multilayer perceptron.
#' - `"ctrnn"` — continuous-time recurrent network (Beer 1995).
#' - `"grn"` — sparse gene-regulatory network topology.
#' - `"transformer"` — self-attention (highest capacity, slowest).
#' - `"synthesis"` — symbolic rule extraction from evolved weights.
#'
#' ## Citation
#'
#' Nakagawa, S. (2026). clade: Agent-based evolutionary simulation with
#' a Julia backend. R package version 0.5.6.
#' \url{https://github.com/itchyshin/clade}
#'
#' @keywords internal
#' @aliases clade-package
"_PACKAGE"
