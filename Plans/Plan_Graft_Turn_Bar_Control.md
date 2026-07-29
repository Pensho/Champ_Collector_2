# Plan — Graft turn-bar control (Batch: Caravan Cadence, Gravitic Rot, Contagion Bond)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`, `Symbiote_Graft_Pool.md`).
Builds the shared turn-bar push/pull primitive first (reused later by Undertow in
`Plan_Graft_Retaliation.md`), then the three grafts that fall out. Follow the graft
conventions in `Plan_Symbiote_Graft_Pool.md` ("Conventions every concrete graft follows").

## Grounding — what already exists vs. what the stub assumed

The stub predates the resolver split (commits `629f8a0`, `6a0d9ce`) and several traits, so
most of its "primitive to build" list is already shipped. Verified against the current tree:

- **Position / ordering queries already exist resolver-side.** `TurnPositions`
  (`Scripts/Battle/turn_positions.gd`) exposes `GetCharactersBehindBy(owner, percent)` and
  `GetCharactersWithinProximity(owner, percent)`, adapted from the live node by
  `TurnBarPositions` (`Scripts/UI/Battle_UI/turn_bar_positions.gd`) and already consumed by
  `PlanTrait`, `ForesightTrait`, `ShieldWallTrait`. **Gravitic Rot needs no new query** — it
  reuses `GetCharactersBehindBy(owner, 0.20)`. Only the two *ordered* shapes are missing (see
  P2 below).
- **Buff-gained (receiver-side) hook already exists.** `Types.Combat_Event.Buff_Applied` fires
  on the buff's target inside `StatusEffectResolver._EmitBuffApplied`
  (`Scripts/Battle/status_effect_resolver.gd:584`), consumed by `OnTheHouseTrait`. Contagion
  Bond reuses it — but its dispatch does **not** pass the applied buff, which Contagion needs
  (see P4).
- **Debuff-landed hook is the wrong side.** `Types.Combat_Event.Debuff_Applied` fires on the
  *applier* (`Skills.DispatchDebuffApplied`, `skills.gd:199`), consumed by `FieldOfStudyTrait`.
  Contagion Bond needs the *receiver* side — a hook that fires on the character a debuff lands
  **on** — which does not exist yet (see P3).
- **`battle_resolver.gd` budget is no longer at the ceiling.** The split left it at 656/800
  lines and 19/25 public methods (`gdlintrc`), so the single new public method in P1 fits.
  `Plan_Symbiote_Graft_Pool.md`'s section-15.10 warning is now stale for this batch.

## Primitives to build first (each with tests)

### P1 — Public turn-bar push/pull (`BumpTurnBar`)
The only turn-bar entry points today are a skill's `turn_effect` / `TraitSkillResult._turn_bar_bump`
and `AccumulateTurnBarMovement`; the general push/pull, `_EmitTurnBarBump`, is a private resolver
method that only its own subsystems (`zone_resolver`, `status_effect_resolver`) call. Add a public
wrapper on `BattleResolver` so grafts can push/pull directly:

```
func BumpTurnBar(p_target_ID: int, p_fraction: float, p_source_ID: int = -1) -> void:
    _EmitTurnBarBump(p_target_ID, p_fraction, p_source_ID)
```

- Positive `p_fraction` pushes forward, negative pulls back. `_EmitTurnBarBump` already honors
  **Anchor** (blocks all bumps) and **Steadfast** (blocks negative bumps), and already routes the
  `Enemy_Turn_Bar_Reduced` tithe — so both Caravan (push) and Gravitic (pull) get that for free.
- One new public method → 20/25, within budget.
- **Forward-push block for Caravan.** Add a `CharacterTrait.BlocksForwardTurnBarBump(p_owner_ID) -> bool`
  hook (default `false`) and check it in `_EmitTurnBarBump`: when `p_fraction > 0.0` and the target's
  trait returns true, suppress the bump. This is the inverse of the existing Steadfast (negative-only)
  block and lets Caravan be pushed *backward* but never *forward* — matching the doc's "cannot be
  pushed forward" exactly, unlike Anchor which blocks both directions. The drawback is a graft-inherent
  property, so it lives on the trait, not as an applied status (per `Plan_Symbiote_Graft_Pool.md`'s
  Batch-1 note that graft-inherent properties never route through the Buff/Debuff system). Guard the
  `_trait` access for null.
