---
name: methane-sea-godot
description: Project-specific Godot workflow for methane_sea. Use when Codex works in this repository on Godot 4.6 scenes, GDScript, assets, tests, project settings, export settings, or broad changes that need awareness of the project layout, validation commands, merge-conflict state, and existing architecture.
---

# Methane Sea Godot

## Quick Start

Confirm the working tree before editing:

```powershell
git status --short
rg -n "<<<<<<<|=======|>>>>>>>" .
```

Prefer scoped edits in `Scripts/`, `Scenes/`, `Shader/`, or `test/unit/`. Avoid changing `.godot/`, generated `.uid` files, imported asset metadata, and `world.tscn*.tmp` unless the user explicitly asks.

Read `references/project-map.md` for the current architecture and validation workflow.

## Project Rules

- Treat this as a Godot 4.6 project using Forward Plus, Jolt Physics, zero 2D gravity, and GUT tests.
- Preserve existing folder casing: `Scripts`, `Scenes`, `Shader`, `Assets`, `test/unit`.
- Use GDScript style already present in the repo: tabs for indentation, typed parameters/returns where surrounding code uses them, `@export` for designer-tunable values, `class_name` only for reusable logic/helpers.
- Keep pure logic in `RefCounted` classes when practical so it can be covered by GUT without scene setup.
- Be careful with `.tscn` edits. Prefer script changes or targeted scene diffs; Godot scene files are order-sensitive and easy to corrupt manually.
- Do not trust test results if merge-conflict markers are present. Resolve or report conflicts first depending on the user request.

## Validation

Run focused text checks first:

```powershell
rg -n "<<<<<<<|=======|>>>>>>>" Scripts test Scenes project.godot
rg -n "push_error|TODO|FIXME" Scripts test
```

Run GUT when Godot is available on PATH:

```powershell
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

If the executable is named differently on Windows, try `godot4` or the locally installed Godot path. Report clearly when Godot is unavailable.
