# Plan — Graft on-kill and conditional damage (Batch: Bloodscent)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`, `Symbiote_Graft_Pool.md`).
Builds two damage-path primitives — a killer-side on-kill hook and a target-Health-conditional
outgoing-damage bonus — then the single graft that falls out. Follow the graft conventions in
`Plan_Symbiote_Graft_Pool.md` ("Conventions every concrete graft follows"). Independent of the other
roadmap batches; its only external dependency, `ResolveTraitHeal`, has already landed.

## Grounding — what already exists vs. what the stub assumed

The stub predates the resolver split. Verified against the current tree:

- **Death fires nothing on the killer today.** `_ApplyHealthLoss` (`battle_resolver.gd:494-509`)
  detects the alive→dead transition (`was_alive` at `:502`, `<= 0` at `:508`) and calls
  `_HandleDeath` (`:521-541`), which fires only the *victim's* `On_Death` (`:530`) and allies'
  `Ally_Death` (`:541`). Both `_ApplyHealthLoss` and `_HandleDeath` take **only the victim ID** — no
  killer. `Combat_Event` has no `On_Kill`.
- **But the killer IS in scope in `_ResolveDamage`.** The killing blow lands at
  `_ApplyHealthLoss(p_target_ID, damage_dealt)` (`:634`), inside `_ResolveDamage` (`:559-644`), where
  `p_caster_ID` and `caster` (`:637`) are live and the `Damage_Dealt` hook already dispatches on the
  caster (`:637-640`). So the on-kill hook fires **here**, right after the victim's death is applied —
  no killer-ID plumbing through `_HandleDeath`. This also correctly scopes the hook to **attack**
  kills; reagent-cost / turn-bar self-damage deaths reach `_HandleDeath` by other paths and should
  not count as a Bloodscent "killing blow." Deathward rescue (`:505-506`) leaves `_current_health == 1`,
  so a post-`_ApplyHealthLoss` `_current_health <= 0` check is a true kill.
- **Damage-dealt bonus is additive and not target-conditional.** `Skills.MitigatedDamage`
  (`skills.gd:240-256`) takes `p_damage_dealt_bonus`, applied as `damage*(1+bonus)` via
  `Skills.DamageDealt` (`skills.gd:234-235`). `_ResolveDamage` reads `_damage_dealt_bonus.get(p_caster_ID, 0.0)`
  at `:603`. The `_damage_dealt_bonus` dict (`:31-32`) is per-caster and battle-persistent (only the
  `Health_Cost_Damage_Bonus` reagent writes it, `:360-361`); it cannot vary by target. **No existing
  trait hook returns a pre-application outgoing multiplier that sees both attacker and target**
  (`OnDamageDealt` sees both but is `void` and fires after `_ApplyHealthLoss`; `OnDamageTaken` is
  pre-application but target-only). So the conditional modifier is a genuine new hook. The closest
  structural precedent is `_OpportunistDamageMultiplier(caster, target)`
  (`status_effect_resolver.gd:512-520`), already threaded into `MitigatedDamage` as
  `p_opportunist_multiplier` — an attacker+target pre-application factor.
- **Lowest-current-Health enemy** has no shared helper; mirror Carrion Bloom's inline min-scan
  (`carrion_bloom_graft.gd:32-40`) over `resolver.GetSides().EnemiesOf(owner).AliveMembers(characters)`.
  Max Health is the **public** `GetMaxHealth(p_character_ID)` (`battle_resolver.gd:76-77`, wrapping
  `_MaxHealth`); current Health is the raw `character._current_health`.
- **`ResolveTraitHeal([owner], fraction)`** (`battle_resolver.gd:282-295`, landed) is the
  killing-blow heal; batch nesting is safe (`_BeginBatch`/`_EndBatch`, `_batch_depth`). This is the
  stub's hard dependency and it is already in place — no separate heal path is added here.
- **New surfaces are trait virtuals + a private dispatch + a folded argument** — no new public method
  on `BattleResolver` (stays 20/25 public methods, 653 lines), so `Plan_Symbiote_Graft_Pool.md`'s
  section-15.10 resolver-ceiling warning does not bind this batch.
- **`_ResolveDamage` is also edited by `Plan_Graft_Retaliation.md`** (broadening `OnDamageTaken` at
  `:628-630`). The edits are in different regions and independent, but whichever batch lands second
  should re-verify the `_ResolveDamage` line numbers before editing.

**Design decisions (settled):**
- **On-kill fires in `_ResolveDamage`, not `_HandleDeath`** — keeps the killer ID out of the death
  plumbing and scopes the hook to attack kills.
- **The conditional modifier is a generic additive outgoing-damage-bonus hook**; the target-Health
  band logic (lowest-Health / above-50%) lives in Bloodscent, folded into the existing
  `p_damage_dealt_bonus` channel so `−0.25` naturally yields `0.75×`.
