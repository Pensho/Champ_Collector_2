# Plan: Skill Effect Components

Replace the flat field bag on the `Skill` resource with an ordered array of
self-resolving effect components, and turn `BattleResolver.ResolveSkill`'s middle
section into a loop over that array.

## Context

The skill work in `Plan_Skill_Implementation.md` grew `Skill`
(`Scripts/Character/skill_data.gd`) to 25 optional fields, nine of them added by
batch 4 alone, and `ResolveSkill` runs every optional mechanic on every cast behind
`if` guards. A review of batch 4 raised five problems, all symptoms of that one cause:

1. `escalated_at_infractions` names an Emissary-only mechanic in the shared resource,
   and `StatusEffectResolver._ResolveBuffManipulation` does an `is StandingRecordTrait`
   cast in the generic path.
2. `bonus_damage_on_trait_condition` is generic in name only — `CharacterTrait.IsConditionActive()`
   is a single unnamed boolean, so a second trait with a different condition cannot
   coexist with the Jester's.
3. Four separate mechanisms compute *fraction × count* damage bonuses:
   `damage_bonus_per_buff`, `bonus_damage_on_trait_condition`, `ramp_per_use`, and
   `CharacterTrait.GetOutgoingDamageBonus`.
4. Skill descriptions carry "Physical/Magical Damage" language for a damage-type split
   the resolver does not implement.
5. `buff_duration_overrides` is a sibling field patching `buffs`, instead of each
   `buffs` entry carrying its own duration.

Two more of the same shape: `barrier_from_health_paid` / `barrier_from_target_max_health`
are sibling fields for one concept, and `alternating_buffs` is a second copy of `buffs`
for one enemy skill.

One live bug. `StandingRecordTrait.GetOutgoingDamageBonus` is applied by
`BattleResolver._ResolveDamage` to *every* damaging skill the Emissary casts, not just
Citation. It is harmless today only because the Emissary's other two skills deal no
damage. Concept Document 3.1.3 is explicit: "skills state what scales, never their own
rate."

Outcome: a mechanic a skill does not list cannot run for it. That is the structural fix
for both the field bloat and the risk of one optional mechanic affecting another by
accident. All five points, both extra smells, and the Standing Record bug are resolved by
the new schema rather than patched in the old one.

## Scope

In scope: the `Skill` schema, the skill-resolution pipeline, migration of all 69 skill
`.tres` files, the trait-facing hooks those mechanics use, the affected tests, and the
documentation and description cleanup.

Out of scope, deferred to `Plan_Skill_Implementation.md` batch 5: the `ZoneResolver`
lifecycle — charges, sections, durations, per-type effect logic. Zone *placement* moves
onto a `ZoneEffect` component so batch 5 has a home for the data-driven zone-effect
definition it already plans; everything inside `ZoneResolver` after placement stays as-is.
This keeps the pass behaviour-preserving, so the existing suite can prove it.

## Approach (confirmed decisions)

- Effects are **self-resolving Resources**: each subclass implements `Resolve(context)`,
  following the existing `CharacterTrait` precedent of behaviour-carrying resources
  authored as `.tres`. `ResolveSkill` has no knowledge of effect kinds.
- Effect order is **authored data**, not resolver structure. Canonical order —
  costs → buff manipulation → statuses → damage → heals — is documented in the Technical
  Design Document and asserted by a test for the skills that depend on it.
- The work lands in **phases, one commit each**, every phase leaving the suite green and
  `gdlint Scripts/` clean, so a regression is bisectable to one phase.
- The whole pass is behaviour-preserving apart from the Standing Record bug fix in
  phase 3. No test's expected damage or duration value changes; an edit to one means the
  migration changed behaviour and needs investigating, not accommodating.

## Design

### Skill resource

`Skill` keeps only what the UI and turn machinery read. Outside `Scripts/Battle/`, only
name, description, icon_path, target, cooldown, cooldown_left, and skill_type are ever
touched (`Scripts/Battle/battle.gd`, plus `skill_type` in `zone_resolver.gd`,
`calibration_trait.gd`, `living_bloom_graft.gd`, `turn_bar.gd`):

