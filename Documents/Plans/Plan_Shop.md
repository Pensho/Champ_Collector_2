# Plan: The Shop

Implements `Concept_Document.md` 3.6.4 — the Reclaimed City shop. Six stock slots that
restock on a one-hour real-world timer, plus a featured Fortune's Favor offer on its own
three-day cooldown. Closes `Remaining_Scope_Checklist.md`'s shop line and the
`FeatureIdeas.md` "Reagent Shop Purchase" entry.

Layout follows a reference design (exit button top-right, heading block top-left, tall
shopkeeper portrait column on the left, 2×3 card grid on the right, cards showing
rarity/category, art, name, price and a Buy button, dimmed when sold out, a featured ribbon
on the Favor slot). Layout only — colors, fonts and styling come from
`default_theme.tres`.

Phases 1–4 are the model and are independently testable; phases 5–7 are the scene; phase 8
is the document pass. Phases run in order.

## Decisions

| Question | Decision |
|---|---|
| Slot split | 3 gear / 1 reagent / 1 supplies / 1 Fortune's Favor (featured) |
| Stock quality | Budget derived from player progress, fed to the existing `LootManager` rarity rolls |
| Favor offer | Always Bone tier, fixed Silver price |
| After purchase | Slot stays sold out until the next restock; the Favor slot waits out its 3 days |
| Restock clock | Wall-clock unix anchor, persisted in the save, offline-aware |

The restock timer and the Favor cooldown are new design the Concept Document does not yet
cover; phase 8 records them.

## Phase 1 — `EquipmentPresetRegistry`

**New:** `Scripts/Gear/equipment_preset_registry.gd`

The shop must pick a random gear preset and persist which one it picked. Gear presets have
no id-keyed lookup today — `Data/Item_Presets/` holds only `Red_Boots.tres`,
`Shield_Basic.tres` and `Weapon_Basic_Spear.tres`, and battle loot reaches them through a
single `LootTable._gear_loot` export.

Mirror `Scripts/Battle/reagent_registry.gd`: `const PRESETS: Dictionary[String,
EquipmentPreset]` of preloads keyed by the `.tres` base name, `Get(p_id)`, `GetRandomKey()`.
Preload-based, not `DirAccess` — same Android-export reason stated in `reagent_registry.gd`.

Only three presets exist, so three gear slots repeat presets. Rarity varies per slot, so the
cards still differ.

## Phase 2 — Progress-driven budget

**Modify:** `Scripts/Worldview/progress_handler.gd`

Add `GetHighestDifficulty() -> int`: the maximum value in `_stage_difficulty`, or `1` when
empty. This is the shop's quality driver — `LootManager.CalculateBudget()` already maps
difficulty 1–20 onto a budget of 159–50456.

## Phase 3 — Balance constants

**Modify:** `Scripts/game_balance.gd`, a `# Shop` block after `# Resources`

```
SHOP_SLOT_COUNT: int = 6
SHOP_GEAR_SLOTS: int = 3
SHOP_RESTOCK_INTERVAL_SECONDS: int = 3600
SHOP_FORTUNES_FAVOR_COOLDOWN_SECONDS: int = 259200   # 3 days
SHOP_BUY_MARKUP: float = 2.5
SHOP_SUPPLIES_BUNDLE_AMOUNT: int = 25
SHOP_SUPPLIES_PRICE: int = 400
SHOP_FORTUNES_FAVOR_PRICE: int = 1200
```

## Phase 4 — `ShopHandler`

**New:** `Scripts/Worldview/shop_handler.gd` (`class_name ShopHandler extends Node`)
**Modify:** `Scripts/main_instance.gd` — add `_shop: ShopHandler`, created and added as a
child in `Init()` alongside `_resources` and `_progress`.

Follow the `ResourceHandler` shape: `_ready()` sets `self.name =
self.get_script().get_global_name()` and calls `add_to_group(SaveManager.GROUP_SAVEABLE)`.
Without the `class_name`-derived node name the save writes under a generic key.

State:
- `_stock: Array[Dictionary]` — six entries; index 0–2 gear, 3 reagent, 4 supplies, 5
  Fortune's Favor.
- `_restock_anchor_unix: int`
- `_favor_purchase_unix: int`

Stock entry, JSON-safe values only (strings, ints, bools):
`{"category": Category, "rarity": int, "price": int, "sold_out": bool, "payload": String,
"amount": int}` where `payload` is a preset id, a reagent key, or `""`.