- **"Penalty wins":** a target above 50% Health always contributes `−0.25`; the lowest-Health bonus
  applies only when the target is at/below 50% Health. The two clauses are not summed.

## Primitives to build first (each with tests)

### P1 — Killer-side on-kill hook

- Add `Types.Combat_Event.On_Kill` (`common_enums.gd`, appended after `Damage_Dealt` at `:196`).
- Add `CharacterTrait.OnKill(_p_owner_ID: int, _p_victim_ID: int, _p_resolver: BattleResolver) -> void`
  (no-op default, base-class print, mirroring `OnDamageDealt`/`OnAllyDeath` at
  `character_trait.gd:74-79`), gated by `_execution_steps` like the other event hooks.
- In `_ResolveDamage`, after the `Damage_Dealt` dispatch (`:640`, reusing the already-bound `caster`
  at `:637`), fire the hook when the target just died and the attacker is alive:
  ```
  if(target._current_health <= 0 and caster._current_health > 0):
  	var kill_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.On_Kill)
  	if(null != kill_trait):
  		kill_trait.OnKill(p_caster_ID, p_target_ID, self)
  ```
  Fires only for attack kills (reagent/turn-bar deaths never reach `_ResolveDamage`); a Deathward
  rescue (`_current_health == 1`) is not a kill.
- Tests: a probe trait registered on `On_Kill` receives `OnKill(owner, victim)` when its character
  lands a lethal hit; it is **not** fired on a non-lethal hit; it is **not** fired when Deathward
  rescues the target to 1 HP.

### P2 — Target-Health-conditional outgoing-damage bonus

- Add `CharacterTrait.GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float`
  returning `0.0` (additive percent) — consulted unconditionally on `_trait` (like
  `GetIncomingDebuffDurationBonus`).
- In `_ResolveDamage`, after `target` is bound (`:589`) and before the `MitigatedDamage` call
  (`:601-604`), compute the attacker's conditional bonus:
  ```
  var conditional_bonus: float = 0.0
  var attacker_trait: CharacterTrait = _characters[p_caster_ID]._trait
  if(null != attacker_trait):
  	conditional_bonus = attacker_trait.GetOutgoingDamageBonus(p_caster_ID, p_target_ID, self)
  ```
  and fold it into the `p_damage_dealt_bonus` argument at `:603`:
  `_damage_dealt_bonus.get(p_caster_ID, 0.0) + conditional_bonus`. It is evaluated per-attack against
  the target's current Health and **not** written back to `_damage_dealt_bonus` (a live computed add,
  not persisted). Reuses `Skills.DamageDealt`'s `damage*(1+bonus)` semantics, so a `−0.25` return
  yields `0.75×`.
  - Scope note: the soaker/redirect share (`:614-617`) keeps only the base persistent bonus; the
    conditional band is evaluated for the primary target being struck (redirect is an edge case).
- Tests: a probe returning `+0.5` raises the primary target's dealt damage ~50% and `−0.25` lowers it
  ~25% (assert via `_ResolveDamage`/`ResolveTraitDamage` result amounts, deterministic roll); a default
  trait leaves damage unchanged; the probe branching on `_p_target_ID` proves per-target evaluation.

## Graft that falls out

Numbers are the design-doc literals (`Symbiote_Graft_Pool.md` "Bloodscent"). Rarity order:
Uncommon / Rare / Epic / Legendary.

### Bloodscent

`Scripts/Character/character_traits/Grafts/bloodscent_graft.gd`,
`class_name BloodscentGraft extends GraftEffect`.

- **Constants:** `LOWEST_HEALTH_BONUS_PER_RARITY: Dictionary[Types.Rarity, float]` =
  `{Uncommon: 0.20, Rare: 0.25, Epic: 0.30, Legendary: 0.35}`; `KILL_HEAL_FRACTION := 0.15`;
  `ABOVE_HALF_PENALTY := 0.25`; `HALF_HEALTH_THRESHOLD := 0.5`.
