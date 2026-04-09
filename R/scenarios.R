# ── Social and theoretical scenarios ─────────────────────────────────────────
#
# Functions here implement social/theoretical models that do not map onto the
# ecological evolutionary simulator (run_alife). They are standalone simulations
# that can be run independently and return data.frames for visualisation.

#' Simulate the evolution of scientific practice
#'
#' Implements the agent-based model from Smaldino & McElreath (2016).
#' "Labs" (agent groups) have heritable `research_power` (W; the probability
#' that a given study tests a true hypothesis) and `research_effort` (e;
#' investment in methodological rigour). The false-positive rate per study is
#'
#'   alpha = W / (1 + (1 - W) * e)
#'
#' Each tick, each lab produces `n_studies_per_tick` studies yielding some
#' mix of true positives (probability W) and false positives (probability
#' alpha among studies that did not find a true effect). Labs with more
#' publications reproduce at higher rates. Optional replication attempts slow
#' but do not stop the deterioration of research standards.
#'
#' @param n_labs Integer; number of labs. Default 200.
#' @param n_ticks Integer; number of evolutionary ticks to run. Default 500.
#' @param n_studies_per_tick Integer; studies produced per lab per tick. Default 5.
#' @param replication_rate Numeric in \[0, 1\]; probability per tick that a lab
#'   attempts to replicate one of a random neighbour's published findings.
#'   Replication does not penalise false positives; it only tracks `failed_reps`
#'   (attempts that fail because the original was a false positive). Default 0.
#' @param research_power_init_mean Numeric; initial mean research power W.
#'   Default 0.3.
#' @param research_effort_init_mean Numeric; initial mean research effort e.
#'   Default 0.8.
#' @param mutation_sd Numeric; standard deviation of Gaussian mutation applied
#'   to both traits at reproduction. Default 0.05.
#' @param seed Integer or `NULL`; random seed for reproducibility. Default `NULL`.
#'
#' @return A data frame with one row per tick and columns:
#' \describe{
#'   \item{`t`}{Tick number.}
#'   \item{`mean_power`}{Mean `research_power` across labs.}
#'   \item{`mean_effort`}{Mean `research_effort` across labs.}
#'   \item{`mean_fpr`}{Mean false-positive rate `alpha` across labs.}
#'   \item{`total_publications`}{Total publications produced this tick.}
#'   \item{`failed_replications`}{Number of failed replication attempts.}
#' }
#'
#' @references
#' Smaldino, P.E. & McElreath, R. (2016) The natural selection of bad science.
#'   Royal Society Open Science 3:160384. doi:10.1098/rsos.160384
#'
#' @examples
#' result <- run_bad_science(n_ticks = 200L, seed = 1L)
#' plot(result$t, result$mean_fpr, type = "l",
#'      xlab = "Tick", ylab = "Mean false-positive rate",
#'      main = "Evolution of bad science")
#' @importFrom stats rbinom
#' @export
run_bad_science <- function(n_labs                   = 200L,
                             n_ticks                  = 500L,
                             n_studies_per_tick       = 5L,
                             replication_rate         = 0.0,
                             research_power_init_mean = 0.3,
                             research_effort_init_mean= 0.8,
                             mutation_sd              = 0.05,
                             seed                     = NULL) {
  n_labs  <- as.integer(n_labs)
  n_ticks <- as.integer(n_ticks)
  n_studies_per_tick <- as.integer(n_studies_per_tick)

  stopifnot(n_labs >= 2L, n_ticks >= 1L, n_studies_per_tick >= 1L)
  stopifnot(replication_rate >= 0, replication_rate <= 1)

  if (!is.null(seed)) set.seed(seed)

  # Initialise labs
  power  <- pmax(0.01, pmin(0.99, rnorm(n_labs, research_power_init_mean,  mutation_sd)))
  effort <- pmax(0.01, pmin(0.99, rnorm(n_labs, research_effort_init_mean, mutation_sd)))
  pubs   <- integer(n_labs)

  # Pre-allocate output
  out <- data.frame(
    t                   = integer(n_ticks),
    mean_power          = numeric(n_ticks),
    mean_effort         = numeric(n_ticks),
    mean_fpr            = numeric(n_ticks),
    total_publications  = integer(n_ticks),
    failed_replications = integer(n_ticks)
  )

  for (tick in seq_len(n_ticks)) {
    # Per-lab false-positive rates
    alpha <- power / (1 + (1 - power) * effort)

    # Publications: true positives + false positives
    n_true <- pmin(n_studies_per_tick,
                   rbinom(n_labs, n_studies_per_tick, power))
    n_false <- rbinom(n_labs, n_studies_per_tick - n_true, alpha)
    new_pubs <- n_true + n_false
    pubs     <- pubs + new_pubs

    # Replication
    failed_reps <- 0L
    if (replication_rate > 0) {
      for (i in seq_len(n_labs)) {
        if (runif(1L) < replication_rate && n_labs > 1L) {
          j <- sample(setdiff(seq_len(n_labs), i), 1L)
          # A replication attempt succeeds if the original finding was a true
          # positive (probability = power[j]); fails if false positive.
          if (runif(1L) > power[j]) failed_reps <- failed_reps + 1L
        }
      }
    }

    out$t[tick]                   <- tick
    out$mean_power[tick]          <- mean(power)
    out$mean_effort[tick]         <- mean(effort)
    out$mean_fpr[tick]            <- mean(alpha)
    out$total_publications[tick]  <- sum(new_pubs)
    out$failed_replications[tick] <- failed_reps

    # Reproduction: top 50% by cumulative publications reproduce;
    # offspring replace the bottom 50% with heritable + mutated traits.
    rank_order <- order(pubs, decreasing = TRUE)
    n_repro    <- n_labs %/% 2L
    parents    <- rank_order[seq_len(n_repro)]
    replaced   <- rank_order[seq(n_repro + 1L, n_labs)]

    # Each "child" inherits from a randomly chosen parent
    parent_idx <- sample(parents, length(replaced), replace = TRUE)
    power[replaced]  <- pmax(0.01, pmin(0.99,
      power[parent_idx]  + rnorm(length(replaced), 0, mutation_sd)))
    effort[replaced] <- pmax(0.01, pmin(0.99,
      effort[parent_idx] + rnorm(length(replaced), 0, mutation_sd)))
    pubs[replaced]   <- pubs[parent_idx] %/% 2L   # offspring inherit half pubs
  }

  out
}
