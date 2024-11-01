# Import the core package functions
from impa import impa

# Load the ICD-9-CM code definitions into a dictionary called icd9map
icd9map = impa.select_codesystem("icd9cm")

# Use icd9map to lookup the code '41001' ("Acute myocardial infarction of anterolateral wall, initial episode of care")
print(icd9map['41001'])

