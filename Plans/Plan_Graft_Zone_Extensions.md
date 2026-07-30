# Plan — Graft zone extensions (Batch: Living Bloom, Rootfeeder)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`, `Symbiote_Graft_Pool.md`).
Builds three zone primitives — a dual-faction Spore zone, capped per-owner-turn charge
replenishment, and an affected-by-zone trait hook (with an incoming-zone-effect multiplier) — then
the two grafts that fall out. Follow the graft conventions in `Plan_Symbiote_Graft_Pool.md`
("Conventions every concrete graft follows"). Independent of the other roadmap batches; its only
external dependency, `ResolveTraitHeal`, has already landed.

## Grounding — what already exists vs. what the stub assumed

The stub predates the resolver split (`Zone` logic moved into `ZoneResolver`). Verified against the
current tree:

- **Zones are single-`_target`, single-effect today.** `Zone` (`Scripts/Battle/zone.gd`) holds one
  `_target` (`ZoneAll`/`ZoneAlly`/`ZoneEnemy`) and one `_type`; `_ResolveZoneEffect`
  (`zone_resolver.gd:100-121`) matches only `Flicker_Zone` / `Lava_Zone` / `Barrier_Zone`. The
  stub's "dual-faction zone" needs **no `Zone` schema change** — a new `Spore_Zone` `_type` placed
  with `_target = ZoneAll` triggers on both sides (`Skills.CorrectZoneTarget` returns true for
  `ZoneAll`, `skills.gd:74-75`), and its new `_ResolveZoneEffect` arm branches on
  `sides.AreAllies(character, owner)` to buff allies / debuff enemies from the one placement.
- **Owner-Knowledge is already snapshotted at placement** (`_owner_knowledge`, set in `PlaceZone`
  at `zone_resolver.gd:33`) and `Skills.ZoneMagnitude(base, K)` (`skills.gd:10-11`,
  `base * (1 + K * 0.005)`, `ZONE_KNOWLEDGE_SCALING = 0.005`) is the standard ally-zone scaling. So
  Knowledge-scaling the Bloom's status values reuses the existing primitive; no new scaling math.
- **Charges are `_duration` with no cap and no replenishment.** `TriggerZones` decrements
  `_duration` per trigger (`zone_resolver.gd:86`) and the sweep frees any zone at 0
  (`:94-97`). `SetZoneDuration` (`:45-52`) sets an absolute value and emits
  `Zone_Duration_Changed`. There is no capped-increment helper — that is the second primitive.
- **`TriggerZones` never consults the affected character's trait.** The only trait hooks in the
  zone path fire on the *zone owner* (`TriggerZoneConstructedHook` at placement, `zone_resolver.gd:42`;
  `TriggerZoneUsedHook` inside the Barrier arm, `skills.gd:66`). Nothing lets the *character being
  affected* react. Rootfeeder needs exactly that — the third primitive.
- **`ResolveTraitHeal([owner], fraction)`** (`battle_resolver.gd:282-295`, landed) is Rootfeeder's
  heal; batch nesting is safe (`_BeginBatch`/`_EndBatch`). This is the stub's hard dependency and it
  is already in place — no separate heal path is added here.
- **Status-application paths:** the Lava arm builds a `Debuff` inline (`zone_resolver.gd:111-119`),
  duplicating snapshot/emit logic and bypassing the standard guards. The new Spore arm instead routes
  through `GetStatusResolver().ApplyBuff` / `ApplyDebuff` (the path `ApplyBarrierZone` uses,
  `skills.gd:65`) to inherit `HasMaxStatusEffects` / Aegis / sequence-lock guards. `MakeBarrierZoneBuff`
  (`skills.gd:25-32`) confirms `ApplyBuff` honours a template's `duration` — so a 1-turn Spore status
  is set on the template.
- **Blight / Regeneration are data-driven** (`Data/Status_Effects/Blight.tres`,
  `Regeneration.tres`; enums `Types.Debuff_Type.Blight`, `Types.Buff_Type.Regeneration`;
  `status_effect_registry.gd:56,22`). Blight = `IncomingHealReduction` 0.5; Regeneration =
  `MaxHealthPercent` 0.04. Registry defaults are the bases scaled by `ZoneMagnitude`.
