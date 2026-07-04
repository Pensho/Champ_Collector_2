# Plan: Team and Roster Abstraction

Replace the magic slot-ID arithmetic (`PLAYER_IDS = [0,1,2]`, `ENEMY_IDS = [3,4,5]`,
`3 + randi() % 3`) with a small team abstraction. This removes an entire bug class
(targeting dead or nonexistent slots), deletes duplicated team-membership checks, and
is the prerequisite for ever fielding more or fewer than 3-versus-3.

## Status

Not started. Best sequenced after `Plan_Combat_Correctness_Fixes.md` (which patches the
worst symptoms in place) and before or during stage 3 of
`Plan_Headless_Combat_Core.md` (the resolver should be written against teams, not raw
IDs).

## Problem

Team layout knowledge is duplicated across:

- `Scripts/Battle/battle.gd` — `PLAYER_IDS`/`ENEMY_IDS` constants, membership checks in
  turn handling, zone targeting, and battle-over scanning.
- `Scripts/Battle/Skills.gd` — its own copies (`PLAYER_IDS`/`MONSTER_IDS`), hardcoded
  `randi() % 3` / `3 + (randi() % 3)` for random targets, and six-slot static arrays
  sized to the assumption.
- `Scripts/UI/Battle_UI/turn_bar.gd` — reaches back into `Battle.PLAYER_IDS` for
  overlay tinting.

Every ally/enemy relationship is expressed as paired `has()` checks, and every random
pick assumes exactly three living members per side.

## Target shape

```
CombatTeam (RefCounted)
├── members: Array[int]                    # slot IDs, order preserved
├── AliveMembers(characters) -> Array[int]
├── Has(id) -> bool
└── RandomAliveMember(characters, rng) -> int   # -1 when none

CombatSides (RefCounted)
├── player: CombatTeam
├── enemy: CombatTeam
├── SideOf(id) -> CombatTeam
├── AlliesOf(id) / EnemiesOf(id) -> CombatTeam
└── AreAllies(a, b) / AreEnemies(a, b) -> bool
```

Built once in `Battle.Init` from the actual roster sizes and passed to whatever needs
it (later: owned by `BattleResolver`).

## Steps

1. **Create `CombatTeam`/`CombatSides`** (`Scripts/Battle/combat_team.gd`) with unit
   tests, including empty-team and all-dead cases.
2. **Rewrite `Skills.FindSkillTargets`** to take `CombatSides` (and the characters
   dictionary, if `Plan_Combat_Correctness_Fixes.md` step 4 has not already added it).
   Every branch becomes a one-liner over `AlliesOf`/`EnemiesOf`/`RandomAliveMember`.
   Update `test_skills.gd` and `test_enemy_turn_targeting.gd`.
3. **Rewrite zone-side checks** — `Skills.CorrectZoneTarget` and the ally/enemy
   filtering in `Battle.TriggerZones` become `AreAllies`/`AreEnemies` calls.
4. **Replace battle.gd membership checks** — turn dispatch (player versus enemy turn),
   `IsTheBattleOver` (scan each team's `AliveMembers` instead of fixed ID ranges),
   damage-tracking guard in `ResolveSkill`.
5. **Remove the reach-back from the turn bar** — pass the needed side information into
   `TurnBar.SetupPlanReachOverlays` instead of referencing `Battle.PLAYER_IDS`.
6. **Size per-combat arrays from the roster** — the six-slot static arrays in `Skills`
   (`_heap_on_stacks`, `_damage_multiplier`) either move to dictionaries keyed by slot
   ID or, if `Plan_Headless_Combat_Core.md` step 1 landed first, are already
   battle-scoped and just need dynamic sizing.

## Watch for

- Slot IDs still index the exported `_character_repr` array and `_char_turns` in the
  turn bar; this plan does not change the ID scheme, only who interprets it. Keep IDs
  stable.
- `Types.Skill_Target.Random_One` and `All` span both teams — make sure the new
  helpers cover the cross-team cases without reintroducing raw ranges.
- Wave sizes below 3 already occur (`Battle_Troll` style single-enemy fights);
  after this plan a two-enemy wave must work with no dead slot 5 phantom.

## Documentation

On completion: update `Technical_Design_Document.md` section 4 (the fixed slot-ID
paragraph) and section 7.3.
