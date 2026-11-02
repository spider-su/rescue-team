# Launcher and loading-screen visual check — 2026-11-02

Tested the actual arm64 debug APK from [CI run 41424619734](https://github.com/spider-su/rescue-team/actions/runs/41424619734), source `651a100`. Godot import, all eight suites and Android export passed in that run. Exact asset/APK hashes are in `manifest.json`.

A dedicated fresh `rescue-team-branding` AVD (`emulator-5556`, Android 15 / API 35, 1080×2400, 420 dpi) was created for this check. It ran with software graphics and no audible output. The existing `emulator-5554` was not used for this build's installation or launch test.

| Check | Result | Evidence |
| --- | --- | --- |
| Install production CI APK | PASS | ADB install returned Success. |
| Android launcher uses new paired helmets | PASS | `launcher.png`, icon in the lower-right dock; both helmets survive the circular mask. |
| Native Android splash uses new icon | PASS | `cold-launch-01.png`; the prebuilt template uses the system light background. |
| Custom title image appears while Godot loads | PASS | `cold-launch-06.png`; readable title, preserved proportions, no Godot logo. |
| Startup proceeds to menu automatically | PASS | `cold-launch-11.png`; no tap was required between launch and mission picker. |
| Initial render-surface continuity | Observation → configuration adjusted | `cold-launch-03.png` caught a black surface before the title appeared. Follow-up source `a78af66` sets `screen/background_color` to teal; the screenshots here predate that setting and do not prove the changed handoff. |
| Physical devices, older Android, alternate launcher masks | NOT TESTED | Separate Android acceptance scenario in `assets/branding/README.md`. |

`frames.json` records host-side elapsed capture-start times. Screenshots are sampled Android framebuffer captures, not a continuous frame-rate or startup performance measurement. The PNGs are unmodified. `launch.txt` records the activity launch; its timing does not measure completion of the Godot menu.

The changed render-surface color does not change icon/title assets, startup sequencing, package ID or gameplay. No minimum splash duration or simulated loading progress was added.

The follow-up configuration at `a78af66` passed all eight suites and Android export in [run 41425412538](https://github.com/spider-su/rescue-team/actions/runs/41425412538). Its updated initial render-surface appearance still needs a fresh emulator capture; the asset and menu screenshots here retain their original `651a100` provenance.
