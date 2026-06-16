# Milestones — champ_collector

## Completed systems

### Core game systems
- **Character** — stat model, equipment slots (equip/unequip), level and XP tracking, attribute aggregation including equipment bonuses
- **Level system** — XP formula (`GetExperienceRequirement`), level-up detection, opponent level scaling with speed-vs-stat differentiation
- **Skills** — targeting resolution (`FindSkillTargets`), zone targeting truth table (`CorrectZoneTarget`), buff/debuff application, damage formula
- **Loot manager** — primary/secondary loot tables, Fortunes Favor distribution by difficulty and budget
- **Resource handler** — supply spending with success/failure guards, offline-aware supply regeneration (+10 per 10 real minutes, capped at 100, partial progress preserved), `resources_changed` signal for live UI updates
- **Item collection** — equipment storage, serialization/deserialization with preset UID lookup

### Adventure feature
- **Adventure state** — node graph, supply cost tiers, daily reset, serialization roundtrip, scaled difficulty, `MarkCurrentNodeComplete()` (extracted from `post_battle_menu`)
- **Adventure generator** — biome-aware node generation, boss node, branching control
- **Adventure UI** — scrollable graph view with touch support, node preview, pre-adventure menu
- **Biome loading** — DirAccess-free biome preloads for Android export compatibility

### Battle feature
- **Turn-based combat** — turn bar zones, character representations, skill casting, status effects
- **Post-battle screen** — loss/victory display, character damage results, team-edit navigation
- **Encounter supply cost** — composable cost (base 6 + optional adventure tier surcharge) charged
  on battle start (including replay); half refunded on a loss; starting an encounter is blocked
  when the player cannot afford the total

### Infrastructure
- **Save system** — group-based saveable nodes, serialization contracts for Character, ItemCollection, ResourceHandler, AdventureStateHandler
- **Scene management** — context-container pattern for scene transitions

## Test suite (added 2026-06-09)
- 87 tests across 10 files, all passing headlessly
- Covers: adventure state, generator, biomes, loot, level system, skills targeting, resource handler, character equipment, ItemCollection and CharacterCollection serialization roundtrips
- Test_Design_Document.md written — defines what is and is not unit-tested and why
- `Tests/unit/helpers/test_factory.gd` — shared character/loot/state builders

## Documentation (added 2026-06-09)
- Technical_Design_Document.md written — describes the as-built architecture (autoloads and
  global state, the context-container scene-management pattern, the preset-versus-instance data
  model, the combat resolution path, the trait hook system, collections and the group-based save
  format) and a forward-looking "known weaknesses and recommendations" section; complements
  Concept_Document.md (design) and Test_Design_Document.md (test strategy)

## Conventions (added 2026-06-09)
- Added a naming and wording convention (spell words out, avoid acronyms) to both the
  fleet `~/repos/CLAUDE.md` and the project `CLAUDE.md`, with a project allowlist of
  accepted acronyms (`UI`, `RPG`, `XP`, `ID`, `UID`, `JSON`, `URL`, `GUT`, `HP`, `AoE`)
- Renamed `TDD.md` → `Test_Design_Document.md` and `Concept_Doc.md` → `Concept_Document.md`
  to remove ambiguous/abbreviated document names; updated all cross-references
- Spelled out abbreviated identifiers in scripts (`idx`, `num`, `mouse_pos`, `cc`,
  `attribute_val`)

## Editor-only debug overlay (added 2026-06-12)
- Added `Scripts/Debug/` + `Scenes/debug/`: a `CanvasLayer` overlay (`DebugOverlay`,
  toggled with **F1**), instantiated by `main.gd` only when `OS.has_feature("editor")`
  is true, so it is absent from exported builds
- Five tabbed pages: Currencies & Progression, Champions (roster availability and
  level), Item Construction (exact-stat `EquipmentPreset`s), Battle Launcher (jump
  straight into a battle with chosen champions/enemy wave/difficulty), and In Battle
  (live HP/turn/status-effect edits during combat)
- `DebugCatalog` (preloaded champion/enemy/battle-context presets, no `DirAccess`) and
  `DebugActions` (pure, unit-tested helpers for building equipment presets and battle
  `ContextContainer`s) back the pages
- Removed the old non-editor-gated debug hooks: KEY_0/KEY_8 in `main.gd` (print scene
  tree / grant legendary boots) and KEY_A/KEY_M kill-team shortcuts in `battle.gd` —
  print-tree and item-granting are now overlay features; kill-team is now per-character
  Kill/Revive buttons on the In Battle page
- `Tests/unit/test_debug_actions.gd` added (2 tests); suite now 89 tests across 11
  files, all passing headlessly

## Adventure node types: Rest Stop, Hint, Gamble, Escalating (added 2026-06-13)
- Added `HINT`, `GAMBLE`, `ESCALATING` to `NodeData.Node_Type` (alongside the
  existing `REST_STOP`); generalized `AdventureGenerator._InsertRestStops` into
  `_InsertSpecialNodes`, driven by new `AdventureTemplate` frequency fields
  (`hint_nodes`, `gamble_nodes`, `escalating_nodes`)
- New context resources: `ContextHint`, `ContextGamble`, `ContextEscalating`, and
  reworked `ContextRestStop` (`purchasable_buffs` -> fixed `granted_buff`)
- Added adventure-spanning effects to `AdventureState`: `active_buffs` /
  `active_debuffs` (combats-remaining, with an `ADVENTURE_PERMANENT_EFFECT` sentinel
  for "rest of adventure"), `AddAdventureBuff`/`AddAdventureDebuff`/
  `DecrementAdventureEffects`, serialized round-trip
