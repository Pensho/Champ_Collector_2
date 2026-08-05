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

Phase 0, Phase 1, Phase 2, Phase 3, and Phase 4 are done. Phase 0's harness lives at
`Scripts/Debug/blowout_calibration.gd`. Phase 1 shipped `CombinedDamageModifier`
(`Scripts/Battle/combined_damage_modifier.gd`) as the multiplicative damage channel, keyed by
mechanic identity and multiplying the pre-mitigation scaled aggregate; see Technical Design
Document 7.4 and 15.12. Its sub-plan (`Plan_Combined_Modifier.md`) has been deleted per the
retention rule in `Plans/README.md`.

Phase 2 classified all 58 statuses into the three damage channels or the enabler class, fixed the
category-keyed damage buckets Phase 1 left in place (trait outgoing bonus, the self-tick damage
multiplier, Opportunist, and zone factors — each now keyed by mechanic identity instead of by
source category), reworked the five statuses whose classification exposed a linear-bump defect
(Opportunist, Daunting_Strength, Luck/Hexed, Bleed/Plague, Temporal_Leak), settled the combined
modifier's boundary (target-side reduction, crit, Barrier all stay outside it) and the
status-effect cap (kept at eight, shared across buffs and debuffs, with denials now reported
instead of dropped silently), and landed the bucket tagging in `Concept_Document.md` 3.2.3. See
Technical Design Document 7.4 for the keying and rework mechanisms. Its sub-plan
(`Plan_Status_Effect_Channels.md`) has been deleted per the retention rule in `Plans/README.md`.

Phase 3 shipped `CascadeResolver` (`Scripts/Battle/cascade_resolver.gd`) as the cascade channel's
architecture: a post-and-drain trigger queue enforcing the two termination bounds from
`Concept_Document.md` 1.1.4 (depth and per-action fan-out) at one point, replacing the four
hardcoded expiry/application branches that stood in for it. Overflow, Plague, Rush, and Mirror
Coat are now registered listeners rather than bespoke branches; Plague's spread was additionally
moved onto the normal `CastDebuff` path (a resist roll, Aegis, Sequence Lock, and stack/refresh
rules now apply to it, where it previously bypassed all four). See Technical Design Document 7.8
and 15.13. Its sub-plan (`Plan_Cascade_Resolution.md`) has been deleted per the retention rule in
`Plans/README.md`; the trigger shapes it sized against but did not author remain below under
`Coverage gaps`.

Phase 4 paced the floating combat text spawned from a cascade's `CombatResult` stream —
`BurstPacing` (`Scripts/Battle/burst_pacing.gd`) maps each instance's ordinal to a shrinking spawn
delay, a growing text scale, and a shift toward red, fully red by the tenth instance — while
`BattleResolver` stays headless and synchronous; game state (health bars, status icons, death)
still applies instantly. Turn completion now waits for the text queue to drain, capped at 2.0
seconds. See Technical Design Document 7.9. Per-source attribution (`Concept_Document.md` 1.1.5's
other requirement) was deliberately not done and is recorded as a `FeatureIdeas.md` entry instead.
Its sub-plan (`Plan_Burst_Presentation.md`) has been deleted per the retention rule in
`Plans/README.md`.

Phase 0 findings, measured against the balanced bosses (Troll, Vael, Obsidian Stallion,
Ulfrac, Bor Bulwark). The newer catalog bosses are excluded as untuned and unplayed:

* **50x is reachable by kit design.** It needs a 26x multiplier on the scaled aggregate —
  about five independent factors of 2x, eight of 1.5x, or three of 3x. That is one to two
  factors per champion across a team of three.
* **Boss Health needs to roughly triple** (attribute ~300 to ~900–1000) for a 50x burst to
  land as 60–80% of a boss rather than 150–283% of it. Doubling suffices for 30x. Recorded
  in section 1.1.2; Phase 7 carries the retuning.
