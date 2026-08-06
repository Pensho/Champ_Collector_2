# Plan: Itemization Channels

Spawned by `Plan_Blowout_Alignment.md` Phase 6, which asks two questions: are affixes
(`Concept_Document.md` 3.3.1) and reagents (3.3.3) factor sources, and does gear grow channel 1
only — keeping base attributes tame per 1.1.4 — or do specific affixes contribute factors, and what
does that do to the power curve across a full collection.

## Status

Not started.

## Context

### What the census found

Gear today is purely additive attribute rolls. There is no affix system: `affix`, `prefix`, and
`suffix` appear nowhere in `Scripts/`, `Data/`, or `Tests/`. `EquipmentPreset.Setup()`
(`Scripts/Gear/equipment_preset.gd:26-34`) rolls `rarity` times, each roll adding
`ITEM_ATTRIBUTE_PER_RARITY = 5` to a random attribute from the slot's pool; `Equipment.Upgrade()`
(`Scripts/Gear/equipment.gd:55-65`) adds `3 + rarity` to an attribute the item already has, capped
at `MAX_ITEM_LEVEL = 10`. Those attributes reach combat through
`Character.GetEquipmentBonus()` → `GetTotalAttributes()` (`Scripts/Character/character.gd:93-116`)
and nowhere else. **Gear has no hook into `CombinedDamageModifier` at all.**

Reagents are almost as one-sided. Of the 82 reagent resources in `Data/Reagents/`, exactly one
family reaches the combined modifier: Fractured Idol, whose `Health_Cost_Damage_Bonus` effect
(`Scripts/Battle/battle_resolver.gd:440-451`) calls `AggregateDamageMultipliers` into
`_damage_dealt_bonus`, read back as the single shared bucket `&"reagent_damage_bonus"` in
`_ContributePersistentCasterFactors` (`battle_resolver.gd:682-695`). Every other effect kind is
channel 1 (Tinctures, heals, attribute buffs) or utility. Chaotic Blessing rolls from
`ReagentResolver.ATTRIBUTE_BUFFS` (`Scripts/Battle/reagent_resolver.gd:15-24`), which holds eight
attribute buffs and no `DamageMultiplier` type, so it is channel 1 without qualification.

The two roles built around reagents contribute almost nothing to the burst channels.
`Scripts/Debug/kit_contribution_manifest.gd` records every Alchemist entry at magnitude 0.0 (its
passive Enabler-classed, its zone Enabler-classed, its debuff channel 1), and every Sorcerer entry
at 0.0 except Cataclysmic Surge's `Warped` bucket at 0.30. The Sorcerer's `Reagent_Consumed` hook —
the strongest reagent-to-kit coupling in the game — is not recorded in the manifest at all, because
it produces potency rather than damage.

### The constraint the phase is squeezed between

`Concept_Document.md` 1.1.4 requires base attribute values to stay tame: growth belongs in the
combined modifier and cascade channels, and inflating base attributes to chase the pillar breaks
fodder tuning and Health-bar readability. Gear is the long-term progression channel and is named in
1.1.3 as a channel 1 input, so it pushes directly against that rule at collection scale.

From the other side, 1.1.6's rejection test says a mechanic whose best case is a linear improvement
over not having it does not serve the pillar. A flat "+8% Attack" affix fails that test as written.

The resolution is not to split the difference but to accept that gear is deliberately the linear
channel and to bound how far it goes, while the *conditional* multiplicative content lives in kits
and reagently-gated role mechanics. That is what the decisions below encode.

### What Phase 5 requires of any new factor

The `C(20,3) = 1140`-team sweep found the roster's combined-modifier-product distribution at median
1.40x, 90th percentile 2.80x, ceiling 5.60x against a 26x target — and the ceiling is a *single*
pairing (Tidal Corsair's Wrangle the Sea composed with Tactician's Daunting Strength grant)
repeated across every top-decile team. The finding is not that the roster is too weak; it is that
the roster has one detonating pair rather than a space of them. A factor available to every
champion regardless of kit lifts the median as much as the ceiling and makes the roster *less*
discriminating even while raising its numbers. This is the reason gear does not get a factor tier,
and the reason the Sorcerer and Alchemist reworks below are shaped to compose with each other
under distinct keys.

