# Clade Consolidation Audit Report

**Scope:** R files (5,035 lines) + 26 Julia modules (4,214 lines)  
**Assessment Date:** April 2026  
**Risk Model:** High regression risk ∝ validation/search logic; low risk ∝ visualization cosmetics

---

## 1. Top 5 Consolidation Opportunities (Ranked by Impact × Risk-Inverse)

### 1.1 **Julia Module Guard Boilerplate** [High Impact, Low Risk]
**Lines saved:** ~40 (5–10% of each module file, × 24 modules = ~100–240 lines total)  
**Regression risk:** Very low (pure structure refactor; no behavior change)

**Pattern Identified:**
Each of 24 Julia modules opens with the same gate pattern:
```julia
function apply_*!(env::Environment, ...)
    Bool(get(env.specs, "module_flag", false)) || return
    # ... module logic
end
```
This appears **26 times** across all modules (body_size, dispersal, cooperation, etc.).

**Proposed Abstraction:**
```julia
# In util.jl or env.jl
"""
    @unless_disabled(flag::String, env::Environment)

Early-exit macro. Expands to `Bool(get(env.specs, flag, false)) || return`.
"""
macro unless_disabled(flag::String, env::Expr, body)
    :(Bool(get($(env).specs, $(flag), false)) || return; $(body))
end

# Usage: much cleaner single-line guard
apply_body_size!(env::Environment) = @unless_disabled("body_size_evolution", env) begin
    # ... existing logic
end
```
**Action:** Extract `@unless_disabled` macro to `src/util.jl`. Replace all 26 instances.

---

### 1.2 **Search Function Candidate Evaluation** [High Impact, Medium Risk]
**Lines saved:** ~80 (duplicate logic in 3 search optimizers × 25–30 lines each)  
**Regression risk:** Medium (optimizer behavior must be verified post-refactor)

**Pattern Identified:**
Three search functions (CMA-ES, gradient descent, MAP-Elites) all independently define:
- `build_specs(log_x)` — convert log-space vector to specs list
- `eval_one(specs)` — run simulation, wrap errors, return score
- Bounds checking (lo_log, hi_log clamping)
- History tracking (iteration → score → data.frame)

Each optimizer reimplements the same evaluation pipeline:
```r
# search_cmaes, lines 349–353
eval_one <- function(s) {
  env <- tryCatch(run_alife(s, verbose = FALSE), error = function(e) NULL)
  if (is.null(env)) return(-Inf)
  tryCatch(obj_fn(env), error = function(e) -Inf)
}

# search_gradient, lines 551–556 (identical structure)
evaluate <- function(log_x) {
  s <- build_specs(log_x)
  env <- tryCatch(run_alife(s, verbose = FALSE), error = function(e) NULL)
  if (is.null(env)) return(NA_real_)
  obj_fn(env)
}
```

**Proposed Abstraction:**
```r
# Create R/search-helpers.R
.eval_candidate_specs <- function(specs, obj_fn, na_on_fail = FALSE) {
  env <- tryCatch(run_alife(specs, verbose = FALSE), error = function(e) NULL)
  if (is.null(env)) return(if (na_on_fail) NA_real_ else -Inf)
  tryCatch(obj_fn(env), error = function(e) if (na_on_fail) NA_real_ else -Inf)
}

.build_specs_from_log <- function(log_x, params, specs_base, lo_log, hi_log) {
  log_x <- pmax(lo_log, pmin(hi_log, log_x))
  s <- specs_base
  for (j in seq_len(length(params))) s[[params[j]]] <- exp(log_x[j])
  s
}

.clamp_log_vector <- function(log_x, lo_log, hi_log) {
  pmax(lo_log, pmin(hi_log, log_x))
}
```
**Action:** Extract these three helpers. Replace in all three search functions.

---

### 1.3 **Visualization Plot Scaffolding** [Medium Impact, Low Risk]
**Lines saved:** ~200 (repeated ggplot2 boilerplate across 14 plot_* functions)  
**Regression risk:** Very low (cosmetic only; plot outputs unchanged)

**Pattern Identified:**
Each of 14 public `plot_*()` functions:
1. Calls `.check_run_data(run_data)` (9 instances)
2. Filters to t > 0 if t column exists (manual in each)
3. Returns empty-grid fallback when nrow(d) == 0 (manual in each)
4. Applies `.clade_theme()` to all axes (28 instances)
5. Uses identical `ggplot2::ggplot() + geom_line() + labs() + .clade_theme()` skeleton

