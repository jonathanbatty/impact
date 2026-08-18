# IMPACT — the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool

IMPACT ascertains long-term conditions from routinely collected, coded
healthcare data used in the UK. It maps each coded event to either:

- 321 granular long-term conditions (LTCs), or
- 116 grouped phenotypes.

The user must select the output level on every run with `level = "ltc"` or
`level = "phenotype"` (and `level(ltc)` or `level(phenotype)` in Stata).
Every input row produces one output row. The identifier is retained, followed
by one binary `__<ID>` indicator for each LTC or phenotype.

The repository provides equivalent implementations for Stata, R and Python.
They are installed directly from GitHub and are not distributed through SSC,
CRAN or PyPI.

## Supported coding systems

| Value | Source coding system |
|---|---|
| `cprd_aurum_medcodeid` | CPRD Aurum medcodeid (`cprdaurum` and `medcodeid` are aliases) |
| `cprd_gold_medcode` | CPRD GOLD medcode (`cprdgold` is an alias) |
| `emis_local` | EMIS local codes |
| `icd10` | ICD-10 |
| `icd10cm` | ICD-10-CM |
| `icd10pcs` | ICD-10-PCS |
| `icd9cm` | ICD-9-CM |
| `icd9pcs` | ICD-9-PCS |
| `opcs4` | OPCS-4 |
| `read_cleansed` | Cleansed Read codes |
| `read_original` | Original Read codes |
| `snomed_concept` | SNOMED CT concept identifiers |
| `snomed_description` | SNOMED CT description identifiers |

Code columns should be stored as strings. This preserves leading zeroes,
decimal points and long identifiers exactly. Surrounding whitespace is ignored.

## Repository structure

- [`codelist/master_codelist.csv`](codelist/master_codelist.csv) is the
  authoritative master codelist. It must not be edited by package code.
- [`packages/stata/`](packages/stata/) contains the Stata implementation.
- [`packages/r/`](packages/r/) contains the R implementation.
- [`packages/python/`](packages/python/) contains the Python implementation.
- [`buildfile.py`](buildfile.py) generates the immutable `__*` definition
  resources from the master codelist.

## Installation from GitHub

### Stata

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/impact
net install impact, replace
help impact
```

### R

```r
install.packages("remotes") # only needed if remotes is not installed
remotes::install_github("jonathanbatty/impact", subdir = "packages/r")
library(impact)
```

### Python

```bash
python -m pip install "git+https://github.com/jonathanbatty/impact.git#subdirectory=packages/python"
```

This uses pip only as the GitHub installer; IMPACT is not fetched from PyPI.

## Common interface

| Argument | Meaning |
|---|---|
| `id` | Identifier column retained in the row-level output. |
| `codesystems` | One or more supported code systems. |
| `searchvars` | Code-column group corresponding to each code system. |
| `level` | Required output level: `ltc` or `phenotype`. |
| `n_cores` | Non-negative integer reserved for interface compatibility; mapping is currently serial. |
| `multimorbidity` | Add phenotype-based multimorbidity measures. |
| `summary` | Print matched-code counts for each selected code system. |

With `multimorbidity`, IMPACT adds:

- `__nphenotypes`: number of the 116 grouped phenotypes present;
- `__nmental` and `__nphysical`: mental and physical phenotype counts;
- `__bs_<system>`: number of phenotypes present in each body system; and
- `__nbody`: number of body systems affected.

These measures count grouped phenotypes even when `level = "ltc"`, so several
granular LTCs belonging to the same phenotype are counted once.

## Examples

### Stata

```stata
clear all
impact, dataset("events.dta") id(patid) codesystems(icd10) ///
    searchvars(icdcode) level(phenotype) multimorbidity summary
```

### R

```r
out <- impact(events, id = "patid", codesystems = "icd10",
              searchvars = "icdcode", level = "phenotype",
              multimorbidity = TRUE, summary = TRUE)
```

### Python

```python
from impact import impact

out = impact(events, id="patid", codesystems="icd10",
             searchvars="icdcode", level="phenotype",
             multimorbidity=True, summary=True)
```

Hard-coded functional examples and assertions are provided in
[`packages/stata/test.do`](packages/stata/test.do),
[`packages/r/test.R`](packages/r/test.R), and
[`packages/python/test.py`](packages/python/test.py).

## License

MIT — see [`LICENSE`](LICENSE).
