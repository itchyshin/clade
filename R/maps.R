# ── Internal smoothing helpers ─────────────────────────────────────────────────

# 2D Gaussian smoothing via separable 1D filters (pure base R).
.smooth2d <- function(mat, sigma) {
  if (sigma <= 0) return(mat)
  nr <- nrow(mat)
  nc <- ncol(mat)
  k_half_r <- min(ceiling(3 * sigma), (nc - 1L) %/% 2L)
  kv_r     <- stats::dnorm(seq(-k_half_r, k_half_r), sd = sigma)
  kv_r     <- kv_r / sum(kv_r)
  mat <- t(apply(mat, 1L, function(r)
    as.numeric(stats::filter(r, kv_r, circular = TRUE))))
  k_half_c <- min(ceiling(3 * sigma), (nr - 1L) %/% 2L)
  kv_c     <- stats::dnorm(seq(-k_half_c, k_half_c), sd = sigma)
  kv_c     <- kv_c / sum(kv_c)
  apply(mat, 2L, function(cc)
    as.numeric(stats::filter(cc, kv_c, circular = TRUE)))
}

# Threshold a continuous field to a 0/1 wall matrix with target p_wall density.
.threshold_field <- function(field, p_wall) {
  thr <- stats::quantile(field, 1 - p_wall, na.rm = TRUE)
  matrix(as.integer(field > thr), nrow = nrow(field), ncol = ncol(field))
}

# ── Type-specific generators ──────────────────────────────────────────────────

.gen_open <- function(nr, nc, ...) {
  matrix(0L, nrow = nr, ncol = nc)
}

.gen_patchy <- function(nr, nc, p_wall, ...) {
  walls    <- matrix(0L, nrow = nr, ncol = nc)
  interior <- expand.grid(r = seq(2L, nr - 1L), c = seq(2L, nc - 1L))
  n_walls  <- round(p_wall * nrow(interior))
  idx      <- sample(nrow(interior), n_walls)
  for (i in idx) walls[interior$r[i], interior$c[i]] <- 1L
  walls
}

.gen_random_cluster <- function(nr, nc, p_wall, scale, ...) {
  if (requireNamespace("NLMR",  quietly = TRUE) &&
      requireNamespace("terra", quietly = TRUE)) {
    r   <- NLMR::nlm_randomcluster(nrow = nr, ncol = nc,
                                    p = p_wall, ai = c(1 - p_wall, p_wall),
                                    rescale = FALSE)
    raw <- matrix(terra::values(r), nrow = nr, ncol = nc, byrow = TRUE)
    return(matrix(as.integer(raw >= stats::quantile(raw, 1 - p_wall)), nrow = nr))
  }
  raw   <- matrix(stats::rnorm(nr * nc), nrow = nr, ncol = nc)
  field <- .smooth2d(raw, sigma = max(1, scale))
  .threshold_field(field, p_wall)
}

.gen_gaussian_field <- function(nr, nc, p_wall, scale, ...) {
  if (requireNamespace("NLMR",  quietly = TRUE) &&
      requireNamespace("terra", quietly = TRUE)) {
    r   <- NLMR::nlm_gaussianfield(nrow = nr, ncol = nc,
                                    autocorr_range = scale, rescale = FALSE)
    raw <- matrix(terra::values(r), nrow = nr, ncol = nc, byrow = TRUE)
    return(.threshold_field(raw, p_wall))
  }
  raw   <- matrix(stats::rnorm(nr * nc), nrow = nr, ncol = nc)
  field <- .smooth2d(raw, sigma = max(2, scale * 2))
  .threshold_field(field, p_wall)
}

.gen_corridors <- function(nr, nc, p_wall, corridor_width, ...) {
  walls <- matrix(1L, nrow = nr, ncol = nc)
  cw    <- max(1L, as.integer(corridor_width))
  spacing <- max(cw + 1L, as.integer(round((cw / (1 - p_wall)) - cw)))
  row_centres <- seq(cw + 1L, nr - cw, by = cw + spacing)
  for (rc in row_centres) {
    r_from <- max(1L, rc - cw %/% 2L)
    r_to   <- min(nr, rc + cw %/% 2L)
    walls[r_from:r_to, ] <- 0L
  }
  col_centres <- seq(cw + 1L, nc - cw, by = cw + spacing)
  for (cc in col_centres) {
    c_from <- max(1L, cc - cw %/% 2L)
    c_to   <- min(nc, cc + cw %/% 2L)
    walls[, c_from:c_to] <- 0L
  }
  walls
}

# ── Public API ────────────────────────────────────────────────────────────────

