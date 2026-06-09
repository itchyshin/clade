# Independent R reimplementation of the Rees-Baylis et al. 2026 (Nat
# Commun) analytical two-sex matrix population model with adaptive
# dynamics. The authors' canonical MATLAB code is on Figshare; this
# script reimplements the equations directly from the paper's Methods
# (Table 1 parameters, eqs 1-19 baseline monogamy + eq 27 life
# expectancy).
#
# Targets: Fig 2 a, b, c (heatmaps of L_m, L_f, and relative
# difference across the 5x5 (s_m^M, s_f^O) grid) + Fig 2 d/e/f
# (same data as scatter vs log10(s_m/s_f)).
#
# Output: dev/audit/fidelity/paper_rees_baylis_2026_analytical.rds
# + PNG plots under vignettes/figures/.
#
# Runtime: roughly 20-40 min on 8 cores at omega = 20.

suppressMessages({
  library(parallel)
  library(ggplot2)
  library(scales)
})

# ── Table 1 parameters ───────────────────────────────────────────────────────

OMEGA <- 20L     # number of age classes
B_RATE <- 0.6    # Gompertz slope (eq 1)
G_MAT <- 5.0     # maturation shape (eq 4)
H_MAT <- 2.5
ETA   <- 0.8     # mating efficiency (eq 6)
K_FEC <- 4       # max annual union fecundity (eqs 8, 9)
R_SR  <- 0.5     # primary sex ratio (proportion male)
D_DIV <- 0       # divorce per tick (eqs 10-12)
SIGMA <- 0.1     # mutational step size
NU    <- 1e-4    # density-regulation strength (eqs 17, 27)

TRADEOFF_GRID <- c(0.01, 0.03, 0.05, 0.07, 0.10)  # Table 1 sweep

# Convergence settings
AD_STEPS        <- 600L   # adaptive-dynamics iterations per cell
EQUIL_TICKS     <- 400L   # ticks to reach demographic equilibrium
MUTANT_TICKS    <- 200L   # ticks to measure mutant growth rate
N_CORES         <- min(8L, parallel::detectCores() - 2L)

# ── Helper functions ─────────────────────────────────────────────────────────

# Maturation function (eq 4): alpha_x = 1 / (1 + exp(g - h*x))
alpha_vec <- function(omega = OMEGA) 1 / (1 + exp(G_MAT - H_MAT * seq_len(omega)))

# Survival (eq 1): u_i(x) = exp(-int_{x}^{x+1} b * exp(b*(y - M)) dy)
#                        = exp(-(exp(b*(x+1-M)) - exp(b*(x-M))))
survival_vec <- function(M, omega = OMEGA, b = B_RATE) {
  x <- seq_len(omega)
  u <- exp(-(exp(b * (x + 1 - M)) - exp(b * (x - M))))
  u[omega] <- 0   # everyone dies at max age (omega+1 doesn't exist)
  u
}

# Mating function (eq 6, min-harmonic): expected number of new unions
# from f singles + m singles. The two-branch formulation handles
# operational sex-ratio skew.
n_unions <- function(f_avail, m_avail, eta = ETA) {
  N <- f_avail + m_avail
  if (N <= 0) return(0)
  ratio <- f_avail / N
  if (ratio <= eta - 0.5 || ratio >= 1.5 - eta) {
    return(min(f_avail, m_avail))
  }
  (f_avail * m_avail / N - N * (ratio - 0.5)^2) / (2 * (1 - eta))
}

# ── State and tick step ──────────────────────────────────────────────────────
#
# State is a list: m (ω-vector of single males per age), f (ω-vector of
# single females per age), u (ω x ω matrix; u[x, y] = unions of female
# age x and male age y).

make_initial_state <- function(omega = OMEGA, n_init = 100) {
  # Spread initial population across age classes; small noise in u.
  m <- rep(n_init / omega, omega)
  f <- rep(n_init / omega, omega)
  u <- matrix(0, omega, omega)
  list(m = m, f = f, u = u)
}

