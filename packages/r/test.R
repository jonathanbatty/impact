# Functional test for the IMPACT R package.
# Run from packages/r with: Rscript test.R

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(impact)
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

error_seen <- tryCatch({
  impact(events, "patid", "icd9cm", "icdcode")
  FALSE
}, error = function(e) grepl("level", conditionMessage(e)))
stopifnot(error_seen)

message("OK: IMPACT R functional test passed")
