# Plan: Role Kit Rework for the Blowout Pillar

Supersedes `Documents/Plans/Plan_Channel_Population_Rework.md`. This is the authoring
counterpart to `Plan_Blowout_Alignment.md`, whose scope guard explicitly excludes new content
and hands it to a build-out plan that was never spawned.

## Status

**Framework correction, applied before Batch 2 design.** `Role_Kit_Design.md`'s kit contract had
pointed every Role at the 30-50x team figure rather than a per-Role one, and forbade an Enabler
primary identity that `Concept_Document.md` 1.1.3 permits. Both are corrected there (§1, §1.2, §4,
§5, §8, §9.2-§9.4) and in this plan's own contract restatement. **Batch 1's five settled kits were
designed under the wrong reading and should be re-read against the corrected contract** before
Phase 6 — Sorcerer, Bloodmage and Appraiser are not yet implemented, so that re-read is cheap for
three of the five.

Phase 0 done. Phase 1 drafted, awaiting sign-off (see below) before Phase 2 starts. Phase 2 in
progress: Plague Doctor and Herald of the Loom implemented; Sorcerer, Bloodmage, and Appraiser
settled and recorded in `Role_Kit_Design.md` §9.3 / §9.4 / §9.5, not yet implemented. Herald of the
Loom's implementation (`weft_and_warp_trait.gd`) added the batch's second and third pieces of new
Channel 3 plumbing beyond §11's original scope: `Combat_Event.Cascade_Instance_Resolved` (a
per-real-instance broadcast off `CascadeResolver._ResolveEvent`'s own loop) and
`CascadeResolver.SubscribeInstanceModifier` (lets a subscriber amplify an already-matched
listener's instance count) — both exercised directly in `Tests/unit/test_cascade_resolution.gd`
ahead of the Herald trait itself, per the plan's own tier-1-before-tier-3 ordering. Two Roles left
in Phase 2. The scorer gaps blocking the remaining two Channel 3 kits are consolidated in §11 and
are the batch's first implementation work; the crit scorer's own gap closed in `e3d39bd`, leaving
only the above-100 Critical Chance clamp that Appraiser's passive needs (§9.5). The framework
question that governed Batch 2's designs — whether Enabler may be a Role-level identity, raised by
Appraiser's kit claiming no bucket key at all — is **settled** (§8): Enabler **is** permitted as a
primary identity, the contract admits crit-path contribution, and it gained a second declared axis,
**contribution direction** (self-facing or exported, §1.1), with a per-Role allocation and a
10-of-20-exported roster target in §5. A Sustain or Control purpose is now explicitly discharged
through Enabler-tagged skills authored as kit content (§1.2, `Concept_Document.md` 3.1.3). Also settled: **the sweep is a sanity check on one calculable factor, not a design gate**
(`Role_Kit_Design.md` §4).

Phase 3 (Batch 2) design started ahead of Phase 2's remaining implementation, which the tier-3 loop
permits — settling a kit does not require implementing it in the same sitting. **Jester settled
(§9.6)**, the first kit designed under the corrected contract and the first to declare an **Enabler**
primary identity with no damage contribution at all. It carries two roster-wide mechanics changes
its export depends on: Luck and Hexed widen from the crit and resist rolls to every chance roll
except damage variance, and the debuff-resist contest's random band widens from 0.95-1.0 to
0.85-1.0 (`Concept_Document.md` 3.2.1 #3) — inside the old band a reroll was worth about 2
percentage points of the stat, leaving Hexed's resistance clause nearly inert. Burning's tick
becomes a rolled 2-10% of max Health roster-wide. **Emissary settled (§9.7)** as an adaptation —
only Levied Sanction's payload changes: Sanction gains a snapshotted per-Infraction damage
multiplier every attacker on the team reads (1.72x at the tally cap), and Signed Writ credits an
Infraction per buff it strips to zero. That closes route A and discharges the standing
exported-Channel-2 requirement the coverage review left open. **Cultist settled (§9.8)**, also an
adaptation: the passive's flat per-cast bonus stays flat (an automatic ramp is a timer, not a
decision) and gains Devotion, a permanent damage bucket per Vessel that dies, while the basic reads
the Vessel's half-Health threshold. Route E closes. **Chronophage settled (§9.9)** as route B's
exported cascade anchor, fielding no damage factor of its own: Time Tithe grants Borrowed Time to an
ally it boosts *alone* on the turn bar, and that ally's next skill resolves once more at 30-60%.
The threshold-crossing `Cascade_Trigger` §5 proposed is **not** authored — counting section
boundaries is arithmetic a player cannot read off the screen. Two roster-wide notes came out of
settling it: §5's allocation predates the Enabler correction, so every unsettled row is now
explicitly a proposal at most; and §3's instance-count test is reworded to compare **total**
resolutions (an additional resolution is Channel 3 at any fixed count; Overflow fails because its
total is one, not because its count is fixed). **Architect settled (§9.10) and Batch 2's design is
complete** — the kit is kept as it ships (its finisher already meets the contract, its zone already
consumes charges against it), with one change: Expose Weakness's Defence reduction scales with the
charges spent, -30% at 5 up to -44% at 12. Phase 0 is what made that worth doing: with Defence
keeping its weight at burst scale, the debuff is a 1.16-1.25x factor for every attacker on the team,
and `Concept_Document.md` 3.2.3's claim that it was build-up pressure only is corrected in this
turn. Batch 2's five kits are settled; **none of Batch 2 is implemented yet**, and Batch 1 still has
Sorcerer, Bloodmage and Appraiser outstanding. Route C's second
anchor is now open rather than assigned: the Jester was Phase 1's proposal and is no longer a
candidate, and no unsettled Role is assumed into it. Phases 4-6 not started.

**Coverage review findings**, from a roster-wide read of all 20 Roles against the corrected contract.

* **Per-Role factors are bimodal within a kind** — instance counts 6.59-8.64x, bucket products split
  1.7-2.2x and 1.3-1.5x, almost nothing at the ~2x figure. `Role_Kit_Design.md` §4 gained a
  roster-level distribution target and the per-kind comparability rule; §1 gained the reading rule
  this review's own first pass got wrong (a declared identity claims one term of a team's product).
  Nothing retuned; the target exists to be measured against in Phases 3-6.
