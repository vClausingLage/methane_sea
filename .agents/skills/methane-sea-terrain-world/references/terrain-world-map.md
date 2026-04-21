# Terrain And World Map

## Cave

`Scripts/Cave/cave.gd` is an `@tool` `Node2D`. It expects:

- `Path2D`
- `Polygon2D`
- optional `StaticBody2D/CollisionPolygon2D` or direct `CollisionPolygon2D`

`generate()` resolves nodes, creates a default curve when missing, configures `FastNoiseLite`, bakes and deduplicates curve points, creates a fill polygon, builds segmented collision parts named `ColliderPart%d`, and creates/updates `EdgeLine2D`.

At runtime `_restore_collision_from_saved_edge()` rebuilds segmented collision from saved `EdgeLine2D` points unless running in editor hint mode.

## Surface

`Scripts/Surface/spline_terrain.gd` is an `@tool` `Node2D`. It expects child nodes named:

- `path`
- `body`
- `line`
- `body/polygon`
- `body/collider`

It creates visual fill parts under `body/fill_parts` and collision parts named `collider_part_%d` directly under `body`. It disables the legacy single collider before applying segmented collision.

## World Actors

`Scripts/World/killerfish.gd` is a `RigidBody2D` actor with:

- `isOrganic := true` for active sonar organic detection.
- `passive_sound` and `passive_loudness` exported for passive sonar.
- `_ready()` adds the actor to `&"passive_sound_emitters"`.
- `get_passive_sonar_stream()` and `get_passive_sonar_loudness()` implement the passive sonar emitter contract.

Preserve these contracts when adding or refactoring actors that should appear on sonar.
