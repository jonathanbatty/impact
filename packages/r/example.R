library(devtools)
load_all(".")

setwd("./R/")

icd10map <- select_codesystem("icd10cm")

icd10map[["I10"]]