# Functional example for the IMPACT R package.
# Run from packages/r with: Rscript r_example.R

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else if (requireNamespace("impact", quietly = TRUE)) {
  library(impact)
} else {
  load(file.path("R", "sysdata.rda"), envir = .GlobalEnv)
  source(file.path("R", "impact.R"), local = .GlobalEnv)
}

stopifnot(length(list_codesystems()) >= 13L)
stopifnot(nrow(list_ltcs()) == 321L)

events <- data.frame(
  patid = c(1L, 1L, 2L, 2L, 3L),
  icdcode = c("410.01", "427.31", "250.00", "493.00", "999.99"),
  stringsAsFactors = FALSE
)

ltc_out <- impact(
  events, id = "patid", codesystems = "icd9cm",
  searchvars = "icdcode", level = "ltc",
  multimorbidity = TRUE, summary = TRUE
)
stopifnot(
  ltc_out[["__STMI"]][1] == 1L,
  ltc_out[["__CORO"]][1] == 1L,
  ltc_out[["__AFIB"]][2] == 1L,
  ltc_out[["__T2DM"]][3] == 1L,
  ltc_out[["__ASTH"]][4] == 1L,
  ltc_out[["__STMI"]][5] == 0L,
  ltc_out[["__nphenotypes"]][1] == 2L,
  ltc_out[["__nmental"]][1] == 0L,
  ltc_out[["__nphysical"]][1] == 2L,
  ltc_out[["__nbody"]][1] == 1L
)

phenotype_out <- impact(
  events, id = "patid", codesystems = "icd9cm",
  searchvars = list("icdcode"), level = "phenotype",
  multimorbidity = TRUE
)
stopifnot(
  phenotype_out[["__ACSN"]][1] == 1L,
  phenotype_out[["__CORO"]][1] == 1L,
  phenotype_out[["__AFIB"]][2] == 1L,
  phenotype_out[["__DIAB"]][3] == 1L,
  phenotype_out[["__ASTH"]][4] == 1L,
  phenotype_out[["__ACSN"]][5] == 0L,
  phenotype_out[["__nphenotypes"]][1] == 2L
)

# IMPORTANT: IMPACT output and multimorbidity counts are event-level. To
# obtain patient-level phenotypes, take the maximum of each phenotype flag
# across all events for the identifier, then recalculate the phenotype count.
message("Aggregating event-level output to patient-level phenotypes...")
phenotype_columns <- grep(
  "^__[A-Z0-9]{4}$", names(phenotype_out), value = TRUE
)
patient_out <- aggregate(
  phenotype_out[phenotype_columns],
  by = list(patid = phenotype_out$patid),
  FUN = max
)
patient_out[["__nphenotypes"]] <- rowSums(patient_out[phenotype_columns])
stopifnot(
  patient_out[["__nphenotypes"]][patient_out$patid == 1L] == 3L,
  patient_out[["__nphenotypes"]][patient_out$patid == 2L] == 2L,
  patient_out[["__nphenotypes"]][patient_out$patid == 3L] == 0L
)

error_seen <- tryCatch({
  impact(events, "patid", "icd9cm", "icdcode")
  FALSE
}, error = function(e) grepl("level", conditionMessage(e)))
stopifnot(error_seen)

message("OK: IMPACT R example passed")

