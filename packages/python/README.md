# impact — Python package

The Python implementation of the Inclusive Multimorbidity Phenotyping
Algorithm. It ascertains long-term conditions (LTCs) from a pandas DataFrame
of coded diagnoses, procedures or clinical events (one row per code) and
returns one 0/1 indicator column per condition (named `__<LTC>`).

## Install from GitHub

```bash
pip install "git+https://github.com/jonathanbatty/impact#subdirectory=packages/python"
```

Requires `pandas`. For development, install in editable mode:

```bash
pip install -e "git+https://github.com/jonathanbatty/impact#subdirectory=packages/python"
```

## Interface

```python
import pandas as pd
from impact import impact

out = impact(df, id="patid",
             codesystems=["icd10"], searchvars=["icdcode"],
             n_cores=1, multimorbidity=False, summary=False)
```

| Argument         | Description                                                          |
|------------------|----------------------------------------------------------------------|
| `df`             | In-memory pandas DataFrame of coded events (one row per code).       |
| `id`             | Name of the unique identifier column.                                |
| `codesystems`    | Coding system(s), one per search variable: `icd9cm`, `icd9pcs`, `icd10cm`, `icd10pcs`, `icd10`, `opcs4`, `cprdaurum` (or `medcodeid`). |
| `searchvars`     | Column name(s) to search, one per code system. An element may be a list of columns. |
| `n_cores`        | CPU cores to use (default 1; 0 = all available). This release runs serially; accepted for interface compatibility. |
| `multimorbidity` | Add `__nltc`, `__nmental`, `__nphysical`, `__nbody`, `__bs_<system>`.|
| `summary`        | Print per-codelist matched-code counts.                              |

The result is a DataFrame with the identifier and `__<LTC>` indicator columns,
plus multimorbidity variables if requested.

## Helpers

- `impact.select_codesystem("icd10")` — return the code-to-LTC lookup for one
  system.
- `impact.list_codesystems()` — names of the supported code systems.
- `impact.list_ltcs()` — metadata for all 120 LTCs (label, body system,
  category).

## Example

See `smoke_test.py` (or `src/example.py`):

```python
import pandas as pd
from impact import impact

events = pd.DataFrame({"patid": [1, 1, 2], "icdcode": ["41001", "42731", "25000"]})
out = impact(events, id="patid", codesystems="icd9cm",
             searchvars=["icdcode"], multimorbidity=True)
```
