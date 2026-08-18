# R ignores package source files whose names begin with an underscore. Locate
# the immutable generated resources explicitly while the namespace is built,
# then capture their contents in the package's lazy-load database.
.impact_definition_candidates <- unique(c(
  file.path(Sys.getenv("R_PACKAGE_SOURCE"), "R"),
  file.path(getwd(), "R"),
  file.path(getwd(), "packages", "r", "R")
))
.impact_definition_dir <- .impact_definition_candidates[
  file.exists(file.path(.impact_definition_candidates, "__ltcs.R"))
][1L]
.impact_archive_candidates <- unique(c(
  file.path(Sys.getenv("R_PACKAGE_SOURCE"), "inst", "extdata", "impact_r_definitions.zip"),
  file.path(getwd(), "inst", "extdata", "impact_r_definitions.zip"),
  file.path(getwd(), "packages", "r", "inst", "extdata", "impact_r_definitions.zip")
))
.impact_definition_archive <- .impact_archive_candidates[
  file.exists(.impact_archive_candidates)
][1L]
if (is.na(.impact_definition_dir) && is.na(.impact_definition_archive)) {
  stop("IMPACT's immutable R definition resources could not be located.")
}

.impact_source_definition <- function(name) {
  filename <- paste0("__", name, ".R")
  target <- environment(.impact_source_definition)
  if (!is.na(.impact_definition_dir)) {
    sys.source(
      file.path(.impact_definition_dir, filename),
      envir = target,
      keep.source = FALSE
    )
  } else {
    connection <- unz(.impact_definition_archive, filename, open = "rb")
    on.exit(close(connection))
    definition <- rawToChar(readBin(connection, what = "raw", n = 5000000L))
    Encoding(definition) <- "UTF-8"
    definition <- gsub("\\r\\n?", "\n", definition)
    eval(parse(text = definition, keep.source = FALSE), envir = target)
  }
}

.impact_codesystems_to_capture <- c(
  "cprd_aurum_medcodeid", "cprd_gold_medcode", "emis_local", "icd10",
  "icd10cm", "icd10pcs", "icd9cm", "icd9pcs", "opcs4",
  "read_cleansed", "read_original", "snomed_concept", "snomed_description"
)
for (.impact_name in .impact_codesystems_to_capture) {
  .impact_source_definition(.impact_name)
  .impact_capture_lookup(.impact_name, generate_lookup)
}

.impact_source_definition("ltcs")
.impact_ltc_ids <- ltc_id
.impact_ltc_labels <- setNames(ltc_label, ltc_id)
.impact_ltc_phenotypes <- setNames(phenotype_id, ltc_id)

.impact_source_definition("phenotypes")
.impact_phenotype_ids <- phenotype_id
.impact_phenotype_labels <- setNames(phenotype_label, phenotype_id)
.impact_phenotype_systems <- setNames(phenotype_body_system, phenotype_id)
.impact_phenotype_categories <- setNames(phenotype_category, phenotype_id)

rm(
  generate_lookup, ltc_id, ltc_label, phenotype_id, phenotype_label,
  phenotype_body_system, phenotype_category, .impact_name
)
