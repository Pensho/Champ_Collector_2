# Plan: Gear Sub-Types

Every item belongs to a **sub-type** within its slot (Axe, Knife, Staff and so on in the Weapon
slot). A sub-type sets which attributes the item's rarity steps and upgrades roll from, and grants
one **implicit** attribute line. Standard gear stays [Channel 1] (`Concept_Document.md` 3.3.1).

Starting numbers, all placeholders for tuning: implicit +4 at item level 0, +1 per upgrade level
(+14 at level 10). Relics carry the full implicit; only their rolled attributes stay halved.

## Steps

### 1. Concept Document
Add sub-types to `Concept_Document.md` 3.3.1: what a sub-type sets (attribute pool, implicit),
and an "Implicit" row in the Standard/Relic table reading "full" in both columns. The sub-type
list itself lives in data, not in the document.

### 2. Sub-type resource and data
- New `ItemSubType` resource (`Scripts/Gear/item_sub_type.gd`): `_name`, `_slot`,
  `_attribute_pool: Array[Types.Attribute]`, `_implicit_attribute: Types.Attribute`.
- `_sub_type: ItemSubType` on `EquipmentPreset`. Each standard preset is one sub-type, with
  its own texture.
- Implicit constants in `GameBalance`: `ITEM_IMPLICIT_BASE = 4`, `ITEM_IMPLICIT_PER_LEVEL = 1`.
- Weapon sub-types (data in `Data/Item_Sub_Types/`, presets in `Data/Item_Presets/`):

  | Sub-type | Attribute pool | Implicit |
  |---|---|---|
  | Spear (existing preset) | Attack, Accuracy, CritChance | Accuracy |
  | Axe | Attack, CritDamage | Attack |
  | Knife | CritChance, Accuracy, Speed | CritChance |
  | Staff | Mysticism, Knowledge, Accuracy | Mysticism |
  | Drakeling | Mysticism, Attack, CritDamage | CritDamage |

- Off-Hand and Boots: step 4 sets their sub-type list. Until then, Shield and Boots are one
  sub-type each, with the slot's current pool and implicits Defence and Speed.
- Remove `GameBalance.ITEM_TYPE_ATTRIBUTES`. Sub-type pools replace it.
- Register the new presets in `EquipmentPresetRegistry.PRESETS`.

### 3. Rolls and implicit
- `EquipmentPreset.Setup()` and the fallback in `Equipment.Upgrade()` roll from
  `_sub_type._attribute_pool`.
- `Equipment.GetImplicitBonus(p_attribute) -> int` computes base + per-level × `_level`. The
  value is derived from the sub-type and level, so it is never stored in `_attributes` or saved.
- `Character.GetEquipmentBonus()` adds the implicit.
- Saves need no format change, since the sub-type resolves through `preset_path`.
- Tests (`test_equipment.gd`): Setup and Upgrade roll only from the sub-type pool; implicit at
  levels 0 and 10; a Relic gets the full implicit while its rolls stay halved;
  `GetEquipmentBonus` includes the implicit; a save round trip keeps sub-type and implicit.
- Invariant test: every preset in both registries has a sub-type whose `_slot` matches its own.

### 4. Relic sub-types
Give every preset in `EquipmentPresetRegistry.RELIC_PRESETS` a sub-type that matches its
appearance in `Relic_Design.md`. The Off-Hand and Boots sub-types this needs (Lantern of the
Standing Ward implies a Lantern, the Sealed Docket a Tome) become the off-hand and boots list,
each with a standard preset. Add a sub-type field to each Relic catalog entry in
`Relic_Design.md`.

### 5. Loot and shop
- `EquipmentPresetRegistry.GetRandomKeyForSlot(p_slot)`, mirroring
  `GetRandomRelicKeyForSlot`.
- `LootManager.DistributeRewards`: a Standard drop picks a random standard preset for the slot
  of the loot table's `_gear_loot`, just as a Relic drop already picks by slot.
- The shop already draws from all of `PRESETS`, so it picks up the new sub-types with no
  change.
- Tests (`test_loot_manager.gd`): a Standard drop's preset matches the table's slot.

### 6. Debug tools and tooltip
- `Equipment.DescriptionText` shows the sub-type name and puts the implicit line above the
  rolled attributes, styled apart from them. Update its callers.
- Item construction page and `DebugActions`: choose a sub-type, not a slot.
  `DebugCatalog.GetItemTextureForSlot` becomes per sub-type.

### 7. Calibration
`BlowoutCalibration._ReportGearCeiling()` reads the union of each slot's sub-type pools and adds
the level-10 implicit when the implicit is the scaled attribute. Re-run it, then update the
gear-ceiling paragraph in `Concept_Document.md` 3.3.1 with the new ratio and with which slots
can now roll Mysticism.

### 8. Art
Icons for Axe, Knife, Staff, Drakeling and the step 4 sub-types, following the art style guide.
Each preset uses a placeholder texture until its icon exists.

## Watch for

- The implicit stays a computed value. Storing it in `_attributes` would let upgrades roll onto
  it and would double-count it across save and load.
- A sub-type's pool and implicit are data on its resource. Code never branches on a sub-type's
  name.
- Implicits may later become small effects (for example, Axe lowering a basic skill's
  Defense_Ignore_Factor). Keep the implicit behind `GetImplicitBonus` so that change stays in one
  place.
- Run `gdlint Scripts/` after steps 2, 3 and 5.
- On completion: document the `ItemSubType` data model in `Technical_Design_Document.md`, then
  follow `README.md`'s retention rule.
