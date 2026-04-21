---
name: methane-sea-terrain-world
description: Maintain methane_sea terrain, cave generation, world setup, surface/cave scenes, killerfish/world actors, collision generation, passive sonar emitters, and related scene scripts. Use for tasks touching Scripts/Cave, Scripts/Surface, Scripts/World, Scenes/cave.tscn, Scenes/surface.tscn, Scenes/killerfish.tscn, or world.tscn.
---

# Methane Sea Terrain World

## Quick Start

Read the relevant script before editing scenes:

- Cave generation: `Scripts/Cave/cave.gd`
- Surface terrain: `Scripts/Surface/spline_terrain.gd`
- World setup: `Scripts/World/world.gd`
- World actor: `Scripts/World/killerfish.gd`
- Scenes: `Scenes/cave.tscn`, `Scenes/surface.tscn`, `Scenes/killerfish.tscn`, `world.tscn`

Read `references/terrain-world-map.md` for node contracts and regeneration behavior.

## Implementation Pattern

- Preserve `@tool` behavior in terrain scripts so generation can run in the editor.
- Keep generated collision segments as direct children of the relevant collision parent.
- Deduplicate baked curve points before generating fill or collision polygons to avoid degenerate geometry.
- Prefer script changes for generation behavior; edit `.tscn` only when node names, exported values, or scene wiring must change.
- Preserve passive sonar actor contracts on world actors: group `passive_sound_emitters`, `get_passive_sonar_stream()`, and `get_passive_sonar_loudness()`.

## Validation

Check for scene and script conflicts:

```powershell
rg -n "<<<<<<<|=======|>>>>>>>" Scripts/Cave Scripts/Surface Scripts/World Scenes world.tscn
```

When changing terrain generation, verify both editor-time and runtime assumptions: exported setters should clamp values, `generate()` should tolerate missing optional nodes with warnings or no-ops, and runtime restoration should rebuild collision from saved visual edge data when needed.
