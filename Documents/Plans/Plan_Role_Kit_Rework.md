# Plan: Role Kit Rework for the Blowout Pillar

Supersedes `Documents/Plans/Plan_Channel_Population_Rework.md`. This is the authoring
counterpart to `Plan_Blowout_Alignment.md`, whose scope guard explicitly excludes new content
and hands it to a build-out plan that was never spawned.

## Status

**Framework correction, applied before Batch 2 design.** `Role_Kit_Design.md`'s kit contract had
pointed every Role at the 30-50x team figure rather than a per-Role one, and forbade an Enabler
primary identity that `Concept_Document.md` 1.1.3 permits. Both are corrected there (§1, §1.2, §4,
§5, §8, §9.2-§9.4) and in this plan's own contract restatement.

**Phase 0-2 complete.** All five Batch 1 kits are implemented: Plague Doctor, Herald of the Loom,
Sorcerer, Bloodmage, and Appraiser (§9.5) — the crit path (No Wasted Margin's overflow conversion,
Sizing Cut/Flaw Analysis's applier-scaled crit grants, Full Appraisal's consignment) closing the
batch's last open route (route C). Herald of the Loom's implementation (`weft_and_warp_trait.gd`) added the batch's second and third pieces of new
Channel 3 plumbing beyond §11's original scope: `Combat_Event.Cascade_Instance_Resolved` (a
per-real-instance broadcast off `CascadeResolver._ResolveEvent`'s own loop) and
`CascadeResolver.SubscribeInstanceModifier` (lets a subscriber amplify an already-matched
listener's instance count) — both exercised directly in `Tests/unit/test_cascade_resolution.gd`
ahead of the Herald trait itself, per the plan's own tier-1-before-tier-3 ordering. The Sorcerer's
implementation widened `SubscribeInstanceModifier` to pass the matched listener's own
`mechanic_key` to the callback, so a modifier can scope itself to one mechanic (its Echo count)
rather than amplifying every cascade instance in the game — the Herald's own Black Thread callback
updated to the new two-argument signature, unscoped as before. The
scorer gaps blocking Channel 3 kits are consolidated in §11; the crit scorer's own gap closed in
`e3d39bd`, and the above-100 Critical Chance clamp Appraiser's passive needed closed in its own
batch (§11). The framework
question that governed Batch 2's designs — whether Enabler may be a Role-level identity, raised by
Appraiser's kit claiming no bucket key at all — is **settled** (§8): Enabler **is** permitted as a
primary identity, the contract admits crit-path contribution, and it gained a second declared axis,
**contribution direction** (self-facing or exported, §1.1), with a per-Role allocation and a
10-of-20-exported roster target in §5. A Sustain or Control purpose is now explicitly discharged
through Enabler-tagged skills authored as kit content (§1.2, `Concept_Document.md` 3.1.3). Also settled: **the sweep is a sanity check on one calculable factor, not a design gate**
(`Role_Kit_Design.md` §4).

Phase 3 (Batch 2) design started ahead of Phase 2's remaining implementation, which the tier-3 loop
permits — settling a kit does not require implementing it in the same sitting. All five settled.
**Jester (§9.6) and Emissary (§9.7) implemented**; Cultist (§9.8), Chronophage (§9.9), Architect
(§9.10) remain. Routes A and E close; route C's second anchor is open rather than assigned, since the
Jester was Phase 1's proposal and is no longer a candidate, and no unsettled Role is assumed into
it. Chronophage's threshold-crossing `Cascade_Trigger` is **not** authored — counting section
boundaries is arithmetic a player cannot read off the screen.

**Jester's implementation** made `BattleResolver._RollFavoring` public (`RollFavoring`) and widened
it to every remaining pass/fail chance gate in combat (`SkillEffect.chance`, Glamour Graft's
incoming redirect, Double the fun!'s avoidance roll, Pilfer's steal chance), alongside its existing
crit-chance and debuff-resist sites; the damage-variance roll stays a bare `randf_range`, per §12's
own exception. The debuff-resist band widened to 0.85-1.0, and `StatusEffectData` gained
`magnitude_max` so `MaxHealthPercent` ticks can roll a range — Burning now rolls 2-10% per stack
(mean 6%), biased the same way, and `Burning_Bolas.tres` gained a second `ApplyDebuffEffect` for
Hexed. `Concept_Document.md` 3.2.1 #3, 3.2.3 and 3.2.4.2's Jester entry updated to match.
Post-Jester sweep: median 1.62x, 90th percentile 3.68x, ceiling 16.24x — unchanged from the
post-Appraiser baseline, as §9.6 predicted for an Enabler kit invisible to the scorer.

**Emissary's implementation** added `StatusEffectData.attacker_damage_value_multiple`, a
`magnitude_kind`-independent rider read by the new `StatusEffectResolver._DebuffValueDamageFactors`
(sibling to `_MissingHealthDamageFactors`, same `_ContributePersistentCasterFactors` call site) so
`Sanction.tres` contributes a `&"Sanction"` `CombinedDamageModifier` bucket to any attacker of its
holder, not only the Emissary's own. `Sanction.tres`'s attribute clause dropped from -1.0 to -0.5
per attribute. `ReduceBuffDurations`/`_ExpireBuffs` gained an optional `source_ID`, threaded from
`ReduceBuffDurationsEffect`, so `Statuses_Removed` can be attributed to a caster; natural expiry
keeps the default and credits nothing. `standing_record_trait.gd` credits an Infraction per buff
Signed Writ strips to zero duration. Post-Emissary sweep: median 1.84x, 90th percentile 4.47x,
ceiling 16.24x (unchanged — Sanction contributes to the modifier product on teams that already
route through it, not a new ceiling path). The top decile (114 teams) keeps its **8 distinct
pairings**, with Bloodmage/Tithe of Vitality displaced by **Emissary/Citation** — Sanction's
exported bucket lifting three Bloodmage/Tidal-Corsair/Architect-partnered teams (17.05x-18.16x)
past the threshold, and Citation itself, stacked with Sanction and Hemorrhage, becoming the
Emissary's own top-decile entry.

Phase 4 (Batch 3) **complete**, settled one Role at a time. Four settled, none implemented:

* **Lancer (§9.11)** — the batch's only replacement, and the first kit gated on *position* rather
  than a resource. Opens route F; accumulate-then-spend drops to four claimants.
* **Thief (§9.12)** — a base-referenced Defence bypass, opening route G with the Architect. One
  scorer gap follows, now `Role_Kit_Design.md` §11's open item: **the scorer models no defence
  ignore at all**, so both the Thief's and the Architect's contributions are invisible to the sweep
  until it does.
* **Tidal Corsair (§9.13)** — an adaptation closing route D. Prompted the description soft cap
  (`Concept_Document.md` 3.2.4), and its Slipstream claim retires part of `FeatureIdeas.md`'s
  orphaned-turn-bar-effects item and narrows its Outrider sketch.
* **Scholar (§9.14)** — an adaptation. The passive is replaced with an amplifier on every attribute
  modification the team applies, giving the roster its first reader of the Channel 1 attribute layer,
  which nothing has ever made worth casting. The basic gains a zone-gated Suppress rider whose gate
  Refutation can clear, so the kit carries an internal decision for the first time. One scorer gap
  follows (`Role_Kit_Design.md` §11): the sweep can credit granted attribute buffs but cannot amplify
  them, so the passive is invisible to it.
* **Tactician** — settled as kept, unchanged. A second Channel-2 hook was explored and every
  candidate shelved (a niche buff on an automatic-target passive, a debuff taxing Accuracy,
  stacking onto Fatal Flaw's already-strong grant, and a rider assuming Fatal Flaw was
  single-target when it is already team-wide); revisiting the Role's kit is deferred outside this
  plan until its team fantasy is clearer than a sweep figure can make it.

Phase 5 (Batch 4) in progress, settled one Role at a time: Alchemist, Diviner, Symbiote, Bar
Brawler, Warlord. Each Role's declared identity is re-derived from what its kit wants to be before
its slots are touched, rather than inherited from `Role_Kit_Design.md` §5's row. Settled so far:

* **Alchemist (§9.15)** — an adaptation. Passive and basic kept; Catalyst gains a brew refund on
  every non-brew reagent consumed, making the zone the thing that keeps the passive's window live
  rather than a potency add-on; Dissolving Agent gains damage and a second debuff, discharging
  Expose Weakness's reserved second source and putting a third feeder on route G.
* **Diviner (§9.16)** — an adaptation, and the batch's first redeclared identity: Channel 1 becomes
  Enabler, since every effect in the kit is mitigation or denial. Premonition keeps its prediction
  decision and gains a counter-attack with the holder's basic, the roster's first counter-attack
  and a minor exported instance count.
* **Symbiote (§9.17)** — settled as kept. Direction corrected to self-facing (§5's row had Exhert
  landing on an ally; it targets the Symbiote), and the kit's composition hook turned out to already
  exist: the Symbiote's own self-wounding feeds route E's `Wounded_Allies` surface.
* **Bar Brawler (§9.18)** — settled as kept. Heap On's ramp violates two of the framework's own
  constraints (an unconditional Channel 2 key on a no-cooldown cast, and uncapped growth) and stands
  as a sanctioned exception on the rule of cool; §1.2's "to fix at its own batch" is retired.
* **Warlord (§9.19)** — an adaptation, and the second redeclared identity: Channel 1 becomes
  Enabler. Brace for Impact, the kit's weakest slot, gains a reactive Enfeeble on anything whose
  attack lands on the Warlord, redirected damage included — discharging Enfeeble's reserved second
  source and closing the kit into one loop. §8's twice-claimed damage-redirection item closes here
  unchanged.

**Phase 5 (Batch 4) design complete. None of the five is implemented.** The batch found no
zero-contribution or one-note kit needing replacement, as expected; its substantive finding is that
§5's rows for the protection kits had each assumed a damage term the kit does not owe, corrected on
the Diviner and the Warlord (now Enabler) and on the Symbiote (direction). **Roster-wide mechanics changes that settled kits depend on are held in
`Role_Kit_Design.md` §12** until each one ships, rather than promoted into `Concept_Document.md`
ahead of the game.

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

**Post-Sorcerer sweep** (`Tests/manual/team_corpus_sweep.gd`, re-run after the Sorcerer landed).
Combined-modifier-product distribution: median 1.30x, 90th percentile 2.80x, ceiling 7.22x (max
unchanged — the Sorcerer's Echoes land in `repeat_contrast_ratio`, not the bucket product; the
median's small drop from 1.36x is not attributable to this batch, which touches no other Role's
buckets). The ceiling *contrast* team is still Alchemist/Tactician/Tidal Corsair (9.39x). The top
decile (114 teams) **regains a second distinct pairing**, the diversification this batch was meant
to produce: 97 Herald of the Loom/Cut the Cloth teams (9.64x-11.22x) and **17 Sorcerer/Cataclysm
teams** (9.86x-10.62x, Echo-driven — `sorcerer_repeat_driven: true` confirms the top entry is
actually driven by the Echo repeat, not merely riding a teammate's grant), up from the Post-Herald
sweep's single pairing. Still short of the pre-Phase-0 baseline's 7 distinct pairings and of §6's
"several independent" target.

**Post-Bloodmage sweep** (`Tests/manual/team_corpus_sweep.gd`, re-run after Bloodmage landed).
Combined-modifier-product distribution: median 1.62x, 90th percentile 3.68x, ceiling 16.24x — the
new ceiling team is Bloodmage/Tactician/Tidal Corsair (Corsairs Reckoning), Sanguine Pact and
Hemorrhage stacking onto the existing Daunting Strength grant rather than opening an independent
line. Contrast-ratio ceiling is now **21.12x**, same team. The top decile (114 teams) **regains the
pre-Phase-0 baseline's shape**: 7 distinct pairings — Herald of the Loom/Cut the Cloth (51 teams,
9.64x-14.44x), Sorcerer/Cataclysm (29, 9.86x-14.80x), Tidal Corsair/Corsairs Reckoning (16,
10.56x-21.12x), Architect/Final Calculation (15, 9.91x-19.82x), Diviner/Ill Omen (1, 11.60x),
Cultist/Devour Blessing (1, 13.62x), Bar Brawler/Headbutt (1, 13.05x) — meeting §6's "several
independent team combinations" target with Batch 1 complete on the Bloodmage's side; Appraiser is
the batch's remaining Role.

**Post-Appraiser sweep** (`Tests/manual/team_corpus_sweep.gd`, re-run after Appraiser landed —
Batch 1 complete). Combined-modifier-product distribution is unchanged (median 1.62x, 90th
percentile 3.68x, ceiling 16.24x) — expected, since the whole kit routes through the crit path
outside the combined modifier, matching the Sorcerer's and Bloodmage's own prior notes. The top
decile (114 teams) **gains an eighth distinct pairing**: Bloodmage/Tithe of Vitality (1 team,
9.74x) joins Herald of the Loom/Cut the Cloth (61 teams, 9.64x-14.44x — up from 51, several
Appraiser-partnered teams crossing the threshold on Sizing Cut/Flaw Analysis's team-reach crit
grants), Sorcerer/Cataclysm (18, 10.18x-14.37x — down from 29, displaced by the same crit lift
raising other pairings past it), Tidal Corsair/Corsairs Reckoning (16, 10.56x-21.12x),
Architect/Final Calculation (15, 9.91x-19.82x), Diviner/Ill Omen (1, 11.60x), Cultist/Devour
Blessing (1, 13.62x), Bar Brawler/Headbutt (1, 13.05x). No team's own best skill is an Appraiser
skill at the roster's base (ungeared) attribute levels the sweep uses — expected, since §9.5's own
≈5.58x projection assumes Legendary rarity and specific investment (Critical Chance 60, Critical
Damage 250, Knowledge 200) the sweep's preset-only attributes don't reach; the kit's contribution
still surfaces indirectly, lifting *other* Roles' crit factors when paired with the Appraiser.
**Batch 1 complete: all five Roles implemented.**

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
* **Plague Doctor's Comorbidity bug** (`status_effect_resolver.gd:70-71` hardcoded
  `tick_bonus_per_debuff = 0.0`, so the zone-trigger debuff path Miasma uses never read it) moved
  into the Plague Doctor's batch and is fixed — see Phase 2's own entry.
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
  **Plague's expiry spread no longer exists**, removed in the Plague Doctor's rework. The repeat tops out at 5.57x, below the roster's own top-decile threshold.
  Against 23 Channel-1-tagged statuses, a co-equal pillar channel had a one-item corpus, which is
  why Batch 1's Channel 3 work is load-bearing rather than incremental.
* **Channel 2 has almost no cross-kit hooks.** Almost every Channel 2 bucket in the roster is a
  skill-name or trait-resource key that only its own caster's skill reads; the levers by which a
  kit hands a factor to a teammate's burst — a granted modifier-bearing status, a debuff every
  attacker reads, an open counter another kit feeds — are held by a handful of entries. Confound,
  Suppress, Unravel and the rest are Channel-1-only in practice, because nothing in the roster
  reads them.
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