- **New surfaces land off `battle_resolver.gd`.** `ReplenishZoneCharge` is public on `ZoneResolver`
  (122 lines today), the new hook is a virtual on `CharacterTrait`, and the enum members are in
  `common_enums.gd` — so `Plan_Symbiote_Graft_Pool.md`'s section-15.10 resolver-ceiling warning does
  not bind this batch.

**Design decisions (settled):**
- **Bloom potency scales with owner Knowledge on both halves:** Regeneration value =
  `ZoneMagnitude(0.04, owner_knowledge)`, Blight value = `ZoneMagnitude(0.50, owner_knowledge)` —
  the whole Bloom's potency scales, matching the design doc's "standard ally-zone rule." Blight's
  `IncomingHealReduction` is floored at 0 downstream (`_HealingMultiplier`), so a >1.0 scaled value
  is safe.
- **Spore is a new `Skill_Type`, not a `Zone` schema change** — the dual-faction behaviour lives
  entirely in the new `_ResolveZoneEffect` arm; `Zone` keeps its single `_target`/`_type`.
- **Rootfeeder's +50% is an incoming-effect multiplier, and its heal fires per effect resolution.**
  The `Zone_Affected` dispatch and the multiplier both live in `_ResolveZoneEffect`, co-located with
  the effect. With Resonance (double-trigger) the heal therefore fires twice — an acceptable,
  consistent consequence of "affected by the zone."
- **The Bloom is not re-seeded if fully spent.** If drained to 0 it is freed by the standard sweep;
  replenishment only tops up a still-living Bloom. With a 5-charge start and +1/turn this is rare and
  matches the general "dissipates when the last charge is spent" rule.

## Primitives to build first (each with tests)

### P1 — Dual-faction Spore zone

- Add `Types.Skill_Type.Spore_Zone` (`common_enums.gd`, alongside
  `Flicker_Zone`/`Lava_Zone`/`Barrier_Zone` at `:102-106`).
- Add a `Spore_Zone` arm to `_ResolveZoneEffect` (`zone_resolver.gd:100`). Compute
  `var sides := _resolver._sides` and branch on `sides.AreAllies(p_character_ID, p_zone._owner_ID)`:
  - **Ally** → apply Regeneration for 1 turn. Build `StatusEffects.Buff.new()` with
    `type = Types.Buff_Type.Regeneration`, `name = "Regeneration"`, `duration = 1`,
    `value = Skills.ZoneMagnitude(StatusEffectRegistry.BuffData(Regeneration).magnitude, p_zone._owner_knowledge)`,
    then `_resolver.GetStatusResolver().ApplyBuff(p_character_ID, buff)`.
  - **Enemy** → apply Blight for 1 turn. Build `StatusEffects.Debuff.new()` with
    `type = Types.Debuff_Type.Blight`, `duration = 1`, `source_ID = p_zone._owner_ID`,
    `value = Skills.ZoneMagnitude(StatusEffectRegistry.DebuffData(Blight).magnitude, p_zone._owner_knowledge)`,
    then `_resolver.GetStatusResolver().ApplyDebuff(p_character_ID, debuff)`.
  - Routing through `ApplyBuff`/`ApplyDebuff` inherits `HasMaxStatusEffects` / Aegis / sequence-lock
    guards (unlike the inline Lava arm) — no guard code duplicated here.
- No `PlaceZone` change: Living Bloom passes a code-built `Skill` with `target = ZoneAll` and
  `skill_type = Spore_Zone` (see the graft below).
- Tests (`Tests/unit/`): a `Spore_Zone` with `ZoneAll`, an ally and an enemy both standing in it —
  driving `TriggerZones` (or `_ResolveZoneEffect` directly) applies Regeneration (1 turn) to the ally
  and Blight (1 turn) to the enemy from one placement; both status `value`s equal the
  `ZoneMagnitude`-scaled registry magnitude for the seeded owner Knowledge (assert the scaling by
  seeding two different Knowledge snapshots). Logic only.

