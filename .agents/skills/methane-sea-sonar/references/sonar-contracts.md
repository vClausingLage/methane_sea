# Sonar Contracts

## Active Sonar

`Scripts/Sonar/sonar.gd` owns active scan timing, manual/auto mode, input-facing methods, raycasts, and calls into drawers.

`SonarLogic.build_ray_directions(cone_angle, rays, global_rotation)` returns an `Array[Vector2]` spread from `-cone_angle / 2` in `cone_angle / rays` steps and rotated by `global_rotation`.

`SonarLogic.build_echo(origin, hit_pos, wave_speed, max_range, is_organic_hit)` returns `{}` for hits at or beyond `max_range`; otherwise it returns:

```gdscript
{
	"point": hit_pos,
	"delay": distance / wave_speed,
	"noise": false,
	"organic": is_organic_hit
}
```

`SonarLogic.is_organic_collider(collider)` walks from collider to parents and currently checks for an `isOrganic` property. If adding metadata or snake_case support, update tests and actors consistently.

## Passive Sonar

`Scripts/Sonar/passive_sonar.gd` finds emitters in group `&"passive_sound_emitters"`, skips self/parent, resolves streams/loudness, ranks candidates by strength, creates `AudioStreamPlayer` children, and draws directional hints.

Emitter contracts, in preferred order:

- `get_passive_sonar_stream() -> AudioStream`
- `get_passive_sonar_loudness() -> float`
- metadata `passive_sound` / `passive_loudness`
- properties `passive_sound` / `passive_loudness`

`PassiveSonarLogic` owns range, strength, volume, direction, and visual contact fading. Keep these calculations scene-independent.

## Player Wiring

`Scripts/player.gd` controls sonar through child node `$sonar`:

- `KEY_UP` / `KEY_DOWN` rotate scan through `rotate_scan(delta)`.
- `KEY_SPACE` calls `scan()` when commands are not locked.
- command-player sonar toggle flips visibility and processing through `_set_sonar_enabled()`.

Changes to scan availability, command locking, or control keys must account for this host script.
