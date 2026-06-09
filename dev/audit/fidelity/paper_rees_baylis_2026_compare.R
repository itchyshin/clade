# Cross-validate the independent R analytical port against the paper's
# own published MATLAB output (Rees-Baylis et al. 2026, Figshare DOI
# 10.6084/m9.figshare.29558150, file `model_output_and_data.zip`).
#
# Usage:
#   1. Download model_output_and_data.zip from Figshare
#      (https://ndownloader.figshare.com/files/63925749, ~1.5 GB).
#   2. Extract only the k4_y0.8 cells (Table 1 parameters):
#        unzip -q model_output_and_data.zip \
#          "model_output_and_data/baseline_monogamous_model_output/k4_y0.8/*M_LE_data.csv" \
#          -d /path/to/extracted/
#   3. Set CSV_DIR below to that path, then `Rscript this_file.R`.
#
# Output:
#   - dev/audit/fidelity/paper_rees_baylis_2026_published.rds  (paper grid)
#   - a summary of per-cell discrepancies vs the R port.
#
# The cached `paper_rees_baylis_2026_published.rds` in the repo is the
# output of this script; re-running it reproduces the comparison.

CSV_DIR <- Sys.getenv("REES_BAYLIS_CSV_DIR",
  "/tmp/rees_baylis_figshare/extracted/model_output_and_data/baseline_monogamous_model_output/k4_y0.8")

stopifnot(dir.exists(CSV_DIR))

files <- list.files(CSV_DIR, pattern = "M_LE_data.csv$",
                    recursive = TRUE, full.names = TRUE)
stopifnot(length(files) == 25L)

parse_cell <- function(path) {
  parts <- strsplit(dirname(path), "/")[[1L]]
  cell  <- tail(parts, 1)
  m_str <- sub("^sm_", "", strsplit(cell, "_sf_")[[1L]][1])
  f_str <- strsplit(cell, "_sf_")[[1L]][2]
  s_m   <- as.numeric(m_str)
  s_f   <- as.numeric(f_str)
  d     <- read.csv(path, stringsAsFactors = FALSE)
  # Final-5-generations mean across 3 replicates → converged ESS values
  d_final <- d[d$time >= max(d$time) - 5L, ]
  m_rows  <- d_final[d_final$sex == "male",   ]
  f_rows  <- d_final[d_final$sex == "female", ]
  data.frame(
    s_m_M               = s_m,
    s_f_O               = s_f,
    M_m_paper           = mean(m_rows$modal_age),
    M_f_paper           = mean(f_rows$modal_age),
    L_m_intr_paper      = mean(m_rows$life_expec_intr),
    L_f_intr_paper      = mean(f_rows$life_expec_intr),
    L_m_dd_paper        = mean(m_rows$life_expec_dd),
    L_f_dd_paper        = mean(f_rows$life_expec_dd)
  )
}

paper <- do.call(rbind, lapply(files, parse_cell))
paper$rel_diff_intr_paper <- (paper$L_f_intr_paper - paper$L_m_intr_paper) /
                              pmax(paper$L_f_intr_paper, paper$L_m_intr_paper)
paper$rel_diff_dd_paper   <- (paper$L_f_dd_paper - paper$L_m_dd_paper) /
                              pmax(paper$L_f_dd_paper, paper$L_m_dd_paper)
paper <- paper[order(paper$s_m_M, paper$s_f_O), ]

out_path <- "dev/audit/fidelity/paper_rees_baylis_2026_published.rds"
saveRDS(paper, out_path)
cat("Saved ", out_path, " (", nrow(paper), " cells)\n", sep = "")

# ── Discrepancy report against the R-port output, if available ───────────
mine_path <- "dev/audit/fidelity/paper_rees_baylis_2026_analytical.rds"
if (file.exists(mine_path)) {
  mine  <- readRDS(mine_path)$grid
  paper$key <- sprintf("%.3f_%.3f", paper$s_m_M, paper$s_f_O)
  mine$key  <- sprintf("%.3f_%.3f", mine$s_m_M,  mine$s_f_O)
  m <- merge(paper, mine[, c("key", "M_m", "M_f", "L_m_intrinsic", "L_f_intrinsic",
                              "rel_diff_intrinsic")], by = "key", all.x = TRUE)
  m$dM_m <- m$M_m - m$M_m_paper
  m$dM_f <- m$M_f - m$M_f_paper
  m$drel <- m$rel_diff_intrinsic - m$rel_diff_intr_paper

  cat("\n── Discrepancy summary (R port vs paper) ─────────────────────\n")
  cat(sprintf("  M_m         bias=%+.3f  mae=%.3f  max|diff|=%.3f\n",
              mean(m$dM_m), mean(abs(m$dM_m)), max(abs(m$dM_m))))
  cat(sprintf("  M_f         bias=%+.3f  mae=%.3f  max|diff|=%.3f\n",
              mean(m$dM_f), mean(abs(m$dM_f)), max(abs(m$dM_f))))
  cat(sprintf("  rel_diff    bias=%+.4f  mae=%.4f  max|diff|=%.4f\n",
              mean(m$drel), mean(abs(m$drel)), max(abs(m$drel))))
  cat(sprintf("  Direction:  %d / 25 cells agree on sign(rel_diff)\n",
              sum(sign(m$rel_diff_intr_paper) == sign(m$rel_diff_intrinsic))))
}