# One projection tick. Implements eq 17 with the block structure of
# eq 19 unrolled into per-component updates so the code can be read
# alongside the paper.
#
# Args:
#   state    : list(m, f, u)
#   M_m, M_f : age of senescence onsets for resident phenotypes
#   s_m_M    : male mating-survival trade-off strength
#   s_f_O    : female offspring-survival trade-off strength
#   density_reg : apply e^{-nu * N_r}
# Returns next state.
project_one_tick <- function(state, M_m, M_f, s_m_M, s_f_O,
                              density_reg = TRUE, omega = OMEGA) {
  m <- state$m; f <- state$f; u <- state$u

  N_r <- sum(m) + sum(f) + 2 * sum(u)
  dr  <- if (density_reg) exp(-NU * N_r) else 1

  u_m <- survival_vec(M_m, omega)
  u_f <- survival_vec(M_f, omega)
  av  <- alpha_vec(omega)

  # ── Singles available to mate (eqs 2, 3)
  m_ready_vec <- av * u_m * m
  f_ready_vec <- av * u_f * f
  m_avail <- sum(m_ready_vec)
  f_avail <- sum(f_ready_vec)

  # ── New unions (eq 7)
  U <- n_unions(f_avail, m_avail)
  mating_mod <- exp(-s_m_M * (M_m - 1))     # male trade-off (eq 7)

  if (f_avail > 0 && m_avail > 0 && U > 0) {
    # outer product divided by (f_avail * m_avail), times U, times male mod
    # Sum of new_u over (x,y) = mod_m * U (NOT U), because the male
    # trade-off reduces realised mating.
    new_u <- (outer(f_ready_vec, m_ready_vec * mating_mod) * U) /
             (f_avail * m_avail)
  } else {
    new_u <- matrix(0, omega, omega)
  }

  # ── Singles aging + survival, minus those who mated
  # Per-capita per-survived mating prob = α * mod_m * U / pool
  # (both sexes — total realised unions is mod_m * U).
  next_m <- numeric(omega); next_f <- numeric(omega)
  for (x in seq_len(omega - 1L)) {
    p_mate_m <- if (m_avail > 0) min(av[x] * mating_mod * U / m_avail, 1) else 0
    p_mate_f <- if (f_avail > 0) min(av[x] * mating_mod * U / f_avail, 1) else 0
    next_m[x + 1L] <- u_m[x] * m[x] * (1 - p_mate_m)
    next_f[x + 1L] <- u_f[x] * f[x] * (1 - p_mate_f)
  }

  # ── Existing-union dynamics: survival, dissolution, age advancement
  # Eq 10-12: union (x_f, y_m) survives both partners with prob u_f(x)*u_m(y)*(1-d).
  # Either-partner dies + divorce → widow returns to singles pool.
  next_u <- matrix(0, omega, omega)
  W_m_vec <- numeric(omega)
  W_f_vec <- numeric(omega)
  if (omega > 1L) {
    for (x in seq_len(omega - 1L)) {
      for (y in seq_len(omega - 1L)) {
        uxy <- u[x, y]
        if (uxy <= 0) next
        survive_both <- u_f[x] * u_m[y] * (1 - D_DIV)
        next_u[x + 1L, y + 1L] <- next_u[x + 1L, y + 1L] + uxy * survive_both
        # Widow returns: per eqs 11-12
        W_f_vec[x + 1L] <- W_f_vec[x + 1L] + uxy *
          (u_f[x] * (1 - u_m[y]) + D_DIV * u_f[x] * u_m[y])
        W_m_vec[y + 1L] <- W_m_vec[y + 1L] + uxy *
          (u_m[y] * (1 - u_f[x]) + D_DIV * u_f[x] * u_m[y])
      }
    }
  }

  # ── Offspring from existing (pre-step) unions (eqs 8, 9)
  fec_mod <- exp(-s_f_O * (M_f - 1))
  k_m <- K_FEC * R_SR * fec_mod
  k_f <- K_FEC * (1 - R_SR) * fec_mod
  total_old_unions <- sum(u)
  next_m[1L] <- next_m[1L] + total_old_unions * k_m
  next_f[1L] <- next_f[1L] + total_old_unions * k_f

  # ── Folder widows + new unions
  next_m <- next_m + W_m_vec
  next_f <- next_f + W_f_vec
  next_u <- next_u + new_u

  # ── Density regulation (eq 17)
  list(m = next_m * dr, f = next_f * dr, u = next_u * dr)
}

# ── Iterate to equilibrium ───────────────────────────────────────────────────

# Run T ticks from a starting state. Returns final state.
project_T <- function(state, M_m, M_f, s_m_M, s_f_O, T_ticks,
                       density_reg = TRUE, omega = OMEGA) {
  for (t in seq_len(T_ticks)) {
    state <- project_one_tick(state, M_m, M_f, s_m_M, s_f_O,
                               density_reg = density_reg, omega = omega)
  }
  state
}

