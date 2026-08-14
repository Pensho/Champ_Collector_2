# Plan: Blowout Alignment

The master plan for bringing the whole game into line with the design pillar in
`Concept_Document.md` section 1.1. The pillar was written after most of the current
systems, so this plan assumes nothing already conforms until it has been checked.

This document does not do the work. It orders the areas, records what each one has to
answer, and spawns a sub-plan per area. Sub-plans are written one at a time, only when
their prerequisites have landed — writing them all up front would bake in assumptions
the calibration phase is likely to overturn.

**Scope: this plan aligns what exists, it does not author new content.** Its phases
classify, rework, and retune the current statuses, kits, items, and encounters against the
pillar. Where a phase finds that a channel or system is too thinly populated to serve the
pillar no matter how well the existing entries are aligned, that is recorded under
`Coverage gaps` below and handed to a separate build-out plan — not solved by authoring
inside this one. The exception is specification input: a phase that must size an
architectural decision against content is entitled to sketch the content it needs to size
it (see Phase 3), because that sketch is a requirement on the system, not an addition to
the game.

## Status

Phases 0-6 are done; **Phase 7 is paused and is the only remaining work in this plan.**

Each completed phase's outcome lives in the documents it updated, not here: the combined modifier
and the cascade architecture in `Technical_Design_Document.md` 7.4 and 7.8, burst pacing in 7.9,
the status channel tags, modifier boundary and status cap in `Concept_Document.md` 1.1.4 and
3.2.3, the gear verdict in 3.3.1, and Phase 0's calibration findings in 1.1.2 and 1.1.4. Phase 0's
harness is kept at `Scripts/Debug/blowout_calibration.gd` and re-answers those questions whenever
the formula or the presets change. Every sub-plan spawned by Phases 1-6 is deleted per the
retention rule.

The roster sweep baseline these phases moved is `Role_Kit_Design.md` section 4's, which owns the
current figures; `Plan_Role_Kit_Rework.md` carries the pairing-web work forward.

## Phases

Phases 0-6 are complete and their sections are deleted per the retention rule.

### Phase 7 — Encounter tier and catalog retrofit — paused

**Produced:** `Plan_Encounter_Blowout_Retrofit.md`, written and partially executed (Phases 1
and 2 done, Phase 3 onward paused pending `Plan_Role_Kit_Rework.md` — see that sub-plan's
Status).

Four decisions were settled with the plan's owner before the sub-plan was written, so it is
written as prescriptions rather than questions: the boss Health retune happens now rather than
waiting on the kit rework (its cost is carried as a Finding, see below);
section 1.1.1's "unsolved is a wall" property is scoped to Boss tier, so the mini-boss keeps
"roughly double unsolved" and gains 1.1.2's ~10x partial-burst expectation and no mini-boss
entry's unsolved texture is rewritten; the channel tagging takes two forms, a per-encounter
audit table in `Encounter_Design_Document.md` alongside inline tags in the existing Role × Tier
coverage ledger; and the scope guard at the top of this plan binds the retrofit — reshaping a
boss's configurations toward a payoff is alignment, authoring new opponent skills or entries is
not.

The audit going in expects nearly the whole catalog to read enabler-only, which is only a defect
at Boss tier: the Warden of the Reliquary's configuration (3) — the Tactician plus Appraiser crit
round — is the one entry in the catalog that already describes a burst, and the sub-plan uses it
as the reference shape for the other two bosses.

Two parts:

* **Tier definitions** (section 5.3, owned by the Concept Document). The mini-boss
  definition currently reads "bringing an answer wins comfortably", which is softer than
  the pillar's promise of a payoff. Tier definitions must state the burst expectation and
  the threat-curve requirement from section 1.1.1.
* **The existing catalog** in `Encounter_Design_Document.md`: seven fodder encounters, the
  three Reanimating Statues, The Ashen Oracle, and the three bosses. All were designed as
  locks whose answers win comfortably, with no burst payoff. The three bosses are the most
  likely to need rework. The coverage ledger needs a column for which channel each
  encounter's answer feeds, enabler included.

Feeds back into `Plan_Encounter_Solution_Design.md`, whose production rules must adopt the
pillar before further volume batches are authored. **That plan is paused until this phase
lands** — authoring more encounters under the old rules adds to the retrofit backlog.

## Coverage gaps

