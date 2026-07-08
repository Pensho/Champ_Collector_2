# Technical Design Document — champ_collector

## 1. Purpose and scope

This document describes **how champ_collector is built** — the runtime architecture, module
boundaries, data model, and the code paths that drive combat, progression, and persistence. It
is an **as-built** record: it documents the architecture that exists today so that future
architecture changes have a baseline to reason from (per the note in `CLAUDE.md`). Where the
current design has known weaknesses, those are gathered in
[Section 15: Known weaknesses and recommendations](#15-known-weaknesses-and-recommendations)
and clearly marked as forward-looking — the rest of the document states only what the code does.

This document does **not** restate game design or lore. For those, see:

- `Concept_Document.md` — game mechanics, attributes, roles, formulas, economy (the design source of truth)
- `World_Building.md` — narrative, factions, locations, lore
- `Test_Design_Document.md` — testing strategy and per-area coverage

When a mechanic's *intent* matters, this document links to `Concept_Document.md` and describes
only the *implementation* here.

Engine: **Godot 4.6** (`config/features = ["4.6", "Mobile"]`), Mobile renderer, 1280×720
base viewport, `canvas_items` stretch. Language: GDScript with full type hints.

---

## 2. High-level architecture

champ_collector is a single-process Godot game built around three pillars:

1. **Three autoload singletons** that hold all global state and constants
   ([Section 3](#3-autoloads-and-global-state)).
2. **A context-container scene-management pattern**: there is no persistent scene graph of
   gameplay screens — `Main_Instance` swaps the current scene in and out and hands each new
   scene a `ContextContainer` describing what to show ([Section 5](#5-scene-management-the-context-container-pattern)).
3. **Resource-defined content**: champions, skills, gear, loot tables, and adventure templates
   are authored as Godot `Resource` files (`.tres`) and duplicated into runtime instances
   ([Section 6](#6-data-and-resource-model)).

Subsystem map (directory → responsibility):

| Directory | Responsibility |
|---|---|
| `Scripts/` (root) | Autoloads: `main.gd`, `game_balance.gd`, `common_enums.gd`; `Main_Instance` |
| `Scripts/Worldview/` | App state, scene switching, save/load, resource and progress handlers, context objects |
| `Scripts/Character/` | Character instance/preset model, skills, leveling, attribute weights, traits |
| `Scripts/Gear/` | Equipment instance/preset model, item collection |
| `Scripts/Battle/` | Combat orchestration (`battle.gd`), the `Skills` static utility, zones, loot |
| `Scripts/Adventure_Scripts/` | Adventure generation, state, templates, biomes |
| `Scripts/UI/` | All user-interface controllers (battle UI, turn bar, hub, adventure, menus) |

Runtime ownership at a glance:

```
SceneTree
└── main (autoload, main.gd)
    └── Main_Instance (main_instance.gd) ── owns ──┐
        ├── CharacterCollection                    │
        ├── ItemCollection                         │ all added as children,
        ├── ResourceHandler                        │ several joined to the
        ├── ProgressHandler                        │ "saveable" group
        ├── SaveManager                            │
        ├── AdventureStateHandler                  │
        └── _current_scene (the active gameplay screen) ─┘
```

Two other autoloads, `Game_Balance` and `Types`, are stateless: they hold only constants and
enums and are referenced globally.

---

## 3. Autoloads and global state

Declared in `project.godot`:

```
[autoload]
main          = "*res://Scripts/main.gd"
Game_Balance  = "*res://Scripts/game_balance.gd"
Types         = "*res://Scripts/common_enums.gd"
```

### 3.1. `main` → `Main_Instance`

`Scripts/main.gd` is a thin autoload. On `_ready()` it creates a `Main_Instance`, calls
`Init()`, and adds it as a child. Any code reaches global state through:

```gdscript
main.GetInstance()._item_collection   # etc.
```

`Scripts/main_instance.gd` (`class_name Main_Instance`) is the heart of the application. `Init()`:

- Constructs and adds the long-lived state nodes: `CharacterCollection`, `ItemCollection`,
  `ResourceHandler`, `ProgressHandler`, `SaveManager`, `AdventureStateHandler`.
- Adds `AdventureStateHandler` to the `SaveManager.GROUP_SAVEABLE` group.
- Seeds a default roster by duplicating preloaded `CharacterPreset` resources (Lancer, Thief,
  Bar Brawler, Jester, Chronophage, Tidal Corsair, Centaur Lancer, Centaur Archivist, Tactician).
- Builds the initial `ContextContainer` and calls `change_scene()` to load the first scene.

`Main_Instance` also owns scene switching — see [Section 5](#5-scene-management-the-context-container-pattern).

Note: `Scripts/main.gd` also contains editor-only debug input in `_process` (gated on
`OS.has_feature("editor")`): `KEY_0` prints the scene tree, `KEY_8` grants a legendary item.

### 3.2. `Game_Balance` (`class_name GameBalance`)

`Scripts/game_balance.gd` is a constants bag. It defines tuning values referenced throughout the
code, including:

- Combat: `TURN_DURATION_SECONDS = 2.5`, `NUMBER_OF_TURN_BAR_ZONES = 5`,
  `MAX_STATUS_EFFECTS = 8`, `MINIMUM_DMG_PERCENT = 0.1`, `MINIMUM_CRIT_DAMAGE = 125.0`,
  `ATTRIBUTE_HEALTH_MULTIPLIER = 4`.
- Progression: the experience-curve constants (`EXPERIENCE_FACTOR`, `EXPERIENCE_EXPONENT`,
  `EXPERIENCE_CONSTANT_1..3`), `LEVEL_UP_POINTS_TO_DISTRIBUTE = 20`.
- Collections, items, adventure energy costs, and the `ITEM_TYPE_ATTRIBUTES` map describing
  which attributes each gear slot can roll.

It is referenced both as the autoload `Game_Balance.X` and, in a few files, by the class name
`GameBalance.X`. Both resolve to the same constants (see
[Section 15](#15-known-weaknesses-and-recommendations)).

### 3.3. `Types` (`common_enums.gd`)

`Scripts/common_enums.gd` is the single source for all shared enums: `Rarity`, `Faction`,
`Role`, `Slot`, `Skill_Target`, `Attribute`, `Skill_Type`, `Buff_Type`, `Debuff_Type`,
`Combat_Event`. Every system references attributes and targeting through `Types.Attribute.*`,
`Types.Skill_Target.*`, and so on, which keeps enum values consistent across data files and code.

---

## 4. Scene and node architecture

The main scene (`run/main_scene`) is `Scenes/main.tscn` — a near-empty `Node`. Gameplay screens
are not embedded in it; they are instantiated on demand by `Main_Instance._deferred_change_scene()`.

Representative scenes:

| Scene | Root | Purpose |
|---|---|---|
| `Scenes/ui/Battle_UI/battle.tscn` | `Node2D` (`battle.gd`) | 3-versus-3 combat arena |
| `Scenes/ui/Battle_UI/battle_ui.tscn` | `CanvasLayer` (`battle_ui.gd`) | In-combat UI overlay |
| `Scenes/Adventure_Scenes/Adventure.tscn` | `Control` (`adventure_ui.gd`) | Adventure run / node graph |
| `Scenes/Hubs/Reclaimed_City_Scene/Reclaimed_City.tscn` | `Control` (`hub_menu.gd`) | Home base / resources |
| `Scenes/ui/MainMenu.tscn` | `Control` | Top-level navigation |
| `Scenes/Characters/Character.tscn` | `Node2D` (`character.gd`) | Character logic node |
| `Scenes/Characters/Character_Battle_Repr.tscn` | `Node2D` | Visual battle representation |

A key split: **`Character` (logic) is separate from `CharacterRepresentation` (visuals).** The
`battle.gd` orchestrator holds `_characters: Dictionary[int, Character]` for game state and an
exported `_character_repr: Array[CharacterRepresentation]` for the on-screen sprites, life bars,
and status-effect icons. Combat logic mutates the former and pushes results into the latter.

By convention, combat uses fixed integer slot IDs: player characters occupy IDs `0,1,2` and
enemies `3,4,5`. These are defined as `PLAYER_IDS`/`MONSTER_IDS` (or `ENEMY_IDS`) constants in
both `battle.gd` and `Skills.gd` and are central to targeting.

### 4.1. UI positioning and viewport space

The project uses `window/stretch/mode="canvas_items"` with a fixed 1280×720 base viewport
(see section 1). Control nodes lay out in that logical 1280×720 canvas space, not in physical
OS-window pixels.

UI positioning must use the logical canvas space. Use `get_viewport_rect().size` (logical
1280×720 base viewport) for layout/centering math — never `get_window().size`, which returns
physical OS-window pixels and breaks on Android, where physical size differs from the base
viewport. On PC the window is usually near 1280×720 so the bug is hidden; on Android it is not.
`test_ui_viewport_sizing.gd` guards against the wrong pattern reappearing.

---

## 5. Scene management: the context-container pattern

There is no scene-stack or router object; scene transitions are a single mechanism on
`Main_Instance`.

`ContextContainer` (`Scripts/Worldview/Context_Container.gd`) is a plain `Node` envelope:

```gdscript
class_name ContextContainer extends Node
var _scene: String                              # UID of the scene to load
var _static_context: Static_Context             # typed payload (e.g. Context_Battle)
var _player_battle_characters: Array[Character] # roster passed into combat
var _arguments: Dictionary                      # free-form key/value (difficulty, results…)
var _previous_scene: String
var _adventure_state: AdventureState
```

Transition flow (`Main_Instance.change_scene` → `_deferred_change_scene`):

1. If the current scene is a real gameplay screen (not `"Main"`/`"RunFromEditor"`), remove it and
   `call_deferred("free")` it.
2. `ResourceLoader.load(p_context._scene)` and `instantiate()` the new scene.
3. Add it as a child of `Main_Instance` and store it as `_current_scene`.
4. Call **`_current_scene.Init(p_context)`** — every gameplay scene exposes an `Init()` that reads
   what it needs out of the context.

`Static_Context` (`Scripts/Worldview/Static_Context.gd`) is the base for typed scene payloads;
`Context_Battle` (`Scripts/Worldview/Context_Battle.gd`) extends it with battle-specific data
(location texture, lighting, enemy waves, environment effects, loot table). Combat reads this in
`Battle.Init()` via `p_context._static_context as Context_Battle`.

This is a **one-way initialization** contract: the scene receives a context once at load and does
not hold a live reference back to global state except through `main.GetInstance()`. Results that
must survive the transition (battle outcome, damage dealt, chosen difficulty) are written back
into `_arguments` on the same context, which is then re-used for the next `change_scene` call (the
post-battle screen reads them).

---

## 6. Data and resource model

Content is authored as Godot `Resource` files under `Data/` and turned into runtime instances at
load time. There is a consistent **preset (template) vs instance (runtime)** split.

### 6.1. Resource templates

| Class | File | Role |
|---|---|---|
| `CharacterPreset` | `Scripts/Character/character_preset.gd` | Champion archetype: base stats, skills, available attribute-weight presets, trait, `_preset_UID` |
| `Skill` | `Scripts/Character/skill_data.gd` | Skill definition: target, damage scaling, turn effect, cooldown, type, buffs/debuffs |
| `AttributeWeightPreset` | `Scripts/Character/attribute_weight_preset.gd` | Per-attribute weight distribution used at level-up |
| `EquipmentPreset` | `Scripts/Gear/equipment_preset.gd` | Gear template: slot, rarity, attribute composition |
| `LootTable` | `Scripts/Battle/loot_table.gd` | Encounter rewards: primary (guaranteed) and secondary (weighted) loot |
| `AdventureTemplate` | `Scripts/Adventure_Scripts/adventure_template.gd` | Adventure generation parameters |
| `BiomeData` | `Scripts/Adventure_Scripts/biome_data.gd` | Biome enemy pools and boss definitions |
| `CharacterTrait` | `Scripts/Character/CharacterTraits/character_trait.gd` | Base class for character special abilities (see [Section 9](#9-trait-hook-system)) |

`Skill` is illustrative of how data drives behavior:

```gdscript
class_name Skill extends Resource
@export var target: Types.Skill_Target
@export var turn_effect: float                              # -1.0 … 1.0, bumps the turn bar
@export var damage_scaling: Dictionary[Types.Attribute, float]
@export var cooldown: int = 0
var cooldown_left: int = 0
@export var duration: int = 0
@export var skill_type: Types.Skill_Type
@export var defense_ignore_factor: float = 1.0             # lower = more defense bypassed
@export var buffs:   Dictionary[Types.Skill_Target, Types.Buff_Type]
@export var debuffs: Dictionary[Types.Skill_Target, Types.Debuff_Type]
```

There are 66+ `.tres` files under `Data/` (player and enemy character variants, skill variants
split into Attack/Support/Zone folders, attribute weights, item presets, loot tables, traits, and
adventure data). `Data/Example_Tree.json` is an exported skill-tree definition (a design artifact,
not yet wired into runtime).

### 6.2. Runtime instances

- `Character` (`Scripts/Character/character.gd`, `extends RefCounted`) is built from a `CharacterPreset`
  via `InstantiateNew(preset, instanceID)`. It copies preset stats into an
  `_attributes: Dictionary[Types.Attribute, int]`, picks a random `AttributeWeightPreset` from
  those the preset allows, duplicates the trait, and stores `_preset_UID` for later save/restore.
  Equipped gear lives in `_held_items: Dictionary[Types.Slot, int]` (slot → item instance ID).
- `Equipment` (`Scripts/Gear/equipment.gd`) is the runtime gear instance, holding its slot,
  rarity, and rolled attributes.

**Attribute aggregation** is centralized: `Character.GetBattleAttribute()` /
`GetBattleAttributes()` return base attributes plus equipment bonuses (the latter summed by
`GetEquipmentBonus()`, which looks items up in the global `ItemCollection`). Combat always reads
attributes through these methods so gear is automatically included. Note that effective HP is
`Health * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER` (×4), applied wherever current health is set.

Player-roster templates are duplicated with `duplicate(true)` when added to the
`CharacterCollection`, so two player instances of the same preset never share mutable state.
`Character.InstantiateNew` additionally deep-duplicates each `Skill`, so enemies built
directly from a preset in `Battle.Init` also own their skills and never share mutable state
such as `cooldown_left` — see [Section 15.6](#156-combat-correctness-defects-fixed).

---

## 7. Combat system (as implemented)

Combat lives in `Scripts/Battle/battle.gd` (`class_name Battle extends Node2D`), with stateless
math and effect resolution delegated to the `Skills` static utility
(`Scripts/Battle/Skills.gd`). For the *design* of the combat formulas, see `Concept_Document.md`;
this section describes the *code path*.

### 7.1. Setup (`Battle.Init`)

1. Reads `Context_Battle` from the container: background, lighting, enemy wave, loot table.
2. Loads player characters into `_characters[0..2]`, setting `_currentHealth` to scaled max HP.
3. Computes `_targeting_order` via `SetTargetingOrder()` — characters sorted by
   `Health + Defence` descending (used by enemy AI to pick "tankiest valid" targets).
4. Instantiates enemies into `_characters[3..5]`, jitters their speed by `randi_range(-3,3)`, and
   scales them to the encounter difficulty with `LevelSystem.SetOpponentLevel()` (boss variant if
   `_arguments["Boss_Scale"]` is present).
5. Fires each character's `StartOfBattle` trait hook (if registered), then initializes the
   battle UI and turn bar.

### 7.2. Turn order (the turn bar)

`Scripts/UI/Battle_UI/turn_bar.gd` advances each character along a horizontal bar every frame.
Each character's progress increases by `base_velocity * normalized_speed * delta`, where
`base_velocity = bar_width / TURN_DURATION_SECONDS` and `normalized_speed = speed / highest_speed`.
When a character reaches the right edge, the bar reports that ID as the active turn.

`Battle._process` drives this: it calls `turn_bar.Update()` for every character until
`GetActiveTurnID()` returns a non-`-1` ID, then calls `StartTurn()`. While a turn is in progress
no character advances.

### 7.3. Taking a turn (`StartTurn`)

- Positions the turn indicator over the active character and fires the `StartOfTurn` trait hook.
- **Player turn** (ID 0–2): populates the skill buttons (icon, name, description, cooldown) and
  waits for input.
- **Enemy turn** (ID 3–5): calls `HandleEnemyTurn()`, which selects the first off-cooldown skill
  (iterating skills in reverse), then either picks a free turn-bar zone (for zone skills) or walks
  `_targeting_order` to find a living valid target via `Skills.FindSkillTargets()`, and resolves.

Player input arrives as two handlers: `_on_battle_ui_battle_skill_selected(skill_ID)` records the
selected skill (and, for zone skills, enables zone selection), and
`_on_character_battle_target_selected(target_ID)` resolves the skill against the chosen target.

### 7.4. Skill resolution (`ResolveSkill`)

`ResolveSkill(caster_ID, target_IDs, skill_ID)` is the core sequence:

1. Snapshot caster attributes via `GetBattleAttributes()` (base + gear).
2. Fire the `OnSkillCast` trait hook → returns a `TraitSkillResult` carrying a damage multiplier
   and turn-bar bump.
3. Tick the caster's own active debuffs (`TriggerExistingCasterDebuffs`) and buffs
   (`TriggerExistingCasterBuffs`) — these apply per-turn effects (e.g. Burning deals 4% of max HP)
   and decrement durations.
4. `Skills.ResolveSkillEffect` for caster-side mechanics (e.g. Heap On stacking).
5. For each target: apply buff/debuff snapshots, optionally `CastBuff`/`CastDebuff` (debuffs are
   accuracy-vs-resistance rolled), and compute damage with `Skills.DamageDealt`.
6. Apply damage to `_currentHealth`, update the life bar, fire `OnDamageTaken`, and bump the
   target on the turn bar by `skill.turn_effect + trait_result._turn_bar_bump`.
7. Decrement all of the caster's cooldowns and set the used skill's `cooldown_left = cooldown`.
8. Mark the turn complete on the bar, run `TriggerZones()`, fire `EndOfTurn`, and clear the active
   turn so the bar resumes.

The implemented damage formula (`Skills.DamageDealt`):

```
caster_scaled = Σ over attrs ( skill.damage_scaling[attr] * caster[attr] * trait_multiplier )
effective_defence = defender.Defence * skill.defense_ignore_factor
damage_ratio = caster_scaled / (effective_defence + caster_scaled + 1)
mitigation = MINIMUM_DMG_PERCENT + (1 - MINIMUM_DMG_PERCENT) * damage_ratio
crit (if randi(0..100) <= CritChance): max(MINIMUM_CRIT_DAMAGE, CritDamage - defender.Knowledge*0.5) * 0.01
damage = mitigation * caster_scaled * _damage_multiplier[caster] * crit * random(0.95..1.05)
```

Status effects are capped at `MAX_STATUS_EFFECTS` (8) per character; Burning is non-overwritable
while the others refresh duration.

### 7.5. Zones

`Zone` (`Scripts/Battle/Zone.gd`) is a persistent effect placed on a turn-bar region:

```gdscript
var _type: Types.Skill_Type     # Flicker_Zone, Lava_Zone
var _duration: int = -1         # -1 = infinite
var _owner_ID: int
var _target: Types.Skill_Target # ZoneAll / ZoneAlly / ZoneEnemy
var _owner_knowledge: int = 0   # snapshotted at placement, see below
```

Each turn, `Battle.TriggerZones()` checks which living, non-active characters sit inside a zone
region (respecting the zone's ally/enemy targeting) and calls `Skills.ResolveZoneEffect()`:
Flicker zones bump the character by `FLICKER_ZONE_BASE_BUMP` (15%); Lava zones apply Burning.
Zones decrement and are erased at duration 0, and the number of live zones is capped at
`NUMBER_OF_TURN_BAR_ZONES` (5).

**Knowledge scaling.** When a zone is created (`Zone.CreateNew`, called from
`Battle._on_turn_bar_zone_selected`, the single call site for both player and enemy zone
placement), the placing character's battle Knowledge is snapshotted into `_owner_knowledge`.
Later Knowledge changes on that character do not retroactively affect the zone. When the zone
triggers on an ally of its owner, the base effect magnitude is scaled by
`Skills.AllyZoneMagnitude(base, owner_knowledge)`:

```
AllyZoneMagnitude = base * (1.0 + owner_knowledge * ZONE_KNOWLEDGE_SCALING)
```

`ZONE_KNOWLEDGE_SCALING` is `0.005` (+0.5% per point of Knowledge). Only ally-targeted zone
effects are scaled this way (e.g. Flicker Zone's bump); enemy-targeted zone effects (Lava Zone's
Burning) are unaffected by Knowledge. Zone duration and size are never scaled.

### 7.6. Ending combat

`IsTheBattleOver()` returns `Player_Won` / `Monsters_Won` / `Ongoing` by scanning current health.
`EndBattle()` resets the `Skills` static state, records the result in `_arguments`, and on victory:
computes the loot budget (`LootManager.CalculateBudget`), distributes rewards
(`LootManager.DistributeRewards`), adds any dropped equipment to the `ItemCollection`, awards
experience via `LevelSystem.AddExperience`, restores player HP, then transitions to the
post-battle scene through `main.GetInstance().change_scene()`.

---

## 8. Character progression

`LevelSystem` (`Scripts/Character/Level_System.gd`, static) owns all progression math.

- **Experience curve** — `GetExperienceRequirement(level)` implements
  `round((level / EXPERIENCE_FACTOR)^EXPERIENCE_EXPONENT * EXPERIENCE_CONSTANT_1
  + EXPERIENCE_CONSTANT_2 * level + EXPERIENCE_CONSTANT_3)` from `Game_Balance`.
- **Level up** — `AddExperience` adds XP and loops `LevelUpReward` while the threshold is met.
  `LevelUpReward` raises Health by a flat 2, then distributes
  `LEVEL_UP_POINTS_TO_DISTRIBUTE + floor(level^1.1)` points randomly, weighted by the character's
  `AttributeWeightPreset` (built into a cumulative-weight table for weighted sampling).
- **Opponent scaling** — `SetOpponentLevel(character, level, boss=false)` raises an enemy to the
  encounter level, distributing points proportional to each attribute's current share of the
  total. Speed scales faster (`+level*2`) than other attributes (`+(level*3)^1.1`); bosses receive
  a ×1.5 multiplier.

Test coverage for these formulas is described in `Test_Design_Document.md` (`test_level_system.gd`).

---

## 9. Trait hook system

Character special abilities are implemented as an **event-hook system**, the project's primary
extension point for bespoke behavior.

`CharacterTrait` (`Scripts/Character/CharacterTraits/character_trait.gd`, `extends Resource`) is
the base class. It declares an `_execution_steps: Dictionary[Types.Combat_Event, Callable]` map and
provides default (no-op, debug-printing) implementations of each hook:

| Hook | `Combat_Event` | Fired from `battle.gd` when… | Returns |
|---|---|---|---|
| `StartOfBattle` | `Start_Combat` | during `Init`, once per character | — |
| `StartOfTurn` | `Start_Turn` | at `StartTurn` for the active character | — |
| `EndOfTurn` | `End_Turn` | at the end of `ResolveSkill` | — |
| `OnSkillCast` | `Skill_Cast` | at the start of `ResolveSkill` | `TraitSkillResult` |
| `OnDamageTaken` | `Damage_Taken` | after a target takes damage | — |
| `OnDeath` | `On_Death` | when a character drops to 0 HP | — |

A concrete trait subclasses `CharacterTrait`, registers the events it cares about in
`_execution_steps`, and overrides the matching hooks. `battle.gd` always guards calls with
`_trait._execution_steps.has(<event>)`, so a trait only pays for the hooks it opts into.

`OnSkillCast` returns a `TraitSkillResult`
(`Scripts/Character/CharacterTraits/TraitHookResults/trait_skill_result.gd`) carrying a
`_damage_multiplier` and `_turn_bar_bump`, which `ResolveSkill` folds into the damage and turn-bar
calculations. Example: the Tidal Corsair trait
(`Scripts/Character/CharacterTraits/CharacterSpecificTraits/Tidal_Corsair_Trait.gd`) accumulates
stacks as skills are cast and, on its finisher, consumes them to return amplified
damage/turn-bar values.

---

## 10. Collections and the save system

### 10.1. Collections

`CharacterCollection` (`Scripts/Character/character_collection.gd`) and `ItemCollection`
(`Scripts/Gear/item_collection.gd`) are `Node`s owned by `Main_Instance`. Each holds a dictionary
keyed by an auto-incrementing instance ID (`Dictionary[int, Character]` / `Dictionary[int, Equipment]`)
and exposes `Serialize()` / `Deserialize()`.

### 10.2. Save format and ordering

`SaveManager` (`Scripts/Worldview/save_manager.gd`) implements **group-based serialization**.
Saveable nodes join the `"saveable"` group (`GROUP_SAVEABLE`); on `Save(slot)` the manager walks
the group, calls each node's `Serialize()`, attaches a metadata block, and writes the whole thing
as JSON to `user://profile_<slot>.save`.

`Load(slot)` parses the JSON and deserializes with a deliberate ordering constraint: **items load
before characters**, so that gear referenced by a character's `_held_items` already exists in the
`ItemCollection` when the character is restored. `_deserialize_group_by_type` is used to force this
order, and remaining saveable nodes are deserialized afterward.

What persists: per-character `_preset_UID`, level, experience, attributes, and held-item IDs;
per-item slot/rarity/attributes; plus resource and adventure state. On load, characters are
rebuilt from their preset UID and then have their saved progression re-applied.

Serialization roundtrips are covered by `test_collection_serialization.gd`
(see `Test_Design_Document.md`).

---

## 11. Adventure generation

The adventure (run) system lives in `Scripts/Adventure_Scripts/`:

- `adventure_generator.gd` builds a node graph from an `AdventureTemplate` and `BiomeData`
  (biome-aware enemy pools, a boss node, controlled branching).
- `adventure_state.gd` / `adventure_state_handler.gd` track current progress, supply-cost tiers,
  daily reset, and serialization; the handler is in the `"saveable"` group.
- `biome_data.gd` deliberately avoids `DirAccess`-based loading in favor of preloads, for Android
  export compatibility.
- Rewards flow through `LootManager` (`Scripts/Battle/loot_manager.gd`) and `LootTable` resources:
  a difficulty-scaled budget feeds primary (guaranteed) and secondary (weighted) loot.

Coverage: `test_adventure_state.gd`, `test_adventure_generator.gd`, `test_biome_loading.gd`,
`test_loot_manager.gd` (see `Test_Design_Document.md`).

---

## 12. Communication patterns

The codebase mixes several inter-node communication mechanisms. In rough order of how often they
appear:

1. **Direct method/property calls** (dominant). `battle.gd` calls `Skills.*` statics and reaches
   into `Character` fields and `CharacterRepresentation` members directly. Global state is reached
   through `main.GetInstance()`.
2. **Callables passed as parameters.** The turn bar receives `_on_turn_bar_zone_selected` as a
   `Callable` in `turn_bar.Init()`; zone buttons invoke it with a bound index.
3. **Signals** (limited use). The battle UI emits e.g. `battle_skill_selected(skill_ID)`, handled
   by `battle.gd._on_battle_ui_battle_skill_selected`.
4. **Resource UID references.** Scenes, presets, and icons are referenced by `uid://…` strings and
   loaded on demand (`ResourceLoader.load` / `preload`).
5. **Dictionary arguments.** `ContextContainer._arguments` carries free-form, stringly-typed data
   across scene transitions (difficulty, per-character damage, battle result).

The project conventions in `CLAUDE.md` state a preference for signals over direct calls for
cross-node communication; the as-built code leans heavily on direct calls instead. This is noted as
an observation, not a defect — see [Section 15](#15-known-weaknesses-and-recommendations).

---

## 13. Testing architecture

Tests use **GUT** (Godot Unit Test, 9.5.x), run headlessly from the project root:

```
/home/jonas/Documents/Godot_v4.6.2-stable_linux.x86_64 \
  --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd -gexit
```

Tests target **pure logic only** — combat math, targeting, leveling, loot, serialization — and
deliberately avoid the scene tree, rendering, and UI. Shared fixtures live in
`Tests/unit/helpers/test_factory.gd` (`make_character`, `make_loot_table`, `make_adventure_state`).
The full coverage matrix and the rationale for what is *not* tested are maintained in
`Test_Design_Document.md`; this document does not duplicate that detail.

---

## 14. Conventions

Code and naming conventions are defined in `CLAUDE.md` and are not repeated here. In summary:
`snake_case` for variables/functions/files, `PascalCase` for classes/nodes, full type hints
everywhere, one responsibility per script, and **words spelled out** in identifiers and document
names (with a small accepted-acronym allowlist: `UI`, `RPG`, `XP`, `ID`, `UID`, `JSON`, `URL`,
`GUT`, `HP`, `AoE`). New documents must be named by their full meaning.

### 9.1. Trait-driven battlefield visuals: `CharacterVisualEffects`

`CharacterVisualEffects` (`Scripts/Battle/character_visual_effects.gd`, `extends Node2D`) is a
generic, trait-agnostic visual-augmentation component on `Character_Battle_Repr.tscn`, separate
from `CharacterRepresentation` so view-only effects don't leak trait-specific methods into the
shared view. It owns a fixed pool of translucent `TextureRect` "echo" copies, positioned and faded
in the scene, and exposes one generic method:

```gdscript
func SetSpriteEchoes(p_count: int) -> void
```

A trait drives the count from its own state; the component only renders it. `CharacterRepresentation`
exposes the component via `GetVisualEffects()`. The first consumer is `DoubleTheFunTrait`
([Section 9](#9-trait-hook-system)), which sets the echo count to its avoidance-stack count and
clears it on a successful avoidance, battle start, or the character's own death (`OnDeath` hook).
This is intended as the home for future trait-driven battlefield visuals (auras, etc.), not
specific to this one trait.

---

## 15. Known weaknesses and recommendations

This section is **forward-looking**. The items below are not yet acted on; they record where the
current architecture is likely to cause friction and suggest directions. Nothing here describes
existing behavior.

### 15.1. User-interface and combat logic are tightly coupled

`battle.gd` owns both game-state mutation and direct manipulation of `CharacterRepresentation`
visuals, life bars, the turn indicator, and combat text. There is no view-model boundary.

*Impact:* combat logic cannot be unit-tested without the scene tree, which is why
`Test_Design_Document.md` excludes the battle scene from logic tests.
*Direction:* extract a headless combat-resolution layer (pure functions over `Character` state and
turn order) that emits result events the UI renders, so the resolution path becomes testable
independent of nodes.

### 15.2. Static mutable state in `Skills`

`Skills` keeps per-character arrays as `static var` (`_heap_on_stacks`, `_heap_on_value`,
`_damage_multiplier`), reset between battles via `Skills.Reset()`.

*Impact:* the combat math is not reentrant and carries hidden global state; a missed `Reset()` or
any future parallel/replayed battle would corrupt results, and tests must remember to reset.
*Direction:* move this transient per-combat state onto a battle-scoped object (or onto the
`Character`/combat-context instance) so it is created and destroyed with the battle.

### 15.3. File and identifier casing diverges from the snake_case convention

Several script files use PascalCase or mixed casing against the stated `snake_case` file
convention: `Skills.gd`, `Zone.gd`, `Level_System.gd`, `Context_Container.gd`, `Static_Context.gd`,
and folders such as `CharacterTraits/`. A handful of `Character` members also use camelCase
(`_currentHealth`, `_instanceID`, `_critChance`).

*Impact:* inconsistent navigation and a mismatch with `CLAUDE.md`.
*Direction:* a dedicated rename pass (files and the stray members), updating `class_name`
references and `.tres`/scene script paths together, ideally as one mechanical commit.

### 15.4. Signal-versus-direct-call usage is inconsistent with the stated convention

`CLAUDE.md` prefers signals for cross-node communication, but most coupling is direct calls and
Callables ([Section 12](#12-communication-patterns)).

*Impact:* tighter coupling than the convention intends; harder to intercept or test interactions.
*Direction:* decide deliberately per boundary — either relax the convention to match reality, or
introduce signals at the highest-traffic seams (e.g. battle → UI result events, which also supports
15.1). Either way, align the convention text and the code.

### 15.5. Stringly-typed cross-scene arguments

`ContextContainer._arguments` passes data between scenes as untyped string keys
(`"Difficulty"`, `"Boss_Scale"`, `"character_dmg_<i>"`, `"Battle_Result"`).

*Impact:* no compile-time safety; typos surface only at runtime.
*Direction:* promote the recurring keys to typed fields on `Static_Context` subclasses (as
`Context_Battle` already does for battle setup), reserving the dictionary for genuinely dynamic data.

### 15.6. Combat correctness defects (fixed)

A code review (July 2026) found the following defects in the combat path. All were
remediated per `Plans/Plan_Combat_Correctness_Fixes.md`; the descriptions are kept as a
record of the fixed behavior.

1. **Enemy `Skill` resources were shared across instances and battles.**
   `Character.InstantiateNew` assigned `_skills = p_preset._skills` by reference, so two
   enemies of the same variant shared `cooldown_left` and mutated the cached `.tres`.
   *Fixed:* `InstantiateNew` now deep-duplicates every skill, so each `Character` owns its
   own `Skill` instances.
2. **Boss scaling never applied.** `Battle.Init` called `SetOpponentLevel(difficulty)`
   unconditionally before the boss branch, and `SetOpponentLevel` early-returns once the
   level is reached, so the boss call carrying the ×1.5 multiplier was dead code.
   *Fixed:* `Battle.Init` computes the boss flag once and makes a single
   `SetOpponentLevel(difficulty, is_boss)` call.
3. **Critical-hit off-by-one.** `Skills.DamageDealt` rolled `randi_range(0, 100) <= CritChance`,
   so 0% crit chance still crit on a rolled 0. *Fixed:* the roll now lives in
   `Skills.RollsCritical`, which uses `randi_range(1, 100)`.
4. **Targeting could select dead or nonexistent slots.** `Skills.FindSkillTargets` hardcoded
   `randi() % 3` and appended whole ID ranges with no alive check. *Fixed:* `FindSkillTargets`
   now takes the characters dictionary and filters candidates on existence and
   `_current_health > 0` (via `FilterAliveTargets` / `PickRandomAliveTarget`) before selection.
5. **Turn-bar speed normalization mixed attribute sources.** `TurnBar.Init` found the highest
   speed from base `_attributes` but normalized with `GetBattleAttribute`. *Fixed:*
   normalization is extracted into the static `TurnBar.NormalizeSpeeds`, which reads one
   (geared) speed source for both the maximum and the division.
6. **Minor (all fixed):** the discarded `clampi()` result in `Battle.UpdateLifeBar` is now
   assigned back; the post-battle heal uses geared Health; `LevelSystem.LevelUpCriteriaMet`
   is a pure predicate with experience consumed in `AddExperience`; the Lava-zone Burning
   application dropped its misleading `OverwritableDebuff` guard — Burning stacks by design
   (`Concept_Document.md` 3.2.3.2), so each trigger adds an independent stack up to the cap.
7. **Burning feedback and attribution (fixed).** A Burning tick previously changed health
   silently and credited no one. Each combatant `Skill.Debuff` now records a `source_ID`
   (the applier), set by `CastDebuff` and the Lava-zone handler. `TriggerExistingCasterDebuffs`
   spawns combat text over the burning character for the tick and returns the damage keyed by
   source; `Battle.ResolveSkill` folds any player source's share into
   `character_dmg_<id>`, so Burning shows up in the post-battle damage totals.

### 15.7. Duplicated team-membership logic and fixed 3-versus-3 assumptions

The slot-ID layout (players `0–2`, enemies `3–5`) is interpreted independently in
`battle.gd`, `Skills.gd` (its own `PLAYER_IDS`/`MONSTER_IDS` copies, `3 + randi() % 3`
arithmetic, six-slot static arrays), and `turn_bar.gd` (reaches back into
`Battle.PLAYER_IDS`).

*Impact:* every ally/enemy relationship is paired `has()` checks; random targeting assumes
three living members per side (the source of several defects in 15.6); team size cannot vary.
*Direction:* a small `CombatTeam`/`CombatSides` abstraction owning membership, alive-filtering,
and random selection — see `Plans/Plan_Team_And_Roster_Abstraction.md`.

### 15.8. Status-effect behavior is hardcoded and duplicated

Buff/debuff magnitudes live in parallel `match` blocks in `Skills.gd`
(`TriggerExistingCasterDebuffs`/`Buffs`, `TriggerTargetBuffs`/`Debuffs`) plus separate
overwritability matches and icon maps. The duplication has already produced a divergence:
Expose Weakness reduces Defence by 30% in the caster-side tick but 50% in the target-side
snapshot (`Concept_Document.md` says 50%).

*Impact:* adding one effect means editing several blocks with nothing enforcing consistency;
the concept document's pending effects (Anchor, Sequence Lock, Frenzy, …) would compound this.
*Direction:* a `StatusEffectData` resource per effect with a generic apply/tick routine,
mirroring how `Skill` already works — see `Plans/Plan_Data_Driven_Status_Effects.md`.

### 15.9. Concept-document combat formulas describe a superseded design

`Concept_Document.md` 3.2.1 still specifies subtractive damage
(`Attack − Defence`), a separate magical-damage formula, a debuff success formula with base
chance and 10–90% caps, and round-based turn ordering. The implementation uses ratio-based
mitigation with per-skill attribute scaling and defense-ignore (Section 7.4), a plain
accuracy-versus-resistance contest with no base chance or caps, and the continuous turn bar.

*Impact:* the stated design source of truth misleads planning; the missing debuff hit-chance
floor also means low-Accuracy champions can be mathematically unable to land debuffs on
high-Resistance bosses, which undercuts the puzzle-encounter design.
*Direction:* rewrite the concept document's formula chapter to the implemented design and
decide the minimum-hit-chance question — see `Plans/Plan_Documentation_Parity.md`.
