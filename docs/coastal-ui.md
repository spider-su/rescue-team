# Coastal rescue UI

The approved direction is an original human rescue squad in a warm coastal town. This implements the mission picker, active puzzle and completion screens from the UI sketch using real Godot controls and the existing deterministic missions.

## Presentation

- Warm paper panels, navy headers, orange firefighter, blue engineer, teal primary actions and green rescue exits.
- Original harbor and victory illustrations, crew portraits/full-body sprites and interactive-object atlas. Asset provenance, exact generation prompts and font licenses are under `assets/coastal/README.md` and `assets/fonts/`.
- Scrollable cards for all ten missions: completed, available and locked states. The first uncompleted available mission is highlighted. Thumbnails are decorative harbor crops, not previews of map geometry.
- Gameplay prioritizes a live board, explicit active specialist, move count, objective, current model feedback and undo/restart/levels. The header has a back-to-missions control. Buttons disable during movement.
- The board uses square cells and low stone walls over decorative harbor surroundings. On tall play areas it rotates a wide mission clockwise; both route drawing and pointer picking transform back to original model coordinates. It keeps the original orientation on shorter play areas. It does not modify JSON maps, collision, action count or solutions.
- Completion shows actual moves and saved best, next mission, replay, undo rescue and levels. Final completion returns to the campaign; save failures are visible and disable the next-mission action. Small screens can scroll completion controls into view.
- Main command targets are at least 96 project units tall (48 dp when a 720-unit layout occupies a 360-dp-wide display); specialist selectors are 108 units tall. Grid targets depend on map and device size and still require physical touch evaluation. Selection uses equipment, portraits and outlines in addition to color.
- Android safe-area insets are applied to the content shell. Android Back returns from play/completion to missions, then exits from the mission picker. Back is ignored during an active movement route.

## Validation

Run editor import, `test_rescue_level.gd`, `test_campaign.gd`, `test_rescue_ui.gd` and scene startup. CI runs all these before Android export.

The UI test instantiates the production scene inside a viewport with an isolated save. It exercises locked missions, real board input and animation, civilian collection, whole-route undo, victory/save/unlock, replay, next mission, the last mission, failed-save feedback, scrolling and tile projection for all ten maps in both orientations. It checks play controls at 720×1280, 720×1600 and 540×960, plus scrolled completion controls at 540×960. The graphical version exports actual viewport screenshots with `-- --capture-dir=/absolute/path`.

Actual rendered evidence is stored in [evidence/2026-10-31-coastal-ui](evidence/2026-10-31-coastal-ui/). Screenshot prior completions are seeded only in the test save. Rendering uses Godot GL Compatibility on macOS; this is desktop evidence, not Android device proof. The first local import encountered a transient engine crash during font import; a retry and a separate clean-cache import completed. Android's clean CI import is a separate required check.

## On-device acceptance scenario (pending)

Record device model, Android version, APK commit and signing/install result. Starting with an isolated test install:

1. Open the picker offline. Scroll to mission 10 and back; verify locked cards cannot start a mission and scrolling does not accidentally activate a card.
2. Complete mission 01 by selecting the firefighter, tapping the civilian and then the exit. During motion, rapidly tap other controls: no duplicate actions or scene changes should occur.
3. Check actual moves/best, next unlock, replay and undo rescue. Force-stop and reopen; completed missions and saved best must persist.
4. Reach mission 04. Select each specialist through both portrait buttons and board sprites. Push onto the switch, extinguish fire and rescue the civilian. Verify route dots, active selection, open gate and carrying marker. Undo an entire long route and restart.
5. Check Android Back, status/navigation bars, camera cutouts, background/resume and a smaller/taller display. Ensure command buttons and completion actions remain reachable, and board orientation/picking remain consistent after resizing/resume.
6. Complete mission 10; the main completion action must return to the ten completed missions. This UI milestone is not accepted on hardware until these results are recorded.

No ads, billing, energy, timers, stars, accounts or new puzzle mechanics were added. Audio and broader Android polish remain roadmap work.