### Decisions settled with the plan owner before this plan was written

1. **Gear feeds channel 1 only, with a Relic-rarity exception.** Relic rarity's unique effect —
   already specified in 3.3.1 as "a strong unique bonus and a downside" — is the single sanctioned
   place a gear-sourced factor may live, audited per Relic rather than opened as a general affix
   tier.
2. **Reagents are channel 1 effects only**, with the existing Fractured Idol exception kept rather
   than reworked.
3. **The Sorcerer's reagent payoff becomes channel 3**: consuming a reagent makes the Sorcerer's
   next skill repeat at a fraction of its damage (roughly 50%, tuned later).
4. **The Alchemist gains a channel 2 factor, team-wide, under its own bucket key**: when an ally
   consumes a reagent, the team gains a damage factor keyed to the Alchemist's mechanic. A distinct
   key from the Sorcerer's, so the two multiply rather than add — a second distinct ceiling pairing,
   which is precisely what the Phase 5 sweep found the roster lacks.

## Phases

### Phase 1 — Channel census for reagents and gear

Tag every reagent family in `Concept_Document.md` 3.3.3 and every gear mechanism in 3.3.1 with the
bracket vocabulary Phase 2 of the master plan established for statuses (`[Channel 1]`,
`[Channel 2]`, `[Channel 3]`, `[Enabler]`), inline in the document exactly as 3.2.3 does.

The census above supplies the expected verdicts: Tinctures, Restorative Draught, Chaotic Blessing,
and the Alchemist brew pool are channel 1; Purging Tonic, Thief's Regret, Zone-Dissolving Salts,
Second Wind Phial, and Rewinding Grit are enablers; Fractured Idol is the sanctioned channel 2
exception. Confirm each against the code rather than against this list — the effect dispatch is
`battle_resolver.gd:407-469`, one `match` arm per `ReagentData.EffectKind`.

Each enabler verdict is held to 1.1.6's collapse test: removing the reagent has to make the fight go
materially differently, not merely be useful to have. A family that fails the collapse test is
**recorded as a finding, not reworked into a damage source** — the master plan's "do not convert
enablers" guardrail applies here unchanged, and a reagent catalog where every entry touches damage
carries fewer decisions, not more.

