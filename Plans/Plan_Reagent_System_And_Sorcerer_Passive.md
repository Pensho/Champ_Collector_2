# Plan: Reagent System and Sorcerer Passive

Introduce reagents — universal consumable items looted from encounters, stored in a
persistent inventory, and brought into battle as a limited loadout — and implement
the Sorcerer's Arcane Instability passive that feeds on them. This realizes the
reagent note in `Concept_Document.md` 3.2.2 (magic requiring "powerful reagents",
tied to the God of Magic's ruins) and the Sorcerer passive specified in
`Concept_Document.md` 3.1.3, whose dependency note points at this plan.

## Status

Not started. Independent of the other plans. Touches `battle.gd` and `Skills.gd`
areas that `Plan_Headless_Combat_Core.md` will later refactor — whichever of the two
lands second adapts to the other (if the combat core extraction lands first, the
reagent resolution and the `Reagent_Consumed` hook go through `BattleResolver`
instead of `battle.gd`/`Skills.gd` directly).

## Design (confirmed decisions)

- Reagents are **universal** — any champion can consume them; no role restriction.
  The Sorcerer merely excels at exploiting them via its passive.
- The player owns a **persistent reagent inventory** outside combat, filled by loot
  drops. Consuming a reagent **permanently deletes it** from the inventory.
- Before battle the player picks a **loadout of up to 3** reagents from the
  inventory. Each brought reagent is usable **exactly once per battle**, by any
  champion on their turn. Unused brought reagents return to the inventory.
- Consuming a reagent is a **free action**: it does not consume the champion's turn.
- Effects are **not primarily buffs**: the starter set spans a heal, a buff, and a
  very rare boss-only cooldown reduction.
- Sorcerer passive (Arcane Instability, `Concept_Document.md` 3.1.3): +1 Instability
  stack per non-basic skill cast (max 5, +4/6/8/10% Mysticism per stack by rarity);
  consuming a reagent grants +2 stacks and amplifies the reagent by 20/30/40/50%;
  at max stacks the next skill also releases a Surge (magical damage to all
  characters, allies included, scaling with Mysticism), then stacks reset. Stacks
  do not persist between combats.

## Target shape

- **`ReagentData`** (`Scripts/Battle/reagent_data.gd`, `class_name ReagentData
  extends Resource`): `@export` display name, description, icon, rarity, and an
  effect definition built on a reagent effect kind enum — `Heal` (percent of max
  Health), `Apply_Buff` (existing `Types.Buff_Type` + duration), `Reduce_Cooldowns`
  (flat turns) — extensible for later kinds (enemy debuffs, turn bar bumps, …).
  One `.tres` per reagent under `Data/Reagents/`, loaded through a preload-const
  registry script (the `main_instance.gd` character-preset precedent — no
  `DirAccess`, safe for Android export).
- **Starter catalog** (lore names from `World_Building.md` materials; final numbers
  recorded in `Concept_Document.md` on completion):
  - Soot-Glass Shard (common drop) — heal the user for X% of max Health.
  - Gold-Thread Sliver (uncommon drop) — grant the user Fortify.
  - Malfunction Quartz (very rare, boss-only drop) — reduce the user's skill
    cooldowns by 1.
- **Inventory**: a reagent inventory holding counts per reagent type, saveable via
  the existing `"saveable"` group pattern with `Serialize()`/`Deserialize()`
  (follow `Scripts/Worldview/resource_handler.gd` and `save_manager.gd`; either new
  fields on `ResourceHandler` or a sibling collection like
  `Scripts/Gear/item_collection.gd`).
- **Acquisition**: reagents drop through the reward structure
  (`Concept_Document.md` 3.8) / biome loot data, rarity-gated (boss encounters only
  for the rare kind).
- **Loadout**: `Scripts/UI/Battle_UI/pre_battle_menu.gd` gains a
  pick-up-to-3-reagents step; the selection rides into battle on a new field on
  `Scripts/Worldview/Context_Container.gd` and is consumed by `battle.gd Init()`.
  `Scripts/Debug/debug_actions.gd` assembles battle contexts the same way and must
  stay in parity.
- **Combat consumption**: a reagent tray in `Scripts/UI/Battle_UI/battle_ui.gd`
  alongside the three skill buttons, enabled on player turns. Resolution lives in
  `battle.gd` parallel to `ResolveSkill` but without ending the turn: apply the
  reagent's effect to the acting champion, mark the loadout entry spent, delete the
  reagent from the inventory.
- **Event hook**: new `Reagent_Consumed` value in `Combat_Event`
  (`Scripts/common_enums.gd`) with a matching virtual on `CharacterTrait`
  (`Scripts/Character/CharacterTraits/character_trait.gd`), fired from `battle.gd`
  with the reagent as argument and returning an amplification multiplier (new
  result type under `TraitHookResults/`, or a plain float).
- **`SorcererTrait`**
  (`Scripts/Character/CharacterTraits/CharacterSpecificTraits/sorcerer_trait.gd`):
  modeled on `lancer_trait.gd` (rarity-keyed `const Dictionary[Types.Rarity, float]`
  for per-stack Mysticism and reagent amplification, stack counter, reset in
  `StartOfBattle`) and `Tidal_Corsair_Trait.gd` (stack display through
  `CharacterRepresentation.SetTraitElement`). Hooks `Skill_Cast` (+1 stack on
  non-basic skills; Surge at max stacks, then reset) and `Reagent_Consumed`
  (+2 stacks, return amplification). Authored as `Sorcerer_Trait.tres` in
  `Data/Character_Traits/` and assigned to Sorcerer presets.

## Steps

1. **Reagent data layer.** Create `ReagentData` with the effect kind enum, the
   preload-const registry, and the three starter `.tres` files under
   `Data/Reagents/`.
2. **Inventory and acquisition.** Add the saveable reagent inventory
   (add/consume/delete, `Serialize`/`Deserialize`) and hook reagent drops into the
   loot/reward flow with rarity gating.
3. **Combat event plumbing.** Add `Reagent_Consumed` to `Combat_Event`, the
   `CharacterTrait` virtual, and its hook result type.
4. **Pre-battle loadout.** Extend `pre_battle_menu.gd` with the
   pick-up-to-3-from-inventory step, add the `ContextContainer` field, and update
   `debug_actions.gd` for parity.
5. **In-battle consumption.** Add the reagent tray to `battle_ui.gd` and the
   free-action resolution in `battle.gd`. Amplification semantics: applies to
   numeric magnitudes (heal percent, buff potency or duration); discrete effects
   such as cooldown reduction are unaffected — state this in reagent descriptions.
6. **Sorcerer passive.** Implement `SorcererTrait` with stack visualization and the
   Surge (per-target magical damage formula; no critical hits; targets mitigate via
   Resistance/Defence as normal, through the shared damage path). Author and assign
   `Sorcerer_Trait.tres`.
7. **Tests** (GUT, `Tests/unit/`): registry data-integrity test covering every
   reagent `.tres` (same pattern as `test_character_preset_skill_invariant.gd`);
   inventory add/consume/serialize round-trip; consumption applies the effect once
   and deletes the reagent; Sorcerer stack accrual on non-basic skills only;
   +2 stacks on reagent consumption; Surge at max stacks then reset; rarity-scaled
   values; stacks reset at battle start.

## Watch for

- Basic versus non-basic skill detection: the basic skill is the no-cooldown skill
  (`Concept_Document.md` 3.2.4) — the trait needs a reliable predicate, not an
  index assumption.
- The Surge hits allies and must run through the normal damage handling
  (`Damage_Taken` trait hooks, Jester avoidance, death) — reuse the
  `Skills.DamageDealt` path, do not hand-roll damage.
- Shop purchase of reagents is out of scope; loot drops are the only acquisition
  source here. Note it as a follow-up for the shop design
  (`Concept_Document.md` 3.6.4 already lists consumables).
- Losing a battle: reagents consumed mid-battle stay consumed on defeat
  (consistent with being spent when used); unused loadout entries are returned.
- Naming allowlist: no new acronyms; spell reagent names out in full.

## Documentation

On completion: update `Concept_Document.md` (final reagent numbers and catalog in
the 3.3 Reagents subsection, Surge and amplification semantics in the Sorcerer
passive entry, and remove the passive's interim "until reagents exist" clause) and
add the reagent data model, inventory, and `Reagent_Consumed` hook to
`Technical_Design_Document.md` (§6 data model, §9 trait hook system, §10 save
system).