### P2 — Capped per-owner-turn charge replenishment

Add one public method to `ZoneResolver`:

```
func ReplenishZoneCharge(p_zone_ID: int, p_amount: int, p_max_charges: int) -> void:
	if(not _zones.has(p_zone_ID)):
		return
	var new_duration: int = mini(_zones[p_zone_ID]._duration + p_amount, p_max_charges)
	if(new_duration == _zones[p_zone_ID]._duration):
		return
	SetZoneDuration(p_zone_ID, new_duration)
```

- Delegates the emit to the existing `SetZoneDuration` (`Zone_Duration_Changed`), so the view layer
  needs no new case. Caps at `p_max_charges`; no-op when already at/above the cap or the zone is gone.
- Tests: increments a zone below cap by `p_amount` and emits `Zone_Duration_Changed`; is a no-op
  (no emit) at the cap and above it; is safe on a missing zone ID.

### P3 — Affected-by-zone hook + incoming-zone-effect multiplier

- Add `Types.Combat_Event.Zone_Affected` (`common_enums.gd`, alongside `Zone_Used`/`Zone_Constructed`
  at `:194-195`).
- Add two virtuals to `CharacterTrait` (`Scripts/Character/character_traits/character_trait.gd`,
  near the existing zone hooks `OnZoneUsed`/`OnZoneConstructed`/`GetZoneChargeBonus` at `:115-123`):
  - `func OnAffectedByZone(_p_owner_ID: int, _p_zone_owner_ID: int, _p_resolver: BattleResolver) -> void:`
    (no-op default) — the reactive hook, gated by `_execution_steps` like the other event hooks.
  - `func GetIncomingZoneEffectMultiplier(_p_owner_ID: int, _p_zone_owner_ID: int, _p_sides: CombatSides) -> float:`
    returning `1.0` — consulted unconditionally on `_trait` (like `GetIncomingDebuffDurationBonus`).
- In `_ResolveZoneEffect` (`zone_resolver.gd:100`), before the `match`, compute the multiplier from
  the *affected* character's trait:
  ```
  var affected: Character = _resolver._characters[p_character_ID]
  var effect_multiplier: float = 1.0
  if(null != affected._trait):
  	effect_multiplier = affected._trait.GetIncomingZoneEffectMultiplier(
  			p_character_ID, p_zone._owner_ID, _resolver._sides)
  ```
  Thread `effect_multiplier` into each arm's magnitude — the Flicker bump, the Lava debuff `value`,
  and the new Spore Regeneration/Blight `value`. (Barrier's `ZoneAlly` targeting means an
  enemy-owned Barrier never triggers on the Symbiote, so its `CorrectZoneTarget` filter makes the
  multiplier moot there; leave `ApplyBarrierZone` unthreaded and note this.)
- After the effect resolves inside `_ResolveZoneEffect`, dispatch the affected character's hook via
  the standard gate:
  ```
  var reactive: CharacterTrait = Skills.ActiveHook(affected, Types.Combat_Event.Zone_Affected)
  if(null != reactive):
  	reactive.OnAffectedByZone(p_character_ID, p_zone._owner_ID, _resolver)
  ```
- Tests: a probe trait registered on `Zone_Affected` receives `OnAffectedByZone` with the correct
  `p_zone_owner_ID` when its character is affected by a zone (ally-owned and enemy-owned); a probe
  returning `1.5` from `GetIncomingZoneEffectMultiplier` scales a Flicker bump and a Lava debuff
  `value` by 1.5 while a default trait leaves them unscaled; an unregistered trait is not dispatched.

## Grafts that fall out

Numbers are the design-doc literals (`Symbiote_Graft_Pool.md` "Living Bloom" / "Rootfeeder").
Attribute-layer percentages are authored as literal percents per `Plan_Symbiote_Graft_Pool.md`'s
percent-of-base note. Rarity order: Uncommon / Rare / Epic / Legendary.

### Living Bloom

