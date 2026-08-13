"""IMPACT - the Inclusive Multimorbidity Phenotyping Algorithm.

Ascertain long-term conditions from routinely collected, coded healthcare
data (ICD-9-CM, ICD-9-PCS, ICD-10-CM, ICD-10-PCS, ICD-10, OPCS-4, and CPRD
Aurum medcodeid values).
"""

from .impact import impact, select_codesystem, list_ltcs, list_codesystems

__all__ = ["impact", "select_codesystem", "list_ltcs", "list_codesystems"]
__version__ = "0.1.0"
