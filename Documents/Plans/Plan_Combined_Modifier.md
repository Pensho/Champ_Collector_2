# Plan: Combined Modifier

Phase 1 of `Plan_Blowout_Alignment.md`. Implements the multiplicative damage channel —
channel 2 of `Concept_Document.md` section 1.1.3 — as one declared mechanism with one
placement and one grouping rule.

Prerequisite for every later phase of the master plan: Phase 2 needs somewhere for a
status to register a factor, Phase 3 needs each cascade instance to carry its own
modifier, Phase 4 needs the per-source breakdown to name what contributed.

## Status

**Not started.** Design below is settled; steps are unexecuted.

## What already exists

The channel is not greenfield. `_ResolveDamage` in `Scripts/Battle/battle_resolver.gd`
already threads eight modifier inputs into `Skills.MitigatedDamage` — some multiplicative,
some additive fractions, some on the scaled aggregate and some on final damage. This plan
is their unification, not a new addition.

## Design (confirmed decisions)

### Placement: on the scaled aggregate

The modifier multiplies `Caster_Scaled` *before* the mitigation ratio is computed, per
section 1.1.4. The aggregate also feeds that ratio, so the placement is worth nearly double
against a boss-tier Defence and worth more the tankier the target. Every existing source
moves there, including the ones currently sitting on final damage.

This strengthens every existing modifier — against Defence 120 a 1.2x becomes roughly
1.35x — and encounter tuning drifts until Phase 7 retunes. Accepted, not compensated:
shrinking authored magnitudes to preserve current output would hide the pillar's own
numbers behind a correction factor.

Section 3.2.1's formula line currently places `Combined_Modifier` on the final product,
contradicting 1.1.4. The pillar outranks the rest of the document, so 3.2.1 is the line
that changes.

### Grouping keys on mechanic identity, never on character identity

Which character applied an effect must not enter the calculation. The same combination
scores the same whether it comes from one champion or three, and adding a champion who
contributes nothing relevant must not change the result.

The bucket key is the contributing **mechanic**: the buff type, the debuff type on the
target, the trait resource, the skill effect.

- Contributions sharing a key **add** into one bucket.
- Distinct keys **multiply**.
- `Product() = Π over keys (1 + bucket[key])`.

The live example of a shared key is `DamageEffect.bonus_per`: a skill's several count
sources (buffs on caster, buffs consumed, zones on the turn bar) already add together and
stay one bucket keyed to that skill. That bucket then multiplies with a trait's.

**This phase ships the mechanism, not a general law about which mechanics share a key.**
Most content is not yet redesigned, so which effects ought to add and which ought to
multiply is not knowable yet — it is decided per mechanic in Phase 2 (statuses and zones)
and Phase 5 (kits), as an authoring decision at each contribution site. What this phase
guarantees is that the choice is expressible and enforced: a single key can never multiply
with itself, which is the mechanical enforcement the master plan asks for in place of
author discipline.

### Assembled per resolution, never stored

A likely channel-3 shape is a mechanic that makes a champion repeat their skill so the
built-up conditions pay out again. That only works if each repeat re-reads live
conditions rather than reusing a cached product — a target debuff consumed by the first
instance must not still be paying the second.

`CombinedModifier` is therefore constructed inside the damage resolution and discarded
with it: no reference to the resolver, never cached on a character, a skill, or the
resolver. Section 1.1.3 already says the modifier is "not a meter that is filled"; this
phase makes that structurally true rather than incidental, because Phase 3 rests on it.

### Attribution rides on the object

`CombatResult` gains one field holding the assembled modifier — its per-mechanic buckets
and its product — populated for `Kind.Damage`. Phase 4 can then name and order
contributors with no further plumbing, and the keys double as display labels.

This parallels the existing `visual_scene` object field rather than adding a float
dictionary alongside `amount_by_source`, which carries a different quantity (damage
amounts, populated only for `Debuff_Tick`).

## Source inventory

The eight existing inputs, their origin, their current placement, and their key. This
table is the definition of done for the migration.

| Current input | Origin | Current placement | Key |
|---|---|---|---|
| `p_trait_multiplier` | `TraitSkillResult._damage_multiplier` from `OnSkillCast` | aggregate, multiplicative | trait resource |
| `p_ramp_multiplier` | `DamageEffect.bonus_per[Uses_This_Battle]` | aggregate, multiplicative | the skill |
| `_damage_multiplier[caster]` | buffs with `MagnitudeKind.DamageMultiplier` on self-tick | final, multiplicative, one-shot | buff type |
| `_damage_dealt_bonus[caster]` | reagents, `GlamourGraft` | final, additive, battle-persistent | reagent / graft |
| `GetOutgoingDamageBonus` | trait and graft hook (`BloodscentGraft`) | final, additive | trait / graft |
| `_OpportunistDamageMultiplier` | buffs with `PerTargetDebuffDamagePercent` | final, multiplicative | buff type |
| `bonus_per` counts | `DamageEffect._AdditiveBonus` | final, additive | the skill — one bucket, all counts add |
| `bonus_per_debuff_on_target` | `DamageEffect` | final, additive | **per debuff type** — each its own factor |

Every assignment preserves current add/multiply behaviour except the last row, which is
where the change bites: target debuffs stop being one additive lump on the caster and
become independent multiplying factors — the channel-2 behaviour section 1.1.3 describes.

All keys here are provisional. Phase 2 owns the status and zone assignments, Phase 5 the
trait and skill ones.

### Explicitly outside the channel

