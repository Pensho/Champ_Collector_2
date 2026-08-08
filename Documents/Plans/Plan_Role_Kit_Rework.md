# Plan: Role Kit Rework for the Blowout Pillar

Supersedes `Documents/Plans/Plan_Channel_Population_Rework.md`. This is the authoring
counterpart to `Plan_Blowout_Alignment.md`, whose scope guard explicitly excludes new content
and hands it to a build-out plan that was never spawned.

## Status

Phase 0 done. Phase 1 drafted, awaiting sign-off (see below) before Phase 2 starts. Phase 2 in
progress: Plague Doctor implemented; Herald of the Loom and Sorcerer settled and recorded in
`Role_Kit_Design.md` §9.2 / §9.3, not yet implemented; Bloodmage and Appraiser not started. The
scorer gaps blocking all three Channel 3 kits are consolidated in §11 and are the batch's first
implementation work. Phases 3-6 not started.

**Phase 1 result.** `Documents/Role_Kit_Design.md` created, holding the kit contract, the
indirect-composition rule, the synergy grammar, Phase 0's re-derived targets, and the two pieces
of new design work: a channel identity allocation across all 20 Roles (4 Channel 3, 7 Channel 2, 4
Channel 1, 5 Enabler — up from ~1 real Role-driven Channel 3 anchor and one cross-kit Channel 2
hook in the baseline) and a five-route pairing web (debuff density, cascade count, crit path,
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
own basic, which 1.1.2 sizes at a **26x multiplier on the scaled attribute aggregate** — about
one to two independent factors per champion across a three-champion team.

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

* **Channel 3 is nearly empty.** Its whole corpus is Overflow, Plague's expiry spread, and the
  Sorcerer's reagent-triggered repeat — and the repeat tops out at 5.57x, below the roster's own
  top-decile threshold. Against 23 Channel-1-tagged statuses, a co-equal pillar channel has
  effectively three entries.
* **Channel 2 has almost no cross-kit hooks.** `bonus_per_debuff_on_target` is the main lever by
  which a debuff-applying kit hands a factor to a teammate's burst, and exactly **one** skill in
  the 79-entry corpus declares it (Cataclysmic Surge). Confound, Suppress, Unravel and the rest
  are Channel-1-only in practice, because nothing in the roster reads them.
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
3. **Replacement is the default posture, not the exception.** A skill is kept only when it earns
   its slot against the framework. Expansion is the middle option and is expected to be common:
   most one-note skills (a lone debuff, a lone buff, plain damage) should gain a second dimension
   rather than be cut. "Keep as-is" is a fallback.
4. **The 3-skill cap stays** (`Concept_Document.md` 3.2.4), *but the basic is a design slot too.*
   A no-cooldown basic may carry a secondary rider — a low-chance debuff or buff application, a
   small heal (Fateful Glimpse is the existing precedent), a stack grant. Riders are
   Enabler-weight only: a basic never carries a Channel-2/3 bucket key, or channel contribution
   becomes free.
5. **Defence is being made to matter** (see Phase 0). The 1.1.4 rule that Defence stops mattering
   at burst scale is rejected on legibility grounds: Defence and defence-ignore are terms every
   RPG player arrives already understanding, and teaching them that the expectation is inverted
   costs more than making the expectation true.
6. **Design home:** a new living `Documents/Role_Kit_Design.md` carries the channel identity
   allocation and synergy ledger (successor to the archived `Plan_Role_Skill_Kits.md` claims
   ledger); settled kits are promoted into `Concept_Document.md` 3.2.4.2, which stays the
   authority.

## The design framework (Phase 1 output, stated here so batches are executable)

### The per-Role kit contract

Each Role must be able to put on the table by burst time:

* **one declared primary channel identity** — Channel 1, Channel 2, Channel 3, or Enabler;
* **at least one distinct `CombinedDamageModifier` bucket key** at a magnitude in the target band
  Phase 0 sets, unless its primary identity is Enabler;
* **at least one composition hook** — something it reliably puts into the world that another
  kit's condition can read.

An Enabler-identity Role carries no bucket key and is held to 1.1.6's **collapse test**: removing
it makes the burst not happen, or not survive to happen. "Useful to have" fails.

### Composition is indirect — never named coupling

**A skill must never reference another Role, champion, or skill.** Hooks read *world state*, and
any kit that can produce that state satisfies them. That is what makes a combination a discovery
rather than a scripted pair, and what keeps every future Role automatically compatible.

Legitimate condition surfaces (illustrative, not exhaustive — the brainstorm should extend this
list):

* a named status effect being present on the target, or on the caster, or on an ally;
* the *absence* of a status, or the target's total status count;
* current or missing Health, on either side; the caster's own resource or stack count;
* turn-bar state — zone presence, section occupancy, relative position;
* whether the target acted, was hit, or crit since the caster's last turn;
* how many distinct debuff *types* are on the target (`bonus_per_debuff_on_target` gives each type
  its own bucket, so each further type multiplies).

### The synergy grammar

"Synergy" has to be expressible in the `.tres` schema, so the plan works from the mechanisms that
actually multiply (see `Technical_Design_Document.md` 7.4):

| Mechanism | Schema | Why it multiplies |
|---|---|---|
| Per-debuff-type factor | `DamageEffect.bonus_per_debuff_on_target: {Debuff_Type: float}` | **One independent bucket per debuff type** — each further debuff on the target multiplies. The primary cross-kit hook, and the most under-used. |
| Trait-counter factor | `DamageEffect.bonus_per: {Trait_Count_Source: float}` | Reads a counter another kit can feed. |
| Granted modifier-bearing status | `ApplyBuffEffect` of a `DamageMultiplier` / `PerTargetDebuffDamagePercent` status | Lands the factor on whoever consumes it. |
| Cascade instance count | `Types.Cascade_Trigger` | Each instance re-reads channels 1 and 2, so count multiplies against them. |
| Zone `on_trigger` payload | `ZoneEffect.on_trigger: Array[SkillEffect]` | A separate resolution on a schedule the enemy walks into. |

Governed by the composition law: **same bucket key adds, distinct keys multiply, and keys are
mechanic identity — never character identity.** Two Roles applying the same debuff type produce
one factor, not two.

**Channel 3's vocabulary is explicitly open.** `Types.Cascade_Trigger` currently holds only
`Status_Expired`, `Status_Landed`, and `Skill_Resolved` — three values sized to the four effects
that happened to need them, not a considered vocabulary. The channel is new and under-explored,
so brainstorming may propose **new trigger values, new bucket shapes, and new condition
surfaces**, and the plan authors the enum value plus its `Post()` call site when a design earns
it. The named gaps with no trigger at all: threshold crossings (health, status count), and
cascade-on-cascade — which 1.1.3 names outright as the compounding case.

### The pairing web

The failure to fix is that one pairing is the ceiling. Target: **at least four independent
ceiling pairings**, each reaching a comparable product through a *different* gating mechanic
(debuff density, cascade count, crit path, stack consumption, zone payload, health thresholds),
and none of them routed through Tidal Corsair or Tactician's grants. Success is measured on the
sweep's *shape* — a populated top decile with distinct member pairs — not only on the maximum.

### Constraints that bind the design

* **The 8-status cap is shared across buffs and debuffs** (1.1.4). A combination that needs six
  debuffs on the boss is fighting the cap against the player's own stacks and the enemy's
  debuffs. Debuff-density payoffs must be designed to land inside it.
* **Burst payload skills need a top-level `DamageEffect`.** Damage nested inside
  `ZoneEffect.on_trigger` is invisible to the Sorcerer's repeat and can never be scored by
  `BurstReachability._HasDamageEffect` — the reason Miasma scores zero at any magnitude.
* **Do not uncap** Momentum, Arcane Instability, or Steel and Sea; magnitude-per-stack is the
  dial, not stack count.
* **Base attributes stay tame** — growth belongs in channels 2 and 3.
* Existing anti-overlap rules from the archived claims ledger still hold: identity effects to one
  Role, commodity buffs/debuffs to at most two, turn-bar effects to one, zones stay signature.

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
* Delete `Plan_Kit_Burst_Reachability.md` (complete but undeleted) and
  `Plan_Channel_Population_Rework.md` (superseded), migrating surviving findings here. Use `rm`.
  Both have live inbound references that must be repointed at this plan in the same change —
  `Plan_Blowout_Alignment.md` (Phase 5's `Produces:`, Phase 7's pause reason, three
  `Coverage gaps` entries), `Plan_Encounter_Blowout_Retrofit.md` (its Status, settled decision
  1, and its open Finding), and `Technical_Design_Document.md:2022`. Deleting the files without
  this leaves a dozen dangling references.
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
   tests: brainstorm candidate kits (via the `brainstorm` skill, against `Role_Kit_Design.md`) →
   settle kits → compute the settled design's projected numbers against the scorer's own
   formula/methodology (`blowout_calibration.gd`'s approach) and check them against the target
   band → **record the settled kit in `Role_Kit_Design.md` §9 (passive, all three skills,
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
  percentile, ceiling, **and the count of distinct pairings in the top decile**.
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
* **Do not reference this plan or its batch numbers in code comments or commit messages.** Plans
  are deleted on completion.
* Phase 0's re-derived figures are still estimates until a burst is playable and can be felt.
* The **contrast baseline** remains open (the bursting champion's own basic vs. the team's average
  per-action output, which under the composition law may be the honest measure). Note it where
  the math touches it; settle it against a playable burst, not now.
