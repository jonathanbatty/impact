"""Small IMPACT example using hard-coded coded-event data."""

import pandas as pd
from impact import impact

events = pd.DataFrame(
    {
        "patid": [1, 1, 2, 2, 3],
        "icdcode": ["410.01", "427.31", "250.00", "493.00", "999.99"],
    }
)

out = impact(
    events,
    id="patid",
    codesystems="icd9cm",
    searchvars="icdcode",
    level="phenotype",
    multimorbidity=True,
    summary=True,
)
print(out)