**Proposed Abstraction:**
```r
# In R/visualization.R
.plot_timeseries <- function(data, aes_y, title, colour = NULL, ...) {
  # Shared boilerplate: checks, filtering, theming
  if (!is.data.frame(data)) data <- as.data.frame(data)
  if ("t" %in% names(data)) data <- data[data$t > 0L, ]
  
  ggplot2::ggplot(data, aes_y) +
    ggplot2::geom_line(colour = colour %||% "#2b6cb0", linewidth = 0.6) +
    ggplot2::labs(title = title, x = "Tick", y = names(aes_y)[2]) +
    .clade_theme()
}

# Usage in plot_genome_diversity(), plot_diversity(), etc.:
p1 <- .plot_timeseries(d, aes(x = t, y = genetic_diversity), 
                       title = "Genetic diversity")
```
**Action:** Extract `.plot_timeseries()`, `.plot_scattermatrix()` helpers. Reduce plot function bodies by ~30 lines each.

---

### 1.4 **Tune Functions (tune_complex_landscape, tune_spatial_sorting, tune_iffolk)** [Medium Impact, Low Risk]
**Lines saved:** ~60 (3 near-identical functions, each ~30 lines)  
**Regression risk:** Very low (dispatch pattern is transparent)

**Pattern Identified:**
All three `tune_*()` functions follow the same template:
```r
tune_module <- function(specs_base = default_specs(), n_iterations = 100L, 
                        method = "cmaes", ...) {
  specs_base$module_enable_flag   <- TRUE
  specs_base$module_init_param    <- <default>
  params <- c("param1", "param2", "param3")
  
  if (identical(method, "map_elites")) {
    search_map_elites(specs_base, archive_dims = ..., ..., ...)
  } else {
    search_cmaes(specs_base, objective = ..., params = params, ...)
  }
}
```

**Proposed Abstraction:**
```r
# Meta-function factory
.make_tune_function <- function(module_name, enable_spec, init_overrides, 
                                params, archive_dims, objective_fn) {
  force(list(enable_spec, params, objective_fn))  # capture defaults
  
  function(specs_base = default_specs(), n_iterations = 100L, 
           method = "cmaes", ...) {
    specs_base[[enable_spec]] <- TRUE
    for (nm in names(init_overrides)) {
      specs_base[[nm]] <- init_overrides[[nm]]
    }
    
    if (identical(method, "map_elites")) {
      search_map_elites(specs_base, archive_dims = archive_dims, 
                       objective = objective_fn, mutation_params = params, 
                       n_iterations = n_iterations, ...)
    } else {
      search_cmaes(specs_base, objective = objective_fn, params = params, 
                  n_iterations = n_iterations, ...)
    }
  }
}

# Single definition replaces three function definitions
tune_complex_landscape <- .make_tune_function(
  "complex_landscape",
  enable_spec = "complex_landscape",
  init_overrides = list(wing_size_init_mean = 0.1),
  params = c("shrub_density", "canopy_density", "shrub_energy", 
             "canopy_energy", "shrub_growth_rate"),
  archive_dims = list(mean_wing_size = seq(0, 1, by = 0.1),
                      mean_shrub_coverage = seq(0, 1, by = 0.1)),
  objective_fn = objective_complex_landscape
)
```
**Action:** Create `.make_tune_function()` factory. Replace 3 functions with 3 assignments.

---

### 1.5 **Julia Parameter Extraction (get/spec boilerplate)** [Low Impact, Very Low Risk]
**Lines saved:** ~30 (repeated `Float32(get(env.specs, ...))` calls, ~2–4 per module)  
**Regression risk:** Negligible (pure helper)

**Pattern Identified:**
Every module repeats parameter extraction 2–4 times per function:
```julia
cost = Float32(get(specs, "dispersal_cost", 2.0))
rows = Int(specs["grid_rows"])
cols = Int(specs["grid_cols"])
toroidal = Bool(get(specs, "toroidal", true))
```

