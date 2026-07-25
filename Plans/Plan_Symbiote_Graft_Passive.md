# Plan — Symbiote "Graft" passive (machinery)

## Context

The Symbiote's `Graft` passive is specified in `Concept_Document.md` (lines 159–161):
an ungrafted Symbiote may, once per lifetime, as a **free action** in battle (no turn
cost, reagent-style), target a living enemy and permanently graft onto it — gaining that
enemy's **graft effect**, an **attribute bonus**, and a **drawback**. The effect and
attribute bonus scale with the Symbiote's own rarity; the drawback is flat. The graft
sticks across all future battles, win or lose, and cannot be undone or replaced (get a
different graft by grafting a *different* Symbiote).

This plan builds the **machinery** only. The **pool of graft options** (the concrete
effects) is authored in `Symbiote_Graft_Pool.md`; this plan does not implement those
grafts, and the enemy-to-graft sourcing (which enemy offers which) is still deferred there
until more opponents are designed. The pool is deliberately varied — not just stat changes,
but effects that spawn a zone, interact with an ally, or interact with an enemy — so the
machinery must let a graft do anything a trait can do, not merely bump numbers. The
`GraftEffect`-extends-`CharacterTrait` model below satisfies that: grafts inherit the full
trait hook surface (buff ally, debuff enemy, place zone, deal damage) plus an
attribute-delta layer.

Depends on the Missing Role Champions work (the Symbiote preset exists,
`Data/Character_Player_Variants/Symbiote.tres`). Findings should be recorded in
`Technical_Design_Document.md` on completion.

## Architecture decisions

A graft is modeled as two reused systems layered together:

1. **Effect** = a `CharacterTrait` subclass. Grafts inherit every trait hook
   (`OnSkillCast`, `StartOfTurn`, `OnDamageTaken`, …) and the resolver vocabulary a trait
   already uses — `resolver.ApplyBuff` (ally), `resolver.ApplyDebuff` (enemy),
   `resolver.PlaceZone` (zone), `resolver.ResolveTraitDamage` (damage). Dispatch is reused
   verbatim: on graft we set the Symbiote's `_trait` to the graft effect, so every existing
   hook call site in `battle.gd` / `battle_resolver.gd` fires it with **zero new dispatch
   code**. The Symbiote preset carries no base trait, so `_trait` is free to hold the graft.

2. **Attribute bonus + drawback** = a **derived attribute layer**, mirroring how equipment
   already works (`Character.GetEquipmentBonus`, `character.gd:85–99`). `_attributes` stays
   the pristine ungrafted base; the graft delta is added on read inside
   `GetTotalAttribute`/`GetTotalAttributes`. Nothing is baked into `_attributes`, so there
   is a single source of truth (the graft identity) and no double-application on load.

**Persistence:** because the graft is a pure derived layer, the only thing that must be
saved is *which* graft — one new field `graft` (the `GraftEffect` resource UID) in
`CharacterCollection.Serialize`/`Deserialize`. The attribute bonus and effect are both
re-derived from that UID plus the Symbiote's rarity on load. `_attributes` serializes
unchanged.

**One-time gating:** the in-battle Graft button is shown only when the acting character's
role is Symbiote **and** it is ungrafted (`_graft == null`). Grafting fills `_graft`, so the
button never appears again for that instance.

## Steps

### 1. `GraftEffect` resource (base class)
- **New:** `Scripts/Character/character_traits/graft_effect.gd` —
  `class_name GraftEffect extends CharacterTrait`.
- Adds an `_attribute_delta: Dictionary[Types.Attribute, int]` computed in `Init(rarity)`
  from a subclass-supplied per-rarity **bonus** (scaled by rarity) merged with a flat
  **drawback**; exposes `GetAttributeDelta(attribute) -> int`.
- Inherits `_title`/`_body` (for the collection tooltip and battle trait icon) and the
  `_execution_steps` hook registration — the concrete grafts in `Symbiote_Graft_Pool.md`
  subclass this and register their hooks exactly like existing traits.
