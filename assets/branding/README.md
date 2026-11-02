# Rescue Team launch branding

Original artwork generated on 2026-11-02 with Codex's built-in image generation tool. No external game artwork, trademarks or extracted assets were used. The generated PNGs are preserved at their original output dimensions. `icon-background.svg` is an original solid-color vector layer.

| Asset | Use |
| --- | --- |
| `app-icon.png` | Project icon and Android legacy launcher icon |
| `adaptive-icon.png` | Padded paired-helmet artwork for adaptive launchers and Android's native splash |
| `icon-background.svg` | Deep-teal adaptive background |
| `boot-splash.png` | Portrait title artwork displayed by Godot during startup |

The paired yellow firefighter helmet and blue engineer hardhat use the coastal game's existing gold/blue/teal palette. The adaptive version leaves room for circular/squircle masks. The earlier `assets/icon.svg` remains as historical source art; it is no longer the configured launcher icon.

## Loading behavior

`export_presets.cfg` configures Android's native splash with the new icon and teal background. `project.godot` keeps the Godot boot splash enabled and uses the portrait title image with aspect-preserving scaling. It is visible while the engine loads the main scene, then the normal mission picker takes over. There is no added timer, simulated progress bar or extra tap to enter the game. Existing campaign/audio/cosmetic/checkpoint files are unchanged.

## Generation prompts

All three images used built-in tool mode; no API/CLI fallback was used.

**App icon:** Use case: stylized-concept. Asset type: production Android game app icon, square 1024x1024. Create ONE original premium polished illustrated 2D mobile rescue puzzle game icon. A bold golden yellow firefighter helmet with dark navy visor and a small teal shield badge, accompanied by one compact blue engineer hardhat tucked behind it to communicate a rescue TEAM. No humans, no faces, no letters, no medical cross, no fire emergency chaos. Friendly hopeful warm hand-painted game art, clear large silhouettes, restrained glossy highlights, orange and gold against a completely opaque uniform deep teal background #194f63, matching a sunlit illustrated coastal rescue game with yellow-helmet firefighter and blue-hardhat engineer. Both helmets form ONE compact centered emblem entirely contained inside the central 62 percent diameter circle, plenty of uninterrupted teal padding all around for Android circular and squircle masks. Frontal three-quarter camera, subtly overlapping helmets, not a busy scene. Edge-to-edge square canvas, no rounded-corner outer frame, no border, no text, no watermark. Crisp legible at 48px. Artwork only.

**Boot splash (edit of the generated icon):** Edit the supplied original Rescue Team helmet icon to create a matching portrait mobile GAME BOOT SPLASH artwork, approximately 720x1280 portrait. Preserve the golden firefighter helmet and blue engineer hardhat identity and illustrated style exactly. Solid deep teal background #194f63 throughout the canvas, without vignette, environment or frame. Place a SMALL clean version of the same paired-helmet emblem centered horizontally, centered at about 43% of canvas height, occupying only 42% of canvas width. Under the emblem place the exact title 'RESCUE TEAM' in large strong cream condensed sans-serif capitals, two words on ONE centered line, no other text at all. Very generous negative space above and below. Entire logo and title should be confined within the center 45% of the portrait canvas height so it reads at any screen aspect ratio. Calm premium illustrated coastal rescue puzzle game branding. No loading bar, no percent, no spinner, no tiny text, no third party branding, no extra objects, no characters. Artwork only.

**Adaptive icon (edit of the generated icon):** Edit this supplied original paired rescue helmet icon ONLY to add substantially more padding for Android adaptive app icon masks. Keep the exact two helmets and their visual design. Shrink the entire existing paired helmet emblem to 58 percent of the square canvas width, centered in BOTH axes. Keep every part of helmet artwork within a centered circle of diameter 62 percent of canvas. Extend uniform opaque deep teal #194f63 background to all four edges. Square1024x1024. No new objects, no text, no outer border. This is a padded export variant of an existing icon: retain identity, colors, pose, helmet badge and style. The emblem must look visibly SMALLER than the reference with large teal margins on every side.

## Android acceptance scenario

Install the matching CI APK over the stable-debug build without clearing data. Check the launcher icon under circular and squircle masks; both helmets should remain readable. Force-stop and launch from the launcher, then observe native splash → title splash → mission picker, with no Godot logo, stretched title, blank flash or required tap. Repeat cold/warm launches on a small and a tall phone and confirm saved progress and resume still work. Very fast launches may show the title only briefly; no minimum delay is imposed. Android 12+ owns the initial native splash, so its size/transition can differ by OS/launcher. A successful export alone does not establish device appearance.
