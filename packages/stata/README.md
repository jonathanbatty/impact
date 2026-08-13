# impact — Stata package

The Stata implementation of the Inclusive Multimorbidity Phenotyping Algorithm.
It ascertains long-term conditions (LTCs) from a dataset of coded diagnoses,
procedures or clinical events (one row per code) and returns one 0/1 indicator
variable per condition (named `__<LTC>`).

## Install from GitHub

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/
net install impact, replace
```

This installs `impact.ado`, `impact.mata`, `impact.sthlp`, `__ltcs.ado`, and
all `__icd*.ado` files. Run `help impact` for the full documentation.

*Manual fallback:* clone the repository and add the folder to the ado-path:
`adopath + "C:\path\to\impact\packages\stata"`.

## Interface

```stata
impact, dataset(events.dta) id(patid) codesystems(icd10) searchvars(icdcode) ///
        [n_cores(1) multimorbidity summary]
```

| Option              | Description                                                         |
|---------------------|---------------------------------------------------------------------|
| `dataset(string)`   | Path to the dataset to be searched (one row per coded event).       |
| `id(string)`        | Unique identifier variable.                                         |
| `codesystems(string)` | Coding system(s), one per search variable: `icd9cm`, `icd9pcs`, `icd10cm`, `icd10pcs`, `icd10`, `opcs4`, `medcodeid` (or `cprdaurum`). |
| `searchvars(string)`  | Variable(s) to search, in the same order as `codesystems`.       |
| `n_cores(integer)`  | CPU cores to use (default 1; 0 = all available). This release runs serially. |
| `multimorbidity`    | Add `__nltc`, `__nmental`, `__nphysical`, `__nbody`, `__bs_<system>`. |
| `summary`           | Print per-codelist matched-code counts.                             |

The output dataset contains the identifier plus one `__<LTC>` column per
long-term condition, and (with `multimorbidity`) the multimorbidity variables.

## Example

See `smoke_test.do`:

```stata
clear all
input long patid str30 icdcode
1 "41001"
2 "49300"
end
save "events.dta", replace
impact, dataset("events.dta") id(patid) codesystems(icd9cm) searchvars(icdcode) multimorbidity summary
```