* **The current round budget is sound.** Three champions at basic-skill output clear a
  balanced boss in 5.9–11.1 rounds, against the 10–12 in section 5.3. No change needed.
* **The modifier belongs on the scaled aggregate, not on final damage** — worth nearly
  double (33x becomes 63x against Defence 120), because the aggregate also feeds the
  mitigation ratio, and worth more the tankier the target. Section 1.1.4.
* **Defence-ignore is irrelevant to bursts** (under 2% across the full range), correcting
  an earlier assumption in section 1.1.4.
* **The multiplicative channel already exists, fragmented.** `_ResolveDamage` in
  `battle_resolver.gd` already threads six ad-hoc modifier inputs into
  `Skills.MitigatedDamage`: `p_trait_multiplier`, `p_ramp_multiplier`,
  `_damage_multiplier`, `_damage_dealt_bonus`, `GetOutgoingDamageBonus`, and
  `_OpportunistDamageMultiplier` — some multiplicative, some additive fractions, some on
  the aggregate and some on final damage. Phase 1 is a unification of these into one
  declared channel, not a greenfield addition.

## Ordering principle

Three constraints set the order:

1. **Nothing is designed against an unknown number.** The 50x contrast target in section
   1.1.2 is an estimate. Content authored before it is validated will need re-authoring.
2. **The math is the foundation.** `Combined_Modifier` does not exist in the damage
   pipeline. Every kit, status, item, and encounter decision depends on how it behaves.
3. **Encounters come last.** They are the consumer of every other system, and the
   existing catalog is the largest body of work at risk.

## Phases

### Phase 0 — Calibration harness

**Done.** Produced `Scripts/Debug/blowout_calibration.gd`, kept rather than thrown away —
it re-answers these questions whenever the formula or the presets change. Findings are in
Status above.

Compute basic-skill damage versus burst damage for a champion under a given set of
modifier factors, using the section 3.2.1 formula with `Combined_Modifier` applied.
Answer three questions before anything is designed against them:

* Is 50x the right order of magnitude for a boss burst, or is the real number closer to
  15x or 200x?
* How many independent factors, at what sizes, are needed to reach it? This sets how many
  kits a burst has to involve, which is the real content cost of the pillar.
* Where does the mitigation term stop mattering — how low must `Defense_Ignore_Factor`
  go before the modifier lands undamped?

Output updates the calibration targets in section 1.1.2. This is a spreadsheet-grade
question and should not become an engineering project.

### Phase 1 — Combined modifier in the damage pipeline — done

**Produced:** `Plan_Combined_Modifier.md`, deleted per the retention rule after completion (see
Technical Design Document 7.4 and 15.12).

Implement the multiplicative channel, unifying the eight existing modifier inputs into one
declared channel on the scaled aggregate. Settled there: factors are keyed by **mechanic
identity, never by character**, so grouping enforces itself; the modifier is assembled per
resolution and never stored, which is what Phase 3's repeat and cascade mechanics rest on;
and `CombatResult` carries the assembled object for Phase 4 to name contributors from.

