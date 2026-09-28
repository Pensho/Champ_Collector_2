# Plan: Localization — Text Preparation

Step 1 of `Plan_Localization.md`. Routes every player-facing string through translation.
No translations ship in this step. The conventions this plan applies (display-time
translation, templates, `tr` versus `TranslationServer`) are defined in that plan's
Conventions section.

## Status

Nothing implemented. Phases are independent except E, which lands with A.

## Phases

### A. Enum display names
`Scripts/common_enums.gd` holds `RarityName`, `BuffName` and `DebuffName`, which return
raw enum keys. Give every enum the player sees one helper of this kind (Attribute, Slot,
Fortune's Favor tier type, and any others the sweep in phase E finds). Each helper maps
the value to a written-out display string and translates it; the enum key's spelling
never reaches the screen.

Replace the display uses of `keys()[...]`, for example in `Scripts/Gear/equipment.gd`,
`Scripts/UI/shop_slot.gd`, `Scripts/UI/renown_window.gd`,
`Scripts/UI/hollow_ledger_window.gd` and the Adventure UI scripts.

*Watch for:* many `keys()[...]` uses are identity keys, not display text. These include
the status keys in `status_effect_resolver.gd` and `damage_effect.gd`, `buff.name` and
`debuff.name` set in `battle.gd`, `apply_buff_effect.gd` and `battle_resolver.gd`, and
the attribute keys in `shop_handler.gd`. They stay as they are; the view calls the
helper when it shows a status.

### B. Trait, relic and graft text
65 scripts under `Scripts/Character/character_traits/` author `_title` and `_body` in
code, 49 of them by joining text with magnitudes (for example `the_closed_wound_relic.gd`), and
some append live state in `RefreshVisuals` (`weft_and_warp_trait.gd`). Convert each body
to one template with named placeholders, and build it when the view asks for it rather
than at setup, so it reflects the current language.

*Watch for:* `StringName` literals naming a trait for cascade attribution (for example
`&"Weft and Warp"`) are identity keys and stay English. Do the base class
`character_trait.gd` first and follow its pattern across the rest.

### C. Sentence templates in UI scripts
Replace text built by joining pieces with templates, and use the plural forms for
counts. Templates use the `{name}` placeholder syntax that `StatusEffectData`
descriptions already use (`{value}`, `{percent}`, filled in `battle.gd`); phase B follows
the same syntax. Files: `equipment.gd` (`DescriptionText` is static, so it uses
`TranslationServer`), `skill_list_row.gd`, `shop_slot.gd`, `renown_window.gd`,
`hollow_ledger_window.gd`, `resource_bar.gd`, `adventure_interaction_panel.gd`,
`adventure_ui.gd` and `battle_ui.gd`.

### D. Data text and literal strings at the view
- Data text is translated where the view sets it: skill `name` and `description`,
  `Character._name`, reagent, act and biome `display_name`, and status names through
  the phase A helpers.
- Literal strings assigned to nodes in scripts are wrapped in `tr()`. This covers
  `.text = "..."` in `inspect_collection_menu.gd`, `post_battle_menu.gd`,
  `confirm_delete_dialog.gd`, `profile_data_slot.gd`, `tally_board_menu.gd`,
  `turn_bar.gd` and the rest of `Scripts/UI/`, plus tooltip titles and descriptions
  passed to the `SetToolTip` functions.
- Combat text: `CombatResult.text` (trait flavor text from `EmitTraitText`, burst
  mechanic keys, status display names) stays English in the battle core and is
  translated in `battle.gd` where it reaches `SpawnCombatText`.
- Static text in `.tscn` files is already translated by Godot and is left alone.

*Watch for:* `Scripts/UI/tooltip.gd` runs `KeyWordColors.ApplyKeywordColors` on the
description. Translation happens before that call. Step 2 of the overview replaces the
colouring itself.

### E. Tests
- **Sweep:** a new `Tests/unit/test_localized_display_text.gd`, modelled on
  `test_android_export_safety.gd`. It scans `Scripts/UI/` and `Scripts/Gear/` and fails
  on any `Types.<Enum>.keys()[`. The first assert is a non-zero file count.
- **Logic:** tests for the phase A helpers and for `Equipment.DescriptionText`. Each
  test registers a test `Translation` with `TranslationServer` for a test-only locale,
  asserts that the translated text comes back, and restores the previous locale in
  `after_each`.

## Exit criterion

With `internationalization/pseudolocalization/use_pseudolocalization` enabled in the
editor, no player-facing string outside `Scripts/Debug/` appears unaltered. Jonas runs
this check. The suite and `gdlint Scripts/` are green.

## Documentation

`Technical_Design_Document.md` gains the localization section named in the overview.
The sweep joins the Tier 2 table in `Test_Design_Document.md`.
