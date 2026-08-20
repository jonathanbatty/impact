"""
Generate IMPACT package resources from the master codelist.
The script validates and normalises ``codelist/master_codelist.csv``,
then uses the resulting shared model to build the Stata definitions, R internal
data, and Python package resources. Run ``python buildfile.py --help`` for the
available build targets.
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Optional

import pandas as pd


# ---------------------------------------------------------------------------
# Project paths and source schema
# ---------------------------------------------------------------------------

ROOT = Path(__file__).resolve().parent
MASTER_CODELIST = ROOT / "codelist" / "master_codelist.csv"
STATA_DIR = ROOT / "packages" / "stata" / "impact"
R_DIR = ROOT / "packages" / "r" / "R"
R_BUILDER = ROOT / "packages" / "r" / "data-raw" / "build_sysdata.R"
PYTHON_PACKAGE_DIR = ROOT / "packages" / "python" / "src" / "impact"
PYTHON_DATA_DIR = PYTHON_PACKAGE_DIR / "data"

REQUIRED_COLUMNS = {
    "phenotype_id",
    "phenotype_name",
    "ltc_id",
    "ltc_name",
    "sex",
    "type",
    "body_system",
    "code_type",
    "code",
}


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------


def _capitalise(value: str) -> str:
    """Return a value with a capitalised first letter and lowercase remainder.

    Args:
        value: Text to normalise. Empty strings are returned unchanged.

    Returns:
        The normalised text.
    """
    return value[:1].upper() + value[1:].lower() if value else value


def _ordered_unique(values):
    """Remove duplicate values while preserving their first-seen order."""
    return list(dict.fromkeys(values))


def load_model(master_path: Path = MASTER_CODELIST) -> dict:
    """Read and validate the codelist, then construct shared lookup structures.

    All columns are read as strings so that clinical codes retain leading
    zeroes, punctuation, and long numeric identifiers.

    Args:
        master_path: Path to the authoritative IMPACT master codelist.

    Returns:
        A dictionary containing normalised LTC and phenotype metadata, the
        supported code-system names, lookups in both mapping directions, and
        flattened lookup rows for the R resource builder.

    Raises:
        ValueError: If required columns are absent or an identifier has
            conflicting metadata.
    """
    # ``utf-8-sig`` accepts both ordinary UTF-8 files and files with a BOM.
    codelist = pd.read_csv(
        master_path,
        dtype=str,
        keep_default_na=False,
        encoding="utf-8-sig",
    )
    missing = REQUIRED_COLUMNS.difference(codelist.columns)
    if missing:
        raise ValueError(
            "Master codelist is missing required columns: "
            + ", ".join(sorted(missing))
        )

    # Whitespace is not meaningful in identifiers or metadata. Normalising it
    # here ensures that all downstream package resources remain consistent.
    for column in REQUIRED_COLUMNS:
        codelist[column] = codelist[column].str.strip()

    # Lookup resources require a complete phenotype/LTC/code-system/code tuple.
    # Metadata-only or incomplete rows remain available to the metadata tables
    # but are excluded from code mappings.
    coded = codelist.loc[
        (codelist["phenotype_id"] != "")
        & (codelist["ltc_id"] != "")
        & (codelist["code_type"] != "")
        & (codelist["code"] != "")
    ].copy()
    coded["code"] = coded["code"].str.strip()
    coded = coded.loc[coded["code"] != ""]

    # Each granular LTC must map to exactly one label and one phenotype.
    ltc_metadata = (
        codelist[["ltc_id", "ltc_name", "phenotype_id"]]
        .loc[codelist["ltc_id"] != ""]
        .drop_duplicates()
    )
    inconsistent_ltcs = ltc_metadata.groupby("ltc_id", sort=False).size()
    inconsistent_ltcs = inconsistent_ltcs[inconsistent_ltcs > 1]
    if not inconsistent_ltcs.empty:
        raise ValueError(
            "Conflicting metadata for LTC IDs: "
            + ", ".join(inconsistent_ltcs.index)
        )
    ltc_metadata = ltc_metadata.sort_values("ltc_id").reset_index(drop=True)

    # Phenotype labels, categories, and body systems must also be unique by ID.
    phenotype_metadata = (
        codelist[["phenotype_id", "phenotype_name", "type", "body_system"]]
        .loc[codelist["phenotype_id"] != ""]
        .drop_duplicates()
    )
    inconsistent_phenotypes = phenotype_metadata.groupby(
        "phenotype_id", sort=False
    ).size()
    inconsistent_phenotypes = inconsistent_phenotypes[
        inconsistent_phenotypes > 1
    ]
    if not inconsistent_phenotypes.empty:
        raise ValueError(
            "Conflicting metadata for phenotype IDs: "
            + ", ".join(inconsistent_phenotypes.index)
        )

    # A grouped phenotype can contain sex-neutral and sex-specific granular
    # LTCs. Such mixed groups are applicable to either sex at phenotype level.
    phenotype_sex = {}
    for phenotype_id, values in codelist.loc[
        codelist["phenotype_id"] != "", ["phenotype_id", "sex"]
    ].groupby("phenotype_id", sort=False)["sex"]:
        sexes = set(values)
        if len(sexes) == 1:
            phenotype_sex[phenotype_id] = next(iter(sexes))
        elif sexes.issubset({"either", "female only", "male only"}):
            phenotype_sex[phenotype_id] = "either"
        else:
            raise ValueError(
                "Conflicting sex metadata for phenotype ID "
                f"{phenotype_id}: {', '.join(sorted(sexes))}"
            )
    phenotype_metadata = phenotype_metadata.sort_values(
        "phenotype_id"
    ).reset_index(drop=True)
    phenotype_metadata.insert(
        2,
        "sex",
        phenotype_metadata["phenotype_id"].map(phenotype_sex),
    )
    phenotype_metadata["body_system"] = phenotype_metadata["body_system"].map(
        _capitalise
    )
    phenotype_metadata["type"] = phenotype_metadata["type"].map(_capitalise)

    # Sorted identifiers and mappings make generated output reproducible and
    # keep resource diffs stable when the master codelist row order changes.
    codesystems = sorted(coded["code_type"].unique())

    # Stata consumes LTC-to-code mappings, whereas R and Python consume
    # code-to-LTC mappings. Both are derived from the same validated rows.
    ltc_to_codes = {}
    code_to_ltcs = {}
    for codesystem in codesystems:
        rows = coded.loc[coded["code_type"] == codesystem, ["ltc_id", "code"]]
        by_ltc = {}
        for ltc, values in rows.groupby("ltc_id", sort=True)["code"]:
            by_ltc[ltc] = _ordered_unique(values.tolist())
        ltc_to_codes[codesystem] = by_ltc

        by_code = {}
        for code, values in rows.groupby("code", sort=True)["ltc_id"]:
            by_code[code] = sorted(set(values))
        code_to_ltcs[codesystem] = by_code

    lookup_rows = coded[["code_type", "code", "ltc_id"]].drop_duplicates()
    lookup_rows = lookup_rows.sort_values(
        ["code_type", "code", "ltc_id"]
    ).reset_index(drop=True)

    return {
        "codesystems": codesystems,
        "ltc_metadata": ltc_metadata,
        "phenotype_metadata": phenotype_metadata,
        "ltc_to_codes": ltc_to_codes,
        "code_to_ltcs": code_to_ltcs,
        "lookup_rows": lookup_rows,
    }


# ---------------------------------------------------------------------------
# Stata definition generation
# ---------------------------------------------------------------------------


def _stata_quoted_local(name, values):
    """Format values as a quoted Stata local macro declaration.

    Embedded quotation marks are doubled according to Stata string syntax.
    """
    escaped = [str(value).replace('"', '""') for value in values]
    return f"local {name} " + " ".join(f'"{value}"' for value in escaped)


def build_stata_definitions(model: dict) -> None:
    """Generate Stata metadata and per-code-system ``__*.ado`` definitions.

    Args:
        model: Shared data model returned by :func:`load_model`.

    Notes:
        Stata definitions remain text-based local macros. This function does
        not create any ``.dta`` files.
    """
    STATA_DIR.mkdir(parents=True, exist_ok=True)
    phenotypes = model["phenotype_metadata"]
    ltcs = model["ltc_metadata"]

    lines = [
        "local phenotype_id " + " ".join(phenotypes["phenotype_id"]),
        _stata_quoted_local("phenotype_label", phenotypes["phenotype_name"]),
        _stata_quoted_local("phenotype_body_system", phenotypes["body_system"]),
        _stata_quoted_local("phenotype_category", phenotypes["type"]),
    ]
    (STATA_DIR / "__phenotypes.ado").write_text(
        "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
    )

    lines = [
        "local ltc_id " + " ".join(ltcs["ltc_id"]),
        _stata_quoted_local("ltc_label", ltcs["ltc_name"]),
        "local phenotype_id " + " ".join(ltcs["phenotype_id"]),
    ]
    (STATA_DIR / "__ltcs.ado").write_text(
        "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
    )

    for codesystem in model["codesystems"]:
        lines = [f"// {codesystem}"]
        for ltc, codes in model["ltc_to_codes"][codesystem].items():
            lines.append(f"local {codesystem}_{ltc} " + " ".join(codes))
        (STATA_DIR / f"__{codesystem}.ado").write_text(
            "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
        )


# ---------------------------------------------------------------------------
# Python resource generation
# ---------------------------------------------------------------------------


def _write_json(path: Path, value, *, compact=False) -> None:
    """Write a value as deterministic UTF-8 JSON.

    Args:
        path: Destination file path.
        value: JSON-serialisable value to write.
        compact: Write compact, key-sorted JSON when true; otherwise write
            indented, human-readable JSON with a trailing newline.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    if compact:
        text = json.dumps(
            value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
        )
    else:
        text = json.dumps(value, ensure_ascii=False, indent=2) + "\n"
    path.write_text(text, encoding="utf-8", newline="\n")


