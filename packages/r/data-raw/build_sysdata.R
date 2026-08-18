args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop(
    "Usage: build_sysdata.R LOOKUPS.csv LTCS.csv PHENOTYPES.csv OUTPUT.rda",
    call. = FALSE
  )
}

read_utf8_csv <- function(path) {
  read.csv(
    path,
    colClasses = "character",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    na.strings = character()
  )
}

lookup_rows <- read_utf8_csv(args[[1L]])
ltc_metadata <- read_utf8_csv(args[[2L]])
phenotype_metadata <- read_utf8_csv(args[[3L]])

.impact_lookup_store <- new.env(hash = TRUE, parent = emptyenv())
for (codesystem in unique(lookup_rows$code_type)) {
  rows <- lookup_rows[lookup_rows$code_type == codesystem, , drop = FALSE]
  values <- lapply(split(rows$ltc_id, rows$code), unique)
  lookup <- list2env(values, hash = TRUE, parent = emptyenv())
  assign(codesystem, lookup, envir = .impact_lookup_store)
}

.impact_ltc_ids <- ltc_metadata$ltc_id
.impact_ltc_labels <- setNames(ltc_metadata$ltc_name, ltc_metadata$ltc_id)
.impact_ltc_phenotypes <- setNames(
  ltc_metadata$phenotype_id,
  ltc_metadata$ltc_id
)

.impact_phenotype_ids <- phenotype_metadata$phenotype_id
.impact_phenotype_labels <- setNames(
  phenotype_metadata$phenotype_name,
  phenotype_metadata$phenotype_id
)
.impact_phenotype_systems <- setNames(
  phenotype_metadata$body_system,
  phenotype_metadata$phenotype_id
)
.impact_phenotype_categories <- setNames(
  phenotype_metadata$type,
  phenotype_metadata$phenotype_id
)
.impact_phenotype_sex <- setNames(
  phenotype_metadata$sex,
  phenotype_metadata$phenotype_id
)

save(
  .impact_lookup_store,
  .impact_ltc_ids,
  .impact_ltc_labels,
  .impact_ltc_phenotypes,
  .impact_phenotype_ids,
  .impact_phenotype_labels,
  .impact_phenotype_systems,
  .impact_phenotype_categories,
  .impact_phenotype_sex,
  file = args[[4L]],
  compress = "xz",
  version = 2
)
