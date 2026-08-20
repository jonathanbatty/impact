# IMPACT — Stata package

This is the `Stata` implementation of IMPACT — the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool. 

It may be used to ascertain 321 granular LTC indicators or 116 grouped phenotype indicators from row-level coded-event healthcare data.

## Install directly from GitHub

The `Stata` IMPACT package is not distributed through SSC. It can be installed directly from this GitHub repository using the following command:

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/impact
net install impact, replace
```

## Help
A `Stata` help file is made available after installation and can be viewed by running: `help impact`

## Run IMPACT

The basic usage of IMPACT is as below:

```stata
clear all
impact, dataset("events.dta") id(patid) codesystems(icd10) ///
        searchvars(icdcode) level(phenotype) multimorbidity summary
```

`dataset()`, `id()`, `codesystems()`, `searchvars()` and `level()` are required.
IMPACT must be run with no dataset currently loaded; use `clear all` before
calling the command.

Specifying level as:

- `level(ltc)` returns 321 granular `__<LTC>` indicators.
- `level(phenotype)` returns 116 grouped `__<phenotype>` indicators.

Note that both levels cannot be returned in a single run.

`codesystems()` and `searchvars()` are ordered pairs. A wildcard expression in one search-variable position can search several columns with the same code system. All variables to search must be strings.

Supported code systems are `icd10`, `opcs4`, `read_original`, `read_cleansed`, `snomed_concept`, `snomed_description`, `emis_local`, `cprd_gold_medcode`, `cprd_aurum_medcodeid`, `icd10cm`, `icd10pcs`, `icd9cm` and `icd9pcs`.

The command processes `"events.dta"` and produces an output dataset containing
the original identifier and indicators. The output remains at the same row
level as the input dataset. Repeated patient
identifiers are retained and are not collapsed or aggregated. The `summary`
option prints the number of matched codes for each selected coding system.

`multimorbidity` adds the following additional multimorbidity-relevant variables:

| Variable | Description |
| --- | --- |
| `__nphenotypes` | Number of the 116 grouped phenotypes identified. Multiple LTCs belonging to the same phenotype are counted once. |
| `__nmental` | Number of grouped phenotypes classified as mental health conditions. |
| `__nphysical` | Number of grouped phenotypes classified as physical health conditions. |
| `__bs_<system>` | Number of grouped phenotypes identified within the specified body-system category, for example `__bs_cardiovascular`. |
| `__nbody` | Number of distinct body-system categories affected. A body system is counted once when at least one phenotype within it is identified. |

Grouped phenotypes are counted even when `level(ltc)` has been specified.

See [`stata_example.do`](stata_example.do) as an example of how to run IMPACT on sample data.