Static functions taking `now` as a parameter — this is what makes the timers testable
without mocking the clock, as `ResourceHandler.ComputeSupplyRegen` already does:
- `IsRestockDue(p_anchor_unix, p_now_unix) -> bool` — true when the anchor is unset or
  `now - anchor >= SHOP_RESTOCK_INTERVAL_SECONDS`
- `GetSecondsUntilRestock(p_anchor_unix, p_now_unix) -> int`
- `IsFavorAvailable(p_last_purchase_unix, p_now_unix) -> bool`
- `GetSecondsUntilFavor(p_last_purchase_unix, p_now_unix) -> int`
- `RollStock(p_budget: int) -> Array[Dictionary]` — builds all six entries
- `GetGearPrice(p_rarity)` / `GetReagentPrice(p_rarity)` — `LootManager.GetSellValue()` and
  `GetReagentSellValue()` times `SHOP_BUY_MARKUP`, so buy and sell prices stay tied to one
  formula

Instance functions:
- `EnsureFresh()` — when `IsRestockDue`, reroll `_stock`, set the anchor to `now`, emit
  `stock_changed`. The anchor becomes `now` rather than carrying a remainder, so a long
  absence yields exactly one reroll.
- `Purchase(p_slot_index) -> bool` — rejects a sold-out slot, calls
  `ResourceHandler.SpendSilver()`, grants, marks `sold_out`, and for slot 5 stamps
  `_favor_purchase_unix`.
- `Serialize()` / `Deserialize()` — cast every number with `int(...)` on load; JSON returns
  floats, as `progress_handler.gd:19` handles.

Rolls reuse `LootManager` unchanged: `GetBestRarityForItem` + `RollRarityForItem` for gear;
`GetBestRarityForReagent` + `RollRarityForReagent` + `ReagentRegistry.GetRandomKeyForRarity`
for the reagent slot.

Granting reuses the existing paths — no new inventory code: `ItemCollection.AddPreset()`
(after `duplicate(true)`, setting `_rarity` and calling `Setup()`, as
`LootManager.DistributeRewards` does), `ReagentCollection.Add()`,
`ResourceHandler.AddSupplies()`, `ResourceHandler.AddFortunesFavor(BONE, 1)`.

**Tests** — `Tests/unit/test_shop_handler.gd`, modelled on `test_resource_handler.gd`
(which builds `now = int(Time.get_unix_time_from_system())` and passes `now - 2100` as an
anchor) and `test_recruitment_manager.gd`. Cover: restock not due below the interval, due at
and past it, due when the anchor is unset; a multi-hour absence yielding one reroll with the
anchor at `now`; countdown seconds at the interval boundaries; Favor available when never
purchased, blocked inside three days, available at exactly three days; `RollStock` returning
`SHOP_SLOT_COUNT` entries with the 3/1/1/1 split and a positive price on each; gear and
reagent prices equal to the `LootManager` sell value times the markup; serialize →
deserialize round-tripping stock, anchor and Favor timestamp with ints intact. Free the node
at the end of each test. Logic only — no scene or grid tests.

## Phase 5 — Shop card scene

**New:** `Scenes/ui/Shop_Slot.tscn` + `Scripts/UI/shop_slot.gd` (`class_name ShopSlot`)

Modelled on `Scenes/ui/Menu_Item_Slot.tscn`: the same `outline.gdshader` ShaderMaterial for
the rarity ring and the same `default_theme.tres`. `MenuItemSlot` itself is not reusable — it
carries no price row or Buy button.

Nodes: a category label top-right, an icon `TextureRect` with the outline material, a name
`Label`, a price row (Silver coin `TextureRect` + `Label`), `Button_Buy`, and a
`Label_Ribbon` shown only on the featured slot.

Script: `Setup(p_entry: Dictionary)` fills every field and applies the rarity outline (reuse
the color match in `menu_item_slot.gd:18-36`); `SetSoldOut(p_sold_out)` sets `modulate.a =
0.55`, the button text to "Sold Out" and `disabled = true`; `ConnectButton(p_callback:
Callable)` binds the slot index, the same idiom as `MenuItemSlot.ConnectButton`.

## Phase 6 — Shop scene and menu script

**New:** `Scenes/Hubs/Reclaimed_City_Scene/Shop.tscn` + `Scripts/UI/shop_menu.gd`
(`class_name ShopMenu extends Control`)

Copy the scaffolding from `Scenes/Hubs/Adventurers_Guild/Recruitment.tscn` — full-screen
`Control` root, `Background` TextureRect, an instanced `Resource_Bar.tscn`
(`uid://bm6xwrr37gevr`, which supplies the Silver/Supplies/Favor display), `Button_Back`
anchored top-right, `node_paths=PackedStringArray(...)` label wiring.

