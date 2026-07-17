# Plan: Reagent Inventory and Storage UI

Step 2 of 4 of the reagent system (`Concept_Document.md` 3.3.3). Adds the persistent
player-owned reagent inventory, reagent acquisition through battle loot, and an
out-of-combat storage UI to view and sell owned reagents. Combat usage comes later
in `Plan_Reagent_Combat_Application.md`.

## Status

Not started. Depends on `Plan_Reagent_Data_And_Catalog.md` (needs `ReagentData` and
the registry). Does not touch combat resolution (`BattleResolver`/`Skills.gd`); it
does extend `loot_manager.gd` and the post-battle reward flow.

## Design (from Concept_Document.md 3.3.3)

- Reagents are stored in a **persistent player inventory**; consuming one (later
  plan) permanently deletes it.
- Acquisition is **loot drops only** — looted primarily from the God of Magic's
  ruins and other encounters; **rarer reagents drop only from bosses**. Shop
  purchase is out of scope (follow-up for the 3.6.4 shop design).
- Reagents can be **sold** from the storage UI for Silver, mirroring equipment
  selling. Sell values scale with rarity; exact values are not yet decided —
  propose them to the user during implementation. Selling is the only
  out-of-combat way to remove a reagent (no separate discard); consumption in
  battle is the later plan.

## Target shape

- **`ReagentCollection`** (`Scripts/Gear/reagent_collection.gd`, `class_name
  ReagentCollection extends Node`): counts per reagent, keyed by the registry
  identifier string — `Dictionary[String, int]`. Methods `Add(p_reagent_key,
  p_amount)`, `Consume(p_reagent_key)` (decrement, erase at zero, false if absent),
  `GetCount`, `GetAllOwned`. Follows `Scripts/Gear/item_collection.gd` structurally.
- **Saveable**: joins `SaveManager.GROUP_SAVEABLE` in `_ready()` with
  `Serialize() -> Dictionary` / `Deserialize(p_data)` exactly like `ItemCollection`
  and `ResourceHandler` (`Scripts/Worldview/save_manager.gd`); no deserialization
  ordering dependency. Registered on the main instance alongside
  `_item_collection` (see `Scripts/main_instance.gd` / `main.GetInstance()`).
- **Acquisition** (`Scripts/Battle/loot_manager.gd` + `loot_table.gd`):
  - New `LootType.Reagent` with a `LOOT_VALUE` entry, a `_reagents` field on
    `LootTable.DropResult` (reagent keys), and a `Reagent` branch in
    `DistributeRewards` that rolls rarity through the existing `RARITY_WEIGHTING`
    machinery clamped to Uncommon–Legendary, then picks a random authored reagent
    of that rarity from the registry.
  - Boss gating: Epic and Legendary reagents only from boss loot tables. Boss
    tables (`Data/Loot_Tables/Adventure_Boss_Loot.tres`) gain the `Reagent` entry
    with the full rarity range; non-boss tables that should drop reagents get a
    rarity cap. Propose the exact cap and drop weights to the user before wiring.
  - Reward application: follow where `_drop_result` is consumed (post-battle flow,
    `Scripts/UI/Battle_UI/post_battle_menu.gd`) to credit the `ReagentCollection`
    and display the drop.
- **Storage UI**: lives inside `Scenes/ui/Inspect_Collection_Menu.tscn` /
  `Scripts/UI/inspect_collection_menu.gd` — no new scene, no hub navigation entry.
  - **Entry point**: a button in the bottom-left of the menu, next to the
    `MenuItemSlot` grid area, that opens a reagent grid window — a panel overlay
    (`ScrollContainer` + `GridContainer`, same 5-column layout as the existing
    grids) toggled visible over the menu, with its own close control.
  - **Grid**: one `MenuItemSlot` (`Scripts/UI/menu_item_slot.gd`) per owned
    reagent — icon via `SetHeldObjectTexture`, rarity outline via
    `SetTextureOutline`, owned count in the slot's `level` label (it is a plain
    count label here, not a level).
  - **Slot click**: opens a `ButtonWithOptions` (`uid://c7smqpmfvs0ih`,
    `Scripts/UI/button_with_options.gd`) titled with the reagent's name and a
    body describing its use (the `ReagentData` description, including the binary
    "not affected by potency modifiers" note where relevant), with a **Sell**
    option and the built-in **Cancel**. Sell goes through a confirmation
    `ButtonWithOptions` stating the Silver gained, red-colored confirm — the
    exact `TrySell`/`SellItem` pattern already in `inspect_collection_menu.gd`.
  - **Selling**: credits Silver via `main.GetInstance()._resources.AddSilver`,
    decrements the reagent through `ReagentCollection.Consume`, and refreshes the
    grid (slot removed when the count hits zero). Sell value from a new
    `LootManager` helper keyed off the reagent `LOOT_VALUE` entry and rarity,
    parallel to `GetSellValue` for equipment.

## Steps

1. **`ReagentCollection`** with add/consume/serialize, registered on the main
   instance and in the saveable group.
2. **Loot integration.** `LootType.Reagent`, `DropResult._reagents`, rarity-gated
   distribution, boss/non-boss loot table entries, post-battle crediting and
   display.
3. **Storage UI.** Bottom-left button in `Inspect_Collection_Menu.tscn`, reagent
   grid window, `ButtonWithOptions` describe/sell/cancel flow, sell resolution.
4. **Tests** (GUT, `Tests/unit/`): `test_reagent_collection.gd` — add/consume
   semantics (consume at zero fails, entry erased), `Serialize`/`Deserialize`
   round-trip, unknown-key handling on load (stale save vs. registry);
   `test_reagent_loot.gd` — rarity roll clamped to Uncommon–Legendary, boss-only
   gating for Epic/Legendary, dropped keys always exist in the registry, sell
   value scales with rarity; selling logic (decrement plus Silver credit) tested
   at the collection/value level. No UI rendering tests (per
   `Test_Design_Document.md` scope).

## Watch for

- Save compatibility: `Deserialize` must tolerate saves from before reagents
  existed (missing node data) and reagent keys no longer in the registry.
- `DistributeRewards` prints heavily and mutates a shared budget — mirror the
  existing budget-deduction style; don't restructure it (no refactoring unasked).
- Reagent drops must not starve existing loot types: adding `Reagent` to a table's
  secondary loot changes the weighted roll; check drop feel with the user.
- `ButtonWithOptions.SetLeftButton`/`SetMiddleButton` `connect` without checking
  for existing connections; the equipment flow re-calls them on every slot click.
  Wire the reagent popup's callbacks once (or disconnect first) to avoid duplicate
  signal connections.
- Selling a reagent that is part of a saved pre-battle state cannot happen yet
  (loadouts arrive in `Plan_Reagent_Combat_Application.md`), but the sell path
  must leave the collection consistent for that plan (counts never negative).
- Naming allowlist: no new acronyms in class, file, or scene names.

## Documentation

On completion: update `Technical_Design_Document.md` §6 (data model) and §10 (save
system) with `ReagentCollection`, and note the reagent loot type in whatever section
covers rewards. Record the agreed sell values in `Concept_Document.md` 3.3.3 (the
selling rule itself is already stated there). Note the shop follow-up in
`FeatureIdeas.md` if not already there.
