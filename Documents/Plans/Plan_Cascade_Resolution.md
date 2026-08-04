# Plan: Cascade Resolution

Phase 3 of `Plan_Blowout_Alignment.md`. Builds the third damage channel from
`Concept_Document.md` 1.1.3 — effects that trigger off other effects, each producing its own
resolution and its own combined modifier — as a declared system rather than the four
hardcoded branches that stand in for it today.

This plan owns the **architecture**: the trigger vocabulary, the termination guarantees
required by section 1.1.4, and how a cascade appears in the `result_produced` stream. It does
**not** own the content that would populate the channel. Section 1.1.5's pacing and
escalation belong to Phase 4 (`Plan_Burst_Presentation.md`), which consumes what this plan
emits.

## Status

**Not started.** Prerequisite (Phase 1, `CombinedDamageModifier`) is landed.

## What exists today

Cascade is not a system. It is four bespoke `if type == …` branches, three of them inside the
same tick loop in `Scripts/Battle/status_effect_resolver.gd`:

- `_TriggerOverflow` — Overflow expires, deals Mysticism-scaled damage to all enemies via
  `BattleResolver.ResolveTraitDamage`. The only one that runs a full damage pipeline.
- `_SpreadPlague` — Plague expires, appends a fresh-duration copy to a random other enemy.
- `_TriggerRushStun` — Rush expires, applies Stun to the holder.
- `_TriggerMirrorCoat` — a debuff lands, a copy goes back to the attacker.

Plus the Sorcerer's Arcane Instability Surge, which reaches the same `ResolveTraitDamage`
entry point from a trait.

Each collects its work into a local array during the tick loop and resolves it after the loop
completes, because mutating the status list mid-iteration is unsafe — the same solution
written four times. None of them share a dedup rule, a depth bound, or a representation.
`_SpreadPlague` bypasses `ApplyDebuff` entirely (no resist roll, no Aegis, no Sequence Lock,
no stack/refresh rules), and re-applies with fresh duration to an ally of the holder, so on a
two-member side it can ping-pong without an architectural stop.

Section 1.1.4 requires that "every cascade must terminate. Each trigger source resolves at
most once per originating action, and a cascade has a maximum depth." Today nothing enforces
either half; termination is a property of the four effects happening to be shaped safely.

## Trigger vocabulary, sized against sketched content

Per `Plan_Blowout_Alignment.md`, the vocabulary is deliberately **not** derived from the two
cascade sources that exist: "a vocabulary settled against those two will express those two and
nothing else, and widening it later is a code change where authoring the content is not."

The ledger below is specification input — the shapes the architecture must be able to express.
The right-hand column is what each shape is sized against. **Authoring the effects behind the
shapes marked as having no precedent is not this phase's work**; they are recorded in
`Plan_Blowout_Alignment.md`'s `Coverage gaps` for `Plan_System_Buildout.md`.

| # | Trigger shape | Sketched effect behind it | Precedent |
|---|---|---|---|
| 1 | A status expires | Overflow's AoE, Rush's self-Stun | shipped |
| 2 | A status expires and propagates | Plague's spread | shipped |
| 3 | A status lands on a character | Mirror Coat's reflection | shipped |
| 4 | A character gains a buff | Bar Brawler's "On the House!" (with its own once-between-turns guard) | shipped |
| 5 | An enemy gains a buff, places a zone, or lands a debuff | Emissary's Standing Record Infractions | shipped |
| 6 | A critical hit lands | Appraiser's Strike the Flaw applying Cracked Facet | shipped |
| 7 | A kill lands | Cultist's Chosen Vessel re-marking on Vessel death | shipped |
| 8 | A character enters a zone | zone trigger, once per visit (3.2.4.1) | shipped |
| 9 | A stack count crosses a threshold | Arcane Instability's max-stack Surge, Calibration's tiers | shipped |
| 10 | Turn-bar movement passes a fraction | Temporal Leak's continuous ticks | shipped |
| 11 | Health crosses a threshold | a debuff that detonates when the target drops below half | **none** |
| 12 | Status count crosses a threshold | a payoff for saturating a target to the eight-status cap | **none** |
| 13 | Another cascade instance lands | the compounding 1.1.3 names outright | **none** |
| 14 | A skill cast repeats | see Repetition below | **none** |
| 15 | A status or zone detonates for its remaining quantity | see Repetition below | **none** |

Five of the fifteen have no existing mechanic behind them. That is the point of sizing against
a sketch: a vocabulary settled against Overflow and Plague would express neither a threshold
crossing, nor cascade-on-cascade, nor repetition.

### Repetition — instance count as a multiplier on channels 1 and 2

Two shapes deserve their own section, because they are the ones that make cascade a *channel*
rather than a garnish, and because they constrain the architecture in ways the other thirteen
do not:

- **Repeat a skill cast.** The repeated cast re-reads channels 1 and 2 rather than copying a
  computed number, so instance count becomes a third multiplier stacked on the other two —
  precisely the compounding 1.1.3 describes: "instance count and modifier size compound
  against each other."
