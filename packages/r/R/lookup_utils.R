.impact_lookup_store <- new.env(hash = TRUE, parent = emptyenv())

# Capture both vectors from a generated lookup factory before another
# immutable definition file replaces generate_lookup(). Rebuilding the
# environment with split() also preserves codes that map to multiple LTCs.
.impact_capture_lookup <- function(name, factory) {
  statements <- as.list(body(factory))
  codes <- trimws(as.character(eval(statements[[2L]][[3L]], envir = baseenv())))
  ltcs <- eval(statements[[3L]][[3L]], envir = baseenv())
  values <- lapply(split(ltcs, codes), unique)
  lookup <- list2env(values, hash = TRUE, parent = emptyenv())
  assign(name, lookup, envir = .impact_lookup_store)
  invisible(NULL)
}
