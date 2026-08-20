"""IMPACT - the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool.

Ascertain long-term conditions from routinely collected, coded healthcare
data using CPRD Aurum and GOLD identifiers, EMIS local codes, ICD-9-CM,
ICD-9-PCS, ICD-10, ICD-10-CM, ICD-10-PCS, OPCS-4, Read codes and SNOMED CT
concept and description identifiers.
"""

from .impact import impact, select_codesystem, list_ltcs, list_codesystems

__all__ = ["impact", "select_codesystem", "list_ltcs", "list_codesystems"]
__version__ = "1.0"