- **Detonate for remaining quantity.** A debuff that, when triggered, deals damage and is
  removed, resolving once per point of remaining duration. The zone variant resolves once per
  remaining charge. Each of the X instances applies channels 1 and 2 afresh, so the shape
  converts a resource the player spent turns building into a multiplier rather than a sum.

Three architectural consequences follow, and the design below answers each:

1. **Fan-out needs a bound separate from the depth cap.** X instances at one depth is breadth,
   not depth — a depth cap does not constrain it at all.
2. **The per-originating-action dedup rule has to admit deliberate repetition.** Read naively,
   "each trigger source resolves at most once per originating action" forbids X instances from
   one detonation outright and kills the shape.
3. **A count read from a live quantity must be snapshotted when the trigger fires.** Remaining
   duration and remaining charges both change while the instances resolve — the debuff is being
   removed, the zone is spending charges.

## Design (confirmed decisions)

- **A `CascadeResolver` helper, not an extension of the trait hook system.** A fourth helper
  alongside `StatusEffectResolver` and `ZoneResolver`, constructed in `BattleResolver._init`
  and reached through a `GetCascadeResolver()` accessor, matching the existing pair.
  `Types.Combat_Event` was considered and rejected as the vehicle: its contract is the trait
  `_execution_steps` gate with a fixed `(character_ID, resolver)` signature, and cascade
  subscribers are statuses, zones, and skill effects as well as traits. Widening it would mean
  one enum with two incompatible dispatch contracts.
- **Triggers post; the resolver drains.** Trigger points call `Post(event)` and return
  immediately; the queue drains after the current resolution completes rather than recursing on
  the call stack. This is what gives the two termination rules a single enforcement point, and
  what gives Phase 4 an instance boundary to pace on. The four existing effects already
  collect-then-resolve for their own reasons — the drain generalizes a pattern the code
  arrived at four times independently.
- **Listeners are keyed by mechanic identity**, as a `StringName` — the same currency
  `CombinedDamageModifier` uses for its bucket keys. The composition law in 1.1.3 then reads as
  one concept across both channels rather than two parallel notions of which mechanic a
  contribution belongs to. Character identity never enters the key, per 1.1.3.
- **The dedup set keys the trigger firing, not the instances it yields.** A trigger source
  fires at most once per originating action and yields an instance count; the listener does not
  re-trigger itself N times. This satisfies 1.1.4 as written while leaving repetition
  expressible.
- **Two independent bounds.** `MAX_CASCADE_DEPTH` bounds chain length (posts made from inside
  an instance carry depth + 1 and are refused at the cap). `MAX_CASCADE_INSTANCES_PER_ACTION`
  bounds total fan-out across the whole originating action, which is the bound a count-driven
  repeat is checked against. Neither substitutes for the other.
- **Instance counts are snapshotted when the trigger fires**, before any instance resolves.
- **Each instance builds its own `CombinedDamageModifier`.** Technical Design Document 7.4
  already states one is "built fresh for one damage resolution and discarded with it… so a
  cascade's repeat instances each read live conditions rather than a stored product." For the
  repetition shapes this is load-bearing rather than incidental: re-reading channels 1 and 2
  per instance is the entire mechanic.
- **Existing call-stack recursion stays out of scope.** `_EmitTurnBarBump`'s tail recursion and
  `_HandleDeath`'s `On_Death` / `Ally_Death` hooks are not ported and not bounded by this work.
  They are named here so the omission is a decision rather than an oversight.

## Implementation

Ordered so the suite stays green at each step. Steps 1–3 add an unused system; step 4 is the
first behaviour change.

1. **`Scripts/Battle/cascade_event.gd`** — `CascadeEvent extends RefCounted`, a flat union
   record in the same style as `CombatResult`: `trigger` (`Types.Cascade_Trigger`),
   `subject_ID`, `origin_ID`, and the payload fields the ledger's shapes need (`buff_type`,
   `debuff_type`, `zone_ID`, `fraction`, `amount`, `instance_count`). New
   `Types.Cascade_Trigger` enum in `Scripts/common_enums.gd`, appended at the end so no
   existing `.tres` numeric values shift.
2. **`Scripts/Battle/cascade_resolver.gd`** — `CascadeResolver`, holding the listener registry
   (keyed by trigger, each record carrying a mechanic-identity `StringName` and a `Callable`),
   the pending queue, the per-originating-action dedup set, and the instance counter.
   `Subscribe`, `Post`, and a `Drain` the resolver calls. `MAX_CASCADE_DEPTH` and
   `MAX_CASCADE_INSTANCES_PER_ACTION` live here. Follow the established helper-resolver shape:
   a `_resolver` back-reference reaching into `_resolver._characters` / `_Emit` / `_BeginBatch`,
   as `StatusEffectResolver` and `ZoneResolver` already do.
3. **Drain point and batching.** `BattleResolver._EndBatch` drains at `_batch_depth` 0, so
   cascade results land in the originating action's batch — what `ResolveSkill`'s array return
   and every existing test read. The dedup set and instance counter clear at the same boundary.
   Note the drain must itself run inside the batch, so the depth accounting needs care: drain
   before decrementing to zero, not after.
