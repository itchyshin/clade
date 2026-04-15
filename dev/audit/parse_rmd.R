# Parse an s-*.Rmd scenario file into its audit-relevant pieces.
#
# Extracts:
#   - displayed code chunks (everything except the `setup` chunk and
#     chunks with eval=FALSE-overridden=TRUE that are figure-display only),
#   - figure chunks: FIG("<name>") references + fig.cap,
#   - "What we found" prose block (if present),
#   - the hypothesis/expected-output paragraph (if present).
#
# Returns a named list with the above fields + the source path.

audit_parse_rmd <- function(path) {
  stopifnot(file.exists(path))
  src <- readLines(path, warn = FALSE)
  text <- paste(src, collapse = "\n")

  chunks <- .extract_chunks(src)

  fig_refs <- .extract_fig_refs(chunks)

  displayed_code <- .collect_displayed_code(chunks)

  list(
    path              = path,
    vignette          = basename(path),
    title             = .extract_yaml_title(src),
    hypothesis        = .extract_section(text, "Expected output"),
    what_we_found     = .extract_section(text, "What we found"),
    key_parameters    = .extract_section(text, "Key parameters"),
    displayed_chunks  = Filter(function(c) !c$is_setup && !c$is_fig, chunks),
    fig_chunks        = Filter(function(c) c$is_fig, chunks),
    fig_refs          = fig_refs,
    displayed_code    = displayed_code,
    n_chunks          = length(chunks)
  )
}

# --- internals -------------------------------------------------------------

.extract_chunks <- function(src) {
  # Match ```{r name?, opts...} ... ``` — knitr syntax
  open_re  <- "^```\\{r\\b([^}]*)\\}\\s*$"
  close_re <- "^```\\s*$"

  chunks <- list()
  i <- 1L
  n <- length(src)
  while (i <= n) {
    if (grepl(open_re, src[i])) {
      header <- sub(open_re, "\\1", src[i])
      start  <- i + 1L
      # find matching close
      j <- start
      while (j <= n && !grepl(close_re, src[j])) j <- j + 1L
      if (j > n) break  # unclosed
      body <- if (start <= j - 1L) src[start:(j - 1L)] else character()
      chunks[[length(chunks) + 1L]] <- .chunk_from(header, body)
      i <- j + 1L
    } else {
      i <- i + 1L
    }
  }
  chunks
}

.chunk_from <- function(header_raw, body) {
  header <- trimws(header_raw)
  # first token before first comma (ignoring spaces) is the label if not key=val
  first_tok <- trimws(strsplit(header, ",")[[1]][[1]])
  label <- if (nzchar(first_tok) && !grepl("=", first_tok)) first_tok else NA_character_

  opts_part <- if (is.na(label)) header else sub("^[^,]*,?\\s*", "", header)
  opts <- .parse_opts(opts_part)

  is_setup <- identical(label, "setup") ||
              (identical(opts$include, "FALSE") && grepl("FIG\\s*<-", paste(body, collapse = "\n")))

  is_fig <- (identical(opts$eval, "TRUE") && any(grepl("FIG\\(", body))) ||
            grepl("^fig(-|$)", label %||% "")

  list(
    label    = label,
    header   = header,
    opts     = opts,
    body     = body,
    is_setup = is_setup,
    is_fig   = is_fig,
    fig_cap  = .unquote(opts$fig.cap)
  )
}

.parse_opts <- function(s) {
  s <- trimws(s)
  if (!nzchar(s)) return(list())
  # Split by comma, but keep simple: split on commas that are not inside quotes
  parts <- .split_preserve_quotes(s)
  out <- list()
  for (p in parts) {
    if (!grepl("=", p)) next
    kv <- regmatches(p, regexec("^([^=]+)=(.*)$", p))[[1]]
    if (length(kv) == 3) {
      out[[trimws(kv[2])]] <- trimws(kv[3])
    }
  }
  out
}

.split_preserve_quotes <- function(s) {
  out <- character()
  buf <- ""
  in_q <- FALSE
  chars <- strsplit(s, "", fixed = TRUE)[[1]]
  for (ch in chars) {
    if (ch == '"') in_q <- !in_q
    if (ch == "," && !in_q) {
      out <- c(out, buf); buf <- ""
    } else {
      buf <- paste0(buf, ch)
    }
  }
  if (nzchar(buf)) out <- c(out, buf)
  out
}

.unquote <- function(x) {
  if (is.null(x)) return(NA_character_)
  sub('^"(.*)"$', "\\1", x)
}

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 1L && is.na(a)) return(b)
  a
}

.extract_fig_refs <- function(chunks) {
  refs <- list()
  for (ch in chunks) {
    if (!ch$is_fig) next
    body <- paste(ch$body, collapse = "\n")
    m <- regmatches(body, gregexpr('FIG\\("([^"]+)"\\)', body))[[1]]
    names <- sub('FIG\\("([^"]+)"\\)', "\\1", m)
    for (nm in names) {
      refs[[length(refs) + 1L]] <- list(
        name    = nm,
        png     = paste0("showcase_", nm, ".png"),
        fig_cap = ch$fig_cap,
        chunk_label = ch$label
      )
    }
  }
  refs
}

.collect_displayed_code <- function(chunks) {
  lines <- character()
  for (ch in chunks) {
    if (ch$is_setup || ch$is_fig) next
    lines <- c(lines, sprintf("# --- chunk: %s ---", ch$label %||% "(unnamed)"))
    lines <- c(lines, ch$body)
  }
  paste(lines, collapse = "\n")
}

.extract_yaml_title <- function(src) {
  # Very small YAML parser: title: "..."
  in_yaml <- FALSE
  for (ln in src) {
    if (ln == "---") {
      if (!in_yaml) in_yaml <- TRUE else break
      next
    }
    if (in_yaml && grepl("^title:", ln)) {
      return(.unquote(trimws(sub("^title:\\s*", "", ln))))
    }
  }
  NA_character_
}

.extract_section <- function(text, heading) {
  # Prose comes in two forms:
  #   **<heading>.**  <paragraph>    (bold-inline lead)
  #   ### <heading>   ... next heading
  # Try bold-inline first, then header-style.
  pat_inline <- sprintf("\\*\\*%s\\.?\\*\\*([\\s\\S]*?)(?=\\n\\n|\\*\\*[A-Z])", heading)
  m <- regmatches(text, regexpr(pat_inline, text, perl = TRUE))
  if (length(m) && nzchar(m)) {
    return(trimws(sub(pat_inline, "\\1", m, perl = TRUE)))
  }
  pat_header <- sprintf("###?\\s+%s[\\s\\S]*?(?=\\n###?\\s|$)", heading)
  m2 <- regmatches(text, regexpr(pat_header, text, perl = TRUE))
  if (length(m2) && nzchar(m2)) return(trimws(m2))
  NA_character_
}
