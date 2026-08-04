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
  Bar Brawler, Jester, Chronophage, Tidal Corsair, Centaur Lancer, Centaur Archivist, Tactician,
  Bloodmage, Sorcerer, Symbiote, Diviner, Appraiser, Emissary, Cultist, Plague Doctor, Warlord,
  Alchemist) — one preset per implemented Role (`Concept_Document.md` 3.1.3).
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
`Role`, `Slot`, `Skill_Target`, `Attribute`, `Buff_Type`, `Debuff_Type`,
`Combat_Event`. Every system references attributes and targeting through `Types.Attribute.*`,
`Types.Skill_Target.*`, and so on, which keeps enum values consistent across data files and code.

### 3.4. `Game_Settings` (`class_name Settings`)

`Scripts/settings.gd` owns user preferences (audio volumes, screen shake, fullscreen, locale),
persisted to `user://settings.cfg` via `ConfigFile`. This is deliberately separate from
`SaveManager`'s per-profile `user://profile_<slot>.save` files: settings apply regardless of
which save slot is active. On `_ready()` it loads the config and applies every value to the
engine (`AudioServer` bus volumes for the `Master`/`Music`/`Sound Effects` buses, window mode via
`DisplayServer`, locale via `TranslationServer`). Each setter applies its side effect immediately
and re-saves, so the settings menu (`Scenes/ui/Settings_Menu.tscn`,
`Scripts/UI/settings_menu.gd`) is a thin view over this autoload. The menu itself is an overlay
`Control` instantiated by `MainMenu` and toggled with `show()`/`hide()`, following the same
pattern as `HollowLedgerWindow`.

