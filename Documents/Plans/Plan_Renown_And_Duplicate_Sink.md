# Plan — Renown and the Duplicate Sink

## Context

The gacha loop has no sink. `CharacterCollection.Add()` silently refuses once the roster is
full and `IncreaseCollectionSize()` is never called by anything, so a player hunting a good
**Nature** (the rolled `AttributeWeightPreset` on each instance) accumulates duplicates with
no way to convert or discard them. `Concept_Document.md` 3.1.2 promises an Ascension system
in one line and 3.1.1 carries an unused **Rank** placeholder; neither is implemented.

This plan closes the loop with four connected pieces:

- **Release** — dismiss a champion for Silver + Supplies + Tallies.
- **Tallies** — the duplicate-conversion currency.
- **Renown** — five ranks per champion, each costing one duplicate of that champion and
  granting +6% of base in a chosen attribute (Speed +3%). This is what 3.1.2 called
  Ascension and what 3.1.1's Rank placeholder becomes.
- **Renown Board** — a three-slot deterministic champion counter in the Adventurer's Guild,
  bought with Tallies.

Plus wiring the dormant roster-slot purchase, which is what makes the cap a live decision.

Renown rank art arrives later; the display is built so swapping in textures is one edit.

---

## Phase 1 — Renown on `Character`

**Files:** `Scripts/Character/character.gd`, `Scripts/game_balance.gd`

Add to `Character`:

```gdscript
## Renown ranks spent per attribute. Each rank grants a percentage of the base sheet.
var _renown: Dictionary[Types.Attribute, int] = {}
```

`_renown` stores ranks per attribute; total rank is the sum of its values, capped at
`GameBalance.RENOWN_MAX_RANK`. Stacking within one attribute is uncapped.

**Where the bonus applies — fold it into `GetBaseAttributes()`:**

```gdscript
func GetBaseAttributes() -> Dictionary[Types.Attribute, int]:
	var attributes: Dictionary[Types.Attribute, int] = _attributes.duplicate(true)
	for attribute: Types.Attribute in _renown.keys():
		var percent: int = (GameBalance.RENOWN_SPEED_BONUS_PERCENT
				if Types.Attribute.Speed == attribute
				else GameBalance.RENOWN_ATTRIBUTE_BONUS_PERCENT)
		attributes[attribute] += int(_attributes[attribute] * _renown[attribute] * percent / 100.0)
	return attributes
```

This is deliberate and is the key architectural decision in the plan. `Character.GetTotalAttributes()`
and `BattleResolver.GetEffectiveAttributes()` are two separate pipelines
(`Technical_Design_Document.md` section on the five contributor steps) that both begin with
`GetBaseAttributes()`. Folding Renown into step 1 means Renown is part of the character's own
sheet everywhere — combat, display, reagent %-scaling, status snapshots — with no call-site
changes and no risk of the two pipelines disagreeing. Adding a sixth step instead would require
editing both and auditing every site that deliberately reads a partial stack.

It also gives the property that motivated the design: `_attributes` grows on every level-up
(`level_system.gd:31` distributes points by Nature weight), so the bonus is recomputed from the
current sheet on every read. Ranking up at level 12 is never wasted and never front-loads power.
Note `LevelSystem` writes to `_attributes` directly, not through `GetBaseAttributes()`, so
Renown never compounds into the stored sheet.

**New constants in `game_balance.gd`:**

```
RENOWN_MAX_RANK: int = 5
RENOWN_ATTRIBUTE_BONUS_PERCENT: int = 6
RENOWN_SPEED_BONUS_PERCENT: int = 3
RENOWN_ATTRIBUTES: Array[Types.Attribute]   # the 8 in AttributeWeightPreset._weights
```

`RENOWN_ATTRIBUTES` is exactly the attribute set `AttributeWeightPreset._weights` uses, which
excludes `CritChance` and `CritDamage` structurally — no special case needed.

**Helpers on `Character`:** `GetRenownRank() -> int` (sum), `CanGainRenown() -> bool`,
`AddRenown(p_attribute)` which rejects an attribute outside `RENOWN_ATTRIBUTES` and rejects
a call past the cap.

