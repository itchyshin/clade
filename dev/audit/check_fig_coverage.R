# Diff every FIG("...") reference in vignettes/*.Rmd against the
# PNG files actually present in vignettes/figures/. Used after
# PNG regeneration to identify any missing figures.

rmd_files <- list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)

extract_fig_names <- function(path) {
  src <- readLines(path, warn = FALSE)
  m <- regmatches(src, gregexpr('FIG\\("([^"]+)"\\)', src))
  names <- unlist(lapply(m, function(x) sub('FIG\\("([^"]+)"\\)', "\\1", x)))
  unique(names)
}

all_refs <- unique(unlist(lapply(rmd_files, extract_fig_names)))
expected <- paste0("showcase_", all_refs, ".png")

on_disk_vig <- list.files("vignettes/figures", pattern = "\\.png$")
on_disk_inst <- list.files("inst/figures",    pattern = "\\.png$")

missing_vig  <- setdiff(expected, on_disk_vig)
missing_inst <- setdiff(expected, on_disk_inst)
orphan_vig   <- setdiff(on_disk_vig,  expected)

cat(sprintf("Rmd files scanned:    %d\n", length(rmd_files)))
cat(sprintf("Unique FIG refs:      %d\n", length(all_refs)))
cat(sprintf("PNGs in vignettes/:   %d\n", length(on_disk_vig)))
cat(sprintf("PNGs in inst/figures: %d\n", length(on_disk_inst)))
cat(sprintf("\nMissing in vignettes/figures (referenced but absent): %d\n",
            length(missing_vig)))
for (m in missing_vig) cat("  ", m, "\n")
cat(sprintf("\nMissing in inst/figures (out of sync with vignettes/): %d\n",
            length(missing_inst)))
for (m in missing_inst) cat("  ", m, "\n")
cat(sprintf("\nOrphan PNGs in vignettes/figures/ (not referenced by any Rmd): %d\n",
            length(orphan_vig)))
for (o in orphan_vig) cat("  ", o, "\n")

invisible(list(all_refs = all_refs, missing_vig = missing_vig,
               missing_inst = missing_inst, orphan_vig = orphan_vig))
