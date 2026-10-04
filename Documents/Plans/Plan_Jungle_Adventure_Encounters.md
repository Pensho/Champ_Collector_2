# Plan: Jungle Adventure Encounters

Implements the jungle adventure's opponents for the playtest: adventures that roll
whole battle variants instead of individual characters, the Spotted debuff and the
Lowest Priority Enemy target, the Momentum buff, universal boss phase 2, and the
Ridge Marksmen, Clearing Crew, and Salvage Baron content.

Design sources: `Concept_Document.md` 3.2.1 (enemy target selection), 3.2.3.2
(Spotted, Momentum), 3.2.4 (Lowest Priority Enemy, Cut Purse), 5.1.1.1 (jungle
encounter list), 5.3 (boss phase 2); `Encounter_Design_Document.md` section 1
(Spotting Shot, Aimed Shot, Breaching Charge, Size Up, Cash In, Press the Advantage),
2.1 (Ridge Marksmen, Clearing Crew), 2.3 (Salvage Baron).

## Decisions taken in this plan

- `AdventureData.possible_opponents` and `possible_bosses` are replaced by
  `battle_variants: Dictionary[Context_Battle, int]` (weighted, as before) and
  `boss_battle_variants: Array[Context_Battle]`. Characters are no longer rolled
  per slot.
- A battle node gets a duplicate of the picked variant. The adventure's loot table
  overrides the variant's; the biome's stage scene is used unless the variant sets
  its own.
- Phase 2 is data on `CharacterPreset`: `_phase_two_skills: Array[Skill]` (the full
  phase 2 kit — adding a skill and upgrading one are both expressed by listing the
  phase 2 version) and `_phase_two_trait: CharacterTrait` (null keeps the current
  trait). A preset with phase 2 data is a phased character; the transition fires
  once, when a hit leaves it alive at or below 50% max Health.
- Spotted is a normal resistible debuff; the presets that apply it carry high
  Accuracy. A side holds one Spotted character: a landed application removes Spotted
  from the holder's allies.
- A stolen permanent buff lasts 3 turns on the thief and then expires.

## Steps

### 1. Adventures roll battle variants

- `Scripts/Adventure_Scripts/adventure_data.gd`: replace the two pools with
  `battle_variants` and `boss_battle_variants`.
- `Scripts/Adventure_Scripts/adventure_generator.gd` `_PopulateNodeContexts`: FIGHT
  picks one weighted variant, BOSS picks one boss variant; both `duplicate()` it,
  then set `_loot_table` and (when the variant has none) `_stage_scene`. Generalize
  `_WeightedRandomPick` to the new key type.
- Both adventure `.tres` files: jungle fodder is Sporeback Pack, Ridge Marksmen,
  Clearing Crew; jungle boss is Salvage Baron (wired in step 7). Magic Ruins keeps
  today's opponents as variants (Battle_Militia, Battle_Obsidian_Stallion) until its
  encounters are designed.
- Tests (`test_adventure_generator.gd`): a FIGHT node fields exactly one variant's
  composition; the adventure's loot table wins; mutating a node's context leaves the
  variant resource untouched; empty pools leave nodes without a context.
- Watch for: generation is seeded (`_generation_seed`), so picks must keep using the
  generator's RNG — a regenerated adventure must roll the same variants.

### 2. Targeting priority helper and Lowest Priority Enemy

- Extract the priority value from `Battle.SetTargetingOrder` into a static
  `Skills.TargetingPriority(p_character) -> float` ((Health + Defence) times the
  trait and buff multipliers). `SetTargetingOrder` sorts by it; behavior unchanged.
- Add `Lowest_Priority_Enemy` to `Types.Skill_Target` (`common_enums.gd`), resolved
  in `Skills.FindSkillTargets`, `SkillCastContext.ResolveIndependentGroup`, and
  `targeting_help.gd` as the alive enemy of the caster with the lowest priority
  (ties toward the lower ID, matching `MostInjured`).
- Tests: a new `test_lowest_priority_targeting.gd` — picks the lowest (Health +
  Defence); Spotlight's multiplier moves the pick; dead characters are skipped;
  works as an effect-level target beside a different skill target.
- Watch for: the extraction is the minimum needed for the resolver to read
  priority; it is not a move of `_targeting_order` out of the scene.

### 3. Spotted

- New `Types.Debuff_Type.Spotted`, `Data/Status_Effects/Spotted.tres`, registry
  entry, placeholder icon.
- `StatusEffectResolver`: when Spotted lands, remove it from the target's allies.
- Enemy AI: a static `Skills.EnemyTargetOrder(p_order, p_caster_ID, p_characters,
  p_sides) -> Array[int]` moves an alive Spotted opponent of the caster to the front;
  `Battle.HandleEnemyTurn` iterates it. Positional and AoE targets already ignore the
  chosen ID in `FindSkillTargets`, so they stay unaffected.
- Player side: when an enemy is Spotted (reachable through Mirror Coat), a player's
  single-target skill may only target it — restrict the valid targets in
  `targeting_help.gd` and the battle's target validation.
- Tests: `test_spotted.gd` — the Spotted champion heads the enemy order regardless
  of priority; Left-most/Right-most/All_Enemies skills ignore it; a second landed
  application moves the mark; a resisted application leaves the old holder Spotted;
  expiry restores the normal order. Extend `test_enemy_turn_targeting.gd` for the
  reordered loop.

### 4. Momentum and stolen permanent buffs

