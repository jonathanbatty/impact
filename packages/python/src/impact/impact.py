"""IMPACT - the Inclusive Multimorbidity Phenotyping Algorithm.

Ascertain long-term conditions (LTCs) from routinely collected, coded
healthcare data using the IMPACT codelists. Each input row is a single coded
event with a unique identifier and one or more code columns. The function
returns a table with the identifier plus one 0/1 indicator column per LTC
(named ``__<LTC>``), optionally with multimorbidity summary variables.
"""

from .__ltcs import LTCS, LTC_LABELS, LTC_MAPPING, LTC_CATEGORY

__all__ = ["impact", "select_codesystem", "list_ltcs", "list_codesystems"]


def select_codesystem(ontology):
    """Return the code -> long-term-condition lookup for one coding system.

    Parameters
    ----------
    ontology : str
        One of: icd9cm, icd9pcs, icd10cm, icd10pcs, icd10, opcs4, cprdaurum.
        ``cprdaurum`` maps to the CPRD Aurum medcodeid codelists.

    Returns
    -------
    dict
        Mapping from code string to a list of LTC identifiers.
    """
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
        print("Code definitions for OPCS-4 loaded...")
        return opcs4.opcs4
    if ontology == "cprdaurum" or ontology == "medcodeid":
        from . import __medcodeid as medcodeid
        print("Code definitions for CPRD Aurum Medcodeids loaded...")
        return medcodeid.medcodeid
    raise ValueError(
        "Unknown code system %r. Select one of: icd9cm, icd9pcs, icd10cm, "
        "icd10pcs, icd10, opcs4, cprdaurum (or medcodeid)." % ontology
    )


def list_codesystems():
    """Return the names of the supported coding systems."""
    return ["icd9cm", "icd9pcs", "icd10cm", "icd10pcs", "icd10", "opcs4",
            "cprdaurum", "medcodeid"]


def list_ltcs():
    """Return a DataFrame of long-term condition metadata (code, label, body
    system, mental/physical category)."""
    import pandas as pd
    return pd.DataFrame({
        "ltc": LTCS,
        "label": [LTC_LABELS[x] for x in LTCS],
        "body_system": [LTC_MAPPING[x] for x in LTCS],
        "category": [LTC_CATEGORY[x] for x in LTCS],
    })


def _as_list(value):
    """Normalise a space/comma separated string or a list into a Python list."""
    if isinstance(value, str):
        return [x.strip() for x in value.replace(",", " ").split() if x.strip()]
    return list(value)


def _body_systems():
    """Distinct body systems, in first-appearance order."""
    seen = []
    for x in LTCS:
        b = LTC_MAPPING[x]
        if b not in seen:
            seen.append(b)
    return seen


def impact(df, id, codesystems, searchvars, multimorbidity=False,
           summary=False):
    """Ascertain IMPACT long-term conditions from a table of coded events.

    Parameters
    ----------
    df : pandas.DataFrame
        Each row is a single coded event; contains the identifier and code
        columns. (Stata's ``dataset`` argument is replaced by this in-memory
        table.)
    id : str
        Name of the unique identifier column.
    codesystems : list or str
        Coding system(s) to use, in the same order as ``searchvars``. Each may
        be one of: icd9cm, icd9pcs, icd10cm, icd10pcs, icd10, opcs4,
        cprdaurum.
    searchvars : list or str
        Column name(s) to search, one per code system. An element may itself be
        a list of column names searched for that code system.
    multimorbidity : bool, optional
        Add multimorbidity variables (LTC count, mental/physical counts, body
        system counts).
    summary : bool, optional
        Print a summary of the totals for each codelist searched.

    Returns
    -------
    pandas.DataFrame
        The identifier column plus one ``__<LTC>`` 0/1 column per long-term
        condition, and (if ``multimorbidity``) the multimorbidity variables.
    """
    import pandas as pd

    codesystems = _as_list(codesystems)
    searchvars = _as_list(searchvars)

    # Normalise searchvars: each element may be a single column or a list.
    sv_cols = []
    for sv in searchvars:
        if isinstance(sv, str):
            sv_cols.append([sv])
        else:
            sv_cols.append(list(sv))

    if len(codesystems) != len(sv_cols):
        raise ValueError(
            "Number of code systems and number of search variables must be equal "
            "(%d vs %d)." % (len(codesystems), len(sv_cols)))

    if id not in df.columns:
        raise KeyError("Identifier column %r not found in the input table." % id)

    for cs in codesystems:
        if cs not in list_codesystems():
            raise ValueError("Unknown code system %r." % cs)

    # Build per-code-system mappings (for the summary) and a combined
    # code -> set(LTC) lookup across the selected systems.
    lookup = {}
    per_cs = {}
    for cs in codesystems:
        mapping = select_codesystem(cs)
        per_cs[cs] = mapping
        for code, ltcs in mapping.items():
            if isinstance(ltcs, (list, tuple)):
                lookup.setdefault(code, set()).update(ltcs)
            else:
                lookup.setdefault(code, set()).add(ltcs)

    # Result table: id plus one 0/1 column per LTC (built in a single concat
    # to keep the frame unfragmented).
    ltc_cols = pd.DataFrame(
        {ltc: 0 for ltc in ("__" + x for x in LTCS)}, index=df.index, dtype="int64")
    result = pd.concat([df[[id]], ltc_cols], axis=1)

    # Search each code system - search variable pair.
    for cs, cols in zip(codesystems, sv_cols):
        for col in cols:
            if col not in df.columns:
                raise KeyError("Search variable %r not found in the input table." % col)
            _search_column(result, df, col, lookup)

    if multimorbidity:
        _add_multimorbidity(result)

    if summary:
        _print_summary(df, codesystems, sv_cols, per_cs)

    return result


def _search_column(result, df, col, lookup):
    """Set the ``__<LTC>`` indicators for one code column."""
    values = df[col]
    codes = values.astype(str)
    for code in codes.unique():
        if not code or code == "nan":
            continue
        ltcs = lookup.get(code)
        if not ltcs:
            continue
        mask = (codes == code).values
        for ltc in ltcs:
            result.loc[mask, "__" + ltc] = 1


def _add_multimorbidity(result):
    """Append multimorbidity-related variables to the result table."""
    # Total number of LTCs
    result["__nltc"] = sum(result["__" + x] for x in LTCS)
    # Mental / physical counts
    result["__nmental"] = sum(result["__" + x] for x in LTCS if LTC_CATEGORY[x] == "Mental")
    result["__nphysical"] = result["__nltc"] - result["__nmental"]
    # Distinct body systems affected
    body_cols = ["__" + x for x in LTCS]
    systems = _body_systems()

    def _nbody(row):
        present = set()
        for b, col in zip((LTC_MAPPING[x] for x in LTCS), body_cols):
            if row[col] == 1:
                present.add(b)
        return len(present)

    result["__nbody"] = result.apply(lambda r: _nbody(r), axis=1)
    # Per-body-system counts
    for b in systems:
        cols = ["__" + x for x in LTCS if LTC_MAPPING[x] == b]
        name = "__bs_" + b.replace(" ", "_").replace("&", "and")
        result[name] = sum(result[c] for c in cols)


def _print_summary(df, codesystems, sv_cols, per_cs):
    """Print a short summary of the totals for each codelist searched."""
    print("\nIMPACT summary: %d coded events" % len(df))
    for cs, cols in zip(codesystems, sv_cols):
        total = 0
        for col in cols:
            codes = df[col].astype(str)
            total += int(codes.isin(per_cs[cs]).sum())
        print("  %s: %d code(s) matched in the searched variable(s)" % (cs, total))