# ── Adaptive dynamics ────────────────────────────────────────────────────────
#
# Standard ESS hill-climber: at each AD step,
#   1. compute resident equilibrium under (M_m, M_f)
#   2. test mutant invasion fitness for M_m ± sigma and M_f ± sigma:
#      - introduce a small mutant population (rare, no density effect on residents)
#      - simulate mutant for MUTANT_TICKS using the resident equilibrium pop sizes
#        for density regulation (e^{-nu N_resident})
#      - compute mutant growth rate = (final / initial)^(1/T)
#   3. accept the direction with highest growth rate > 1
# Alternates between mutating M_m and M_f loci.

# Proper rare-mutant invasion (paper's eq 19 specialised for the rare
# mutant). The key fix vs a naive simulation: mutants always pair with
# RESIDENTS (never each other), so mating opportunities come from the
# resident pool, not from the mutant's own tiny pool. Concretely, a
# mutant male's per-tick mating prob is α_y * u_m_mut(y) *
# exp(-s_m^M (M_m_mut - 1)) * U_res / m_avail_res — the resident
# numerator U_res / m_avail_res is what every male "sees", and only
# the mutant's own survival + trade-off modifier differ.
#
# State tracks mutant carriers in 4 compartments:
#   m_mut[ω], f_mut[ω]        — single mutant carriers per age
#   u_mr[x, y]                — unions with mutant male age y +
#                               resident female age x (mother RES,
#                               so fec uses resident M_f; offspring
#                               carry mutant allele w.p. 1/2)
#   u_rm[x, y]                — unions with resident male age y +
#                               mutant female age x (mother MUT, so
#                               fec uses M_f_mut; offspring carry
#                               mutant allele w.p. 1/2)
mutant_growth_rate <- function(M_m_mut, M_f_mut, s_m_M, s_f_O,
                                 M_m_res, M_f_res, resident_state,
                                 T_ticks = MUTANT_TICKS,
                                 omega = OMEGA) {
  N_r_res <- sum(resident_state$m) + sum(resident_state$f) +
             2 * sum(resident_state$u)
  if (N_r_res <= 0) return(0)
  dr <- exp(-NU * N_r_res)

  u_m_res <- survival_vec(M_m_res, omega)
  u_f_res <- survival_vec(M_f_res, omega)
  u_m_mut <- survival_vec(M_m_mut, omega)
  u_f_mut <- survival_vec(M_f_mut, omega)
  av      <- alpha_vec(omega)

  m_avail_res <- sum(av * u_m_res * resident_state$m)
  f_avail_res <- sum(av * u_f_res * resident_state$f)
  U_res       <- n_unions(f_avail_res, m_avail_res)

  if (m_avail_res <= 0 || f_avail_res <= 0 || U_res <= 0) return(0)

  # Resident-pool age-frequency vectors (for new union assignment)
  f_age_frac_res <- (av * u_f_res * resident_state$f) / f_avail_res
  m_age_frac_res <- (av * u_m_res * resident_state$m) / m_avail_res

  mod_m_mut   <- exp(-s_m_M * (M_m_mut - 1))
  mod_m_res   <- exp(-s_m_M * (M_m_res - 1))
  fec_mod_mut <- exp(-s_f_O * (M_f_mut - 1))
  fec_mod_res <- exp(-s_f_O * (M_f_res - 1))

  # Per-survived-mutant-male age y per-tick mating prob:
  # α_y * mod_m_mut * U_res / m_avail_res  (his own modifier).
  # Per-survived-mutant-female age x per-tick mating prob:
  # α_x * mod_m_res * U_res / f_avail_res  (RESIDENT male's modifier
  # — she mates with resident males, whose mod is mod_m_res).
  p_mate_m_mut <- pmin(av * mod_m_mut * U_res / m_avail_res, 1)
  p_mate_f_mut <- pmin(av * mod_m_res * U_res / f_avail_res, 1)

  # Initialise mutant: 0.5 single male + 0.5 single female at age 1.
  m_mut <- numeric(omega); m_mut[1] <- 0.5
  f_mut <- numeric(omega); f_mut[1] <- 0.5
  u_mr  <- matrix(0, omega, omega)
  u_rm  <- matrix(0, omega, omega)

  N0 <- 1.0

  for (t in seq_len(T_ticks)) {
    # ── New mutant-resident unions
    new_u_mr <- matrix(0, omega, omega)   # mutant male y × resident female x
    new_u_rm <- matrix(0, omega, omega)
    # Survived mutant males of age y entering unions per tick:
    #   u_m_mut(y) * m_mut[y] * p_mate_m_mut[y]
    # Distribute across resident-female ages x by f_age_frac_res.
    mat_per_age_y <- u_m_mut * m_mut * p_mate_m_mut
    if (any(mat_per_age_y > 0)) {
      new_u_mr <- outer(f_age_frac_res, mat_per_age_y)
    }
    mat_per_age_x <- u_f_mut * f_mut * p_mate_f_mut
    if (any(mat_per_age_x > 0)) {
      new_u_rm <- outer(mat_per_age_x, m_age_frac_res)
    }

    # ── Singles age + survive (minus those who mated)
    next_m_mut <- numeric(omega); next_f_mut <- numeric(omega)
    for (x in seq_len(omega - 1L)) {
      next_m_mut[x + 1L] <- u_m_mut[x] * m_mut[x] * (1 - p_mate_m_mut[x])
      next_f_mut[x + 1L] <- u_f_mut[x] * f_mut[x] * (1 - p_mate_f_mut[x])
    }

    # ── Existing-union dynamics (survival + widowing)
    next_u_mr <- matrix(0, omega, omega)
    next_u_rm <- matrix(0, omega, omega)
    W_mut_m   <- numeric(omega)
    W_mut_f   <- numeric(omega)
    if (omega > 1L) {
      for (x in seq_len(omega - 1L)) for (y in seq_len(omega - 1L)) {
        # u_mr: mutant male y × resident female x
        v <- u_mr[x, y]
        if (v > 0) {
          surv <- u_f_res[x] * u_m_mut[y] * (1 - D_DIV)
          next_u_mr[x + 1L, y + 1L] <- next_u_mr[x + 1L, y + 1L] + v * surv
          # Mutant male widowed: female dies OR divorce
          W_mut_m[y + 1L] <- W_mut_m[y + 1L] +
            v * (u_m_mut[y] * (1 - u_f_res[x]) + D_DIV * u_m_mut[y] * u_f_res[x])
        }
        # u_rm: resident male y × mutant female x
        v <- u_rm[x, y]
        if (v > 0) {
          surv <- u_f_mut[x] * u_m_res[y] * (1 - D_DIV)
          next_u_rm[x + 1L, y + 1L] <- next_u_rm[x + 1L, y + 1L] + v * surv
          W_mut_f[x + 1L] <- W_mut_f[x + 1L] +
            v * (u_f_mut[x] * (1 - u_m_res[y]) + D_DIV * u_f_mut[x] * u_m_res[y])
        }
      }
    }

    # ── Offspring (per existing unions; not new ones)
    # u_mr mother is RESIDENT → fecundity uses fec_mod_res
    # u_rm mother is MUTANT   → fecundity uses fec_mod_mut
    # Offspring inherit mutant allele with prob 0.5 in both cases.
    n_mr <- sum(u_mr); n_rm <- sum(u_rm)
    new_carriers_m <- 0.5 *
      (n_mr * K_FEC * R_SR       * fec_mod_res +
       n_rm * K_FEC * R_SR       * fec_mod_mut)
    new_carriers_f <- 0.5 *
      (n_mr * K_FEC * (1 - R_SR) * fec_mod_res +
       n_rm * K_FEC * (1 - R_SR) * fec_mod_mut)
    next_m_mut[1L] <- next_m_mut[1L] + new_carriers_m
    next_f_mut[1L] <- next_f_mut[1L] + new_carriers_f

    # ── Folder widows + new unions
    next_m_mut <- next_m_mut + W_mut_m
    next_f_mut <- next_f_mut + W_mut_f
    next_u_mr  <- next_u_mr  + new_u_mr
    next_u_rm  <- next_u_rm  + new_u_rm

    # ── Density regulation (frozen at resident)
    m_mut <- next_m_mut * dr
    f_mut <- next_f_mut * dr
    u_mr  <- next_u_mr  * dr
    u_rm  <- next_u_rm  * dr

    # Numerical guard: if mutant population blows up, rescale
    N <- sum(m_mut) + sum(f_mut) + 2 * sum(u_mr) + 2 * sum(u_rm)
    if (!is.finite(N) || N <= 0) return(0)
    if (N > 1e10) {
      scale <- 1 / N
      m_mut <- m_mut * scale; f_mut <- f_mut * scale
      u_mr  <- u_mr  * scale; u_rm  <- u_rm  * scale
      N0    <- N0   * scale
    }
  }

  N_final <- sum(m_mut) + sum(f_mut) + 2 * sum(u_mr) + 2 * sum(u_rm)
  if (N_final <= 0) return(0)
  (N_final / N0)^(1 / T_ticks)
}

