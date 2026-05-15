# Package startup: initialise the Julia session and load the Clade.jl module.
#
# JuliaConnectoR (Lenz & Csala 2021) starts a persistent Julia process when
# the R package is first loaded and keeps it alive for the session. All
# subsequent calls to run_alife() cross the R-Julia boundary exactly once
# (send specs, receive results) rather than once per tick.
#
# Reference: Lenz & Csala (2021) JuliaConnectoR: A functionally oriented
# interface between R and Julia, *Journal of Statistical Software* 101(6).

.clade_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Defer actual Julia startup until first use to keep library() fast.
  # The Julia session is started on first call to .clade_julia() below.
  .clade_env$julia_ready   <- FALSE
  .clade_env$julia_version <- NA_character_
}

#' Start the Julia session and load Clade.jl (called automatically)
#'
#' This function is called once, on the first call to [run_alife()]. It
#' starts a Julia process via JuliaConnectoR, activates the Clade.jl Julia
#' project, and imports the module. First-call startup takes roughly
#' **60-90 seconds** (Julia JIT compilation of the full kernel);
#' subsequent calls within the same R session are instant.
#'
#' @param verbose Logical. Print startup messages (default `TRUE`).
#' @return Invisibly, the result of `JuliaConnectoR::juliaEval("true")` as a
#'   connectivity check.
#' @keywords internal
.clade_start_julia <- function(verbose = TRUE) {
  if (.clade_env$julia_ready) return(invisible(TRUE))

  if (!requireNamespace("JuliaConnectoR", quietly = TRUE)) {
    stop(
      "Package 'JuliaConnectoR' is required to run clade simulations.\n",
      "Install it with: install.packages('JuliaConnectoR')",
      call. = FALSE
    )
  }

  if (verbose) message("clade: starting Julia session...")

  # Locate the bundled Julia project inside the installed package
  julia_project <- system.file("julia", package = "clade", mustWork = TRUE)

  # Activate the project so Project.toml is honoured
  JuliaConnectoR::juliaEval(
    sprintf('import Pkg; Pkg.activate("%s", io=devnull)',
            gsub("\\\\", "/", julia_project))
  )
  JuliaConnectoR::juliaEval('import Pkg; Pkg.instantiate(io=devnull)')

  # Load the Clade module
  src_path <- file.path(julia_project, "src", "Clade.jl")
  JuliaConnectoR::juliaEval(
    sprintf('include("%s")', gsub("\\\\", "/", src_path))
  )

  # Record Julia version for diagnostics
  ver <- JuliaConnectoR::juliaEval('string(VERSION)')
  .clade_env$julia_version <- ver
  .clade_env$julia_ready   <- TRUE

  if (verbose) {
    message(sprintf("clade: Julia %s ready.", ver))
  }

  invisible(TRUE)
}

#' Check whether the Julia session is active
#'
#' @return Logical.
#' @export
julia_is_ready <- function() isTRUE(.clade_env$julia_ready)

#' Report the Julia version used by clade
#'
#' @return Character scalar, e.g. `"1.10.0"`, or `NA` if Julia has not been
#'   started yet.
#' @export
julia_version <- function() .clade_env$julia_version
