# Test Design Document — champ_collector

## Testing tool

Framework: **GUT** (Godot Unit Test), version 9.5.x.

Run headlessly from the project root:
```
./Tests/run_tests.sh
```

`Tests/run_tests.sh` wraps the `gut_cmdln.gd` invocation and prints only GUT's run
summary — failing tests with their assert texts and line numbers, plus the totals.
Arguments are passed through to GUT, so `./Tests/run_tests.sh -gtest=res://Tests/unit/test_foo.gd`
runs a single file.

## What we test

Unit tests cover **pure logic only** — functions that transform values and return results without depending on the scene tree, the rendering engine, or Godot autoloads beyond `main` (which can be minimally mocked).

The suite is organized around **what can break**, not around what content exists. Every
test file belongs to exactly one of three tiers, and the tier decides its shape.

### Tier 1 — Mechanism tests

One file per engine mechanism, parameterized over that mechanism's cases. This is where
thoroughness belongs: if a rule can be stated about the engine, its cases live here.

Exemplars: `test_skill_effects.gd` (one section per `SkillEffect` subclass),
`test_status_effect_hooks.gd`, `test_skill_effect_order.gd`, `test_graft.gd`,
`test_targeting_order.gd`, `test_skills.gd`, the `test_turn_bar_*` family,
`test_battle_resolver.gd`.

A new mechanism gets a new Tier 1 file. A new *case* of an existing mechanism gets a new
test inside the existing file.

### Tier 2 — Contract sweeps

One data-driven test that iterates **all** items of a kind and asserts a semantic
invariant. A sweep covers content that does not exist yet, which is what makes the
per-item test file unnecessary.

| Sweep | Iterates | Invariant |
|---|---|---|
| `test_trait_contract.gd` | every script in `character_traits/CharacterSpecificTraits/` and `Grafts/`, at every rarity | every `CharacterTrait` hook is callable, returns in range, returns the neutral value for a dead owner; rarity tables are no worse at Legendary than at Uncommon |
| `test_skill_content_sweep.gd` | every `.tres` in `Data/Character_Skill_Variants/` | every authored enum resolves — buff/debuff types registered in `StatusEffectRegistry`, condition/condition_test/target in range |
| `test_skill_resources.gd` | the same skill resources | each loads and carries at least one effect |
| `test_character_preset_skill_invariant.gd` | every `CharacterPreset` resource | slot-0 skill has no cooldown (the enemy-turn fallback depends on it) |
| `test_android_export_safety.gd` | every script under `Scripts/` | no `DirAccess` or `get_window().size` usage (packed-export guards) |

Two rules govern sweeps:

- **Assert semantics, never cosmetics.** A sweep may assert that an authored enum resolves,
  that a referenced resource loads, that a hook is neutral for a dead owner. It must not
  assert description wording, icon not-null, non-empty strings, or expected row counts.
- **Never pass vacuously.** A directory scan that silently finds nothing looks green and
  proves nothing, so each sweep's first assert is a non-zero item count. If content moves
  folder, the sweep must fail loudly rather than skip.

### Tier 3 — Novel behavior

A bespoke file survives only for behavior **no other content has**: `test_shield_wall_trait.gd`'s
damage-redirect split, `test_standing_record_trait.gd`'s counter source,
`test_detritivore_graft.gd`'s uncapped scrap stacks. Anything a trait, graft, or skill
*shares* with its peers — rarity scaling, "the hook fires", "does nothing when the owner is
dead" — belongs in Tier 1 or Tier 2 instead, and a test restating a data table
(copying `MOMENTUM_PER_STACK` and asserting it equals itself) detects nothing and does not
belong anywhere.

### Regression tests outrank the tiers

A test written for a bug that actually shipped is kept verbatim, in whatever file it lives
in, even where it looks redundant — its value is that the bug happened. Files carrying such
tests mark them with an explanatory comment (`test_character_skill_isolation.gd`,
`test_health_result_ordering.gd`, `test_turn_bar_speed.gd`, `test_dead_owner_hook_gating.gd`
and others). If a regression test moves file, its comment moves with it.

## When adding content, do not add a test file

New traits, grafts, skills, and presets are covered **by construction** — the Tier 2 sweeps
pick them up from the directory scan the moment the file exists. Adding a champion does not
imply adding a test.

Write a new test file only when one of these is true:

1. The content introduces a **mechanism no existing content has** (Tier 3), or a mechanism
   general enough to deserve its own Tier 1 file.
2. It fixes a **bug that shipped**, and the test locks the fix in.

Otherwise: run the suite, confirm the sweeps pass with the new content in place, and stop.
If the sweeps would not have caught a plausible authoring mistake in the new content,
strengthen the sweep — do not write a file about the one item.

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
