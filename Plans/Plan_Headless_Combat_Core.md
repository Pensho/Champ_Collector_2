# Plan: Headless Combat Core

Extract combat resolution into a layer that runs without the scene tree, addressing
`Technical_Design_Document.md` sections 15.1 (user interface and combat logic are
tightly coupled) and 15.2 (static mutable state in `Skills`). This is the largest
plan and the one that unlocks the others: testable combat, signals at the battle-to-UI
seam (15.4), reproducible rolls, and the "Run Multiplier" auto-battle idea from
`FeatureIdeas.md`.

## Status

Not started. Both recommended predecessors are complete: the combat-correctness fixes
and the team and roster abstraction. Stage 3's resolver is therefore written against
`CombatTeam`/`CombatSides`, not raw slot IDs.

## Target shape

A pure resolution core that mutates `Character` state and returns/emits *result
records* ("X took 12 damage", "Y gained Empower for 2 turns", "Z bumped +15% on the
turn bar"). `battle.gd` shrinks to: feed input in, render results out.

```
BattleResolver (RefCounted, no nodes)
├── owns per-combat transient state (heap-on stacks, damage multipliers, zones)
├── owns a RandomNumberGenerator (injectable, seedable)
├── ResolveSkill(...) -> Array[CombatResult]
└── emits/returns results; never touches CharacterRepresentation or BattleUI
```

## Steps

### 1. Move `Skills` static state onto a battle-scoped object
- **What:** `_heap_on_stacks`, `_heap_on_value`, `_damage_multiplier` are `static var`
  on `Skills` (`Scripts/Battle/Skills.gd:10-12`), reset via `Skills.Reset()`. Create a
  `BattleResolver` (or extend the existing combat context) instantiated per battle that
  owns this state; delete `Skills.Reset()` once nothing references the statics.
- **Files:** `Scripts/Battle/Skills.gd`, `Scripts/Battle/battle.gd`, new
  `Scripts/Battle/battle_resolver.gd`.
- **Watch for:** tests that currently call `Skills.Reset()` between cases.

### 2. Inject a seedable random number generator
- **What:** combat uses global `randf_range`/`randi_range`/`randi` (damage variance,
  crits, debuff resist, enemy speed jitter). Give `BattleResolver` a
  `RandomNumberGenerator` member, seed it from the encounter (mirroring how adventure
  generation is already seeded), and route every combat roll through it.
- **Files:** `Scripts/Battle/Skills.gd`, `Scripts/Battle/battle.gd`.
- **Why:** deterministic unit tests for crits, resists, and variance — several steps in
  `Plan_Combat_Correctness_Fixes.md` get stronger tests once this exists.

### 3. Extract skill resolution from `battle.gd` into the resolver
- **What:** move the logic of `ResolveSkill`, `TriggerZones`, and the battle-over check
  out of the `Node2D` into `BattleResolver`, returning typed result records
  (`CombatResult` resource or lightweight class: kind, source ID, target ID, amount,
  status type, duration). `battle.gd` keeps: input handling, calling the resolver, and
  translating results into visuals (life bars, combat text, grayscale, turn indicator).
- **Files:** `Scripts/Battle/battle.gd`, `Scripts/Battle/battle_resolver.gd`, new
  `Scripts/Battle/combat_result.gd`.
- **Watch for:** trait hooks currently receive `BattleUI` and
  `CharacterRepresentation` parameters directly (for example `StartOfTurn`,
  `OnDamageTaken` in `Scripts/Character/CharacterTraits/`). Traits must instead return
  or append result records; this touches every trait under
  `CharacterSpecificTraits/` and their tests. Migrate hook by hook, not all at once.
- **Watch for:** zone effects on allies now scale with caster Knowledge
  (commit `1dbe29f`: `Zone` carries the caster's Knowledge, constants in
  `game_balance.gd`) — that scaling moves into the resolver along with
  `TriggerZones`.
- **Watch for:** the turn bar is both state (positions decide zone hits and Plan-trait
  reach) and view. Short term, keep positional queries behind an interface the resolver
  calls; long term the positions belong in the core.

### 4. Introduce signals at the battle-to-UI seam
- **What:** with results as data, have the battle scene connect to
  `BattleResolver.result_produced` (or iterate returned arrays) instead of the resolver
  reaching into UI. This resolves the convention mismatch recorded in section 15.4 for
  the highest-traffic boundary; afterwards, update the convention text if the remaining
  direct-call seams are accepted as-is.
- **Files:** `Scripts/Battle/battle_resolver.gd`, `Scripts/Battle/battle.gd`,
  `CLAUDE.md` (convention note).

### 5. Replace the turn sentinel with an explicit state machine
- **What:** turn flow is implicit in `_turn_character_ID == NO_CHARACTERS_TURN`
  polled from `_process`,
  and `HandleEnemyTurn` carries a "TODO: Clean this nested mess up". Introduce explicit
  states (Advancing, AwaitingPlayerInput, EnemyActing, Resolving, BattleOver) as an
  enum-driven state machine in `battle.gd`.
- **Files:** `Scripts/Battle/battle.gd`.
- **Watch for:** zone-selection is a sub-mode of the player-input state (skill chosen,
  waiting for a zone click) — model it as such rather than a boolean.

### 6. Headless battle test
- **What:** the payoff test — run a full scripted 3-versus-3 battle through
  `BattleResolver` with a fixed seed in GUT, assert the winner and key intermediate
  results. This is the regression net for all future combat work and the foundation for
  the "Run Multiplier" feature.
- **Files:** new `Tests/unit/test_battle_resolver.gd`, fixtures in
  `Tests/unit/helpers/test_factory.gd`.

## Documentation

When this lands, update `Technical_Design_Document.md` sections 7 (combat as
implemented), 12 (communication patterns), and strike 15.1/15.2; update
`Test_Design_Document.md` to remove the "battle scene excluded from logic tests"
caveat.