```gdscript
class_name Skill extends Resource
@export var name: String
@export var description: String
@export var icon_path: String
@export var target: Types.Skill_Target      # default target group for the effects
@export var skill_type: Types.Skill_Type    # UI category, and the zone's type
@export var cooldown: int = 0
@export var effects: Array[SkillEffect]
var cooldown_left: int = 0
```

Every other field is deleted.

### Effect base and cast context

New folder `Scripts/Battle/Skill_Effects/`.

```gdscript
class_name SkillEffect extends Resource
## Skill_Default means "use the skill's own target".
@export var target: Types.Skill_Target = Types.Skill_Target.Skill_Default
@export var condition: Types.Skill_Condition = Types.Skill_Condition.None
@export var condition_test: Types.Condition_Test = Types.Condition_Test.At_Least
@export var condition_threshold: float = 0.0
func Resolve(_p_context: SkillCastContext) -> void: pass
```

`SkillCastContext` (`Scripts/Battle/Skill_Effects/skill_cast_context.gd`) replaces the
growing parameter lists on `_ResolveDamage` (nine parameters) and `_ResolveStatusGroups`
(seven), and retires `BuffManipulationResult`:

- Inputs: `resolver`, `caster_ID`, `target_IDs`, `skill`, `caster_attributes`,
  `use_count`, `trait_result` (the existing `TraitSkillResult`).
- Accumulators written by earlier effects and read by later ones: `health_paid`,
  `buffs_consumed`.
- Helper: `TargetsFor(effect)` — `StatusEffectResolver._ResolveStatusGroupTargets` and
  `_ResolveIndependentStatusGroup` move here unchanged.

The context is a deliberate, visible coupling channel (it is how a consume count reaches a
damage bonus). It does not remove ordering-dependence; it makes it explicit and
author-controlled.

### Effect catalog

Every current field maps to exactly one effect:

| Effect | Replaces |
|---|---|
| `DamageEffect` | `damage_scaling`, `defense_ignore_factor`, `damage_bonus_per_buff`, `bonus_damage_on_trait_condition`, `ramp_per_use` |
| `ApplyStatusEffect` | `buffs`, `debuffs`, `duration`, `buff_duration_overrides` — one effect per status, each with its own `duration` |
| `BarrierEffect` | `barrier_from_health_paid`, `barrier_from_target_max_health` (one `source` enum plus a fraction) |
| `HealthChangeEffect` | `health_change`, `heal_scaling` |
| `StealBuffEffect` | `steal_buff_count`, `steal_buff_to` |
| `ConsumeBuffsEffect` | `consume_buffs` (writes `context.buffs_consumed`) |
| `ReduceBuffDurationsEffect` | `buff_duration_reduction` |
| `TurnBarEffect` | `turn_effect` |
| `AlternatingEffect` | `alternating_buffs` — holds an `Array` of effect sets, indexed by `use_count` |
| `ZoneEffect` | the zone half of `duration` / `debuffs`, read by `ZoneResolver.PlaceZone` |
| — | `escalated_at_infractions` — expressed as a `condition` on the base class |

The buff primitives added in batch 4 (`StatusEffectResolver.StealBuff`, `ConsumeBuffs`,
`ReduceBuffDurations`, `_ExpireBuffs`) stay where they are and are called by the effects.

### Unified damage bonuses

`DamageEffect.bonus_per: Dictionary[Types.Damage_Bonus_Source, float]`. New enums in
`Scripts/common_enums.gd`:

```gdscript
enum Damage_Bonus_Source { Buffs_On_Caster, Buffs_Consumed, Uses_This_Battle,
                           Trait_Condition, Trait_Counter_On_Target }
enum Skill_Condition { None, Trait_Condition, Trait_Counter_On_Target }
enum Condition_Test { At_Least, Below }
```

plus `Skill_Target.Skill_Default`.

