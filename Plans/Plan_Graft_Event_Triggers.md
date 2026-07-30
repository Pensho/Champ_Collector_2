# Plan — Graft event triggers (Batch: Detritivore)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`, `Symbiote_Graft_Pool.md`).
Builds a broadcast dispatch primitive — a way for a graft to react to events happening to *any*
character on either side — then the single graft that falls out. Follow the graft conventions in
`Plan_Symbiote_Graft_Pool.md` ("Conventions every concrete graft follows").

Detritivore: whenever a reagent is consumed, a buff expires, or a zone dissipates — anywhere, either
side — the Symbiote heals 2% max Health and gains a permanent **Scrap** stack worth +2/3/4/5%
Resistance (no cap). No attribute bonus; drawback: starts each battle at −20% Resistance.

## Grounding — what already exists vs. what the stub assumed

- **No broadcast / global-subscriber mechanism exists.** Every hook routes to one character's own
  trait via `Skills.ActiveHook(character, event)` (`skills.gd:13-17` — returns the trait iff its
  `_execution_steps` registered the event; the caller then invokes the named method). All 20+ call
  sites pass one specific character. So the real primitive is a **broadcast dispatch** to every
  character's trait on both sides. Because Detritivore's three triggers produce the *same* response,
  the clean shape is **one broadcast event fired at three sites**, not three parallel event types.
- **Buff expiry** lives in `status_effect_resolver.gd` `_TriggerExistingCasterBuffs` (removal block
  `:265-279`, emits a `Statuses_Removed` CombatResult); no `Combat_Event` fires today. Duration
  expiry (`buff.duration <= 0`) is distinct from early `RemoveBuff` (`:51-58`) and death
  `Statuses_Cleared` — the trigger hooks **only** the expiry site. The design says "a **buff**
  expires," so debuff expiry (`_TriggerExistingCasterDebuffs:207-219`) is **out of scope**.
- **Zone dissipation**: `zone_resolver.gd` `TriggerZones` frees zero-duration zones silently at
  `:94-98` (no CombatResult, no event). The trigger fires the broadcast there. The stub assumed a new
  `Zone_Dissipated` CombatResult Kind, but the mechanic doesn't need one — dropping it avoids a
  `combat_result.gd` enum member and a `battle.gd` view-layer case for no gain.
- **Reagent consumed**: `battle_resolver.gd` `ResolveReagent` dispatches the *consumer's own*
  `OnReagentConsumed` (`:274-276`, which returns a potency delta). Detritivore reacts to *others'*
  consumption, so the broadcast fires alongside — the existing consumer hook is untouched, with no
  signature clash.
- **`ResolveTraitHeal([owner_ID], 0.02)`** (`battle_resolver.gd:282`, landed) is the 2% heal; batch
  nesting is safe (`_batch_depth`, `:36,401-408`). The Scrap stack mirrors `ReactivePlatingGraft`
  mutating `_attribute_percent_delta`. **Subtlety:** the Scrap bonus and the −20% drawback are the
  *same* attribute (Resistance), so the per-battle reset must restore **−0.20**, not `0.0` (unlike
  reactive-plating, whose bonus and drawback are different attributes).
- Resolver budget: 653/800 lines, 20/25 public methods — room for the one new public method
  (`BroadcastEvent` → 21/25). `Plan_Symbiote_Graft_Pool.md`'s section-15.10 warning is stale here.

**Design decisions (settled, per the design doc):**
- **Buff expiry only** (not debuff) — the doc says "a buff expires"; broadening to debuffs would
  exceed the Concept/design doc. Confirm if a broader "any status expiry" is ever wanted.
- **No new CombatResult Kind** — the broadcast is the whole mechanic; the stub's zone-dissipation
  result is dropped as unnecessary surface.
- **Per-occurrence firing** — one broadcast per expired buff / per dissipated zone / per reagent, so
  simultaneous expiries yield multiple Scrap stacks and heals ("scavenges the remains").

## Primitive to build first (with tests)

### Broadcast dispatch + one new event

- Add `Types.Combat_Event.Remains_Scavenged` (`common_enums.gd`). The name is Detritivore-flavored;
  the helper itself is generic and reusable.
- Add `BattleResolver.BroadcastEvent(p_event: Types.Combat_Event) -> void`: iterate `_characters`;
  for each whose `_trait != null and _trait._execution_steps.has(p_event)`, invoke the registered
  Callable — `character._trait._execution_steps[p_event].call(character_ID, self)`.