#' Generate a procedural habitat map
#'
#' Creates a 0/1 wall matrix for use with [run_alife()]. Five landscape types
#' are available, ranging from completely open to structured corridor networks.
#' Pass the result to [prepare_map()] to validate dimensions before use.
#'
#' Types `"random_cluster"` and `"gaussian_field"` use the `NLMR` package
#' when installed; otherwise a pure-R Gaussian-smoothed fallback is used.
#'
#' @param type Character; one of `"open"`, `"patchy"`, `"random_cluster"`,
#'   `"gaussian_field"`, `"corridors"`. Default `"random_cluster"`.
#' @param grid_rows Integer; number of grid rows. Default 50.
#' @param grid_cols Integer; number of grid columns. Default 50.
#' @param p_wall Numeric in (0, 1); target proportion of wall cells. Default
#'   0.3. Ignored for `"open"`.
#' @param scale Positive numeric; spatial scale of wall clustering (sigma for
#'   Gaussian, autocorrelation range for `nlm_gaussianfield`). Default 4.
#' @param corridor_width Integer; open-corridor width in cells (`"corridors"`
#'   only). Default 2.
#' @param seed Integer or `NULL`; random seed. Default `NULL`.
#'
#' @return An integer matrix (0 = open, 1 = wall) of dimensions
#'   `grid_rows` x `grid_cols`. Assign to `specs$wall_map` before calling
#'   [run_alife()], or pass to [prepare_map()] first.
#'
#' @seealso [load_map()], [prepare_map()]
#' @examples
#' map <- generate_map("random_cluster", grid_rows = 20L, grid_cols = 20L,
#'                     p_wall = 0.25, seed = 1L)
#' mean(map == 0L)  # fraction open
#' @export
generate_map <- function(type           = "random_cluster",
                          grid_rows      = 50L,
                          grid_cols      = 50L,
                          p_wall         = 0.3,
                          scale          = 4,
                          corridor_width = 2L,
                          seed           = NULL) {
  type <- match.arg(type,
                    c("open", "patchy", "random_cluster",
                      "gaussian_field", "corridors"))
  if (!is.null(seed)) set.seed(seed)

  nr <- as.integer(grid_rows)
  nc <- as.integer(grid_cols)

  walls <- switch(type,
    open           = .gen_open(nr, nc),
    patchy         = .gen_patchy(nr, nc, p_wall),
    random_cluster = .gen_random_cluster(nr, nc, p_wall, scale),
    gaussian_field = .gen_gaussian_field(nr, nc, p_wall, scale),
    corridors      = .gen_corridors(nr, nc, p_wall, corridor_width)
  )

  open_frac <- mean(walls == 0L)
  if (open_frac < 0.2) {
    warning(sprintf(
      "generate_map(): only %.0f%% of cells are open; forcing borders open.",
      open_frac * 100
    ))
    walls[1L, ]  <- 0L
    walls[nr, ]  <- 0L
    walls[, 1L]  <- 0L
    walls[, nc]  <- 0L
  }

  walls
}

#' Load a bundled or saved habitat map
#'
#' Returns a wall matrix from a bundled `.rds` file in the package's
#' `inst/maps/` directory (use short name, e.g. `"open"` or `"patchy"`) or
#' from an arbitrary file path.
#'
#' @param fn Character; short map name (e.g. `"open"`, `"patchy"`) or the
#'   full path to a saved `.rds` file.
#'
#' @return An integer matrix (0 = open, 1 = wall).
#' @seealso [generate_map()], [prepare_map()]
#' @examples
#' \dontrun{
#' map <- load_map("open")
#' }
#' @export
load_map <- function(fn) {
  pkg_path <- system.file("maps", paste0(fn, ".rds"), package = "clade")
  if (nzchar(pkg_path)) return(readRDS(pkg_path))
  if (!file.exists(fn))
    stop("Map file not found: '", fn,
         "'. Use a bundled name ('open', 'patchy') or supply a full file path.")
  readRDS(fn)
}

#' Validate and resize a habitat map
#'
#' Checks that a wall matrix has the correct dimensions for a given specs list.
#' If dimensions differ, the map is rescaled via nearest-neighbour resampling
#' and a warning is issued. Values are coerced to 0/1 integer.
#'
#' @param map Integer or numeric matrix; a raw wall matrix.
#' @param specs Named list; simulation parameters from [default_specs()]. Used
#'   for dimension checking (`$grid_rows`, `$grid_cols`).
#'
#' @return An integer matrix of dimensions `specs$grid_rows` x
#'   `specs$grid_cols` with values 0 or 1.
#' @seealso [generate_map()], [load_map()]
#' @examples
#' specs   <- default_specs()
#' specs$grid_rows <- 20L; specs$grid_cols <- 20L
#' raw_map <- matrix(0L, nrow = 20L, ncol = 20L)
#' raw_map[1L, ] <- 1L; raw_map[20L, ] <- 1L
#' map <- prepare_map(raw_map, specs)
#' sum(map)   # number of wall cells
#' @export
prepare_map <- function(map, specs) {
  nr_target <- specs$grid_rows
  nc_target <- specs$grid_cols

  if (nrow(map) != nr_target || ncol(map) != nc_target) {
    warning(sprintf(
      "Map dimensions (%d x %d) differ from grid (%d x %d); rescaling.",
      nrow(map), ncol(map), nr_target, nc_target
    ))
    row_idx <- round(seq(1, nrow(map), length.out = nr_target))
    col_idx <- round(seq(1, ncol(map), length.out = nc_target))
    map     <- map[row_idx, col_idx, drop = FALSE]
  }

  matrix(as.integer(map != 0L), nrow = nr_target, ncol = nc_target)
}