def build_python_resources(model: dict) -> None:
    """Generate the UTF-8 resources consumed by the Python package.

    Args:
        model: Shared data model returned by :func:`load_model`.

    Notes:
        Code mappings are compressed because they are substantially larger
        than the LTC and phenotype metadata. A fixed gzip timestamp makes the
        compressed output reproducible across otherwise identical builds.
    """
    PYTHON_DATA_DIR.mkdir(parents=True, exist_ok=True)

    codes_payload = {
        "schema_version": 1,
        "codesystems": model["code_to_ltcs"],
    }
    encoded = json.dumps(
        codes_payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    codes_path = PYTHON_DATA_DIR / "codes.json.gz"
    with codes_path.open("wb") as raw_file:
        with gzip.GzipFile(
            filename="",
            mode="wb",
            fileobj=raw_file,
            compresslevel=9,
            mtime=0,
        ) as compressed:
            compressed.write(encoded)

    # Metadata remains uncompressed and indented so it can be inspected easily
    # during code review and by TRE airlock teams.
    ltc_records = [
        {
            "ltc_id": row.ltc_id,
            "ltc_label": row.ltc_name,
            "phenotype_id": row.phenotype_id,
        }
        for row in model["ltc_metadata"].itertuples(index=False)
    ]
    _write_json(
        PYTHON_DATA_DIR / "ltcs.json",
        {"schema_version": 1, "ltcs": ltc_records},
    )

    phenotype_records = [
        {
            "phenotype_id": row.phenotype_id,
            "phenotype_label": row.phenotype_name,
            "sex": row.sex,
            "category": row.type,
            "body_system": row.body_system,
        }
        for row in model["phenotype_metadata"].itertuples(index=False)
    ]
    _write_json(
        PYTHON_DATA_DIR / "phenotypes.json",
        {"schema_version": 1, "phenotypes": phenotype_records},
    )


# ---------------------------------------------------------------------------
# R resource generation
# ---------------------------------------------------------------------------

def _find_rscript(explicit: Optional[str]) -> str:
    """Locate an Rscript executable using explicit and conventional paths.

    Args:
        explicit: Optional executable path supplied with ``--rscript``.

    Returns:
        The resolved path to an existing Rscript executable.

    Raises:
        RuntimeError: If Rscript cannot be found.
    """
    # Respect the command-line option first, followed by the environment and
    # PATH. Windows R installations are commonly absent from PATH, so their
    # conventional Program Files locations are checked as a final fallback.
    candidates = [explicit, os.environ.get("RSCRIPT"), shutil.which("Rscript")]
    if os.name == "nt":
        program_files = Path(os.environ.get("ProgramFiles", "C:/Program Files"))
        candidates.extend(
            str(path)
            for path in sorted(
                program_files.glob("R/R-*/bin/Rscript.exe"), reverse=True
            )
        )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(Path(candidate))
    raise RuntimeError(
        "Rscript is required to build packages/r/R/sysdata.rda. "
        "Install R, set RSCRIPT, or pass --rscript PATH."
    )


def build_r_sysdata(model: dict, rscript: Optional[str] = None) -> None:
    """Generate compressed R internal data from the shared model.

    Args:
        model: Shared data model returned by :func:`load_model`.
        rscript: Optional path to an Rscript executable.

    Raises:
        RuntimeError: If no Rscript executable is available.
        subprocess.CalledProcessError: If the R resource builder fails.
    """
    executable = _find_rscript(rscript)
    R_DIR.mkdir(parents=True, exist_ok=True)
    r_environment = os.environ.copy()
    if os.name == "nt":
        # C.UTF-8 is a common Unix setting but is not a valid Windows R locale.
        for name in tuple(r_environment):
            if name == "LC_ALL" or name.startswith("LC_"):
                r_environment.pop(name, None)

    # CSV provides a simple UTF-8 interchange format between Python and the
    # small R builder responsible for writing R's native ``sysdata.rda``.
    # Temporary files are removed automatically when the context exits.
    with tempfile.TemporaryDirectory(prefix="impact-build-") as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        lookups_path = temp_dir / "lookups.csv"
        ltcs_path = temp_dir / "ltcs.csv"
        phenotypes_path = temp_dir / "phenotypes.csv"
        model["lookup_rows"].to_csv(lookups_path, index=False, encoding="utf-8")
        model["ltc_metadata"].to_csv(ltcs_path, index=False, encoding="utf-8")
        model["phenotype_metadata"].to_csv(
            phenotypes_path, index=False, encoding="utf-8"
        )
        subprocess.run(
            [
                executable,
                str(R_BUILDER),
                str(lookups_path),
                str(ltcs_path),
                str(phenotypes_path),
                str(R_DIR / "sysdata.rda"),
            ],
            check=True,
            env=r_environment,
        )


# ---------------------------------------------------------------------------
# Command-line interface and build orchestration
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    """Parse and return command-line build options."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--target",
        choices=("all", "stata", "r", "python"),
        default="all",
        help="Build one package or all packages (default: all).",
    )
    parser.add_argument(
        "--resources-only",
        action="store_true",
        help="Build R/Python runtime resources without rebuilding Stata.",
    )
    parser.add_argument(
        "--rscript",
        help="Path to Rscript when it is not available on PATH.",
    )
    return parser.parse_args()


def main() -> None:
    """Validate the codelist once and run the requested package builders."""
    args = parse_args()
    model = load_model()

    # Stata has no separate binary/data resource: its runtime data consists of
    # the ``__*.ado`` definitions created by the standard Stata target.
    if args.resources_only and args.target == "stata":
        raise SystemExit("Stata has no separate runtime resource target.")

    if not args.resources_only and args.target in ("all", "stata"):
        build_stata_definitions(model)

    if args.target in ("all", "r"):
        build_r_sysdata(model, args.rscript)

    if args.target in ("all", "python"):
        build_python_resources(model)

    print(
        "IMPACT build complete: "
        f"{len(model['ltc_metadata'])} LTCs, "
        f"{len(model['phenotype_metadata'])} phenotypes, "
        f"{len(model['codesystems'])} code systems."
    )


if __name__ == "__main__":
    main()
