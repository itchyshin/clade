# Pure-text drift scan: compare displayed chunk specs against the
# "What we found" prose. Catches GENERATOR_DRIFT without Julia.

source(file.path("dev", "audit", "parse_rmd.R"))

# Key numeric params we care about in both places
.keys <- c("max_ticks", "n_agents_init", "grid_size", "grass_rate",
           "seed", "learning_rate", "seasonal_amplitude",
           "transmission_prob", "care_duration")

.scan_numbers <- function(text, keys = .keys) {
  if (is.na(text)) return(list())
  out <- list()
  for (k in keys) {
    # key<-val or key = val in R code style
    pat_r <- sprintf("%s\\s*(?:<-|=)\\s*([0-9]+(?:\\.[0-9]+)?L?)", k)
    m <- regmatches(text, regexec(pat_r, text))[[1]]
    if (length(m) == 2) out[[k]] <- m[2]
    # "400 ticks" style numeric prose
    if (k == "max_ticks") {
      m2 <- regmatches(text, regexec("([0-9]{2,5})\\s*ticks", text))[[1]]
      if (length(m2) == 2) out[[paste0(k, "_prose")]] <- m2[2]
    }
    if (k == "n_agents_init") {
      m3 <- regmatches(text, regexec("([0-9]{2,5})\\s*agents", text))[[1]]
      if (length(m3) == 2) out[[paste0(k, "_prose")]] <- m3[2]
    }
    if (k == "seed") {
      m4 <- regmatches(text, regexec("seeds?\\s+([0-9]+(?:[-\u2013][0-9]+)?)", text))[[1]]
      if (length(m4) == 2) out[[paste0(k, "_prose")]] <- m4[2]
    }
  }
  # Replicate count
  m5 <- regmatches(text, regexec("([0-9]+)\\s+replicates", text))[[1]]
  if (length(m5) == 2) out$replicates_prose <- m5[2]
  out
}

paths <- list.files("vignettes", pattern = "^s-.*\\.Rmd$", full.names = TRUE)
rows <- lapply(paths, function(p) {
  parsed <- audit_parse_rmd(p)
  disp  <- .scan_numbers(parsed$displayed_code)
  found <- .scan_numbers(parsed$what_we_found)
  both  <- union(names(disp), names(found))
  drift <- sapply(both, function(k) {
    v1 <- disp[[k]] %||% ""
    v2 <- found[[k]] %||% ""
    if (nzchar(v1) && nzchar(v2) && !identical(gsub("L$", "", v1), gsub("L$", "", v2))) {
      sprintf("%s: displayed=%s vs found=%s", k, v1, v2)
    } else NA_character_
  })
  drift <- drift[!is.na(drift)]
  data.frame(
    vignette = parsed$vignette,
    n_drifts = length(drift),
    drift    = if (length(drift)) paste(drift, collapse = " | ") else "",
    displayed_max_ticks = disp$max_ticks %||% NA,
    found_max_ticks     = found$max_ticks %||% found$max_ticks_prose %||% NA,
    displayed_n_agents  = disp$n_agents_init %||% NA,
    found_n_agents      = found$n_agents_init_prose %||% NA,
    found_replicates    = found$replicates_prose %||% NA,
    stringsAsFactors = FALSE
  )
})
tbl <- do.call(rbind, rows)
utils::write.csv(tbl, "dev/audit/_artifacts/text_drift.csv", row.names = FALSE)
cat(sprintf("wrote dev/audit/_artifacts/text_drift.csv (%d rows, %d with drift)\n",
            nrow(tbl), sum(tbl$n_drifts > 0)))
print(tbl[tbl$n_drifts > 0, c("vignette","drift")], row.names = FALSE)
