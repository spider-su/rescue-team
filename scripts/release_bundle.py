"""Prepare the opt-in Gradle export and verify the actual Play upload bundle."""

import hashlib
import json
import os
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

PACKAGE = "com.spidersu.rescueteam"
CERTIFICATE = "5857d1852465d292b6a7a947cf45b05a11e7366ff965743b32837e41889b25a6"
ANDROID = "{http://schemas.android.com/apk/res/android}"


def version():
    code = os.environ["RELEASE_VERSION_CODE"]
    name = os.environ["RELEASE_VERSION_NAME"]
    if not re.fullmatch(r"[1-9][0-9]*", code) or int(code) > 2100000000:
        raise ValueError("Release version code must be 1..2100000000")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.+_-]{0,31}", name):
        raise ValueError("Invalid release version name")
    return code, name


def prepare():
    code, name = version()
    path = Path("export_presets.cfg")
    text = path.read_text()
    for pattern, replacement in [
        (r"^gradle_build/use_gradle_build=false$", "gradle_build/use_gradle_build=true\ngradle_build/export_format=1"),
        (r"^version/code=\d+$", f"version/code={code}"),
        (r'^version/name="[^"]*"$', f'version/name="{name}"'),
    ]:
        text, count = re.subn(pattern, replacement, text, flags=re.M)
        if count != 1:
            raise ValueError(f"Expected one export setting matching {pattern}")
    path.write_text(text)


def verify():
    code, name = version()
    bundle = Path("build/rescue-team-release.aab")
    root = ET.parse("build/release-manifest.xml").getroot()
    if root.get("package") != PACKAGE:
        raise ValueError("Unexpected application ID")
    if root.get(ANDROID + "versionCode") != code or root.get(ANDROID + "versionName") != name:
        raise ValueError("Bundle version does not match requested candidate")
    application = root.find("application")
    if application is None or application.get(ANDROID + "debuggable", "false") != "false":
        raise ValueError("Release bundle is debuggable or has no application")
    permissions = [node.get(ANDROID + "name") for node in root.findall("uses-permission")]
    if "android.permission.INTERNET" in permissions:
        raise ValueError("Offline product unexpectedly requests INTERNET")
    fingerprint = Path("build/release-certificate.txt").read_text().strip().split("=")[-1].replace(":", "").lower()
    if fingerprint != CERTIFICATE:
        raise ValueError("Bundle was not signed with the approved upload certificate")
    with zipfile.ZipFile(bundle) as archive:
        libraries = [p for p in archive.namelist() if p.startswith("base/lib/") and p.endswith(".so")]
    if not libraries or any(p.split("/")[2] != "arm64-v8a" for p in libraries):
        raise ValueError("Bundle must contain only arm64 native libraries")
    sdk = root.find("uses-sdk")
    metadata = {
        "package": PACKAGE, "version_name": name, "version_code": int(code),
        "sha256": hashlib.sha256(bundle.read_bytes()).hexdigest(),
        "certificate_sha256": fingerprint, "abi": "arm64-v8a", "debuggable": False,
        "target_sdk": sdk.get(ANDROID + "targetSdkVersion") if sdk is not None else None,
        "permissions": permissions, "source_commit": os.environ.get("GITHUB_SHA"),
        "ci_run": f"https://github.com/{os.environ.get('GITHUB_REPOSITORY')}/actions/runs/{os.environ.get('GITHUB_RUN_ID')}",
    }
    Path("build/release-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    {"prepare": prepare, "verify": verify}[sys.argv[1]]()
