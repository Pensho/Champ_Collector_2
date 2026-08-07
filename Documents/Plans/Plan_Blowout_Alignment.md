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

Phase 0 through Phase 6 are done. Phase 5 was re-scoped as
`Plan_Kit_Burst_Reachability.md` after a first attempt (below) proved insufficient. Phase 0's
harness lives at
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

Phase 5 was first attempted as a per-entry audit: all 79 kit entries (19 Role passives, 60 Role
skills) in `Concept_Document.md` 3.1.3 and 3.2.4.2 tagged against the rejection test, plus the four
unassigned/generic entries in 3.2.4.3. The tags landed and are kept — the corpus is overwhelmingly
**conforms**, Batch 3 (Tactician, Symbiote, Bar Brawler, Warlord, Architect) is enabler-heavy exactly
as predicted, and two skills (Corsair's Reckoning, Final Calculation) are clean pressure-and-burst
reference examples — but a per-entry tag cannot answer the pillar's actual question, which is a
property of a team, not an entry. The one number the first attempt produced by hand, for two
sample teams (3.12x and 2.80x, against a 26x requirement), showed neither reaching within an order
of magnitude of the target, but covered 2 of ~1330 possible teams and could not be recomputed after
a kit changed. Re-scoped and re-run as `Plan_Kit_Burst_Reachability.md`: instead of auditing tags,
it builds an executable scorer — a kit contribution manifest plus a burst-reachability tool,
verified live against `BattleResolver` — that computes a team's combined-modifier product and burst
contrast ratio directly, and sweeps the full roster once for the distribution shape (median versus
ceiling) rather than ranking teams to act on. The corpus of curated "should this team detonate"
sets is deliberately left as a pluggable slot, seeded provisionally, because those sets cannot be
named until kit reworks give the roster real candidates. Documentation-vs-code conflicts found by
the first attempt were carried into the second rather than lost (Lancer's Reckless Momentum
offense/defense skill names, Architect's Calibration thresholds and the already-known
construction-zone claim, the Weigh the Mark/Case the Target name and duration drift, and
Comorbidity's tick bonus never reaching the Plague Doctor's own signature zone skill; these four
are now corrected directly in `Concept_Document.md` 3.1.3/3.2.4.2, citing
`Scripts/Debug/kit_contribution_manifest.gd` rather than a plan file). Both
`Plan_Kit_Blowout_Audit.md` and `Plan_Kit_Reworks.md` are deleted per the retention rule.

The full `C(20,3) = 1140`-team sweep (`Tests/manual/team_corpus_sweep.gd`, which reduces the
known preset roster to one preset per Role via `TeamSweep.DedupeByRole` before scoring — several
presets field the same Role's kit, e.g. `Centaur_Lancer.tres` and `Knight.tres` both field
Lancer, and scoring both would only add duplicate-kit teams) found the roster's
combined-modifier-product distribution at **median 1.40x, 90th percentile 2.80x, maximum 5.60x**
— against the 26x target, roughly 4.6x short at the product level even at the ceiling. The gap
between the 90th percentile and the maximum is one pairing repeated across every top-decile row
(Tidal Corsair's Wrangle the Sea composed with Tactician's unconditional Daunting Strength grant),
not a spread of distinct pairs: no other pair in the 20-champion roster reaches a second distinct
Channel-2/3 key at all, a single point of failure rather than a discriminating top tail. Four
prescriptions were quantified by re-running the scorer against a modified manifest copy
(`Tests/manual/prescription_sweep.gd`, never the real manifest): spreading a
`bonus_per_debuff_on_target` hook across more Channel-1-only skills, and adding a distinct
Channel-2 key to each zero-contribution kit (Herald of the Loom, Bloodmage), both leave the
ceiling and median completely unchanged, because either only ever composes with Tactician's lone
team-wide grant, never with the actual ceiling pair; a uniform retune of every existing
Channel-2/3 magnitude — including an Enabler-classed entry's `granted_status` magnitude, since a
grant like Tactician's Daunting Strength is a real Channel-2 factor once it lands, just carried
on an Enabler-classed manifest entry — reaches 26x by retuning alone at a 3.03x multiplier; and
populating Channel 3 via repeated `CascadeEvent.instance_count` stays flat until instance counts
get large (K=16, the per-action cascade cap, before the ceiling moves at all). Ranked by ceiling
delta per unit of work: retune (+1.71x at a modest 1.25x patch) > populate channel 3 (+1.20x at
K=16) > spread-hook and zero-contribution-kit (tied at zero). No prescription here uncaps
Momentum, Arcane Instability, or Steel and Sea. `Plan_Channel_Population_Rework.md` carries these
prescriptions forward; `Plan_Kit_Burst_Reachability.md` is deleted per the retention rule once
these findings have landed here and it has been reviewed.

Phase 6 shipped the gear verdict (channel 1 only, Relic rarity's unique effect the sole sanctioned
exception — no code changed, since gear was already purely additive) and two reagent-gated Role
reworks: the Sorcerer's next skill repeats at 50% damage after consuming a reagent (Channel 3,
riding a new `Types.Cascade_Trigger.Skill_Resolved` value and `Post()` call site in
`BattleResolver.ResolveSkill`), and the Alchemist grants the whole team a `Volatile_Mixture` damage
buff on any ally's reagent consumption (Channel 2, under its own bucket key, distinct from
Fractured Idol's `reagent_damage_bonus`). Both ride a new `Ally_Reagent_Consumed` broadcast
(`Skills.TriggerAllyReagentConsumedHook`) rather than the existing consumer-only `Reagent_Consumed`
hook. See Technical Design Document 7.4, 7.8, and 15.14.