These stay where they are: the critical multiplier, the 0.95–1.05 random roll,
`Defense_Ignore_Factor`, the Shield Wall redirect fraction, and every defender-side term
(`_DamageTakenMultiplier`, `OnDamageTaken`, barrier absorption, Deathward). They are
mitigation and separate formula terms, not blowout.

## Steps

### 1. The value object

`Scripts/Battle/combined_modifier.gd`, a new `RefCounted`. `Contribute(p_key: StringName,
p_fraction: float)` adds into that key's bucket; `Product() -> float` returns the product
over keys of `1 + bucket`; the buckets are readable for presentation. Each bucket's factor
clamps at 0 so a damage-reducing contribution cannot invert the sign.

Unit tests for the grouping rule land with it: two contributions under one key add, two
under distinct keys multiply, an empty modifier is exactly 1.0.

### 2. Reshape the formula

`Skills.MitigatedDamage` in `Scripts/Battle/skills.gd` loses `p_damage_multiplier`,
`p_damage_dealt_bonus`, and `p_opportunist_multiplier`, gaining a single combined-modifier
float applied to `p_caster_scaled_attribute_aggregate` before `damage_ratio` is computed.
The `Skills.DamageDealt` helper goes away with the additive term. The Shield Wall soaker
call site re-mitigates against its own Defence using the same modifier, as it does today.

Watch for: the aggregate now feeds `damage_ratio` at burst magnitudes, where the ratio
saturates near 1. That is the intended behaviour recorded in section 1.1.4, not a bug.

### 3. Rethread the resolution

`ResolveEffectDamage` and `ResolveTraitDamage` in `Scripts/Battle/battle_resolver.gd` take
a `CombinedModifier` in place of `p_trait_multiplier`, `p_ramp_multiplier`, and
`p_bonus_damage_fraction`.

`DamageEffect.Resolve` in `Scripts/Battle/Skill_Effects/damage_effect.gd` builds one per
target — it already loops targets, and the per-debuff keys are target-dependent — seeds
its own contributions, and hands it over. The resolver then adds the resolver-owned
sources: statuses through `StatusEffectResolver`, the caster's trait hooks, and
`_damage_dealt_bonus`.

`ClearZoneEffect` is the other `trait_result._damage_multiplier` reader and moves with it.

Watch for: the one-shot `_damage_multiplier.erase()` keeps its current semantics and its
current position after the redirect, so a consumed one-shot buff still pays exactly one
hit including the soaker's share.

### 4. Attribution

`CombatResult` gains the modifier field; `_EmitDamageResult` populates it for
`Kind.Damage`. No consumer is written in this phase — Phase 4 owns presentation.

### 5. Re-baseline the tests

Aggregate placement shifts every exact-ratio assertion. `Tests/unit/test_opportunist_damage.gd`
asserts a 1.2 ratio and `Tests/unit/test_buff_count_damage.gd` a fixed additive bonus;
both move. Also touched: the four `trait_result._damage_multiplier` writers
(`test_calibration_trait.gd`, `test_chosen_vessel_trait.gd`, `test_ash_offering_trait.gd`,
`test_tidal_corsair_trait.gd`), `test_bloodscent_graft.gd`, and `test_shield_wall_trait.gd`.
Ordinal assertions such as `test_warped_damage.gd` should survive unchanged.

Follow the existing A/B-two-resolvers pattern built on `Tests/unit/helpers/test_factory.gd`.

Two new properties get their own tests:

- **Placement.** A 2x modifier against a defended target yields strictly more than 2x
  damage.
- **Freshness.** Two damage resolutions in one action each build their own modifier:
  consume a contributing condition between them and the second lands lower. This is the
  property Phase 3's repeat and cascade mechanics rest on.

### 6. Documentation

- `Concept_Document.md` 1.1.3 — correct the composition law wording. It currently reads
  "within a champion's kit, effects add into one factor; across kits, effects form
  separate factors that multiply", which describes character-keyed grouping and is not
  what the code does. State that grouping is by mechanic, that character identity never
  enters the math, and that collection is still the power fantasy because more kits means
  more distinct mechanics in play — not because additional bodies multiply. Do **not**
  replace it with a new general rule about what adds; that stays open until the content is
  redesigned.
- `Concept_Document.md` 3.2.1 — move `Combined_Modifier` onto `Caster_Scaled` in the
  formula block and drop "it is **not yet implemented**".
- `Technical_Design_Document.md` 7.4 — currently documents the fragmented scheme in
  detail, including the "application point is a property of the source" rule that this
  phase removes. Rewrite, and add a section 15 entry.
- `Plan_Blowout_Alignment.md` — update Status.

## Verification

- GUT headless, full suite green:
  ```
  /home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64 \
    --headless -s addons/gut/gut_cmdln.gd \
    -gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd -gexit
  ```
- `gdlint Scripts/` clean.
- Re-run `Scripts/Debug/blowout_calibration.gd` and confirm shipped damage matches its
  aggregate-placement column. The harness already tabulates both placements, so it is the
  direct check that step 2 landed on the right side of the mitigation ratio.

## Watch for

- Character identity must not re-enter the calculation. Statuses carry a `source_ID` and it
  is tempting to key on it; that is the design this phase explicitly rejected.
- The modifier must stay constructed per resolution. Any caching that survives a single
  damage resolution breaks Phase 3.
- Encounter tuning drifts the moment placement moves. That is expected and Phase 7 carries
  the retune — do not patch individual encounters in this phase.
- No new content. No buffs, skills, or traits are added here; the phase only re-homes what
  exists.