## Phase 2 — Tallies on `ResourceHandler`

**File:** `Scripts/Worldview/resource_handler.gd`

Mirror the Silver members exactly: `_tallies: int`, `GetTallies()`, `AddTallies()`,
`SpendTallies() -> bool`, each emitting `resources_changed`. Add `"tallies"` to `Serialize()`
and read it in `Deserialize()` with `p_data.get("tallies", 0)` so existing saves load.

**Balance:** `TALLY_VALUE_PER_RARITY: Dictionary[Types.Rarity, int]` in `game_balance.gd` —
Uncommon 1, Rare 4, Epic 20, Legendary 100. Common is in the `Types.Rarity` enum but there are
no Common playable champions (`Concept_Document.md` 3.1); give it 0 rather than omitting it, so
a lookup can never fail.

Display: add a Tally entry to the resource bar (`Scripts/UI/resource_bar.gd`,
`resource_ui_slot.gd`) following the Silver/Supplies pattern, with a placeholder texture
constant until art arrives.

## Phase 3 — Release, in the Armory

**File:** `Scripts/UI/inspect_collection_menu.gd`, `Scenes/ui/Inspect_Collection_Menu.tscn`

Model directly on the existing `TrySell()` / `SellItem()` pair (lines 268–283): a "Release"
button on the selected-character options, then `_confirm_option` with the red destructive
colour already used for selling.

- Payout: Silver and Supplies by rarity from new `game_balance.gd` tables, plus
  `TALLY_VALUE_PER_RARITY` Tallies. Scale the Silver half by level the way the design sketch
  had it (`×(1 + level / 25)`); keep Supplies and Tallies flat per rarity so the confirm text
  stays short.
- Clear `_held_items` before removing the character. The items themselves live in
  `ItemCollection` and are untouched, so this is a plain unequip, not a delete.
- Guard: refuse to release if it would empty the roster, and refuse if the character is the
  currently selected one in a way that leaves the panel pointing at a dead ID — reuse
  `_on_button_deselect_char_button_up()` to clear selection before `RefreshDisplayedItems()`.
- No guard is needed against saved parties or an in-progress adventure: neither stores
  character information, so a released champion cannot be referenced from elsewhere.

## Phase 4 — Spending duplicates on Renown

**Files:** `Scripts/UI/inspect_collection_menu.gd`, new `Scenes/ui/Renown_Window.tscn` +
`Scripts/UI/renown_window.gd`

An "Ascend" button on the selected character opens a small window with the five rank pips and
one button per attribute in `RENOWN_ATTRIBUTES`, each showing its current rank and what the
next rank grants in absolute terms (computed from the live base sheet, so the number the player
sees is the number they get).

**Cost: one duplicate of the same champion, chosen by the player.** A duplicate is any other
instance sharing `_name`. Choosing an attribute opens a sacrifice picker listing every eligible
duplicate with its portrait, level, Nature and Renown rank, so the player can keep the instance
with the Nature they want and spend the rest. Selecting one raises the red confirm naming that
instance; confirming consumes it through the same removal path as Release, paying nothing.

Build the picker as a **selection mode over the existing character grid** rather than a second
grid: `_available_characters` is already a pool of `MenuItemSlot` sized to the collection, so
the picker hides every slot that is not an eligible duplicate, swaps the slot callback to the
sacrifice handler, and restores normal browsing on cancel. This reuses the pool instead of
allocating a parallel one, and a duplicate count is bounded only by roster size, so a fixed
preallocated popup grid would either be wastefully large or silently truncate.

Disable the button with an explanatory line when there is no duplicate, or when
`GetRenownRank()` is already at `RENOWN_MAX_RANK`.

**Display:** rank pips as a row of five `TextureRect` nodes authored in the scene, driven by a
filled/empty texture pair in a constant. Until the art lands, point both at a placeholder; the
swap is then one line. Show the rank beside level on the character panel
(`_selected_char_level` area) as well as in the window.

## Phase 5 — The Renown Board

**New files:** `Scripts/Worldview/renown_board_handler.gd`,
`Scripts/UI/renown_board_menu.gd`, `Scenes/Hubs/Adventurers_Guild/Renown_Board.tscn`

