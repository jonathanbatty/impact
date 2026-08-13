#' Ascertain IMPACT long-term conditions from a data frame of coded events.
#'
#' Each row is a single coded event; \code{data} must contain the identifier
#' and code columns. Returns a data frame with the identifier plus one 0/1
#' indicator column per long-term condition (named \code{__<LTC>}), optionally
#' with multimorbidity summary variables.
#'
#' @param data A data frame of coded events.
#' @param id Name of the unique identifier column.
#' @param codesystems Coding system(s) to use, in the same order as
#'   \code{searchvars}: icd9cm, icd9pcs, icd10cm, icd10pcs, icd10, opcs4,
#'   cprdaurum.
#' @param searchvars List of column name(s) to search, one per code system.
#'   Each element may be a character vector of several columns searched for
#'   that code system.
#' @param multimorbidity Add multimorbidity variables (LTC count, mental/
#'   physical counts, body-system counts).
#' @param summary Print a summary of the totals for each codelist searched.
#' @return A data frame with the identifier and \code{__<LTC>} indicator
#'   columns, plus multimorbidity variables if requested.
#' @export
impact <- function(data, id, codesystems, searchvars,
                   multimorbidity = FALSE, summary = FALSE) {

  # ---- Normalise inputs ----
  if (is.character(codesystems)) codesystems <- as.list(strsplit(codesystems, "[, ]+")[[1]])
  codesystems <- as.list(codesystems)

  # searchvars: accept a list of column vectors, or a flat character vector
  sv_cols <- list()
  if (!is.list(searchvars)) searchvars <- as.list(searchvars)
  for (sv in searchvars) {
    if (is.list(sv)) sv <- unlist(sv)
    sv_cols <- c(sv_cols, list(sv))
  }

  if (length(codesystems) != length(sv_cols)) {
    stop("Number of code systems and number of search variables must be equal.")
  }
  if (!(id %in% names(data))) stop("Identifier column '", id, "' not found.")
  for (cs in codesystems) {
    if (!(cs %in% list_codesystems())) stop("Unknown code system '", cs, "'.")
  }

  # ---- Build a combined code -> LTC lookup ----
  lookup <- new.env(hash = TRUE, parent = emptyenv())
  per_cs <- list()
  for (cs in codesystems) {
    mapping <- select_codesystem(cs)          # an environment
    per_cs[[cs]] <- mapping
    keys <- ls(mapping)
    for (k in keys) {
      val <- mapping[[k]]
      if (is.null(val)) next
      for (ltc in as.character(val)) {
        old <- lookup[[k]]
        if (is.null(old)) lookup[[k]] <- ltc
        else lookup[[k]] <- unique(c(old, ltc))
      }
    }
  }

  # ---- Result data frame: id + one 0/1 column per LTC ----
  result <- data.frame(id = data[[id]])
  names(result)[1] <- id
  for (ltc in ltc_names) result[[paste0("__", ltc)]] <- 0L

  # ---- Search each code system - search variable pair ----
  for (i in seq_along(codesystems)) {
    cols <- sv_cols[[i]]
    for (col in cols) {
      if (!(col %in% names(data))) stop("Search variable '", col, "' not found.")
      vals <- as.character(data[[col]])
      uniq <- unique(vals)
      for (code in uniq) {
        if (is.na(code) || code == "") next
        ltc <- lookup[[code]]
        if (is.null(ltc)) next
        mask <- !is.na(vals) & vals == code
        for (l in as.character(ltc)) result[mask, paste0("__", l)] <- 1L
      }
    }
  }

  # ---- Multimorbidity ----
  if (multimorbidity) {
    ltc_cols <- paste0("__", ltc_names)
    result[["__nltc"]] <- rowSums(result[ltc_cols])
    mental <- ltc_names[ltc_category == "Mental"]
    result[["__nmental"]] <- rowSums(result[paste0("__", mental)])
    result[["__nphysical"]] <- result[["__nltc"]] - result[["__nmental"]]
    # distinct body systems affected, per row
    result[["__nbody"]] <- apply(
      result[ltc_cols], 1,
      function(r) length(unique(ltc_mapping[r == 1])))
    # per-body-system counts
    systems <- unique(ltc_mapping)
    for (b in systems) {
      cols <- ltc_cols[ltc_mapping == b]
      if (length(cols) > 0) {
        name <- paste0("__bs_", gsub(" ", "_", gsub("&", "and", b)))
        result[[name]] <- rowSums(result[cols])
      }
    }
  }

  # ---- Summary ----
  if (summary) {
    cat("\nIMPACT summary:", nrow(data), "coded events\n")
    for (i in seq_along(codesystems)) {
      cs <- codesystems[i]
      cols <- sv_cols[[i]]
      tot <- 0
      for (col in cols) {
        vals <- as.character(data[[col]])
        tot <- tot + sum(vals %in% ls(per_cs[[cs]]))
      }
      cat(" ", cs, ":", tot, "code(s) matched in the searched variable(s)\n")
    }
  }

  result
}

#' Return the code -> long-term-condition lookup for one coding system.
#'
#' @param ontology One of: icd9cm, icd9pcs, icd10cm, icd10pcs, icd10, opcs4,
#'   cprdaurum (CPRD Aurum medcodeid codelists).
#' @return An environment mapping code strings to LTC identifiers.
#' @export
select_codesystem <- function(ontology) {
  if (ontology == "icd9cm")  return(generate_lookup_icd9cm())
  if (ontology == "icd9pcs") return(generate_lookup_icd9pcs())
  if (ontology == "icd10cm") return(generate_lookup_icd10cm())
  if (ontology == "icd10pcs") return(generate_lookup_icd10pcs())
  if (ontology == "icd10")   return(generate_lookup_icd10())
  if (ontology == "opcs4")   return(generate_lookup_opcs4())
  if (ontology %in% c("cprdaurum", "medcodeid")) return(generate_lookup_medcodeid())
  stop("Unknown code system '", ontology,
       "'. Select one of: icd9cm, icd9pcs, icd10cm, icd10pcs, icd10, opcs4, cprdaurum (or medcodeid).")
}

#' Names of the supported coding systems.
#' @export
list_codesystems <- function() {
  c("icd9cm", "icd9pcs", "icd10cm", "icd10pcs", "icd10", "opcs4",
    "cprdaurum", "medcodeid")
}

#' Long-term condition metadata (code, label, body system, category).
#' @export
list_ltcs <- function() {
  data.frame(ltc = ltc_names,
             label = ltc_labels,
             body_system = ltc_mapping,
             category = ltc_category,
             stringsAsFactors = FALSE)
}
