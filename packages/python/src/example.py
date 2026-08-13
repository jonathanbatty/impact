# Import the core package functions
from impact import impact

# Load the ICD-9-CM code definitions into a dictionary called icd9map
icd9map = impact.select_codesystem("icd9cm")

# Use icd9map to lookup the code '41001' ("Acute myocardial infarction of
# anterolateral wall, initial episode of care")
print(icd9map['41001'])

# Build a small example dataset of coded events (one row per code).
# patid is the unique identifier; icdcode holds ICD-9-CM codes.
import pandas as pd
events = pd.DataFrame({
    'patid':  [1, 1, 2, 2, 3],
    'icdcode': ['41001', '42731', '25000', '49300', '99999'],
})

# Ascertain long-term conditions, adding multimorbidity and summary output.
out = impact(events, id='patid',
             codesystems=['icd9cm'], searchvars=['icdcode'],
             multimorbidity=True, summary=True)

print(out)