- Tests: a headless `BattleResolver` with a fake `TurnPositions`; assert a `Turn_Bar_Bump`
  `CombatResult` is emitted with the right sign, that Anchor on the target suppresses it, that
  Steadfast suppresses a negative but not a positive bump, and that `BlocksForwardTurnBarBump`
  suppresses a positive but not a negative bump.

### P2 — Two ordered position queries
Add to `TurnPositions` (base returns `[]`), `TurnBar`, and the `TurnBarPositions` adapter, matching
the three existing query methods' shape and validation:

- `GetCharactersBehindOrdered(p_owner_ID: int) -> Array[int]` — every character strictly behind the
  owner, ordered **furthest-first**. (Caravan's "furthest behind".) `TurnBar` sorts by marker
  `position.x`; skip the owner and markers at `position.x == 0.0` (not yet on the bar), mirroring
  `GetCharactersBehindBy`.
- `GetCharactersByProximityOrdered(p_owner_ID: int, p_bar_percent: float) -> Array[int]` — every
  character within `p_bar_percent` of the owner in either direction, ordered **nearest-first**.
  (Contagion's "nearest within width".) Same range-validation `print` guard as the existing
  proximity query.

Faction filtering stays out of `TurnPositions` (consistent with today's queries): grafts intersect
the ordered list with `FindSkillTargets(...)` and take the first survivor, exactly as `PlanTrait` /
`ForesightTrait` do.

- Tests: exercise `TurnBar` directly with hand-placed marker positions (unit-testable node logic,
  as `test_turn_bar*` already does) — assert ordering, owner exclusion, off-bar exclusion, and the
  proximity window bound.

### P3 — Receiver-side debuff hook (`Debuff_Received`)
Add `Debuff_Received` to `Types.Combat_Event` (`common_enums.gd`) and dispatch it on the **target**
inside `StatusEffectResolver._EmitDebuffApplied`, mirroring the target-side buff dispatch in
`_EmitBuffApplied`:

```
var target: Character = _resolver._characters[p_target_ID]
var debuff_trait: CharacterTrait = Skills.ActiveHook(target, Types.Combat_Event.Debuff_Received)
if(null != debuff_trait):
    debuff_trait.OnDebuffReceived(p_target_ID, p_debuff, _resolver)
```

- Naming note to carry into review: `Buff_Applied` is receiver-side but `Debuff_Applied` is
  applier-side, so the receiver-side debuff event cannot reuse that name — hence `Debuff_Received`.
  This asymmetry is pre-existing; do not rename `Debuff_Applied` (out of scope, would ripple into
  `FieldOfStudyTrait` and `Skills.DispatchDebuffApplied`).
- Tests: apply a debuff to a character carrying a probe trait that registers `Debuff_Received`;
  assert the hook fires once with the landed debuff instance.

### P4 — Pass the applied buff to `Buff_Applied` consumers
Contagion Bond must know *which* buff it just gained to copy it. Broaden the `_EmitBuffApplied`
dispatch to `OnBuffGained(p_target_ID, p_buff, p_resolver)` and update the sole existing consumer,
`OnTheHouseTrait.OnBuffGained`, to accept (and ignore) the new `p_buff` parameter.

- Tests: extend/adjust the existing On-the-House test for the new signature; assert Contagion's
  `OnBuffGained` receives the correct buff instance.

### P5 — Contested debuff application (unify into one `CastDebuff`)
Contagion's enemy copy is "contested against that enemy's Resistance" — that's an *attempt*
(may miss), not an unconditional application. `ApplyDebuff`'s contract is specifically
"apply, no roll" (every existing caller relies on that), so the resist-roll-then-land shape
belongs with `_CastDebuff`, not `ApplyDebuff`. `_CastDebuff` was coupled to a `Skill` resource
(`p_skill.debuffs[p_skill.target]`, `p_skill.duration`) that a copied template doesn't have —
rather than add a second, parallel "cast a template" function next to it (two functions doing
the same resist-then-insert job is its own problem), fold the `Skill`-unpacking into the
**caller**: `BattleResolver.ResolveSkill` now builds a `StatusEffects.Debuff` template from the
cast `Skill` (`type` from `p_skill.debuffs[p_skill.target]`, `duration` from `p_skill.duration`)
and calls one public, template-shaped
`StatusEffectResolver.CastDebuff(target_ID, debuff_template, caster_ID,
tick_bonus_per_debuff := 0.0, always_refresh_duration := false, trigger_mirror_coat := false)
-> Array[CombatResult]`. The skill-cast call site passes `always_refresh_duration=true,
trigger_mirror_coat=true` (its pre-existing behavior); Contagion Bond's copy leaves both at
their default `false`, matching `ApplyDebuff`'s scope — Mirror Coat only reflects skill-cast
debuffs, and passive/graft-sourced attempts only extend an existing duration rather than
resetting it. `_CastDebuff` is deleted; there is exactly one debuff-attempt entry point.
`StatusEffectResolver._RollsResistDebuff` also moves here from `BattleResolver` in the same
pass — it's status-effect logic (Signed Writ, the resist roll), not core resolver
infrastructure, and every caller was already inside `StatusEffectResolver`; it keeps calling
back into `BattleResolver._HasDebuff`/`_RollFavoring` (genuinely shared RNG/status-query
primitives used well beyond debuffs, so those stay put).

- Tests: forced dominance both ways (Accuracy vs. Resistance) on `CastDebuff` — resisted
  (no debuff, `Debuff_Resisted` result emitted) and landed (debuff present on target). One test
  confirming `ApplyDebuff` itself is unchanged (still lands unconditionally, no new parameter).

### P6 — Incoming-debuff-duration bonus hook (`GetIncomingDebuffDurationBonus`)
Contagion's drawback ("debuffs on the Symbiote last 2 turns longer") follows the Carrion Bloom
precedent (`GetIncomingHealMultiplier`): add `CharacterTrait.GetIncomingDebuffDurationBonus(p_owner_ID) -> int`
(default `0`) and, in `StatusEffectResolver._InsertOrRefresh`, add the target trait's bonus to the
debuff `duration` before it is stored/emitted (debuff branch only — guard on `not p_is_buff`).
Applying it at insertion keeps the extra turns visible in the very first `Status_Applied` /
`Status_Duration` result, rather than patching duration after the fact.

- Tests: a character whose trait returns a duration bonus receives a debuff at `duration + bonus`;
  a normal character is unchanged; buffs are never affected.

## Grafts that fall out

All numbers below are the design-doc literals (`Symbiote_Graft_Pool.md`). Percentages in the
attribute layers are authored as literal percents per `Plan_Symbiote_Graft_Pool.md`'s
percent-of-base note. Rarity order: Uncommon / Rare / Epic / Legendary.

### Caravan Cadence
- **Hook:** `Start_Turn`. Get `GetCharactersBehindOrdered(owner)`, intersect with
  `FindSkillTargets(owner, owner, All_Other_Allies)`, take the first (furthest-behind ally), and
  `BumpTurnBar(ally_ID, push, owner_ID)`.
- **Push:** `+0.07 / 0.08 / 0.09 / 0.10`.
- **Attribute bonus (`_BonusForRarity`):** Knowledge `+15 / 20 / 25 / 30%`.
- **Drawback (graft-inherent, not an attribute):** cannot be pushed forward on the turn bar (may
  still be pulled backward). Override `BlocksForwardTurnBarBump()` → `true` (the P1 hook). No status
  is applied — the block is an inherent property of the graft.
- **`_Drawback()`** returns `{}` (the drawback is the forward-block hook, not an attribute delta).

### Gravitic Rot
- **Hook:** `Start_Turn`. `GetCharactersBehindBy(owner, 0.20)`, intersect with the enemy targets
  (`FindSkillTargets` per id as `ForesightTrait` does, or the enemy side list), and for each
  `BumpTurnBar(enemy_ID, -drain, owner_ID)`.
- **Drain:** `0.05 / 0.06 / 0.07 / 0.08` (negative bump).
- **Turn-bar visuals:** exposes a static `GetReachThreshold(rarity)` (ignores rarity, flat
  `REAR_PROXIMITY`) so `TurnBar._GetReachThreshold` can dispatch to it, joining Plan/Foresight's
  single behind-only overlay — not `_HasBidirectionalReach` (its window is rear-only).
- **Attribute bonus:** none.
- **Drawback (`_Drawback()`):** Speed `-10%`.

### Contagion Bond
- **Buff side — hook `Buff_Applied` → `OnBuffGained(owner, buff, resolver)`:** duplicate the gained
  buff, set `duration = 1` and `source_ID = owner`, find the nearest ally via
  `GetCharactersByProximityOrdered(owner, width)` ∩ ally targets (first survivor), and
  `GetStatusResolver().ApplyBuff(ally_ID, copy)`.
- **Debuff side — hook `Debuff_Received` → `OnDebuffReceived(owner, debuff, resolver)`:** duplicate
  the landed debuff, `source_ID = owner`, find the nearest enemy the same way, and
  `GetStatusResolver().CastDebuff(enemy_ID, copy, owner)`. **Design flag:** the doc gives
  the buff copy an explicit 1-turn duration but is silent on the debuff copy's duration — mirror it
  at `duration = 1` for symmetry and confirm with the user.
- **Width (`GetCharactersByProximityOrdered` percent):** `0.06 / 0.08 / 0.10 / 0.12`, both directions.
- **Turn-bar visuals:** exposes a static `GetReachThreshold(rarity)` (mirrors Plan/Foresight/
  Shield Wall) so `TurnBar._GetReachThreshold` can dispatch to it; since its width is
  bidirectional like Shield Wall's, it also joins `TurnBar._HasBidirectionalReach` for the
  second, mirrored (ahead-facing) reach overlay.
- **Attribute bonus:** none.
- **Drawback:** override `GetIncomingDebuffDurationBonus()` → `2` (via P6).
- **Recursion note:** a copy landing on another Contagion carrier can re-trigger its hook; copies
  are width-gated and 1-turn, so a runaway chain is bounded and acceptable. Do not add a guard
  unless play-testing shows a problem.

## Files

- New graft scripts: `Scripts/Character/character_traits/Grafts/caravan_cadence_graft.gd`,
  `gravitic_rot_graft.gd`, `contagion_bond_graft.gd` (+ `.uid`).
- New `.tres`: `Data/Character_Traits/Grafts/Caravan_Cadence_Graft.tres`,
  `Gravitic_Rot_Graft.tres`, `Contagion_Bond_Graft.tres` (mirror an existing graft `.tres`; no
  numbers in the resource).
- Engine edits: `battle_resolver.gd` (P1), `character_trait.gd` (P1 `BlocksForwardTurnBarBump` +
  P6 defaults), `turn_positions.gd` / `turn_bar.gd` / `turn_bar_positions.gd` (P2), `common_enums.gd`
  + `status_effect_resolver.gd` (P3, P4, P6), `status_effect_resolver.gd` (P5),
  `on_the_house_trait.gd` (P4).
- Enemy `_graft_effect` sourcing stays **deferred** (author subclasses + `.tres`, unit-test, leave
  enemy sources null) per `Plan_Symbiote_Graft_Pool.md`.

## Tests

`Tests/unit/`, `test_*.gd`, GUT. One test file per primitive (P1–P6) and one per graft asserting:
attribute layer via `GetAttributeDelta`, the correct hook registration and its effect on a headless
`BattleResolver` (with fake `TurnPositions` returning scripted ordered lists), and the drawback
(Caravan's forward-block suppressing a push while allowing a pull, Gravitic's Speed delta, Contagion's duration bonus). Test
logic only — no wording/icon assertions (`feedback-test-scope-no-static-content-checks`). Run the
suite headlessly and iterate to green before marking done.

## Dependencies

Graft machinery (shipped) + P1–P6, all self-contained here. P1 (`BumpTurnBar`) is the shared
primitive Undertow reuses; land it before or alongside `Plan_Graft_Retaliation.md`. No other batch
blocks this one.

## Docs on completion

Fold the three grafts and the P1–P6 primitives into `Technical_Design_Document.md` section 9.2
(and the turn-bar/status-effect sections the primitives touch), run `/review-implementation`
against this plan, strike the matching section-15 entries, then delete this plan file per
`Plans/README.md`.
