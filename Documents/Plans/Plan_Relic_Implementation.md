# Plan: Relic Implementation

The code plan for the Relic item type. `Concept_Document.md` 3.3.1 owns the contract and
`Relic_Design.md` owns the 24-entry catalog; this plan owns the mechanism — splitting item type
from rarity, carrying a Relic's effect, dispatching it alongside the wearer's trait, and
implementing the catalog.

Spawned by `Plan_System_Buildout.md`'s Relic coverage gap.

## Status

Created 2026-08-23. Phases 1 through 3 landed. Phase 4 batches 1 through 4 landed. Phases land in
order, each ending with a green suite and clean `gdlint Scripts/`, and each separately
committable. Phase 4's batches are approved one at a time.

## The blocking defect

`Types.Rarity.Relic = 6` makes Relic a rarity value rather than an item type, so:

- `EquipmentPreset.Setup()` skips the attribute roll for a Relic, which rolls blank instead of
  3.3.1's half.
- `Equipment.GetUpgradeGain()` returns 9 for a Relic, above Legendary's 8.
- A Relic has no rarity, so none of the catalog's five-step ladders can be read.
- `LootManager.RARITY_WEIGHTING` prices Relic as a sixth tier requiring a 28,268 budget. Per 3.3.1
  a drop rolls its rarity from the budget as normal, costs what the standard item of that rarity
  costs, and then takes a separate 5% roll for item type that spends no budget of its own.

## Phases

### 1. Split item type from rarity

Pure refactor; behaviour is unchanged afterwards but for the removal of a rarity tier nothing could
roll usefully.

- `Scripts/common_enums.gd`: add `enum Item_Type { Standard, Relic }`, delete `Rarity.Relic = 6`.
  `RarityName()` indexes `keys()[p_rarity - 1]` and stays correct at five entries.
- `Scripts/Gear/equipment_preset.gd`: `_item_type` export; `Setup()` rolls attributes for both
  types, a Relic gaining half the attribute points per rarity step, rounded up. The
  `if (Types.Rarity.Relic != _rarity)` guard goes away.
- `Scripts/Gear/equipment.gd`: `_item_type` carried through `InstantiateNew()`; `GetUpgradeGain()`
  yields half the attribute points for a Relic, rounded up. Two static helpers — the setup step and
  the upgrade gain, each taking item type — give the halving rule one home, called from both here
  and `Setup()`. These are item rules, so they live on `Equipment`; `game_balance.gd` holds
  constants only.
- `Scripts/Gear/item_collection.gd`: serialize and deserialize `item_type`, defaulting a missing key
  to `Standard`. No live save carries the old rarity-6 Relic value, so no migration is needed.
- `Scripts/Battle/loot_manager.gd`: drop the Relic weighting row, clamp `GetBestRarityForItem()` at
  Legendary, add `RollItemType()` — an independent 5% roll that neither reads nor spends the budget.
  `GetSellValue()` and `GetUpgradeCost()` key off rarity alone and are unchanged.
- `Scripts/UI/menu_item_slot.gd`, `shop_slot.gd`, `hollow_ledger_window.gd`: remove the
  `Rarity.Relic` colour branch. Item type gets its own tell in Phase 2.

Tests: a Relic's setup roll and upgrade gain each grant half the standard item's attribute points at
the same rarity, rounded up; `RollItemType()` is bounded and budget-independent; `item_type`
survives an `ItemCollection` roundtrip and defaults to `Standard` when absent.

### 2. Relic carrier, presets, icons

- `Scripts/Character/character_traits/Relics/relic_effect.gd`: `RelicEffect extends CharacterTrait`,
  inheriting the whole hook vocabulary. It adds only the rarity ladder —
  `_magnitude_by_rarity: Array[float]` of five entries plus `Magnitude()` reading the `_owner_rarity`
  that `CharacterTrait.Init()` already sets. One subclass per Relic, mirroring
  `CharacterSpecificTraits/`.
- `EquipmentPreset` gains `@export var _relic_effect: RelicEffect`;
  `Equipment.InstantiateNew()` deep-duplicates it and calls `Init(_rarity)`.
- `EquipmentPresetRegistry`: a `RELIC_PRESETS` preload map and `GetRandomRelicKey()` beside the
  existing map. `GetRandomKey()` stays standard-only.
- 24 presets under `Data/Item_Presets/Relics/`, each naming its slot, effect script and icon path.
- Drop and shop routing: the `LootType.Equipment` branch of `LootManager.DistributeRewards()` and
  the gear loop of `ShopHandler.RollStock()` each call `RollItemType()` after the rarity roll.
  `RollStock()` swaps in `GetRandomRelicKey()` unrestricted, matching the shop's existing
  unrestricted-slot standard roll. `DistributeRewards()` swaps in `GetRandomRelicKeyForSlot()`
  instead, scoped to `_gear_loot`'s own slot — some loot tables guarantee a slot (e.g.
  `Statue_Weapon_Loot.tres` always Weapon), which the item-type roll must not override. Budget
  spent stays what the standard item of that rarity would have cost either way. The shop applies
  the Relic markup on top of `GetGearPrice()`.