4. **Port the four.** Overflow (expiry → AoE), Plague (expiry → spread), Rush (expiry →
   self-Stun), Mirror Coat (status landed → reflect), each from a hardcoded branch in
   `status_effect_resolver.gd` to a registered listener. Two decisions to make while porting,
   both currently open (see below): whether registration is data-driven via a new
   `StatusEffectData` field or stays in code, and whether `_SpreadPlague` keeps bypassing
   `ApplyDebuff`. Arcane Instability's Surge is a candidate but is left alone — it is a kit
   question Phase 5 owns.
5. **Result stream.** New `CombatResult.Kind.Cascade_Triggered`, emitted immediately before
   each instance resolves, carrying the trigger, the listener's mechanic identity (in `text`),
   and the depth; plus a new `cascade_depth: int = 0` field set on every result produced inside
   an instance. Both follow the flat-union style the file already uses, the way
   `combined_damage_modifier` was added by Phase 1. `Scripts/Battle/battle.gd`'s handler gains
   a no-op branch for the new kind — actual pacing is Phase 4's work and this plan must not
   pre-empt it.
6. **Tests** (`Tests/unit/test_cascade_resolution.gd`, plus updates to the existing files).
   Use the `make_empty_skill()` idiom already established for both existing cascades: the
   depth cap refuses a self-re-entering listener; the fan-out cap bounds a listener that yields
   a large instance count; a trigger source fires once per originating action but its N
   instances all resolve; a snapshotted count is unaffected by the quantity draining as
   instances resolve; each instance carries a distinct `CombinedDamageModifier` reflecting
   conditions live at that instant; `Cascade_Triggered` brackets each instance in the stream.
   `Tests/unit/test_overflow_wanderlust.gd` and `Tests/unit/test_bleed_plague_ticks.gd` must
   still pass unchanged after the port — that is the regression proof.

### Invariants the port must not break

- **Health is mutated before the result is emitted.** `Tests/unit/test_health_result_ordering.gd`
  connects to `result_produced` and snapshots `_current_health` at emit time. Deferring
  resolution to a drain must not defer the mutation past the emit.
- **Seed reproducibility.** `Tests/unit/test_battle_resolver.gd`'s
  `test_same_seed_reproduces_the_same_battle` compares two runs result-by-result. Moving
  Overflow and Plague from inline to drained changes random-draw ordering; the port either orders
  the drain to preserve the existing sequence or re-baselines that test deliberately. Decide
  before writing code, not when the test goes red.
- **The status cap still gates cascade-applied statuses.** `Skills.HasMaxStatusEffects` gates
  six call sites today, `_SpreadPlague` among them; a status denied by the cap emits
  `Status_Effect_Denied` rather than vanishing (1.1.4).
- **Enablers are not converted into damage channels** (1.1.3). Rush and Mirror Coat resolve
  through the cascade *system* while staying tagged `Enabler` in `Concept_Document.md` 3.2.3 —
  the system is the plumbing, not the classification. If the port makes those tags read wrong,
  flag it rather than retagging.

## Documentation

- `Technical_Design_Document.md` gains `### 7.8. Cascade resolution`, after 7.7. (Do not copy
  the 9.1 / 9.2 misnumbering that already sits under section 14.)
- `Technical_Design_Document.md` gains a `### 15.13.` entry recording the four hardcoded
  cascade paths as the weakness this work resolves, matching how 15.12 recorded the eight
  fragmented multiplicative damage inputs.
- `Concept_Document.md` 1.1.4's cascade-termination bullet is extended to name both bounds and
  the trigger-keyed dedup rule, since "each trigger source resolves at most once" read alone
  forbids the repetition shapes.
- `Plan_Blowout_Alignment.md`'s `Coverage gaps` channel-3 entry gains the shapes this plan
  sized against but did not author: repetition (repeat-a-cast, count-driven detonation),
  threshold crossings (health, status count), and cascade-on-cascade.
- `Documents/Plans/README.md` gains this plan's entry.

## Open questions

- `MAX_CASCADE_DEPTH` and `MAX_CASCADE_INSTANCES_PER_ACTION` values. Proposed 4 and 16
  respectively, as placeholders to land with — both are balance numbers that want a playable
  burst before they are settled, and the fan-out bound in particular has to accommodate a
  detonation sized by remaining duration against the eight-status cap.
- Whether cascade registration is data-driven (a new on-expiry / on-trigger field on
  `StatusEffectData`, which today has none) or stays code-registered per status type. Data-driven
  is the better fit for the status catalog and the worse fit for effects whose behaviour is not
  expressible as data; the answer may be both.
- Whether `_SpreadPlague` keeps bypassing `ApplyDebuff` on the port. Routing it through the
  normal path gives it resist rolls, Aegis, and Sequence Lock interaction, which is either a
  bug fix or a nerf depending on whether the bypass was ever intended.
- Whether a cascade instance that produces no damage (Rush's Stun, Mirror Coat's reflection)
  should emit `Cascade_Triggered` at all, or whether the marker is reserved for damage
  instances. Phase 4 is the real consumer and may have an opinion; defaulting to emitting for
  all instances is the reversible choice.
