# First signed Android App Bundle — 2026-11-02

Candidate `0.1.0` / Play version code `1`, package `com.spidersu.rescueteam`, source `ea291a045ae142ce6809f2e179fa5540d184dea7`.

[Successful release build](https://github.com/spider-su/rescue-team/actions/runs/41460812065) — download the `rescue-team-release-aab` artifact. The local handoff is `build/release-0.1.0-1/rescue-team-release.aab` (ignored by Git). The AAB is an upload artifact, not a directly installable APK. The owner subsequently reported Play Console warnings for version code 1; Play delivery and policy approval have not been independently verified.

| Check | Result |
| --- | --- |
| Pinned Godot 4.7.2 import, eight existing suites, debug APK and release Gradle export | PASS |
| Bundletool 1.18.3 structural validation | PASS |
| JAR signature verification | PASS — `jar verified`; warnings retained in `release-signature.txt` |
| Dedicated upload certificate | PASS — `5857d1852465d292b6a7a947cf45b05a11e7366ff965743b32837e41889b25a6` |
| Package and requested version | PASS — `com.spidersu.rescueteam`, `0.1.0` / `1` |
| Native ABI / manifest | PASS — arm64 only, SDK 36 target, non-debuggable, no requested permissions |
| Downloaded artifact checksum, ZIP integrity, source commit and private recovery-key certificate comparison | PASS |
| Release AAB through Play delivery / physical devices / policy review | NOT TESTED |

AAB SHA-256: `6e11f31ad210512d5cb3782429aa09e1d1fdfb5afa9e865c0e16b522c3ec628a`.

The signature log retains self-signed-chain, missing-timestamp, ZIP attribute and JarInputStream entry-order warnings from the Android-produced archive. JarFile verification and bundletool validation passed; this is not a claim of public-CA trust or Play acceptance.

`release-metadata.json`, `release-manifest.xml`, `release-certificate.txt` and `release-signature.txt` are copied directly from CI. No keystore, password or secret is included. The dedicated upload key is separate from the existing debug certificate. Recovery files are in private owner storage outside the checkout and require an independent secure backup. Future Play uploads must use a previously unused, increasing version code.

## Native-symbol handoff for the existing version 1

Prepared `build/release-0.1.0-1/native-debug-symbols.zip` (approximately 182 MiB), containing only `arm64-v8a/libgodot_android.so` and `arm64-v8a/libc++_shared.so`. Upload this ZIP through the version-1 bundle's **Downloads → Assets → Native debug symbols** control in Play Console. The existing AAB is unchanged; no new version code is needed for this supplementary upload. Upload/processing in Play Console remains pending.

The source is the [official Godot 4.7.2 release-template symbols archive](https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_native_debug_symbols.4.7.2.stable.template_release.android.zip), verified against its published SHA-256. `scripts/release_symbols.py` compared GNU build IDs against both libraries extracted from the original AAB and verified symbol-table presence. The exact checksums and IDs are in [native-debug-symbols.json](native-debug-symbols.json).

| Symbol check | Result |
| --- | --- |
| Official symbols SHA-256 | PASS — `4bc879f6ef3967dadd55d60382fe36cd79c700877280e5b410527a5ddcb72e49` |
| Godot library build ID | PASS — `270121fef88100c19643517c328b5868e01d345c` |
| C++ runtime build ID | PASS — `ba615e4ff75bc2d8ba1eee93f983e02bc427c433` |
| ZIP CRC/integrity and ABI-root layout | PASS |
| Invalid source archive and mismatched ELF negative checks | PASS — both rejected, no upload ZIP created |
| Godot editor import and deterministic rescue-level suite | PASS |
| Workflow syntax | PASS — actionlint without shellcheck; full lint reports two pre-existing SC2129 style notices |

The deobfuscation warning does not require an upload for this candidate: the [pinned release Gradle template](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/app/build.gradle) does not enable R8 minification, the exported DEX retains Godot class names, and the AAB has no obfuscation mapping metadata. No mapping file was fabricated and minification was not changed.
