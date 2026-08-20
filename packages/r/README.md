# IMPACT — R package

This is the `R` implementation of IMPACT — the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool.

It may be used to ascertain 321 granular LTC indicators or 116 grouped phenotype indicators from row-level coded-event healthcare data.

## Install directly from GitHub

The `R` IMPACT package is not distributed through CRAN. It can be installed directly from this GitHub repository using:

```r
install.packages("remotes") # if remotes is not already installed
remotes::install_github("jonathanbatty/impact", subdir = "packages/r")
library(impact)
```

The package's code lookups and LTC/phenotype metadata are stored as compressed internal data in `R/sysdata.rda`. This file is generated from the repository's authoritative `codelist/master_codelist.csv` by `buildfile.py` and should not be edited directly.

## Help

The `R` help file is made available after installation and can be viewed by running `?impact` or `help(impact)`.

## Run IMPACT

The basic usage of IMPACT is as below:

```r
out <- impact(events, id = "patid", codesystems = "icd10",
              searchvars = "icdcode", level = "phenotype",
              multimorbidity = TRUE, summary = TRUE)
```

`data`, `id`, `codesystems`, `searchvars` and `level` are required.

Specifying level as:

- `level = "ltc"` returns 321 granular `__<LTC>` indicators.
- `level = "phenotype"` returns 116 grouped `__<phenotype>` indicators.

Note that both levels cannot be returned in a single run.

`codesystems` and `searchvars` are ordered pairs. For several coding systems, pass one search-column group per system. All variables to search should be character vectors so that leading zeroes, decimal points and long identifiers are preserved.

```r
out <- impact(events, id = "patid",
              codesystems = c("icd10", "opcs4"),
              searchvars = list("diagnosis", c("procedure_1", "procedure_2")),
              level = "ltc")
```

Supported code systems are `icd10`, `opcs4`, `read_original`, `read_cleansed`, `snomed_concept`, `snomed_description`, `emis_local`, `cprd_gold_medcode`, `cprd_aurum_medcodeid`, `icd10cm`, `icd10pcs`, `icd9cm` and `icd9pcs`.

The function processes `events` and returns a data frame containing the original identifier and indicators. The output remains at the same row level as the input data. Repeated patient identifiers are retained and are not collapsed or aggregated. Setting `summary = TRUE` prints the number of matched codes for each selected coding system.

`multimorbidity = TRUE` adds the following additional multimorbidity-relevant variables:

| Variable | Description |
| --- | --- |
| `__nphenotypes` | Number of the 116 grouped phenotypes identified. Multiple LTCs belonging to the same phenotype are counted once. |
| `__nmental` | Number of grouped phenotypes classified as mental health conditions. |
| `__nphysical` | Number of grouped phenotypes classified as physical health conditions. |
| `__bs_<system>` | Number of grouped phenotypes identified within the specified body-system category, for example `__bs_cardiovascular`. |
| `__nbody` | Number of distinct body-system categories affected. A body system is counted once when at least one phenotype within it is identified. |

Grouped phenotypes are counted even when `level = "ltc"` has been specified.

Additional helper functions are available:

- `select_codesystem("icd10")` returns a code-to-granular-LTC environment.
- `list_codesystems()` lists the supported code-system names.
- `list_ltcs()` returns all 321 LTCs with their phenotype metadata.

See [`r_example.R`](r_example.R) as an example of how to run IMPACT on sample data.
