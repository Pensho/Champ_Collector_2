# Plan — Graft retaliation (Batch: Glass Refraction, Undertow, Glamour)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`, `Symbiote_Graft_Pool.md`).
Builds an attacker-aware damage-taken reaction (shared by Glass Refraction and Undertow) plus
Glamour's own defender-side redirect and damage-dealt-bonus channel, then the three grafts. Follow
the graft conventions in `Plan_Symbiote_Graft_Pool.md` ("Conventions every concrete graft follows").

## Grounding — what already exists vs. what the stub assumed

The stub predates the resolver split and several traits. Verified against the current tree:

- **The attacker ID is already in scope at the `OnDamageTaken` dispatch.** `_ResolveDamage`
  (`Scripts/Battle/battle_resolver.gd:559`) holds `p_caster_ID` (the attacker) and dispatches the
  target's hook at line 628-630 as `OnDamageTaken(p_target_ID, self)` — it simply drops the
  attacker. The symmetric `Damage_Dealt` hook right below (line 638-640) is *already* attacker-aware
  (`OnDamageDealt(p_caster_ID, p_target_ID, damage, self)`). So this is a **signature broadening**,
  not new plumbing — the same shape as Turn Bar Control's P4 (broaden a hook, update its consumers).
- **Batch nesting is safe** (`_batch_depth`, `battle_resolver.gd:36,401-408`), so Glass Refraction
  may call `ResolveTraitDamage` (`:298`) from inside the hook. `ResolveTraitDamage(caster, [target],
  caster_attributes, {Mysticism: 0.25}, allow_critical=false)` is exactly the Mysticism-scaled
  backlash, mirroring `SorcererTrait` (`sorcerer_trait.gd:83`). Caster attributes come from
  `GetCombatAttributes(symbiote_ID)`.
- **`BumpTurnBar(target, fraction, source)`** (`battle_resolver.gd:239`; negative fraction pulls
  back, respects Anchor/Steadfast, tithes only when an *enemy* bar is reduced) is landed and used by
  `gravitic_rot_graft.gd` / `caravan_cadence_graft.gd`. Undertow pulls the attacker and self-reduces.
- **Glamour is heavier than the stub implies and shares none of the retaliation primitive.** The
  existing `Types.Debuff_Type.Refracted` (`common_enums.gd:168`, `Data/Status_Effects/Refracted.tres`)
  is a *caster-side* debuff that redirects the holder's own future single-target skills to
  `Random_One` at `FindSkillTargets:96-101` — it does **not** redirect an incoming attack. Glamour
  also needs the `_damage_dealt_bonus` channel (`:32`, additive, passed to `Skills.MitigatedDamage`,
  no public mutator today) for +10% dealt; the existing `OnDamageTaken` multiplier for +10% taken;
  and `GetTargetingDefenceMultiplier` (`battle.gd:77-87` sorts targeting by `Health + Defence*mult`
  descending; `DoubleTheFunTrait` returns `1.5` to be targeted *more*) for "targeted 20% more".
- Resolver budget: 653/800 lines, 20/25 public methods — room for the one new public method (the
  damage-dealt-bonus setter → 21/25). `Plan_Symbiote_Graft_Pool.md`'s section-15.10 warning is stale.

