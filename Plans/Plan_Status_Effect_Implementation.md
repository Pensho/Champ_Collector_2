# Plan: Status Effect Implementation

Implement the full status effect catalog from `Concept_Document.md` 3.2.3 —
turn bar effects (3.2.3.1) and common buffs/debuffs (3.2.3.2) — as
`StatusEffectData` resources with the resolver behaviors they need, plus a
placeholder icon generator so every effect is visually represented from day
one. Status effects have no dependency on the skills that will eventually
deliver them: `BattleResolver.ApplyBuff` / `ApplyDebuff` apply effects from
templates directly, and existing skills plus seeded resolvers can exercise
every trigger in tests. `Plan_Skill_Implementation.md` depends on this plan;
nothing here depends on it.

## Status

Batches 0, 1, 2, and 3 done. Implemented: 42 of the catalog's ~50 effects — the
original 7 (Empower, Fortify, Daunting Strength, Phalanx Guard, Burning,
Enfeeble, Expose Weakness), batch 1's 18 (debuffs: Suppress, Slow, Blind,
Unravel, Confound, Exposed Facet, Cracked Facet, Sequence Lock; buffs: Attune,
Haste, True Aim, Clarity, Insight, Vigor, Keen Edge, Lethal Precision, Frenzy,
Opportunist), and batch 2's 6 (debuffs: Bleed, Plague, Blight, Temporal Leak;
buffs: Regeneration, Exhert). `StatusEffectData` now carries `attribute_modifiers`
(attribute -> sign) instead of a single `affected_attribute`, plus seven new
`MagnitudeKind` values (`AttributePercentagePointAdd`,
`MaxHealthAttributePercent`, `PerTargetDebuffDamagePercent`,
`AttackerCritChanceBonus`, `AttackerCritDamageBonus`,
`CasterAttributeSnapshotPercent`, `IncomingHealReduction`,
`TurnBarMovementDamagePercent`) and one new field independent of
`magnitude_kind` (`self_tick_max_health_cost_percent`, for Exhert) — see
`Technical_Design_Document.md` section 6.1. The placeholder icon generator
(`Scripts/Debug/generate_placeholder_icons.gd`) gained a `STATUS_EFFECT_TABLE`
that batches 3-4 should keep extending.

Batch 2 landed `BattleResolver._ApplyHeal` as the single health-gain
application point (now returning the amount actually gained instead of void),
Blight's healing reduction hooked into it, and a generic
`CasterAttributeSnapshotPercent` self-tick path shared by Bleed and Plague.
Temporal Leak went live rather than dormant (user decision during batch 2):
`TurnBar.Update()` now returns the fraction of the bar moved that frame, and
`Battle.AdvanceTurnBar()` forwards it to the new
`BattleResolver.AccumulateTurnBarMovement()` entry point, which owns all the
actual accumulation/threshold/damage logic so it stays headless-testable.
`CombatResult.Kind.Burning_Tick` was renamed to `Debuff_Tick` since Bleed and
Plague now share it. `gdlintrc`'s `max-public-methods` was bumped from 21 to
22 for the new `AccumulateTurnBarMovement` entry point (user decision).

Dormant note beyond the exclusions below: Slow and Haste's Speed modifier
applies to combat calculations (e.g. Speed-scaling damage) but has no live
effect on turn-bar rate yet — `turn_bar.gd` reads only base + gear Speed, not
buffed combat attributes. Wiring that up is turn-bar-effects territory
(batch 4), not part of this plan's batch 1 scope.

Batch 3 landed the 9 buffs and 2 debuffs whose defining trait is a trigger rather
than a steady per-turn magnitude: Premonition, Deathward, Aegis, Rehearsed
(consume-on-trigger, reusing `RemoveBuff()` as their consume step), Barrier (a
per-instance absorb pool, replace-only-if-larger), Mirror Coat (reflects a landed
debuff back at its source, rolled again), Overflow (expiry-triggered AoE damage),
Wanderlust (a random primary attribute boosted each self-tick, transient), Mana
Burn (cast-triggered rather than tick-triggered self-damage), and Luck/Hexed (a
shared double-roll helper wrapping every existing roll site). Two catalog numbers
had no specified value and were confirmed with the user: Overflow and Mana Burn
both scale at 30% of the relevant Mysticism, matching Plague's existing
convention. Rehearsed turned out to have no missing dependency despite being
grouped with the dormant exclusions below — it landed fully live. If a character
holds Luck and Hexed simultaneously, they cancel out to a single normal roll
(user decision). `gdlintrc`'s `max-file-lines` was added at 1150 (`battle_resolver.gd`
crossed the default 1000-line cap) — same category of decision as batch 2's
`max-public-methods` bump.