run_adaptive_dynamics <- function(s_m_M, s_f_O,
                                    M_init = 10, n_ad_steps = AD_STEPS,
                                    omega = OMEGA) {
  M_m <- M_init; M_f <- M_init
  state <- make_initial_state(omega, n_init = 200)
  trace <- matrix(NA_real_, n_ad_steps, 2)
  colnames(trace) <- c("M_m", "M_f")

  for (it in seq_len(n_ad_steps)) {
    # 1. Resident equilibrium
    state <- project_T(state, M_m, M_f, s_m_M, s_f_O,
                        T_ticks = EQUIL_TICKS, omega = omega)
    N_r <- sum(state$m) + sum(state$f) + 2 * sum(state$u)
    if (N_r <= 0) {
      # population extinct → cannot continue
      trace[it:n_ad_steps, ] <- matrix(c(M_m, M_f),
                                       n_ad_steps - it + 1, 2, byrow = TRUE)
      break
    }

    # 2. Alternate mutated locus by iteration. Compare mutant lambda to
    # the resident's own lambda (same simulation, same truncation) —
    # the absolute value of either is ~1 but not exactly due to
    # finite-T_ticks truncation; the COMPARISON cancels that error.
    lam_res <- mutant_growth_rate(M_m, M_f, s_m_M, s_f_O,
                                    M_m, M_f, state, omega = omega)
    mutate_m <- (it %% 2L == 0L)

    if (mutate_m) {
      up <- max(1, M_m + SIGMA); dn <- max(1, M_m - SIGMA)
      lam_up <- mutant_growth_rate(up, M_f, s_m_M, s_f_O,
                                    M_m, M_f, state, omega = omega)
      lam_dn <- mutant_growth_rate(dn, M_f, s_m_M, s_f_O,
                                    M_m, M_f, state, omega = omega)
      if (lam_up > lam_res && lam_up >= lam_dn) M_m <- up else
        if (lam_dn > lam_res && lam_dn >  lam_up) M_m <- dn
    } else {
      up <- max(1, M_f + SIGMA); dn <- max(1, M_f - SIGMA)
      lam_up <- mutant_growth_rate(M_m, up, s_m_M, s_f_O,
                                    M_m, M_f, state, omega = omega)
      lam_dn <- mutant_growth_rate(M_m, dn, s_m_M, s_f_O,
                                    M_m, M_f, state, omega = omega)
      if (lam_up > lam_res && lam_up >= lam_dn) M_f <- up else
        if (lam_dn > lam_res && lam_dn >  lam_up) M_f <- dn
    }

    trace[it, ] <- c(M_m, M_f)
  }

  list(M_m = M_m, M_f = M_f, trace = trace)
}