`RenownBoardHandler` mirrors `ShopHandler` closely enough that it should be written by reading
`shop_handler.gd` first and following it structurally:

- `_offers: Array[Dictionary]`, `_restock_anchor_unix: int`, `stock_changed` signal, registered
  in `SaveManager.GROUP_SAVEABLE` from `_ready()`, instantiated in `main_instance.gd::Init()`
  next to `_shop`.
- Static, testable time predicates copied in shape from `IsRestockDue()` /
  `GetSecondsUntilRestock()`, against a new `RENOWN_BOARD_RESTOCK_INTERVAL_SECONDS`.
- `RollOffers()` picks `RENOWN_BOARD_SLOTS` (3) distinct champions from the union of the three
  `FortuneFavorTier.recruitable_champions` arrays (`Data/Recruitment/*.tres`), storing
  `preset_path`, rarity, price, and `sold_out`. Price by rarity from a new
  `RENOWN_BOARD_PRICE_PER_RARITY` table, set well above `TALLY_VALUE_PER_RARITY` for the same
  rarity so the board is a long-term goal rather than a wash.
- `Purchase(p_index)` refuses when sold out, when Tallies are insufficient, or when
  `IsTheCollectionFull()`; otherwise spends Tallies, calls `CharacterCollection.Add()` — which
  rolls a random Nature in `InstantiateNew()`, so a board champion is not a Nature shortcut —
  and marks the slot sold out.

`renown_board_menu.gd` follows `shop_menu.gd` (grid refresh, countdown tick, confirm dialog),
reusing `Scenes/ui/Shop_Slot.tscn` if its layout takes a portrait cleanly, otherwise a sibling
scene copied from it. Entry point: a new button in `Scripts/UI/adventurers_guild_menu.gd`
beside `_on_fortunes_favor_button_up()`.

## Phase 6 — Roster slot purchase

**Files:** `Scripts/Character/character_collection.gd`, `Scripts/UI/inspect_collection_menu.gd`

`IncreaseCollectionSize()` currently prints "maximum size reached" on every call including
successful ones. Fix that (print only in the failing branch) and return `bool`.

Add `GetRosterSlotPrice(p_current_max: int) -> int` as a static on `CharacterCollection` — a
rising curve keyed off how far past `COLLECTION_START_ROSTER_SIZE` the roster already is — and
a buy-a-slot button in the Armory using the existing confirm-dialog pattern.

## Phase 7 — Persistence

**File:** `Scripts/Character/character_collection.gd`

Add `"renown": character._renown.duplicate(true)` to the `Serialize()` dictionary and read it
back in `Deserialize()` with a `.has()` guard and integer key casting, matching how
`attributes` and `held_items` are already restored. `RenownBoardHandler` gets its own
`Serialize()`/`Deserialize()` for offers and the restock anchor, following `ShopHandler`.

## Phase 8 — Tests

`Tests/unit/`, GUT, run with `./Tests/run_tests.sh`. Logic only, no node trees.

- **`test_renown.gd`** — the load-bearing file. A rank grants exactly 6% of the *base* value;
  Speed grants 3%; five ranks in one attribute give +30% and are allowed; the sixth is refused;
  an attribute outside `RENOWN_ATTRIBUTES` (crit chance, crit damage) is refused; the bonus
  grows after a level-up without any re-application call (the living-modifier property); the
  bonus does **not** scale off equipped gear — build a character with gear and assert the
  Renown delta matches base-only maths. Also cover the sacrifice-eligibility rule as a pure
  function over a collection: candidates share `_name`, exclude the character being ascended,
  and an empty candidate list is what disables the button.
- **`test_renown_board_handler.gd`** — restock predicates at boundary times; `RollOffers()`
  returns three distinct champions; price follows rarity; `Purchase()` refuses on insufficient
  Tallies, on sold out, and on a full roster, and deducts exactly once on success.
- **`test_release_value.gd`** — payout per rarity and the level scaling on the Silver half.
- Extend **`test_resource_handler.gd`** — Tallies add/spend/refuse-when-short, and a
  round-trip where a legacy save dictionary without `"tallies"` loads as 0.
