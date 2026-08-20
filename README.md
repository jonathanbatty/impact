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

The tool supports coding systems commonly encountered in UK primary and secondary care data, including ICD-10, OPCS-4, SNOMED CT, Read codes, EMIS local codes and CPRD-specific identifiers. It also includes the US ICD-9-CM and ICD-10-CM mappings. Equivalent implementations are provided for Stata, R and Python, allowing the same master codelist and phenotype definitions to be used across different analytical environments. Installation of these packages should be performed directly from GitHub (see instructions [below](#installation)) or can be done by downloading this repository and installing locally (for example, on a [TRE](#TREs))

IMPACT is intended to reduce the duplication and inconsistency involved in developing study-specific multimorbidity definitions. Its definitions are generated from a single master codelist, providing a transparent and maintainable workflow in which updates can be propagated consistently across all three packages. It may be used for cohort description, epidemiological analyses, risk adjustment, healthcare utilisation research, target trial emulations and other studies requiring systematic ascertainment of long-term conditions.

The number of long-term conditions included in each phenotype and for each body system is summarised below:

![Phenotypes](assets/phenotypes.png "mapping")

### Supported coding systems

IMPACT supports the following coding systems:

| Coding system | Details and example |
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

To simplify the application of IMPACT for use in CPRD datasets, mappings are given at CPRD Gold medcode and CPRD Aurum medcodeid level (see above table).

Please note that all clinical coding data should be stored as strings so that leading zeroes, decimal points, and long identifiers are preserved. Surrounding whitespace is ignored.

### Codelists and definitions

The master codelist for IMPACT can be found at [`codelist/master_codelist.csv`](codelist/master_codelist.csv). The definition files for each of the `stata`, `R` and `python` packages are generated from this codelist.
This codelist could be used to apply the IMPACT definitions to other software packages, or in situations in which custom packages cannot be installed.

## Installation

### Stata

See the `Stata` package [README](packages/stata/README.md) for complete installation and usage instructions.

The `Stata` package can be installed using:

```stata
net from https://raw.githubusercontent.com/jonathanbatty/impact/main/packages/stata/impact
net install impact, replace
help impact
```

### R

See the `R` package [README](packages/r/README.md) for complete installation and usage instructions.

The `R` package can be installed using:

```r
install.packages("remotes") # if remotes is not already installed
remotes::install_github("jonathanbatty/impact", subdir = "packages/r")
library(impact)
```

### Python

See the `Python` package [README](packages/python/README.md) for complete installation and usage instructions.

The `Python` package can be installed using:

```bash
python -m pip install "git+https://github.com/jonathanbatty/impact.git#subdirectory=packages/python"
```

Pip is used only to install the package from the GitHub source; IMPACT is not fetched from PyPI.

### TREs
Trusted research environments (TREs, also referred to as Secure Data Environments and Data Safe Havens) often restrict access to the open Internet, including GitHub. In these environments, IMPACT can be [downloaded](https://github.com/jonathanbatty/impact/archive/refs/heads/main.zip) (or cloned) to an Internet-connected computer outside of the TRE, prior to review and transfer via the approved file upload process for the TRE. It can then be installed locally using the local file system. Instructions for each package are given below:

#### Stata

From within Stata, install the package from the transferred repository:

```stata
net install impact, from("C:/path/to/impact/packages/stata/impact") replace
```

Alternatively, the packages/stata/impact directory can be added to the ado-path for a project-specific installation:

```
adopath ++ "C:/path/to/impact/packages/stata/impact"
```

#### R

Install the R package directly from its local source directory using a terminal or command prompt within the TRE:

```bash
R CMD INSTALL "C:/path/to/impact/packages/r"
```

R and the required installation tools must already be available within the TRE.

#### Python

Install the Python package from its local source directory:

```bash
python -m pip install --no-index --no-deps --no-build-isolation "C:/path/to/impact/packages/python"
```

Python, pandas, setuptools and wheel must already be installed within the TRE, or transferred and installed separately through the approved airlock process.

#### Binary and compressed files
IMPACT does not contain compiled executables, DLLs, shared libraries or other native machine-code binaries. It does, however, include generated data resources that are not directly human-readable: the R package contains a compressed R/sysdata.rda file, and the Python package contains a gzip-compressed data/codes.json.gz file. These files contain codelists and metadata rather than executable code.
If the TRE airlock does not permit .rda, .gz or other compressed files, exclude `packages/r/R/sysdata.rda` and `packages/python/src/impact/data/codes.json.gz` from the transfer. Transfer the remaining human-readable source files—including `codelist/master_codelist.csv`, `buildfile.py` and the package source directories—and regenerate the excluded package resources inside the TRE before installation:

``` bash
python buildfile.py --resources-only
```

This requires `Python` with pandas and an available R installation. If `Rscript` is not discoverable automatically, provide its local path:

```
python buildfile.py --resources-only --rscript "C:/path/to/Rscript"
```

The generated `R` and `Python` resources are built using the human-readable master codelist. TRE users should consult the relevant governance team before transfer, as permitted file types and installation procedures vary between environments.


## Syntax

The IMPACT packages require the specification of (i) an individual-level identifier, (ii) a coding system, (iii) the corresponding code column, and (iv) the desired output level: long-term condition (*n* = 321) or phenotype (*n* = 116).

### Stata

```stata
impact, dataset(string) id(varname) codesystems(string) ///
        searchvars(string) level(ltc|phenotype) ///
        [multimorbidity summary]
```

More information about using the `Stata` package can be found [here](packages/stata/README.md). An example of usage is also provided in [`packages/stata/stata_example.do`](packages/stata/stata_example.do).

### R

```r
impact(data, id, codesystems, searchvars, level,
       multimorbidity = FALSE, summary = FALSE)
```

More information about using the `R` package can be found [here](packages/r/README.md). An example of usage is also provided in [`packages/r/r_example.R`](packages/r/r_example.R).

### Python

```python
impact(df, id, codesystems, searchvars, level,
       multimorbidity = False, summary = False)
```
More information about using the `Python` package can be found [here](packages/python/README.md). An example of usage is also provided in [`packages/python/python_example.py`](packages/python/python_example.py).

## Feedback

Please [open an issue](https://github.com/jonathanbatty/impact/issues) to report suspected errors or omissions in the codelists, identify installation or runtime problems, suggest feature enhancements, or make any other requests.

## Acknowledgements

This work was done while JB was a member of the [Survivorship and Multimorbidity Epidemiology Group](https://multimorbidity-research-leeds.github.io/) at the University of Leeds, led by Dr Marlous Hall. 

We would like to acknowledge the following sources of funding for this work:

- JB received funding from a Wellcome Trust 4ward North Clinical Research Training Fellowship (227498/Z/23/Z; R127002).
- MH was funded by the Wellcome Trust Sir Henry Wellcome Postdoctoral Fellowship scheme (206470/Z/17/Z). 

## Suggested citation
Batty JA, del Toro T, Sturley C, Wilkinson C, Brown BC, Kearney MT and Hall M (2026). *IMPACT: The Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool* (Version 1.0) [Computer software].
https://github.com/jonathanbatty/impact
