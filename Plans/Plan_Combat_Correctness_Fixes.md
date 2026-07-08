# Plan: Combat Correctness Fixes

Small, independent defect fixes in the combat path. Each step is one logical change with
its own test. No architecture changes belong in this plan — those live in
`Plan_Headless_Combat_Core.md`, `Plan_Team_And_Roster_Abstraction.md`, and
`Plan_Data_Driven_Status_Effects.md`.

## Status

Complete. All eight steps implemented with tests; the full GUT suite is green. Step 7
was resolved as "Burning stacks by design": the misleading `OverwritableDebuff` guard was
removed and `Concept_Document.md` 3.2.3.2 now states Burning stacks up to the status cap.
Step 8 (Burning combat text + damage attribution) was added after review. Findings are
recorded as fixed in `Technical_Design_Document.md` section 15.6.

## Findings being fixed

Recorded in `Technical_Design_Document.md` section 15.6.

## Steps

### 1. Stop enemies sharing Skill resources across instances and battles
- **What:** `Character.InstantiateNew` assigns `_skills = p_preset._skills` by reference
  (`Scripts/Character/character.gd:13`), and `Battle.Init` instantiates enemies straight
  from the preset without duplication (`Scripts/Battle/battle.gd:102`). Two enemies of
  the same variant share `cooldown_left`, and because the mutated `Skill` lives on the
  cached `.tres`, enemy cooldowns leak into later battles in the same session
  (`EndBattle` resets only player cooldowns). Fix by deep-duplicating each skill inside
  `InstantiateNew` so every `Character` owns its skills regardless of caller.
- **Files:** `Scripts/Character/character.gd`; verify `Scripts/Character/character_collection.gd`
  paths still behave (they duplicate the preset first — double duplication is harmless).
- **Watch for:** player characters are currently protected by the collection-level
  duplicate; do not remove that without checking serialization round-trips
  (`test_collection_serialization.gd`).
- **Test:** new test — instantiate two characters from one preset, put a skill on
  cooldown on one, assert the other and the preset are untouched.

### 2. Make boss scaling actually apply
- **What:** `Battle.Init` calls `LevelSystem.SetOpponentLevel(character, difficulty)`
  unconditionally (`Scripts/Battle/battle.gd:104`) before the boss/non-boss branch.
  `SetOpponentLevel` early-returns when the level is already reached, so the boss call
  with the 1.5x multiplier is dead code. Remove the unconditional first call and keep
  the branch.
- **Files:** `Scripts/Battle/battle.gd`.
- **Watch for:** bosses become genuinely stronger — sanity-check the statue and troll
  boss encounters afterwards for difficulty feel.
- **Test:** new test — `SetOpponentLevel` with `p_boss = true` on a fresh character
  yields higher attribute totals than `p_boss = false` at the same level; plus a
  regression test that the boss path in battle setup passes `true` exactly once
  (extract the levelling decision into a testable helper if needed).

### 3. Fix the critical-hit off-by-one
- **What:** `Skills.DamageDealt` rolls `randi_range(0, 100) <= CritChance`
  (`Scripts/Battle/Skills.gd:332`), so 0% crit chance still crits on a rolled 0.
  Change to `randi_range(1, 100)`.
- **Files:** `Scripts/Battle/Skills.gd`.
- **Test:** with `CritChance = 0`, no crit over many rolls; with `CritChance = 100`,
  always crits. (Deterministic testing becomes easier after the injectable random
  number generator lands in `Plan_Headless_Combat_Core.md`; a statistical test is
  acceptable meanwhile.)

### 4. Exclude dead and missing characters from targeting
- **What:** `Skills.FindSkillTargets` (`Scripts/Battle/Skills.gd:66-123`) hardcodes
  `randi() % 3` for random targets and appends whole ID arrays with no alive check.
  Random Enemy can waste a turn damaging a corpse; All Enemies re-damages the dead.
  Pass the characters dictionary into `FindSkillTargets` and filter candidates on
  existence and `_current_health > 0` before selection.