Batch 4 (turn-bar/rule effects) remains and needs its own implementation pass.

## Scope and exclusions

In scope: every effect in Concept Document 3.2.3 not yet implemented, the
`StatusEffectData` / registry / enum plumbing they need, and the placeholder
icon generator (which also serves skills and passives later).

Effects that cannot be fully live yet land **dormant** — implemented, tested
through template application, but with their missing half explicitly deferred:

- **Catalyst** — modifies reagent consumption; inert until the reagent plans
  land.
- **Sanction** — the attribute-reduction machinery lands here; its magnitude
  source (the Emissary's Infraction tally) arrives with the Emissary in
  `Plan_Skill_Implementation.md`.
- **Spotlight** — the damage-reduction half lands here; the targeting-weight
  half needs the enemy-AI targeting work in `Plan_Skill_Implementation.md`.

Rehearsed was originally grouped here too, but turned out to have no missing
dependency (unlike the three above) and landed fully live in batch 3.

## Approach (confirmed decisions)

- One `.tres` per effect under `Data/Status_Effects/`, one
  `StatusEffectRegistry` entry, enum entries in `Scripts/common_enums.gd`
  (`Buff_Type` / `Debuff_Type`). New behaviors are new `MagnitudeKind` values
  or application sites on `StatusEffectData` — never per-effect match arms
  (that is the hardcoding `Technical_Design_Document.md` 15.8 removed).
- Numbers come from the catalog verbatim; where the catalog says an effect
  stacks (Burning, Haste) the resource says `stackable`, everything else
  refreshes per the existing overwrite rule.
- Tests alongside every batch (`Tests/unit/`, patterns:
  `test_status_effect_registry.gd`, `test_status_effect_ticks.gd`,
  `test_burning_damage.gd`), suite green, `gdlint Scripts/` clean per batch.
- The registry test that walks every enum entry should be extended to assert
  catalog completeness: every `Buff_Type`/`Debuff_Type` resolves to a resource
  with an icon.

## Batches

### Batch 0 — placeholder icon generator

A sibling of `Scripts/Debug/generate_placeholder_textures.gd` following the
same recipe: `Scripts/Debug/generate_placeholder_icons.gd`, a `@tool`
EditorScript with a data-driven table (one row per icon: folder, base name,
size, color), flat-color PNG output, skip-existing so real art is never
clobbered, an `OVERWRITE` constant, headless-runnable. Output follows the
existing icon convention (`Assets/Champ_Collector/Icons/Abilities/<Skill_Name>/`
per current skill `icon_path` values): status effect icons under
`Assets/Champ_Collector/Icons/Status_Effects/`, skill placeholders into the
`Abilities/` layout. Color language: buffs in a green/blue family,
debuffs in a red/purple family, one distinct hue per effect. Rows for the 7
existing effects land immediately; each batch below adds its rows and wires
the texture into its `StatusEffectData.icon`. `Plan_Skill_Implementation.md`
later adds skill and passive rows to the same table.

### Batch 1 — attribute and stat modifiers

Infrastructure: `StatusEffectData` today holds a single
`affected_attribute` — extend it to carry multiple attribute modifiers
(Frenzy, Rush, Exhert, Sanction all touch several attributes, with mixed
signs), and add an additive percentage-point kind for the crit stats (Keen
Edge's "+15 percentage points" is not a percent-of-attribute).

- Debuffs: Suppress, Slow, Blind, Unravel, Confound, Exposed Facet, Cracked
  Facet, Sequence Lock (blocks Speed changes — a modifier rule, checked where
  Speed-affecting statuses apply).
- Buffs: Attune, Haste (stackable), True Aim, Clarity, Insight, Vigor (max
  Health — mind the effective-HP multiplier when current health is set), Keen
  Edge, Lethal Precision, Frenzy, Opportunist (+10% damage per debuff on the
  target, resolved in `_ResolveDamage`).

### Batch 2 — ticks, healing hook, and damage over time

Infrastructure: a health-gain application in the resolver (`_ApplyHealthGain`
mirroring `_ApplyHealthLoss`, with its own `CombatResult` kind). Regeneration
is its first consumer; `Plan_Skill_Implementation.md`'s heal skills reuse it.
Blight hooks that same application point, so it lands live here, not dormant.

- Debuffs: Bleed (start-of-turn tick scaling with the caster's Attack,
  snapshotted at application), Plague (per-turn tick + spread to a random
  other enemy on expiry), Blight (halves healing received), Temporal Leak
  (damage per 10% of turn-bar movement).
- Buffs: Regeneration (4% max Health at turn start), Exhert (batch-1
  multi-attribute modifier + 5% max-Health loss per own turn).

### Batch 3 — consumed and event-triggered effects

Infrastructure: consume-on-trigger semantics (a status that removes itself
when its trigger fires) and a central double-roll helper so Hexed/Luck wrap
every roll site (crit, resist, damage variance) once instead of per-site
duplication.

- Buffs: Premonition (next attack misses), Deathward (fatal hit leaves 1
  Health), Aegis (blocks next debuff), Mirror Coat (landed debuff copied back
  to the attacker, resisted normally), Barrier (absorbs damage before Health;
  replace-only-if-larger, never stacks), Luck, Rehearsed (next non-basic skill
  skips cooldown — dormant half, see exclusions), Overflow (expiry deals
  Mysticism-scaled damage to all enemies), Wanderlust (turn-start random stat
  bonus until next turn).
- Debuffs: Mana Burn (damage on non-basic skill cast), Hexed.

### Batch 4 — turn-bar and rule-modifying effects

The effects that constrain resolver behavior rather than modify numbers:
turn-bar reactions and rule switches, several touching the turn state machine.

- Debuffs: Dead Weight (3% turn-bar loss on damage taken), Stun (skip next
  turn), Fatigue (cooldowns do not tick), Refracted (single-target skills
  retarget randomly, allies included), Warped (damage scaling forced through
  Mysticism — the catalog leaves broader forcing undecided; implement damage
  only and flag the open question), Signed Writ (cannot resist debuffs),
  Severance (cannot gain new buffs), Sanction (dormant, see exclusions),
  Anchor (immune to turn-bar pushes).
- Buffs: Steadfast (cannot be moved backward), Slipstream (passes through
  enemy zones untriggered), Resonance (ally zones affect at double effect),
  Battle Orders (allies gain 5% turn bar when holder takes damage), Rush
  (batch-1 modifiers + expiry applies an unresistable Stun, ordered after
  other expiries per the catalog), Spotlight (damage-reduction half; dormant
  targeting half), Catalyst (dormant).

## Watch for

- The status-effect cap (`MAX_STATUS_EFFECTS` = 8) with stacking effects
  (Haste, Burning) — test behavior at the cap.
- Statuses are applied through both `ApplyBuff`/`ApplyDebuff` (template path)
  and `_CastBuff`/`_CastDebuff` (skill path) — new behaviors must work
  through both.
- Zone-applied debuffs come from the placing skill's `debuffs` dictionary —
  new debuffs should work from zones without extra wiring; add one zone test
  (the Lava-zone Burning test is the pattern).
- Effect magnitudes and rules live in the resource, per-instance values in
  `StatusEffects.Buff`/`Debuff.value` — snapshot-at-application effects
  (Bleed's caster Attack, Sanction's tally read) follow the Phalanx Guard
  per-instance precedent.
- The extension of `StatusEffectData` to multiple attributes must not break
  the 7 existing single-attribute resources — migrate them in batch 1 and keep
  `test_status_effect_registry.gd` green.
- The turn state machine effects (Stun, Fatigue, Refracted) touch
  `Battle`/turn handling beyond the resolver — keep the logic headless and
  testable, per the `BattleResolver` seam rule.

## Documentation

- Update `Technical_Design_Document.md` section 6.1 when `StatusEffectData`
  gains fields or magnitude kinds, and section 7.4 for new application sites.
- Strike each effect's "(Not yet implemented)" marker in Concept Document
  3.2.3 as it lands; note dormant halves there explicitly (e.g. Catalyst,
  Spotlight).
- On completion: run `/review-implementation`, update the documents above,
  then delete this file per the `Plans/README.md` retention rule.