Also record, without fixing: the deferred reagent families listed in Technical Design Document 6.1
(Barrier Stone, Deathward Charm, Chant Fragment, Notarized Seal, Wayfarer's Draught) are described
in 3.3.3 but not implemented, and 6.1's deferred list is itself stale about the brew pool, which has
shipped.

Files: `Documents/Concept_Document.md` 3.3.1 and 3.3.3. No code.

### Phase 2 — Write the gear verdict and size the collection power curve

Write decision (1) into 3.3.1 as a stated rule rather than an implication: gear feeds the scaled
attribute sum; no affix contributes to `CombinedDamageModifier`; a Relic's unique effect may, and
each such Relic must be shown to pass 1.1.6 and to be a *conditional* factor rather than an
always-on one. An always-on Relic factor is a flat multiplier on every hit the owner ever throws,
which is the median-lifting shape the Context section rules out.

Then size the linear channel, because "channel 1 only" is a bound on kind, not on magnitude. Use
`Scripts/Debug/blowout_calibration.gd`'s `ContrastRatioForFactors` to compute the scaled aggregate
of a fully-geared, fully-upgraded four-slot Legendary loadout against an unequipped champion of the
same preset, and record the ratio in this plan's Status the way the kit sweep figures are recorded
in `Plan_Channel_Population_Rework.md`. Two things to judge it against: whether fodder encounters
tuned against ungeared champions survive it, and whether it keeps base attributes tame in 1.1.4's
sense.

Record as gaps rather than fixing here:

* `GameBalance.ITEM_TYPE_ATTRIBUTES` (`Scripts/game_balance.gd:29-59`) defines attribute pools for
  Weapon, Shield, and Boots only. Trinket is a core slot per 3.3.1 and rolls nothing —
  `EquipmentPreset.Setup()` silently produces an attribute-less item for it.
* Relic rarity rolls no attributes and has no unique-effect mechanism in code at all. Decision (1)
  gives Relics a design slot that the codebase cannot yet express; that is build-out work for
  `Plan_System_Buildout.md`, not this plan.
* Only three item presets ship (`Data/Item_Presets/`), so "the power curve across a full
  collection" is a projection from the roll formula, not a measurement of authored content. State
  it as such.

### Phase 3 — Sorcerer: reagent consumption as a channel 3 repeat

The largest piece of work here, and the one whose architecture cost is currently understated in two
places in the repository.

**The record is half-corrected already.** `Plan_Blowout_Alignment.md`'s `Coverage gaps` section
said repetition "is expressible today, through `CascadeEvent.instance_count`, with no further
architecture work"; that has been corrected in place when this plan was written. The
`Types.Cascade_Trigger` docstring (`Scripts/common_enums.gd:227-231`) still carries the same claim
more specifically — "`CascadeEvent.instance_count` already covers repetition (a repeated cast or a
count-driven detonation) with no enum change" — and is corrected by this phase, alongside the code
change that makes it false. The claim is true of the *count* and false of the *trigger*: the enum
ships `Status_Expired` and `Status_Landed` only, every `Post()` call site in the codebase lives in
`Scripts/Battle/status_effect_resolver.gd`, and nothing posts when a skill resolves, so a repeated
cast has no trigger to hang an instance count on.

Shape to implement:

* Add `Types.Cascade_Trigger.Skill_Resolved` and post a `CascadeEvent` from
  `BattleResolver.ResolveSkill` after the effect loop and before the existing `Drain()`
  (`battle_resolver.gd:189-192`), carrying caster, targets, and skill identity. Depth stamping and
  both termination bounds are already owned by `CascadeResolver.Post` and `_ResolveEvent`
  (`Scripts/Battle/cascade_resolver.gd:64-101`) — no new termination work, and the per-action
  `_fired_this_action` dedup already guarantees one trigger firing per originating action.
* `SorcererTrait` (`Scripts/Character/character_traits/CharacterSpecificTraits/sorcerer_trait.gd`)
  subscribes under its own `mechanic_key`, with `matches` gating on "this Sorcerer consumed a
  reagent since their last cast" and a callback that re-resolves the cast skill's damage at the
  repeat fraction. The consumed-a-reagent flag is set in the existing `OnReagentConsumed` hook
  (`sorcerer_trait.gd:73-76`) and cleared when the repeat fires.
* **Repeat damage only.** The callback re-runs `DamageEffect`s at the fraction and nothing else. A
  repeated `CastDebuff` would double-apply against the eight-status cap in 1.1.4 and re-post
  `Status_Landed`; a repeated zone effect would spend charges twice. This is the defect most likely
  to ship — write the test for it before the implementation.
