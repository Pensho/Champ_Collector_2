# Plan: Gear Sub-Types

Every standard item belongs to a **sub-type** within its slot (for example Shard Pike in the
Weapon slot). A sub-type grants one **implicit**; rarity steps and upgrades keep rolling from the
slot's attribute pool. Implicits grow more complex as the player advances through the Acts, so
the early game asks the player to read only simple ones. Each Act has a **gear pool** of the
sub-types obtainable in it, and each of its Adventures drops from a subset of that pool, so the
player farms a sub-type by choosing the Adventure that carries it.

Relics have no sub-type and no implicit, and stay general drops.

Starting numbers, all placeholders for tuning: every Act 1 implicit is +6 at Common, scaled by a
shared rarity multiplier (1.00 / 1.33 / 1.67 / 2.00 / 2.33), and fixed when the item is made.

## Steps

### 1. Sub-type design — done
**Implicit ladder.** Act 1 sub-types carry a flat attribute line [Channel 1]. An implicit's
attribute need not be in its slot's pool. Later Acts' implicits may be any kind of effect, and
are designed when those Acts' Adventures are built.

**Act 1 catalog.** Each Adventure's pool holds one sub-type per slot, and the Act's pool is the
union of both.

| Sub-type | Slot | Implicit | Adventure | Existing preset |
|---|---|---|---|---|
| Briar Staff | Weapon | +Attack | Jungle | |
| Shard Pike | Weapon | +Mysticism | Magic Ruins | Spear |
| Seed Lantern | Off-Hand | +Accuracy | Jungle | |
| Pew Shield | Off-Hand | +Defence | Magic Ruins | Shield |
| Scaled Greaves | Boots | +Health | Jungle | Red Boots |
| Hueless Slippers | Boots | +Resistance | Magic Ruins | |

### 2. Concept Document — done
`Concept_Document.md` 3.3.1 holds sub-types, the implicit ladder as a per-Act rule, and the Act
and Adventure gear pools, plus an "Implicit" row in the Standard/Relic table. 3.6.4 draws
Standard shop stock from the current Act's pool. 5.4's Act and Adventure tree has "Gear pool"
leaves, which is where a later Act's sub-types get designed. This plan is not kept for later
Acts.

### 3. Sub-type resource and data — done
- New `ItemSubType` resource (`Scripts/Gear/item_sub_type.gd`): `_name`, `_slot`,
  `_implicit: ItemImplicit`. `ItemImplicit` is the base for every kind of implicit, supplying
  `AttributeBonus()` and `Text()` by rarity; Act 1 uses `AttributeImplicit`.
- `_sub_type: ItemSubType` on `EquipmentPreset`, set on every standard preset and left null on
  Relics. Each standard preset is one sub-type, with its own texture.
- `GameBalance.ITEM_IMPLICIT_RARITY_MULTIPLIER` scales any implicit's Common magnitude by rarity;
  `AttributeImplicit._base_value` is that magnitude, set per sub-type.
- The step 1 catalog as data: sub-types in `Data/Item_Sub_Types/`, presets in
  `Data/Item_Presets/`. The existing presets are renamed to their sub-type.
- `GameBalance.ITEM_TYPE_ATTRIBUTES` stays the pool every item rolls from.
- Register the new presets in `EquipmentPresetRegistry.PRESETS`.
- Invariant test: every preset in `PRESETS` has a sub-type whose `_slot` matches its own, and no
  preset in `RELIC_PRESETS` has one.

### 4. Implicit — done
- `Equipment.GetImplicitBonus(p_attribute) -> int` asks the sub-type's implicit for its bonus at
  the item's rarity, and returns 0 for a Relic. The value is derived, so it is never stored in
  `_attributes` or saved.
- `Character.GetEquipmentBonus()` adds the implicit.
- Saves need no format change, since the sub-type resolves through `preset_path`.
- Tests (`test_equipment.gd`): implicit by rarity and unchanged by upgrades; a Relic has no implicit;
  `GetEquipmentBonus` includes the implicit; a save round trip keeps sub-type and implicit.

### 5. Gear pools, loot and shop — done
- `LootTable._gear_loot: EquipmentPreset` becomes `_gear_pool: Array[EquipmentPreset]`, and
  `DropResult._equipment` becomes an array.
- `LootManager.DistributeRewards`: a drop picks a random preset from `_gear_pool`. A Relic roll
  then picks a Relic by that preset's slot, as it does today. Equipment drops as primary and as
  secondary loot. Adventures drop gear: `Adventure_Combat_Loot` (Experience_Quest plus a gear
  weight) is both Adventures' combat table, and the boss table guarantees one gear drop.
- `ActData.gear_pool` and `AdventureData.gear_pool`, both `Array[EquipmentPreset]`, authored
  per the step 1 catalog.
- `AdventureGenerator._PopulateNodeContexts` gives every battle, hint and escalate node a loot
  table carrying the Adventure's pool. Combat and boss loot tables are shared resources across
  nodes and Adventures, so the pool goes on a copy.
- The Statue loot tables carry a one-entry pool of their current preset.
- `ShopHandler.RollStock` takes a pool and draws Standard stock from it; the hub passes its
  Act's pool (`main_instance.HUB_ACT`). Relic stock draws from all Relics.
- Tests: a Standard drop comes from the pool; a Relic drop's slot matches a pool preset's slot
  (`test_loot_manager.gd`); every generated battle, hint and escalate node carries the
  Adventure's pool and the shared loot table is left unchanged (`test_adventure_generator.gd`);
  Standard shop stock comes only from the given pool. Invariant tests: every Act's and every
  Adventure's pool covers Weapon, Off-Hand and Boots; every Adventure's pool is a subset of its
  Act's pool; every pool entry is registered in `PRESETS`.

### 6. UI and debug tools — done
- `Equipment.DescriptionText` shows the sub-type name and puts the implicit line above the
  rolled attributes, styled apart from them. Update its callers, and add the implicit to the
  item comparison in `inspect_collection_menu.gd`.
- The Adventure selection screen and the pre-battle drop preview show the gear pool's sub-type
  icons, so the player can see what an Adventure farms. `pre_battle_menu._IconForEntry` reads
  the pool in place of `_gear_loot`.
- Item construction page and `DebugActions`: choose a sub-type for a standard item, not a slot.
  A constructed item takes its texture from the sub-type's preset, replacing
  `DebugCatalog.GetItemTextureForSlot`.

### 7. Calibration — skipped
A Legendary implicit moves the gear ceiling from 3.1x to about 3.2x, so the calibration code is
unchanged. `Concept_Document.md` 3.3.1 states the new figure.

### 8. Art
Icons for every step 1 sub-type, following the art style guide. Each preset uses a placeholder
texture (the existing Spear, Shield and Red Boots icons where they apply) until its icon exists.

## Watch for

- The implicit stays a computed value. Storing it in `_attributes` would let upgrades roll onto
  it and would double-count it across save and load.
- A sub-type's implicit is data on its resource. Code never branches on a sub-type's name.
- A later Act's implicit kind is a new `ItemImplicit` subclass; `Equipment` and `ItemText` stay
  unaware of implicit kinds.
- An Adventure in progress keeps its node loot tables across save and load; confirm the pool on
  each copy survives that round trip.
- Run `gdlint Scripts/` after steps 3, 4 and 5.
- On completion: document the `ItemSubType` data model and gear pools in
  `Technical_Design_Document.md`, then follow `README.md`'s retention rule.