# ── Life expectancy at adulthood (eq 27) ─────────────────────────────────────
#
# Adult life expectancy = expected time-units in age classes >= 2, given
# survival to age 2. Per eq 27: N_i = (I_omega - U_i * e^{-nu N_r})^{-1}.
# Sum of column 1 of N_i gives expected lifespan from age 1. The paper
# uses column 2 (life expectancy AT adulthood = age 2 onwards).
life_expectancy_adult <- function(M_i, N_r, use_density = TRUE,
                                    omega = OMEGA) {
  u_i <- survival_vec(M_i, omega)
  U_i <- matrix(0, omega, omega)
  # subdiagonal: U_i[x+1, x] = u_i(x)
  for (x in seq_len(omega - 1L)) U_i[x + 1L, x] <- u_i[x]
  dr <- if (use_density) exp(-NU * N_r) else 1
  N_i <- solve(diag(omega) - U_i * dr)
  # Column 2 → expected time spent in each age class for an individual
  # at age 2. Sum of column 2 = adult life expectancy.
  sum(N_i[, 2L])
}

# ── Per-cell evaluation ──────────────────────────────────────────────────────

evaluate_cell <- function(s_m_M, s_f_O, ad_steps = AD_STEPS) {
  t0 <- proc.time()
  ad <- tryCatch(run_adaptive_dynamics(s_m_M, s_f_O, n_ad_steps = ad_steps),
                 error = function(e) list(M_m = NA, M_f = NA, error = conditionMessage(e)))
  if (!is.null(ad$error) || is.na(ad$M_m) || is.na(ad$M_f)) {
    return(list(s_m_M = s_m_M, s_f_O = s_f_O,
                M_m = NA_real_, M_f = NA_real_,
                L_m_intrinsic = NA_real_, L_f_intrinsic = NA_real_,
                L_m_realised  = NA_real_, L_f_realised  = NA_real_,
                rel_diff_intrinsic = NA_real_, rel_diff_realised = NA_real_,
                N_r = NA_real_,
                elapsed = as.numeric((proc.time() - t0)[3])))
  }
  M_m <- ad$M_m; M_f <- ad$M_f
  # Compute resident equilibrium one more time for N_r
  state <- project_T(make_initial_state(n_init = 200), M_m, M_f,
                      s_m_M, s_f_O, T_ticks = EQUIL_TICKS)
  N_r <- sum(state$m) + sum(state$f) + 2 * sum(state$u)
  L_m_int <- life_expectancy_adult(M_m, N_r, use_density = FALSE)
  L_f_int <- life_expectancy_adult(M_f, N_r, use_density = FALSE)
  L_m_real <- life_expectancy_adult(M_m, N_r, use_density = TRUE)
  L_f_real <- life_expectancy_adult(M_f, N_r, use_density = TRUE)
  list(
    s_m_M = s_m_M, s_f_O = s_f_O,
    M_m = M_m, M_f = M_f,
    L_m_intrinsic = L_m_int, L_f_intrinsic = L_f_int,
    L_m_realised  = L_m_real, L_f_realised  = L_f_real,
    rel_diff_intrinsic = (L_f_int - L_m_int) / max(L_f_int, L_m_int),
    rel_diff_realised  = (L_f_real - L_m_real) / max(L_f_real, L_m_real),
    N_r = N_r,
    elapsed = as.numeric((proc.time() - t0)[3])
  )
}

