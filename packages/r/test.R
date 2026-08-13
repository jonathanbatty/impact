# Development usage (load the package in place):
library(devtools)
load_all(".")

# Load an ICD-9-CM code lookup and look up a single code
icd9map <- select_codesystem("icd9cm")
icd9map[["41001"]]   # "Acute myocardial infarction of anterolateral wall"

# Build a small example data frame of coded events (one row per code)
events <- data.frame(
  patid   = c(1, 1, 2, 2, 3),
  icdcode = c("41001", "42731", "25000", "49300", "99999"),
  stringsAsFactors = FALSE
)

# Ascertain long-term conditions, adding multimorbidity and summary output
out <- impact(events, id = "patid",
              codesystems = "icd9cm", searchvars = list("icdcode"),
              multimorbidity = TRUE, summary = TRUE)

out
