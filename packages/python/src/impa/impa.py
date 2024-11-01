def select_codesystem(ontology):

    if ontology == "icd9cm":
        from . import __icd9cm as icd9cm
        print("Code definitions for ICD-9-CM loaded...")
        
        return icd9cm.icd9cm

    if ontology == "icd9pcs":
        from . import __icd9pcs as icd9pcs
        print("Code definitions for ICD-9-PCS loaded...")

        return icd9pcs.icd9pcs

    if ontology == "icd10cm":
        from . import __icd10cm as icd10cm
        print("Code definitions for ICD-10-CM loaded...")

        return icd10cm.icd10cm

    if ontology == "icd10pcs":
        from . import __icd10pcs as icd10pcs
        print("Code definitions for ICD-10-PCS loaded...")

        return icd10pcs.icd10pcs

    if ontology == "icd10":
        from . import __icd10 as icd10
        print("Code definitions for ICD-10 (UK version) loaded...")

        return icd10.icd10

    if ontology == "opcs4":
        from . import __opcs4 as opcs4
        print("Code definitions for OPCS4 loaded...")

        return opcs4.opcs4

    if ontology == "cprdaurum":
        from . import __medcodeid as medcodeid
        print("Code definitions for CPRD Aurum Medcodeids loaded...")

        return medcodeid.medcodeid

