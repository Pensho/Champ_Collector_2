# Plan: Localization

Makes all player-facing text translatable, then ships the languages listed in
`Concept_Document.md` section 8. What already exists: a saved locale in
`Settings.locale`, applied through `TranslationServer.set_locale`
(`Scripts/settings.gd`); a language dropdown offering only English
(`LOCALE_BY_LANGUAGE_ID` in `Scripts/UI/settings_menu.gd`); and Godot's automatic
translation of the static text in `.tscn` files.

## Status

Nothing implemented. Each step below gets its own detailed plan, written when the
step before it completes, so it builds on what that step shipped. Step 1's plan is
`Plan_Localization_Text_Preparation.md`.

## Conventions (confirmed decisions)

- **gettext `.po` files, English source text as the key.** The `.tres` resources and
  scripts stay the single home of the English text; each language is one `.po` file.
- **Translate at display time only.** Data resources, the battle core, identity keys and
  save files hold English source text. A view translates when it sets text on a node.
- **`tr()` / `tr_n()`** in object code; **`TranslationServer.translate()` /
  `translate_plural()`** in static functions.
- **Sentences are whole templates.** A sentence with variable parts is one translated
  string with named placeholders, filled after translation. Counts use the plural forms.
- **Language changes apply when a screen next opens.** Text set by scripts is not
  refreshed live.

## Steps

### 1. Text preparation
Every player-facing string reaches the screen through translation: enum display names,
sentences built by scripts, data text (names, descriptions) and literal strings in
scripts. Adds a sweep test that blocks raw enum names as display text.
*Exit:* with pseudolocalization enabled, no player-facing string appears unaltered.

### 2. Keyword markup
`Scripts/keyword_colors.gd` colours keywords by matching English words, which fails on
translated text. Replace it with explicit markup in the source text, resolved to colour
at display, and migrate the `.tres` descriptions to the markup.
*Exit:* keyword colouring no longer depends on the display language.

### 3. Extraction pipeline
Godot's POT generation over scenes and scripts, plus an `EditorTranslationParserPlugin`
that extracts the player-facing fields of the `.tres` resources. Defines how the `.po`
files are updated when source text changes.
*Exit:* one command or editor action produces a complete template.

### 4. Layout for text expansion
Pseudolocalization's expansion setting approximates longer languages. Fix the controls
that overflow or clip at the 1280×720 base viewport.
*Exit:* every screen stays readable with expansion on.

### 5. Tier 1 languages
German, Spanish and French `.po` files (Swedish if pursued), their
`LOCALE_BY_LANGUAGE_ID` entries, and each language listed under its own name in the
dropdown.
*Exit:* each Tier 1 language is selectable and complete against the template.

### 6. Tier 2 languages (optional)
Fallback fonts in the theme for Chinese, Japanese, Korean and Cyrillic glyphs, and line
breaking for scripts written without spaces. Then the four `.po` files.
*Exit:* each Tier 2 language is selectable and renders without missing glyphs.

## Watch for

- **Display names are identity keys.** The battle core builds keys from skill and zone
  names (`battle_resolver.gd`, `damage_effect.gd`) and `CharacterCollection` keys by
  `Character._name`. These stay English; only the view translates.
- `Scripts/Debug/`, logging and `print()` output are out of scope.
- Project conventions: full type hints, the naming allowlist, UI nodes authored in
  `.tscn` files.

## Documentation

`Technical_Design_Document.md` gains a localization section stating the conventions
above as each step lands. New sweeps join the Tier 2 table in `Test_Design_Document.md`.