`Scripts/Character/character_traits/Grafts/living_bloom_graft.gd`,
`class_name LivingBloomGraft extends GraftEffect`.

- **Constants:** `MAX_CHARGES := 5`; `CHARGE_PER_TURN := 1`;
  `KNOWLEDGE_BONUS_PER_RARITY: Dictionary[Types.Rarity, float]` =
  `{Uncommon: 0.15, Rare: 0.20, Epic: 0.25, Legendary: 0.30}`.
- **State:** `_bloom_zone_ID: int = -1`.
- **Attribute layer:** `_BonusForRarity(rarity)` →
  `{Types.Attribute.Knowledge: KNOWLEDGE_BONUS_PER_RARITY.get(rarity, 0.0)}`; `_Drawback()` → `{}`
  (no drawback).
- **`Init(rarity)`:** `super.Init(rarity)`, set `_title`/`_body`, register
  `_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")` and
  `_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")`. Do **not**
  override `_trait_texture`.
- **`StartOfBattle(owner, resolver)`:** seed the Bloom. Build a `Skill.new()` in code (mirror
  `calibration_trait.gd:88-105` `_ReErectZone`): `skill_type = Types.Skill_Type.Spore_Zone`,
  `target = Types.Skill_Target.ZoneAll`, `duration = MAX_CHARGES`, `name = "Spore Bloom"`. Pick a
  free slot: `var free := resolver.GetZoneResolver().AvailableZoneIDs()`; if empty, leave
  `_bloom_zone_ID = -1` and return; else `_bloom_zone_ID = free[0]` and
  `resolver.GetZoneResolver().PlaceZone(_bloom_zone_ID, owner, zone_skill)`. `PlaceZone` snapshots
  the owner's Knowledge (already includes the graft's +15–30% via `GetTotalAttribute`).
- **`StartOfTurn(owner, resolver)`:** if `_bloom_zone_ID != -1` and
  `resolver.GetZoneResolver().HasZone(_bloom_zone_ID)`,
  `resolver.GetZoneResolver().ReplenishZoneCharge(_bloom_zone_ID, CHARGE_PER_TURN, MAX_CHARGES)`.
  (A Bloom drained to 0 was freed by the sweep — no re-seed.)
- **Attribute bonus (`_BonusForRarity`):** Knowledge `+15 / 20 / 25 / 30%`.
- **Drawback (`_Drawback`):** none (`{}`).

### Rootfeeder

`Scripts/Character/character_traits/Grafts/rootfeeder_graft.gd`,
`class_name RootfeederGraft extends GraftEffect`.

- **Constants:** `HEAL_FRACTION_PER_RARITY: Dictionary[Types.Rarity, float]` =
  `{Uncommon: 0.04, Rare: 0.05, Epic: 0.06, Legendary: 0.07}`; `ENEMY_ZONE_EFFECT_MULTIPLIER := 1.5`.
- **State:** `_heal_fraction: float = 0.0`.
- **Attribute layer:** `_BonusForRarity` → `{}` (no bonus); `_Drawback` → `{}` (the +50% enemy-zone
  effect is graft-inherent behaviour via `GetIncomingZoneEffectMultiplier`, not an attribute — same
  pattern as Caravan Cadence's `BlocksForwardTurnBarBump` and Undertow's self-turn-bar loss).
- **`Init(rarity)`:** `super.Init(rarity)`, `_heal_fraction = HEAL_FRACTION_PER_RARITY.get(rarity, 0.0)`,
  set `_title`/`_body`, register
  `_execution_steps[Types.Combat_Event.Zone_Affected] = Callable(self, "OnAffectedByZone")`.
- **`OnAffectedByZone(owner, zone_owner_ID, resolver)`** (override): heal on top of the zone effect —
  `resolver.ResolveTraitHeal([owner], _heal_fraction)`. Fires for any zone, either side ("whenever
  affected by any zone"); never clears the zone (the charge is consumed by `TriggerZones` exactly as
  for any character).