The composition law in section 1.1.3 is worded in terms of champions ("within a champion's
kit, effects add"), which describes character-keyed grouping. That wording is corrected in
this phase. Which mechanics ought to share a key is left open — it is a content decision
Phases 2 and 5 make as kits are redesigned.

Prerequisite for every phase after it.

### Phase 2 — Status effect reclassification — done

**Produced:** `Plan_Status_Effect_Channels.md`, deleted per the retention rule after completion
(see Status above and Technical Design Document 7.4). Every one of the 58 statuses carries a
settled channel or enabler verdict, tagged inline in `Concept_Document.md` 3.2.3; five reworks
landed (Opportunist, Daunting_Strength, Luck/Hexed, Bleed/Plague, Temporal_Leak); the combined
modifier's boundary and the status-effect cap are both settled and written into
`Concept_Document.md` 1.1.4.

Every buff and debuff in section 3.2.3 is currently either an attribute modifier or a
flat effect. Each is classified into one of three buckets: channel 1 (attributes),
channel 2 (its own factor), or **enabler** (section 1.1.3 — creates or protects the burst
window, produces no damage). Zone effects (section 3.2.4.1) are part of this pass — a zone
is a natural factor source and is currently not treated as one.

A status is broken in one of two ways, and only these two:

* It sits in no bucket — it neither moves an attribute, nor supplies a factor, nor passes
  the collapse test in section 1.1.6 for an enabler.
* It is filed as a damage factor but delivers a linear bump.

Watch for:

* **Do not convert enablers into damage factors.** The target is not a roster where every
  status touches damage; choosing a non-damage line is a decision worth preserving. An
  enabler that passes the collapse test needs no rework.
* A status whose nominal bucket is channel 1 but whose real value is denial (Blind reduces
  Accuracy, but is picked to stop an application) is classified by both: its attribute
  effect is channel 1, its role is enabler. Reworking it toward a damage factor is wrong.
* The status effect cap interacting with uncapped deliberate resources (section 1.1.4).

### Phase 3 — Cascade system — done

**Produced:** `Plan_Cascade_Resolution.md` — implemented and deleted per the retention rule.

The "more numbers" channel: effects that trigger off other effects, each producing its own
resolution. New architecture. Must settle the trigger vocabulary (what an effect can listen
for), the termination guarantees required by section 1.1.4 (one resolution per trigger
source per originating action, plus a depth cap), and how a cascade is represented in the
`result_produced` stream.

**The vocabulary is sized against sketched content, not against the two cascade sources
that exist.** Phase 2 left channel 3 populated by Overflow and Plague's expiry spread
only; a vocabulary settled against those two will express those two and nothing else, and
widening it later is a code change where authoring the content is not. Before the
vocabulary is frozen, sketch a dozen or so candidate trigger statements — the shapes an
effect should be able to listen for (a status expiring, a status being applied, a
threshold crossed, a kill, a zone entered, a critical hit, another cascade instance
landing) with a plausible effect behind each. The sketch is specification input, kept in
the sub-plan; **authoring those effects is not this phase's work** and belongs to the
build-out plan under `Coverage gaps`.

Depends on Phase 1 — each cascade instance carries its own combined modifier.

### Phase 4 — Burst presentation — done

**Produces:** `Plan_Burst_Presentation.md`.

Sequential resolution with escalating tempo, per section 1.1.5. The event stream already
existed — `battle_resolver.gd` emits one `CombatResult` per atomic event, with a
`Cascade_Triggered` marker and `cascade_depth` stamped ahead of each cascade instance. The
work was entirely on the consuming side: `Scripts/Battle/battle.gd` tracks the cascade
instance ordinal and gates turn completion on the combat-text queue (capped at 2.0 seconds);
`Scripts/Battle/burst_pacing.gd` and the battle UI's spawn queue turn that ordinal into
escalating delay, scale, and color. `BattleResolver` remains headless and synchronous
throughout — game state still applies in one frame. Per-source attribution, section 1.1.5's
other half, was deliberately deferred; see the plan's `Deliberately not done` section and the
resulting `FeatureIdeas.md` entry.

Depended on Phase 3.

### Phase 5 — Champion kit audit

**Produces:** `Plan_Kit_Blowout_Audit.md`.

Every Role and champion in section 3.1.3 and every skill in section 3.2.4.2 against the
rejection test. For each kit: which channel does it feed — or whether it is an enabler
passing the collapse test — does it contribute independently of other kits, and can it
participate in a burst at all. A kit carrying enablers rather than factors is a valid
result, not a finding. Expected output is a
list of kits that need rework, not a rewrite of all of them.

Watch for: the capped passives (Momentum, Arcane Instability, Steel and Sea stacks) are
explicitly correct as written per section 1.1.4 — they accrue automatically. Do not uncap
them as part of this pass.

### Phase 6 — Items, gear, and reagents

**Produces:** `Plan_Itemization_Channels.md`.

Affixes (section 3.3.1) and reagents (section 3.3.3) as factor sources. Gear is the
long-term progression channel, so this phase decides whether gear grows channel 1 only —
keeping base attributes tame per section 1.1.4 — or whether specific affixes contribute
factors, and what that does to the power curve across a full collection.

### Phase 7 — Encounter tier and catalog retrofit

**Produces:** `Plan_Encounter_Blowout_Retrofit.md`.

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
  authors. Repetition is expressible today, through `CascadeEvent.instance_count`, with no
  further architecture work; the other two need a new `Types.Cascade_Trigger` value and a
  `Post()` call site added before content can be authored against them — the shipped enum
  (`Status_Expired`, `Status_Landed`) only covers the two trigger shapes Phase 3's four ported
  effects needed:
  * **Repetition** — a skill cast that repeats, and a status or zone that detonates once per
    point of remaining duration or charge. Both re-read channels 1 and 2 per instance, so
    instance count becomes a multiplier on the other two channels rather than a sum. This is
    the shape that makes cascade a co-equal channel; nothing in the game does it.
  * **Threshold crossings** — health dropping below a fraction, or a target's status count
    saturating. The game has stack thresholds (Arcane Instability, Calibration) but no
    health or status-count trigger at all.
  * **Cascade-on-cascade** — an effect listening for another cascade instance landing, which
    `Concept_Document.md` 1.1.3 names outright as the compounding case.

## Watch for

* Sub-plans are written when their prerequisites land, not up front.
* **An under-populated channel is a result, not a null result.** Every phase asks its audit
  question — is each existing entry aligned — and a coverage question alongside it: does the
  existing corpus populate this channel densely enough to design against at all. A phase that
  finds nothing to rework has not thereby found nothing; record the gap above rather than
  closing the phase clean. This runs opposite to the conservative guardrails in Phases 2 and
  5 (do not convert enablers, do not uncap passives, a list of reworks rather than a rewrite),
  which are deliberately deflationary and would otherwise be the only pressure in the plan.
* The calibration targets in section 1.1.2 are estimates until Phase 0 replaces them. Do
  not treat 50x as settled while authoring.
* The pillar outranks the rest of the Concept Document. When a phase finds a conflict, the
  other section is the one that changes — but flag it rather than rewriting silently.
* **The contrast baseline is unsettled.** Section 1.1.2 measures a burst against the
  bursting champion's own basic skill, and the Phase 0 harness models it that way. Under
  the composition law a burst is a team product, so the honest baseline may instead be the
  team's average per-action output — which would move the target substantially. Deliberately
  left unresolved: a burst is assembled from a composition rather than a single origin, and
  that composition is what makes an encounter a puzzle, so the baseline is a design question
  to settle against a playable burst rather than to emulate now. Revisit in Phase 5.
* **Flagged, unresolved: Defence going irrelevant at burst scale is a risk, not a settled
  win.** Deferred to `FeatureIdeas.md` ("Defence Relevance at Burst Scale") — important but
  not urgent. Phase 4 and Phase 7 proceed without waiting on it; whichever phase's math
  restates the current irrelevance (Phase 4's modifier boundary, Phase 7's encounter Defence
  tuning) should note it as inherited from section 1.1.4, not re-litigate it. It already
  load-bears one Phase 2 verdict (Expose_Weakness is filed channel-1-not-channel-2
  specifically because a Defence debuff can't move a burst) — that verdict stands until the
  backlog item is picked up.

## Documentation

Each phase updates the Concept Document sections it touches before its sub-plan is closed.
`Technical_Design_Document.md` gains architecture entries from Phases 1, 3, and 4.
`Encounter_Design_Document.md` is rewritten in part by Phase 7.