- Wire three sites, each firing **per occurrence**:
  - `status_effect_resolver.gd` buff-expiry (`:265-279`): after the `Statuses_Removed` `_Emit`, call
    `_resolver.BroadcastEvent(Types.Combat_Event.Remains_Scavenged)` once per expired buff (loop
    `status_IDs_to_be_removed`). The debuff site is left untouched.
  - `zone_resolver.gd` `TriggerZones` (`:94-98`): inside the free loop, call
    `_resolver.BroadcastEvent(...)` once per dissipated zone.
  - `battle_resolver.gd` `ResolveReagent` (after `:276`): call `BroadcastEvent(...)` once, additive
    to the existing consumer `OnReagentConsumed`.
- Tests: `BroadcastEvent` invokes registered traits on **both** sides and skips unregistered ones; a
  buff running to 0 fires it while `RemoveBuff` and death-clear do **not**; a zone reaching 0 duration
  fires it; a reagent consumed by a non-Symbiote fires it on the Symbiote.

## Graft that falls out

Numbers are the design-doc literals. Rarity order: Uncommon / Rare / Epic / Legendary.

### Detritivore

`Scripts/Character/character_traits/Grafts/detritivore_graft.gd`,
`class_name DetritivoreGraft extends GraftEffect`.

- **Constants:** `SCRAP_PER_RARITY: Dictionary[Types.Rarity, float]` = `{0.02 / 0.03 / 0.04 / 0.05}`;
  `STARTING_RESISTANCE_PENALTY := -0.20`; `SCAVENGE_HEAL_FRACTION := 0.02`.
- **State:** `_stacks: int = 0`, `_scrap_per_stack: float = 0.0`.
- **Attribute layer:** `_BonusForRarity` → `{}` (no bonus — Scrap stacks are the scaling);
  `_Drawback` → `{Types.Attribute.Resistance: STARTING_RESISTANCE_PENALTY}`.
- **`Init(rarity)`:** `super.Init`, set `_scrap_per_stack = SCRAP_PER_RARITY.get(rarity, 0.0)`, set
  `_title`/`_body`, register `_execution_steps[Start_Combat] = Callable(self, "StartOfBattle")` and
  `_execution_steps[Remains_Scavenged] = Callable(self, "OnScavenge")`.
- **`StartOfBattle(owner, resolver)`:** `_stacks = 0`;
  `_attribute_percent_delta[Types.Attribute.Resistance] = STARTING_RESISTANCE_PENALTY` (restore the
  drawback — **not** `0.0`).
- **`OnScavenge(owner, resolver)`:** `_stacks += 1` (uncapped);
  `_attribute_percent_delta[Types.Attribute.Resistance] = STARTING_RESISTANCE_PENALTY +
  _scrap_per_stack * _stacks`; `resolver.ResolveTraitHeal([owner], SCAVENGE_HEAL_FRACTION)`.
- **`RefreshVisuals`** showing current Scrap stacks (mirror `ReactivePlatingGraft`), optional.

## Files

- New graft script: `Scripts/Character/character_traits/Grafts/detritivore_graft.gd` (+ `.uid`).
- New `.tres`: `Data/Character_Traits/Grafts/Detritivore_Graft.tres` (mirror an existing graft
  `.tres`; no numbers in the resource).
- Engine edits: `common_enums.gd` (new event), `battle_resolver.gd` (`BroadcastEvent` + reagent
  site), `status_effect_resolver.gd` (buff-expiry site), `zone_resolver.gd` (dissipation site).
- Enemy `_graft_effect` sourcing stays **deferred** per `Plan_Symbiote_Graft_Pool.md`.

## Tests

`Tests/unit/`, `test_*.gd`, GUT. One file for the primitive and one for the graft
(`test_detritivore_graft.gd`), mirroring the existing graft-test harness for the headless
`BattleResolver`. Assert: the primitive behaviors above; and for Detritivore — each
`Remains_Scavenged` adds one uncapped Scrap stack (Resistance delta grows `−0.20 + n * per_stack`,
per rarity) and heals 2% max Health via `ResolveTraitHeal`; the graft starts at −20% Resistance
(`GetAttributeDelta(Resistance, base)` negative before any scavenge). Deterministic setups; test
logic only — no wording/icon assertions. Run the suite headlessly and iterate to green.

## Dependencies

Graft machinery (shipped) + the landed `ResolveTraitHeal` + this batch's `BroadcastEvent`, all
self-contained. Independent of the two remaining stub batches.

## Docs on completion

Fold Detritivore and the broadcast primitive into `Technical_Design_Document.md` section 9.2 (and the
status-effect / zone sections the trigger sites touch), run `/review-implementation` against this
plan, strike the matching section-15 entry, then delete this plan file per `Plans/README.md`.