- **`GetIncomingZoneEffectMultiplier(owner, zone_owner_ID, sides)`** (override): return
  `ENEMY_ZONE_EFFECT_MULTIPLIER` if `sides.AreEnemies(owner, zone_owner_ID)` else `1.0`.
- **Attribute bonus:** none. **Drawback:** none as an attribute; the +50% enemy-zone effect is the
  behavioural drawback.

## Files

- New graft scripts: `Scripts/Character/character_traits/Grafts/living_bloom_graft.gd`,
  `rootfeeder_graft.gd` (+ `.uid`).
- New `.tres`: `Data/Character_Traits/Grafts/Living_Bloom_Graft.tres`, `Rootfeeder_Graft.tres`
  (mirror an existing graft `.tres`; `script_class`, one `ExtResource` for the `.gd`,
  `script = ExtResource(...)`; no numbers in the resource).
- Engine edits:
  - `common_enums.gd` — `Skill_Type.Spore_Zone` (P1), `Combat_Event.Zone_Affected` (P3).
  - `Scripts/Battle/zone_resolver.gd` — Spore arm in `_ResolveZoneEffect` (P1), `ReplenishZoneCharge`
    (P2), affected-character multiplier + `Zone_Affected` dispatch in `_ResolveZoneEffect` (P3).
  - `Scripts/Character/character_traits/character_trait.gd` — `OnAffectedByZone` and
    `GetIncomingZoneEffectMultiplier` virtuals (P3).
- Enemy `_graft_effect` sourcing stays **deferred** (author subclasses + `.tres`, unit-test, leave
  every enemy source null) per `Plan_Symbiote_Graft_Pool.md`.

## Tests

`Tests/unit/`, `test_*.gd`, GUT. One file per primitive (P1–P3) and one per graft
(`test_living_bloom_graft.gd`, `test_rootfeeder_graft.gd`), mirroring the existing graft-test harness
(`test_turn_bar_control_grafts.gd` / `test_graft.gd`, with `helpers/test_factory.gd`'s
`FakeTurnPositions` and roster/sides builders) for the headless `BattleResolver`. Assert:

- **P1:** one `Spore_Zone` applies Regeneration(1) to an ally and Blight(1) to an enemy; both
  `value`s are the `ZoneMagnitude`-scaled registry magnitude (two Knowledge snapshots → different
  values).
- **P2:** `ReplenishZoneCharge` raises `_duration` up to the cap and emits `Zone_Duration_Changed`;
  no-op at/above cap and on a missing zone.
- **P3:** `OnAffectedByZone` dispatched with the correct `zone_owner_ID` (ally- and enemy-owned
  zones); `GetIncomingZoneEffectMultiplier` of 1.5 scales a Flicker bump and a Lava value; default
  trait leaves them unscaled; unregistered trait not dispatched.
- **Living Bloom:** Knowledge `+15/20/25/30%` via `GetAttributeDelta`; `StartOfBattle` seeds a
  5-charge `Spore_Zone` in a free slot (and no-ops when slots are full); `StartOfTurn` tops the Bloom
  up by 1 to a max of 5 and never past it; no drawback.
- **Rootfeeder:** `OnAffectedByZone` heals `4/5/6/7%` max Health via `ResolveTraitHeal` per rarity;
  `GetIncomingZoneEffectMultiplier` returns 1.5 for an enemy zone owner and 1.0 for an ally; empty
  attribute layer (`GetAttributeDelta` == 0 for a probe attribute).

Use deterministic setups (single eligible slot / known Knowledge). Test logic only — no
wording/icon assertions. Run the suite headlessly and iterate to green before marking done.

## Dependencies

Graft machinery (shipped) + the landed `ResolveTraitHeal` + this batch's three primitives (P1–P3),
all self-contained here. Independent of the other roadmap batches; nothing else depends on these
primitives.

## Docs on completion

Fold Living Bloom, Rootfeeder, and the three zone primitives into `Technical_Design_Document.md`
section 9.2 (and the zone-system section the primitives touch), run `/review-implementation`
against this plan, strike the matching section-15 entry, then delete this plan file per
`Plans/README.md`.
