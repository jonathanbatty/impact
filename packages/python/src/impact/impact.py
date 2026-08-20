"""Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool (IMPACT)."""

import gzip
import json
from functools import lru_cache
import pkgutil
import re

__all__ = ["impact", "select_codesystem", "list_ltcs", "list_codesystems"]


def _load_json_resource(filename):
    raw = pkgutil.get_data(__package__, "data/" + filename)
    if raw is None:
        raise RuntimeError("IMPACT package resource %r is missing." % filename)
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RuntimeError(
            "IMPACT package resource %r is not valid UTF-8 JSON." % filename
        ) from exc
    if payload.get("schema_version") != 1:
        raise RuntimeError(
            "Unsupported schema in IMPACT package resource %r." % filename
        )
    return payload


_LTC_RECORDS = _load_json_resource("ltcs.json")["ltcs"]
_PHENOTYPE_RECORDS = _load_json_resource("phenotypes.json")["phenotypes"]

LTC_IDS = tuple(row["ltc_id"] for row in _LTC_RECORDS)
LTC_LABELS = {row["ltc_id"]: row["ltc_label"] for row in _LTC_RECORDS}
LTC_PHENOTYPES = {
    row["ltc_id"]: row["phenotype_id"] for row in _LTC_RECORDS
}
PHENOTYPE_IDS = tuple(row["phenotype_id"] for row in _PHENOTYPE_RECORDS)
PHENOTYPE_LABELS = {
    row["phenotype_id"]: row["phenotype_label"]
    for row in _PHENOTYPE_RECORDS
}
PHENOTYPE_SYSTEMS = {
    row["phenotype_id"]: row["body_system"] for row in _PHENOTYPE_RECORDS
}
PHENOTYPE_CATEGORIES = {
    row["phenotype_id"]: row["category"] for row in _PHENOTYPE_RECORDS
}

CANONICAL_CODESYSTEMS = (
    "cprd_aurum_medcodeid",
    "cprd_gold_medcode",
    "emis_local",
    "icd10",
    "icd10cm",
    "icd10pcs",
    "icd9cm",
    "icd9pcs",
    "opcs4",
    "read_cleansed",
    "read_original",
    "snomed_concept",
    "snomed_description",
)

ALIASES = {
    "cprdaurum": "cprd_aurum_medcodeid",
    "medcodeid": "cprd_aurum_medcodeid",
    "cprdgold": "cprd_gold_medcode",
}


def _normalise_codesystem(value):
    value = str(value).lower()
    value = ALIASES.get(value, value)
    if value not in CANONICAL_CODESYSTEMS:
        raise ValueError(
            "Unknown code system %r. See list_codesystems()." % value
        )
    return value


