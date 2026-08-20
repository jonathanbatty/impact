#' Run the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool.
#'
#' Each row of `data` is a coded event. IMPACT returns that row's
#' identifier and either 321 granular LTC indicators or 116 grouped phenotype
#' indicators. The output level must be selected explicitly.
#'
#' @param data A data frame containing coded events.
#' @param id Name of the identifier column. Names beginning `__` are reserved
#'   for IMPACT outputs.
#' @param codesystems Code system name(s), in the same order as
#'   `searchvars`.
#' @param searchvars A list with one character vector of character code-column
#'   names per code system. For one code system, a character vector is also
#'   accepted.
#' @param level Either "ltc" or "phenotype".
#' @param multimorbidity A single logical value. If TRUE, add event-level,
#'   phenotype-based counts.
#' @param summary A single logical value. If TRUE, print matched-code counts by
#'   code system.
#' @return A data frame containing the identifier and requested indicators.
#' @export
impact <- function(data, id, codesystems, searchvars, level,
                   multimorbidity = FALSE, summary = FALSE) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  if (!is.character(id) || length(id) != 1L || is.na(id)) {
    stop("id must be one column name.", call. = FALSE)
  }
  if (startsWith(id, "__")) {
    stop(
      "Identifier column names beginning '__' are reserved for IMPACT outputs.",
      call. = FALSE
    )
  }
  if (!(id %in% names(data))) {
    stop("Identifier column '", id, "' was not found.", call. = FALSE)
  }
  .impact_validate_logical(multimorbidity, "multimorbidity")
  .impact_validate_logical(summary, "summary")
  if (missing(level) || length(level) != 1L) {
    stop("level must be specified as 'ltc' or 'phenotype'.", call. = FALSE)
  }
  level <- match.arg(tolower(level), c("ltc", "phenotype"))
  codesystems <- .impact_as_codesystems(codesystems)
  if (!is.list(searchvars)) {
    searchvars <- if (length(codesystems) == 1L) list(searchvars) else as.list(searchvars)
  }
  searchvars <- lapply(searchvars, function(x) as.character(unlist(x, use.names = FALSE)))
  if (length(codesystems) != length(searchvars)) {
    stop("The number of code systems and search-variable groups must be equal.",
         call. = FALSE)
  }
  if (length(codesystems) == 0L || any(lengths(searchvars) == 0L)) {
    stop("codesystems and searchvars must not be empty.", call. = FALSE)
  }

  canonical <- vapply(codesystems, .impact_normalize_codesystem, character(1))
  for (cols in searchvars) {
    missing_cols <- setdiff(cols, names(data))
    if (length(missing_cols)) {
      stop("Search variable(s) not found: ", paste(missing_cols, collapse = ", "),
           call. = FALSE)
    }
    non_character <- cols[!vapply(data[cols], is.character, logical(1))]
    if (length(non_character)) {
      stop(
        "Search variable(s) must be character columns: ",
        paste(non_character, collapse = ", "),
        ". Store clinical codes as character values to preserve leading ",
        "zeroes and long identifiers.",
        call. = FALSE
      )
    }
  }

  target_ids <- if (level == "ltc") .impact_ltc_ids else .impact_phenotype_ids
  indicator_names <- paste0("__", target_ids)
  flags <- matrix(0L, nrow = nrow(data), ncol = length(target_ids),
                  dimnames = list(NULL, indicator_names))
  result <- cbind(data[id], as.data.frame(flags, check.names = FALSE))

  lookups <- vector("list", length(canonical))
  for (i in seq_along(canonical)) {
    lookup <- get(canonical[[i]], envir = .impact_lookup_store, inherits = FALSE)
    lookups[[i]] <- lookup
    for (column in searchvars[[i]]) {
      values <- trimws(as.character(data[[column]]))
      for (code in unique(values[!is.na(values) & values != ""])) {
        ltcs <- lookup[[code]]
        if (is.null(ltcs)) next
        targets <- if (level == "ltc") {
          unique(as.character(ltcs))
        } else {
          unique(unname(.impact_ltc_phenotypes[as.character(ltcs)]))
        }
        rows <- which(!is.na(values) & values == code)
        result[rows, paste0("__", targets)] <- 1L
      }
    }
  }

  if (isTRUE(multimorbidity)) {
    result <- .impact_add_multimorbidity(result, level)
  }

  if (isTRUE(summary)) {
    cat("\nIMPACT summary:", nrow(data), "coded event(s)\n")
    for (i in seq_along(canonical)) {
      keys <- ls(lookups[[i]], all.names = TRUE)
      total <- sum(vapply(searchvars[[i]], function(column) {
        values <- trimws(as.character(data[[column]]))
        sum(!is.na(values) & values %in% keys)
      }, integer(1)))
      cat(" ", codesystems[[i]], ": ", total, " matched code(s)\n", sep = "")
    }
  }

  result
}

