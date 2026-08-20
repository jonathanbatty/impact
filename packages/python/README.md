# IMPACT — Python package

This is the Python implementation of IMPACT, the Inclusive Multimorbidity
Phenotyping Algorithm and Coding Tool. It returns either 321 granular LTC
indicators or 116 grouped phenotype indicators for row-level coded-event data.

## Install directly from GitHub

```bash
python -m pip install "git+https://github.com/jonathanbatty/impact.git#subdirectory=packages/python"
```

Pip is used only to install the GitHub source; IMPACT is not published on PyPI.
The package requires pandas.

The generated lookup data are installed as UTF-8 package resources:
`data/codes.json.gz`, `data/ltcs.json`, and `data/phenotypes.json`. They are
built from the repository's authoritative `codelist/master_codelist.csv` by
`buildfile.py` and should not be edited directly.

## Run IMPACT

```python
from impact import impact

out = impact(events, id="patid", codesystems="icd10",
             searchvars="icdcode", level="phenotype",
             multimorbidity=True, summary=True)
```

`level` is required. Use `"ltc"` for 321 granular `__<LTC>` indicators or
`"phenotype"` for 116 grouped `__<phenotype>` indicators.

For several code systems, pass one search-column group per system:

```python
out = impact(events, id="patid",
             codesystems=["icd10", "opcs4"],
             searchvars=[["diagnosis"], ["procedure_1", "procedure_2"]],
             level="ltc")
```

Supported canonical systems are `cprd_aurum_medcodeid`,
`cprd_gold_medcode`, `emis_local`, `icd10`, `icd10cm`, `icd10pcs`, `icd9cm`,
`icd9pcs`, `opcs4`, `read_cleansed`, `read_original`, `snomed_concept`, and
`snomed_description`. Aliases are `cprdaurum`, `medcodeid`, and `cprdgold`.

Code columns should contain strings; surrounding whitespace is ignored.
`multimorbidity=True` adds phenotype-based
`__nphenotypes`, `__nmental`, `__nphysical`, `__bs_<system>`, and `__nbody`,
regardless of the chosen output level.

Helpers:

- `select_codesystem("icd10")` returns a code-to-granular-LTC dictionary.
- `list_codesystems()` lists canonical names and aliases.
- `list_ltcs()` returns all 321 LTCs with their phenotype metadata.

Run [`python_example.py`](python_example.py) from this directory to exercise
both output levels with hard-coded sample data. [`src/example.py`](src/example.py)
is a minimal worked example.
