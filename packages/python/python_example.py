"""Functional IMPACT Python example. Run with: python python_example.py"""

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

    # IMPORTANT: IMPACT output and multimorbidity counts are event-level. To
    # obtain patient-level phenotypes, take the maximum of each phenotype flag
    # across all events for the identifier, then recalculate the phenotype
    # count.
    print("Aggregating event-level output to patient-level phenotypes...")
    phenotype_columns = [
        column
        for column in phenotype_out.columns
        if column.startswith("__") and len(column) == 6
    ]
    patient_out = (
        phenotype_out[["patid"] + phenotype_columns]
        .groupby("patid", as_index=False)
        .max()
    )
    patient_out["__nphenotypes"] = patient_out[phenotype_columns].sum(axis=1)
    patient_counts = patient_out.set_index("patid")["__nphenotypes"]
    assert patient_counts.loc[1] == 3
    assert patient_counts.loc[2] == 2
    assert patient_counts.loc[3] == 0

    try:
        impact(events, "patid", "icd9cm", "icdcode", level="invalid")
    except ValueError as error:
        assert "level" in str(error)
    else:
        raise AssertionError("An invalid output level did not raise ValueError.")

    print("OK: IMPACT Python example passed")


if __name__ == "__main__":
    main()