* Each repeat instance assembles its own `CombinedDamageModifier` through the normal
  `DamageEffect.Resolve` path, which is what makes instance count multiply against channels 1 and 2
  rather than add to them (1.1.3's cascade definition).
* Decide, and state, whether `REAGENT_AMPLIFICATION` (`sorcerer_trait.gd:10-15`) survives alongside
  the repeat. It is a channel 1 potency bonus and harmless to keep; keeping it means the passive
  reads as "reagents make my consumables bigger *and* make my next skill repeat", which is a fuller
  expression of the Role's stated identity as the one that "excels at drawing power from reagents".
  If it is dropped, 3.1.3's Sorcerer entry needs rewriting rather than amending.

Adjacent, in scope because it sits on the same trait: `ResolveTraitDamage`
(`battle_resolver.gd:390-404`) constructs an empty `CombinedDamageModifier` at the call, so the
Instability Surge lands in no skill, ramp, or trait-resource bucket — the persistent caster factors
still reach it downstream, but the modifier the Surge carries is otherwise empty. The manifest
already flags this as a trap. Fix it or record it as a deliberate exclusion; do not leave it
undocumented after this phase touches the trait.

Guardrail: **do not uncap Arcane Instability.** 1.1.4 caps what accrues automatically, and the
master plan's Phase 5 note names this passive specifically.

### Phase 4 — Alchemist: team-wide channel 2 factor on reagent consumption

`BattleResolver.ResolveReagent` (`battle_resolver.gd:356-370`) already fires the `Reagent_Consumed`
trait hook, but only on the *consumer*. The Alchemist's factor triggers on any ally's consumption,
so this phase needs a broadcast rather than a consumer-side hook.

Deliver the factor as a `DamageMultiplier`-kind buff applied to allies.
`StatusEffectResolver.ConsumeDamageMultiplierFactors` (`status_effect_resolver.gd:163-174`) already
removes each such buff on the next damage resolution and contributes `(value - 1.0)` under a bucket
keyed by buff-type name — no new plumbing, and it composes with the Sorcerer's repeat automatically
because each repeat instance builds its own modifier. The cost is one slot against the eight-status
cap, and over-cap applications are denied outright rather than dropped silently; that is acceptable
and is the same trade every granted buff in the roster makes. The alternative — a persistent caster
factor tracked on the trait and contributed via `_ContributePersistentCasterFactors` — bypasses the
cap but adds a bespoke code path for one Role, and is not taken.

Two hard requirements on the key: it is the Alchemist's mechanic identity, never character identity
(1.1.3's composition law), and it must not be `&"reagent_damage_bonus"` — colliding with Fractured
Idol's shared bucket would make the two add where they should multiply.

`FreshBatchTrait` (`.../CharacterSpecificTraits/fresh_batch_trait.gd`) registers no
`_execution_steps` today — it is consumed only by `battle.gd:180-182` at combat start — so this is
the passive's first combat hook, and `Init` gains an `_execution_steps` entry alongside the existing
brew fields.

Retag both passives in `Concept_Document.md` 3.1.3 once the behavior lands: Fresh Batch moves off
`[Enabler]`, and Arcane Instability's `[Channel 1 + Channel 3]` tag becomes accurate for the first
time rather than aspirational.

### Phase 5 — Manifest, scorer, and the sweep re-run

Add the reworked Sorcerer and Alchemist contributions to `Scripts/Debug/kit_contribution_manifest.gd`
(bucket key, Legendary magnitude, stack cap, `Contribution_Class`, precondition, `file.gd:line`
citation) and re-run `Tests/manual/team_corpus_sweep.gd`, recording median, 90th percentile, and
ceiling in this plan's Status.

**The manifest has no reagent axis, and this phase must resolve that before the sweep means
anything.** Both new contributions are gated on a reagent being consumed; reagents are a
player-brought resource the scorer knows nothing about; so the manifest as it stands scores both as
zero and the sweep would report no change. Add a "reagent assumed available" precondition axis to
the manifest and to `Scripts/Debug/burst_reachability.gd` — modeling the assumption explicitly, the
way `granted_status` models an Enabler handing a factor to a teammate — so the phase can verify its
own central claim: that a Sorcerer plus an Alchemist forms a second distinct ceiling pairing, not
gated on Tidal Corsair. Recording the blind spot instead of closing it is the fallback, and it
leaves the claim unverified.

Judge the result against the discrimination requirement, not the ceiling alone. The target outcome
is a second pairing in the top decile, distinct from Tidal Corsair plus Tactician — a median that
moves as much as the ceiling is a failure even if the ceiling number looks good.

### Phase 6 — Documentation and hand-back

* `Concept_Document.md`: 3.1.3 (Sorcerer, Alchemist), 3.2.4.2 where skill text changes, and 3.3.1 /
  3.3.3 with Phase 1 and 2's tags and the gear rule.
* `Technical_Design_Document.md`: a section for the `Skill_Resolved` trigger and the repeat path
  alongside 7.8's cascade architecture, and the Alchemist factor alongside 7.4's keying rules;
  update 6.1's stale deferred-reagent list; add the section 15 entry per `Plans/README.md`.
* `Plan_Blowout_Alignment.md`: mark Phase 6 done in Status with the sweep figures, strike the
  `Coverage gaps` correction note added when this plan was written (the trigger now exists), and
  move any coverage gap this plan found (Relic unique effects having no code mechanism, the Trinket
  attribute pool, any reagent family failing Phase 1's collapse test) into the gaps list.
* Delete this file per the retention rule in `Plans/README.md` once its content has landed in the
  living documents, and remove its line from `Plans/README.md`.

## Watch for

* **A discriminating roster, not a high-scoring one.** Re-check the median on every change, not
  only the ceiling. Carried from `Plan_Channel_Population_Rework.md`, and the reason gear gets no
  factor tier.
* **Do not convert enablers.** Most of the reagent catalog is correctly non-damage and stays that
  way; Phase 1 records collapse-test failures rather than reworking them.
* **Do not uncap Arcane Instability**, Momentum, or Steel and Sea.
* **Enemies never use reagents** (3.3.3). A reagent-gated channel 2/3 factor is a player-only
  asymmetry — acceptable, but the master plan's Phase 7 boss Health retune must then assume
  reagents are in play, or it will tune against a burst ceiling the player can exceed.
* **Reagent effects scale with rarity only, never with the consumer's attributes** (3.3.3;
  `Scripts/Battle/reagent_data.gd:3-6` deliberately carries no attribute hook). The Sorcerer repeat
  scales with the *skill*, not with the reagent, so it does not breach this — say so explicitly in
  the documentation, because it looks like it does.
* **Potency modifiers stack additively on one consumption** (3.3.3). If `REAGENT_AMPLIFICATION`
  survives Phase 3, it stays additive with the Catalyst buff and Alchemist brew potency.
* **Overlap with `Plan_Channel_Population_Rework.md` Phase 2**, which also populates channel 3
  through repetition (modeled on Quarantine Breach). Whichever plan runs first owns the
  `Skill_Resolved` trigger and its `Post()` call site; the second consumes it. Two separate repeat
  architectures must not land.
* Spell words out in full in identifiers and prose, per the naming convention.

## Verification

* The GUT suite green (see the `run-tests` skill) and `gdlint Scripts/` clean.
* New unit tests written alongside each code phase, following `Tests/unit/helpers/test_factory.gd`:
  * a repeat fires exactly once per reagent consumption, and is bounded by
    `MAX_CASCADE_DEPTH` / `MAX_CASCADE_INSTANCES_PER_ACTION`;
  * a repeat re-runs damage only — a repeated skill that applies a debuff applies it once, not
    twice, and spends no second zone charge;
  * the Alchemist factor lands under its own bucket key and multiplies against the Sorcerer's
    contribution rather than adding to it;
  * the Alchemist factor is not keyed to `&"reagent_damage_bonus"`, verified against a Fractured
    Idol consumption in the same resolution.
* Existing suites still green, in particular `test_sorcerer_trait.gd`, `test_fresh_batch_trait.gd`,
  `test_reagent_resolution.gd`, `test_cascade_resolver.gd`, and
  `test_combined_damage_modifier_resolution.gd`.
* `Tests/manual/team_corpus_sweep.gd` re-run after Phase 5, with median, 90th percentile, and
  ceiling recorded in Status, plus whether a second distinct top-decile pairing appeared.
* The Phase 2 full-collection gear ratio from `blowout_calibration.gd` recorded in Status.