- **Files:** `Scripts/Battle/Skills.gd`, call sites in `Scripts/Battle/battle.gd`,
  existing tests `test_skills.gd` and `test_enemy_turn_targeting.gd`.
- **Watch for:** `Random_One` and `All` targets both teams; keep self-targeting rules
  unchanged. The `!_characters.has(target_ID)` guard in `ResolveSkill` becomes
  redundant but can stay as a backstop.
- **Test:** extend `test_skills.gd` — with one enemy dead, Random Enemy never returns
  it and All Enemies excludes it.

### 5. Normalize turn-bar speed from one attribute source
- **What:** `TurnBar.Init` compares base speed (`_attributes[Speed]`) but stores geared
  speed (`GetBattleAttribute(Speed)`) (`Scripts/UI/Battle_UI/turn_bar.gd:20-26`). A
  character whose geared speed is highest but base speed is not produces a normalized
  speed above 1.0. Use `GetBattleAttribute` in both the comparison and the assignment.
- **Files:** `Scripts/UI/Battle_UI/turn_bar.gd`.
- **Test:** pure-logic test on the normalization math with a geared character
  (extract the max/normalize step into a static helper if the node dependency blocks
  testing).

### 6. Small defects, one commit each or one grouped commit
- `Scripts/Battle/battle.gd:250` — `clampi(...)` result discarded; assign it or delete
  the line.
- `Scripts/Battle/battle.gd:415` — post-battle heal uses base `_attributes[Health]`;
  use `GetBattleAttribute(Types.Attribute.Health)` so geared characters report full
  health outside battle.
- `Scripts/Character/Level_System.gd` — `LevelUpCriteriaMet` mutates `_experience`
  inside a predicate: split into a pure check plus an explicit consume step in
  `AddExperience`; fix the `p_experiene_gained` typo; `round(int(...))` at line 93
  rounds after truncation — reorder to `int(round(...))`.
- **Test:** `test_level_system.gd` already covers the experience loop — extend it to
  assert experience is only consumed on an actual level-up.

### 7. Design decision needed: Lava zone Burning stacking
- **What:** the Lava zone handler (`Scripts/Battle/Skills.gd:31-41`) never checks
  whether the target already has Burning, so it appends a fresh copy every trigger up
  to the status cap. The surrounding `OverwritableDebuff` check reads as if it meant to
  prevent that. Confirm intent against `Concept_Document.md` (Burning is defined as a
  4% max-health tick, nothing about stacking) before changing behavior; then either
  add the duplicate check or document stacking as intended in the concept document.
- **Files:** `Scripts/Battle/Skills.gd`, possibly `Concept_Document.md`.
- **Resolved:** Burning stacks by design; the misleading `OverwritableDebuff` guard was
  removed and `Concept_Document.md` 3.2.3.2 updated to state the stacking rule.

### 8. Burning damage feedback and attribution
- **What:** a Burning tick changed the target's health with no combat text and never
  contributed to the post-battle damage total for the character who applied it.
- **Fix:** `StatusEffects.Effect` gained a `source_ID`, set by `CastDebuff` (skill-applied
  Burning) and the Lava-zone handler (the zone owner). `TriggerExistingCasterDebuffs` now
  spawns combat text over the burning character and returns the Burning damage keyed by
  source; `Battle.ResolveSkill` attributes each player source's share to
  `character_dmg_<id>`.
- **Files:** `Scripts/Battle/status_effects.gd`, `Scripts/Battle/Skills.gd`,
  `Scripts/Battle/battle.gd`.
- **Test:** `Tests/unit/test_burning_damage.gd` — combat text is spawned, health drops by
  the 4% tick, damage is attributed to the source, and stacks from the same and different
  sources are summed/kept separate.

## Test run

```
/home/jonas/Documents/Godot_v4.6.2-stable_linux.x86_64 \
  --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd -gexit
```

All existing tests must stay green; each step adds its own coverage.