- `Battle.Init` applies all active adventure buffs/debuffs to player champions via
  new `Skills.ApplyDebuff` (mirrors `ApplyBuff`, no resist check) with an
  effectively-infinite turn duration; `post_battle_menu` decrements adventure
  effects on Victory
- New `Adventure_Interaction_Panel` scene/script resolves all four interactive node
  types in the adventure scene (no battle load); `adventure_ui.gd` routes to it and
  shows active adventure effects in the header
- Documented the four node types in `Concept_Document.md` (section 3.9)

## Adventurers Guild scene shell (added 2026-06-13)
- Added `Scenes/Hubs/Adventurers_Guild/Adventurers_Guild.tscn` and
  `Scripts/UI/adventurers_guild_menu.gd`, following the Reclaimed City /
  World Atlas button styling and navigation pattern (`TextureButton` +
  hover highlight + shadowed `Label`, `ResourceBar` instance)
- Three buttons: "Fortune's Favor" and "Drop Rates" (stubbed, mechanics to
  follow in a future plan) and "Town" (returns to Reclaimed City)
- Wired the existing `Button_Adventure_guild` on the Reclaimed City hub to
  navigate to the new scene

## Brass and Parchment Fortune's Favor tiers (added 2026-06-14)
- `FortuneFavorTier` gains a `tier_type` enum (`BONE`/`BRASS`/`PARCHMENT`); added
  `Brass_Tier.tres` (`reward_count = 5`) and `Parchment_Tier.tres` (`reward_count = 9`)
  alongside `Bone_Tier.tres` (`reward_count = 3`), sharing the same weights/amounts
  and recruitable champion pool
- `ResourceHandler._fortunes_favor` is now a per-tier `Dictionary`, with
  `GetFortunesFavor`/`AddFortunesFavor`/`SpendFortunesFavor(tier_type, amount)`;
  serialized under `fortunes_favor_bone/brass/parchment` with migration of the old
  flat `fortunes_favor` key into Bone on load
- `RecruitmentMenu`/`Recruitment.tscn` now show three tier buttons (Bone/Brass/
  Parchment), each spending its own balance and resolving via its own
  `FortuneFavorTier` resource
- Battle loot still awards generic Fortune's Favor into the Bone balance;
  `ResourceBar` shows the sum of all three tiers under one icon; debug currencies
  page exposes all three balances
- Documented the three tiers in `Concept_Document.md` (section 3.3.2)

## Hollow Ledger drop rates window (added 2026-06-14)
- The Adventurers Guild's "Hollow Ledger" button now opens
  `Hollow_Ledger_Window.tscn`, showing each Fortune's Favor tier's chance to
  award a champion alongside the champion rarity odds available from that tier
- The champion chance per tier is derived from `RecruitmentManager`'s
  `reward_count` and `CHAMPION_CHANCE_PER_REWARD`; `LootManager.GetRarityRates()`
  derives rarity odds from the existing `RARITY_WEIGHTING` table, and
  `Types.RarityName()` converts a `Rarity` enum value to a display string; no
  rates are hard-coded

## Item upgrading (added 2026-06-14)
- Equipment now has a `_level` (0-10) raised via `Equipment.Upgrade()`, which
  adds `3 + rarity` to a random attribute the item already holds (falling back
  to `Game_Balance.ITEM_TYPE_ATTRIBUTES[_slot]` for items with no nonzero stats,
  e.g. Relic); `CanUpgrade()`/`GetUpgradeGain()` support the new flow
- `LootManager.GetUpgradeCost(rarity, current_level)` returns
  `BASE_ITEM_UPGRADE_COST * (current_level + 1) * rarity`; new balance constants
  `MAX_ITEM_LEVEL`, `ITEM_UPGRADE_FLAT_BONUS`, `BASE_ITEM_UPGRADE_COST`
- `ResourceHandler.SpendSilver()` mirrors `SpendSupplies` as the silver spend
  sink
- `ButtonWithOptions` gained a fourth `Button_Upgrade`/`SetUpgradeButton()`;
  Inspect Collection's item options dialog now offers Equip/Sell/Upgrade/Cancel,
  showing cost and confirming via `TryUpgrade`/`UpgradeItem`
- Item level persists via `ItemCollection` serialize/deserialize and is shown on
  each unequipped item's grid slot (`MenuItemSlot.level`, same label used for
  character level)
- Rarity/affix rerolling on upgrade remains out of scope (Remaining_Scope_Checklist.md)

## Hollow Ledger — tabbed reference panel with Nature attribute weights (added 2026-06-16)
- `Hollow_Ledger_Window.tscn` restructured: window enlarged from 560×480 to 720×600;
  content area replaced with a `TabContainer` holding two tabs
- **Tab "Champion Odds"** — unchanged drop-rate view (three Fortune's Favor tiers with
  champion chance and rarity odds); `_tier_list` export path updated to reflect new nesting
- **Tab "Natures"** — `OptionButton` listing all 11 `AttributeWeightPreset`s (preloaded via
  `NATURE_PRESETS` constant); selecting a preset rebuilds an attribute list using computed
  descriptors (`None` / `Low` / `Medium` / `High`) derived at runtime from each preset's
  weight range, so `.tres` balance changes re-bucket automatically without touching script
- `DescribeWeight(p_weight, p_min, p_max) -> String` static helper implements the
  bottom-25%/top-25% bucketing rule; covered by 9 unit tests in
  `Tests/unit/test_hollow_ledger_window.gd`; suite now 147 tests across 15 files, all passing
