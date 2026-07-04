# Plan: Naming Convention Alignment

Make the written conventions in `CLAUDE.md` and the actual code agree. This matters
more than usual here because the agent-fleet workflow has a Reviewer phase that
enforces the written rules — as long as rules and reality diverge, every review
produces the same noise.

## Status

Partially done (July 2026). Two of the four findings were resolved outside this plan:

- Finding 1 (function casing) — resolved by amending the rule: `CLAUDE.md` now states
  `PascalCase` for custom functions, matching the codebase (the recommendation below
  was taken).
- Finding 4 (camelCase members) — resolved by commit `4de83b6`, with slightly
  different names than proposed here: `_critical_chance`, `_critical_damage`
  (spelling out "crit", better than the proposed `_crit_*`), `_current_health`,
  `_instance_ID`, and `_turn_character_ID` (instead of `_active_turn_character_ID`).
  The serialization concern proved real but harmless: the crit values are exported
  preset properties stored by name in `.tres` files, so three resources were updated
  in the same commit and `test_collection_serialization.gd` stayed green.
- Commit `5fa9bf3` additionally codified the real conventions in `gdlintrc`
  (enum names, enum elements, class-variable casing including acronym segments like
  `_owner_ID`), so `gdlint Scripts/` now enforces them mechanically.

Remaining: findings 2 and 3 (file renames and abbreviation spell-outs). Lowest
priority of the plans; schedule as one or two mechanical commits in a quiet moment,
never mixed into feature work. Extends `Technical_Design_Document.md` 15.3, which
already covers file casing.

## Findings

1. ~~**Function casing**~~ — resolved; rule amended in `CLAUDE.md` (see Status).
2. **File casing** (already recorded in 15.3): `Skills.gd`, `Zone.gd`,
   `Level_System.gd`, `Context_Container.gd`, `Static_Context.gd`,
   `CharacterTraits/`, `Statue_Weapon_Trait.gd`, `Tidal_Corsair_Trait.gd`.
3. **Abbreviations not on the allowlist:** `Character_Battle_Repr.tscn` /
   `CharacterRepresentation`'s scene name ("Repr"), `_char_turns` ("char"),
   `_character_repr` ("repr"), `p_caster_attr`/`p_attacker_attr` ("attr"). The
   project's own rule says spell words out; none of these are on the
   accepted-acronym list.
4. ~~**camelCase members**~~ — resolved by commit `4de83b6` (see Status). Locals like
   `randomVal`/`randomVal2` may linger; gdlint does not check local names, so sweep
   them during step 3.

## Steps

1. ~~**Amend `CLAUDE.md`**~~ — done; also enforced via `gdlintrc` (commit `5fa9bf3`).
2. **Rename the off-convention files** from finding 2 in one commit: file renames plus
   `preload`/`load` path updates. Prefer `uid://` references (most already are) so
   scene links survive; grep for any remaining `res://` string paths to the renamed
   files. Note `class_name`s stay PascalCase — only filenames change.
3. **Spell out the abbreviations** from finding 3: rename `Character_Battle_Repr.tscn`
   to `Character_Battle_Representation.tscn`, `_char_turns` to
   `_character_turn_markers` (or similar), `_character_repr` to
   `_character_representations`, `p_caster_attr` to `p_caster_attributes`. Scene
   renames must update the exported node paths in `battle.tscn`.
4. ~~**Rename the camelCase members**~~ — done in commit `4de83b6`.
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
