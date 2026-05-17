# Shared helper(s) for dev/audit/fidelity/paper_*.R scripts.
#
# Each script sources this file near the top:
#     source("dev/audit/fidelity/_helper.R")
# and then calls `.fidelity_cores(default = NL)` instead of hard-
# coding a literal `n_cores = NL`. This lets CI (and any developer
# with a smaller machine than the script author) override the
# parallelism without editing the script:
#
#     CLADE_FIDELITY_NCORES=2 Rscript dev/audit/fidelity/paper_emlen_1982.R
#
# Motivation: GitHub Actions ubuntu-latest runners have 4 cores and
# ~16 GB RAM. A PSOCK worker spawns its own Julia process
# (~500 MB RAM, ~60-90s JIT warmup). Hard-coded `n_cores = 32L` on
# a 4-core / 16 GB box → OOM at ~18 min (observed in
# fidelity-matrix smoke test, run #25993163288, paper_emlen_1982
# job). Honouring an env var keeps the local-author defaults intact
# while giving CI a knob to dial parallelism down to safe levels.

.fidelity_cores <- function(default = 1L) {
  env_val <- Sys.getenv("CLADE_FIDELITY_NCORES", unset = NA_character_)
  if (!is.na(env_val) && nzchar(env_val)) {
    n <- suppressWarnings(as.integer(env_val))
    if (!is.na(n) && n >= 1L) return(n)
  }
  as.integer(default)
}