Re-running `Tests/manual/team_corpus_sweep.gd` with both reworks and the manifest's new
`reagent_gated_bonus` precondition axis moved the roster's combined-modifier-product ceiling from
5.60x to **7.22x** (Alchemist + Tactician + Tidal Corsair bursting Corsair's Reckoning, 19.28x
contrast ratio) — the Alchemist's factor composes with the pre-existing Tidal-Corsair-plus-Tactician
pairing rather than opening an independent second one. Median and 90th percentile were not
re-measured against this specific change (see `Plan_Itemization_Channels.md` Phase 5 for the full
write-up); the Sorcerer's own repeat, scored separately as `repeat_contrast_ratio` since it is a
separate cascade instance rather than part of the same `CombinedDamageModifier`, tops out at 5.57x
total contrast anywhere in the 1140-team roster — short of the 7.33x top-decile threshold, and
therefore **not** the second, Tidal-Corsair-independent ceiling pairing Phase 5 was hoping for.
Recorded as an open balance question below (`Coverage gaps`), not resolved here.

Phase 0 findings, measured against the balanced bosses (Troll, Vael, Obsidian Stallion,
Ulfrac, Bor Bulwark). The newer catalog bosses are excluded as untuned and unplayed:

* **50x is reachable by kit design.** It needs a 26x multiplier on the scaled aggregate —
  about five independent factors of 2x, eight of 1.5x, or three of 3x. That is one to two
  factors per champion across a team of three.
* **Boss Health needs to roughly triple** (attribute ~300 to ~900–1000) for a 50x burst to
  land as 60–80% of a boss rather than 150–283% of it. Doubling suffices for 30x. Recorded
  in section 1.1.2; Phase 7 carries the retuning.
* **The current round budget is sound, at current boss Health.** Three champions at
  basic-skill output clear a balanced boss in 5.9–11.1 rounds, against the 10–12 in section
  5.3. No change needed to the budget itself — but Phase 7's Health retune takes boss fights
  out of that budget until a burst exists to shorten them again; see
  `Plan_Encounter_Blowout_Retrofit.md`'s `Findings`.
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

**Flaw found after completion, since fixed:** skill/reagent/graft buttons stayed visually active
through a cascade's resolve window — visible and apparently clickable while `_state` was
`Resolving`, even though the selection handlers already rejected clicks made in that state.
`ResolveTurn()` (`battle.gd`) now hides the skill, reagent, and graft UI itself the moment it
enters `Resolving`, instead of relying on `CompleteTurn()` alone.

### Phase 5 — Kit burst reachability — done

**Produced:** `Plan_Kit_Blowout_Audit.md`, then `Plan_Kit_Burst_Reachability.md` (the re-scoped
executable version), both deleted per the retention rule after completion (see Status above and
Technical Design Document 7.10). **Produces:** `Plan_Channel_Population_Rework.md`, carrying
Phase 6's prescriptions forward.

Re-scoped from a per-entry tag audit into an executable scorer, because a tag is a property of
one entry and the pillar's requirement is a property of a team. For each kit: which channel does
it feed — or whether it is an enabler passing the collapse test — does it contribute
independently of other kits, and can it participate in a burst at all, now answerable for any
team rather than by hand for two samples.

Watch for: the capped passives (Momentum, Arcane Instability, Steel and Sea stacks) are
explicitly correct as written per section 1.1.4 — they accrue automatically. Do not uncap
them as part of this pass.

### Phase 6 — Items, gear, and reagents — done

**Produced:** `Plan_Itemization_Channels.md`, executed and deleted per the retention rule (see
Status above and Technical Design Document 7.4, 7.8, and 15.14).

