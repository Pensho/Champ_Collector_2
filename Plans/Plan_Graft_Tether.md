# Plan — Graft tether (Batch: Symbiotic Anchor)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`, `Symbiote_Graft_Pool.md`).
Builds one shared primitive — a public per-character flat attribute-bonus channel — then the
single graft that falls out. Follow the graft conventions in `Plan_Symbiote_Graft_Pool.md`
("Conventions every concrete graft follows"). Independent of the other roadmap batches.

## Grounding — what already exists vs. what the stub assumed

The stub predates several traits and the resolver split, so most of its "primitive" is already
shipped. Verified against the current tree:

- **The tether lifecycle needs no new engine code.** `StrengthInNumbersGraft`
  (`Scripts/Character/character_traits/Grafts/strength_in_numbers_graft.gd`) and `ChosenVesselTrait`
  (`Scripts/Character/character_traits/CharacterSpecificTraits/chosen_vessel_trait.gd`) already
  implement exactly the "pick a random living ally at `Start_Combat`, store its ID, re-pick in
  `OnAllyDeath` when that ID dies" pattern. Both hooks exist on `CharacterTrait` and are dispatched
  by the resolver: `StartOfBattle(owner, resolver)` from `battle.gd:161-170` (and on mid-battle
  graft apply, `battle.gd:635-636`); `OnAllyDeath(owner, dead_ally_ID, resolver)` from
  `battle_resolver.gd` `_HandleDeath` — the reacting trait receives the **dead ally's ID**.
- **Random-living-ally idiom** (from both templates):
  `resolver.GetSides().AlliesOf(owner).AliveMembers(resolver.GetCharacters())`, `.erase(owner)`,
  then index with `resolver.GetRandom().randi_range(0, allies.size() - 1)`.
- **The one genuine gap the stub names is accurate: no cross-character attribute sharing exists.**
  `GraftEffect._attribute_percent_delta` / `GetAttributeDelta` only scale the graft owner's *own*
  base attributes. The only per-character flat-additive layer combat math reads is
  `BattleResolver._battle_long_attribute_bonus` (`battle_resolver.gd:30`), summed into every combat
  calculation by `GetCombatAttributes(id)` (`:88-93`). It has **no public mutator** — only the
  private `_ApplyReagentAttributeIncrease` (`:382-388`) writes it. No buff type adds flat attributes
  through `GetTotalAttribute`/`GetCombatAttributes`. So the sharing channel is the single primitive
  this batch builds.
- **Resolver budget** is 653/800 lines, 20/25 public methods — room for the one new public method
  (→ 21/25). `Plan_Symbiote_Graft_Pool.md`'s section-15.10 ceiling warning is stale for this batch.

**Design decisions (settled):**
- **Snapshot at tether**, not live-tracked: the shared amount is computed once from the Symbiote's
  current total Resistance/Attack when it (re-)tethers, and does not follow later stat changes.
- **Persist after Symbiote death**: the tethered ally keeps its shared bonus if the Symbiote dies.
  `OnDeath()` has no resolver argument, so no cleanup hook is added — the snapshot simply remains.

## Primitive to build first (with tests)

### Public per-character flat attribute bonus (`AdjustLongAttributeBonus`)

Expose the existing `_battle_long_attribute_bonus` layer with one public method on `BattleResolver`:

```
func AdjustLongAttributeBonus(p_character_ID: int, p_attribute: Types.Attribute, p_delta: int) -> void:
	var bonus: Dictionary = _battle_long_attribute_bonus.get(p_character_ID, {})
	bonus[p_attribute] = bonus.get(p_attribute, 0) + p_delta
	_battle_long_attribute_bonus[p_character_ID] = bonus
```

- Positive `p_delta` grants, negative removes — one method covers both directions (add to the new
  ally, subtract from an old one if ever needed). The inner `Dictionary` is left untyped to match
  the existing `_ApplyReagentAttributeIncrease` shape (`_battle_long_attribute_bonus` is
  `Dictionary[int, Dictionary]`, inner keyed `Types.Attribute -> int`).
- **Refactor** `_ApplyReagentAttributeIncrease` (`:382-388`) to call this method for its final
  dict-merge (its last three lines), removing the duplication and keeping net new public surface at
  exactly +1.
- Tests (`Tests/unit/`): `AdjustLongAttributeBonus` raises `GetCombatAttributes(id)[attr]` by the
  delta; a negative delta lowers it; two attributes on one character accumulate independently; the
  reagent path (`_ApplyReagentAttributeIncrease`) still produces the same result after the refactor.
  Logic only.

## Graft that falls out

All numbers are the design-doc literals (`Symbiote_Graft_Pool.md` "Symbiotic Anchor").
Percentages in the attribute layer are authored as literal percents per `Plan_Symbiote_Graft_Pool.md`'s
percent-of-base note. Rarity order: Uncommon / Rare / Epic / Legendary.

### Symbiotic Anchor

`Scripts/Character/character_traits/Grafts/symbiotic_anchor_graft.gd`,
`class_name SymbioticAnchorGraft extends GraftEffect`.