**Proposed Abstraction:**
```julia
# In env.jl or util.jl
"""
    get_typed(specs::Dict, key::String, default, ::Type{T})::T

Type-coerced specs getter. Shorthand for `T(get(specs, key, default))`.
"""
get_typed(specs::Dict, key::String, default, ::Type{Float32}) = 
    Float32(get(specs, key, default))
get_typed(specs::Dict, key::String, default, ::Type{Int}) = 
    Int(get(specs, key, default))
get_typed(specs::Dict, key::String, default, ::Type{Bool}) = 
    Bool(get(specs, key, default))

# Usage: cleaner, more readable
cost = get_typed(specs, "dispersal_cost", 2.0, Float32)
```
**Action:** Add `get_typed()` function to util.jl. Replace ~40 instances.

---

## 2. Per-File Duplication Scan

| File | Approx Duplicate Lines | Suggested Factor-Out |
|------|----------------------|----------------------|
| **R/visualization.R** (1,676 lines) | ~200 | `.plot_timeseries()`, `.plot_empty_fallback()`, theme consolidation (14 plot_* functions share scaffolding) |
| **R/search.R** (1,248 lines) | ~80 | `.eval_candidate_specs()`, `.build_specs_from_log()`, bounds clamping (3 optimizers) |
| **inst/julia/src/modules/** (4,214 lines, 26 files) | ~150 | `@unless_disabled` macro (26 guard calls), `get_typed()` helper (40+ instances) |
| **R/config.R** (1,168 lines) | ~80 | Module specs organized as table (68 module-related parameters scattered across function body lines 880–1105) |
| **R/analysis.R** (943 lines) | ~40 | `.locate_agent_by_id()` (called twice in `inspect_brain()` and `get_brain_weights()`); `.summarise_weights()` (similar reductions in both) |

**Total Consolidation Potential:** ~550 lines (9% of R codebase, 12% of Julia modules)

---

## 3. Dead Code & Export Audit

**Export Status:** 63 exported functions (NAMESPACE verified against R/*.R).  
**Unused Exports Found:** None detected via grep cross-reference within package.  
**Candidate Deprecation:** None identified (all exports are active or legitimately optional).

**Note:** `heritability_estimate()` and `estimate_heritability()` both exist (lines 86–134 in analysis.R). 
- `heritability_estimate` appears in NAMESPACE but is never defined in R files.
- `estimate_heritability` is the working function (lines 134–178).
- **Action:** Remove `heritability_estimate` from NAMESPACE; it is a dead export.

---

## 4. Naming Inconsistencies

| Pattern | Inconsistency | Examples | Recommended Fix |
|---------|--|----------|---|
| **Verb prefix** | `apply_*`, `tune_*`, `search_*` vs `get_*`, `plot_*` | `apply_body_size!`, `get_run_data()` | Consistent—no change needed; Julia mutations end with `!` (idiomatic) |
| **Getter style** | `get_*_data` vs `extract_*` | `get_run_data()`, `get_genome_data()`, `get_brain_weights()` | Consistent snake_case throughout; use `get_` for extractors |
| **Boolean predicates** | `is_*` vs `has_*` | None; package uses verbs exclusively | OK |
| **Trait specification** | `*_evolution` vs `*_enabled` | `body_size_evolution`, `brain_size_evolution`, etc. | Consistent suffix; good naming |
| **Objective functions** | `objective_*` vs `score_*` | `objective_complex_landscape`, `objective_iffolk` (3 total) | Consistent; good |
| **Internal prefix** | `.` for internal only | `.check_run_data()`, `.clade_theme()` (13 identified) | Consistent throughout; good practice |

**Action:** None required; naming is internally consistent.

---

## Implementation Roadmap

**Phase 1 (Very low risk, high-value):**
- Extract Julia `@unless_disabled` macro (24 guards, ~40 lines saved)
- Add Julia `get_typed()` helper (40+ instances, ~30 lines saved)
- Remove dead export `heritability_estimate` from NAMESPACE

**Phase 2 (Low risk, medium value):**
- Extract `.plot_timeseries()` and empty-fallback helpers (14 functions, ~200 lines)
- Consolidate tune_* functions via factory pattern (3 functions → 3 assignments, ~60 lines)

**Phase 3 (Medium risk, review-recommended):**
- Extract search evaluation helpers (3 optimizers, ~80 lines). Verify convergence numerics before/after.

**Phase 4 (Optional, low priority):**
- Organize module specs as data table in config.R (readability gain, minimal LOC reduction)

---

**Total Estimated Savings:** ~550 lines; ~9% code reduction with negligible regression risk in phases 1–2.