**Design decision (settled):** Glamour **redirects the current attack** — when an enemy's
single-target skill resolves onto the Glamour Symbiote, roll the chance and, on success, that attack
instead hits a random *other* character this turn (not the delayed "apply the Refracted debuff to
the attacker" reading). New defender-side redirect at `FindSkillTargets`, reusing the `Random_One`
resolution but excluding the Symbiote.

## Primitives to build first (each with tests)

### P1 — Attacker-aware `OnDamageTaken` (Glass Refraction, Undertow)

Broaden `CharacterTrait.OnDamageTaken(p_owner_ID, p_resolver) -> float` →
`OnDamageTaken(p_owner_ID, p_attacker_ID, p_resolver) -> float` (base `character_trait.gd:50`), and
pass `p_caster_ID` at the `battle_resolver.gd:630` dispatch. The multiplier contract is unchanged
(`1.0` = incoming damage unchanged, `0.0` = avoided); retaliation is a side effect inside the
override. The hook fires at line 630 — **before** `_ApplyHealthLoss` (634), after `damage_dealt > 0`
is confirmed — so a lethal hit still retaliates.

- Update every existing override to accept (and ignore) the new argument: `ReactivePlatingGraft`
  (`reactive_plating_graft.gd:35`), `DoubleTheFunTrait` (`double_the_fun_trait.gd:47`). Grep all
  `OnDamageTaken` overrides during implementation to catch any others.
- Tests: a probe trait registered on `Damage_Taken` receives the correct `p_attacker_ID`;
  `ReactivePlating` (Hardened stack) and `DoubleTheFun` (avoidance roll) still behave (regression).

### P2 — Defender-side single-target redirect (Glamour)

Add `CharacterTrait.GetIncomingSingleTargetRedirectChance(p_owner_ID) -> float` (default `0.0`). In
`BattleResolver.FindSkillTargets` (`:96`), when `p_target_type` is `Single_Enemy`/`Single_Ally` and
the resolved target's trait returns chance `> 0`, roll via `_random`; on success resolve to a random
character other than the target — reuse `Skills.FindSkillTargets(..., Random_One, ...)` and
exclude/reroll the original target. This sits alongside the existing caster-side Refracted redirect
at the same site. Emit a `"Refracted!"` trait text via `EmitTraitText` for feedback (optional).

- Tests: a single-target skill aimed at a chance-1.0 carrier lands on another character; a chance-0
  carrier is untouched; AoE skills are never redirected.

### P3 — Public damage-dealt-bonus setter (Glamour +10% dealt)

`_damage_dealt_bonus` has no public mutator (only the reagent path writes it, `:358-360`). Add
`BattleResolver.AddDamageDealtBonus(p_character_ID, p_amount)` doing the same additive merge, and
refactor the reagent write to call it (net +1 public method → 21/25). Glamour adds `0.10` at
`Start_Combat`.

- Tests: the setter raises a character's dealt damage through `Skills.MitigatedDamage`; the reagent
  path is unchanged after the refactor.

## Grafts that fall out

Numbers are the design-doc literals (`Symbiote_Graft_Pool.md`). Attribute-layer percentages are
authored as literal percents per `Plan_Symbiote_Graft_Pool.md`'s percent-of-base note. Rarity order:
Uncommon / Rare / Epic / Legendary.

### Glass Refraction

`Scripts/Character/character_traits/Grafts/glass_refraction_graft.gd`.

- **Hook `Damage_Taken` → `OnDamageTaken(owner, attacker, resolver)`:** guard the attacker is alive
  and `!= owner`; `resolver.ResolveTraitDamage(owner, [attacker], resolver.GetCombatAttributes(owner),
  {Types.Attribute.Mysticism: MYSTICISM_BACKLASH}, false)` with `MYSTICISM_BACKLASH := 0.25`; return
  `1.0`. Backlash resolves through standard `_ResolveDamage` mitigation, like Sorcerer's surge.
- **Attribute bonus (`_BonusForRarity`):** Mysticism `+0.12 / 0.16 / 0.20 / 0.24`.
- **Drawback (`_Drawback`):** `{Resistance: -0.40}`.

### Undertow

`undertow_graft.gd`.

- **Hook `Damage_Taken`:** guard the attacker is alive, `!= owner`, and an enemy of the owner
  (`resolver.GetSides().EnemiesOf(owner)` membership — "when an *enemy* hits"); pull the attacker
  `resolver.BumpTurnBar(attacker, -PULL_PER_RARITY.get(rarity), owner)`; self-reduce
  `resolver.BumpTurnBar(owner, -SELF_TURN_BAR_LOSS)` (default source `-1`, so no enemy tithe);
  return `1.0`. `PULL_PER_RARITY := {0.06 / 0.07 / 0.08 / 0.09}`, `SELF_TURN_BAR_LOSS := 0.05`.
- **Attribute bonus:** Health `+0.13 / 0.16 / 0.19 / 0.22`.
- **Drawback:** `_Drawback` returns `{}` — the self-turn-bar loss is a graft-inherent behavior, not
  an attribute (same pattern as Caravan Cadence's forward-block).

### Glamour

`glamour_graft.gd` — all effects are behavioral; both attribute layers are empty.

- **`Init`:** register `Start_Combat` → `resolver.AddDamageDealtBonus(owner, 0.10)` (P3); register
  `Damage_Taken` → return `1.1` (the +10%-taken drawback; ignores the attacker arg).
- **Override `GetIncomingSingleTargetRedirectChance(owner)`** → `REDIRECT_CHANCE_PER_RARITY`
  `{0.25 / 0.30 / 0.35 / 0.40}` (consumed by P2).
- **Override `GetTargetingDefenceMultiplier()`** → `1.2` (targeted ~20% more; same direction as
  `DoubleTheFunTrait`'s `1.5`).
- **Attribute bonus:** none (`_BonusForRarity` → `{}`). **Drawback:** none as an attribute
  (`_Drawback` → `{}`); the +10% taken and targeting penalty are the behavioral drawbacks.

## Files

- New graft scripts: `Scripts/Character/character_traits/Grafts/glass_refraction_graft.gd`,
  `undertow_graft.gd`, `glamour_graft.gd` (+ `.uid`).
- New `.tres`: `Data/Character_Traits/Grafts/Glass_Refraction_Graft.tres`, `Undertow_Graft.tres`,
  `Glamour_Graft.tres` (mirror an existing graft `.tres`; no numbers in the resource).
- Engine edits: `character_trait.gd` (P1 signature, P2 hook), `battle_resolver.gd` (P1 dispatch, P2
  redirect in `FindSkillTargets`, P3 setter + reagent refactor), `reactive_plating_graft.gd` and
  `double_the_fun_trait.gd` (P1 signature).
- Enemy `_graft_effect` sourcing stays **deferred** (author subclasses + `.tres`, unit-test, leave
  enemy sources null) per `Plan_Symbiote_Graft_Pool.md`.

## Tests

`Tests/unit/`, `test_*.gd`, GUT. One file per primitive (P1–P3) and one per graft, mirroring the
existing graft-test harness (`test_graft.gd` / the turn-bar graft tests) for the headless
`BattleResolver`. Assert: attribute layers via `GetAttributeDelta`; Glass Refraction deals
Mysticism-scaled backlash to the attacker (probe attacker, self-hit/dead guards); Undertow pulls the
attacker and self-reduces (`Turn_Bar_Bump` results with correct signs and targets, enemy guard,
self-hit guard); Glamour redirects a single-target attack at chance 1.0 and not at 0, leaves AoE
alone, adds the damage-dealt bonus, returns `1.1` taken, and returns the targeting multiplier. Use
deterministic setups (chance 0/1, a single eligible redirect target). Test logic only — no
wording/icon assertions. Run the suite headlessly and iterate to green before marking done.

## Dependencies

Graft machinery (shipped) + `BumpTurnBar` (shipped) + P1–P3 here, all self-contained. Independent of
the three remaining stub batches.

## Docs on completion

Fold the three grafts and P1–P3 into `Technical_Design_Document.md` section 9.2 (and the
damage/targeting sections the primitives touch), run `/review-implementation` against this plan,
strike the matching section-15 entry, then delete this plan file per `Plans/README.md`.