Work this plan deliberately does not do: places where a channel or system is too thinly
populated to serve the pillar even once every existing entry is correctly aligned. Aligning
a roster cannot fill a channel that has nothing in it, and authoring the missing content is
a different body of work with different review criteria.

Distinct from a `Findings` section (see `Plans/README.md`): a finding is work this plan must
do before a phase is correct, and is deleted when fixed. A coverage gap is work this plan
is handing off, and is deleted when it migrates to the build-out plan.

Each entry names the under-populated channel or system, the census that shows it, and the
phase that found it. Once the list holds more than the cascade entry — realistically after
Phase 5, which is expected to produce the bulk of it — it spawns
`Plan_System_Buildout.md`, and the entries move there. At the latest that spawn happens
when this plan completes, since the retention rule in `Plans/README.md` deletes this file
and its open work has to land somewhere living.

* **Channel 3 has almost no content.** Of the 34 statuses tagged with a damage channel in
  `Concept_Document.md` 3.2.3, two touch channel 3: Overflow, and Plague's expiry spread —
  and Plague is primarily a channel 1 + 2 status whose spread is a corner case. Against 23
  channel 1 and 6 channel 2 tags, cascade is a co-equal pillar channel in section 1.1.3
  with a two-item corpus. Found by Phase 2, which could not report it: its failure taxonomy
  ("a status is broken in one of two ways, and only these two") is defined per status, so
  roster-level under-coverage is not expressible in it. Phase 3 sizes the trigger vocabulary
  against sketched content to avoid baking the sparsity into the architecture; populating
  the channel with real statuses, skill effects, and trait triggers is build-out work.

  Phase 3's ledger names the specific shapes the channel has no mechanic for, none of which it
  authors. All three need a new `Types.Cascade_Trigger` value and a `Post()` call site added
  before content can be authored against them — the shipped enum (`Status_Expired`,
  `Status_Landed`) only covers the two trigger shapes Phase 3's four ported effects needed, and
  every `Post()` call site in the codebase lives in `status_effect_resolver.gd`:
  * **Repetition — the trigger now exists, the content is still thin.** A skill cast that
    repeats, and a status or zone that detonates once per point of remaining duration or charge,
    both re-read channels 1 and 2 per instance, so instance count becomes a multiplier on the
    other two channels rather than a sum — the shape that makes cascade a co-equal channel. Phase
    6 landed the first half: `Types.Cascade_Trigger.Skill_Resolved` and a `Post()` call site in
    `BattleResolver.ResolveSkill` (see Technical Design Document 7.8), consumed by the Sorcerer's
    reagent-triggered repeat. A status or zone that detonates per remaining duration/charge still
    has no trigger or content at all. `Plan_Role_Kit_Rework.md` consumes the landed
    trigger rather than authoring its own where a batch's kit design calls for repetition.
  * **Threshold crossings** — health dropping below a fraction, or a target's status count
    saturating. The game has stack thresholds (Arcane Instability, Calibration) but no
    health or status-count trigger at all.
  * **Cascade-on-cascade** — an effect listening for another cascade instance landing, which
    `Concept_Document.md` 1.1.3 names outright as the compounding case.