- **Shared texture:** the base class sets `_trait_texture` once to a single Graft-passive
  icon; concrete grafts do **not** each supply their own. Every graft displays the same
  passive icon, so `sorcerer_trait.gd`'s per-trait `_trait_texture = load(...)` is set here
  in the base `Init` and left alone by subclasses.
- **Watch for:** follow the existing rarity-dict convention (`const X_PER_RARITY`) seen in
  `sorcerer_trait.gd`; the bonus scales with rarity, the drawback does not.

### 2. Enemy preset field
- **`Scripts/Character/character_preset.gd`:** add
  `@export var _graft_effect: GraftEffect = null` (sibling of `_trait` at line 27).
  Populated per-enemy in the enemy `.tres` files once `Symbiote_Graft_Pool.md` assigns
  concrete enemy sources — left `null` for now.
- **Watch for:** enemies with `_graft_effect == null` are simply not graftable (targeting
  guard in step 5). Do not populate real enemy grafts in this plan.

### 3. `Character` — hold, layer, hydrate the graft
- **`Scripts/Character/character.gd`:**
  - Add `var _graft: GraftEffect = null` (runtime effect) and `var _graft_UID: String = ""`
    (persisted identity).
  - `GetTotalAttribute`/`GetTotalAttributes` (lines 91–100): add the graft delta the same
    way `GetEquipmentBonus` is added — `if _graft: value += _graft.GetAttributeDelta(attr)`.
  - Add `ApplyGraft(p_graft_effect: GraftEffect) -> void`: duplicate the effect,
    `Init(_rarity)`, assign to both `_graft` and `_trait`, set `_graft_UID` to the effect's
    resource UID. Used by both the in-battle resolve (step 5) and load (step 4).
- **Watch for:** a mid-battle graft that raises Health increases *max* health via
  `GetTotalAttribute(Health)`; current health is not auto-scaled (leave current health, only
  max grows — consistent with equipment).

### 4. Persistence
- **`Scripts/Character/character_collection.gd`:**
  - `Serialize` (lines 16–25): add `"graft": character._graft_UID`.
  - `Deserialize` (lines 39–62): after `InstantiateNew`, if `graft` is present and
    non-empty, `load(uid)` the `GraftEffect` and call `new_character.ApplyGraft(...)`.
- **Watch for:** old saves lack the `graft` key — guard with `character_data.has("graft")`
  and treat missing/empty as ungrafted (mirrors the `attribute_weights` guard at line 48).

### 5. In-battle Graft flow (button → target → confirm → resolve)
Model the entire flow on the reagent free-action seam.
- **`Scripts/UI/Battle_UI/battle_ui.gd`:** add a role-gated Graft button and its
  `battle_graft_selected` signal, mirroring `_on_reagent_N_button_up` /
  `battle_reagent_selected` (lines 152–162). Reuse `ButtonWithOptions`
  (`Scripts/UI/button_with_options.gd`) for **two** windows: the effect-description window
  ("Graft" / "Cancel") and the permanence confirm ("Are you sure? This is permanent.") —
  exactly as `_reagent_confirm` is instantiated and shown (lines 44–49, 109–116).
- **Scenes:** add the Graft button node to `Scenes/ui/Battle_UI/battle_ui.tscn` and wire
  `battle_graft_selected` in `Scenes/ui/Battle_UI/battle.tscn` (mirror line 89).
