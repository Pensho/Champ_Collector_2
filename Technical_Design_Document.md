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

By convention, combat uses integer slot IDs: player characters count up from `0` and enemies
from `ENEMY_ID_OFFSET` (`3`, fixed so enemy slots always index the same `_character_repr`
entries even when a wave fields fewer than three enemies). Team membership is owned by a
single abstraction built in `Battle.Init` from the actual roster sizes:
`CombatSides` (`Scripts/Battle/combat_sides.gd`) holds a player and an enemy
`CombatTeam` (`Scripts/Battle/combat_team.gd`) and answers every ally/enemy question
(`SideOf`, `AlliesOf`/`EnemiesOf`, `AreAllies`/`AreEnemies`); `CombatTeam` owns membership,
alive-filtering (`AliveMembers`), and random selection (`RandomAliveMember`, `-1` when no
member lives). Targeting, zone checks, and battle-over scanning all go through it — no code
outside `Battle.Init` assumes a fixed 3-versus-3 layout.

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

`ContextContainer` (`Scripts/Worldview/context_container.gd`) is a plain `Node` envelope:

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

`Static_Context` (`Scripts/Worldview/static_context.gd`) is the base for typed scene payloads;
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
| `CharacterTrait` | `Scripts/Character/character_traits/character_trait.gd` | Base class for character special abilities (see [Section 9](#9-trait-hook-system)) |
| `StatusEffectData` | `Scripts/Battle/status_effect_data.gd` | Buff/debuff definition: magnitude, magnitude kind, default duration, overwrite/stack rules, application sites, icon |
| `ReagentData` | `Scripts/Battle/reagent_data.gd` | Reagent definition (one rarity tier per resource): effect kind, target kind, rarity, binary flag, magnitude(s), icon |

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

`StatusEffectData` replaces the old hardcoded match blocks that used to duplicate buff/debuff
magnitudes across `skills.gd`. One `.tres` per implemented `Buff_Type`/`Debuff_Type` lives under
`Data/Status_Effects/`, looked up by `StatusEffectRegistry` (`Scripts/Battle/status_effect_registry.gd`,
preload-based like `Scripts/Debug/debug_catalog.gd`, not `DirAccess`-based, for Android export safety):

```gdscript
class_name StatusEffectData extends Resource
enum MagnitudeKind { AttributePercent, MaxHealthPercent, DamageMultiplier, TurnBarBump }
@export var magnitude_kind: MagnitudeKind
@export var affected_attribute: Types.Attribute            # AttributePercent only
@export var magnitude: float = 0.0                         # 0.0 = no static default; the
                                                             # applier sets the instance's value
                                                             # directly (e.g. Phalanx Guard)
@export var duration_default: int = 2
@export var overwritable: bool = true                       # re-apply refreshes duration
@export var stackable: bool = false                         # re-apply adds an independent instance
@export var applies_on_self_tick: bool = true                # ticks on the holder's own turn
@export var applies_on_target_snapshot: bool = false          # applies when the holder is targeted
@export var icon: Texture2D
```

`StatusEffects.Buff`/`Debuff` (`Scripts/Battle/status_effects.gd`) carry the resolved per-instance
`value` (Empower/Fortify read `StatusEffectData.magnitude` by default; Phalanx Guard overrides it
per-rarity in `LancerTrait`). `BattleResolver.ApplyBuff`/`ApplyDebuff`/`_CastBuff`/`_CastDebuff` all
resolve `stackable`/`overwritable` from the registry instead of the old `Skills.OverwritableBuff`/
`OverwritableDebuff` match statements, and the caster-tick methods
(`_TriggerExistingCasterBuffs`/`Debuffs`) and target-snapshot methods (`Skills.TriggerTargetBuffs`/
`TriggerTargetDebuffs`) dispatch generically on `magnitude_kind` instead of the buff/debuff type.
Zone-applied debuffs (e.g. the Lava zone's Burning) come from the placing `Skill`'s existing
`debuffs` dictionary, keyed by the skill's own `target`, rather than being hardcoded in
`BattleResolver._ResolveZoneEffect`.

`ReagentData` (`Concept_Document.md` 3.3.3) is the reagent-system data model, authored so far as
a pure data layer with no inventory, UI, or combat-application code yet (those land in
`Plans/Plan_Reagent_Inventory_And_Storage_UI.md` and `Plans/Plan_Reagent_Combat_Application.md`).
Unlike `StatusEffectData`, one resource covers exactly
one rarity tier — `Data/Reagents/<Family>/<Family>_<Rarity>.tres`, one subfolder per reagent
family — since reagent magnitudes scale with rarity only, never with the consumer's attributes
(deliberately no attribute-snapshot fields on the resource). Looked up by `ReagentRegistry`
(`Scripts/Battle/reagent_registry.gd`, same preload-not-`DirAccess` pattern as
`StatusEffectRegistry`) through a stable string identifier matching the `.tres` base file name
(e.g. `"Tincture_Speed_Uncommon"`):

```gdscript
class_name ReagentData extends Resource
enum EffectKind {
    Attribute_Increase, Heal, Remove_Debuffs, Destroy_Enemy_Buffs, Reduce_Cooldown,
    Turn_Bar_Reset, Clear_Zone, Random_Attribute_Increase, Health_Cost_Damage_Bonus,
}
enum TargetKind { Self_Target, One_Ally, One_Enemy, Zone_Section }
@export var rarity: Types.Rarity
@export var binary: bool = false                            # unaffected by potency modifiers
@export var effect_kind: EffectKind
@export var target_kind: TargetKind
@export var affected_attribute: Types.Attribute             # Attribute_Increase / Random_Attribute_Increase only
@export var magnitude: float = 0.0                          # units depend on effect_kind, see script
@export var secondary_magnitude: float = 0.0                # Health_Cost_Damage_Bonus's damage-dealt bonus only
@export var icon: Texture2D
```

The catalog currently covers the "feasible subset" whose combat mechanics already exist:
Tinctures (one family per primary attribute), Restorative Draught, Purging Tonic, Thief's Regret,
Rewinding Grit, Second Wind Phial, Zone-Dissolving Salts, Unrefined Residue, and Fractured Idol —
68 `.tres` files (17 families × 4 rarity tiers). Rewinding Grit targets one ally directly
(`One_Ally`) and reduces the cooldown of every skill that ally has currently on cooldown, rather
than requiring a skill-choice target kind. Reagents still deferred until their blocking mechanic
lands: Barrier Stone, Deathward Charm, Chant Fragment, Notarized Seal, Wayfarer's Draught, and the
Alchemist brew pool.

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
such as `cooldown_left`.

---

## 7. Combat system (as implemented)

Combat is split across two layers:

- **`BattleResolver`** (`Scripts/Battle/battle_resolver.gd`, `extends RefCounted`) — the headless
  resolution core. It owns all per-combat transient state (Heap-On stacks, damage multipliers,
  zones, status-effect identity), a seedable `RandomNumberGenerator` that every combat roll goes
  through, and the battle-over check. It mutates `Character` state and reports everything that
  happens as **`CombatResult`** records (`Scripts/Battle/combat_result.gd`) — each result is both
  appended to the returned array and emitted through the `result_produced` signal. The resolver
  never touches `CharacterRepresentation` or `BattleUI`.
- **`Battle`** (`Scripts/Battle/battle.gd`, `extends Node2D`) — the scene. It feeds input into the
  resolver and renders the results: life bars, combat text, status icons, turn-bar effects, the
  turn indicator. Turn flow is an explicit `BattleState` state machine (`Advancing`,
  `Awaiting_Player_Input`, `Selecting_Zone`, `Enemy_Acting`, `Resolving`, `Battle_Over`); zone
  selection is a sub-state of player input, not a boolean.

Stateless helpers (targeting, zone-target checks, status-effect rules, attribute-snapshot
modifiers) remain as statics on `Skills` (`Scripts/Battle/skills.gd`). For the *design* of the
combat formulas, see `Concept_Document.md`; this section describes the *code path*.

### 7.1. Setup (`Battle.Init`)

1. Reads `Context_Battle` from the container: background, lighting, enemy wave, loot table.
2. Builds `CombatSides` from the fielded rosters and constructs the `BattleResolver` over the
   shared characters dictionary, connecting `result_produced` to the scene's renderer. When the
   encounter comes from a generated adventure, the resolver is seeded from the adventure's
   generation seed and current node index (`Battle.BattleSeed()`), making the battle's rolls
   reproducible; otherwise the seed is randomized.
3. Loads player characters into `_characters[0..2]`, setting `_current_health` to scaled max HP,
   and applies adventure buffs/debuffs through `resolver.ApplyBuff`/`ApplyDebuff`.
4. Computes `_targeting_order` via `SetTargetingOrder()` — characters sorted by
   `Health + Defence` descending (used by enemy AI to pick "tankiest valid" targets).
5. Instantiates enemies into `_characters[3..5]`, jitters their speed by `randi_range(-3,3)` on
   the **resolver's** generator, and scales them to the encounter difficulty with
   `LevelSystem.SetOpponentLevel()` (boss variant if `_arguments["Boss_Scale"]` is present).
6. Fires each character's `StartOfBattle` trait hook (logic reset only) and paints the initial
   trait visuals via `trait.RefreshVisuals(repr)`, then initializes the battle UI and turn bar.

### 7.2. Turn order (the turn bar)

`Scripts/UI/Battle_UI/turn_bar.gd` advances each character along a horizontal bar every frame.
Each character's progress increases by `base_velocity * normalized_speed * delta`, where
`base_velocity = bar_width / TURN_DURATION_SECONDS` and `normalized_speed = speed / highest_speed`.
When a character reaches the right edge, the bar reports that ID as the active turn.

`Battle._process` drives this only in the `Advancing` state: it calls `turn_bar.Update()` for
every living character until `GetActiveTurnID()` returns a non-`-1` ID, then calls `StartTurn()`.

The turn bar is still both state and view: zone occupancy and Plan-trait reach are positional
questions only it can answer. The resolver reaches them through the **`TurnPositions`** interface
(`Scripts/Battle/turn_positions.gd`) — `IsCharacterInZone` and `GetCharactersBehindBy` — with
`TurnBarPositions` (`Scripts/UI/Battle_UI/turn_bar_positions.gd`) adapting the live node and the
base class doubling as the headless default for tests. Long term the positions belong in the core.

### 7.3. Taking a turn (`StartTurn` and the state machine)

- Positions the turn indicator over the active character and calls `resolver.BeginTurn(ID)`,
  which fires the `StartOfTurn` trait hook (e.g. the Plan trait's reach-based Empower).
- **Player turn** (`_sides.player.Has(ID)`): populates the skill buttons (icon, name,
  description, cooldown) and enters `Awaiting_Player_Input`. Selecting a zone skill enters
  `Selecting_Zone` and enables the zone buttons; selecting a non-zone skill returns to
  `Awaiting_Player_Input`.
- **Enemy turn** (`_sides.enemy.Has(ID)`): enters `Enemy_Acting` and calls `HandleEnemyTurn()`,
  which selects the first off-cooldown skill via `SelectEnemySkillID()` (skipping zone skills when
  no zone is free), then either places a random free zone (`resolver.PlaceZone`, rolled on the
  resolver's generator) or walks `_targeting_order` for a living valid target via
  `resolver.FindSkillTargets()`.

Every resolution path funnels through `Battle.ResolveTurn(target_IDs)`: it enters `Resolving`,
calls `resolver.ResolveSkill`, marks the turn complete on the bar, refreshes trait visuals, hides
the skill UI, and returns to `Advancing` (or ends the battle).

### 7.4. Skill resolution (`BattleResolver.ResolveSkill`)

`ResolveSkill(caster_ID, target_IDs, skill_ID) -> Array[CombatResult]` is the core sequence:

1. Snapshot caster attributes via `GetBattleAttributes()` (base + gear).
2. Fire the `OnSkillCast` trait hook → returns a `TraitSkillResult` carrying a damage multiplier
   and turn-bar bump.
3. Tick the caster's own active debuffs and buffs — per-turn effects (e.g. Burning deals 4% of
   max HP, reported as a `Burning_Tick` result with a per-source damage split) and duration
   decrements (reported as `Status_Duration` / `Statuses_Removed` results).
4. Resolve caster-side skill mechanics (e.g. Heap On stacking against the resolver's per-combat
   state).
5. For each target: apply buff/debuff snapshots, fire `OnDefend`, optionally cast the skill's
   buff/debuff (debuffs are accuracy-vs-resistance rolled on the resolver's generator; a failed
   roll reports `Debuff_Resisted`), and compute damage.
6. Apply damage to `_current_health` (clamped; an alive→dead transition clears the victim's
   statuses, fires the `OnDeath` trait hook, and reports `Statuses_Cleared` + `Death`), and bump
   the target on the turn bar by `skill.turn_effect + trait_result._turn_bar_bump`
   (`Turn_Bar_Bump`).
7. Decrement all of the caster's cooldowns and set the used skill's `cooldown_left = cooldown`.
8. Run `TriggerZones()` and fire the `EndOfTurn` trait hook.

The implemented damage formula (`BattleResolver._ResolveDamage`):

```
caster_scaled = Σ over attrs ( skill.damage_scaling[attr] * caster[attr] * trait_multiplier )
effective_defence = defender.Defence * skill.defense_ignore_factor
damage_ratio = caster_scaled / (effective_defence + caster_scaled + 1)
mitigation = MINIMUM_DMG_PERCENT + (1 - MINIMUM_DMG_PERCENT) * damage_ratio
crit (if rng.randi(1..100) <= CritChance): max(MINIMUM_CRIT_DAMAGE, CritDamage - defender.Knowledge*0.5) * 0.01
damage = mitigation * caster_scaled * damage_multiplier[caster] * crit * rng.random(0.95..1.05)
```

Status effects are capped at `MAX_STATUS_EFFECTS` (8) per character; Burning is non-overwritable
while the others refresh duration. The resolver assigns each applied status a battle-unique ID
(carried on `Status_Applied` results); the scene maps those IDs to the representation's icon slots
when rendering.

### 7.5. Zones

`Zone` (`Scripts/Battle/zone.gd`) is a persistent effect placed on a turn-bar region:

```gdscript
var _type: Types.Skill_Type     # Flicker_Zone, Lava_Zone
var _duration: int = -1         # -1 = infinite
var _owner_ID: int
var _target: Types.Skill_Target # ZoneAll / ZoneAlly / ZoneEnemy
var _owner_knowledge: int = 0   # snapshotted at placement, see below
```

The resolver owns the live zones. `PlaceZone(zone_ID, owner_ID, skill)` creates one (reporting
`Zone_Placed`); `TriggerZones(active_ID)` runs at the end of every `ResolveSkill`, checking which
living, non-active characters sit inside a zone region (via `TurnPositions`, respecting the zone's
ally/enemy targeting) and applying the effect: Flicker zones bump the character
(`Turn_Bar_Bump`); Lava zones apply Burning (a silent `Status_Applied`). Each trigger decrements
the zone and reports `Zone_Triggered`; expired zones are freed and erased. At most one zone fires
per character per round, and the number of live zones is capped at `NUMBER_OF_TURN_BAR_ZONES` (5).

**Knowledge scaling.** When a zone is created, the placing character's battle Knowledge is
snapshotted into `_owner_knowledge`. Later Knowledge changes on that character do not
retroactively affect the zone. When the zone triggers on an ally of its owner, the base effect
magnitude is scaled by `Skills.AllyZoneMagnitude(base, owner_knowledge)`:

```
AllyZoneMagnitude = base * (1.0 + owner_knowledge * ZONE_KNOWLEDGE_SCALING)
```

`ZONE_KNOWLEDGE_SCALING` is `0.005` (+0.5% per point of Knowledge). Only ally-targeted zone
effects are scaled this way (e.g. Flicker Zone's bump); enemy-targeted zone effects (Lava Zone's
Burning) are unaffected by Knowledge. Zone duration and size are never scaled.

### 7.6. Ending combat

`BattleResolver.IsTheBattleOver()` returns `Player_Won` / `Monsters_Won` / `Ongoing` by scanning
team aliveness. `Battle.EndBattle()` enters `Battle_Over`, records the result in `_arguments`, and
on victory: computes the loot budget (`LootManager.CalculateBudget`), distributes rewards
(`LootManager.DistributeRewards`), adds any dropped equipment to the `ItemCollection`, awards
experience via `LevelSystem.AddExperience`, restores player HP, then transitions to the
post-battle scene through `main.GetInstance().change_scene()`. The resolver (and all its
per-combat state) is simply discarded with the scene — there is no global state to reset.

---

## 8. Character progression

`LevelSystem` (`Scripts/Character/level_system.gd`, static) owns all progression math.

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

`CharacterTrait` (`Scripts/Character/character_traits/character_trait.gd`, `extends Resource`) is
the base class. It declares an `_execution_steps: Dictionary[Types.Combat_Event, Callable]` map and
provides default (no-op, debug-printing) implementations of each hook. The combat hooks are
**logic-only**: they mutate trait/`Character` state and report effects through the
`BattleResolver` they receive (`ApplyBuff`, `RemoveBuff`, `EmitTraitText`, `GetRandom`,
`GetTurnPositions`, …), never through UI types:

| Hook | `Combat_Event` | Fired when… | Returns |
|---|---|---|---|
| `StartOfBattle()` | `Start_Combat` | during `Battle.Init`, once per character (logic reset) | — |
| `StartOfTurn(owner_ID, resolver)` | `Start_Turn` | in `BeginTurn` for the active character | — |
| `EndOfTurn(owner_ID, resolver)` | `End_Turn` | at the end of `ResolveSkill` | — |
| `OnSkillCast(owner_ID, target_IDs, skill_name, caster_attributes, resolver)` | `Skill_Cast` | at the start of `ResolveSkill` | `TraitSkillResult` |
| `OnDefend(defender_ID, defender_attributes, characters)` | `Defend` | when snapshotting a target's attributes | — |
| `OnDamageTaken(owner_ID, rarity, resolver)` | `Damage_Taken` | before damage lands; returns the incoming-damage multiplier | `float` |
| `OnDeath()` | `On_Death` | when a character drops to 0 HP (logic reset) | — |

One **view hook** complements them: `RefreshVisuals(character_repr)` repaints the trait's icons,
tooltips, and battlefield effects (e.g. sprite echoes) from current trait state. The battle scene
calls it after `StartOfBattle` and after every resolved action; the resolver never does.

A concrete trait subclasses `CharacterTrait`, registers the events it cares about in
`_execution_steps`, and overrides the matching hooks. Callers always guard with
`_trait._execution_steps.has(<event>)`, so a trait only pays for the hooks it opts into.

`OnSkillCast` returns a `TraitSkillResult`
(`Scripts/Character/character_traits/TraitHookResults/trait_skill_result.gd`) carrying a
`_damage_multiplier` and `_turn_bar_bump`, which `ResolveSkill` folds into the damage and turn-bar
calculations. Example: the Tidal Corsair trait
(`Scripts/Character/character_traits/CharacterSpecificTraits/tidal_corsair_trait.gd`) accumulates
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

1. **Signals at the battle-to-UI seam.** `BattleResolver` emits every `CombatResult` through its
   `result_produced` signal; the battle scene connects once in `Init` and renders each record
   (`Battle._on_resolver_result_produced`). The battle UI likewise emits
   `battle_skill_selected(skill_ID)`, handled by `battle.gd`. This is the project's
   highest-traffic boundary and it is signal-driven.
2. **Direct method/property calls** (still common elsewhere). Scene code reaches into `Character`
   fields and `CharacterRepresentation` members directly, and global state is reached through
   `main.GetInstance()`.
3. **Callables passed as parameters.** The turn bar receives `_on_turn_bar_zone_selected` as a
   `Callable` in `turn_bar.Init()`; zone buttons invoke it with a bound index.
4. **Resource UID references.** Scenes, presets, and icons are referenced by `uid://…` strings and
   loaded on demand (`ResourceLoader.load` / `preload`).
5. **Dictionary arguments.** `ContextContainer._arguments` carries free-form, stringly-typed data
   across scene transitions (difficulty, per-character damage, battle result).

The `CLAUDE.md` convention (prefer signals for cross-node communication) is now honored at the
combat seam. The remaining direct-call seams (view-internal wiring, `main.GetInstance()`) are
accepted as-is — see [Section 15.4](#154-signal-versus-direct-call-usage-is-inconsistent-with-the-stated-convention).

---

## 13. Testing architecture

Tests use **GUT** (Godot Unit Test, 9.5.x), run headlessly from the project root:

```
/home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64 \
  --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd -gexit
```

Tests target **pure logic only** — combat resolution (`BattleResolver`, including a full seeded
3-versus-3 battle in `test_battle_resolver.gd`), combat math, targeting, leveling, loot,
serialization — and deliberately avoid the scene tree, rendering, and UI. Shared fixtures live in
`Tests/unit/helpers/test_factory.gd` (`make_character`, `make_full_roster`, `make_resolver`,
skill builders, and the `FakeTurnPositions` stub).
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

### 15.1. User-interface and combat logic are tightly coupled — resolved

Resolved by the headless combat core: `BattleResolver` owns all combat mutation and reports
`CombatResult` records; `battle.gd` is input handling, a turn-flow state machine, and rendering
([Section 7](#7-combat-system-as-implemented)). The resolution path is unit-tested without the
scene tree (`test_battle_resolver.gd`). One residue remains: turn-bar *positions* are still view
state, reached through the `TurnPositions` interface — moving them into the core is the follow-up.

### 15.2. Static mutable state in `Skills` — resolved

Resolved: the per-combat state (`_heap_on_stacks`, `_heap_on_value`, `_damage_multiplier`) lives
on the battle-scoped `BattleResolver` instance and is created and discarded with the battle;
`Skills.Reset()` is gone and `Skills` keeps only stateless helpers (plus a static texture cache).
Combat rolls all go through the resolver's injectable, seedable `RandomNumberGenerator`.

### 15.3. File and identifier casing diverges from the snake_case convention — resolved

Resolved by the completed naming-convention-alignment plan: `skills.gd`, `zone.gd`,
`level_system.gd`, `context_container.gd`, `static_context.gd`, and the `character_traits/`
folder now use `snake_case`; the stray camelCase `Character` members and the
`Repr`/`char`/`attr` abbreviations in `_character_representations`, `_character_turn_markers`,
and `p_caster_attributes` are spelled out. `class_name`s were left unchanged; `.tres`/scene
script paths were updated alongside the renamed files.

### 15.4. Signal-versus-direct-call usage is inconsistent with the stated convention — resolved for the combat seam

The highest-traffic boundary is now signal-driven: `BattleResolver.result_produced` carries every
combat event to the battle scene ([Section 12](#12-communication-patterns)). The remaining
direct-call seams (view-internal wiring, `main.GetInstance()` access, Callable-based zone
selection) are accepted as-is; the `CLAUDE.md` convention should be read as applying to
cross-subsystem boundaries, not every node interaction.

### 15.5. Stringly-typed cross-scene arguments

`ContextContainer._arguments` passes data between scenes as untyped string keys
(`"Difficulty"`, `"Boss_Scale"`, `"character_dmg_<i>"`, `"Battle_Result"`).

*Impact:* no compile-time safety; typos surface only at runtime.
*Direction:* promote the recurring keys to typed fields on `Static_Context` subclasses (as
`Context_Battle` already does for battle setup), reserving the dictionary for genuinely dynamic data.

### 15.7. Duplicated team-membership logic and fixed 3-versus-3 assumptions — resolved

Resolved by the completed team-and-roster-abstraction plan: team membership,
alive-filtering, and random selection now live in `CombatTeam`/`CombatSides`
(see section 4), built once in `Battle.Init` from the actual roster sizes. The
`PLAYER_IDS`/`MONSTER_IDS`/`ENEMY_IDS` constants and the six-slot static arrays in
`skills.gd` (now dictionaries keyed by slot ID) are gone, and `turn_bar.gd` receives the
player team instead of reaching back into `Battle`.

### 15.8. Status-effect behavior is hardcoded and duplicated — resolved

Resolved by the completed data-driven-status-effects plan: buff/debuff magnitude,
overwrite/stack rules, application sites, and icons now live on one `StatusEffectData`
resource per effect under `Data/Status_Effects/`, looked up through
`StatusEffectRegistry` (see section 6.1). `skills.gd`/`BattleResolver`'s per-type
`match` blocks and the `Statuses.BUFF_ICONS`/`DEBUFF_ICONS` maps are gone; the caster-tick
and target-snapshot methods dispatch generically on `StatusEffectData.magnitude_kind`.