* **Cross-kit Channel 2/3 composition is mechanically sound but content-thin, quantified.** Found
  by Phase 5's per-entry pass, quantified by the re-scoped full-roster sweep (figures below predate `Plan_Role_Kit_Rework.md` Phase 0's mitigation-formula
  change; that plan's Status carries the current baseline). The architecture composes correctly —
  each `CombinedDamageModifier` is assembled fresh per resolution from only the acting caster's
  own state, so nothing about the composition law is broken — but the 1140-team sweep's product
  distribution (median 1.40x, 90th percentile 2.80x, ceiling 5.60x, against the then-26x target)
  shows almost none of that correctness reaching the roster: the ceiling is one pairing (Tidal
  Corsair's Wrangle the Sea composed with Tactician's unconditional Daunting Strength grant)
  repeated across every top-decile team, and no other pair reaches a second distinct Channel-2/3
  key at all. Only one skill in the 79-entry kit corpus (Sorcerer's Cataclysmic Surge) declares
  `bonus_per_debuff_on_target`, the main lever by which a debuff-applying kit hands a Channel 2
  factor to a teammate's burst; most debuff-appliers (Confound, Suppress, Unravel, and others)
  have no damage skill anywhere in the roster that reads them as a factor, leaving them
  Channel-1-only in practice despite being individually correct. that sweep's own phase quantified four candidate fixes against this sweep: spreading more
  `bonus_per_debuff_on_target` hooks and giving each zero-contribution kit (Herald of the Loom,
  Bloodmage) a distinct factor both left the ceiling and median unchanged, since either only
  composes with Tactician's lone grant; a uniform retune of existing factors — including an
  Enabler-classed entry's granted-status magnitude — closes the gap alone at a 3.03x multiplier,
  the largest single-unit-of-work ceiling gain of the four; populating channel 3 via repeated
  `CascadeEvent.instance_count` is the next largest, but stays flat until instance counts get
  large. Populating more composition hooks across existing damage skills is build-out/rework
  content, not an architecture change — `Plan_Role_Kit_Rework.md` carries this forward as its
  pairing-web target.

* **Relic rarity has a design slot but no code mechanism.** `Concept_Document.md` 3.3.1 names
  Relic rarity's unique effect as the sole sanctioned gear-sourced `CombinedDamageModifier`
  factor, but Relic rarity rolls no attributes and no unique-effect mechanism exists in code at
  all. Found by Phase 6's census. Build-out work for `Plan_System_Buildout.md`: authoring the
  mechanism and then auditing each individual Relic's unique effect against the 1.1.6 rejection
  test as a conditional factor, per the gear verdict.
* **Trinket has no attribute pool, and crashes on upgrade.** `Game_Balance.ITEM_TYPE_ATTRIBUTES`
  (`Scripts/game_balance.gd:32-55`) defines Weapon, Shield, and Boots only; `EquipmentPreset.Setup()`
  silently rolls a Trinket item no attributes, and `Equipment.Upgrade()`
  (`Scripts/Gear/equipment.gd:55-65`) then crashes on it outright — the candidate-attributes
  fallback reads a `Trinket` dictionary key that does not exist. Found by Phase 6, which
  worked around it by sizing the collection power-curve figure off a three-slot (Weapon, Shield,
  Boots) loadout rather than the four-slot one `Concept_Document.md` 3.3.1 names as the core
  intended loadout. Build-out work: give Trinket an attribute pool (or a Trinket-specific
  mechanic, per its own item type) before a four-slot loadout is reachable at all.
* **The Sorcerer's reagent-triggered repeat does not reach the roster's top decile, as tuned.**
  Phase 6's full-roster sweep found the strongest Sorcerer-cast candidate anywhere in the 1140-team
  roster at 5.57x total contrast ratio (5.03x single-hit plus 0.53x repeat), against a 7.33x
  top-decile threshold — so the Sorcerer-plus-Alchemist pairing Phase 5 hoped would open a second,
  Tidal-Corsair-independent ceiling does not, as currently tuned. A balance-tuning question
  (`REPEAT_FRACTION`, the debuff-anchored Warped bonus stacking, or Instability stack magnitude)
  for `Plan_Role_Kit_Rework.md`, not a code defect.

**This list now holds more than the cascade entry — the spawn condition above is met.**
`Plan_System_Buildout.md` is due to be created and receive both entries above; not yet spawned as
part of this update — flagged here per the standing rule rather than left implied, pending a
decision on scope with the plan's owner.

## Watch for

* Sub-plans are written when their prerequisites land, not up front.
* **An under-populated channel is a result, not a null result.** Every phase asks its audit
  question — is each existing entry aligned — and a coverage question alongside it: does the
  existing corpus populate this channel densely enough to design against at all. A phase that
  finds nothing to rework has not thereby found nothing; record the gap above rather than
  closing the phase clean.
* The pillar outranks the rest of the Concept Document. When a phase finds a conflict, the
  other section is the one that changes — but flag it rather than rewriting silently.
* **The contrast baseline is unsettled.** Section 1.1.2 measures a burst against the bursting
  champion's own basic skill. Under the composition law a burst is a team product, so the honest
  baseline may instead be the team's average per-action output, which would move the target
  substantially. Left to settle against a playable burst rather than emulated now.
* **Defence going irrelevant at burst scale is a risk, not a settled win.** Deferred to
  `FeatureIdeas.md` ("Defence Relevance at Burst Scale"). Phase 7's encounter Defence tuning
  should treat the irrelevance as inherited from section 1.1.4, not re-litigate it. It
  load-bears the verdict that Expose_Weakness is channel 1, not channel 2 — that stands until
  the backlog item is picked up.

## Documentation

Phase 7 rewrites part of `Encounter_Design_Document.md` and updates section 5.3's tier
definitions.