- **`Scripts/Battle/battle.gd`:**
  - In `StartTurn` (near the reagent-button population, ~lines 235–240), `show()` the Graft
    button only when `_characters[_turn_character_ID]._role` is Symbiote **and**
    `_graft == null`.
  - Add `BattleState.Selecting_Graft_Target` and route enemy clicks to it in
    `_on_character_battle_target_selected` (lines 458–461), reusing the living-target guard
    from `_OnReagentTargetSelected` (line 477). Reject targets whose `_graft_effect == null`.
  - Add `_ResolveGraft(p_symbiote_ID, p_target_enemy_ID)` modeled on
    `_ResolveReagentConsumption` (lines 544–556): call
    `symbiote.ApplyGraft(enemy._graft_effect)`, **also** write the graft onto the canonical
    collection instance via
    `main.GetInstance()._character_collection.GetCharacter(instance_ID).ApplyGraft(...)` so
    persistence is correct regardless of whether the battle `Character` shares the collection
    reference. If the graft subscribes to `Start_Combat`, call its `StartOfBattle` once here
    (battle already started). Call `RefreshVisuals` so the trait icon appears. **End with
    `_state = Awaiting_Player_Input` — never `CompleteTurn()`** (this is what makes it a free
    action).
- **Watch for:** the free-action seam is precisely the *absence* of `CompleteTurn()`
  (contrast `ResolveTurn`, lines 282–285). Do not advance the turn bar.

### 6. Inspect Collection display
- **`Scripts/UI/inspect_collection_menu.gd`:** add a `_selected_char_graft` Label and
  `_selected_char_graft_tooltip` ToolTip, populated only when the selected character's role
  is Symbiote (mirror the Nature block at lines 139–142): `"Graft: " + _graft._title` with
  the tooltip body from `_graft._body`; show "Graft: Ungrafted" when `_graft == null`; hide
  the row entirely for non-Symbiotes.
- **Scene:** add the label and tooltip nodes to the inspect-collection scene next to the
  Nature row.

### 7. Tests
- **New:** `Tests/unit/test_graft.gd` (GUT, pure logic only):
  - A minimal test-only `GraftEffect` subclass (a stat bonus + flat drawback + one hook,
    e.g. applies a buff) to exercise the machinery without depending on the pool content.
  - Assert `GetAttributeDelta` scales the bonus by rarity and keeps the drawback flat.
  - Assert `Character.GetTotalAttribute` includes the graft layer and `_attributes` stays
    the pristine base.
  - Assert `ApplyGraft` sets `_graft`/`_graft_UID` and that `_trait` now dispatches the
    graft's hook.
  - Assert `CharacterCollection.Serialize` → `Deserialize` round-trips the graft (identity
    re-hydrated, attribute layer restored) and that a save without a `graft` key loads as
    ungrafted.
- Do **not** test node/UI wiring (per `Test_Design_Document.md` conventions).

## Relationship to the graft pool document

This plan ships **no real graft content**. The concrete graft effects and their numbers are
specified in `Symbiote_Graft_Pool.md`; each entry there becomes one `GraftEffect` subclass
plus a one-line `.tres` (mirroring `Foresight_Trait.tres`) in a separate content pass. Each
enemy's `_graft_effect` assignment is still deferred in that document until more opponents
are designed. When both land, the only work is authoring those subclasses and `.tres` files
and setting `_graft_effect` on the enemy variant `.tres` files. No further engine changes
needed.

## Verification

1. **Tests:** run the GUT suite headlessly (per project `CLAUDE.md`) and confirm
   `test_graft.gd` and the existing suite are green.
2. **Lint:** `gdlint Scripts/` clean.
3. **Runtime (with a temporary test graft wired to one enemy):**
   - Enter a battle with a Symbiote; confirm the Graft button appears only on the Symbiote's
     turn and only while ungrafted.
   - Graft a living enemy; confirm the description window then the permanence confirm both
     appear, the action does **not** consume the turn, the Symbiote's attributes change by
     the expected rarity-scaled delta, and the effect fires in subsequent turns.
   - Confirm the button is gone for that Symbiote for the rest of the battle.
   - Save, reload; confirm the graft persists (effect + attribute delta) and the Inspect
     Collection menu shows "Graft: <name>" with the correct tooltip.
   - Lose or flee a battle after grafting a *second* Symbiote; confirm that graft also stuck.
   - Remove the temporary test graft wiring before finishing (content belongs to the future
     pool doc).