The bonus is `fraction × Count(source)`, so binary conditions fold in as count 0 or 1.
For `Trait_Counter_On_Target` the authored fraction is `1.0` and the per-unit rate comes
from the trait — the skill states *that* it scales, never the rate, per Concept 3.1.3.

**Application point is a property of the source, not a separate field.**
`Uses_This_Battle` scales `caster_scaled_attribute_aggregate` *before* mitigation, exactly
as `ramp_per_use` does today; the other four sources add to the final damage bonus
alongside `_damage_dealt_bonus`. The two are genuinely different effects — "this skill
grows" versus "this hit lands harder" — and the split preserves current behaviour exactly.

Making the ramp additive instead would have cost Heap On, Breaching Charge, and Cinder
Sermon between 5% and 26% of their ramped damage, growing with both use count and target
Defence, because the pre-mitigation form improves Defence penetration as well as raw size
(mitigation rises with attack size, so `mitigation(S) < mitigation(S·R)`). That is a
balance change, not a rounding difference, so the per-source rule is the deliberate choice.
Document it per source in Technical Design Document 7.4.

### Trait hooks

- `CharacterTrait.GetConditionCount(p_owner_ID, p_target_ID, p_source, p_resolver) -> float`
  answers `Trait_Condition` (0 or 1) and `Trait_Counter_On_Target` (already multiplied by
  the trait's own rate). It replaces `IsConditionActive()` and `StandingRecordTrait`'s
  `GetOutgoingDamageBonus` override — which fixes the bug, since the Infraction rate now
  reaches damage only where a `DamageEffect` asks for it.
- `GetAppliedStatusValue` stays as-is (Sanction's magnitude source); it is already
  correctly trait-owned.
- `GetOutgoingDamageBonus` stays on the base class for `BloodscentGraft`, which uses it
  legitimately as an always-on trait effect.
- `StandingRecordTrait` keeps `GetInfractions` for its own use; no shared code names
  Infractions again.

### Resolution pipeline

`ResolveSkill` keeps its turn-machinery spine — trait hook, caster status ticks,
cooldowns, `TriggerZones`, end-of-turn hook — and its middle becomes:

```gdscript
var context := SkillCastContext.new(self, p_caster_ID, p_target_IDs, cast_skill,
        caster_attributes, _SkillUseCount(p_caster_ID, cast_skill), trait_result)
for effect in cast_skill.effects:
    if(context.ConditionMet(effect)):
        effect.Resolve(context)
```

`BattleResolver` exposes the internals effects need as public methods rather than leaving
them underscore-private: `ResolveEffectDamage`, `ApplyHealthCost`, `ApplyHeal`, `Emit`
(`MaxHealth` is already public as `GetMaxHealth`).

## Phases

Each phase leaves the GUT suite green and `gdlint Scripts/` clean, and is staged and
presented for approval before committing.

### Phase 0 — plan documents (complete)

This document, plus the batch 4 and batch 5 notes in `Plan_Skill_Implementation.md`
recording that batch 4's fields were replaced by effect components and that zone
placement now runs through `ZoneEffect` while the `ZoneResolver` lifecycle rework remains
batch 5's job.

### Phase 1 — effect classes and pipeline (complete)

Add `Scripts/Battle/Skill_Effects/` (base, context, eleven effect subclasses), the new
enums, the `CharacterTrait` getter, and the new public `BattleResolver` methods. Add
`effects` to `Skill` and run the effect loop in `ResolveSkill` *alongside* the existing
flat-field path, so nothing breaks yet. Move `_ResolveStatusGroupTargets` and
`_ResolveIndependentStatusGroup` from `StatusEffectResolver` to `SkillCastContext`
(`HealthTransferResolver` and `ZoneResolver` follow). New unit tests per effect class,
built with new `Tests/unit/helpers/test_factory.gd` helpers.

Delivered with three naming deviations, all deliberate — phase 4's documentation must use
the real names: the catalog's single `ApplyStatusEffect` shipped as `ApplyBuffEffect` plus
`ApplyDebuffEffect` (buff and debuff application genuinely diverge, and the split still
yields eleven subclasses); `ApplyHealthCost` / `ApplyHeal` shipped as `ResolveHealthCost` /
`ResolveHealthGain`; and no public `Emit` was needed, because those two methods emit their
own `CombatResult`. `ZoneEffect` ships inert, since `ZoneResolver.PlaceZone` is rewired in
phase 2.

### Phase 2 — data migration and field removal (complete)

A throwaway `Scripts/Debug/migrate_skills_to_effects.gd` reads each of the 69 `.tres`
files under `Data/Character_Skill_Variants/` and rewrites its flat fields as an ordered
`effects` array, run headless; the script is deleted in the same commit once its output is
verified. Then delete every migrated field from `Skill`, delete
`Scripts/Battle/buff_manipulation_result.gd`, delete the old paths in
`battle_resolver.gd` / `status_effect_resolver.gd` / `health_transfer_resolver.gd`, point
`ZoneResolver.PlaceZone` at the skill's `ZoneEffect` for duration and debuffs, and update
the 21 test files that construct skills from flat fields (`test_factory.gd`'s
`make_strike_skill` / `make_lava_zone_skill` first, which covers most of them). Add a test
asserting every shipped skill `.tres` loads and carries at least one effect.

Also clears the phase 2 findings below: the `context.health_paid` seed and the
`SkillCastContext` accessor bypass.

Delivered with one deliberate deviation from the Blocker's literal text: Signed Writ's
`escalated_at_infractions` is migrated now, not deferred, using the existing (overloaded)
`Trait_Counter_On_Target` contract with a hardcoded `condition_threshold` of `6 × 0.025`
(the rate of the only rarity Signed Writ ships at today) — confirmed with the user rather
than leaving the field as a phase-2 exception. The `ApplyDebuffEffect` half of the
escalation pair authors the escalated branch's `duration` as the full value (2), not a
`+1` delta, because `_InsertOrRefresh`'s `p_always_refresh_duration` overwrites rather than
adds; `ReduceBuffDurationsEffect` is additive, so its pair does use `+1` per effect. The
real contract split and clean count-based re-expression remain phase 3's job. Also found
and fixed along the way: two more `Skill.new()` call sites outside `.tres` data
(`living_bloom_graft.gd`, `calibration_trait.gd`) that built zone skills from the flat
`duration` field; `ZoneResolver.PlaceZone` bypasses the effect loop entirely for
zone-target skills (cast routes straight to `PlaceZone`, never `ResolveSkill`), so
zone-type skills carry only a `ZoneEffect`, never the generic resolution effects; and the
per-target `Defend`-hook trigger in `ResolveSkill`'s tail loop was dead code once
`ResolveEffectDamage` started triggering it itself, so it was deleted rather than kept
redundant. One accepted expected-value change, the sole exception to the no-value-changes
rule: `test_transfusion_barrier.gd`'s zero-multiplier case moved from `0.0` to `-1.0`,
which is delta (4) below becoming real. No shipped skill reaches it — every
`barrier_from_*` skill authored a positive fraction — so the new "grant nothing" reading
is the intended one; it is recorded here so a later phase does not re-derive it as a
regression.

### Phase 3 — behaviour fixes and wording

Remove `StandingRecordTrait.GetOutgoingDamageBonus` so the Infraction rate applies only
through Citation's `DamageEffect`; re-express Signed Writ's escalation as a conditional
effect pair — which is blocked by the `GetConditionCount` finding below until the condition
contract splits from the damage-bonus one. Lowercase "Deals damage" in the ten batch-4 descriptions, and strip "Physical Damage"
and "Magical Damage" from `Concept_Document.md` (38 occurrences) and
`Encounter_Design_Document.md` (13) — the resolver has no damage-type split, so the words
describe a mechanic that does not exist.

### Phase 4 — documentation

Rewrite Technical Design Document section 6.1 (the `Skill` template becomes the effect
catalog), 7.4 (the effect pipeline, canonical order, and the context accumulators), and the
trait-getter passage in section 9. Remove the "skill implementation batch 4" phrasing from
the Technical Design Document — plan metadata does not belong in a document that outlives
the plan. Also sweep for stale references outside those three sections: phase 2 deleted
`HealthTransferResolver`, `BuffManipulationResult`, `CharacterTrait.IsConditionActive`, and
`_SkillRampMultiplier`, and the document still describes at least `HealthTransferResolver`
as a live subsystem-composition precedent (around line 1495) — grep the whole document for
all four names rather than assuming sections 6.1/7.4/9 are the only places they appear.

## Findings

Review findings raised against the implemented phases, each tagged with the phase that
resolves it. **Blocker** — the named phase cannot be authored correctly until it is
resolved. **Concern** — a real defect or gap; fix within the named phase. **Nit** —
cosmetic or bookkeeping. A finding that is a standing property to preserve rather than a
piece of work belongs in "Watch for" instead. A resolved finding is deleted from this
section, not annotated as fixed — the section lists open work only, and the fix itself is
in the code.

### Blocker — resolve before phase 3

**`GetConditionCount` overloads two contracts.** `StandingRecordTrait.GetConditionCount`
returns `infractions × _rate_per_infraction`, and `SkillCastContext.ConditionMet` compares
that already-multiplied value against `condition_threshold`. That is right for a damage
bonus and wrong for a condition: re-expressing Signed Writ's `escalated_at_infractions = 6`
would need a threshold of `6 × rate`, and the rate is rarity-dependent (0.025 to 0.04), so
one skill would need four authored thresholds — each of them the trait's own rate written
into skill data, which is what Concept 3.1.3 forbids and what this pass exists to prevent.
`Trait_Condition` is not a substitute: it is binary, and `StandingRecordTrait` returns 0.0
for it. The fix is to split the contract — either a raw-count `Damage_Bonus_Source`, or
`ConditionMet` querying a separate un-multiplied hook. Signed Writ now authors a condition
(migrated in phase 2 against the overloaded contract, with the user's explicit sign-off —
see phase 2's entry above), so this is reachable today, not just a future risk.

### Nit

**Plan bookkeeping (phase 4).** Phase 1's naming deviations are recorded in its own entry
above; the documentation rewrite must use the shipped names, not the catalog's.

**Stale comments naming deleted symbols (phase 3).** `Scripts/Battle/Skill_Effects/zone_effect.gd`'s
class docstring still says `ZoneResolver.PlaceZone` does not read the effect yet, which phase 2
made false; `skill_cast_context.gd` line 7 names `_ResolveStatusGroups` and
`BuffManipulationResult`, and `Tests/unit/test_sequence_lock.gd` line 6 names `_CastBuffOfType` —
all three symbols are gone. Reword each in terms of the surviving API.

**`gdlintrc` `max-public-methods` can revert (phase 3).** `CharacterTrait` is back to 35 public
methods now that `IsConditionActive` is deleted, so the phase 1 bump to 36 is no longer needed;
`gdlint Scripts/` was confirmed clean at 35. The batch 4 `BattleResolver` bump is separate and
still load-bearing.

**Jester condition test asserts a private field (phase 3).** `Tests/unit/test_jester_skills.gd`
line 76 reads `DoubleTheFunTrait._avoided_since_last_turn` directly, so it no longer exercises the
contract the skill uses. Assert through `GetConditionCount(..., Trait_Condition, ...)` instead —
best done alongside the `GetConditionCount` contract split, since that is the hook it should be
testing.

**Migration test name outlives the migration (phase 3 or 4).** `Tests/unit/test_skill_data_migration.gd`
asserts a standing invariant — every shipped skill loads and carries at least one effect — under a
name that describes a one-time event. Rename to `test_skill_resources.gd`.

## Watch for

- Every phase must be green with **no expected-value changes**; the Standing Record fix in
  phase 3 only removes a bonus that was never meant to apply, and no shipped skill relies
  on it. An edit to an expected number means the migration changed behaviour.
- `Uses_This_Battle` keeps its pre-mitigation application point. Folding it into the
  additive term is the one change in this pass that would move damage numbers.
- Effect order is now data. A mis-ordered `.tres` is a silent behaviour bug rather than a
  compile error — hence the canonical order and the test that asserts it.
- Three small, deliberate behaviour deltas between the old per-target loop and the new
  effect loop, introduced in phase 1 and not yet exercised by any migrated skill: (1)
  `SkillCastContext.TargetsFor` filters a `DamageEffect`'s targets to those still alive,
  where the old loop would resolve damage against any target still present in
  `_characters` regardless of Health; (2) effect order means every `DamageEffect` in a
  skill's `effects` array resolves before any later `TurnBarEffect`, where the old code
  interleaved damage and the turn-bar bump per target; (3) `HealthChangeEffect` guards on
  a positive amount, where `ResolveHealthGains` emits a zero-amount `Heal` result
  unconditionally. All three read as improvements, but phase 2's migration should verify
  them deliberately against the skills that could expose them (multi-target skills that
  can kill some but not all targets; skills with both damage and a turn-bar bump; skills
  whose heal can compute to zero) rather than discover a behaviour change after the fact.
- Two more behaviour deltas the same migration surfaced, both unreachable in shipped data
  today: (4) `BarrierEffect` skips granting entirely on a non-positive value, where the old
  path fell back to the status registry's default magnitude and still granted a Barrier
  (`test_transfusion_barrier.gd`'s zero-multiplier case exercises this; every shipped
  `barrier_from_*` skill authors a positive fraction, so it never fires today); (5) a skill
  combining a `DamageEffect`-adjacent trait turn-bar bump with a `TurnBarEffect` now emits
  two separate `Turn_Bar_Bump` results instead of one combined bump, so a sign-gating trait
  (Anchor, Steadfast) or `Skills.TurnBarTithe` would see each part independently rather than
  their sum — no shipped skill both deals damage via a trait bump and carries a
  `TurnBarEffect`, so this is latent, not live.
- A sixth delta, live in shipped content: the old pipeline resolved heals *before* the per-target
  damage loop, where the canonical effect order puts them after. Fateful Glimpse authors
  `[DamageEffect, HealthChangeEffect]`, so its `Most_Injured_Ally` heal target is now chosen once
  the hit has landed — and a target carrying `GlassRefractionGraft` backlashes damage onto the
  caster inside `ResolveEffectDamage`, which can change who the most-injured ally is. The suite is
  green either way. Phase 4's order documentation must state which reading is canonical; if the
  old order was intended, Fateful Glimpse authors the heal first rather than the canonical order
  changing.
- `gdlintrc`'s `max-public-methods` was raised by batch 4 (`BattleResolver`) and again in
  phase 1 (`CharacterTrait`, 35 → 36, for `GetConditionCount`); revert either bump if the
  class it was raised for shrinks back below the old limit.
- `test_character_preset_skill_invariant.gd` (skill slot 0 has zero cooldown) must still
  hold for every migrated preset.
- Skills are deep-copied per character instance; per-battle state (use counts,
  alternation) stays on the resolver, never on the effect resource — the existing
  `_skill_use_counts` precedent.
- `AlternatingEffect` holds one effect per alternate, not the array of effect *sets* the
  design sketched. Reliquary Ward — the only skill using `alternating_buffs`, one buff per
  alternate — migrates fine, so this is not worth changing now. An alternate needing two
  effects has no expression short of a composite effect class; add one then, not before.

## Documentation

- Technical Design Document sections 6.1, 7.4, and 9, as described in phase 4.
- `Plan_Skill_Implementation.md` batch 5 carries the `ZoneResolver` deferral note.
- On completion: run `/review-implementation` against this plan, update the documents
  above, then delete this file per the `Plans/README.md` retention rule.