Layout:
- `Label_Title` top-left — the shop name heading
- `Label_Restock` beneath it — the countdown, `"Restocks in %02d:%02d:%02d"` in
  `ResourceBar.SUPPLY_REGEN_COUNTDOWN_COLOR` (`#E6D29E`)
- `Button_Back` top-right (the design's X button)
- `TextureRect_Shopkeeper` — left column, ~400px wide, full body height
- `ScrollContainer > GridContainer` (`columns = 2`) on the right, holding six `ShopSlot`
  instances

Script:
- `Init(p_context_container)` instantiates three `ButtonWithOptions`
  (`uid://c7smqpmfvs0ih`) for confirm / insufficient-Silver / result, centred and hidden —
  the same shape as `recruitment_menu.gd:17-32`
- `_ready()` calls `main.GetInstance()._shop.EnsureFresh()`, then `RefreshGrid()`, connects
  `resources_changed`, and adds a 1-second `Timer` (as in `resource_handler.gd:24-28`) whose
  handler updates the countdown label and calls `EnsureFresh()`, so the grid rerolls live if
  the shop is left open past the hour
- `RefreshGrid()` — `queue_free()` the old slots, instantiate one `ShopSlot` per stock entry,
  `add_child` to the grid, `Setup()`, `ConnectButton(_on_slot_pressed)`; follows
  `inspect_collection_menu.gd:273`
- Slot 5 shows the ribbon; while the Favor cooldown runs it renders sold out with the days
  remaining in place of the price
- `_on_back_button_up()` builds a `ContextContainer` with `_scene = "uid://cfdrcdtsx2jh7"`
  (Reclaimed City) and calls `main.GetInstance().change_scene(...)`

## Phase 7 — Hub wiring

**Modify:** `Scripts/UI/hub_menu.gd` — add `_on_button_shop_button_up()` navigating to the
Shop scene's uid, matching the four existing handlers.
**Modify:** `Scenes/Hubs/Reclaimed_City_Scene/Reclaimed_City.tscn` — one `[connection]` line
for `Navigation_Buttons/Button_Shop`, alongside the four at lines 180–183. The button and its
label already exist in the scene and are currently dead.

## Phase 8 — Documents

- `Concept_Document.md` 3.6.4 — replace the two-line stub with the shop's rules: six slots,
  the 3/1/1/1 split, hourly restock on real-world time, the Bone Favor offer on a three-day
  cooldown, sold-out-until-restock, and stock quality scaling with progress. Net growth,
  justified: 3.6.4 currently specifies almost nothing.
- `Technical_Design_Document.md` — add `ShopHandler` to the runtime and persistence sections.
- `FeatureIdeas.md` — delete the "Reagent Shop Purchase" entry; it ships here.
- `Remaining_Scope_Checklist.md` — tick the shop line.
- `Plans/README.md` — add this plan to the code-plan list when work starts, and delete it
  along with this file on completion, per the retention rule.

## Watch for

- `ResourceHandler.AddSupplies` does not clamp to `MAX_SUPPLIES`, so buying a bundle can push
  the player over the cap. Consistent with the existing function; left as-is.
- No shopkeeper art exists. Phase 6 reserves the node and points it at an existing scenery
  texture; it needs an art pass.
- Selling stays in the Armory (`inspect_collection_menu.gd`); the shop is purchase-only.
- No new equipment presets are authored here — the shop stocks the three that exist.
- `gdlint Scripts/` must stay clean; `class-definitions-order` is the usual offender on new
  scripts (see the `gdlint-fixes` skill).

## Verification

1. `./Tests/run_tests.sh` — full suite green, including `test_shop_handler.gd`.
2. `gdlint Scripts/` — clean.
3. Enter Reclaimed City, click Shop: the scene opens, six cards are populated, the countdown
   ticks down.
4. Buy a gear card → Silver drops, the card dims to "Sold Out", the item appears in the
   Armory. Buy the reagent → it appears in reagent storage. Buy Supplies → the resource bar
   rises.
5. Buy the Fortune's Favor → the Bone count rises by one, the featured slot switches to its
   cooldown display, and the Adventurer's Guild shows the new Favor.
6. Back returns to Reclaimed City.
7. Save, quit, relaunch, load — sold-out flags and both timers survive. Then temporarily
   lower `SHOP_RESTOCK_INTERVAL_SECONDS` to ~60 to watch a live reroll, and restore it before
   committing.
