# Plan: Reagent Data and Catalog

Step 1 of 4 of the reagent system (`Concept_Document.md` 3.3.3). Defines the reagent
data model and authors the initial catalog as data — no inventory, UI, or combat
behavior yet. Successors: `Plan_Reagent_Inventory_And_Storage_UI.md`,
`Plan_Reagent_Combat_Application.md`, `Plan_Sorcerer_Arcane_Instability.md`.

## Status

Not started. No dependencies on other plans. Purely additive data layer; does not
touch `battle.gd`, `Skills.gd`, or `BattleResolver`.

## Design (from Concept_Document.md 3.3.3)

- Reagents come in four rarities: Uncommon, Rare, Epic, Legendary (a subset of
  `Types.Rarity`). Effects scale with rarity only — never with the consumer's
  attributes.
- Every reagent effect is either **scalar** (has a magnitude that potency modifiers
  can raise) or **binary** (happens or doesn't; potency modifiers ignore it).
- Targeting varies per reagent: self, one ally, one enemy, or one zone section.
- Only the **feasible subset** of the catalog is authored now: reagents whose
  underlying combat mechanics already exist in code. The data structure must still
  support every effect kind in the concept catalog.

### Feasible subset (verified against current code)

| Reagent | Effect kind | Existing mechanic |
| --- | --- | --- |
| Tinctures (one family per primary attribute) | battle-long attribute increase (not a buff) | attribute dictionaries on `Character`; the battle-long modifier mechanism itself lands in the combat plan |
| Restorative Draught | heal one ally, % of max Health | health handling in `Skills.gd` |
| Purging Tonic | remove up to N debuffs from one ally | `_active_debuffs` + erase pattern (`Skills.RemoveBuff` precedent) |
| Thief's Regret | destroy up to N buffs on one enemy | `Skills.RemoveBuff` (`Scripts/Battle/Skills.gd`) |
| Rewinding Grit | tick one *chosen* skill's cooldown down 1/1/1/2 | `cooldown_left` on skills (`battle.gd`); note the target is a skill, not a character — the data model needs a skill-choice target kind (whose skill is undecided in the concept; settle with the user) |
| Second Wind Phial | turn bar resets to 15/20/25/30% after the consumer's turn | turn bar with `BumpCharacter` / `TurnCompleteForCharacter` |
| Zone-Dissolving Salts (Binary) | clear one targeted zone section | `_zones` dictionary in `battle.gd`, zone targeting UI via `_on_turn_bar_zone_selected` |
| Unrefined Residue | random tincture effect | derives from Tinctures |
| Fractured Idol | self-damage 10/14/18/22% max Health + battle-long +10/13/16/20% damage dealt | health handling exists; the damage-dealt bonus mechanism lands in the combat plan |

### Deferred (blocking mechanic not implemented)

Barrier Stone (no Barrier), Deathward Charm (no Deathward buff), Chant Fragment
(no Pagan Curse), Notarized Seal (no Signed Writ debuff), Wayfarer's Draught
(no Wanderlust buff). Author these when their mechanics land; the effect-kind enum
does not need placeholder values for them. The Alchemist brew pool ("Lesser …"
reagents, `Concept_Document.md` 3.3.3) is also deferred — it is authored with the
future Fresh Batch passive plan, not here.

## Target shape

- **`ReagentData`** (`Scripts/Battle/reagent_data.gd`, `class_name ReagentData
  extends Resource`): `@export` display name, description, icon, rarity, lore family
  (plain string), `binary` flag, effect kind enum, target kind enum
  (`Self_Target` / `One_Ally` / `One_Enemy` / `Zone_Section` / `One_Skill` —
  the last for Rewinding Grit), and rarity-scaled
  magnitude fields. Magnitude semantics per effect kind (percent of max Health,
  debuff/buff count, cooldown turns, turn bar percent, …) documented in the script.
- **Effect kind enum** (on `ReagentData` or in `Scripts/common_enums.gd` if other
  scripts need it): `Attribute_Increase`, `Heal`, `Remove_Debuffs`,
  `Destroy_Enemy_Buffs`, `Reduce_Cooldown`, `Turn_Bar_Reset`, `Clear_Zone`,
  `Random_Attribute_Increase`, `Health_Cost_Damage_Bonus`. Extensible for the
  deferred entries later.
- **Registry** (`Scripts/Battle/reagent_registry.gd`): preload-const per `.tres`
  plus a `Dictionary[String, ReagentData]` keyed by a stable identifier string —
  the `Scripts/main_instance.gd` character-preset precedent; no `DirAccess`, safe
  for Android export. The identifier string is what the inventory (next plan) will
  serialize.
- **`.tres` files** under a new `Data/Reagents/` folder: one file per reagent per
  rarity tier for the feasible subset (family entries exist at each of the four
  rarities; check with the user whether one `.tres` per rarity or one `.tres` with
  per-rarity magnitude dictionaries is preferred before mass-authoring — the
  per-rarity-file variant matches how `Data/Character_Traits/` scales values, the
  dictionary variant means fewer files; pick one and stay consistent).
- **Proposed magnitudes**: concept-decided values are Rewinding Grit (1/1/1/2),
  Second Wind Phial (15/20/25/30%), Fractured Idol (10/14/18/22% cost,
  +10/13/16/20% bonus). All other magnitudes are marked "not yet decided" in the
  concept — propose numbers to the user during this plan and record the agreed ones.

## Steps

1. **`ReagentData` resource.** Effect kind enum, target kind enum, rarity, binary
   flag, magnitudes. Type-hint everything; `gdlint Scripts/` clean.
2. **Registry.** `reagent_registry.gd` with preload consts and the keyed dictionary.
3. **Author the feasible subset** under `Data/Reagents/` with agreed magnitudes,
   lore-consistent names and descriptions (check `World_Building.md` for the God of
   Magic / God of Rules / God of Adventure lore families).
4. **Tests** (GUT, `Tests/unit/test_reagent_registry.gd`, pattern:
   `test_character_preset_skill_invariant.gd`): every registry entry loads; rarity
   is within Uncommon–Legendary; binary reagents have no scalar magnitude; scalar
   reagents have a positive magnitude; target kind is valid for the effect kind;
   names and descriptions are non-empty; registry keys are unique.

## Watch for

- Reagent effects must never scale with consumer attributes — keep attribute hooks
  out of the data model entirely.
- Naming allowlist: spell reagent identifiers out in full; no new acronyms.
- Descriptions should state amplification semantics for binary reagents ("not
  affected by potency modifiers") so later UI can surface it — matches
  Concept_Document.md 3.3.3.

## Documentation

On completion: record the agreed magnitudes in the `Concept_Document.md` 3.3.3
catalog, and add the reagent data model and registry to
`Technical_Design_Document.md` §6 (data model).
