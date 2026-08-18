"""Functional test for the IMPACT Python package. Run with: python test.py"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "src"))

import pandas as pd
from impact import impact, list_codesystems, list_ltcs


def main():
    assert len(list_codesystems()) >= 13
    assert list_ltcs().shape == (321, 6)

    events = pd.DataFrame(
        {
            "patid": [1, 1, 2, 2, 3],
            "icdcode": ["410.01", "427.31", "250.00", "493.00", "999.99"],
        }
    )

    ltc_out = impact(
        events,
        id="patid",
        codesystems="icd9cm",
        searchvars="icdcode",
        level="ltc",
        multimorbidity=True,
        summary=True,
    )
    assert ltc_out.loc[0, "__STMI"] == 1
    assert ltc_out.loc[0, "__CORO"] == 1
    assert ltc_out.loc[1, "__AFIB"] == 1
    assert ltc_out.loc[2, "__T2DM"] == 1
    assert ltc_out.loc[3, "__ASTH"] == 1
    assert ltc_out.loc[4, "__STMI"] == 0
    assert ltc_out.loc[0, "__nphenotypes"] == 2
    assert ltc_out.loc[0, "__nmental"] == 0
    assert ltc_out.loc[0, "__nphysical"] == 2
    assert ltc_out.loc[0, "__nbody"] == 1

    phenotype_out = impact(
        events,
        id="patid",
        codesystems=["icd9cm"],
        searchvars=[["icdcode"]],
        level="phenotype",
        multimorbidity=True,
    )
    assert phenotype_out.loc[0, "__ACSN"] == 1
    assert phenotype_out.loc[0, "__CORO"] == 1
    assert phenotype_out.loc[1, "__AFIB"] == 1
    assert phenotype_out.loc[2, "__DIAB"] == 1
    assert phenotype_out.loc[3, "__ASTH"] == 1
    assert phenotype_out.loc[4, "__ACSN"] == 0
    assert phenotype_out.loc[0, "__nphenotypes"] == 2

    try:
        impact(events, "patid", "icd9cm", "icdcode", level="invalid")
    except ValueError as error:
        assert "level" in str(error)
    else:
        raise AssertionError("An invalid output level did not raise ValueError.")

    print("OK: IMPACT Python functional test passed")


if __name__ == "__main__":
    main()
