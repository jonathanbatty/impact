# IMPACT — the Inclusive Multimorbidity Phenotyping Algorithm

IMPACT (the **I**nclusive **M**ultimorbidity **P**henotyping **A**lgorithm and **C**oding **T**ool)
ascertains long-term conditions (LTCs) from routinely collected, coded
healthcare data used in the UK. Given a dataset of coded diagnoses, procedures
or clinical events (one row per code), IMPACT maps each code to one or more of
120 long-term conditions and returns one 0/1 indicator variable per condition
(named `__<LTC>`).

The algorithm is implemented as three installable packages with a consistent
interface:

- **Stata** — the `impact` command (`.ado`/`.mata` files)
- **R** — the `impact()` function (an R package)
- **Python** — the `impact.impact()` function (a Python package)

## What is ascertained

The codelists cover the following coding systems, each stored as plain-text
lists in [`codelists/`](codelists/):

| Code system        | Description                                 |
|--------------------|---------------------------------------------|
| `icd9cm`           | ICD-9-CM diagnosis codes                    |
| `icd9pcs`          | ICD-9-PCS procedure codes                   |
| `icd10cm`          | ICD-10-CM (US clinical modification) codes  |
| `icd10pcs`         | ICD-10-PCS procedure codes                  |
| `icd10`            | ICD-10 (UK version) diagnosis codes         |
| `opcs4`            | OPCS-4 procedure codes                      |
| `cprdaurum`        | CPRD Aurum medcodeid values (alias: `medcodeid`) |

All three packages accept either `cprdaurum` or `medcodeid` for the CPRD Aurum
codelists.

Each codelist maps codes to long-term conditions such as diabetes, coronary
artery disease, chronic kidney disease, asthma, and 115 more. The full set of
conditions, their labels, body systems, and mental/physical category are
included in each package (`__ltcs` metadata). The plain-text master codelists
in `codelists/` are the source of truth; the per-package code-definition files
(`__icd*.ado`, `__icd*.R`, `__icd*.py`) are generated from them by
[`buildfile.py`](buildfile.py).

## Repository layout

- [`codelists/`](codelists/) — the master plain-text codelists, one file per
  condition per code system.
- [`packages/stata/`](packages/stata/) — the Stata package (`impact.ado`,
  `impact.mata`, `impact.sthlp`, `__ltcs.ado`, and `__icd*.ado`).
- [`packages/r/`](packages/r/) — the R package (`impact.R`, `__ltcs.R`, and
  `__icd*.R`).
- [`packages/python/`](packages/python/) — the Python package (`impact.py`,
  `__ltcs.py`, and `__icd*.py`).
- [`buildfile.py`](buildfile.py) — regenerates the per-package code-definition
  files from the master codelists.

All packages are installed **directly from this GitHub repository**
(`jonathanbatty/impact`); no formal package managers (ssc, pip, CRAN) are used.

## Installation

### 1. Stata

Install from the raw GitHub file URL with Stata's `net` command:

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/
net install impact, replace
```

This installs `impact.ado`, `impact.mata`, `impact.sthlp`, `__ltcs.ado`, and
all `__icd*.ado` files. Run `help impact` to see the full documentation.

*Manual fallback:* clone this repository and add the package folder to the
ado-path:

```stata
adopath + "C:\path\to\impact\packages\stata"
```

### 2. R

Install the package in `packages/r/` directly from GitHub with `devtools`:

```r
install.packages("devtools")          # if not already installed
devtools::install_github("jonathanbatty/impact", subdir = "packages/r")
```

Then load it with `library(impact)`.

### 3. Python

Install the package in `packages/python/` directly from GitHub with `pip`:

```bash
pip install "git+https://github.com/jonathanbatty/impact#subdirectory=packages/python"
```

This installs the `impact` package (requires `pandas`). You may also install
in editable mode for development:

```bash
pip install -e "git+https://github.com/jonathanbatty/impact#subdirectory=packages/python"
```

## Package documentation

The three implementations share a consistent interface. The only intentional
difference: in Stata the input is the **path to a dataset on disk**
(`dataset()`), while in R and Python the input is an **in-memory
data frame / DataFrame** of coded events. All other options have the same name
and meaning.

### Stata — `impact`

```stata
impact, dataset(events.dta) id(patid) codesystems(icd10) searchvars(icdcode) ///
        [n_cores(1) multimorbidity summary]
```

| Option            | Description                                                          |
|-------------------|----------------------------------------------------------------------|
| `dataset(string)` | Path to the dataset to be searched (one row per coded event).        |
| `id(string)`      | Unique identifier variable.                                          |
| `codesystems(string)` | Coding system(s), one per search variable (see table above).     |
| `searchvars(string)`  | Variable(s) to search, in the same order as `codesystems`.       |
| `n_cores(integer)` | CPU cores to use (default 1; 0 = all available).                     |
| `multimorbidity`  | Add multimorbidity variables (`__nltc`, `__nmental`, `__nphysical`, `__nbody`, `__bs_<system>`). |
| `summary`         | Print per-codelist matched-code counts.                              |

The output dataset contains the identifier plus one `__<LTC>` 0/1 column per
long-term condition, and (with `multimorbidity`) the multimorbidity variables.

### R — `impact()`

```r
out <- impact(data, id = "patid",
              codesystems = "icd10", searchvars = list("icdcode"),
              n_cores = 1, multimorbidity = FALSE, summary = FALSE)
```

Arguments are identical to the Stata options, except that `data` is the
in-memory data frame instead of `dataset` (a path). `searchvars` is a list,
one element per code system, each a vector of column names. It returns a data
frame with the identifier and `__<LTC>` indicator columns. Helpers:
`select_codesystem("icd10")`, `list_codesystems()`, `list_ltcs()`.

### Python — `impact()`

```python
import pandas as pd
from impact import impact

out = impact(df, id="patid",
             codesystems=["icd10"], searchvars=["icdcode"],
             n_cores=1, multimorbidity=False, summary=False)
```

Arguments are identical to the R version, with `df` the in-memory pandas
DataFrame. It returns a DataFrame with the identifier and `__<LTC>` indicator
columns. Helpers: `impact.select_codesystem("icd10")`,
`impact.list_codesystems()`, `impact.list_ltcs()`.

## Examples

Minimal worked examples for each language are in the package folders:
`packages/stata/smoke_test.do`, `packages/r/tests/smoke_test.R`, and
`packages/python/smoke_test.py` (or `packages/python/src/example.py`).

## License

MIT — see [LICENSE](LICENSE).
