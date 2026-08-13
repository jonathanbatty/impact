# impact — R package

The R implementation of the Inclusive Multimorbidity Phenotyping Algorithm.
It ascertains long-term conditions (LTCs) from a data frame of coded diagnoses,
procedures or clinical events (one row per code) and returns one 0/1 indicator
column per condition (named `__<LTC>`).

## Install from GitHub

```r
install.packages("devtools")          # if not already installed
devtools::install_github("jonathanbatty/impact", subdir = "packages/r")
```

Then load it with `library(impact)`.

## Interface

```r
out <- impact(data, id = "patid",
              codesystems = "icd10", searchvars = list("icdcode"),
              n_cores = 1, multimorbidity = FALSE, summary = FALSE)
```

| Argument        | Description                                                          |
|-----------------|----------------------------------------------------------------------|
| `data`          | In-memory data frame of coded events (one row per code).             |
| `id`            | Name of the unique identifier column.                                |
| `codesystems`   | Coding system(s), one per search variable: `icd9cm`, `icd9pcs`, `icd10cm`, `icd10pcs`, `icd10`, `opcs4`, `cprdaurum` (or `medcodeid`). |
| `searchvars`    | List of column name(s) to search, one per code system. Each element may be a vector of columns. |
| `n_cores`       | CPU cores to use (default 1; 0 = all available). This release runs serially; accepted for interface compatibility. |
| `multimorbidity`| Add `__nltc`, `__nmental`, `__nphysical`, `__nbody`, `__bs_<system>`.|
| `summary`       | Print per-codelist matched-code counts.                              |

The result is a data frame with the identifier and `__<LTC>` indicator columns,
plus multimorbidity variables if requested.

## Helpers

- `select_codesystem("icd10")` — return the code-to-LTC lookup for one system.
- `list_codesystems()` — names of the supported code systems.
- `list_ltcs()` — metadata for all 120 LTCs (label, body system, category).

## Example

See `tests/smoke_test.R`:

```r
library(devtools); load_all(".")
events <- data.frame(patid = c(1, 1, 2), icdcode = c("41001", "42731", "25000"))
out <- impact(events, id = "patid", codesystems = "icd9cm",
              searchvars = list("icdcode"), multimorbidity = TRUE)
```
