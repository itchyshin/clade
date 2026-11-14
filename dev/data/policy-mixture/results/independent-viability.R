args <- commandArgs(trailingOnly = TRUE)
repo <- normalizePath(args[[1]], mustWork = TRUE)
root <- normalizePath(args[[2]], mustWork = TRUE)
outfile <- if (length(args) >= 3) args[[3]] else tempfile("clade-mixture-viability-", fileext = ".csv")
pkgload::load_all(repo, quiet = TRUE)
runs <- read.csv(file.path(root, "runs.csv"), stringsAsFactors = FALSE)
out <- lapply(seq_len(nrow(runs)), function(j) {
  x <- runs[j, ]
  ticks <- data.frame(t = c(x$tick_of_min, x$final_tick),
                      n_agents = c(x$min_population, x$final_agents))
  v <- viability_report(ticks, n_agents_init = 48L)
  data.frame(ploidy=x$ploidy, source_mutation=x$source_mutation,
             seed=x$seed, mode=x$mode, mono=x$mono, verdict=v$verdict)
})
write.csv(do.call(rbind, out), outfile, row.names=FALSE)
cat("actual R viability_report rows:", length(out), "output:", outfile, "\n")