* **§9.1's Plague Doctor entry has no projected numbers** in any kind, the only implemented kit that
  cannot be placed in the distribution. Project Comorbidity as an instance count when Batch 1 closes.
* **Cross-kit Channel 2 is thin** — the Context shortfall Batch 1 did not close; Emissary's Sanction
  is the first exported bucket answering it (§9.7). Still the axis to check per batch,
  `Role_Kit_Design.md` §8.
* **`bonus_per_debuff_on_target` is identity-scoped, not a general hook.** It enumerates its debuff
  types at authoring time, so it reads nothing a later batch invents. Its single claimant (Cataclysm
  reading Warped) is the intended state, not to be expanded; debuff density runs through
  `bonus_per: {Target_Debuff_Count}`. §2, §3 and §6's route A updated, plus this plan's Context.
* **A long tail of the status catalog has no source in the game.** Settled posture: claiming an
  existing status is preferred to authoring a new one. Inventory in `Role_Kit_Design.md` §10.1,
  checked in the per-batch loop's tier 3.
* **Overflow is not Channel 3, and Channel 3's corpus was one entry, not three.** Overflow posts a
  real cascade instance but always exactly one, so it multiplies nothing — retagged Channel 1, with
  the general test in `Role_Kit_Design.md` §3. Plague's expiry spread, the other entry Context
  counted, no longer exists. Stale references cleaned from `Concept_Document.md`,
  `Technical_Design_Document.md` and this plan's Context.

