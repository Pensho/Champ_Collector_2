# Milestones — champ_collector

## Completed systems

### Core game systems
- **Character** — stat model, equipment slots (equip/unequip), level and XP tracking, attribute aggregation including equipment bonuses
- **Level system** — XP formula (`GetExperienceRequirement`), level-up detection, opponent level scaling with speed-vs-stat differentiation
- **Skills** — targeting resolution (`FindSkillTargets`), zone targeting truth table (`CorrectZoneTarget`), buff/debuff application, damage formula
- **Loot manager** — primary/secondary loot tables, Fortunes Favor distribution by difficulty and budget
- **Resource handler** — supply spending with success/failure guards
- **Item collection** — equipment storage, serialization/deserialization with preset UID lookup

### Adventure feature
- **Adventure state** — node graph, supply cost tiers, daily reset, serialization roundtrip, scaled difficulty, `MarkCurrentNodeComplete()` (extracted from `post_battle_menu`)
- **Adventure generator** — biome-aware node generation, boss node, branching control
- **Adventure UI** — scrollable graph view with touch support, node preview, pre-adventure menu
- **Biome loading** — DirAccess-free biome preloads for Android export compatibility

### Battle feature
- **Turn-based combat** — turn bar zones, character representations, skill casting, status effects
- **Post-battle screen** — loss/victory display, character damage results, team-edit navigation

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