- Icons: a `RELIC_ICON_TABLE` in `Scripts/Debug/generate_placeholder_icons.gd`, 24 rows writing
  `Items/Relics/<Relic_Name>/<Relic_Name>.png` at 64px with the hue grouped by payout group, reusing
  `_write_flat_icon_table()`. The EditorScript is run by hand from the open editor.
- UI: the item tooltip in `inspect_collection_menu.gd` shows the Relic's effect and drawback from
  `_title` and `_body`.

Tests: a Relic preset instantiates its effect at the equipping rarity's ladder step; the drop and
shop paths produce a Relic at the rolled rarity, spending what the standard item would have.

### 3. Trait dispatch through a collection

Every hook site reads `character._trait` directly today, so an equipped Relic has nowhere to fire.

- `Character.HookSources() -> Array[CharacterTrait]` returns `_trait` when non-null followed by each
  equipped item's `_relic_effect`, read off `_held_items` through
  `main.GetInstance()._item_collection` as `GetEquipmentBonus()` already does.
- Aggregate helpers on `Scripts/Battle/skills.gd` beside the existing `ActiveHook()`: sum-style
  (`GetOutgoingDamageBonus`, `GetAttributeDelta`, the duration bonuses), product-style
  (`OnDamageTaken`, `GetIncomingHealMultiplier`, targeting weight) and any-style
  (`DebuffsCannotBeResisted`, `BlocksForwardTurnBarBump`). Call sites move to a helper rather than
  each growing its own loop.
- `ActiveHook()` becomes `ActiveHooks()`, returning every source whose `_execution_steps` holds the
  event; the broadcast loops in `battle_resolver.gd` and `battle.gd` iterate it.
- `Skills.AppliedAttributeAmplification()` sums across the team instead of taking `maxf`, so a
  Relic's amplification adds to a passive's — Quorum Bell's stated rule.
- New hooks on `CharacterTrait`: `GetOutgoingDefenceIgnoreFactor` for Sunderplate Nail, kept
  distinct from `GetBaseDefenceIgnoreRate`, and `GetRewardMultiplier` for Laden Coffer, which also
  needs a fielded-team argument on `DistributeRewards()`.
- Ally-event reach: `OnAllyDeath`, `OnAllyDamageTaken`, `OnAllyTurnBarIncreased` and the
  status-application hooks must reach the wearer's Relic, not only the acting character's trait.
  `StatusEffects.Effect` already carries `source_ID`, so the applier is resolvable; the work is
  routing it into `GetAppliedStatusValue`.
- `turn_bar.gd`'s `is PlanTrait` checks stay on `_trait`: they ask about the champion's own passive.

Tests: a character with a trait and two Relics fires all three on one event; sum and product
aggregation each compose; a Relic's amplification adds to a passive's.

### 4. The 24 effects, in batches

Each batch delivers a per-Relic effect script, its preset, and a test asserting the effect at two
rarity steps and the drawback firing. Batches are ordered by the plumbing they lean on.

1. Wearer-only, existing hooks — The Quiet Mass, The Planted Heel, The Answering Boss, Kiln Brand,
   Sunderplate Nail, The Ossuary Ledger.
2. Applied-status amplification — The Even Tread, The Frayed Hour, The Solvent Mark, Signatory's
   Seal, Quorum Bell, Prism of Small Favors.
3. Echo, zone and reagent — The Long Furrow, Draught-Fed Edge, Threefold Bite, Lantern of the
   Standing Ward.
4. Compositional drawbacks needing team reach — The Closed Wound, The Sealed Docket, The Long
   Second, The Unguarded Glass.
5. Ally events and sustain — Ceded Ground, Mercy Stitch, Understudy's Coat, Laden Coffer.

## Documentation this plan owes

- `Technical_Design_Document.md`: record the item-type split and the trait-collection dispatch,
  deleting the wording they supersede.
- `FeatureIdeas.md`: delete the *Split Relic from the rarity enum* entry once Phase 3 lands.
- `Relic_Design.md`: no change expected. A magnitude that has to move during implementation is a
  design decision — raise it before editing.

## Watch for

* **The worst-case product is 2.97x**, from `Relic_Design.md`'s *Slots and stacking*. Any
  implementation choice that lets a single Role qualify for more damage entries per slot than the
  catalog assigns breaks it.
* **Standard gear's ceiling is 3.1x** (`Concept_Document.md` 3.3.1). Re-run
  `Scripts/Debug/blowout_calibration.gd`'s `_ReportGearCeiling()` after Phase 1: the figure must be
  unchanged, and a Relic loadout must sit below it.
* **Item type must never become a rarity again.** A Relic's rarity is one of the five, and its
  ladder step is read from that.
* A Relic's drawback is keyed to a mechanic, never to a Role or a champion. An implementation that
  tests a teammate's Role instead of the mechanic they supply breaks 1.1.3's composition law.
