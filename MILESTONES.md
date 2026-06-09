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
- TDD.md written — defines what is and is not unit-tested and why
- `Tests/unit/helpers/test_factory.gd` — shared character/loot/state builders