**Post-Herald sweep** (`Tests/manual/team_corpus_sweep.gd`, re-run after Herald of the Loom
landed). Combined-modifier-product distribution is unchanged from the post-Defence baseline
(median 1.36x, 90th percentile 2.80x, ceiling 7.22x) — expected, since Cut the Cloth's Channel 3
contribution lands in `combined_contrast_ratio`, not the bucket product. The ceiling *contrast*
team is still Alchemist/Tactician/Tidal Corsair (9.39x). The top decile (114 teams) has fully
flipped: **every** top-decile team is now a Herald of the Loom/Cut the Cloth pairing
(9.64x-11.22x combined contrast ratio), having displaced Tidal Corsair+Tactician entirely from the
top of the ranking (still present in the roster, `tidal+tactician: true` confirms it's reachable,
just no longer top-decile). This opens the intended independent, non-Tidal-Corsair-routed ceiling
pairing the batch set out for — but the top decile's own **distinct-pairing count dropped from 7 to
1**, the opposite direction from the plan's own shape target (§6's "several independent team
combinations", "a populated top decile with distinct member pairs"). Cut the Cloth's per-Tension
curve is strong enough on its own (floor ~9.64x with *any* two teammates, uncoupled from what they
contribute) to swamp the ranking regardless of partner. Not a regression to fix inside this Role's
own batch — Sorcerer and Bloodmage still to come in Phase 2 are exactly what's meant to repopulate
the top decile with further distinct pairings — but worth flagging now rather than only at Phase 6:
if the shape doesn't diversify once Batch 1 completes, Cut the Cloth's curve (0.08 magnitude, 8 flat
instances) is the first thing to revisit, not a symptom of the framework.

**Phase 1 result.** `Documents/Role_Kit_Design.md` created, holding the kit contract, the
indirect-composition rule, the synergy grammar, Phase 0's re-derived targets, and the two pieces
of new design work: a channel identity allocation across all 20 Roles (4 Channel 3, 9 Channel 2, 7
Channel 1, no Role-level Enabler — up from ~1 real Role-driven Channel 3 anchor and one cross-kit
Channel 2 hook in the baseline), a contribution-direction allocation across the same 20 (10
exported, 10 self-facing), and a five-route pairing web (debuff density, cascade count, crit path,
stack consumption, Health threshold), each independent of Tidal Corsair's existing ceiling
pairing and of each other. Batch 1 (fixed by this plan) opens or partially opens four of the five
routes; batch composition for Phases 3-5 is proposed in the design doc's section 7, sequenced so
batch 2 closes every route batch 1 opened before batches 3-4 turn to bug fixes and the remaining
Enablers. **Stop here for review per the plan's own instruction — the allocation is the decision
everything downstream inherits.**

Per-phase progress is recorded here as it lands. Every batch records the sweep result it
produced — median, 90th percentile, ceiling, and the count of distinct pairings in the top
decile — so the roster's *shape* is trackable across the plan, not just its maximum.