Affixes (section 3.3.1) and reagents (section 3.3.3) as factor sources. Gear is the
long-term progression channel, so this phase decides whether gear grows channel 1 only —
keeping base attributes tame per section 1.1.4 — or whether specific affixes contribute
factors, and what that does to the power curve across a full collection.

Four decisions were settled with the plan's owner before the sub-plan was written, and it is
written as prescriptions to execute rather than questions to litigate: gear feeds channel 1
only, with Relic rarity's unique effect the single sanctioned place a gear-sourced factor may
live; reagents are channel 1 effects only, keeping the one existing exception (Fractured Idol)
rather than reworking it; the Sorcerer's reagent payoff becomes channel 3 — consuming a reagent
makes the next skill repeat at a fraction of its damage; and the Alchemist gains a team-wide
channel 2 factor on ally reagent consumption, under a key distinct from the Sorcerer's so the
two multiply. The last two are shaped against Phase 5's finding: the roster's ceiling is one
pairing, and a Sorcerer plus an Alchemist is a candidate second one that is not gated on Tidal
Corsair.

The census behind the sub-plan found gear entirely additive (no affix system exists anywhere in
`Scripts/`, `Data/`, or `Tests/`) and one reagent family out of 82 resources reaching the
combined modifier. The one architecture cost the sub-plan surfaces is recorded under
`Coverage gaps` below.

### Phase 7 — Encounter tier and catalog retrofit — paused

**Produced:** `Plan_Encounter_Blowout_Retrofit.md`, written and partially executed (Phases 1
and 2 done, Phase 3 onward paused pending `Plan_Channel_Population_Rework.md` — see that
sub-plan's Status).

Four decisions were settled with the plan's owner before the sub-plan was written, so it is
written as prescriptions rather than questions: the boss Health retune happens now rather than
waiting on `Plan_Channel_Population_Rework.md` (its cost is carried as a Finding, see below);
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
    has no trigger or content at all. `Plan_Channel_Population_Rework.md` Phase 2, which planned
    to populate channel 3 through the same repetition shape, now consumes the landed trigger
    rather than authoring its own.
  * **Threshold crossings** — health dropping below a fraction, or a target's status count
    saturating. The game has stack thresholds (Arcane Instability, Calibration) but no
    health or status-count trigger at all.
  * **Cascade-on-cascade** — an effect listening for another cascade instance landing, which
    `Concept_Document.md` 1.1.3 names outright as the compounding case.

* **Cross-kit Channel 2/3 composition is mechanically sound but content-thin, quantified.** Found
  by Phase 5's per-entry pass, quantified by the re-scoped `Plan_Kit_Burst_Reachability.md`'s
  full-roster sweep. The architecture composes correctly — each `CombinedDamageModifier` is
  assembled fresh per resolution from only the acting caster's own state, so nothing about the
  composition law is broken — but the 1140-team sweep's product distribution (median 1.40x, 90th
  percentile 2.80x, ceiling 5.60x, against the 26x target) shows almost none of that correctness
  reaching the roster: the ceiling is one pairing (Tidal Corsair's Wrangle the Sea composed with
  Tactician's unconditional Daunting Strength grant) repeated across every top-decile team, and no
  other pair reaches a second distinct Channel-2/3 key at all. Only one skill in the 79-entry kit
  corpus (Sorcerer's Cataclysmic Surge) declares `bonus_per_debuff_on_target`, the main lever by
  which a debuff-applying kit hands a Channel 2 factor to a teammate's burst; most debuff-appliers
  (Confound, Suppress, Unravel, and others) have no damage skill anywhere in the roster that reads
  them as a factor, leaving them Channel-1-only in practice despite being individually correct.
  `Plan_Kit_Burst_Reachability.md`'s Phase 6 quantified four candidate fixes against this sweep:
  spreading more `bonus_per_debuff_on_target` hooks and giving each zero-contribution kit (Herald
  of the Loom, Bloodmage) a distinct factor both left the ceiling and median unchanged, since
  either only composes with Tactician's lone grant; a uniform retune of existing factors — including
  an Enabler-classed entry's granted-status magnitude — closes the gap alone at a 3.03x multiplier,
  the largest single-unit-of-work ceiling gain of the four; populating channel 3 via repeated
  `CascadeEvent.instance_count` is the next largest, but stays flat until instance counts get
  large. Populating more composition hooks across existing damage skills is build-out/rework
  content, not an architecture change — `Plan_Channel_Population_Rework.md` carries these ranked
  prescriptions forward.

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
  for `Plan_Channel_Population_Rework.md`, not a code defect.

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
