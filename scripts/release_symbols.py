"""Package official Godot symbols only after matching the exported ELF build IDs."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile


# Update together with the pinned editor/templates in godot-ci.yml.
SYMBOLS_SHA256 = "4bc879f6ef3967dadd55d60382fe36cd79c700877280e5b410527a5ddcb72e49"


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_id(readelf, path):
    notes = subprocess.check_output([readelf, "--notes", str(path)], text=True)
    matches = re.findall(r"Build ID: ([0-9a-f]+)", notes)
    if len(matches) != 1:
        raise ValueError(f"Expected one GNU build ID: {path.name}")
    return matches[0]


def package(args):
    if sha256(args.symbols) != SYMBOLS_SHA256:
        raise ValueError("Official Godot 4.7.2 release symbols checksum mismatch")
    matched = {}
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as directory:
        staging = Path(directory)
        with zipfile.ZipFile(args.aab) as bundle, zipfile.ZipFile(args.symbols) as symbols:
            libraries = [name for name in bundle.namelist()
                         if name.startswith("base/lib/") and name.endswith(".so")]
            if not libraries:
                raise ValueError("Bundle contains no native libraries")
            for library in libraries:
                relative = library.removeprefix("base/lib/")
                # Official archives use ABI/library.so (or library.so.debug).
                candidates = [name for name in symbols.namelist()
                              if name in (relative, relative + ".debug")]
                if len(candidates) > 1:
                    raise ValueError(f"Ambiguous symbols for {relative}")
                if not candidates:
                    raise ValueError(f"Missing official symbols for {relative}")
                native = staging / "native.so"
                with bundle.open(library) as source, native.open("wb") as target:
                    shutil.copyfileobj(source, target)
                symbol = staging / relative
                symbol.parent.mkdir(parents=True, exist_ok=True)
                with symbols.open(candidates[0]) as source, symbol.open("wb") as target:
                    shutil.copyfileobj(source, target)
                expected = build_id(args.readelf, native)
                if build_id(args.readelf, symbol) != expected:
                    raise ValueError(f"Symbols do not match bundle: {relative}")
                sections = subprocess.check_output(
                    [args.readelf, "--sections", str(symbol)], text=True)
                if ".symtab" not in sections:
                    raise ValueError(f"No debug symbol table: {relative}")
                matched[relative] = expected
            if not any(name.endswith("/libgodot_android.so") for name in matched):
                raise ValueError("Missing matching Godot engine symbols")
        temporary_zip = staging / "native-debug-symbols.zip"
        with zipfile.ZipFile(temporary_zip, "w", zipfile.ZIP_DEFLATED) as archive:
            for relative in sorted(matched):
                archive.write(staging / relative, relative)
        shutil.copyfile(temporary_zip, output)
    evidence = {
        "godot_version": "4.7.2.stable",
        "aab_sha256": sha256(args.aab),
        "official_symbols_sha256": SYMBOLS_SHA256,
        "upload_zip_sha256": sha256(output),
        "matched_build_ids": matched,
    }
    output.with_suffix(".json").write_text(json.dumps(evidence, indent=2) + "\n")
    print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--aab", required=True)
    parser.add_argument("--symbols", required=True)
    parser.add_argument("--readelf", required=True)
    parser.add_argument("--output", required=True)
    package(parser.parse_args())
