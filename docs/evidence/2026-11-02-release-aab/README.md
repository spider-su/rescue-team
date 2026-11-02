# First signed Android App Bundle — 2026-11-02

Candidate `0.1.0` / Play version code `1`, package `com.spidersu.rescueteam`, source `ea291a045ae142ce6809f2e179fa5540d184dea7`.

[Successful release build](https://github.com/spider-su/rescue-team/actions/runs/41460812065) — download the `rescue-team-release-aab` artifact. The local handoff is `build/release-0.1.0-1/rescue-team-release.aab` (ignored by Git). The AAB is an upload artifact, not a directly installable APK. It has not been submitted to Play.

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
