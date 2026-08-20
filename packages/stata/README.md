# IMPACT — Stata package

This is the Stata implementation of IMPACT — the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool. It may be used to ascertain 321 granular LTC indicators or 116 grouped phenotype indicators from row-level coded-event healthcare data.

## Install directly from GitHub

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/impact
net install impact, replace
help impact
```

IMPACT is not distributed through SSC. For local development, clone the
repository and add the implementation folder to Stata's ado-path:

```stata
adopath ++ "C:\path\to\impact\packages\stata\impact"
```

## Run IMPACT

```stata
clear all
impact, dataset("events.dta") id(patid) codesystems(icd10) ///
    searchvars(icdcode) level(phenotype) multimorbidity summary
```

`level()` is required:

- `level(ltc)` returns 321 granular `__<LTC>` indicators.
- `level(phenotype)` returns 116 grouped `__<phenotype>` indicators.

`codesystems()` and `searchvars()` are ordered pairs. A wildcard expression in
one search-variable position can search several columns with the same code
system. Search variables must be strings.

Supported canonical systems are `cprd_aurum_medcodeid`,
`cprd_gold_medcode`, `emis_local`, `icd10`, `icd10cm`, `icd10pcs`, `icd9cm`,
`icd9pcs`, `opcs4`, `read_cleansed`, `read_original`, `snomed_concept`, and
`snomed_description`. Aliases are `cprdaurum`, `medcodeid`, and `cprdgold`.

The command replaces the empty Stata session with an output dataset containing
the identifier and indicators. `multimorbidity` adds phenotype-based
`__nphenotypes`, `__nmental`, `__nphysical`, `__bs_<system>`, and `__nbody`.
Grouped phenotypes are counted even with `level(ltc)`.

`summary` prints matched-code counts.

Run [`stata_example.do`](stata_example.do) from this directory to exercise both
output levels on hard-coded sample data.
