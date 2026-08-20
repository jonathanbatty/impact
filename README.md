![IMPACT](assets/header.png "IMPACT")

[![Version](https://img.shields.io/badge/version-1.0-blue)](https://github.com/jonathanbatty/impact)
[![Stata 17+](https://img.shields.io/badge/Stata-17%2B-1f77b4)](packages/stata/README.md)
[![R 3.5+](https://img.shields.io/badge/R-%E2%89%A53.5.0-276DC3?logo=r&logoColor=white)](packages/r/README.md)
[![Python 3.8+](https://img.shields.io/badge/Python-%E2%89%A53.8-3776AB?logo=python&logoColor=white)](packages/python/README.md)
[![Issues](https://img.shields.io/github/issues/jonathanbatty/impact)](https://github.com/jonathanbatty/impact/issues)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Stars](https://img.shields.io/github/stars/jonathanbatty/impact)](https://github.com/jonathanbatty/impact/stargazers)

---

[Introduction](#introduction) | [Installation](#installation) ([Stata](#stata) | [R](#r) | [Python](#python) | [TREs](#TREs)) | [Syntax](#syntax) | [Feedback](#feedback) | [Acknowledgements](#acknowledgements) | [Citation](#suggested-citation)

---

## Introduction

IMPACT — the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool — is designed to ascertain a broad range of long-term conditions from routinely collected, coded healthcare data. It supports the reproducible identification of multimorbidity in UK (and international) healthcare datasets, where diagnoses, procedures and other clinical information may be recorded using several different coding systems.

IMPACT translates individual clinical codes into one or more related classifications:
- 321 granular long-term conditions (LTCs), providing detailed condition-level information;
- 116 grouped phenotypes, combining clinically related LTCs into broader, analytically useful categories; and
- 21 body-system categories, supporting higher-level summaries of the distribution of disease.

Users may select whether the primary output contains the 321 granular LTCs or the 116 grouped phenotypes. Multimorbidity measures are based on the grouped phenotypes, ensuring that several closely related LTCs within the same phenotype are counted only once. IMPACT can also summarise the number of mental and physical phenotypes and the body systems affected.

The tool supports coding systems commonly encountered in UK primary and secondary care data, including ICD-10, OPCS-4, SNOMED CT, Read codes, EMIS local codes and CPRD-specific identifiers. It also includes the US ICD-9-CM and ICD-10-CM mappings. Equivalent implementations are provided for Stata, R and Python, allowing the same master codelist and phenotype definitions to be used across different analytical environments. Installation of these packages should be performed directly from Github (see instructions [Below](#installation)) or can be done by downloading this repository and installing locally (for example, on a [TRE](#TREs))

IMPACT is intended to reduce the duplication and inconsistency involved in developing study-specific multimorbidity definitions. Its definitions are generated from a single master codelist, providing a transparent and maintainable workflow in which updates can be propagated consistently across all three packages. It may be used for cohort description, epidemiological analyses, risk adjustment, healthcare utilisation research, target trial emulations and other studies requiring systematic ascertainment of long-term conditions.

The number of long-term conditions included in each phenotype and for each body system is summarised below:

![Phenotypes](assets/phenotypes.png "mapping")

### Supported coding systems

IMPACT supports the following coding systems:

| Coding system alias | Details and example |
| ---------------------- | ------------------------------------------------------- |
| `icd10`                | The UK implementation of the International Classification of Diseases, 10th Revision (5th Edition), as specified in the [NHS Classification Browser](https://classbrowser.nhs.uk/#/book/ICD-10-5TH-Edition); for example, I21.4 – “Acute subendocardial myocardial infarction”, which includes non-ST elevation myocardial infarction (NSTEMI).          |
| `opcs4`                | The UK classification of interventions and procedures, based on the Office of Population Censuses and Surveys Classification of Interventions and Procedures (OPCS-4), version 4.11, as specified in the [NHS Classification Browser](https://classbrowser.nhs.uk/#/book/OPCS-4.11).                                                                     |
| `read_original`        | A Read code as stored in the source clinical system before standardisation, which may use a shortened or unpadded representation; for example, G3071 – “Acute non-ST segment elevation myocardial infarction”.                                                                                                                                           |
| `read_cleansed`        | A standardised representation of a UK primary-care Read code, reformatted to a consistent structure to facilitate matching and comparison across datasets; for example, G3071 may be represented as G307100 – “Acute non-ST segment elevation myocardial infarction”.                                                                                    |
| `snomed_concept`       | A unique numeric identifier assigned to a clinical concept in SNOMED CT, independent of the particular term used to describe it; for example, 401314000 represents “Non-ST elevation myocardial infarction (NSTEMI)”.                                                                                                                                    |
| `snomed_description`   | A unique numeric identifier assigned to a particular textual description or synonym of a SNOMED CT concept; for example, 1787486017 identifies the description “NSTEMI - Non-ST segment elevation MI”, associated with concept 401314000.                                                                                                                |
| `emis_local`           | A proprietary identifier used within the EMIS clinical system for a clinical term that may not have a standard Read code representation and may instead be linked to a SNOMED CT concept; for example, ^ESCTNS665139 maps to the SNOMED CT concept for NSTEMI.                                                                                           |
| `cprd_aurum_medcodeid` | A unique identifier assigned by CPRD to a clinical term in the CPRD Aurum medical dictionary; for example, 1780501013 identifies “Acute non-ST segment elevation myocardial infarction”.                                                                                                                                                                 |
| `cprd_gold_medcode`    | A unique identifier assigned by CPRD to a clinical term in the CPRD GOLD medical dictionary; for example, 10562 identifies “Acute non-ST segment elevation myocardial infarction”.                                                                                                                                                                       |
| `icd10cm`              | The US Clinical Modification of the International Classification of Diseases, 10th Revision (ICD-10-CM), maintained by the National Center for Health Statistics (NCHS), with official coding guidelines issued jointly with the Centers for Medicare & Medicaid Services (CMS); for example, I21.4 – “Non-ST elevation (NSTEMI) myocardial infarction”. |
| `icd10pcs`             | The US International Classification of Diseases, 10th Revision, Procedure Coding System (ICD-10-PCS), maintained by the Centers for Medicare & Medicaid Services (CMS), for coding procedures performed during inpatient hospital admissions.                                                                                                            |
| `icd9cm`               | The US Clinical Modification of the International Classification of Diseases, 9th Revision (ICD-9-CM), used for diagnosis coding in the United States before the transition to ICD-10-CM on 1 October 2015; for example, 410.71 – “Subendocardial infarction, initial episode of care”, commonly used to code NSTEMI.                                    |
| `icd9pcs`              | ICD-9-CM Volume 3, the former US classification for procedures performed during inpatient hospital admissions, used before the transition to ICD-10-PCS on 1 October 2015.                                                                                                                                                                               |

To simplify the application of IMPACT for use in CPRD datasets, mappings are given at CPRD Gold medcode and CPRD Aurum medcodeid level (see above).

Please note that clinical coding data should be stored as strings so that leading zeroes, decimal points, and long identifiers are preserved. Surrounding whitespace is ignored.

### Codelists and generated definitions

[`codelist/master_codelist.csv`](codelist/master_codelist.csv) is the
authoritative master codelist. [`buildfile.py`](buildfile.py) generates the
Stata `__*.ado` definitions, compressed R internal data in `R/sysdata.rda`,
and the UTF-8 Python package resources from this master file. Generated
definitions should not be edited manually.

From the repository root, rebuild every package definition with:

```bash
python buildfile.py
```

Use `--rscript PATH` if `Rscript` is not on `PATH`. To rebuild only the R and
Python resources without regenerating the Stata definitions, run
`python buildfile.py --resources-only`.

## Installation

### Stata

See the [Stata package README](packages/stata/README.md) for complete usage
instructions.

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/impact
net install impact, replace
help impact
```

### R

See the [R package README](packages/r/README.md) for complete usage
instructions.

```r
install.packages("remotes") # only needed if remotes is not installed
remotes::install_github("jonathanbatty/impact", subdir = "packages/r")
library(impact)
```

### Python

See the [Python package README](packages/python/README.md) for complete usage
instructions.

```bash
python -m pip install "git+https://github.com/jonathanbatty/impact.git#subdirectory=packages/python"
```

Pip is used only to install the GitHub source; IMPACT is not fetched from
PyPI.

### TREs
Trusted research environments (TREs) often restrict access to the open Internet, including GitHub. 

## Syntax

The common IMPACT interface requires an identifier, one or more coding
systems, the corresponding code columns, and the desired output level.

### Stata syntax

```stata
impact, dataset(string) id(varname) codesystems(string) ///
    searchvars(string) level(ltc|phenotype) ///
    [multimorbidity summary]
```

### R syntax

```r
impact(data, id, codesystems, searchvars, level,
       multimorbidity = FALSE, summary = FALSE)
```

### Python syntax

```python
impact(df, id, codesystems, searchvars, level,
       multimorbidity=False, summary=False)
```

| Argument | Meaning |
|---|---|
| `id` | Identifier column retained in the row-level output. |
| `codesystems` | One or more supported coding systems. |
| `searchvars` | Code-column group corresponding to each coding system. |
| `level` | Required output level: `ltc` or `phenotype`. |
| `multimorbidity` | Add phenotype-based multimorbidity measures. |
| `summary` | Print matched-code counts for each selected coding system. |

When `multimorbidity` is selected, IMPACT adds:

- `__nphenotypes`: number of the 116 grouped phenotypes present;
- `__nmental` and `__nphysical`: mental and physical phenotype counts;
- `__bs_<system>`: number of phenotypes present in each body system; and
- `__nbody`: number of body systems affected.

These measures always count grouped phenotypes, even when the requested output
level is `ltc`. Several granular LTCs belonging to one phenotype are therefore
counted once.

## Examples of key syntax

Full details and additional examples are available in the
[Stata](packages/stata/README.md), [R](packages/r/README.md), and
[Python](packages/python/README.md) package READMEs.

### Stata example

```stata
clear all
impact, dataset("events.dta") id(patid) codesystems(icd10) ///
    searchvars(icdcode) level(phenotype) multimorbidity summary
```

### R example

```r
out <- impact(events, id = "patid", codesystems = "icd10",
              searchvars = "icdcode", level = "phenotype",
              multimorbidity = TRUE, summary = TRUE)
```

### Python example

```python
from impact import impact

out = impact(events, id="patid", codesystems="icd10",
             searchvars="icdcode", level="phenotype",
             multimorbidity=True, summary=True)
```

Hard-coded functional examples and assertions are also provided in
[`packages/stata/stata_example.do`](packages/stata/stata_example.do),
[`packages/r/r_example.R`](packages/r/r_example.R), and
[`packages/python/python_example.py`](packages/python/python_example.py).

## Feedback

Please [open an issue](https://github.com/jonathanbatty/impact/issues) to
report suspected errors or omissions in the codelists, identify installation
or runtime problems, suggest feature enhancements, or make any other request.

## Acknowledgements

This work was done while JB was a member of the [Survivorship and Multimorbidity Epidemiology Group](https://multimorbidity-research-leeds.github.io/) at the University of Leeds, led by Dr Marlous Hall.

- JB received funding from a Wellcome Trust 4ward North Clinical Research Training Fellowship (227498/Z/23/Z; R127002).
- MH was funded by the Wellcome Trust Sir Henry Wellcome Postdoctoral Fellowship scheme (206470/Z/17/Z). 

## Suggested citation

Batty, J. A. (2026). *IMPACT: The Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool* (Version 0.1.0) [Computer software].
https://github.com/jonathanbatty/impact