- Extend **`test_collection_serialization.gd`** — Renown survives a save/load round trip; a
  character dictionary with no `"renown"` key loads at rank 0.
- Extend **`test_shop_handler.gd`** pattern for the roster-slot price curve, or add a small
  case to an existing collection test.

Then `gdlint Scripts/` (scope is `Scripts/` only) and fix warnings before calling it done.

## Phase 9 — Documentation

All edits net-neutral where a decision replaces prior text; report the per-file word delta.

- **`Concept_Document.md` 3.1** — delete the "future idea to use duplicate heroes as a mean to
  increase it a few steps at most (or to upgrade skills)" sentence. Superseded, and the skills
  branch is not real.
- **`Concept_Document.md` 3.1.1** — rename the secondary-attribute placeholder **Rank** to
  **Renown**. Faction stays as it is.
- **`Concept_Document.md` 3.1.2** — replace the one-line Ascension bullet with the Renown spec:
  five ranks, one duplicate of that champion per rank, +6% of base in a chosen attribute (Speed
  +3%), stacking uncapped, applied to the base sheet before gear, crit attributes excluded.
- **`Concept_Document.md` 3.6.2 The Armory** — add Release (Silver + Supplies + Tallies by
  rarity) and the roster-slot purchase.
- **`Concept_Document.md` 3.6.3 The Adventurer's Guild** — add the Renown Board: three slots,
  restock cadence, Tally price by rarity, champions arrive with a rolled Nature.
- **`Technical_Design_Document.md`** — the five-step contributor list: step 1 is now "base
  sheet + Renown", stated once at `GetBaseAttributes()` and not repeated in the
  `GetEffectiveAttributes()` walkthrough. Add `RenownBoardHandler` wherever `ShopHandler` is
  listed among the saveable handlers.
- **`Remaining_Scope_Checklist.md`** — tick "Ascension system"; note that Renown rank art is
  outstanding if the art backlog is the right home for it.
- **`FeatureIdeas.md`** — no change; the Nature Reroll entry is already captured.

---

## Watch for

- **Renown never enters `_attributes`.** The stored sheet stays raw; the percentage is
  computed on read. Any code that writes a Renown result back into `_attributes` breaks the
  living-modifier property and compounds on the next rank.
- **Board champions always roll a Nature.** If a future change lets the board hand over a
  fixed-Nature champion, the board silently replaces the duplicate hunt.
- **Backward-compatible saves.** Every new serialized key is read with a default, never a
  bare index — existing save files must open.
- **Naming.** Renown, Tally, Nature and every new identifier spelled out in full; the
  project allowlist (`UI`, `RPG`, `XP`, `ID`, `UID`, `JSON`, `URL`, `GUT`, `HP`, `AoE`) does
  not grow for this work.
- **No plan references in code.** No comment may mention this plan, its filename, or a phase
  number — the file is deleted on completion.
- **Rank art.** The pip display stays driven by a texture-pair constant so the art the user
  supplies later is a one-line swap, not a scene rebuild.

## Verification

1. `./Tests/run_tests.sh` green, including the new files.
2. `gdlint Scripts/` clean.
3. Headless check of the pure logic, per the project's working pattern — a bare `SceneTree`
   script that builds a `Character`, applies Renown, levels it, and prints the attribute deltas
   is reliable; anything touching `main.GetInstance()` is not, so leave those paths to GUT.
4. Save/load round trip: create a character with Renown and Tallies, save, reload, confirm both
   restore; then load a save file created before this change and confirm it opens with rank 0
   and 0 Tallies.
5. No visual verification — there is no display available here. Screen-level behaviour
   (the board grid, the Renown window, the Release confirm) is for the user to look at.

## Order and checkpoints

Phases 1–2 (data model and currency) are the foundation and should land with their tests before
any UI. Phase 3 (Release) is the smallest complete player-facing loop and is the natural first
checkpoint. Phases 4–6 are independent of each other and can be done in any order. Phases 7–8 run
alongside each preceding step rather than at the end. Phase 9 lands before the work is presented.

Changes are left unstaged for review.