- **State:** `_lowest_health_bonus: float = 0.0`.
- **Attribute layer:** `_BonusForRarity` → `{}` (no bonus — damage rides on Resistance);
  `_Drawback` → `{}` (the −25% vs healthy enemies is graft-inherent behaviour, not an attribute —
  same pattern as Caravan Cadence's `BlocksForwardTurnBarBump`).
- **`Init(rarity)`:** `super.Init(rarity)`, `_lowest_health_bonus = LOWEST_HEALTH_BONUS_PER_RARITY.get(rarity, 0.0)`,
  set `_title`/`_body`, register
  `_execution_steps[Types.Combat_Event.On_Kill] = Callable(self, "OnKill")`. (`GetOutgoingDamageBonus`
  is an unconditional override — no `_execution_steps` entry needed; `On_Kill` must be registered
  because it is dispatched via `ActiveHook`.) Do **not** override `_trait_texture`.
- **`OnKill(owner, victim_ID, resolver)`** (override): `resolver.ResolveTraitHeal([owner], KILL_HEAL_FRACTION)`
  — heal 15% max Health on a killing blow.
- **`GetOutgoingDamageBonus(owner, target_ID, resolver)`** (override, "penalty wins"):
  ```
  var characters: Dictionary[int, Character] = resolver.GetCharacters()
  var target: Character = characters[target_ID]
  if(float(target._current_health) > HALF_HEALTH_THRESHOLD * float(resolver.GetMaxHealth(target_ID))):
  	return -ABOVE_HALF_PENALTY
  var enemies: Array[int] = resolver.GetSides().EnemiesOf(owner).AliveMembers(characters)
  if(enemies.is_empty()):
  	return 0.0
  var lowest_ID: int = enemies[0]
  for enemy_ID in enemies:
  	if(characters[enemy_ID]._current_health < characters[lowest_ID]._current_health):
  		lowest_ID = enemy_ID
  return _lowest_health_bonus if target_ID == lowest_ID else 0.0
  ```
  Mirrors Carrion Bloom's min-scan (`carrion_bloom_graft.gd:32-40`) but over `EnemiesOf`;
  `GetMaxHealth` is the public wrapper at `battle_resolver.gd:76`.
- **Attribute bonus:** none. **Drawback:** none as an attribute; the −25% against enemies above 50%
  Health is the behavioural drawback.

## Files

- New graft script: `Scripts/Character/character_traits/Grafts/bloodscent_graft.gd` (+ `.uid`).
- New `.tres`: `Data/Character_Traits/Grafts/Bloodscent_Graft.tres` (mirror an existing graft `.tres`;
  `script_class`, one `ExtResource` for the `.gd`, `script = ExtResource(...)`; no numbers in the
  resource).
- Engine edits:
  - `common_enums.gd` — `Combat_Event.On_Kill` (P1).
  - `Scripts/Character/character_traits/character_trait.gd` — `OnKill` and `GetOutgoingDamageBonus`
    virtuals (P1, P2).
  - `Scripts/Battle/battle_resolver.gd` — conditional-bonus fold into the `MitigatedDamage` argument
    (`:601-604`, P2) and the `On_Kill` dispatch after `:640` (P1).
- Enemy `_graft_effect` sourcing stays **deferred** (author subclass + `.tres`, unit-test, leave every
  enemy source null) per `Plan_Symbiote_Graft_Pool.md`.

## Tests

`Tests/unit/`, `test_*.gd`, GUT. One file per primitive (P1, P2) and one for the graft
(`test_bloodscent_graft.gd`), mirroring the existing graft-test harness (`test_turn_bar_control_grafts.gd`
/ `test_graft.gd`, with `helpers/test_factory.gd`'s roster/sides builders) for the headless
`BattleResolver`. Assert:

- **P1:** `On_Kill` dispatched with `(owner, victim)` on a lethal attack; not on a non-lethal hit;
  not on a Deathward rescue to 1 HP.
- **P2:** a probe `GetOutgoingDamageBonus` of `+0.5` / `−0.25` raises / lowers the primary target's
  dealt damage accordingly; default trait unchanged; per-target evaluation (probe branches on the
  target ID). Use a deterministic damage roll.
- **Bloodscent:** empty attribute layer (`GetAttributeDelta` == 0 for a probe attribute); `OnKill`
  heals 15% max Health via `ResolveTraitHeal`; `GetOutgoingDamageBonus` returns `−0.25` for a target
  above 50% Health (even when it is the lowest-Health enemy — "penalty wins"), `+bonus` per rarity for
  the lowest-Health enemy at/below 50%, and `0.0` for a non-lowest enemy at/below 50%.

Use deterministic setups (known Health values, single lethal hit). Test logic only — no wording/icon
assertions. Run the suite headlessly and iterate to green before marking done.

## Dependencies

Graft machinery (shipped) + the landed `ResolveTraitHeal` + this batch's two primitives (P1, P2), all
self-contained here. Independent of the other roadmap batches; note only that `Plan_Graft_Retaliation.md`
also edits `_ResolveDamage` (different region), so whichever lands second re-verifies line numbers.

## Docs on completion

Fold Bloodscent, the on-kill hook, and the conditional outgoing-damage bonus into
`Technical_Design_Document.md` section 9.2 (and the damage-resolution section the primitives touch),
run `/review-implementation` against this plan, strike the matching section-15 entry, then delete this
plan file per `Plans/README.md`.