The autoload key (`Game_Settings`) intentionally differs from the class name (`Settings`) —
matching `Game_Balance`/`GameBalance` — because an autoload's registered name shadows a
same-named `class_name` in the global scope, which would otherwise make `Settings.new()`
resolve to the singleton instance instead of the class.

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
| `CharacterPreset` | `Scripts/Character/character_preset.gd` | Champion archetype: base stats, skills, available attribute-weight presets, trait, `_preset_path` |
| `Skill` | `Scripts/Character/skill_data.gd` | Skill definition: name/description/icon, default target, type, cooldown, and an ordered `effects` array |
| `SkillEffect` | `Scripts/Battle/Skill_Effects/skill_effect.gd` | Base class for one self-resolving skill effect (see [Section 7.4](#74-skill-resolution-battleresolverresolveskill)) |
| `AttributeWeightPreset` | `Scripts/Character/attribute_weight_preset.gd` | Per-attribute weight distribution used at level-up |
| `EquipmentPreset` | `Scripts/Gear/equipment_preset.gd` | Gear template: slot, rarity, attribute composition |
| `LootTable` | `Scripts/Battle/loot_table.gd` | Encounter rewards: primary (guaranteed) and secondary (weighted) loot |
| `AdventureTemplate` | `Scripts/Adventure_Scripts/adventure_template.gd` | Adventure generation parameters |
| `BiomeData` | `Scripts/Adventure_Scripts/biome_data.gd` | Biome enemy pools and boss definitions |
| `CharacterTrait` | `Scripts/Character/character_traits/character_trait.gd` | Base class for character special abilities (see [Section 9](#9-trait-hook-system)) |
| `StatusEffectData` | `Scripts/Battle/status_effect_data.gd` | Buff/debuff definition: magnitude, magnitude kind, default duration, overwrite/stack rules, self-tick behavior, icon |
| `ReagentData` | `Scripts/Battle/reagent_data.gd` | Reagent definition (one rarity tier per resource): effect kind, target kind, rarity, binary flag, magnitude(s), icon |
| `ReagentCollection` | `Scripts/Gear/reagent_collection.gd` | Persistent player-owned reagent counts, keyed by `ReagentRegistry` identifier string |

`Skill` holds only what the UI and turn machinery read directly — everything a skill *does* is an
ordered array of self-resolving `SkillEffect` resources instead of an optional flat field per
mechanic:

```gdscript
class_name Skill extends Resource
@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target      # default target group for the effects
# cooldown is the amount of turns until the skill can be used again.
@export var cooldown: int = 0
## Ordered, self-resolving effects.
@export var effects: Array[SkillEffect]
var cooldown_left: int = 0
```

`SkillEffect` (`Scripts/Battle/Skill_Effects/skill_effect.gd`) is the base class every effect
subclass extends. `ResolveSkill` (see [Section 7.4](#74-skill-resolution-battleresolverresolveskill))
knows nothing about effect kinds — it walks `Skill.effects` in authored order and calls
`Resolve(context)` on each one whose condition is met. Every subclass inherits four fields from
the base class:

```gdscript
class_name SkillEffect extends Resource
## Skill_Default means "use the skill's own target".
@export var target: Types.Skill_Target = Types.Skill_Target.Skill_Default
@export var condition: Types.Skill_Condition = Types.Skill_Condition.None
@export var condition_test: Types.Condition_Test = Types.Condition_Test.At_Least
@export var condition_threshold: float = 0.0
```

`target` defaults to `Skill_Default`, meaning "resolve against the same targets the skill itself
was cast at"; any other value resolves that one effect's target group independently (e.g. a
self-buff on an otherwise offensive skill). `condition`/`condition_test`/`condition_threshold`
gate the whole effect on a trait's `GetConditionCount` reading for the primary target — see
[Section 9](#9-trait-hook-system).

The effect subclasses, all under `Scripts/Battle/Skill_Effects/`:

| Effect | Fields | Resolves |
|---|---|---|
| `DamageEffect` | `damage_scaling`, `defense_ignore_factor`, `bonus_per: Dictionary[Types.Trait_Count_Source, float]`, `bonus_per_debuff_on_target: Dictionary[Types.Debuff_Type, float]`, `allow_critical` | Damage to the target group, scaled and bonused — see the damage-bonus discussion in [Section 7.4](#74-skill-resolution-battleresolverresolveskill). `bonus_per_debuff_on_target` sums an additive bonus per debuff type currently on each individual target (e.g. Cataclysmic Surge's +30% against Warped) — keyed by debuff type rather than `Trait_Count_Source` because the source is which debuff is present, not a count |
| `HealthChangeEffect` | `fraction`, `scaling: Dictionary[Types.Attribute, float]` | A signed max-Health-fraction transfer: negative is a cost (writes `context.health_paid` when the target is the caster), non-negative plus attribute scaling is a heal |
| `ApplyBuffEffect` | `buff_type`, `duration` | Applies one buff type, with its own duration, to the target group (a second buff on the same skill with a different duration is just a second `ApplyBuffEffect`) |
| `ApplyDebuffEffect` | `debuff_type`, `duration` | Applies one debuff type; consults `CharacterTrait.GetAppliedStatusValue` for a value override before casting |
| `BarrierEffect` | `source` (`Health_Paid` or `Target_Max_Health`), `fraction`, `duration` | Grants a Barrier sized as a fraction of `context.health_paid` or the recipient's own max Health; skips entirely on a non-positive value |
| `StealBuffEffect` | `count`, `to`, `duration_override` | Steals `count` buffs from the target group and re-applies them to one recipient rolled once from the `to` group |
| `ConsumeBuffsEffect` | `count` (`-1` = all) | Consumes buffs from the target group, adding the removed count to `context.buffs_consumed` |
| `ReduceBuffDurationsEffect` | `amount` | Shaves `amount` turns off every buff already on the target group |
| `TurnBarEffect` | `fraction` | Bumps the target group's turn bar by the skill's own contribution, independent of any trait turn-bar bump |
| `AlternatingEffect` | `effects: Array[SkillEffect]` | Cycles through `effects` by this cast's use count, so a skill can behave differently on alternating (or any N-way rotating) casts |
| `ZoneEffect` | `charges`, `section` (`Player_Chosen`/`Left_Most_Empty`/`Random_Empty`), `on_trigger: Array[SkillEffect]`, `visual_scene: PackedScene` | Resolves a turn-bar section (see [Section 7.5](#75-zones)) and calls `ZoneResolver.PlaceZone` with itself; an ordinary effect in the effect loop like any other, so a skill can place a zone alongside a direct effect (e.g. Inscribe's damage-plus-glyph) |
| `BarrierZoneEffect` | *(none)* | The Architect's charge-scaled turn-bar Barrier (`Skills.ApplyBarrierZone`), kept as its own effect rather than a generic `BarrierEffect` zone case so the Calibration trait's charge-investment bonus and `Zone_Used` hook stay intact |
| `ClearZoneEffect` | `damage_scaling_per_charge: Dictionary[Types.Attribute, float]`, `cooldown_reduction` | Removes one zone from the turn bar (Refutation): a player-chosen or random occupied section; damages the placing enemy scaled by remaining charges, or reduces the placing ally's zone skill's cooldown |

There are 81 `.tres` files under `Data/Character_Skill_Variants/` (skill variants, mostly split
into Attack/Support/Zone subfolders), plus player and enemy character variants, attribute weights, item
presets, loot tables, traits, and adventure data elsewhere under `Data/`. `Data/Example_Tree.json`
is an exported skill-tree definition (a design artifact, not yet wired into runtime).

`StatusEffectData` replaces the old hardcoded match blocks that used to duplicate buff/debuff
magnitudes across `skills.gd`. One `.tres` per implemented `Buff_Type`/`Debuff_Type` lives under
`Data/Status_Effects/`, looked up by `StatusEffectRegistry` (`Scripts/Battle/status_effect_registry.gd`,
preload-based like `Scripts/Debug/debug_catalog.gd`, not `DirAccess`-based, for Android export safety):

```gdscript
class_name StatusEffectData extends Resource
enum MagnitudeKind {
    AttributePercent, MaxHealthPercent, DamageMultiplier, TurnBarBump,
    AttributePercentagePointAdd, MaxHealthAttributePercent, PerTargetDebuffDamagePercent,
    AttackerCritChanceBonus, AttackerCritDamageBonus, CasterAttributeSnapshotPercent,
    IncomingHealReduction, TurnBarMovementDamagePercent,
}
@export var magnitude_kind: MagnitudeKind
@export var attribute_modifiers: Dictionary[Types.Attribute, float] = {}  # attribute -> sign
                                                             # (+1.0/-1.0); AttributePercent and
                                                             # AttributePercentagePointAdd only
@export var magnitude: float = 0.0                         # 0.0 = no static default; the
                                                             # applier sets the instance's value
                                                             # directly (e.g. Phalanx Guard)
@export var duration_default: int = 2
@export var overwritable: bool = true                       # re-apply refreshes duration
@export var stackable: bool = false                         # re-apply adds an independent instance
@export var applies_on_self_tick: bool = true                # has a genuine per-turn tick effect
                                                             # (DoT/HoT, self-tick Health cost, a
                                                             # re-rolled random attribute, a damage
                                                             # multiplier) — does NOT gate
                                                             # attribute_modifiers, which are always
                                                             # live (see below)
@export var applies_on_target_snapshot: bool = false          # vestigial: no longer read anywhere;
                                                             # kept only so the existing .tres
                                                             # resources don't need a values
                                                             # migration
@export var self_tick_max_health_cost_percent: float = 0.0    # extra self-tick Health cost,
                                                             # independent of magnitude_kind (Exhert)
@export var targeting_weight_multiplier: float = 1.0          # multiplies the holder's enemy-AI
                                                             # targeting priority, independent of
                                                             # magnitude_kind (Spotlight, 1.5x)
@export var icon: Texture2D
```

`StatusEffects.Buff`/`Debuff` (`Scripts/Battle/status_effects.gd`) carry the resolved per-instance
`value` (Empower/Fortify read `StatusEffectData.magnitude` by default; Phalanx Guard overrides it
per-rarity in `LancerTrait`). Debuffs resolve `value` the same way buffs do (`ApplyDebuff`/
`CastDebuff` default it to `data.magnitude`), so both buff and debuff read one instance value
instead of buffs reading `value` and debuffs reading `data.magnitude` directly. `ApplyBuff`/
`ApplyDebuff`/`_CastBuff`/`CastDebuff` (`StatusEffectResolver`, see
[Section 15.10](#1510-battle_resolvergd-growth-the-zoneresolver-and-statuseffectresolver-splits))
all resolve `stackable`/`overwritable` from the registry instead of the old
`Skills.OverwritableBuff`/`OverwritableDebuff` match statements.

**Attribute modifiers are always live, not sampled at two checkpoints.** Earlier, an
attribute-modifying status (`AttributePercent`/`AttributePercentagePointAdd`) was only folded
into a combatant's attributes at two gated moments: the holder's own turn
(`applies_on_self_tick`) and when the holder was directly targeted (`applies_on_target_snapshot`).
Every other combat read — debuff-resist rolls, redirected/soaked damage, trait/DoT damage, the
Temporal Leak DoT, turn-bar Speed — used a status-blind base value the rest of the time, so a
status held its effect only in those two moments instead of continuously for its whole duration.
`BattleResolver.GetEffectiveAttributes(character_ID)` is now the single source of truth for a
combatant's current attributes, and every combat read that needs "this character's attributes
right now" calls it. It composes five ordered contributor steps live on every call — order
matters, since the trait delta and status percentages both read the running total:

```gdscript
func GetEffectiveAttributes(p_character_ID: int) -> Dictionary[Types.Attribute, int]:
    var character: Character = _characters[p_character_ID]
    var attributes: Dictionary[Types.Attribute, int] = character.GetBaseAttributes()  # 1. base
    character.ApplyEquipmentBonuses(attributes)                                      # 2. gear
    character.ApplyTraitAttributeBonus(attributes)                                   # 3. trait
    _ApplyLongAttributeBonus(p_character_ID, attributes)                # 4. reagent long-bonus
    Skills.ApplyActiveAttributeModifiers(character, attributes)         # 5. active statuses
    return attributes
```

Each step is its own function rather than a pre-baked bundle: `Character.GetBaseAttributes()`,
`ApplyEquipmentBonuses()`, and `ApplyTraitAttributeBonus()` (steps 1–3) also compose into
`Character.GetTotalAttributes()`/`GetTotalAttribute()`, the accessor non-combat and
battle-setup reads use when no active statuses are relevant (max Health display, AI targeting
priority, initial turn-bar seeding). Step 3 asks `Character._trait` generically via
`CharacterTrait.GetAttributeDelta(attribute, running_value)` (default: 0, no contribution) —
`Character` has no graft-specific code path; `GraftEffect` is simply the one `CharacterTrait`
subclass that overrides it today. This keeps `Character` unaffected if a future non-graft trait
ever needs to contribute a static attribute delta. `Skills.ApplyActiveAttributeModifiers`
(step 5) replaced the old `Skills.TriggerTargetBuffs`/`TriggerTargetDebuffs` pair and the
attribute-modifier branches inside `StatusEffectResolver._TriggerExistingCasterBuffs`/`Debuffs`;
it folds every active attribute-modifying buff then debuff (plus any debuff weakness rider) into
the given attributes dictionary unconditionally — there is no gating flag. The old
`GetCombatAttributes()` (base + gear + graft + reagent, but never statuses) is retired; the few
combat-time sites that deliberately want the pre-status value (reagent %-scaling in
`_ApplyReagentAttributeIncrease`, so a semi-permanent bonus can't compound off a temporary buff;
`_SnapshotStatusValue`'s snapshot-at-application reads for `CasterAttributeSnapshotPercent` DoTs)
call `Character.GetTotalAttributes()` plus `BattleResolver._ApplyLongAttributeBonus()` explicitly,
so no accessor silently hides statuses again.

Base and gear (steps 1–2) are combat-static — nothing mutates a character's base sheet or gear
once combat is running — so they are a trivial memoization point if profiling ever justifies it.
`GetEffectiveAttributes` deliberately does not cache them: the call volume is tiny (turn-based,
at most six combatants), and caching would add resolver state plus a static-layer invariant to
maintain for no measurable gain. The trait delta (step 3) is not static — a Symbiote can graft
mid-battle — so it must stay live regardless.

Turn order and the turn bar's advance rate now also read live Speed:
`Battle.RefreshTurnBarSpeeds()` rebuilds the normalized speed ratios
(`TurnBar.RefreshSpeeds`/`NormalizeSpeeds`) from every living character's
`GetEffectiveAttributes(id)[Speed]`, called once at battle start and again each time a turn
completes back into `BattleState.Advancing` — never every frame, since statuses only change
during a turn's resolution.

`Skills.ApplyAttributeModifiers`, the low-level helper `ApplyActiveAttributeModifiers` calls per
status, loops `attribute_modifiers` instead of touching one hardcoded attribute (needed for
effects like Frenzy that move several attributes with mixed signs in one status).
`AttributePercentagePointAdd` adds `magnitude` directly instead of a percent of the current
value, for the crit stats (Keen Edge, Lethal Precision) where a percent-of-attribute reading
would be nearly meaningless at low Crit Chance values.
Zone-applied debuffs (e.g. the Lava zone's Burning) come from the placing `Skill`'s own
`ZoneEffect.debuffs`, read by `ZoneResolver.PlaceZone`, rather than being hardcoded in
`ZoneResolver._ResolveZoneEffect`.

Three magnitude kinds are read directly at their own application site instead of through
`ApplyActiveAttributeModifiers`: `MaxHealthAttributePercent` (Vigor) is summed by
`BattleResolver._MaxHealth()` from the holder's active buffs, with a reclamp of current health to
the new max when such a buff expires; `PerTargetDebuffDamagePercent` (Opportunist) and
`AttackerCritChanceBonus`/`AttackerCritDamageBonus` (Exposed Facet/Cracked Facet) are read in
`BattleResolver._ResolveDamage` — the former from the caster's own active buffs (scaled by the
target's debuff count), the latter from the target's active debuffs (added to the attacker's roll
for that hit only). Sequence Lock has no dedicated field: `ApplyBuff`/`ApplyDebuff`/`_CastBuff`/
`CastDebuff` block any status whose `attribute_modifiers` touches Speed when the target already
has an active `Sequence_Lock` debuff, generic over any current or future Speed-touching status.

The health-gain application point and three more self-contained magnitude kinds:
`BattleResolver._ApplyHeal` (mirroring `_ApplyHealthLoss`)
is the single site all healing flows through — reagent heals and Regeneration's self-tick alike —
and now returns the Health actually gained instead of void, since `IncomingHealReduction` (Blight)
halves the request there before the caller's `CombatResult.Kind.Heal` is built, keeping the
reported amount honest. `CasterAttributeSnapshotPercent` (Bleed, Attack; Plague, Mysticism) is
resolved once, at application, by `BattleResolver._SnapshotStatusValue()` — called from `CastDebuff`,
`ApplyDebuff`, and the zone path alike — into the instance's `value`, per the Phalanx Guard
per-instance precedent; the self-tick loop then just reads that already-resolved `value` instead of
re-deriving it from the source's current (possibly changed) attributes. Plague additionally spreads
to a random other living member of its own side when it expires (`BattleResolver._SpreadPlague`),
a dedicated per-type hook in the same spirit as the Sequence Lock block above — no other effect
needs "copy myself onto someone else on expiry" today. `TurnBarMovementDamagePercent` (Temporal
Leak) is the one magnitude kind with no self-tick or target-snapshot involvement at all: it is read
by the new public entry point `BattleResolver.AccumulateTurnBarMovement(character_ID, fraction_moved)`,
called every frame from `Battle.AdvanceTurnBar()` with the fraction `TurnBar.Update()` reports it
just advanced the character's marker by. The resolver accumulates fractional progress per holder
and deals damage scaled by the holder's live `GetEffectiveAttributes` Speed (so a Speed buff/debuff
changes the tick, not just the base sheet) each time `GameBalance.TURN_BAR_PROGRESS_TRIGGER_FRACTION`
(0.1) is crossed — the only application site backed by the view layer instead of purely resolver-internal
state, since turn-bar position is tracked in `TurnBar`, not the resolver; `TurnBar.Update()` and
`Battle.AdvanceTurnBar()` are thin unconditional pass-throughs, so the actual behavior stays in the
resolver and is tested without the view. `CombatResult.Kind.Burning_Tick` was renamed to
`Debuff_Tick` since Bleed and Plague now report through the same self-tick damage result Burning
used exclusively before.

`StatusEffects.Debuff` also carries a small but growing set of fields useful to only one trait
each, instead of every field being generic across all debuffs: `tick_bonus_per_debuff`
(Comorbidity) and the `has_weakness_rider`/`weakness_attribute`/`weakness_reduction` trio (the
Scholar's Field of Study, stamped in `OnDebuffApplied` onto whichever debuff triggered it, read by
`Skills.ApplyWeaknessRider` wherever `GetEffectiveAttributes` folds in active statuses, always
live) both sit unused on every debuff instance that isn't theirs. Fine at two, but this is a shape to watch — see FeatureIdeas.md's
"Watch Debuff Class Field Bloat" entry for the reassessment trigger.

The consumed and event-triggered effects: two more `MagnitudeKind` values
(`DamageAbsorb` for Barrier, `RandomAttributePercent` for Wanderlust) and three more
`CombatResult.Kind` entries (`Attack_Missed`, `Debuff_Blocked`, `Barrier_Absorbed`). The
consume-on-trigger buffs (Premonition, Deathward, Aegis, Rehearsed) each get one dedicated
resolver method checking their own trigger condition and calling the existing `RemoveBuff()` to
consume themselves, in the same spirit as `_BlockedBySequenceLock` and `_SpreadPlague` — no shared
"consumable" field, since each trigger site differs (an incoming hit, a fatal hit, a landing
debuff, a cooldown assignment). Barrier is read directly in `_ApplyHealthLoss` ahead of the normal
clamp, absorbing as much of an incoming loss as its per-instance `value` covers and consuming
itself when exhausted; its reapplication rule is the one exception to the standard
duration-refresh overwrite logic — `ApplyBuff`/`_CastBuff` special-case it to replace the existing
instance only when the new value is larger. Mirror Coat is wired only at `CastDebuff` (it needs a
real attacker): a debuff that lands on a Mirror Coat holder is rolled again, holder Accuracy vs.
attacker Resistance, and copied directly onto the attacker on success, the same direct-append
pattern as `_SpreadPlague` rather than a recursive `CastDebuff` call (which is what keeps mutual
Mirror Coat from looping). Overflow is an expiry hook collected the same way as Plague's spread,
dealing Mysticism-scaled damage (30%) to every living enemy through the existing
`ResolveTraitDamage` entry point when the buff's duration lapses. Wanderlust's
`RandomAttributePercent` case lives in the ordinary self-tick `match` block, picking one attribute
each tick via `ReagentResolver.RandomTinctureAttribute()` (the same random-primary-attribute pool
reagents already use) and applying it only to that turn's `p_caster_attributes` copy — never
written back to the `Character`, so the bonus does not persist. Mana Burn is cast-triggered, not
tick-triggered: `ResolveSkill` computes `is_non_basic := cast_skill.cooldown > 0` once and a
dedicated `_TriggerManaBurn()` call deals 30%-Mysticism-scaled self-damage whenever a Mana Burn
holder casts a non-basic skill; the same `is_non_basic` flag gates Rehearsed's cooldown skip.
Luck and Hexed wrap every existing roll site (`_ResolveDamage`'s damage-variance and crit-chance
rolls, `CastDebuff`'s two resist-roll components) through a new `_RollFavoring()` helper that
rolls twice and keeps the better or worse result for whichever character owns that roll; a holder
with both active cancels out to a single normal roll (user decision). `Skills.RollsCritical` is no
longer called by the resolver (replaced by `_RollFavoring` at the crit-chance site) but remains for
its own direct unit tests.

The turn-bar reactions and rule switches, the last of the status-effect catalog. Three more
`MagnitudeKind` values: `SelfTurnBarLossOnDamage` (Dead Weight), `AllyTurnBarGainOnDamage` (Battle
Orders), and `IncomingDamageReduction` (Spotlight, mirroring `IncomingHealReduction`), each read
directly at its own application site rather than through the generic self-tick loop. Every other
effect in this group is a pure rule check with no numeric payload —
`magnitude_kind = AttributePercent` (unused) and `applies_on_self_tick = false`, the convention
already established by Aegis/Sequence Lock/Rehearsed; Rush is the one exception, reusing
`AttributePercent` with the same `attribute_modifiers` set as Exhert (every attribute except
Health). A new `_EmitTurnBarBump()` is now the sole site that emits `CombatResult.Kind.Turn_Bar_Bump`
(replacing the two inline emissions in `ResolveSkill` and `_ResolveZoneEffect`'s Flicker Zone case):
it no-ops for a target holding Anchor, and blocks negative fractions for a target holding Steadfast.
`_ApplyHealthLoss` gained two more steps ahead of the existing Barrier absorption: `_DamageTakenMultiplier`
(Spotlight's `IncomingDamageReduction`, mirroring `_HealingMultiplier`) reduces the incoming amount,
and — once real Health is lost — `_TriggerDamageTakenReactions` fires Dead Weight's self-bump and
Battle Orders' ally-bump (excluding the holder) through `_EmitTurnBarBump`, uniformly for any source
of Health loss (attacks, DOT ticks, self-inflicted costs), not just attacker-dealt damage. Stun's
turn-skip needed a resolver entry point outside `ResolveSkill`: `ResolveStunTurn()` still ticks the
caster's existing buffs/debuffs (so Stun's own duration decrements and clears itself, and other
DOTs/heals still fire) and cooldowns/zones/`EndOfTurn`, but casts no skill, reporting a new
`CombatResult.Kind.Turn_Skipped`; `Battle.StartTurn` checks the active character's debuffs directly
(the same direct `_active_debuffs` access `EndBattle` already uses) rather than adding another
public resolver method, and a factored-out `Battle.CompleteTurn()` is shared between the stun-skip
path and the normal `ResolveTurn` tail. The cooldown-decrement loop that used to live inline in
`ResolveSkill` is now `_TickCooldowns()`, gated on Fatigue, and reused by `ResolveStunTurn()`; the
cooldown *assignment* for the skill just cast is untouched by Fatigue. Signed Writ is a single
shared `_RollsResistDebuff()` check (returns "not resisted" immediately for a Signed-Writ-holding
defender) used at both existing resist-roll sites, `CastDebuff` and `_TriggerMirrorCoat`, so a
holder can't resist a debuff regardless of whether it arrives directly or via a Mirror Coat
reflection. Severance is a blanket `_BlockedBySeverance()` check alongside `_BlockedBySequenceLock`
in `ApplyBuff`/`_CastBuff`, the same precedent as Sequence Lock's blanket block for Speed-touching
statuses. Warped is read once in `_ResolveDamage`: if the caster holds it, the triggering `DamageEffect`'s
`damage_scaling` weights are summed and collapsed into a single `{Mysticism: total_weight}`
dictionary before the aggregate calculation — damage only, per the catalog's own open question
about broader forcing. Refracted is read in the resolver's `FindSkillTargets` wrapper: a
Refracted caster's `Single_Enemy`/`Single_Ally` target type is overridden to `Random_One` before
delegating to `Skills.FindSkillTargets`, which already draws from both sides via
`CombatSides.RandomAliveMember`. Rush's expiry is collected the same way Overflow's is in
`_TriggerExistingCasterBuffs`, then `_TriggerRushStun()` direct-appends an unresistable 1-turn Stun
after the tick's other expiry hooks run. Zone interactions (Slipstream, Resonance) are read in
`ZoneResolver.TriggerZones` right before `_ResolveZoneEffect`: a Slipstream holder skips a matched zone entirely
(no effect, no duration decrement) when its owner is an enemy of theirs; otherwise `_ResolveZoneEffect`
runs twice instead of once when the character holds Resonance and the zone's owner is an ally — a
generic "double effect" that works for both Flicker Zone's turn-bar bump (two bumps sum) and Lava
Zone's stackable Burning (two independent instances) with no per-zone-type special-casing. Sanction
lands as a resource only (`gdlintrc`'s `max-public-methods`/`max-file-lines` bumped to
23/1250 for `battle_resolver.gd`'s growth): its
`attribute_modifiers`/`magnitude_kind` are wired but `magnitude = 0.0` (the applier sets the
instance value, the same "applier sets the instance's value directly" convention `magnitude`'s own
doc comment already describes, used today by Phalanx Guard/Bleed) since its magnitude source (the
Emissary's Infraction tally) is deferred. Catalyst Cloud (`Data/Character_Skill_Variants/Zone_Skills/Catalyst_Cloud.tres`)
applies the Catalyst buff; `BattleResolver.ResolveReagent` consumes it via
`StatusEffectResolver.ConsumeCatalystIfPresent`, adding its value to potency for scalar reagents
only, additively alongside the `Reagent_Consumed` trait hook and a brew's own potency bonus.

`ReagentData` (`Concept_Document.md` 3.3.3) is the reagent-system data model. The persistent
inventory, loot-drop acquisition, and in-battle combat consumption are all landed (see
`ReagentCollection` below, [Section 10](#10-collections-and-the-save-system), and
[Section 7.7](#77-reagent-consumption)).
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
Rewinding Grit, Second Wind Phial, Zone-Dissolving Salts, Chaotic Blessing, and Fractured Idol —
68 `.tres` files (17 families × 4 rarity tiers). Rewinding Grit targets one ally directly
(`One_Ally`) and reduces the cooldown of every skill that ally has currently on cooldown, rather
than requiring a skill-choice target kind. Reagents still deferred until their blocking mechanic
lands: Barrier Stone, Deathward Charm, Chant Fragment, Notarized Seal, Wayfarer's Draught, and the
Alchemist brew pool.

### 6.2. Runtime instances

- `Character` (`Scripts/Character/character.gd`, `extends RefCounted`) is built from a `CharacterPreset`
  via `InstantiateNew(preset, instanceID)`. It copies preset stats into an
  `_attributes: Dictionary[Types.Attribute, int]`, picks a random `AttributeWeightPreset` from
  those the preset allows, duplicates the trait, and stores `_preset_path` for later save/restore.
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
   and applies adventure buffs/debuffs through `resolver.GetStatusResolver().ApplyBuff`/`ApplyDebuff`.
4. Computes `_targeting_order` via `SetTargetingOrder()` — characters sorted by
   `Health + Defence` descending (used by enemy AI to pick "tankiest valid" targets).
5. Instantiates enemies into `_characters[3..5]`, jitters their speed by `randi_range(-3,3)` on
   the **resolver's** generator, and scales them to the encounter difficulty with
   `LevelSystem.SetOpponentLevel()` (boss variant if `_arguments["Boss_Scale"]` is present).
6. Fires each character's `StartOfBattle` trait hook (logic reset only), then unconditionally
   calls `trait.BrewReagentKey()`/`GetBrewPotencyBonus()` — a no-op for every trait except the
   Alchemist's Fresh Batch, which adds a brewed slot to `_reagent_loadout` here (section 7.7) —
   and paints the initial trait visuals via `trait.RefreshVisuals(repr)`, then initializes the
   battle UI and turn bar.

### 7.2. Turn order (the turn bar)

`Scripts/UI/Battle_UI/turn_bar.gd` advances each character along a horizontal bar every frame.
Each character's progress increases by `base_velocity * normalized_speed * delta`, where
`base_velocity = bar_width / TURN_DURATION_SECONDS` and `normalized_speed = speed / highest_speed`.
When a character reaches the right edge, the bar reports that ID as the active turn.

`Battle._process` drives this only in the `Advancing` state: it calls `turn_bar.Update()` for
every living character until `GetActiveTurnID()` returns a non-`-1` ID, then calls `StartTurn()`.
`turn_bar.Update()` also returns the fraction of the bar's width that character just moved (`0.0`
while it is already someone's turn); `Battle.AdvanceTurnBar()` forwards any non-zero fraction to
`resolver.AccumulateTurnBarMovement()`, the only place turn-bar position feeds back into the
resolver outside the `TurnPositions` queries (see section 6.1's Temporal Leak note).

The turn bar is still both state and view: zone occupancy and Plan-trait reach are positional
questions only it can answer. The resolver reaches them through the **`TurnPositions`** interface
(`Scripts/Battle/turn_positions.gd`) — `IsCharacterInZone` and `GetCharactersBehindBy` — with
`TurnBarPositions` (`Scripts/UI/Battle_UI/turn_bar_positions.gd`) adapting the live node and the
base class doubling as the headless default for tests. Long term the positions belong in the core.

### 7.3. Taking a turn (`StartTurn` and the state machine)

- Positions the turn indicator over the active character and calls `resolver.BeginTurn(ID)`,
  which fires the `StartOfTurn` trait hook (e.g. the Plan trait's reach-based Empower).
- If the active character holds Stun, `StartTurn` calls `resolver.ResolveStunTurn(ID)` (still ticks
  their own statuses and cooldowns/zones, but casts no skill) and completes the turn immediately via
  `CompleteTurn()`, skipping skill-button population and enemy-turn handling entirely.
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

1. Read the caster's live attributes via `GetEffectiveAttributes()` (base + gear + graft + any
   battle-long reagent attribute bonus + active statuses, see section 6.1).
2. Fire the `OnSkillCast` trait hook → returns a `TraitSkillResult` carrying a damage multiplier
   and turn-bar bump.
3. Tick the caster's own active debuffs and buffs — per-turn effects (e.g. Burning deals 4% of
   max HP, reported as a `Debuff_Tick` result with a per-source damage split; Regeneration heals
   4% of max HP, reported as `Heal`) and duration decrements (reported as `Status_Duration` /
   `Statuses_Removed` results). Attribute modifiers are no longer applied here — they were already
   folded in at step 1.
4. Compute this cast's use count (`_SkillUseCount`, per (caster, skill name), read by
   `DamageEffect`'s ramp and `AlternatingEffect`'s rotation), build a `SkillCastContext`, then run
   the skill's own effects:
   ```gdscript
   var context := SkillCastContext.new(self, caster_ID, target_IDs, cast_skill, caster_attributes,
           use_count, trait_result)
   for effect in cast_skill.effects:
       if(context.ConditionMet(effect)):
           effect.Resolve(context)
   ```
   `ResolveSkill` knows nothing about effect kinds — see "The effect loop and cast context" below.
5. `ResolveEffectDamage` (called by `DamageEffect`, above) folds per-target attribute reads,
   `OnDefend`, mitigation, and death handling into one entry point, so step 4's loop is also where
   damage lands and targets die — there is no separate per-target damage step after the loop.
6. For each of the cast's original targets still present: bump them on the turn bar by the
   *trait's* `_turn_bar_bump` only (`Turn_Bar_Bump`) — a skill's own turn-bar contribution is a
   `TurnBarEffect` inside the loop above, resolved independently. The two never combine into one
   result: a skill whose caster's trait already bumps the turn bar (step 2) and which also carries
   its own `TurnBarEffect` reports two separate `Turn_Bar_Bump`s rather than their sum, so a
   sign-gating trait (Anchor, Steadfast) or `Skills.TurnBarTithe` sees each independently.
7. Decrement all of the caster's cooldowns and set the used skill's `cooldown_left = cooldown`.
8. Run `GetZoneResolver().TriggerZones()` and fire the `EndOfTurn` trait hook. Because a `ZoneEffect`
   placement already happened inside step 4's loop, a zone placed this same cast can immediately
   trigger here if a character other than the caster already occupies its section (see
   [Section 7.5](#75-zones)).

**The effect loop and cast context.** `SkillCastContext`
(`Scripts/Battle/Skill_Effects/skill_cast_context.gd`, `RefCounted`) carries the read-only inputs
every effect needs (`resolver`, `caster_ID`, `target_IDs`, `skill`, `caster_attributes`,
`use_count`, `trait_result`) plus two accumulators effects write for later effects in the same cast
to read: `health_paid` (written by a cost-phase `HealthChangeEffect`, read by a later
`BarrierEffect`) and `buffs_consumed` (written by `ConsumeBuffsEffect`, read by a later
`DamageEffect` scaling off `Trait_Count_Source.Buffs_Consumed`). This is a deliberate, visible
coupling channel — it does not remove ordering-dependence between effects, it makes it explicit
and author-controlled instead of implicit in resolver structure. `TargetsFor(effect)` resolves one
effect's target group (`Skill_Default` reuses the skill's own targets, filtered to characters still
alive); `ConditionMet(effect)` answers the base class's `condition`/`condition_test`/
`condition_threshold` fields by reading `CharacterTrait.GetConditionCount` (see
[Section 9](#9-trait-hook-system)) for the primary target.

A `Skill`'s `effects` are authored data, deep-copied per character instance the same as any other
`CharacterPreset` field — an effect resource must stay stateless. Per-battle state that persists
across casts (use counts, alternation position) lives on the resolver instead: `_skill_use_counts`,
keyed by `(caster_ID, skill name)`, is what `DamageEffect`'s ramp and `AlternatingEffect`'s rotation
both read via `SkillCastContext.use_count`.

**Canonical effect order.** A skill's `effects` array should be authored
**costs → buff manipulation → statuses → damage → heals** — an authoring convention the pipeline
does not enforce (a mis-ordered `.tres` is a silent behaviour bug, not a compile error), asserted
for two skills by `Tests/unit/test_skill_effect_order.gd`. Heals resolving last is deliberate:
Fateful Glimpse authors `[DamageEffect, HealthChangeEffect]`, so its `Most_Injured_Ally` heal
target is chosen *after* its own damage has landed — including any `GlassRefractionGraft` backlash
the hit triggered on the caster. That is the intended reading, not an artifact of migration.

**Unified damage bonuses and the Combined_Modifier channel.** `DamageEffect.bonus_per:
Dictionary[Types.Trait_Count_Source, float]` replaces what used to be four separate
fraction-times-count mechanisms; the bonus is `fraction × Count(source)`, so a binary condition
(`Trait_Condition`) folds in as count 0 or 1. Every damage-relevant multiplicative contribution —
`bonus_per`, a caster's trait-resource multiplier, buff- and reagent-sourced damage bonuses — is a
contribution to `CombinedDamageModifier` (`Scripts/Battle/combined_damage_modifier.gd`, `RefCounted`), the
multiplicative channel from Concept Document 1.1.3-1.1.4: `Contribute(key, fraction)` adds into
`key`'s bucket, and `Product()` returns `Π over keys (1 + bucket[key])`. Contributions sharing a
key add; distinct keys multiply. Keys are mechanic identity (buff type, debuff type, trait
resource, skill name), never character identity, so which champion supplied a contribution never
changes the result. A `CombinedDamageModifier` is built fresh for one damage resolution and discarded
with it — never cached on a character, a skill, or the resolver — so a cascade's repeat instances
each read live conditions rather than a stored product.

`Uses_This_Battle` is the one exception with its own bucket rather than joining the skill's
additive one: it scales the caster's pre-mitigation damage aggregate as a ramp, and keeping it
separate preserves the same multiplicative relationship to the skill's other contributions that
existed before unification. Folding the ramp into the same additive bucket instead would have cost
Heap On, Breaching Charge, and Cinder Sermon between 5% and 26% of their ramped damage, growing
with both use count and target Defence, because the ramp's pre-mitigation placement also improves
Defence penetration (mitigation rises with attack size, so `mitigation(S) < mitigation(S·R)`).
Every other `bonus_per` source (`Buffs_On_Caster`, `Buffs_Consumed`, `Trait_Condition`,
`Trait_Counter_On_Target`, `Trait_Counter_Raw_On_Target`) sums into one bucket keyed to the skill.
`bonus_per_debuff_on_target` contributes one independent bucket per debuff type present on the
target, rather than one summed lump, so satisfying a further target debuff multiplies the result.

The implemented damage formula (`BattleResolver._ResolveDamage`):

```
combined_damage_modifier.Contribute(...)  # DamageEffect's own contributions, seeded before the call
combined_damage_modifier.Contribute(trait_outgoing_bonus, CharacterTrait.GetOutgoingDamageBonus(...))
combined_damage_modifier.Contribute(reagent_damage_bonus, damage_dealt_bonus[caster])
combined_damage_modifier.Contribute(damage_multiplier_buff, damage_multiplier[caster] - 1.0)
combined_damage_modifier.Contribute(opportunist_buff, OpportunistDamageMultiplier(caster, target) - 1.0)
caster_scaled = (Σ over attrs ( damage_scaling[attr] * caster[attr] )) * combined_damage_modifier.Product()
effective_defence = defender.Defence * defense_ignore_factor
damage_ratio = caster_scaled / (effective_defence + caster_scaled + 1)
mitigation = MINIMUM_DMG_PERCENT + (1 - MINIMUM_DMG_PERCENT) * damage_ratio
crit (if rng.randi(1..100) <= CritChance): max(MINIMUM_CRIT_DAMAGE, CritDamage - defender.Knowledge*0.5) * 0.01
damage = mitigation * caster_scaled * crit * rng.random(0.95..1.05)
```

`damage_scaling` and `defense_ignore_factor` are the triggering `DamageEffect`'s own fields.
`GetOutgoingDamageBonus` (an always-on trait effect — its one live override is `BloodscentGraft`'s
target-Health-based bonus/penalty) and `damage_dealt_bonus[caster]` (the battle-persistent
reagent/graft bonus, e.g. `GlamourGraft`) are resolver-owned contributions added on top of whatever
`DamageEffect` already seeded the modifier with; they are not folded back into
`damage_dealt_bonus[caster]` itself. Citation's Infraction-rate scaling, for example, is entirely
`bonus_per = {Trait_Counter_On_Target: 1.0}` on its `DamageEffect`: the skill states *that* it
scales off the target's Infraction tally, `StandingRecordTrait.GetConditionCount` supplies the
rate, and no shared code names Infractions (Concept Document 3.1.3: "skills state what scales,
never their own rate"). `CombatResult` carries the assembled `CombinedDamageModifier` on `Kind.Damage`
results for attribution, unconsumed by any presentation code yet.

Status effects are capped at `MAX_STATUS_EFFECTS` (8) per character; Burning is non-overwritable
while the others refresh duration. The resolver assigns each applied status a battle-unique ID
(carried on `Status_Applied` results); the scene maps those IDs to the representation's icon slots
when rendering.

### 7.5. Zones

`Zone` (`Scripts/Battle/zone.gd`) is a persistent effect placed on a turn-bar section, matching
`Concept_Document.md` 3.2.4.1: zones hold **charges**, not a duration, and a character is affected
**once per visit** — not again until they leave the section and re-enter it.

```gdscript
var _charges: int = -1                        # -1 = infinite
var _owner_ID: int
var _target: Types.Skill_Target                # ZoneAll / ZoneAlly / ZoneEnemy
var _owner_knowledge: int = 0                   # snapshotted at placement, see below
var _owner_attributes: Dictionary[Types.Attribute, int] = {}  # full snapshot, see below
var _on_trigger: Array[SkillEffect] = []        # the zone's effect, as ordinary skill-effect data
var _visual_scene: PackedScene
var _affected_since_entry: Array[int] = []      # character IDs already affected this visit
var _source_name: String = ""                   # placing skill, or graft/trait; see below
```

**Placement.** A `ZoneEffect` (see [Section 6.1](#61-resource-templates)) is an ordinary
`SkillEffect`: its `Resolve` picks a turn-bar section per its `section` mode
(`Player_Chosen` reads a pending section the UI set via `BattleResolver.SetPendingZoneSection`,
consumed once by `ConsumePendingZoneSection`, falling back to random if none is pending — e.g. an
enemy AI cast; `Left_Most_Empty` / `Random_Empty` pick from `ZoneResolver.AvailableZoneIDs()`
directly) and calls `ZoneResolver.PlaceZone(zone_ID, owner_ID, zone_effect, target,
owner_attributes, source_name)`, which snapshots the owner's full effective attributes
(`BattleResolver.GetEffectiveAttributes`, not only Knowledge) and reports `Zone_Placed`. Because
`ZoneEffect` is just one effect among a skill's `effects`, a skill can place a zone *and* do
something else in the same cast (Inscribe: a direct `DamageEffect` at the skill level plus a
`ZoneEffect` placing a Wild Glyph). An already-occupied target section is a silent no-op for
`Player_Chosen`/explicit picks and for `Left_Most_Empty`/`Random_Empty` when the bar is full — the
rest of the skill's effects still resolve. `battle.gd`'s `Selecting_Zone` state carries a
`_clearing_zone_mode` flag rather than a separate state: the same turn-bar click handler validates
against an empty section for a placement and an occupied one for a `ClearZoneEffect` (Refutation),
picking the zone ID the effect consumes the same way either way.

**Triggering.** `ZoneResolver.TriggerZones(active_ID)` runs at the end of every `ResolveSkill`
(including the one that just placed a zone, so a section already occupied when the zone lands
triggers immediately — see [Section 7.4](#74-skill-resolution-battleresolverresolveskill) step 8).
For every living, non-active character standing in a zone (`TurnPositions.IsCharacterInZone`) whose
side matches the zone's `ZoneAll`/`ZoneAlly`/`ZoneEnemy` target (`Skills.CorrectZoneTarget`) and who
is not already recorded in `_affected_since_entry` this visit, `_ResolveZoneEffect` builds a
`SkillCastContext` (`caster_ID` = the zone owner, `target_IDs` = `[affected_ID]`, the snapshotted
owner attributes, `is_zone_trigger = true`, `zone_target` / `zone_ID` / `zone_magnitude` /
`zone_source_name` set) and
walks `zone._on_trigger` through the same `ConditionMet` / `Resolve` loop as any skill's own
`effects` — a zone's effect is ordinary `SkillEffect` data, not a hardcoded match on a zone kind.
`ApplyBuffEffect`/`ApplyDebuffEffect` snapshot their status value from `StatusEffectRegistry` scaled
by `zone_magnitude` when triggered this way (see Knowledge scaling below) and set
`context.status_effect_attempted`/`status_effect_landed`, so `ZoneResolver` can skip the
`Zone_Affected` hook when a status was attempted but blocked (status cap, Aegis). An effect can
override its own `target` (`ZoneAlly`/`ZoneEnemy`) independently of the zone's own target — Unstable
Rift's zone is `ZoneAll` but authors two `DamageEffect`s, one `target = ZoneEnemy` at 30%, one
`target = ZoneAlly` at 15%, so both sides are affected by the same trigger but scaled differently.

Each trigger decrements the zone's charges by one and reports `Zone_Triggered`; a zone reaching zero
charges is cleared and reports `Zone_Cleared` (the same result a natural expiry and a
`ClearZoneEffect` clear both route through — there is no silent-free path). Before the per-character
pass, any character `_affected_since_entry` records for a zone they are no longer standing in is
forgotten (`_ForgetDepartedVisitors`) — that is the "left the section" edge that allows a fresh
trigger on re-entry. At most one zone fires per character per round (`break` after the first zone
that matches), and the number of live zones is capped at `NUMBER_OF_TURN_BAR_ZONES` (5). Slipstream
lets an ally pass through an enemy's zone untriggered; Resonance triggers an ally's own zone twice
(for one charge) on the character carrying it.

**Knowledge scaling.** When a zone is created, the placing character's full effective attributes
are snapshotted (`_owner_attributes`, `_owner_knowledge` for convenience). Later attribute changes on
that character do not retroactively affect the zone. Every zone-triggered effect's magnitude is
scaled by `context.zone_magnitude`, set once per trigger to
`Skills.ZoneMagnitude(1.0, owner_knowledge) * trait.GetIncomingZoneEffectMultiplier(...)`:

```
ZoneMagnitude = base * (1.0 + owner_knowledge * ZONE_KNOWLEDGE_SCALING)
```

`ZONE_KNOWLEDGE_SCALING` is `0.005` (+0.5% per point of Knowledge). Unlike the old model, this
applies uniformly regardless of which side is affected — `TurnBarEffect`, `ApplyBuffEffect`,
`ApplyDebuffEffect`, and `BarrierEffect` (via `BarrierZoneEffect`/`Skills.ApplyBarrierZone`) all
multiply by `zone_magnitude`, which is `1.0` outside a zone trigger, so non-zone casts are
unaffected. `GetIncomingZoneEffectMultiplier` (default `1.0`) lets a character's own trait amplify
or dampen what they receive from *any* zone, independent of the owner's Knowledge (e.g.
`RootfeederGraft` at 150% against enemy-owned zones).

**Visuals.** `ZoneEffect.visual_scene` is an exported `PackedScene`, resolved when the `.tres` loads
at battle setup; `SpawnZoneEffect` only pays `instantiate()`, no per-placement `load()`. The three
lore families the Concept Document describes (order / unstable / momentum) are expressed by which
scene a zone authors, not by an enum — there is no zone-kind enum left in `Types` at all. The six
Batch 5 zone-carrying skills (Catalyst Cloud, Unstable Rift, Temporal Sinkhole, Miasma, Weight of
Law, Inscribe's Wild Glyph) all point at `Turn_Bar_Flicker.tscn` as a placeholder visual — bespoke
scenes per the three lore families are follow-up art work, not yet built.

**Clearing.** Besides natural expiry, `ClearZoneEffect` (Refutation) is the other dedicated removal
path (Concept 3.2.4.1: "Zones are removed only by dedicated clearing effects... There is
deliberately no universal zone-clearing skill"). It resolves a section the same way `ZoneEffect`
does for `Player_Chosen` (the pending-section channel) or picks a random occupied one for an AI
cast, then clears it and either damages the placing enemy (`damage_scaling_per_charge` × charges
remaining, via `BattleResolver.ResolveEffectDamage`) or reduces the placing ally's zone skill's
`cooldown_left` — found by matching `Zone._source_name` against the owner's `_skills`, which
is why `PlaceZone` threads the casting skill's name through from `ZoneEffect.Resolve`
(`p_context.skill.name`); the grafts/traits that construct a `ZoneEffect` directly rather than
through a cast skill (Living Bloom, Calibration's Raise the Frame) pass their own name instead,
which matches no skill and so is a no-op here — it still identifies the zone for
`CombinedDamageModifier` keying (Section 7.4). A reagent-consumed clear (`ReagentData.EffectKind.Clear_Zone`)
is a separate, simpler path straight to `ZoneResolver.ClearZone` with no damage/refund branch.

### 7.6. Ending combat

`BattleResolver.IsTheBattleOver()` returns `Player_Won` / `Monsters_Won` / `Ongoing` by scanning
team aliveness. `Battle.EndBattle()` enters `Battle_Over`, records the result in `_arguments`, and
on victory: computes the loot budget (`LootManager.CalculateBudget`), distributes rewards
(`LootManager.DistributeRewards`), adds any dropped equipment to the `ItemCollection`, awards
experience via `LevelSystem.AddExperience`, restores player HP, then transitions to the
post-battle scene through `main.GetInstance().change_scene()`. The resolver (and all its
per-combat state) is simply discarded with the scene — there is no global state to reset.

### 7.7. Reagent consumption

Reagents (`Concept_Document.md` 3.3.3) apply through a resolution path parallel to, but
independent of, `ResolveSkill` — consuming a reagent is a **free action**: it never ticks a
cooldown, never fires `Start_Turn`/`End_Turn`, and never advances the turn bar.

- **Loadout.** `Pre_Battle_Menu` writes up to 3 chosen reagent registry keys to
  `ContextContainer._battle_reagents`. `Battle.Init()` wraps them in a
  `ReagentLoadout` (`Scripts/Battle/reagent_loadout.gd`, `RefCounted`) — a small class kept
  independent of the `Battle` scene node specifically so once-per-battle enforcement and
  inventory deletion are unit-testable headlessly. `ReagentLoadout.TryConsume(index,
  reagent_collection)` marks an entry spent and calls `ReagentCollection.Consume()`
  immediately (so a mid-battle defeat still keeps it consumed); unused entries need no
  "return to inventory" step, since they were never debited from the collection at
  loadout-selection time in the first place.
- **Resolution core.** `BattleResolver.ResolveReagent(consumer_ID, reagent_key, target_ID,
  extra_potency := 0.0)` starts potency at `1.0 + extra_potency`, then fires the consumer's
  `Reagent_Consumed` trait hook (binary reagents never call it — see section 9) for an
  additional additive contribution — all potency modifiers (a trait's own amplification, the
  brewed slot's potency bonus, future battle-long modifiers) stack additively on one
  consumption (`Concept_Document.md` 3.3.3). It then dispatches on `ReagentData.effect_kind` to
  `_ResolveReagentEffect`. The per-kind math (percent-to-fraction conversion, potency scaling,
  the random-Tincture-attribute roll, the flat-value `Barrier` scaling) lives in
  `ReagentResolver` (`Scripts/Battle/reagent_resolver.gd`), stateless static functions
  mirroring `skills.gd`'s style; `BattleResolver` applies the result and reports it as
  `CombatResult`s.
- **Brewed slot (the Alchemist's Fresh Batch).** `ReagentLoadout` carries parallel `_brewed` and
  `_potency_bonus` arrays alongside its keys/spent flags. `AddBrewed(key, potency_bonus)`
  appends a slot beyond the three brought reagents; `TryConsume` skips
  `ReagentCollection.Consume()` for a brewed slot, so it never touches the persistent
  inventory and is simply lost if unconsumed when the battle ends. `Battle.gd` passes
  `_reagent_loadout.PotencyBonusAt(index)` as `ResolveReagent`'s `extra_potency` on consumption,
  so the bonus travels with the slot rather than the consumer — any champion can spend a brewed
  reagent, and the Alchemist's own rarity (fixed at brew time) still sets its potency.
  `ReagentData.brew_only` marks the four brew-pool reagents (`Data/Reagents/Alchemist_Brews/`)
  so `ReagentRegistry.GetRandomKeyForRarity` (ordinary loot rolls) never returns one.
- **Battle-long mechanisms.** Two effects persist for the rest of the battle without being a
  `StatusEffects.Buff` (undispellable, unstealable, invisible to buff-counting):
  `_battle_long_attribute_bonus` (Tinctures — folded into
  `GetEffectiveAttributes()` via `_ApplyLongAttributeBonus()`) and `_damage_dealt_bonus` (Fractured Idol — folded into
  `_ResolveDamage` via `Skills.DamageDealt`). Both are plain resolver-owned dictionaries
  that disappear with the resolver at battle end, needing no explicit cleanup.
- **Deferred turn-bar reset.** Second Wind Phial's reset can't apply at consumption time
  (the consumer's turn hasn't ended yet), so `ResolveReagent` reports a
  `Turn_Bar_Reset_Pending` result instead; `Battle` stores it in a local dictionary and
  consults it at the one call site where `TurnCompleteForCharacter` actually resets the bar,
  passing the stored percent instead of the default 0.
- **Battle scene wiring.** `BattleUI` exposes up to 4 `ReagentButton`s (the fourth for a brewed
  slot, shown only when one exists) — a simpler sibling of
  `SkillButton` — no cooldown countdown, just an available/permanently-spent state via
  `MarkSpent()`), shown alongside the skill buttons on the player's turn. Selecting one
  branches on `ReagentData.target_kind`: `Self_Target` resolves immediately; `One_Ally`/
  `One_Enemy` enters a new `BattleState.Selecting_Reagent_Target` that reuses the existing
  character-click signal (`_on_character_battle_target_selected`); `Zone_Section` enters
  `BattleState.Selecting_Reagent_Zone` and reuses the turn bar's zone-click callback,
  requiring an *occupied* zone (the opposite condition from skill-driven zone placement,
  which requires an empty one). Resolution always returns `_state` to
  `Awaiting_Player_Input` rather than routing through `ResolveTurn` — the defining trait of
  a free action.

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
`BattleResolver` they receive (`GetStatusResolver().ApplyBuff`/`RemoveBuff`, `EmitTraitText`,
`GetRandom`, `GetTurnPositions`, …), never through UI types:

| Hook | `Combat_Event` | Fired when… | Returns |
|---|---|---|---|
| `StartOfBattle(owner_ID, resolver)` | `Start_Combat` | during `Battle.Init`, once per character (logic reset) | — |
| `StartOfTurn(owner_ID, resolver)` | `Start_Turn` | in `BeginTurn` for the active character | — |
| `EndOfTurn(owner_ID, resolver)` | `End_Turn` | at the end of `ResolveSkill` | — |
| `OnSkillCast(owner_ID, target_IDs, skill_name, caster_attributes, resolver)` | `Skill_Cast` | at the start of `ResolveSkill` | `TraitSkillResult` |
| `OnDefend(defender_ID, defender_attributes, characters)` | `Defend` | when snapshotting a target's attributes | — |
| `OnDamageTaken(owner_ID, resolver)` | `Damage_Taken` | before damage lands; returns the incoming-damage multiplier | `float` |
| `OnDeath()` | `On_Death` | when a character drops to 0 HP (logic reset) | — |
| `OnReagentConsumed(consumer_ID, reagent, resolver)` | `Reagent_Consumed` | in `ResolveReagent`, for non-binary reagents only; returns an additive potency contribution (0.0 base) | `float` |
| `OnCriticalHit(owner_ID, target_ID, resolver)` | `Critical_Hit` | in `_ResolveDamage`, after a critical hit lands, on the caster's trait | — |
| `OnDamageDealt(owner_ID, target_ID, amount, resolver)` | `Damage_Dealt` | in `_ResolveDamage`, after damage lands (unconditionally, not only on a crit), on the caster's trait | — |
| `OnAllyDeath(owner_ID, dead_ally_ID, resolver)` | `Ally_Death` | in `_HandleDeath`, on every living ally of the character who just died | — |
| `OnAllyDamageTaken(owner_ID, damaged_ally_ID, resolver)` | `Ally_Damage_Taken` | in `_ResolveDamage`, polled on the target's living allies before mitigation; returns the fraction of the incoming hit this owner redirects to itself (0.0 base) | `float` |

`StartOfBattle`'s `owner_ID`/`resolver` parameters were added specifically so traits can subscribe
to resolver signals (`resolver.result_produced`) or mark battle-start state (e.g. the Cultist's
Vessel) before the character's own first turn — a lazily-initialized equivalent would miss events
that fire before then.

One **view hook** complements them: `RefreshVisuals(character_repr)` repaints the trait's icons,
tooltips, and battlefield effects (e.g. sprite echoes) from current trait state. The battle scene
calls it after `StartOfBattle` and after every resolved action; the resolver never does.

A concrete trait subclasses `CharacterTrait`, registers the events it cares about in
`_execution_steps`, and overrides the matching hooks. Callers always guard with
`_trait._execution_steps.has(<event>)`, so a trait only pays for the hooks it opts into.

Two hooks sit outside the `_execution_steps`/`Combat_Event` dispatch entirely and are called
unconditionally on every character's trait, relying on a no-op base-class default instead of an
opt-in guard: `BrewReagentKey(random) -> String` and `GetBrewPotencyBonus() -> float`, called once
per character during `Battle.Init`'s `StartOfBattle` loop so the Alchemist's Fresh Batch passive
can add a brewed slot to the `ReagentLoadout` (section 7.7) without `Battle.gd` needing an
Alchemist-specific branch.

`OnSkillCast` returns a `TraitSkillResult`
(`Scripts/Character/character_traits/TraitHookResults/trait_skill_result.gd`) carrying a
`_damage_multiplier` and `_turn_bar_bump`, which `ResolveSkill` folds into the damage and turn-bar
calculations. Example: the Tidal Corsair trait
(`Scripts/Character/character_traits/CharacterSpecificTraits/tidal_corsair_trait.gd`) accumulates
stacks as skills are cast and, on its finisher, consumes them to return amplified
damage/turn-bar values.

Traits that deal damage outside the casting skill's own resolution (e.g. the Sorcerer's Surge,
`Scripts/Character/character_traits/CharacterSpecificTraits/sorcerer_trait.gd`) call
`BattleResolver.ResolveTraitDamage(caster_ID, target_IDs, caster_attributes, damage_scaling,
allow_critical := true)`. It calls `_ResolveDamage` directly with the given `damage_scaling`
dictionary (no `Skill` or `DamageEffect` involved) and routes each target through the same
mitigation, `Damage_Taken` hook, and death handling as normal skill damage — `allow_critical =
false` skips the crit roll without touching any other part of the shared path, so a trait effect
can never crit while still mitigating and killing normally.

**Buff manipulation:** two more unconditional query getters, the same category as
`GetOutgoingDamageBonus`/`GetIncomingDebuffDurationBonus` above.
`CharacterTrait.GetAppliedStatusValue(owner_ID, target_ID, debuff_type, resolver) -> float`
(default `-1.0`, no opinion) is read in `ApplyDebuffEffect.Resolve` before a debuff is cast; a
non-negative return becomes the new debuff's value instead of the usual snapshot/template value.
`StandingRecordTrait` overrides it for `Sanction` only, returning
`GetInfractions(target_ID) * _rate_per_infraction` — this is Sanction's magnitude source
(section 3.2.3.2) going live; every other debuff type still falls through to the existing
`_SnapshotStatusValue` path.

`CharacterTrait.GetConditionCount(owner_ID, target_ID, source: Types.Trait_Count_Source,
resolver) -> float` (default `0.0`) is the shared answer to two different questions: a
`DamageEffect`'s `bonus_per` count (see [Section 7.4](#74-skill-resolution-battleresolverresolveskill))
and a `SkillCastContext.ConditionMet` condition test. It has no opinion of its own on which source
it is answering — a concrete trait matches on `source` and returns 0 for anything it does not
recognize. `StandingRecordTrait` (Citation, Signed Writ) answers two:
`Trait_Counter_On_Target` (Infraction count × the trait's own rarity-scaled rate — the skill
states *that* it scales, never the rate) and `Trait_Counter_Raw_On_Target` (the plain Infraction
count, always what `Skill_Condition`'s member of the same name reads, regardless of which
`Trait_Count_Source` member shares its name); it returns 0 for `Trait_Condition`, which is instead
answered by the Jester's `DoubleTheFunTrait`, tracking `_avoided_since_last_turn` — set on a
successful avoidance and cleared on the Jester's own `End_Turn` — for Pratfall Sting's conditional
bonus.
Both getters are consulted from inside the effect loop (see
[Section 7.4](#74-skill-resolution-battleresolverresolveskill)), not gated by `_execution_steps`,
the same "always polled" shape as the rest of this getter family.

---

## 10. Collections and the save system

### 10.1. Collections

`CharacterCollection` (`Scripts/Character/character_collection.gd`) and `ItemCollection`
(`Scripts/Gear/item_collection.gd`) are `Node`s owned by `Main_Instance`. Each holds a dictionary
keyed by an auto-incrementing instance ID (`Dictionary[int, Character]` / `Dictionary[int, Equipment]`)
and exposes `Serialize()` / `Deserialize()`.

`ReagentCollection` (`Scripts/Gear/reagent_collection.gd`) is likewise owned by `Main_Instance`
and in the saveable group, but holds a `Dictionary[String, int]` of owned counts keyed by the
`ReagentRegistry` identifier string rather than an instance-ID dictionary, since reagents are
fungible (no per-instance state). `Deserialize` tolerates both pre-reagent saves (missing data)
and stale keys no longer in `ReagentRegistry.REAGENTS`.

### 10.2. Save format and ordering

`SaveManager` (`Scripts/Worldview/save_manager.gd`) implements **group-based serialization**.
Saveable nodes join the `"saveable"` group (`GROUP_SAVEABLE`); on `Save(slot)` the manager walks
the group, calls each node's `Serialize()`, attaches a metadata block, and writes the whole thing
as JSON to `user://profile_<slot>.save`.

`Load(slot)` parses the JSON and deserializes with a deliberate ordering constraint: **items load
before characters**, so that gear referenced by a character's `_held_items` already exists in the
`ItemCollection` when the character is restored. `_deserialize_group_by_type` is used to force this
order, and remaining saveable nodes are deserialized afterward.

What persists: per-character `_preset_path`, level, experience, attributes, and held-item IDs;
per-item slot/rarity/attributes; plus resource and adventure state. On load, characters are
rebuilt from their preset's `res://` path and then have their saved progression re-applied.

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
./Tests/run_tests.sh
```

`Tests/run_tests.sh` wraps the `gut_cmdln.gd` invocation and filters its output down to
GUT's run summary; see `Test_Design_Document.md`.

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

### 9.2. The Graft passive: `GraftEffect`

`GraftEffect` (`Scripts/Character/character_traits/graft_effect.gd`, `extends CharacterTrait`)
models the Symbiote's Graft passive as two reused systems layered together rather than a bespoke
subsystem:

- **Effect** — a graft *is* a `CharacterTrait`, so it inherits the full hook surface
  ([Section 9](#9-trait-hook-system)) and the existing dispatch: grafting sets the Symbiote's
  `_trait` to the graft effect, so every existing hook call site fires it with no new dispatch
  code. Concrete grafts (`Scripts/Character/character_traits/Grafts/`, e.g.
  `ReactivePlatingGraft`) subclass `GraftEffect`, override `_BonusForRarity(rarity)` and
  `_Drawback()`, and register hooks in `Init` exactly like any other trait.
- **Attribute layer** — `GetAttributeDelta(attribute, base_value)` is declared on `CharacterTrait`
  itself (default: 0, no contribution), not on `GraftEffect` — `Character.ApplyTraitAttributeBonus()`
  (see section 6.1's `GetEffectiveAttributes` contributor steps) asks whatever `_trait` a
  character holds, generically, the same way `ApplyEquipmentBonuses` applies `GetEquipmentBonus`.
  `GraftEffect` overrides it to return a percent-of-base delta (a rarity-scaled bonus plus a
  flat-percent drawback, both expressed as `Dictionary[Types.Attribute, float]`) — `_attributes`
  itself is never mutated, so there is one source of truth (the graft identity) and no
  double-application on load. `Character` never references `GraftEffect` or grafts by name for
  this; a future non-graft trait needing a static attribute delta overrides the same base-class
  method with no change to `Character`.

`Character` holds two independent `GraftEffect` references: `_graft_effect` is the offer an
enemy preset carries (`CharacterPreset._graft_effect`, populated per-enemy as the graft pool is
authored) and `_graft` is what a Symbiote has actually acquired. `ApplyGraft(effect)` duplicates
the effect, calls `Init(_rarity)`, and assigns it to both `_graft` and `_trait`.

**Battle flow** (`Battle._on_battle_ui_battle_graft_selected` / `_OnGraftTargetSelected` /
`_ResolveGraft`, `Scripts/Battle/battle.gd`): the Graft button appears only for a Symbiote with
`_graft == null`; targeting a living enemy with a non-null `_graft_effect` shows a description
window then a permanence confirm (`ButtonWithOptions`, mirroring the reagent-consumption flow);
`_ResolveGraft` calls `ApplyGraft` on both the battle-local `Character` and the canonical
`CharacterCollection` instance (they are not guaranteed to be the same reference) so the graft
persists regardless of battle outcome, then returns to `Awaiting_Player_Input` without
`CompleteTurn()` — the free action never advances the turn bar.

**Persistence:** `CharacterCollection.Serialize`/`Deserialize` save only the acquired graft's
resource path (`_graft_UID`); the effect and attribute layer are re-derived from `load(path)` +
`Init(rarity)` on load. Old saves without a `"graft"` key deserialize as ungrafted.

Coverage: `test_graft.gd` (machinery, via a test-only `GraftEffect` subclass) and
`test_symbiote_graft_pool.gd` (concrete grafts) — see `Test_Design_Document.md`.

The four grafts buildable with no new engine
primitive — `WretchedConscriptGraft` (pure `Defence` bonus), `SpreadingRotGraft`
(`Skill_Cast` applies Blight to enemy targets, `Start_Turn` self-damages 3% max Health),
`ReactivePlatingGraft` (`Damage_Taken` adds a Hardened stack to `Defence`, capped at 9, alongside
a flat Speed drawback), and `StrengthInNumbersGraft` (`Start_Combat`/`Start_Turn`/`Ally_Death`
recompute a Resistance+Defence bonus scaled by living-ally count, or a no-ally Resistance
penalty). All four live under `Scripts/Character/character_traits/Grafts/` with one `.tres` each
under `Data/Character_Traits/Grafts/`.

Three more grafts landed on two new primitives —
`HollowHungerGraft` (`Damage_Dealt` heals the owner by a rarity-scaled fraction of damage dealt,
alongside a flat max-Health drawback), `CarrionBloomGraft` (`Start_Turn` heals the lowest-current-
Health living ally, including the owner itself, by a rarity-scaled fraction of that ally's max
Health; overrides `GetIncomingHealMultiplier` to permanently halve healing the owner itself
receives — kept off the Buff/Debuff system as an inherent graft property), and `OvergrowthGraft`
(`Start_Turn` stacks a self-heal that grows each turn, spilling over into team-wide Regeneration at
6 stacks before resetting). The primitives: `ResolveTraitHeal`
(`BattleResolver`) gained an optional `p_raw_amount` so a raw healed amount (lifesteal) can reuse
the same path as its existing max-Health-fraction heals, and `CharacterTrait.GetIncomingHealMultiplier(owner_ID)`
is a permanent, unconditional multiplier `_HealingMultiplier` composes with the existing
`IncomingHealReduction` debuff scan — the same "plain getter, no `Combat_Event`" shape as
`GetTargetingPriorityMultiplier`/`GetZoneChargeBonus`.

Three more grafts landed on the shared turn-bar push/pull
primitive — `CaravanCadenceGraft` (`Start_Turn` finds the furthest-behind living ally via
`TurnPositions.GetCharactersBehindOrdered` and pushes them forward with `BattleResolver.BumpTurnBar`,
alongside a Knowledge bonus and a graft-inherent forward-bump block on itself),
`GraviticRotGraft` (`Start_Turn` pulls every living enemy within the existing rear-proximity window
back with a negative `BumpTurnBar`, alongside a flat Speed drawback), and `ContagionBondGraft`
(`Buff_Applied`/`Debuff_Received` duplicate whatever buff/debuff the owner just gained or received,
at 1-turn duration, onto the nearest ally/enemy found via the new
`TurnPositions.GetCharactersByProximityOrdered`, alongside a permanent incoming-debuff-duration
extension on the owner). The primitives: `BattleResolver.BumpTurnBar` is a public wrapper around
the existing private `_EmitTurnBarBump`, so grafts can push/pull turn-bar position directly and get
Anchor/Steadfast/turn-bar-tithe handling for free; `CharacterTrait.BlocksForwardTurnBarBump(owner_ID)`
is a new hook (default `false`), checked in `_EmitTurnBarBump` to suppress only positive bumps — the
inverse of Steadfast's negative-only block — kept off the Buff/Debuff system as a graft-inherent
property. `TurnPositions`/`TurnBar`/`TurnBarPositions` gained the two
ordered queries (`GetCharactersBehindOrdered`, furthest-first; `GetCharactersByProximityOrdered`,
nearest-first), matching the shape of the existing `GetCharactersBehindBy`/`GetCharactersWithinProximity`.
`Types.Combat_Event.Debuff_Received` is a new receiver-side hook dispatched from
`StatusEffectResolver._EmitDebuffApplied` (mirroring the target-side `Buff_Applied` dispatch in
`_EmitBuffApplied`; `Debuff_Applied` itself stays applier-side, an existing asymmetry left
unchanged), and `_EmitBuffApplied`'s dispatch was broadened to pass the applied buff itself to
`OnBuffGained` (`OnTheHouseTrait` updated to the new signature, ignoring the added parameter).
`CharacterTrait.GetIncomingDebuffDurationBonus(owner_ID)` (default `0`) is added to the debuff
duration in `StatusEffectResolver._InsertOrRefresh` before it is stored, the same "plain getter"
shape as `GetIncomingHealMultiplier`. Finally, the passive resist-then-land debuff path was
unified: `_CastDebuff` (which unpacked a `Skill` resource directly) is gone, replaced by one public
`StatusEffectResolver.CastDebuff(target_ID, debuff_template, caster_ID, tick_bonus_per_debuff := 0.0,
always_refresh_duration := false, trigger_mirror_coat := false)` that takes an already-built
`StatusEffects.Debuff` template; `ApplyDebuffEffect.Resolve` (see
[Section 6.1](#61-resource-templates)) builds that template from its own `debuff_type`/`duration`
and passes `always_refresh_duration=true, trigger_mirror_coat=true` for its pre-existing behavior,
while Contagion Bond's passive copy leaves both `false` (matching `ApplyDebuff`'s
unconditional-application scope — Mirror Coat only reflects skill-cast debuffs).

Three more grafts landed on an attacker-aware damage-taken
reaction — `GlassRefractionGraft` (`Damage_Taken` strikes a living, non-self attacker back for a
Mysticism-scaled backlash through `ResolveTraitDamage`, alongside a Mysticism bonus and a flat
Resistance drawback), `UndertowGraft` (`Damage_Taken` pulls a living enemy attacker back on the
turn bar via `BumpTurnBar` and self-reduces by a flat amount, alongside a Health bonus; the
self-reduction is a graft-inherent behavior, not an attribute), and
`GlamourGraft` (`Start_Combat` adds a flat dealt-damage bonus via the new
`AggregateDamageMultipliers`; `Damage_Taken` returns a flat 1.1 taken-damage multiplier; overrides
`GetIncomingSingleTargetRedirectChance` and the existing `GetTargetingPriorityMultiplier` for its
redirect chance and increased targeting — all effects are behavioral, both attribute layers
empty). The primitives: `CharacterTrait.OnDamageTaken(owner_ID, attacker_ID, resolver)` is a
broadened signature (previously `(owner_ID, resolver)`; every existing override —
`ReactivePlatingGraft`, `DoubleTheFunTrait` — updated to accept, and mostly ignore, the added
attacker ID), the same "broaden a hook, update its consumers" shape as `Buff_Applied`'s earlier
broadening above. `CharacterTrait.GetIncomingSingleTargetRedirectChance(owner_ID) -> float`
(default `0.0`) is read in `BattleResolver.FindSkillTargets`: a `Single_Enemy`/`Single_Ally` skill
whose resolved target rolls under this chance is redirected to a random other living combatant
(`_RandomOtherCharacter`), the defender-side counterpart to the existing caster-side Refracted
redirect at the same site — the two are mutually exclusive (a Refracted caster's redirect takes
priority) and neither ever touches AoE targeting. `BattleResolver.AggregateDamageMultipliers(
character_ID, amount)` is a public wrapper around the existing additive `_damage_dealt_bonus`
merge (multiple sources on the same character sum their percentages rather than compounding); the
Fractured Idol reagent path was refactored to call it instead of mutating the dictionary directly,
with no behavior change (its own test still passes unmodified).

Landing Glamour surfaced a pre-existing bug in `Battle.SetTargetingOrder`, fixed in the same pass:
the trait multiplier (previously `GetTargetingDefenceMultiplier`, renamed
`GetTargetingPriorityMultiplier` to match) was scaling only the Defence term of the
Health-plus-Defence targeting-priority score before the two were summed, so a trait like Glamour's
+20% or Double the Fun's +50% barely moved a low-Defence character's priority at all. It now scales
the whole `Health + Defence` sum before comparison, so "targeted N% more/less often" holds
regardless of the holder's Health/Defence split (`test_targeting_order.gd`'s
`test_targeting_priority_multiplier_scales_the_whole_score_not_just_defence` covers the regression).

One graft, `BloodscentGraft`, lands on two new
damage-path primitives. `Types.Combat_Event.On_Kill` and `CharacterTrait.OnKill(owner_ID,
victim_ID, resolver)` (no-op default) are a killer-side hook, dispatched from
`BattleResolver._ResolveDamage` right after the existing `Damage_Dealt`/`Critical_Hit` dispatch,
guarded by `target._current_health <= 0 and caster._current_health > 0` — this scopes it to attack
kills only (reagent-cost and turn-bar self-damage deaths never reach `_ResolveDamage`) and correctly
excludes a Deathward rescue, which pins the target at 1 Health rather than 0.
`CharacterTrait.GetOutgoingDamageBonus(owner_ID, target_ID, resolver) -> float` (default `0.0`) is an
unconditional per-attack getter, read in `_ResolveDamage` before `Skills.MitigatedDamage` and folded
additively into the existing `_damage_dealt_bonus.get(caster_ID, 0.0)` argument — a live computed
add, not persisted back to `_damage_dealt_bonus`, so it can vary by target on every attack.
`BloodscentGraft` registers only `On_Kill` in `_execution_steps` (`OnKill` heals the owner for 15% of
its own max Health via `ResolveTraitHeal`); `GetOutgoingDamageBonus` is read unconditionally and
implements "penalty wins" — a target above 50% Health always takes −25% regardless of whether it is
also the lowest-Health enemy, checked before the lowest-Health min-scan (mirroring `CarrionBloomGraft`'s
inline scan, but over `GetSides().EnemiesOf(owner)`) that grants +20/25/30/35% by rarity. Both
attribute layers are empty — all of Bloodscent's effects are behavioral.

Two more grafts land on three zone primitives —
`LivingBloomGraft` (`Start_Combat` seeds a 10-charge Spore zone in a free turn-bar-zone slot via
`ZoneResolver.PlaceZone`, no-op if every slot is full; `Start_Turn` tops the zone back up by 1
charge, capped at 10, via `ReplenishZoneCharge`; a Knowledge bonus by rarity, no drawback) and
`RootfeederGraft` (`Zone_Affected` heals the owner for a rarity-scaled fraction of max Health via
`ResolveTraitHeal` on top of whatever zone effect just landed, for either side's zones; overrides
`GetIncomingZoneEffectMultiplier` to make enemy-owned zone effects 150% as strong against it — a
graft-inherent behavioral drawback, not an attribute). The primitives:
`Types.Skill_Type.Spore_Zone` is a new dual-faction zone type resolved in
`ZoneResolver._ResolveZoneEffect` — it branches on `_resolver._sides.AreAllies(character, zone
owner)` to apply a 1-turn Regeneration to allies or a 1-turn Blight to enemies from the same
placement, both routed through `StatusEffectResolver.ApplyBuff`/`ApplyDebuff` (inheriting the
max-status/sequence-lock/Aegis/severance guards those already enforce) rather than building the
status inline the way the older Lava arm does; both values are `Skills.ZoneMagnitude`-scaled by
the zone owner's Knowledge snapshot, the existing ally-zone scaling convention.
`ZoneResolver.ReplenishZoneCharge(zone_ID, amount, max_charges)` raises a zone's `_duration`
toward a cap via the existing `SetZoneDuration` emitter, and is a no-op — it does not shrink the
zone — both below, at, and above the cap. `Types.Combat_Event.Zone_Affected` and two new
`CharacterTrait` virtuals, `OnAffectedByZone(owner_ID, zone_owner_ID, resolver)` (no-op default)
and `GetIncomingZoneEffectMultiplier(owner_ID, zone_owner_ID, sides) -> float` (default `1.0`),
give the character standing in a zone a reactive hook and an incoming-magnitude multiplier,
mirroring the owner-side `GetZoneChargeBonus`/`OnZoneUsed` shape from the opposite side of the
interaction. `_ResolveZoneEffect` computes the affected character's multiplier once up front and
threads it into the Flicker bump, the Lava debuff's value, and both Spore values — Barrier is left
unthreaded, since Barrier only ever targets `ZoneAlly` and so an enemy-owned Barrier can never
trigger on a multiplier-holding character in the first place. The `Zone_Affected` dispatch fires
only when the zone's own effect actually landed: the Lava arm already skipped it via its existing
early returns (max status effects, Aegis consumed), and the new Spore arm checks the `Array[CombatResult]`
`ApplyBuff`/`ApplyDebuff` return for emptiness (blocked, or silently no-op'd because the refreshed
duration wasn't longer) before falling through to the dispatch — so Rootfeeder's heal never fires
for a zone effect that didn't actually apply.

`CharacterTrait`'s hook surface reached exactly `gdlintrc`'s `max-public-methods` ceiling (30) with
these two new virtuals (32 total). Unlike `battle_resolver.gd`'s growth
([Section 15.10](#1510-battle_resolvergd-growth-the-zoneresolver-and-statuseffectresolver-splits)),
this base class cannot be split into a `RefCounted` subsystem the way `ZoneResolver`/
`StatusEffectResolver` were — it is a `Resource` base class extended by every trait and graft
subclass in the project, and its public surface *is* the hook interface by design, so there is no
"internal implementation detail" half to move out. The ceiling was raised to 34 (two methods of
headroom over the current count, rather than the exact count) — the same category of decision as
the resolver bumps, but with no split available, growth here will keep consuming that headroom one
hook at a time until future work needs to revisit the shape of the interface itself (e.g.
grouping related hooks behind a smaller number of dispatch entry points).

One graft, `DetritivoreGraft`, lands on a broadcast-dispatch
primitive. `BattleResolver.BroadcastEvent(event: Types.Combat_Event) -> void` iterates every
character on either side and invokes the registered `_execution_steps` Callable directly (no new
`CharacterTrait` hook method — it reuses the existing per-trait `_execution_steps` dispatch table
in place), so any trait can react to something happening to *any* character, not just itself. It
calls the hook as `(owner_ID: int, resolver: BattleResolver)`, which is not every hook's shape
(`OnDamageTaken` also takes an attacker ID, `OnSkillCast` takes a target list, and so on), so it is
restricted to a `_BROADCASTABLE_EVENTS` allowlist checked by an `assert` — currently `Start_Combat`,
`Start_Turn`, `End_Turn`, and `Resource_Depleted`, the only `Combat_Event`s whose hook matches that
shape; broadening it to a differently-shaped hook needs its own dispatch, not this one. The
new `Types.Combat_Event.Resource_Depleted` is fired at three sites, once per occurrence:
`StatusEffectResolver._TriggerExistingCasterBuffs` (once per buff whose duration reaches 0 —
early `RemoveBuff` and death's `Statuses_Cleared` are untouched, and debuff expiry is deliberately
out of scope, per the design doc's "a buff expires"), `ZoneResolver.TriggerZones` (once per zone
freed at 0 duration), and `BattleResolver.ResolveReagent` (once per reagent consumed by anyone,
additive to the existing consumer-side `OnReagentConsumed` hook). `DetritivoreGraft` registers
`Start_Combat` and `Resource_Depleted`: each scavenge heals 2% of the owner's max Health via
`ResolveTraitHeal` and adds an uncapped Scrap stack, recomputing `_attribute_percent_delta[Resistance]`
from scratch each time as `STARTING_RESISTANCE_PENALTY + scrap_per_stack * stacks` (a graft-inherent
scaling mutation, not a Buff/Debuff) so the permanent −20% Resistance
drawback and the growing Scrap bonus — the same attribute — never drift apart; `StartOfBattle`
resets stacks to 0 and restores exactly `STARTING_RESISTANCE_PENALTY`, not `0.0`.

One graft, `SymbioticAnchorGraft`, lands on a cross-character
attribute-sharing primitive. `BattleResolver.AdjustLongAttributeBonus(character_ID, attribute,
delta)` is a public mutator over the existing `_battle_long_attribute_bonus` layer (previously
written only by the private `_ApplyReagentAttributeIncrease`, which now calls it for its
dict-merge instead of duplicating the logic) — a positive delta grants a flat attribute bonus for
the rest of the battle, negative removes one, and it is summed into every combat calculation via
`GetEffectiveAttributes`. `SymbioticAnchorGraft` registers `Start_Combat` and
`Ally_Death`: it tethers to a random living ally (the same pick-random-ally/re-tether-on-death
idiom as `StrengthInNumbersGraft`/`ChosenVesselTrait`), snapshotting 20% of the Symbiote's own
total Resistance and Attack at the moment of tethering and granting it to the tethered ally via
`AdjustLongAttributeBonus` — a one-time snapshot, not a live-tracked share, so later changes to the
Symbiote's stats do not retroactively adjust the ally's bonus, and the ally keeps its shared bonus
even if the Symbiote dies afterward (`OnDeath()` takes no resolver argument, so there is no cleanup
hook to remove it). The graft re-tethers only when its currently tethered ally dies, so the
previous tether target is always dead by the time a new one is picked — no bonus needs to be
stripped from a still-living prior ally. It also carries a rarity-scaled Resistance bonus (14–20%)
and a flat −30% Defence/CritDamage drawback on its own attribute layer.

Every enemy `_graft_effect` stays null until a future pass assigns sources.

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

Resolved: the per-combat state (`_skill_ramp_uses`, `_damage_multiplier`) lives
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
`match` blocks and the `Statuses.BUFF_ICONS`/`DEBUFF_ICONS` maps are gone; the effect-application
methods dispatch generically on `StatusEffectData.magnitude_kind` (see section 6.1's
"always live" note for how that dispatch is wired today).

### 15.9. The Symbiote's Graft passive needed generic effect + attribute-bonus machinery — resolved

Resolved by the completed Graft passive plan
([Section 9.2](#92-the-graft-passive-grafteffect)): `GraftEffect` reuses the `CharacterTrait`
hook surface for the graft's effect and layers a derived, percent-of-base attribute delta on top
of `Character`'s base attributes, so a graft can do anything a trait can (buff, debuff, zone,
damage) without any new dispatch code. The in-battle flow models the reagent free-action seam;
persistence stores only the graft's resource UID. Ships no graft content itself — enemy
`_graft_effect` sourcing is populated separately by the graft-pool plan.

### 15.10. `battle_resolver.gd` growth: the `ZoneResolver` and `StatusEffectResolver` splits

`Scripts/Battle/battle_resolver.gd` previously sat at exactly `gdlintrc`'s then-current
`max-file-lines` (1320) and `max-public-methods` (26) — the healing-primitives graft content
(section 9.2) landed by extending an existing public method (`ResolveTraitHeal`'s optional
`p_raw_amount`) rather than adding a new one, specifically to stay under budget.

The zone lifecycle (`_zones` state, `PlaceZone`, `TriggerZones`, `SetZoneDuration`,
`AvailableZoneIDs`, `HasZone`, `GetZones`, `ClearZone`, `_ResolveZoneEffect`) moved first,
into `ZoneResolver` (`Scripts/Battle/zone_resolver.gd`), a `RefCounted` subsystem constructed
by `BattleResolver._init` and held as `_zone_resolver`, mirroring `CombatSides`/`TurnPositions`/
`ReagentLoadout`'s pattern of small `RefCounted` collaborators rather than `Node`-based
utilities like `Skills`/`ReagentResolver`. `ZoneResolver` holds a back-reference to its owning
`BattleResolver` and reaches its `_characters`/`_sides`/`_turn_positions` state and
`_BeginBatch`/`_EndBatch`/`_Emit`/`_EmitTurnBarBump`/`_NextStatusID`/`_HasBuff` services directly
through it, plus the status-effect services below through `GetStatusResolver()` — GDScript does
not enforce `_`-privacy, so no method needed to become public to support this. `BattleResolver`
exposes the subsystem through a single `GetZoneResolver() -> ZoneResolver` accessor, mirroring
the existing `GetSides()`/`GetTurnPositions()` pattern of handing back an owned collaborator
rather than re-forwarding each of its methods; callers reach the zone API as
`resolver.GetZoneResolver().PlaceZone(...)` etc. (`battle.gd`, `calibration_trait.gd`, and the
zone-touching tests were updated to the new call shape; the `Clear_Zone` reagent branch, being
internal to `BattleResolver`, calls `_zone_resolver` directly).

The buff/debuff lifecycle moved the same way, into `StatusEffectResolver`
(`Scripts/Battle/status_effect_resolver.gd`) — the resolver's largest remaining source of
per-effect method growth (one bespoke private method per status: `_TriggerManaBurn`,
`_SpreadPlague`, `_TriggerMirrorCoat`, `_ConsumeAegisIfPresent`, `_BlockedBySequenceLock`, …).
`StatusEffectResolver` owns `ApplyBuff`/`ApplyDebuff`/`RemoveBuff`, the `_CastBuff`/`CastDebuff`/
`_TriggerExistingCasterBuffs`/`Debuffs` skill-resolution helpers, every status-specific block/
consume/trigger rule, the status-derived damage and healing multipliers, and the `Status_Applied`/
`Status_Duration` emitters — constructed and held the same way as `_zone_resolver`, exposed
through `GetStatusResolver() -> StatusEffectResolver`. `BattleResolver` itself keeps only the
shared substrate (`_characters`, `_sides`, batch/emit, `_NextStatusID`, `_HasBuff`/`_HasDebuff`,
the health primitives `_ApplyHealthLoss`/`_ApplyHeal`) and damage/turn orchestration
(`ResolveSkill`, `_ResolveDamage`, `_TickCooldowns`, `_HandleDeath`, …); two checks that were
previously inlined in that orchestration — the Premonition miss and the Deathward fatal-hit
save — became named `ConsumePremonitionIfPresent`/`ConsumeDeathwardIfPresent` on
`StatusEffectResolver` so the damage/health path calls one line instead of scanning the buff
array itself. Because `ApplyBuff`/`ApplyDebuff`/`RemoveBuff` are the resolver's trait-facing
public API (called from most `CharacterTrait` subclasses, `skills.gd`, `battle.gd`, and debug
tooling — an order of magnitude more external callers than zones had), every call site was
updated to the `resolver.GetStatusResolver().ApplyBuff(...)` shape rather than adding thin
forwarders on `BattleResolver`, for consistency with the `ZoneResolver` accessor precedent.
The four insertion methods' shared skeleton (max-status guard, stackable/overwritable scan with
duration-refresh, append, emit) was also collapsed onto one `_InsertOrRefresh` helper; it takes
an `p_always_refresh_duration` flag because `CastDebuff` alone refreshes an existing debuff's
duration unconditionally (the other three only refresh when the new duration is longer), and
returns the created instance (or `null` when nothing new was created) so `CastDebuff` alone can
gate its Mirror Coat trigger on an actual creation, not a mere refresh.

`Skill.health_change`/`heal_scaling` resolution landed the same way from the start, as
`HealthTransferResolver` (`Scripts/Battle/health_transfer_resolver.gd`) rather than as new
`BattleResolver` methods, since the addition alone would have pushed the file past
`max-file-lines`. It owned `ResolveHealthCosts`/`ResolveHealthGains`, constructed and held as
`_health_transfer_resolver` the same way as `_zone_resolver`/`_status_resolver`, called directly
from `ResolveSkill`. It reached `GetStatusResolver()._ResolveStatusGroupTargets` and
`_MaxHealth`/`_ApplyHealthCost`/`_ApplyHeal`/`_Emit` on the owning `BattleResolver` directly, same
as the other two subsystems.

This freed real budget back: `battle_resolver.gd` dropped from roughly 1230 to 656 lines and 19
public methods, with the buff/debuff machinery now in its own 599-line file. `gdlintrc`'s
`max-file-lines`/`max-public-methods` were retightened from 1320/26 to 800/25 — headroom over the
current largest file and highest public-method count (`character_trait.gd`'s 24 hook methods at
the time), not a return to the original pre-split values, since those predate this work entirely.

The skill effect components pass (see [Section 6.1](#61-resource-templates) and
[Section 7.4](#74-skill-resolution-battleresolverresolveskill)) later dissolved
`HealthTransferResolver` and `BuffManipulationResult` (`Scripts/Battle/buff_manipulation_result.gd`,
a small standalone return-value class that used to carry a cast's additive damage-bonus fraction
and duration bonus) along with the flat `Skill` fields they existed to resolve.
`HealthChangeEffect.Resolve` now calls `BattleResolver.ResolveHealthCost`/`ResolveHealthGain`
directly, and `SkillCastContext.buffs_consumed` replaced `BuffManipulationResult`'s accumulator.
`_SkillRampMultiplier`'s inline per-(caster, skill) counter became `DamageEffect._RampMultiplier`
reading the still-resolver-side `_SkillUseCount` (which `AlternatingEffect` also reads for its
rotation), and `CharacterTrait.IsConditionActive` was replaced by the source-parameterized
`GetConditionCount` (see [Section 9](#9-trait-hook-system)). `StatusEffectResolver`'s
`_ResolveStatusGroups`/`_ResolveStatusGroupTargets`/`_ResolveIndependentStatusGroup` were absorbed
into `SkillCastContext.TargetsFor`/`TargetsForGroup`/the static `ResolveStatusGroupTargets`/
`ResolveIndependentGroup` — the group-resolution logic moved once more, from the resolver
subsystem to the per-cast context object that now owns skill resolution's shared state.

`max-public-methods` has since ratcheted up several more times, one method at a time, as later
content (grafts, then skill effects) pushed `character_trait.gd`'s hook count past each successive
ceiling — it is currently `35`, project-wide (`gdlintrc` has always set a single ceiling for every
`.gd` file, never split per class, despite this section's history reading like a per-file budget).
`character_trait.gd` sits exactly at that ceiling (35 public hook methods, its surface *is* the
hook interface by design — see Section 9.2's `GraftEffect` note, no split available). `max-file-lines`
is currently `800`; `battle_resolver.gd` (`747` lines, `26` public methods) has headroom on both.

The skill effect components pass is the current answer to `battle_resolver.gd`'s recurring growth
pressure: a new skill mechanic now adds one small `SkillEffect` subclass under
`Scripts/Battle/Skill_Effects/` instead of a new flat `Skill` field plus an `if` in `ResolveSkill`,
so per-mechanic growth no longer lands on the resolver's own file or method budget at all.

### 15.11. `Skill`'s flat field bag grew unboundedly and let mechanics leak into each other — resolved

Resolved by the completed skill-effect-components plan (see [Section 6.1](#61-resource-templates)
and [Section 7.4](#74-skill-resolution-battleresolverresolveskill)): `Skill` had grown to 25
optional fields, and `ResolveSkill` ran every optional mechanic on every cast behind an `if` guard,
so a mechanic could read state left over from an unrelated field on the same skill. One live bug
came from this shape: `StandingRecordTrait.GetOutgoingDamageBonus` applied its Infraction-rate
bonus to *every* damaging skill the Emissary cast, not just Citation, violating Concept Document
3.1.3's "skills state what scales, never their own rate" — harmless only because the Emissary's
other skills dealt no damage. `Skill.effects: Array[SkillEffect]` replaces the field bag: a
mechanic a skill does not list cannot run for it, closing that whole class of bug rather than
patching the one instance. `CharacterTrait.GetConditionCount` replaced both `IsConditionActive`
and `StandingRecordTrait`'s damage-bonus override, so the Infraction rate now reaches damage only
through a `DamageEffect` that explicitly asks for it.

### 15.12. Eight fragmented multiplicative damage inputs, each with its own placement — resolved

Resolved by `CombinedDamageModifier` (see [Section 7.4](#74-skill-resolution-battleresolverresolveskill)):
before unification, `Skills.MitigatedDamage` took eight separate float parameters
(`p_trait_multiplier`, `p_ramp_multiplier`, `p_damage_multiplier`, `p_damage_dealt_bonus`,
`p_opportunist_multiplier`, plus the outgoing-damage-bonus and `bonus_per` totals folded into
`p_bonus_damage_fraction`), each hardcoded to either the pre-mitigation aggregate or the final
product depending on which source it happened to be. Adding a ninth source meant deciding its
placement from scratch and threading a new parameter through `_ResolveDamage`,
`ResolveEffectDamage`, and `ResolveTraitDamage`. It also grouped by whichever accident of the
source's own storage applied — most sources were already effectively one bucket per mechanic, but
`bonus_per_debuff_on_target` summed every target debuff into a single additive lump on the caster,
so a second qualifying debuff added rather than multiplied, contradicting the "distinct mechanics
multiply" law in Concept Document 1.1.3. `CombinedDamageModifier` replaces the eight parameters with one
object built at each damage resolution, contributed to by key (mechanic identity, not source
plumbing), and multiplies the pre-mitigation aggregate uniformly — a new source is one `Contribute`
call, not a new formula parameter.