.impact_validate_logical <- function(value, name) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop(name, " must be either TRUE or FALSE.", call. = FALSE)
  }
}

.impact_as_codesystems <- function(value) {
  if (is.character(value) && length(value) == 1L) {
    value <- strsplit(value, "[,[:space:]]+")[[1L]]
  }
  value <- tolower(as.character(unlist(value, use.names = FALSE)))
  value[nzchar(value)]
}

.impact_canonical_codesystems <- c(
  "cprd_aurum_medcodeid", "cprd_gold_medcode", "emis_local", "icd10",
  "icd10cm", "icd10pcs", "icd9cm", "icd9pcs", "opcs4",
  "read_cleansed", "read_original", "snomed_concept", "snomed_description"
)

.impact_normalize_codesystem <- function(value) {
  value <- tolower(value)
  if (!(value %in% .impact_canonical_codesystems)) {
    stop("Unknown code system '", value, "'. See list_codesystems().", call. = FALSE)
  }
  value
}

.impact_system_name <- function(value) {
  value <- tolower(gsub("&", "and", value, fixed = TRUE))
  value <- gsub("[^a-z0-9]+", "_", value)
  sub("_$", "", sub("^_", "", value))
}

.impact_add_multimorbidity <- function(result, level) {
  phenotype_names <- paste0("__", .impact_phenotype_ids)
  if (level == "phenotype") {
    phenotype_flags <- as.matrix(result[phenotype_names])
  } else {
    phenotype_flags <- matrix(
      0L, nrow = nrow(result), ncol = length(.impact_phenotype_ids),
      dimnames = list(NULL, phenotype_names)
    )
    for (ltc in .impact_ltc_ids) {
      phenotype <- unname(.impact_ltc_phenotypes[[ltc]])
      column <- paste0("__", phenotype)
      phenotype_flags[, column] <- pmax(
        phenotype_flags[, column], result[[paste0("__", ltc)]]
      )
    }
  }

  result[["__nphenotypes"]] <- rowSums(phenotype_flags)
  mental <- .impact_phenotype_ids[.impact_phenotype_categories == "Mental"]
  result[["__nmental"]] <- rowSums(phenotype_flags[, paste0("__", mental), drop = FALSE])
  result[["__nphysical"]] <- result[["__nphenotypes"]] - result[["__nmental"]]

  systems <- unique(unname(.impact_phenotype_systems))
  body_present <- matrix(FALSE, nrow = nrow(result), ncol = length(systems))
  for (i in seq_along(systems)) {
    phenotypes <- .impact_phenotype_ids[.impact_phenotype_systems == systems[[i]]]
    counts <- rowSums(phenotype_flags[, paste0("__", phenotypes), drop = FALSE])
    result[[paste0("__bs_", .impact_system_name(systems[[i]]))]] <- counts
    body_present[, i] <- counts > 0L
  }
  result[["__nbody"]] <- rowSums(body_present)
  result
}

#' Return an LTC lookup for a supported code system.
#'
#' @param ontology A value returned by `list_codesystems()`.
#' @return An independent environment mapping code strings to LTC identifier
#'   vectors. Modifying it does not alter IMPACT's internal lookup.
#' @export
select_codesystem <- function(ontology) {
  canonical <- .impact_normalize_codesystem(ontology)
  lookup <- get(canonical, envir = .impact_lookup_store, inherits = FALSE)
  list2env(
    as.list.environment(lookup, all.names = TRUE),
    hash = TRUE,
    parent = emptyenv()
  )
}

#' List supported code-system names.
#'
#' @return A character vector.
#' @export
list_codesystems <- function() {
  .impact_canonical_codesystems
}

#' List IMPACT granular LTC metadata.
#'
#' @return A data frame with LTC and grouped-phenotype metadata.
#' @export
list_ltcs <- function() {
  phenotypes <- unname(.impact_ltc_phenotypes[.impact_ltc_ids])
  data.frame(
    ltc = .impact_ltc_ids,
    label = unname(.impact_ltc_labels[.impact_ltc_ids]),
    phenotype = phenotypes,
    phenotype_label = unname(.impact_phenotype_labels[phenotypes]),
    body_system = unname(.impact_phenotype_systems[phenotypes]),
    category = unname(.impact_phenotype_categories[phenotypes]),
    stringsAsFactors = FALSE
  )
}
