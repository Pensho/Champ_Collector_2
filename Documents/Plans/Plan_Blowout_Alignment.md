# Plan: Blowout Alignment

The master plan for bringing the whole game into line with the design pillar in
`Concept_Document.md` section 1.1. The pillar was written after most of the current
systems, so this plan assumes nothing already conforms until it has been checked.

This document does not do the work. It orders the areas, records what each one has to
answer, and spawns a sub-plan per area. Sub-plans are written one at a time, only when
their prerequisites have landed — writing them all up front would bake in assumptions
the calibration phase is likely to overturn.

## Status

Phase 0 is done; its harness lives at `Scripts/Debug/blowout_calibration.gd`. Phase 1's
sub-plan is written (`Plan_Combined_Modifier.md`) and unexecuted.

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

### Phase 1 — Combined modifier in the damage pipeline

**Produced:** `Plan_Combined_Modifier.md`, written and unexecuted.

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

### Phase 2 — Status effect reclassification

**Produces:** `Plan_Status_Effect_Channels.md`.

Every buff and debuff in section 3.2.3 is currently either an attribute modifier or a
flat effect. Each must be classified as feeding channel 1 (attributes) or channel 2
(its own factor), and the ones that should contribute a factor but currently cannot need
reworking. Zone effects (section 3.2.4.1) are part of this pass — a zone is a natural
factor source and is currently not treated as one.

Watch for: the status effect cap interacting with uncapped deliberate resources
(section 1.1.4).

### Phase 3 — Cascade system

**Produces:** `Plan_Cascade_Resolution.md`.

The "more numbers" channel: effects that trigger off other effects, each producing its own
resolution. New architecture. Must settle the trigger vocabulary (what an effect can listen
for), the termination guarantees required by section 1.1.4 (one resolution per trigger
source per originating action, plus a depth cap), and how a cascade is represented in the
`result_produced` stream.

Depends on Phase 1 — each cascade instance carries its own combined modifier.

### Phase 4 — Burst presentation

**Produces:** `Plan_Burst_Presentation.md`.

Sequential resolution with escalating tempo and per-source attribution, per section 1.1.5.
The event stream already exists — `battle_resolver.gd` emits one `CombatResult` per atomic
event and `CombatResult.amount_by_source` already carries attribution. The work is on the
consuming side in `Scripts/Battle/battle.gd` and the battle UI: pacing, ordering, and
escalation, rather than flushing a cascade instantly.

Depends on Phase 3. This phase carries as much of the pillar as the math does and is not
to be deferred as polish.

### Phase 5 — Champion kit audit

**Produces:** `Plan_Kit_Blowout_Audit.md`.

Every Role and champion in section 3.1.3 and every skill in section 3.2.4.2 against the
rejection test. For each kit: which channel does it feed, does it contribute a factor
independent of other kits, and can it participate in a burst at all. Expected output is a
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
  encounter's answer feeds.

Feeds back into `Plan_Encounter_Solution_Design.md`, whose production rules must adopt the
pillar before further volume batches are authored. **That plan is paused until this phase
lands** — authoring more encounters under the old rules adds to the retrofit backlog.

## Watch for

* Sub-plans are written when their prerequisites land, not up front.
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

## Documentation

Each phase updates the Concept Document sections it touches before its sub-plan is closed.
`Technical_Design_Document.md` gains architecture entries from Phases 1, 3, and 4.
`Encounter_Design_Document.md` is rewritten in part by Phase 7.
