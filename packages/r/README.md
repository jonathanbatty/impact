# IMPACT — R package

This is the R implementation of IMPACT, the Inclusive Multimorbidity
Phenotyping Algorithm and Coding Tool. It returns either 321 granular LTC
indicators or 116 grouped phenotype indicators for row-level coded-event data.

## Install directly from GitHub

```r
install.packages("remotes") # only if remotes is not installed
remotes::install_github("jonathanbatty/impact", subdir = "packages/r")
library(impact)
```

IMPACT is not distributed through CRAN.

The package's code lookups and LTC/phenotype metadata are stored as compressed
internal data in `R/sysdata.rda`. This file is generated from the repository's
authoritative `codelist/master_codelist.csv` by `buildfile.py`; it should not be
edited directly.

## Run IMPACT

```r
out <- impact(events, id = "patid", codesystems = "icd10",
              searchvars = "icdcode", level = "phenotype",
              multimorbidity = TRUE, summary = TRUE)
```

`level` is required. Use `"ltc"` for 321 granular `__<LTC>` indicators or
`"phenotype"` for 116 grouped `__<phenotype>` indicators.

For several code systems, pass one search-column group per system:

```r
out <- impact(events, id = "patid",
              codesystems = c("icd10", "opcs4"),
              searchvars = list("diagnosis", c("procedure_1", "procedure_2")),
              level = "ltc")
```

Supported canonical systems are `cprd_aurum_medcodeid`,
`cprd_gold_medcode`, `emis_local`, `icd10`, `icd10cm`, `icd10pcs`, `icd9cm`,
`icd9pcs`, `opcs4`, `read_cleansed`, `read_original`, `snomed_concept`, and
`snomed_description`. Aliases are `cprdaurum`, `medcodeid`, and `cprdgold`.

Code columns should be character vectors; surrounding whitespace is ignored.
`multimorbidity = TRUE` adds
phenotype-based `__nphenotypes`, `__nmental`, `__nphysical`,
`__bs_<system>`, and `__nbody`, regardless of the chosen output level.

Helpers:

- `select_codesystem("icd10")` returns a code-to-granular-LTC environment.
- `list_codesystems()` lists canonical names and aliases.
- `list_ltcs()` returns all 321 LTCs with their phenotype metadata.

Run [`r_example.R`](r_example.R) from this directory to exercise both output
levels with hard-coded sample data.
