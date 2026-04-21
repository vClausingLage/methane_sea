---
name: methane-sea-sonar
description: Maintain methane_sea active sonar, passive sonar, sonar drawing, organic detection, emitter contracts, player sonar controls, and related GUT tests. Use for tasks touching Scripts/Sonar, sonar nodes in scenes, scan timing, echo visualization, passive audio contacts, or sonar test failures.
---

# Methane Sea Sonar

## Quick Start

Start from the logic classes before changing scene scripts:

- Active sonar logic: `Scripts/Sonar/sonar_logic.gd`
- Passive sonar logic: `Scripts/Sonar/passive_sonar_logic.gd`
- Active sonar integration: `Scripts/Sonar/sonar.gd`
- Passive sonar integration: `Scripts/Sonar/passive_sonar.gd`
- Rendering: `Scripts/Sonar/sonar_drawer.gd`, `Scripts/Sonar/sonar_cone_drawer.gd`
- Tests: `test/unit/test_sonar_logic.gd`, `test/unit/test_passive_sonar_logic.gd`

Read `references/sonar-contracts.md` before changing behavior.

## Implementation Pattern

- Put deterministic calculations in `SonarLogic` or `PassiveSonarLogic` as `static func` methods.
- Keep scene scripts responsible for Godot APIs: input, physics queries, drawing, audio players, node lookup, and groups.
- Preserve the active sonar echo dictionary shape: `point`, `delay`, `noise`, `organic`.
- Preserve passive sonar candidate fields: `node`, `stream`, `strength`, `direction`.
- Update or add GUT tests for logic-level behavior whenever calculations, organic detection, emitter contracts, or fading behavior changes.

## Common Checks

Before trusting sonar tests, check for conflict markers:

```powershell
rg -n "<<<<<<<|=======|>>>>>>>" Scripts/Sonar test/unit
```

Run the sonar tests with GUT when Godot is available:

```powershell
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_sonar_logic.gd -gtest=res://test/unit/test_passive_sonar_logic.gd
```

If the task changes player controls, also inspect `Scripts/player.gd` because it gates sonar rotation, scan input, and sonar visibility.
