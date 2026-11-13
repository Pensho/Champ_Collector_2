# Plan: Reagent Attunement

Players hoard or sell reagents instead of consuming them. Attunement is an account-wide
experience track that rewards consumption: each reagent drawn in battle grants Attunement
experience, and each rank raises the highest reagent rarity the player can obtain from any
source. Reagent sell values are lowered alongside it so selling stops being the better use.

## Rules

| Rarity drawn | Attunement experience |
|---|---|
| Uncommon | 1 |
| Rare | 3 |
| Epic | 9 |
| Legendary | 30 |

| Total experience | Highest obtainable rarity |
|---|---|
| 0 | Uncommon |
| 10 | Rare |
| 30 | Epic |
| 90 | Legendary |

- Experience is granted when an inventory reagent is consumed in battle. Alchemist brews
  never enter the inventory and grant none; selling grants none.
- The cap applies to every reagent rarity roll: battle loot, Escalate, the shop's reagent
  slot, and the starting reagents of a new game. It clamps the result of the existing roll
  and replaces none of the existing limits (loot table maximum, budget-derived best rarity).
- All six numbers are balance values, tuned later.

## Steps

### 1. Attunement logic
New `Scripts/Battle/reagent_attunement.gd` (`ReagentAttunement`, static functions):
`ExperienceForRarity(rarity)`, `MaxRarityForExperience(experience)`,
`ExperienceToNextRank(experience)` (0 at Legendary). The two tables live in `GameBalance`.
Tests: `Tests/unit/test_reagent_attunement.gd` — every threshold edge (9/10, 29/30, 89/90),
each rarity's experience, next-rank distance at the top.

### 2. Persisted experience and the draw path
`ReagentCollection` gains `_attunement_experience: int`, saved under a new `"attunement"`
key; a save without the key loads as 0, and `Reset()` clears it. Add
`ReagentCollection.Draw(key) -> bool`: consumes like `Consume` and adds the reagent's
experience. `ReagentLoadout.TryConsume` calls `Draw` for non-brewed slots; the sell path in
`inspect_collection_menu.gd` keeps calling `Consume`. `ReagentLoadout` tracks experience
gained this battle for the results screen.
Tests: extend `test_reagent_collection.gd` (draw grants experience, consume does not,
serialize round-trip, missing-key load) and `test_reagent_loadout.gd` (brewed slot grants
none, per-battle total).

### 3. Apply the cap to every roll
- `LootManager.DistributeRewards`: both reagent branches pass
  `min(loot table maximum, attunement cap)` to `RollRarityForReagent`. Take the cap as a
  parameter so the function stays testable without `main.GetInstance()`; every caller
  (battle rewards, Escalate context) supplies it.
- `ShopHandler.RollStock`: pass the attunement cap where it passes `Types.Rarity.Legendary`.
- `MainInstance.StartingReagentCandidates`: filter to rarities at or below the cap for 0
  experience.
- `drop_preview.gd`: the reagent band respects the cap, so the preview never shows a rarity
  that cannot drop.
Tests: extend `test_reagent_loot.gd`, `test_shop_handler.gd`, `test_drop_preview.gd`.

### 4. Lower reagent sell values
`ShopHandler.GetReagentPrice` derives from `GetReagentSellValue`, so cutting the sell value
would also cut shop prices. Give the shop price its own derivation that keeps today's
prices, then scale `GetReagentSellValue` down by a `GameBalance` factor (value set with the
user).
Tests: shop prices unchanged; sell value equals the old value times the factor.

### 5. UI
- Reagents tab (`inspect_collection_menu.gd` and its scene): a static header with rank
  label, progress bar, and the next unlock ("12 / 30 — Epic reagents can be found"), plus
  locked-rarity indicators. Nodes authored in the scene, wired by `@export`.
- Post-battle reward summary (`reward_summary.gd`): an "+N Attunement" line when the
  battle granted experience, and a rank-up line when it crossed a threshold.

### 6. Documentation
- `Concept_Document.md` 3.3.3: the Attunement rules above; a sell-value line matching
  step 4.
- `Technical_Design_Document.md` 7.7 (`Draw` on the consumption path), section 10
  (`ReagentCollection` save shape), and the loot section covering `RollRarityForReagent`.

## Watch for
- Existing saves load at 0 experience and drop to Uncommon-only rolls; acceptable in early
  development, but say so when presenting step 2.
- Debug grants (`debug_actions.gd`) bypass the cap on purpose.
- `GetRandomKeyForRarity` returns `""` when no reagent exists at a rarity in the active
  content pool; the cap must not make that more frequent under `--mode playtest`.
- Lint `Scripts/` and run the suite after every step.
