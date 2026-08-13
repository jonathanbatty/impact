"""Smoke test for the impact Python package.

Runs the full pipeline on a small synthetic dataset and asserts the expected
long-term condition flags. Run with:  python smoke_test.py
"""

import os
import sys

# Make the src/ package importable regardless of the current working directory
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "src"))

import pandas as pd
from impact import impact, list_codesystems, list_ltcs


def main():
    # Introspection helpers
    assert "icd9cm" in list_codesystems()
    assert "cprdaurum" in list_codesystems()
    meta = list_ltcs()
    assert meta.shape == (120, 4), meta.shape

    # A small dataset of coded events (one row per code)
    events = pd.DataFrame({
        "patid":   [1, 1, 2, 2, 3],
        "icdcode": ["41001", "42731", "25000", "49300", "99999"],
    })

    out = impact(events, id="patid",
                 codesystems="icd9cm", searchvars=["icdcode"],
                 multimorbidity=True, summary=False)

    # 41001 -> CORO + MINF ; 42731 -> AFIB ; 25000 -> DIAB ; 49300 -> ASTH
    assert out.loc[0, "__MINF"] == 1
    assert out.loc[0, "__CORO"] == 1
    assert out.loc[1, "__AFIB"] == 1
    assert out.loc[2, "__DIAB"] == 1
    assert out.loc[3, "__ASTH"] == 1
    assert out.loc[4, "__MINF"] == 0          # 99999 is not a known code
    assert out.loc[0, "__nltc"] == 2
    assert out.loc[0, "__nmental"] == 0       # MINF/CORO are physical
    assert "__nbody" in out.columns
    assert any(c.startswith("__bs_") for c in out.columns)

    # Validation
    try:
        impact(events, id="patid", codesystems=["icd9cm"], searchvars=["icdcode", "x"])
        raise SystemExit("expected length-mismatch error")
    except ValueError:
        pass

    print("OK: impact smoke test passed")


if __name__ == "__main__":
    main()
