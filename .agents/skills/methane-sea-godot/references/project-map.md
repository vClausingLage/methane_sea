# Methane Sea Project Map

## Engine And Settings

- `project.godot` uses `config_version=5`, Godot 4.6 features, Forward Plus, and main scene `world.tscn`.
- Jolt Physics is enabled for 3D. 2D default gravity is `0.0`, so submarine and actor movement should apply forces directly.
- GUT is enabled via `res://addons/gut/plugin.cfg`.
- `.gutconfig.json` points tests at `res://test/unit` and exits after test execution.

## Layout

- `Scripts/player.gd`: submarine host, command input, sonar toggle, movement delegation.
- `Scripts/Movement/submarine_movement.gd`: reusable `RefCounted` movement logic.
- `Scripts/command_player.gd` and `Scripts/motor_player.gd`: command delay/audio and motor stream playback.
- `Scripts/Sonar/`: active sonar, passive sonar, drawing, and pure logic helpers.
- `Scripts/Cave/` and `Scripts/Surface/`: tool scripts for generated cave/surface geometry and collision.
- `Scripts/World/`: world startup and world actors such as `killerfish`.
- `test/unit/`: GUT tests for logic classes.

## Current Caution

At the time this skill was created, `test/unit/test_sonar_logic.gd` contained unresolved merge-conflict markers. Re-check before running or modifying tests:

```powershell
rg -n "<<<<<<<|=======|>>>>>>>" test/unit/test_sonar_logic.gd
```

Do not silently resolve user conflicts unless the user asks for that fix.

## Validation Commands

Use text checks even when Godot is unavailable:

```powershell
rg -n "<<<<<<<|=======|>>>>>>>" .
rg -n "class_name|extends|@export|func " Scripts test
```

Run all GUT tests when possible:

```powershell
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```