- New `Types.Buff_Type.Momentum`, `Data/Status_Effects/Momentum.tres` (permanent,
  15% per stack, 10 stacks), placeholder icon. Add a `MagnitudeKind` for outgoing
  damage percent that contributes to `CombinedDamageModifier` under its own
  "Momentum" bucket, and a `max_stacks_in_place` field on `StatusEffectData`.
- `StatusEffectResolver`: a generic stack-in-place apply, following `ApplySeaLegs`
  (stack count in `trait_riders`, value = per-stack × stacks); `ApplyBuffEffect`
  routes buffs with `max_stacks_in_place > 0` through it. Sea Legs keeps its own
  path.
- `Breaching_Charge.tres`: drop the `Uses_This_Battle` ramp, add an apply-buff
  effect granting the caster Momentum.
- `StealBuff`: a permanent buff arrives with a 3-turn duration and expires normally
  on the recipient (an instance-level flag overriding the data's `permanent`),
  keeping its value and stack count.
- Tests: `test_momentum.gd` — each Breaching Charge adds a stack; damage rises 15%
  per stack; stacks cap at 10; Cut Purse takes the whole stack, the Thief deals the
  bonus, and it expires after 3 turns.

### 5. Boss phase 2

- `CharacterPreset` gains `_phase_two_skills` and `_phase_two_trait`; `Character`
  carries them plus an `_in_phase_two` flag.
- `BattleResolver`: after health loss, if the target is phased, not yet in phase 2,
  alive, and at or below 50% max Health, swap in the phase 2 skills (a skill present
  in both lists keeps its cooldown), swap the trait when set (run its
  `StartOfBattle`), and emit a new `CombatResult.Kind.Phase_Changed`. A hit that
  kills skips the transition; damage is never capped.
- `battle.gd`: on `Phase_Changed`, show combat text and refresh the character's
  skill and trait visuals. Sound, visual effect, stage-wide effect, and the larger
  boss Health bar are presentation hand-offs (see Watch for).
- Tests: `test_boss_phase.gd` — crossing 50% swaps skills and trait exactly once;
  a lethal hit from above 50% kills without a transition; shared skills keep their
  cooldown; non-phased characters never transition.

### 6. Press the Advantage

- New trait hook `OnAllyDamageDealt(p_owner_ID, p_dealer_ID, p_target_ID, p_amount,
  p_resolver)` on `CharacterTrait`, dispatched beside `OnDamageDealt` in the skill
  damage path to every living ally of the dealer, the dealer included (follow
  `Skills.TriggerAllyCriticalHitHook`).
- New trait `press_the_advantage_trait.gd` (`CharacterSpecificTraits/`): when the
  target holds Spotted, grant the owner one Momentum stack through step 4's path.
- Tests: `test_press_the_advantage.gd` — an ally's hit on the Spotted champion adds
  a stack; a hit on anyone else does not; the Baron's own hit counts; damage-over-time
  ticks do not count.

### 7. Content

- Skills (`Data/Character_Skill_Variants/`): Spotting Shot, Size Up (damage plus an
  ApplyDebuff Spotted effect targeting `Lowest_Priority_Enemy`), Cash In (220%);
  Aimed Shot's target becomes `Single_Enemy`.
- Enemies (`Data/Character_Enemy_Variants/`): Ridge Marksman's basic becomes
  Spotting Shot and its Accuracy rises; new Rubble Breaker (from Plains Charger's
  stats), Vinecutter (from Flank Cutter's stats), Salvage Baron (high Defence and
  Accuracy, kit Size Up + Cash In, phase 2 trait Press the Advantage). Placeholder
  textures until art exists.
- Battles (`Data/Battle_Variants/`): Battle_Clearing_Crew, Battle_Salvage_Baron
  (Baron plus two Scavenger Skirmishers); add both to `debug_catalog.gd`.
- Wire the jungle adventure (step 1).
- Tests: extend `test_encounter_assembly.gd` with the new compositions and
  mechanic carriers; add a wiring check that every boss variant in an adventure's
  `boss_battle_variants` has phase 2 data, exempting Magic Ruins' placeholder boss by
  path until it is designed.

### 8. Documentation

- `Technical_Design_Document.md`: §6.1 (`AdventureData`, `CharacterPreset` phase
  fields), §7.1/§7.3 (priority helper, Spotted ordering, phase transition), §9 (the
  ally damage hook), §11 (variant-based generation).
- `Test_Design_Document.md`: the new test files.
- `Concept_Document.md` 5.1.1.1 names Clearing Crew as the third fodder encounter.

## Watch for

- Presentation the user owns: the phase transition's sound, visual effect,
  stage-wide effect, and the boss Health bar enlargement (at least 50%); the
  Spotted and Momentum icons; art for Rubble Breaker, Vinecutter, Salvage Baron.
- `LootTable` carries runtime state (`_drop_result`) and the adventure's
  `combat_rewards` instance is shared across battle nodes; step 1 keeps that
  existing behavior rather than changing loot ownership.
- Ridge Marksmen gets harsher: the Skirmishers' Stab now follows Spotted too. Tune
  numbers in play rather than special-casing the skill.
- The three cataloged bosses (Archivist, Collector, Warden) have no phase 2 yet;
  they are not placed in an adventure, so the wiring check does not cover them.
- Player-facing strings (status descriptions, combat text) follow the localization
  conventions in `Plan_Localization_Text_Preparation.md`.
- Lint `Scripts/` and run the suite after every step.