**Phase 0 result.** `Skills.MitigatedDamageUnrounded` (`Scripts/Battle/skills.gd`) now takes
Defence's mitigation ratio against a fixed scale constant (`GameBalance.DEFENCE_SCALE_CONSTANT
= 100.0`) instead of the caster's own scaled aggregate — Defence keeps the same percentage
weight at burst scale as at basic-hit scale, restoring both boss-to-boss differentiation (1.82x
weakest-vs-toughest boss, unchanged from basic to burst) and `Defense_Ignore_Factor` as a burst
lever (a ~2x swing, up from under 2%). Side effect: the old "modifier on the aggregate is worth
nearly double the same modifier on final damage" mechanic (`Concept_Document.md` 1.1.4) is now
damage-equivalent — mitigation no longer scales with the aggregate — so the required aggregate
multiplier for the burst target rose from 26x to 50x (1.1.2 re-derived accordingly).
`Scripts/Debug/burst_reachability.gd` also gained `_ContributeGrantedAttributeBuffs`, crediting
fixed one-shot Channel-1 attribute grants (Empower, Attune, Rush, Fortify, Exhert) into a
candidate's scaled aggregate — previously invisible to the scorer, understating any team
carrying one of these grants (`kit_contribution_manifest.gd`'s new `granted_attribute_buff`
field on the five entries that carry one).

Post-Phase-0 baseline (`Tests/manual/team_corpus_sweep.gd`, re-run after both fixes): combined-
modifier-product median 1.62x, 90th percentile 2.80x, ceiling 7.22x (product is unaffected by
either Phase 0 fix — neither touches bucket contribution — so this matches the itemization-phase
figure already in place before Phase 0 started). Contrast-ratio ceiling (the figure comparable to
the 30-50x target) is now **9.39x**, the same Alchemist/Tactician/Tidal Corsair/Corsairs Reckoning
team as before. The top decile (114 teams) now spans **7 distinct caster-role/skill pairings**
(Tidal_Corsair/Corsairs Reckoning, Architect/Final Calculation, Bar_Brawler/Headbutt,
Cultist/Devour Blessing, Diviner/Ill Omen, Sorcerer/Cataclysmic Surge, Thief/Pierce weakness) —
already better-shaped than the single-pairing baseline this plan opened against, from work
landed in the itemization phase; Phase 0 itself didn't change this shape, only the contrast-ratio
scale it's measured on.

Findings carried forward from the two deleted plans (`Plan_Kit_Burst_Reachability.md`,
`Plan_Channel_Population_Rework.md`):

* **Reach already derives structurally from the granting effect's target**
  (`BurstReachability._GrantReachesCandidate`), not assumed reachable by every teammate — landed
  before this plan started; noted here so it isn't rediscovered.
* **Opportunist's `PerTargetDebuffDamagePercent` bonus keys to whatever debuff is present on the
  target** (`status_effect_resolver.gd:634`), not a fixed bucket — for a Sorcerer/Scholar/
  Tactician team this lands in the *same* bucket as Cataclysmic Surge's own Warped requirement
  and adds rather than multiplying. Worth knowing when authoring a kit meant to compose with
  Opportunist.
* **Two known implementation bugs, still unfixed:** Plague Doctor's Comorbidity
  (`status_effect_resolver.gd:70-71` hardcodes `tick_bonus_per_debuff = 0.0`, so the zone-trigger
  debuff path Miasma uses never reads it) moves into the Plague Doctor's batch (Phase 2, below;
  **fixed** — see Phase 2's own entry). Lancer's Reckless Momentum (`lancer_trait.gd`'s
  `OFFENSIVE_SKILL_NAMES` names a Thief skill, "Stab", instead of the Lancer's own "Lance Thrust",
  and no preset ever populates `defensive_skill_names`, so Momentum stacks accrue but only Disarm
  ever grants them and Phalanx Guard can never spend them) — fix it whenever Lancer's kit lands in
  a batch (Phase 3-5, composition set at the end of Phase 1).
* **Architecture gap, found in Plague Doctor's batch, deliberately not fixed yet:**
  `StatusEffects.Debuff` (`status_effects.gd`) carries dedicated fields for individual traits'
  rider data instead of one generic container — `repeats_per_distinct_debuff` (Comorbidity, this
  batch) and `has_weakness_rider`/`weakness_attribute`/`weakness_reduction` (Field of Study,
  Scholar's passive, already shipped) are the same shape twice. The fix: a single
  `trait_riders: Dictionary[StringName, Variant]` on `Debuff`, keyed by mechanic identity, plus
  generalizing `TraitSkillResult`'s equivalent bespoke field the same way so `CastDebuff`'s
  signature stops naming individual mechanics. Deferred rather than fixed inline because it
  touches Field of Study — a different Role's already-shipped, already-tested kit — outside this
  batch's scope; fix it opportunistically (a third trait needing a debuff rider is the natural
  trigger) or in a dedicated cleanup pass, not silently while authoring an unrelated Role.

## Context

`Concept_Document.md` 1.1 requires a solved boss to produce a burst of **30-50x** the champion's
own basic — a figure describing **a team at one resolution**, not any single Role. 1.1.2 sizes it
at a **50x multiplier on the scaled attribute aggregate** (26x before Phase 0's mitigation change
re-derived it), decomposed as roughly **two independent factors of ~2x per champion** across a
three-champion team. The per-champion figure is the one kits are designed against.

The roster does not come close, and the measurement already exists. The full 1140-team sweep
(`Tests/manual/team_corpus_sweep.gd`) recorded a combined-modifier-product distribution of
**median 1.40x, 90th percentile 2.80x, ceiling 5.60x** (7.22x after the itemization phase).
Worse than the shortfall is its shape: the ceiling is **one pairing** — Tidal Corsair's Wrangle
the Sea composed with Tactician's unconditionally granted Daunting Strength — repeated across
every top-decile team. No other pair in the roster reaches a second distinct Channel-2/3 key at
all. That is a single point of failure, not a discriminating tail, and it fails the pillar at
the *realisation* step before the blowout step is even reachable. (The Tactician's Plan passive
also grants Empower, a Channel-1 attribute buff — correctly absent from the *modifier product*,
since Channel 1 is a separate term in the damage formula, but it inflates the aggregate that
product multiplies. It makes that pairing stronger, not weaker.)

Three structural causes, all in the kits rather than the architecture:

* **Channel 3 is empty apart from one entry.** This bullet originally counted three — Overflow,
  Plague's expiry spread, and the Sorcerer's reagent-triggered repeat. Only the repeat was ever
  real: **Overflow is not Channel 3** (it yields exactly one instance, so it multiplies nothing —
  see `Role_Kit_Design.md` §3's instance-count test) and has no source in the game anyway, and
  **Plague's expiry spread no longer exists**, removed when the Plague Doctor's kit was reworked
  around debuff density. The repeat tops out at 5.57x, below the roster's own top-decile threshold.
  Against 23 Channel-1-tagged statuses, a co-equal pillar channel had a one-item corpus — a worse
  starting position than this plan opened by claiming, and the reason Batch 1's Channel 3 work is
  load-bearing rather than incremental.
* **Channel 2 has almost no cross-kit hooks.** Almost every Channel 2 bucket in the roster is a
  skill-name or trait-resource key that only its own caster's skill reads; the levers by which a
  kit hands a factor to a teammate's burst — a granted modifier-bearing status, a debuff every
  attacker reads, an open counter another kit feeds — are held by a handful of entries. Confound,
  Suppress, Unravel and the rest are Channel-1-only in practice, because nothing in the roster
  reads them. (This bullet originally named `bonus_per_debuff_on_target` as the main lever and its
  single declarer as the shortfall. That field is **identity-scoped by design** — see the grammar
  table above — so its one claimant is the intended state, not evidence of the gap. The gap itself
  is real and is restated above without it.)
* **Most kits are three Channel-1 skills**, and many are one-note — a single effect and nothing
  else. That is the exact shape 1.1.6's rejection test rejects.

The prior plan quantified four fixes against this sweep and found that spreading more hooks
(+0.00x) and giving the zero-contribution kits a factor (+0.00x) move nothing, *because
everything only ever composes with Tactician's lone grant*. Its own conclusion is the premise of
this plan: the roster needs genuinely new kits that compose with each other, not a retune of a
roster built the wrong way.

**Intended outcome:** all 20 Roles carry a declared channel identity and indirect composition
hooks, such that several *independent* team combinations reach the aggregate target through
different mechanics — so that finding one is a discovery, not the only option.

## Settled decisions

1. **Supersede, do not sequence.** `Plan_Channel_Population_Rework.md` is deleted; its Phases 2-3
   (populate Channel 3, retune magnitudes) are dropped as work on kits about to be replaced. Its
   Comorbidity bug fix moves into the Plague Doctor's batch — fixing a skill that may be replaced
   is premature.
2. **All 20 Roles, authored in batches.** Channel spread and the pairing web are only assessable
   roster-wide; the sweep re-runs between batches.
3. **Adaptation is the default posture; replacement is the exception.** A kit already meeting its
   contract is not redesigned to look reworked. Change the smallest thing that closes the gap: a
   one-note skill (a lone debuff, a lone buff, plain damage) gains a second dimension, a dead slot
   gets a new payload. A skill is replaced only when it scores zero and cannot be widened into its
   Role's declared identity — Levied Sanction's payload swap (§9.7) is the shape to copy, not a
   three-skill rewrite.
4. **The 3-skill cap stays** (`Concept_Document.md` 3.2.4), *but the basic is a design slot too.*
   A no-cooldown basic may carry a secondary rider — a low-chance debuff or buff application, a
   small heal (Fateful Glimpse is the existing precedent), a stack grant — and a **conditional**
   Channel 2 bucket key. Only an unconditional one is forbidden. Rule and rationale in
   `Role_Kit_Design.md` §1.2; this decision originally banned the key outright.
5. **Defence is being made to matter** (see Phase 0). The 1.1.4 rule that Defence stops mattering
   at burst scale is rejected on legibility grounds: Defence and defence-ignore are terms every
   RPG player arrives already understanding, and teaching them that the expectation is inverted
   costs more than making the expectation true.
6. **Design home:** a new living `Documents/Role_Kit_Design.md` carries the channel identity
   allocation and synergy ledger (successor to the archived `Plan_Role_Skill_Kits.md` claims
   ledger); settled kits are promoted into `Concept_Document.md` 3.2.4.2, which stays the
   authority.

## The design framework

Phase 1's output is `Role_Kit_Design.md`, which is authoritative for all of it and is what a batch
reads before designing: the per-Role kit contract and contribution direction (§1), indirect
composition (§2), the synergy grammar (§3), the per-Role ~2x figure and the constraints that bind
a design (§4), channel identity allocation (§5), and the pairing web (§6).

## Phases

### Phase 0 — Make Defence matter, then re-baseline

Gating: kit design happens once, against real targets.

* **Resolve the mitigation formula.** `Concept_Document.md` 1.1.4 states Defence stops mattering
  at burst scale (varying `Defense_Ignore_Factor` 1.0 → 0.0 moves a burst under 2%);
  `FeatureIdeas.md:46-47` frames the two directions. Take direction (b): change
  `Skills.MitigatedDamage` so Defence retains meaningful weight at burst magnitudes. The specific
  shape is a design question to settle with numbers in hand — produce two or three candidate
  shapes (a floor on Defence's share, a flat reduction term alongside the ratio, others) with
  each one's computed impact on 1.1.2's figures, and pick against the numbers. **Amend 1.1.4 and
  re-derive 1.1.2** — this is a section 1.1 change and it supersedes the existing bullet, which
  is now wrong.
* Re-derive every calibration figure through `Scripts/Debug/blowout_calibration.gd`: the 26x
  aggregate target, the 30-50x contrast band, boss Health implications. Record the new targets.
* Restore defence-ignore as a legitimate design lever in the framework once the formula holds.
* **Verify the scorer's base term.** Confirm whether `burst_reachability.gd` credits Channel-1
  grants (Empower from the Plan trait, Attune, Rush) in its base/contrast term, or scores only
  the modifier product. If Channel-1 grants are uncredited, the recorded contrast ratios
  understate the ceiling pairing and the baseline needs correcting before anything is measured
  against it.
* Re-run `Tests/manual/team_corpus_sweep.gd` and record the post-Defence baseline. Every later
  batch is measured against it.

*Deliberately not here:* the Comorbidity bug fix (`status_effect_resolver.gd:70-71` hardcodes
`tick_bonus_per_debuff = 0.0`, so Comorbidity is inert on Miasma) — it moves into the Plague
Doctor's batch, where the skill it affects is being redesigned anyway.

### Phase 1 — Write the design framework, then get sign-off

Create `Documents/Role_Kit_Design.md` holding: the kit contract, the indirect-composition rule,
the synergy grammar, the pairing web target, the binding constraints (all as above, with Phase
0's numbers) — plus the actual new work: a **channel identity allocation across all 20 Roles**
and a **sketched pairing web** naming which Roles are intended to detonate together and through
which mechanic. Design only; no skills, no code.

**Stop here for review.** The allocation is the decision everything downstream inherits.

### Phase 2 — Batch 1: establish independent pairings

Roles chosen to open ceiling pairings that do not route through Tidal Corsair, and to fix the
worst kits at the same time:

| Role | Why in batch 1 |
|---|---|
| **Plague Doctor** | The deepest identity claim in the roster: debuffs *and* Channel 3. Goes deep — a full-kit redesign around debuff density feeding cascade instance count, absorbing the Comorbidity fix. The anchor of the debuff-density pairing. |
| Herald of the Loom | No passive and no real kit exists in code — free design space, needs a passive authored |
| Sorcerer | Owns the repeat but tops out at 5.57x; the second cascade anchor, gated differently from the Plague Doctor's |
| Bloodmage | Scores zero contribution today; health-as-resource is an unused condition surface |
| Appraiser | The crit path is a multiplier axis independent of the combined modifier |

**Per-batch loop, in three cost tiers** (settled during batch 1's review — the point is to catch a
wrong assumption at the cheapest tier it can be caught at, not to front-load every Role's design
before any code lands):

1. **Plumbing, fixed opportunistically.** Bugs, missing schema (a new `Trait_Count_Source` or
   `Cascade_Trigger` value), or scorer blind spots (e.g. a mechanic the scorer structurally can't
   see yet) are fixed as soon as found, independent of batch boundaries — cheap and low-risk, and
   finding one early prevents baking the same wrong assumption into several Roles' designs. The
   open ones are consolidated in `Role_Kit_Design.md` §11: the scorer cannot represent any of batch
   1's Channel 3 payloads (fixed instance count of 1, no per-instance magnitude curve,
   reagent-specific gate framing, unscored sustained ticks, invisible zone-trigger damage). Three
   settled kits depend on it, so it is the batch's first implementation work, not a later cleanup.
2. **Coverage-level identity**, already carried by `Role_Kit_Design.md` §5-7 (channel identity,
   route sketches, batch composition) — cheap to revise since it's prose, not code. Before
   finalizing a batch's concrete numbers, sanity-check its hooks against the *other* batches'
   still-sketchy anchors for the same pairing-web route (does the shape the other side needs
   actually exist yet?) — a quick coherence check, not a full settle of those other Roles.
3. **Concrete kit design**, the expensive-to-revert tier once it becomes `.tres` + trait code +
   tests: brainstorm candidate kits (via the `brainstorm` skill, against `Role_Kit_Design.md`,
   checking §10.1's unclaimed-status inventory before any new status resource is proposed) →
   settle kits → compute the settled design's projected numbers against the scorer's own
   formula/methodology (`blowout_calibration.gd`'s approach) and check the Role's *own* factors
   against `Role_Kit_Design.md` §4's per-Role ~2x figure, never against the 30-50x team figure
   → **record the settled kit in `Role_Kit_Design.md` §9 (passive, all three skills,
   rationale, the projected numbers, and its claims) before writing any code** — a session that
   settles a kit is not required to also implement it in the same sitting; recording first means
   the next session (or a coverage review) can compare every settled kit's channel spread and
   route coverage without reading trait scripts → *then*, whenever implementation happens, author
   `.tres` under `Data/Character_Skill_Variants/`, plus new `Data/Status_Effects/` entries, trait
   code, and any new `Cascade_Trigger`/`Combat_Event` value and `Post()` site the design earns →
   add/update `Scripts/Debug/kit_contribution_manifest.gd` entries → tests → `./Tests/run_tests.sh`
   and `gdlint Scripts/` green → re-run the sweep and record the delta → mark the §9 entry
   implemented.

### Phases 3-5 — Batches 2, 3, 4

Remaining 15 Roles in three batches, grouped so each batch completes at least one intended
pairing rather than scattering half-pairs. Batch composition is fixed at the end of Phase 1, when
the pairing web exists. Same per-batch loop, same measurement.

### Phase 6 — Measure, promote, hand off

* Final sweep against Phase 0's re-derived target, reported as a distribution: median, 90th
  percentile, ceiling, **and the count of distinct pairings in the top decile**. The pass this plan
  is after is several distinct combinations reaching the band, with nothing far above it and
  nothing nowhere near it. That is a real result within the scorer's domain and a partial one
  overall — it does not decide whether a team is good, and the exported-window kits are absent from
  it by design (`Role_Kit_Design.md` §4, §8).
* Promote settled kits into `Concept_Document.md` 3.2.4.2 and updated passives into 3.1.3; add
  new status entries to 3.2.3.
* `Technical_Design_Document.md` gains entries for the mitigation change and any new effect type,
  `Cascade_Trigger` value, `MagnitudeKind`, or `Combat_Event` this plan added.
* Anything still short becomes a coverage gap for `Plan_System_Buildout.md`, which this plan
  spawns if it does not exist by then (its spawn condition has been met since Phase 5 of
  `Plan_Blowout_Alignment.md`).
* Run `/check-design` over the design documents.

## Files this touches

* **New:** `Documents/Role_Kit_Design.md`; new skill `.tres` under
  `Data/Character_Skill_Variants/{Attack,Support,Zone}_Skills/`; new `Data/Status_Effects/*.tres`.
* **Reworked:** existing skill `.tres` for all 20 Roles; trait scripts under
  `Scripts/Character/character_traits/CharacterSpecificTraits/` where a passive changes (Herald
  of the Loom needs one authored).
* **Phase 0 code:** `Skills.MitigatedDamage` and `Scripts/Debug/blowout_calibration.gd`;
  `Scripts/Battle/status_effect_resolver.gd` in the Plague Doctor batch.
* **Ledger:** `Scripts/Debug/kit_contribution_manifest.gd` — one entry per Role passive plus its
  three skills; the scorer reads this, not the design documents.
* **Docs:** `Concept_Document.md` 1.1.2 / 1.1.4 / 3.1.3 / 3.2.3 / 3.2.4.2,
  `Technical_Design_Document.md`, `FeatureIdeas.md` (close the Defence entry),
  `Documents/Plans/` deletions.
* **Possible code:** new `MagnitudeKind` values and their read sites; new `Types.Cascade_Trigger`
  values plus `Post()` call sites; new `Combat_Event` values for new trait hooks. All documented
  extension patterns.

## Verification

* `./Tests/run_tests.sh` green after every phase, including `test_burst_reachability*.gd` updated
  for new manifest entries. Phase 0's mitigation change needs its own damage-formula tests.
* `gdlint Scripts/` clean (scope: `Scripts/` only).
* `./Tests/run_tests.sh -gtest=res://Tests/manual/team_corpus_sweep.gd -gexit` after every batch,
  with median / 90th / ceiling / distinct-top-decile-pairings recorded in Status.
* Each new mechanic is checked against 1.1.6 in the batch's own review: it either multiplies with
  something else in the game, or it gates a burst that fails without it and survives the collapse
  test. A linear improvement is rejected regardless of theme fit.
* Every hook is checked for the indirect-composition rule: no skill names another Role, champion,
  or skill.
* Play verification of at least one completed pairing against a boss encounter before Phase 6.

## Watch for

* **A high-scoring roster is not the goal; a discriminating one is.** Check the median on every
  change, not only the ceiling — a change that lifts both equally has failed.
* **Check the spread of per-Role factors, not only each kit against its own contract.** Every kit can
  pass section 1 individually while the set of them is bimodal (`Role_Kit_Design.md` §4). Compare
  only within a kind, and read a low figure as a question about the Role's declared identity before
  reading it as a gap.
* **Do not railroad Roles into damage kits.** Every Role reaching for a burst-sized number is the
  failure this plan opened against, not the goal. A kit meeting §1's contract with one ~2x factor
  and a hook is finished; a kit whose honest identity is Enabler declares Enabler and fields no
  damage factor at all (`Concept_Document.md` 1.1.3). Symptoms to catch in a batch's own review:
  every settled kit reading Channel 2 or 3, a Sustain/Control Role whose purpose went unserved
  while three damage skills were authored, or a design revised upward to close a gap against
  another Role's recorded number.
* **Do not reference this plan or its batch numbers in code comments or commit messages.** Plans
  are deleted on completion.
* Phase 0's re-derived figures are still estimates until a burst is playable and can be felt.
* The **contrast baseline** remains open (the bursting champion's own basic vs. the team's average
  per-action output, which under the composition law may be the honest measure). Note it where
  the math touches it; settle it against a playable burst, not now.
