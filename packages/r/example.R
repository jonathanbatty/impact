library(devtools)
load_all(".")

icd10map <- select_codesystem("icd10cm")

icd10map[["I10"]]