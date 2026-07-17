# Test Design Document — champ_collector

## Testing tool

Framework: **GUT** (Godot Unit Test), version 9.5.x.

Run headlessly from the project root:
```
/home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64 \
  --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd -gexit
```

## What we test

Unit tests cover **pure logic only** — functions that transform values and return results without depending on the scene tree, the rendering engine, or Godot autoloads beyond `main` (which can be minimally mocked).

| Area | File | What is covered |
|---|---|---|
| Adventure state | `test_adventure_state.gd` | Supply cost tiers, daily reset, serialization roundtrip (via real Serialize/Deserialize), node completion, scaled difficulty |
| Adventure generation | `test_adventure_generator.gd` | Node count, uniqueness, boss node, biome context |
| Android export safety | `test_android_export_safety.gd` | No DirAccess or `get_window().size` usage in scripts (packed-export guards) |
| Loot manager | `test_loot_manager.gd` | Fortunes Favor primary/secondary distribution by difficulty and budget |
| Level system | `test_level_system.gd` | XP formula monotonicity, level-up threshold, XP consumption, `SetOpponentLevel` guards and attribute scaling |
| Skills (targeting) | `test_skills.gd` | `FindSkillTargets` for all target types; `CorrectZoneTarget` truth table |
| Battle resolver | `test_battle_resolver.gd` | Full seeded 3-versus-3 battle to a winner, same-seed reproducibility, per-resolver (non-static) Heap-On state |
| Resource handler | `test_resource_handler.gd` | `SpendSupplies` success, failure, exact, zero, empty-state paths |
| Character | `test_character.gd` | Equipment bonus baseline, `GetBattleAttribute` with and without gear, `EquipItem`/`UnequipItem` slot management |
| Collection serialization | `test_collection_serialization.gd` | `ItemCollection` and `CharacterCollection` Serialize↔Deserialize roundtrips through real methods |
| Battle over screen | `test_battle_over.gd` | UI focus, Init loss/victory, scene-change calls |

## What we deliberately do NOT unit-test

These areas depend on the scene tree, rendering, or real input and are covered by manual play instead:

- `Scripts/Battle/battle.gd` — after the headless-combat-core extraction this script is input
  handling, a turn-flow state machine, and result rendering only; the combat logic it used to own
  is tested through `BattleResolver` (`test_battle_resolver.gd` and the trait/status tests)
- `Scripts/Battle/character_battle_repr.gd` — visual representation node
- All scripts under `Scripts/UI/` — requires scene instantiation
- Texture and asset loading — hardware-dependent

## Determinism rules

Tests that involve randomness must use one of these approaches:
1. **Seed the resolver**: combat rolls all go through `BattleResolver`'s injected `RandomNumberGenerator`; construct it with a fixed seed (`TestFactory.make_resolver` defaults to seed 0) so every roll is reproducible.
2. **Seed before calling**: `seed(12345)` immediately before a call that still uses the global generator (non-combat code).
3. **Assert bounds / invariants**: when exact output cannot be predicted (e.g. `Random_Enemy` targeting), assert the result is within the valid range and test the branch conditions via non-random paths instead.

## File naming and helper

- Test files: `Tests/unit/test_<feature>.gd`, all extending `GutTest`.
- Shared builders: `Tests/unit/helpers/test_factory.gd`. Load it via:
  ```gdscript
  const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
  ```
  The factory provides static builders: `make_character()`, `make_full_roster()`, `make_full_sides()`, `make_resolver()`, the skill builders (`make_strike_skill()`, `make_empty_skill()`, `make_lava_zone_skill()`), `make_loot_table()`, `make_adventure_state()`, and the `FakeTurnPositions` stub for zone/reach queries. Add a builder when the same construction logic is needed in two or more test files.

## Known issues / flags

- `last_palayed_date` is a misspelled field name in `AdventureState` (and `AdventureTemplate`). The serialization key is `last_played_date`. Renaming is a deliberate refactor — do it in a separate approved change.
- `test_battle_over.gd` produces orphan-node warnings on every test from `ContextContainer` (`extends Node`). These are pre-existing and out of scope here. `Character` and `TraitSkillResult` orphans are resolved — both now extend `RefCounted` and are constructed via `.new()`.
