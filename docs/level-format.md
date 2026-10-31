# Level content format

Each JSON map under `levels/` is a UTF-8 object with an `id`, `title`, player `hint` and rectangular `rows`. A level is not playable unless its filename appears in the explicit manifest in `scripts/level_catalog.gd`.

Example (truncated for explanation; actual file must pass validation):

```json
{
  "id": "01",
  "title": "First Response",
  "hint": "Tap the civilian, then the green exit.",
  "rows": [
    "#########",
    "#F.C.X..#",
    "#.......#",
    "#E......#",
    "#########"
  ]
}
```

| Character | Meaning |
| --- | --- |
| `#` | Permanent wall |
| `.` | Walkable floor |
| `F` / `E` | Firefighter / engineer starting tile |
| `R` / `Z` | Optional ranger spawn / stationary infected blocker |
| `C` / `X` | Civilian / extraction exit |
| `f` | Optional fire hazard (firefighter clears) |
| `B` / `s` / `G` | Optional crate / floor switch / gate (all three together) |

Validation requires same-length rows, all-wall border, board 5–24 columns × 3–24 rows, exactly one F/E/C/X, at most one fire, and either zero or exactly one each of B/s/G. An optional ranger is unique; at most six infected are supported, and any infected requires a ranger. Optional `location` is `coast` (default) or `old-town`. Invalid maps are rejected before game startup rather than partially applied.

A `RescueLevel` instance keeps the parsed definition and resets to its own map. Its BFS routing only uses currently walkable tiles and preserves fire, crate and gate interactions as explicit actions. Adding a level requires a known winning route in `tests/test_campaign.gd` (original chapter) or `tests/fixtures/old_town_solutions.json` replayed by `tests/test_old_town.gd` so content cannot silently ship unwinnable.

Progress is stored locally as JSON in `user://rescue_progress_v1.json` containing version 1 and a map of completed level IDs to best move counts. Only the next level after a completed predecessor unlocks; corrupted or unknown records are safely ignored. There is no online account or cloud synchronization.

The explicit manifest groups IDs 01–10 in Coastal District and 11–20 in Old Town Quarantine. IDs 01–10 and the progress-file format are unchanged. See [Old Town rules, walkthrough counts and device scenario](old-town.md).