# ── Main sweep ───────────────────────────────────────────────────────────────

main <- function() {
  cat("Rees-Baylis 2026 analytical reproduction\n")
  cat("  omega = ", OMEGA, "  AD_steps = ", AD_STEPS,
      "  equil_ticks = ", EQUIL_TICKS, "  n_cores = ", N_CORES, "\n", sep = "")

  grid <- expand.grid(s_m_M = TRADEOFF_GRID, s_f_O = TRADEOFF_GRID,
                      stringsAsFactors = FALSE)
  cat("  cells: ", nrow(grid), "\n", sep = "")

  t0 <- proc.time()
  work <- split(grid, seq_len(nrow(grid)))
  results <- if (.Platform$OS.type == "unix" && N_CORES > 1L) {
    parallel::mclapply(work, function(w)
      evaluate_cell(w$s_m_M, w$s_f_O),
      mc.cores = N_CORES, mc.preschedule = FALSE)
  } else {
    lapply(work, function(w) evaluate_cell(w$s_m_M, w$s_f_O))
  }
  elapsed <- as.numeric((proc.time() - t0)[3])
  cat(sprintf("\nDone in %.1f s (%.1f min)\n", elapsed, elapsed / 60))

  # Tabular result
  df <- do.call(rbind, lapply(results, function(r)
    data.frame(s_m_M = r$s_m_M, s_f_O = r$s_f_O,
               M_m = r$M_m, M_f = r$M_f,
               L_m_intrinsic = r$L_m_intrinsic, L_f_intrinsic = r$L_f_intrinsic,
               L_m_realised  = r$L_m_realised,  L_f_realised  = r$L_f_realised,
               rel_diff_intrinsic = r$rel_diff_intrinsic,
               rel_diff_realised  = r$rel_diff_realised,
               N_r = r$N_r, elapsed = r$elapsed)))

  # Save
  out <- "dev/audit/fidelity/paper_rees_baylis_2026_analytical.rds"
  saveRDS(list(meta = list(omega = OMEGA, AD_steps = AD_STEPS,
                            equil_ticks = EQUIL_TICKS, mutant_ticks = MUTANT_TICKS,
                            timestamp = as.character(Sys.time()),
                            elapsed_seconds = elapsed),
               grid = df,
               raw  = results),
          out)
  cat("Saved: ", out, "\n", sep = "")

  cat("\n── Summary table ─────────────────────────────────────────────\n")
  print(df, row.names = FALSE, digits = 3)

  # ── Plots: Fig 2 a, b, c (heatmaps) and d, e, f (scatter)
  # Use log-axis for s values to match paper visualisation
  df$s_m_log <- log10(df$s_m_M)
  df$s_f_log <- log10(df$s_f_O)
  df$rel_strength <- log10(df$s_m_M / df$s_f_O)

  hm_theme <- theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank())

  p_a <- ggplot(df, aes(x = s_f_O, y = s_m_M, fill = L_m_intrinsic)) +
    geom_tile() +
    geom_text(aes(label = sprintf("%.1f", L_m_intrinsic)), size = 3) +
    scale_fill_gradient(low = "#fff7bc", high = "#cc4c02", name = "L_m") +
    scale_x_log10(breaks = TRADEOFF_GRID) +
    scale_y_log10(breaks = TRADEOFF_GRID) +
    labs(title = "Fig 2 a: male intrinsic life expectancy L_m",
         x = expression(s[f]^O), y = expression(s[m]^M)) +
    hm_theme
  ggsave("vignettes/figures/showcase_rees_baylis_analytical_fig2a.png",
         p_a, width = 5.5, height = 4.5, dpi = 110)

  p_b <- ggplot(df, aes(x = s_f_O, y = s_m_M, fill = L_f_intrinsic)) +
    geom_tile() +
    geom_text(aes(label = sprintf("%.1f", L_f_intrinsic)), size = 3) +
    scale_fill_gradient(low = "#fff7bc", high = "#cc4c02", name = "L_f") +
    scale_x_log10(breaks = TRADEOFF_GRID) +
    scale_y_log10(breaks = TRADEOFF_GRID) +
    labs(title = "Fig 2 b: female intrinsic life expectancy L_f",
         x = expression(s[f]^O), y = expression(s[m]^M)) +
    hm_theme
  ggsave("vignettes/figures/showcase_rees_baylis_analytical_fig2b.png",
         p_b, width = 5.5, height = 4.5, dpi = 110)

  p_c <- ggplot(df, aes(x = s_f_O, y = s_m_M, fill = rel_diff_intrinsic)) +
    geom_tile() +
    geom_text(aes(label = sprintf("%+.2f", rel_diff_intrinsic)), size = 3) +
    scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                          midpoint = 0,
                          limits = c(-1, 1) * max(abs(df$rel_diff_intrinsic), na.rm = TRUE),
                          name = expression((L[f] - L[m]) / max)) +
    scale_x_log10(breaks = TRADEOFF_GRID) +
    scale_y_log10(breaks = TRADEOFF_GRID) +
    labs(title = "Fig 2 c: relative adult life expectancy difference",
         subtitle = "Negative (blue) = male-biased longevity; positive (red) = female-biased",
         x = expression(s[f]^O), y = expression(s[m]^M)) +
    hm_theme
  ggsave("vignettes/figures/showcase_rees_baylis_analytical_fig2c.png",
         p_c, width = 5.8, height = 4.7, dpi = 110)

  p_f <- ggplot(df, aes(x = rel_strength, y = rel_diff_intrinsic)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_point(aes(colour = s_m_M), size = 3, alpha = 0.8) +
    scale_colour_viridis_c(name = expression(s[m]^M)) +
    labs(title = "Fig 2 f: relative life-expectancy difference vs trade-off ratio",
         subtitle = "x-axis: log10(s_m^M / s_f^O); y-axis: (L_f - L_m) / max(L_f, L_m)",
         x = expression(log[10](s[m]^M / s[f]^O)),
         y = expression((L[f] - L[m]) / max(L[f], L[m]))) +
    theme_minimal(base_size = 11)
  ggsave("vignettes/figures/showcase_rees_baylis_analytical_fig2f.png",
         p_f, width = 6, height = 4.2, dpi = 110)

  cat("\nPlots saved under vignettes/figures/showcase_rees_baylis_analytical_*.png\n")
  invisible(df)
}

if (sys.nframe() == 0L) main()
