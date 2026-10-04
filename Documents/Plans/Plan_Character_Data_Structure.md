# Plan: Character Data Structure

`CharacterPreset` and `Character` each hold every field any character type uses. Playable
champions and opponents share one shape, so each type carries fields that mean nothing for
it, and nothing stops a field being set on the wrong type. This plan restructures both
classes so a field exists only on the type it applies to.

## Field audit

| Field | Applies to | Readers |
|---|---|---|
| `_name`, `_texture`, `_normal_map`, `_skills`, base attributes, `_trait` | All | battle, UI |
| `_rarity` | All | collection, gear, recruitment; opponents feed it to `_trait.Init` |
| `_headshot_region` | Champions | tally board, collection |
| `_role` | Champions | `battle.gd` Symbiote and Herald of the Loom checks, `skill_list_row.gd`, debug sweeps; every opponent sets the `Generic_Enemy` placeholder |
| `_attribute_weight_types_available` / `_attributes_weights` | Champions | level-up weights, `character_collection.gd` |
| `_preset_path` | Champions | collection, tally board, save |
| `_experience`, `_level`, `_renown`, `_held_items`, `_graft`, `_graft_UID` (`Character` only) | Champions | progression, gear, save, Symbiote graft |
| `_thematic_hint` | Opponents | `opponent_preview.gd` |
| `_graft_effect` | Opponents | `battle.gd` graft targeting |
| `_phase_two_skills`, `_phase_two_trait`, `_phase_two_text` (`Plan_Jungle_Adventure_Encounters.md` step 5) | Bosses | `BattleResolver` phase transition |
| `_faction` | None | copied into `Character`, never read |

Also audit fields from the Character class.

## Steps

### 1. Choose the split
Decide the structure with the user before any code: a champion/opponent subclass pair on
both classes, or optional per-type data resources hung off a shared base. The choice also
settles where boss phase 2 data lives and whether `Generic_Enemy` and `_faction` are deleted.

### 2. Restructure `CharacterPreset`
Move each field to its type per the audit; migrate every `.tres` under
`Data/Character_Player_Variants/` and `Data/Character_Enemy_Variants/`.

### 3. Restructure `Character`
Same split for the runtime class. `InstantiateNew` copies only the fields its type has;
battle code that reads a champion-only field on any character (`_role` checks on the turn
character) goes through the type.

### 4. Save compatibility
`character_collection.gd` serializes champions by `_preset_path`; existing saves must load
into the new shape.

### 5. Documentation
`Technical_Design_Document.md` §6.1 (`CharacterPreset`, `Character`).

## Watch for
- Tests build characters through `TestFactory.make_character()` with no preset; it must
  produce the right type for what each test exercises.
- Debug tools (`burst_reachability.gd`, `team_sweep.gd`) read `_role` across both sides.
- Lint `Scripts/` and run the suite after every step.