- **Constants:** `SHARE_FRACTION := 0.20`;
  `RESISTANCE_BONUS_PER_RARITY: Dictionary[Types.Rarity, float]` =
  `{Uncommon: 0.14, Rare: 0.16, Epic: 0.18, Legendary: 0.20}`;
  `DEFENCE_PENALTY := -0.30`; `CRIT_DAMAGE_PENALTY := -0.30`.
- **State:** `_tethered_ally_ID: int = -1`.
- **Attribute layer:**
  `_BonusForRarity(rarity)` → `{Types.Attribute.Resistance: RESISTANCE_BONUS_PER_RARITY.get(rarity, 0.0)}`;
  `_Drawback()` → `{Types.Attribute.Defence: DEFENCE_PENALTY, Types.Attribute.CritDamage: CRIT_DAMAGE_PENALTY}`.
- **`Init(rarity)`:** `super.Init(rarity)`, set `_title`/`_body`, register
  `_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")` and
  `_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")`. Do **not**
  override `_trait_texture` (the base `Init` sets the shared Graft texture).
- **`StartOfBattle(owner, resolver)`:** `_Tether(owner, resolver)`.
- **`OnAllyDeath(owner, dead_ally_ID, resolver)`:**
  `if dead_ally_ID == _tethered_ally_ID: _Tether(owner, resolver)`.
- **`_Tether(owner, resolver)`:** collect living allies (idiom above, `.erase(owner)`); if empty,
  set `_tethered_ally_ID = -1` and return; pick a random one via
  `resolver.GetRandom().randi_range(0, allies.size() - 1)`; snapshot the shared amounts from the
  Symbiote (`resolver.GetCharacters()[owner]`):
  `share_res = int(ceilf(symbiote.GetTotalAttribute(Types.Attribute.Resistance) * SHARE_FRACTION))`
  and the same for `Attack`; then
  `resolver.AdjustLongAttributeBonus(new_ally, Types.Attribute.Resistance, share_res)` and the Attack
  equivalent. `GetTotalAttribute` already folds in the graft's own +14–20% Resistance, so "the rarity
  bonus also raises the shared Resistance" holds automatically. `ceilf` matches
  `GraftEffect.GetAttributeDelta`'s rounding convention.
- **Invariant:** `_Tether` runs only at `Start_Combat` and on the tethered ally's death, so the
  previous tether target is always dead at re-tether — no bonus removal from a living prior ally is
  needed, and the dead ally's stale entry is harmless. Persist-after-Symbiote-death needs no code
  (the ally's snapshot stays in `_battle_long_attribute_bonus`).
- **Attribute bonus (`_BonusForRarity`):** Resistance `+14 / 16 / 18 / 20%`.
- **Drawback (`_Drawback`):** Defence `-30%`, CritDamage `-30%`.

## Files

- New graft script: `Scripts/Character/character_traits/Grafts/symbiotic_anchor_graft.gd` (+ `.uid`).
- New `.tres`: `Data/Character_Traits/Grafts/Symbiotic_Anchor_Graft.tres` (mirror an existing graft
  `.tres`; `script_class`, one `ExtResource` for the `.gd`, `script = ExtResource(...)`; no numbers).
- Engine edit: `Scripts/Battle/battle_resolver.gd` (`AdjustLongAttributeBonus` +
  `_ApplyReagentAttributeIncrease` refactor).
- Enemy `_graft_effect` sourcing stays **deferred** (author subclass + `.tres`, unit-test, leave
  enemy sources null) per `Plan_Symbiote_Graft_Pool.md`.

## Tests

`Tests/unit/`, `test_*.gd`, GUT. One file for the primitive and one for the graft
(`test_symbiotic_anchor_graft.gd`), mirroring the existing graft-test harness (`test_graft.gd` /
the turn-bar graft tests) for the headless `BattleResolver`. Assert:

- Attribute layer via `GetAttributeDelta`: positive Resistance per rarity; −30% Defence and
  CritDamage.
- `StartOfBattle` with exactly one other living ally grants that ally Resistance + Attack equal to
  20% of the Symbiote's totals, read back via `GetCombatAttributes(ally)`.
- Re-tether: kill the tethered ally, fire `OnAllyDeath` with its ID, assert the surviving ally now
  carries the bonus.
- A non-tethered ally's death is a no-op.
- Symbiote alone leaves `_tethered_ally_ID == -1` and does not crash.
- Snapshot: buff the Symbiote's Resistance after tethering, assert the ally's shared bonus is
  unchanged.

Use single-eligible-ally setups so the random pick is deterministic (no RNG seeding). Test logic
only — no wording/icon assertions. Run the suite headlessly and iterate to green before marking
done.

## Dependencies

Graft machinery (shipped) + this batch's `AdjustLongAttributeBonus`, all self-contained here.
Independent of the other four remaining stubs.

## Docs on completion

Fold Symbiotic Anchor and the `AdjustLongAttributeBonus` primitive into `Technical_Design_Document.md`
section 9.2, run `/review-implementation` against this plan, strike any matching section-15 entry,
then delete this plan file per `Plans/README.md`.
