# ── Custom module registry ────────────────────────────────────────────────────
#
# Allows users to inject R functions into the clade Julia tick loop at named
# hook points. Custom modules can read and modify agent energy, alive status,
# and the grass matrix. They cannot add new Agent fields (the Julia struct is
# fixed at compile time).
#
# Usage:
#   register_module(fn, when = "post_tick", name = "my_module")
#   env <- run_alife(default_specs())
#   clear_modules()
#
# Hook points (value of `when`):
#   "pre_tick"      — before grow_grass! (first step of each tick)
#   "post_agents"   — after tick_agents! (movement + eating complete)
#   "post_tick"     — after all modules but before kill_dead! / reproduce
#   "post_reproduce"— after create_offspring!, before log_tick!
#
# Performance: each hook call marshals the env snapshot across the R-Julia
# boundary once per tick. Keep custom modules lightweight (< 1ms per tick).
# For 200 agents × 500 ticks, the overhead is ~0.5–1s total.

# Package-level environment storing registered custom modules
.clade_custom_modules <- new.env(parent = emptyenv())
.clade_custom_modules$modules <- list()

#' Register a custom module function
#'
#' Injects an R function into the clade simulation tick loop at the specified
#' hook point. The function receives a simplified environment snapshot
#' (`list(agents, grass, t, specs)`) and must return it (modified or
#' unmodified). Multiple modules may be registered at the same hook point;
#' they run in registration order.
#'
#' Custom modules can modify:
#' - `env$agents[[i]]$energy` — agent energy
#' - `env$agents[[i]]$alive` — set to `FALSE` to kill an agent
#' - `env$grass` — resource matrix (numeric matrix, rows x cols)
#'
#' @param fn A function with signature `function(env) -> env`.
#' @param when Character; one of `"pre_tick"`, `"post_agents"`,
#'   `"post_tick"`, `"post_reproduce"`. Default `"post_tick"`.
#' @param name Character label for the module (optional; used in
#'   [list_modules()] output).
#'
#' @return Invisibly `NULL`. Side-effects: adds to the module registry.
#'
#' @seealso [list_modules()], [clear_modules()], [run_alife()]
#' @examples
#' # Kill any agent older than 100 ticks
#' register_module(
#'   fn   = function(env) {
#'     for (i in seq_along(env$agents)) {
#'       if (isTRUE(env$agents[[i]]$age > 100)) env$agents[[i]]$alive <- FALSE
#'     }
#'     env
#'   },
#'   when = "post_tick",
#'   name = "max_age_100"
#' )
#' clear_modules()
#' @export
register_module <- function(fn, when = "post_tick", name = NULL) {
  valid_whens <- c("pre_tick", "post_agents", "post_tick", "post_reproduce")
  if (!is.character(when) || length(when) != 1L || !when %in% valid_whens)
    stop(sprintf(
      "register_module(): `when` must be one of {%s}.",
      paste(valid_whens, collapse = ", ")), call. = FALSE)
  if (!is.function(fn))
    stop("register_module(): `fn` must be a function.", call. = FALSE)

  if (is.null(name)) name <- paste0("module_", length(.clade_custom_modules$modules) + 1L)

  .clade_custom_modules$modules <- c(
    .clade_custom_modules$modules,
    list(list(fn = fn, when = when, name = name))
  )
  invisible(NULL)
}

#' List registered custom modules
#'
#' Returns a character vector of registered module names and their hook points.
#'
#' @return A character vector: `"name (when)"` for each registered module.
#'   Returns `character(0)` if no modules registered.
#'
#' @seealso [register_module()], [clear_modules()]
#' @export
list_modules <- function() {
  mods <- .clade_custom_modules$modules
  if (length(mods) == 0L) return(character(0L))
  vapply(mods, function(m) paste0(m$name, " (", m$when, ")"), character(1L))
}

#' Remove all registered custom modules
#'
#' Clears the module registry. Call this after `run_alife()` completes if you
#' do not want the modules applied in subsequent runs.
#'
#' @return Invisibly `NULL`.
#'
#' @seealso [register_module()], [list_modules()]
#' @export
clear_modules <- function() {
  .clade_custom_modules$modules <- list()
  invisible(NULL)
}

# ── Internal: apply custom modules to an R env snapshot ──────────────────────

#' Apply all registered custom modules at a given hook point
#'
#' Called by the simulation engine when a hook point is reached. Runs each
#' registered module in order. Errors are caught and re-raised as warnings
#' so the simulation continues.
#'
#' @param env_snap A list snapshot of the environment.
#' @param when Character; the current hook point.
#' @return The (possibly modified) env snapshot.
#' @keywords internal
.apply_custom_modules <- function(env_snap, when) {
  mods <- .clade_custom_modules$modules
  for (m in mods) {
    if (m$when != when) next
    env_snap <- tryCatch(
      m$fn(env_snap),
      error = function(e) {
        warning(sprintf(
          "Custom module '%s' (hook '%s') raised an error: %s",
          m$name, when, conditionMessage(e)), call. = FALSE)
        env_snap   # return unchanged snapshot on error
      }
    )
  }
  env_snap
}