@lru_cache(maxsize=1)
def _load_all_codes():
    raw = pkgutil.get_data(__package__, "data/codes.json.gz")
    if raw is None:
        raise RuntimeError("IMPACT package resource 'codes.json.gz' is missing.")
    try:
        payload = json.loads(gzip.decompress(raw).decode("utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RuntimeError(
            "IMPACT package resource 'codes.json.gz' is not valid UTF-8 JSON."
        ) from exc
    if payload.get("schema_version") != 1:
        raise RuntimeError(
            "Unsupported schema in IMPACT package resource 'codes.json.gz'."
        )
    return payload["codesystems"]


def _load_codesystem(canonical):
    """Load a generated code-to-LTC mapping from package resources."""
    try:
        return _load_all_codes()[canonical]
    except KeyError as exc:
        raise RuntimeError(
            "Code system %r is absent from IMPACT package resources." % canonical
        ) from exc


def select_codesystem(ontology):
    """Return the code-to-granular-LTC dictionary for one code system."""
    return _load_codesystem(_normalise_codesystem(ontology))


def list_codesystems():
    """Return canonical supported code-system names followed by aliases."""
    return list(CANONICAL_CODESYSTEMS) + list(ALIASES)


def list_ltcs():
    """Return granular LTC metadata and each LTC's grouped phenotype."""
    import pandas as pd

    phenotypes = [LTC_PHENOTYPES[x] for x in LTC_IDS]
    return pd.DataFrame(
        {
            "ltc": LTC_IDS,
            "label": [LTC_LABELS[x] for x in LTC_IDS],
            "phenotype": phenotypes,
            "phenotype_label": [PHENOTYPE_LABELS[x] for x in phenotypes],
            "body_system": [PHENOTYPE_SYSTEMS[x] for x in phenotypes],
            "category": [PHENOTYPE_CATEGORIES[x] for x in phenotypes],
        }
    )


def _as_codesystems(value):
    if isinstance(value, str):
        values = [x for x in re.split(r"[,\s]+", value) if x]
    else:
        values = list(value)
    if not values:
        raise ValueError("codesystems must not be empty.")
    return [_normalise_codesystem(x) for x in values]


def _as_search_groups(value, number_of_systems):
    if isinstance(value, str):
        return [[value]]
    values = list(value)
    if number_of_systems == 1 and all(isinstance(x, str) for x in values):
        return [values]
    groups = [[x] if isinstance(x, str) else list(x) for x in values]
    return groups


def impact(
    df,
    id,
    codesystems,
    searchvars,
    level,
    multimorbidity=False,
    summary=False,
):
    """Ascertain IMPACT indicators from a pandas DataFrame of coded events.

    Parameters
    ----------
    df : pandas.DataFrame
        One row per coded event.
    id : str
        Identifier column retained in the result.
    codesystems : str or sequence of str
        Code systems corresponding, in order, to ``searchvars``.
    searchvars : str or sequence
        One code-column group per code system. A nested sequence searches
        several columns using one code system.
    level : {"ltc", "phenotype"}
        Return 321 granular LTC indicators or 116 grouped phenotype indicators.
    multimorbidity : bool, optional
        Add phenotype-based counts, including ``__nphenotypes``.
    summary : bool, optional
        Print matched-code counts for each selected code system.
    """
    import pandas as pd

    if not isinstance(df, pd.DataFrame):
        raise TypeError("df must be a pandas DataFrame.")
    if not isinstance(id, str) or not id:
        raise TypeError("id must be one column name.")
    if id not in df.columns:
        raise KeyError("Identifier column %r was not found." % id)
    if not isinstance(level, str) or level.lower() not in ("ltc", "phenotype"):
        raise ValueError("level must be specified as 'ltc' or 'phenotype'.")
    level = level.lower()
    canonical = _as_codesystems(codesystems)
    search_groups = _as_search_groups(searchvars, len(canonical))
    if len(canonical) != len(search_groups):
        raise ValueError(
            "The number of code systems and search-variable groups must be equal."
        )
    if any(not group for group in search_groups):
        raise ValueError("searchvars must not contain an empty group.")
    for group in search_groups:
        missing = [column for column in group if column not in df.columns]
        if missing:
            raise KeyError("Search variable(s) not found: %s" % ", ".join(missing))

    target_ids = LTC_IDS if level == "ltc" else PHENOTYPE_IDS
    flags = pd.DataFrame(
        0,
        index=df.index,
        columns=["__" + x for x in target_ids],
        dtype="int8",
    )
    result = pd.concat([df[[id]].copy(), flags], axis=1)

    lookups = []
    for canonical_name, columns in zip(canonical, search_groups):
        lookup = _load_codesystem(canonical_name)
        lookups.append(lookup)
        for column in columns:
            values = df[column].astype("string").str.strip()
            for code in values.dropna().unique():
                if code == "":
                    continue
                ltcs = lookup.get(str(code))
                if not ltcs:
                    continue
                if isinstance(ltcs, str):
                    ltcs = [ltcs]
                targets = (
                    list(dict.fromkeys(ltcs))
                    if level == "ltc"
                    else list(dict.fromkeys(LTC_PHENOTYPES[x] for x in ltcs))
                )
                result.loc[values == code, ["__" + x for x in targets]] = 1

    if multimorbidity:
        _add_multimorbidity(result, level)

    if summary:
        print("\nIMPACT summary: %d coded event(s)" % len(df))
        for requested, columns, lookup in zip(
            _display_codesystems(codesystems), search_groups, lookups
        ):
            total = 0
            for column in columns:
                values = df[column].astype("string").str.strip()
                total += int(values.isin(lookup).sum())
            print("  %s: %d matched code(s)" % (requested, total))

    return result


def _display_codesystems(value):
    if isinstance(value, str):
        return [x for x in re.split(r"[,\s]+", value) if x]
    return [str(x) for x in value]


def _system_name(value):
    value = value.lower().replace("&", "and")
    return re.sub(r"^_|_$", "", re.sub(r"[^a-z0-9]+", "_", value))


def _add_multimorbidity(result, level):
    import pandas as pd

    phenotype_columns = ["__" + x for x in PHENOTYPE_IDS]
    if level == "phenotype":
        phenotype_flags = result[phenotype_columns].copy()
    else:
        phenotype_flags = pd.DataFrame(
            0, index=result.index, columns=phenotype_columns, dtype="int8"
        )
        for ltc in LTC_IDS:
            column = "__" + LTC_PHENOTYPES[ltc]
            phenotype_flags[column] = phenotype_flags[column].where(
                result["__" + ltc] == 0, 1
            )

    result["__nphenotypes"] = phenotype_flags.sum(axis=1).astype("int16")
    mental = [
        "__" + x for x in PHENOTYPE_IDS if PHENOTYPE_CATEGORIES[x] == "Mental"
    ]
    result["__nmental"] = phenotype_flags[mental].sum(axis=1).astype("int16")
    result["__nphysical"] = result["__nphenotypes"] - result["__nmental"]

    systems = list(dict.fromkeys(PHENOTYPE_SYSTEMS[x] for x in PHENOTYPE_IDS))
    body_present = pd.DataFrame(False, index=result.index, columns=systems)
    for system in systems:
        columns = [
            "__" + x for x in PHENOTYPE_IDS if PHENOTYPE_SYSTEMS[x] == system
        ]
        counts = phenotype_flags[columns].sum(axis=1).astype("int16")
        result["__bs_" + _system_name(system)] = counts
        body_present[system] = counts > 0
    result["__nbody"] = body_present.sum(axis=1).astype("int16")
