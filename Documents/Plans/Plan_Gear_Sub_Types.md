# Plan: Gear Sub-Types

Every standard item belongs to a **sub-type** within its slot (for example Axe or Staff in the
Weapon slot). A sub-type sets which attributes the item's rarity steps and upgrades roll from, and
grants one **implicit**. Implicits grow more complex as the player advances through the Acts, so
the early game asks the player to read only simple ones. Each Act has a **gear pool** of the
sub-types obtainable in it, and each of its Adventures drops from a subset of that pool, so the
player farms a sub-type by choosing the Adventure that carries it.

Relics have no sub-type and no implicit. They keep rolling from their slot's attribute pool and
stay general drops.

Starting numbers, all placeholders for tuning: a flat implicit is +4 at item level 0, +1 per
upgrade level (+14 at level 10).

## Steps

### 1. Sub-type design
Brainstorm the sub-types (`/brainstorm`) and record the result in this plan as two parts.

**Implicit ladder** — the kind of implicit each Act's sub-types introduce, rising in complexity.
Act 1 sub-types carry a flat attribute line. Each later rung adds one kind of complexity (for
example a conditional attribute line, or an effect such as Axe lowering a basic skill's
Defense_Ignore_Factor). Tag each rung's channel in section 1.1.3's vocabulary.

**Act 1 catalog** — one row per sub-type: name, slot, attribute pool, implicit, and the Adventure
pools that carry it. The catalog:
- covers Weapon, Off-Hand and Boots across the Act's pool;
- gives the existing Spear, Shield and Boots presets a sub-type;
- gives Jungle and Magic Ruins pools that differ, so each Adventure has something only it
  drops. Decide here whether each Adventure's pool covers all three slots.

Later Acts' sub-types are designed against the ladder when those Acts' Adventures are built.

### 2. Concept Document
In `Concept_Document.md` 3.3.1, add: what a sub-type sets (attribute pool, implicit); an
"Implicit" row in the Standard/Relic table reading "one, from its sub-type" and "none"; the
implicit ladder, updating the gear verdict to match any rung outside [Channel 1]; and the Act and
Adventure gear pools, including that every Act's pool covers all three slots and that the shop
sells only the current Act's sub-types. The sub-type list and the pools live in data, not in the
document. Add "Gear pool" leaves to the Act and Adventure tree in 5.4.

### 3. Sub-type resource and data
- New `ItemSubType` resource (`Scripts/Gear/item_sub_type.gd`): `_name`, `_slot`,
  `_attribute_pool: Array[Types.Attribute]`, `_implicit_attribute: Types.Attribute`.
- `_sub_type: ItemSubType` on `EquipmentPreset`, set on every standard preset and left null on
  Relics. Each standard preset is one sub-type, with its own texture.
- Implicit constants in `GameBalance`: `ITEM_IMPLICIT_BASE = 4`, `ITEM_IMPLICIT_PER_LEVEL = 1`.
- The step 1 catalog as data: sub-types in `Data/Item_Sub_Types/`, presets in
  `Data/Item_Presets/`.
- `GameBalance.ITEM_TYPE_ATTRIBUTES` stays as the slot pool Relics roll from.
- Register the new presets in `EquipmentPresetRegistry.PRESETS`.

### 4. Rolls and implicit
- `EquipmentPreset.Setup()` and the fallback in `Equipment.Upgrade()` roll from
  `_sub_type._attribute_pool` for a standard item and from `ITEM_TYPE_ATTRIBUTES` for a Relic.
- `Equipment.GetImplicitBonus(p_attribute) -> int` computes base + per-level × `_level`, and 0
  for a Relic. The value is derived from the sub-type and level, so it is never stored in
  `_attributes` or saved.
- `Character.GetEquipmentBonus()` adds the implicit.
- Saves need no format change, since the sub-type resolves through `preset_path`.
- Tests (`test_equipment.gd`): Setup and Upgrade roll only from the sub-type pool; implicit at
  levels 0 and 10; a Relic has no implicit and still rolls halved from its slot pool;
  `GetEquipmentBonus` includes the implicit; a save round trip keeps sub-type and implicit.
- Invariant test: every preset in `PRESETS` has a sub-type whose `_slot` matches its own, and no
  preset in `RELIC_PRESETS` has one.

### 5. Gear pools, loot and shop
- `LootTable._gear_loot: EquipmentPreset` becomes `_gear_pool: Array[EquipmentPreset]`.
- `LootManager.DistributeRewards`: a drop picks a random preset from `_gear_pool`. A Relic roll
  then picks a Relic by that preset's slot, as it does today.
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
  Standard shop stock comes only from the given pool. Invariant tests: every Act's pool covers
  Weapon, Off-Hand and Boots; every Adventure's pool is a subset of its Act's pool; every pool
  entry is registered in `PRESETS`.

### 6. UI and debug tools
- `Equipment.DescriptionText` shows the sub-type name and puts the implicit line above the
  rolled attributes, styled apart from them. Update its callers.
- The Adventure selection screen and the pre-battle drop preview show the gear pool's sub-type
  icons, so the player can see what an Adventure farms. `pre_battle_menu._IconForEntry` reads
  the pool in place of `_gear_loot`.
- Item construction page and `DebugActions`: choose a sub-type for a standard item, not a slot.
  `DebugCatalog.GetItemTextureForSlot` becomes per sub-type.

### 7. Calibration
`BlowoutCalibration._ReportGearCeiling()` reads the union of each slot's sub-type pools and adds
the level-10 implicit when the implicit is the scaled attribute. It also reports the gap the
implicit opens between a standard item and a Relic at the same rarity and level, as input for a
Relic power bump. Re-run it, then update the gear-ceiling paragraph in `Concept_Document.md`
3.3.1 with the new ratio and with which slots can now roll Mysticism.

### 8. Art
Icons for every step 1 sub-type that lacks one, following the art style guide. Each preset uses a
placeholder texture until its icon exists.

## Watch for

- The implicit stays a computed value. Storing it in `_attributes` would let upgrades roll onto
  it and would double-count it across save and load.
- A sub-type's pool and implicit are data on its resource. Code never branches on a sub-type's
  name.
- Keep the implicit behind `GetImplicitBonus`, so the later rungs of the implicit ladder change
  one place.
- An Adventure in progress keeps its node loot tables across save and load; confirm the pool on
  each copy survives that round trip.
- Run `gdlint Scripts/` after steps 3, 4 and 5.
- On completion: document the `ItemSubType` data model and gear pools in
  `Technical_Design_Document.md`, then follow `README.md`'s retention rule.
