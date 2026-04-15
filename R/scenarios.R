# ── Social and theoretical scenarios ─────────────────────────────────────────
#
# Functions here implement social/theoretical models that do not map onto the
# ecological evolutionary simulator (run_alife). They are standalone simulations
# that can be run independently and return data.frames for visualisation.

#' Simulate the evolution of scientific practice
#'
#' Implements the agent-based model from Smaldino & McElreath (2016).
#' "Labs" (agent groups) have heritable `research_power` (W; the probability
#' of detecting a real effect when the hypothesis under test is true) and
#' `research_effort` (e; methodological rigour, which lowers the per-test
#' false-positive rate). Each tick, a lab tests `n_studies_per_tick`
#' hypotheses, each of which is a priori true with probability
#' `base_rate_true` (b). Pub counts are
#'
#'   true positives  ~ Binomial(n_studies * b,       W)
#'   false positives ~ Binomial(n_studies * (1 - b), alpha(e))
#'
#' with `alpha(e) = alpha_base * (1 - e)`. The per-test FPR depends on
#' effort only, **not** on W, matching Smaldino & McElreath's formulation.
#' Labs with more publications reproduce at higher rates. If
#' `replication_rate > 0`, each lab has that probability per tick of
#' replicating a random peer's random finding; a failed replication
#' (original was a false positive, which happens with probability
#' `alpha(1-b) / (Wb + alpha(1-b))`) debits the original lab's
#' publication count by `replication_penalty`. With a large enough
#' penalty, replication culture selects against low-effort labs and
#' slows or reverses the evolution of high FPR.
#'
#' @param n_labs Integer; number of labs. Default 200.
#' @param n_ticks Integer; number of evolutionary ticks to run. Default 500.
#' @param n_studies_per_tick Integer; studies produced per lab per tick. Default 5.
#' @param replication_rate Numeric in \[0, 1\]; probability per tick that a lab
#'   attempts to replicate one of a random neighbour's published findings.
#'   A failed replication (original was a false positive) debits the original
#'   lab's publication count by `replication_penalty`. Default 0.
#' @param replication_penalty Numeric \eqn{\geq 0}; publication credits
#'   subtracted from the original lab when a replication attempt fails. Set to
#'   0 to recover the "replication without cost" behaviour. Default 5.
#' @param alpha_base Numeric in (0, 1\]; per-test false-positive rate at zero
#'   effort. FPR at effort `e` is `alpha_base * (1 - e)`. Default 0.5,
#'   matching Smaldino & McElreath's \eqn{\alpha_0}.
#' @param base_rate_true Numeric in (0, 1); prior probability that a tested
#'   hypothesis is genuinely true. Default 0.3. Higher values mean a larger
#'   share of publications are true positives, which sharpens replication's
#'   ability to discriminate low-effort labs; very low values (< 0.15) swamp
#'   replication's signal because almost every publication is a false
#'   positive regardless of effort.
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
                             replication_penalty      = 5.0,
                             alpha_base               = 0.5,
                             base_rate_true           = 0.3,
                             research_power_init_mean = 0.3,
                             research_effort_init_mean= 0.8,
                             mutation_sd              = 0.05,
                             seed                     = NULL) {
  n_labs  <- as.integer(n_labs)
  n_ticks <- as.integer(n_ticks)
  n_studies_per_tick <- as.integer(n_studies_per_tick)

  stopifnot(n_labs >= 2L, n_ticks >= 1L, n_studies_per_tick >= 1L)
  stopifnot(replication_rate >= 0, replication_rate <= 1)
  stopifnot(replication_penalty >= 0)
  stopifnot(alpha_base > 0, alpha_base <= 1)
  stopifnot(base_rate_true > 0, base_rate_true < 1)

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
    # Per-lab FPR depends on effort only (Smaldino & McElreath 2016 eq. 1):
    # high effort ⇒ low alpha.
    alpha <- alpha_base * pmax(0, 1 - effort)

    # Per tick, each lab tests n_studies_per_tick hypotheses. Each is a priori
    # true with probability base_rate_true. Publishable findings are
    #   true positives  ~ Binomial(n_true_hyp, power)
    #   false positives ~ Binomial(n_false_hyp, alpha)
    n_true_hyp  <- rbinom(n_labs, n_studies_per_tick, base_rate_true)
    n_false_hyp <- n_studies_per_tick - n_true_hyp
    n_true      <- rbinom(n_labs, n_true_hyp,  power)
    n_false     <- rbinom(n_labs, n_false_hyp, alpha)
    new_pubs    <- n_true + n_false
    pubs        <- pubs + new_pubs

    # Replication: a random pub from lab j is false-positive with probability
    # alpha_j(1-b) / (W_j b + alpha_j(1-b)). Failed replications debit the
    # original lab's pubs by replication_penalty (Smaldino & McElreath 2016
    # §"Replication"). Guarded against divide-by-zero when a lab has no
    # expected pubs this tick.
    failed_reps <- 0L
    if (replication_rate > 0) {
      tp_rate <- power * base_rate_true
      fp_rate <- alpha * (1 - base_rate_true)
      p_false_given_pub <- ifelse(tp_rate + fp_rate > 0,
                                  fp_rate / (tp_rate + fp_rate),
                                  0)
      for (i in seq_len(n_labs)) {
        if (runif(1L) < replication_rate && n_labs > 1L) {
          j <- sample(setdiff(seq_len(n_labs), i), 1L)
          if (runif(1L) < p_false_given_pub[j]) {
            failed_reps <- failed_reps + 1L
            pubs[j] <- max(0L, pubs[j] -
                           as.integer(round(replication_penalty)))
          }
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
