# Plan: Naming Convention Alignment

Make the written conventions in `CLAUDE.md` and the actual code agree. This matters
more than usual here because the agent-fleet workflow has a Reviewer phase that
enforces the written rules — as long as rules and reality diverge, every review
produces the same noise.

## Status

Not started. Lowest priority of the plans; schedule as one or two mechanical commits
in a quiet moment, never mixed into feature work. Extends
`Technical_Design_Document.md` 15.3, which already covers file casing.

## Findings

1. **Function casing:** `CLAUDE.md` mandates `snake_case` for functions; the entire
   codebase uses `PascalCase` (`Init`, `ResolveSkill`, `GetBattleAttribute`, ...).
   This is the largest divergence and it is total — no file follows the written rule.
2. **File casing** (already recorded in 15.3): `Skills.gd`, `Zone.gd`,
   `Level_System.gd`, `Context_Container.gd`, `Static_Context.gd`,
   `CharacterTraits/`, `Statue_Weapon_Trait.gd`, `Tidal_Corsair_Trait.gd`.
3. **Abbreviations not on the allowlist:** `Character_Battle_Repr.tscn` /
   `CharacterRepresentation`'s scene name ("Repr"), `_char_turns` ("char"),
   `_character_repr` ("repr"), `p_caster_attr` ("attr"). The project's own rule says
   spell words out; none of these are on the accepted-acronym list.
4. **camelCase members** (partially recorded in 15.3): `_currentHealth`,
   `_instanceID`, `_critChance`, `_critDamage`, plus oddities like
   `_characterIDs_turn` (reads as plural; it holds a single ID) and locals like
   `randomVal`/`randomVal2`.

## Decision to make first

**Recommended: change the rule, not the code, for function casing.** PascalCase
functions are applied consistently across the whole project, Godot does not care, and
a full rename touches every file, scene connection, and Callable reference for zero
behavioral value. Amend `CLAUDE.md` to state: functions use `PascalCase`; variables
and file names use `snake_case`.

If you instead want the code to match the current rule, that is a much larger
mechanical pass — decide explicitly before anyone starts.

## Steps

1. **Amend `CLAUDE.md`** (project and, if applicable, fleet-level `~/repos/CLAUDE.md`)
   with the decided function-casing rule, so reviews stop flagging it.
2. **Rename the off-convention files** from finding 2 in one commit: file renames plus
   `preload`/`load` path updates. Prefer `uid://` references (most already are) so
   scene links survive; grep for any remaining `res://` string paths to the renamed
   files. Note `class_name`s stay PascalCase — only filenames change.
3. **Spell out the abbreviations** from finding 3: rename `Character_Battle_Repr.tscn`
   to `Character_Battle_Representation.tscn`, `_char_turns` to
   `_character_turn_markers` (or similar), `_character_repr` to
   `_character_representations`, `p_caster_attr` to `p_caster_attributes`. Scene
   renames must update the exported node paths in `battle.tscn`.
4. **Rename the camelCase members** from finding 4 (`_currentHealth` →
   `_current_health`, `_instanceID` → `_instance_ID`, `_critChance` → `_crit_chance`,
   `_critDamage` → `_crit_damage`, `_characterIDs_turn` → `_active_turn_character_ID`).
   These appear in save serialization? Verify: `character_collection.gd` serializes by
   its own string keys, not member names — confirm no member name leaks into the save
   format before renaming, and run `test_collection_serialization.gd` after.
5. **Run the full test suite and a manual battle smoke test** after each commit —
   renames in GDScript are textual and the compiler will not catch every stale string
   reference (Callable-by-name, `get_node` paths).

## Watch for

- Do not combine renames with any logic change; the value of a mechanical commit is
  that reviewers can skim it.
- `.tres` resources reference scripts by path/UID — renaming script files requires
  the Godot editor (or careful UID preservation) so resource links do not break.
  Safest: perform file renames inside the editor, then commit.
- Sequence this plan *after* the combat plans if they are imminent, to avoid rebase
  pain across the same files.
