# Plan: Cascade Channel Cleanup

The follow-up plan to the Channel 3 unification (commit `fd7a910`). That commit moved every
skill-replay Echo, zone Echo and forced debuff tick onto `CascadeContribution`, but left the
old plumbing standing beside the new. This plan retires the leftovers, closes the fragility
the contributor model introduced, and brings `Technical_Design_Document.md` 7.8 back into
line with the code.

## Context

`fd7a910` is a genuine improvement — `BeginEchoInstance` is now a single choke point, guarded
by `test_begin_echo_instance_is_called_only_from_cascade_resolver`. But the refactor stopped
one step short in three places:

- **Three non-Channel-3 mechanics are resolved as Echoes.** Overflow, Rush and Mirror Coat
  still run on the old `Subscribe`/`Listener` path, which routes them through
  `BeginEchoInstance` — so they spend Channel 3's fan-out budget, emit burst markers and feed
  Golden Thread, none of which their `Concept_Document.md` channel tags entitle them to.
- **New state was added without matching the old state's rules.** `_echo_strength_stack`
  is pushed and popped alongside `_echo_depth_stack` but is absent from `_EndBatch`'s
  per-action reset, and `_StrengthContributionsFor` overwrites where
  `CombinedDamageModifier` sums.
- **Contributors are polled speculatively, and one of them mutates while being polled.**
  Cut the Cloth's banked Tension is consumed inside a query whose answer
  `_ResolveContributions` can still discard.

The suite is green today, so none of this is user-visible breakage. Phase 2's items are
latent defects; Phase 3's mis-categorization is a live rules divergence from the Concept
Document. Intended outcome: Channel 3 machinery serves only Channel 3 mechanics, one strength
channel with one composition law, no state consumed by a query, and a design doc that
describes what the code does.

**Scoped out.** `repeat_bonus` and `zone_strength_multiplier` carry a mechanic's *intrinsic*
Echo strength while `CurrentEchoStrengthContributions()` carries *external* scalars —
`Technical_Design_Document.md` 7.8 already declares that split deliberate. Only the
inconsistent bucket naming is in scope, as a nit in Phase 4.

## Status

Created 2026-08-26. Not started. Phases land in order, each ending with a green suite and a
clean `gdlint Scripts/`, and each separately committable.

## Phases

### 1. Leftovers

Mechanical; no behaviour change.

- **`Scripts/Battle/battle_resolver.gd`** — add `_echo_strength_contributions.clear()` and
  `_echo_strength_stack.clear()` to `_EndBatch`'s `_batch_depth == 0` branch, beside the
  existing `_echo_depth`/`_echo_depth_stack` reset. Push and pop are paired today, so this
  is prophylactic: the two stacks are currently maintained by different rules, and the
  invariant is one edit away from breaking silently.
- **New `Scripts/Battle/cascade_strength.gd`** — `CascadeStrength extends RefCounted`, two
  fields (`mechanic_key: StringName`, `multiplier: float`) and an `_init` taking both. Make
  it the return type of `SubscribeStrengthModifier` callbacks. This retires four meaningless
  arguments per strength call site: `CascadeContribution.new(&"Weft and Warp", 1,
  CascadeContribution.Kind.Base, 1.0 + _self_bonus)` becomes
  `CascadeStrength.new(&"Weft and Warp", 1.0 + _self_bonus)`. `CascadeContribution`'s doc
  comment then describes one contract instead of misdescribing two.
  Call sites: `weft_and_warp_trait.gd:73-77`, `the_sealed_docket_relic.gd:17-22`,
  `cascade_resolver.gd:149-157`, and the strength-modifier tests in
  `Tests/unit/test_cascade_resolution.gd`.
- **`Scripts/Battle/cascade_resolver.gd`** — drop the unused `p_mechanic_key` argument from
  the strength-modifier signature. Both implementations discard it (`_p_mechanic_key`); it
  is a carry-over from `SubscribeInstanceModifier`, where scoping by matched mechanic was
  the point. `_StrengthContributionsFor` then takes only the event.
- **`Scripts/Character/character_traits/Relics/lantern_of_the_standing_ward_relic.gd`** —
  drop the `Magnitude()` passed as `strength_multiplier` at line 26. It supplies a `resolve`
  callback, so `strength_multiplier` is never read (`cascade_resolver.gd:140-144`); the
  callback passes `Magnitude()` itself. Reads as meaningful and is not.
- **`Scripts/Character/character_traits/CharacterSpecificTraits/weft_and_warp_trait.gd`** —
  hoist `&"Cut the Cloth"` (lines 65 and 108) into a `_CASCADE_MECHANIC_KEY` const, matching
  `the_long_furrow_relic.gd` and `the_sealed_docket_relic.gd`. It currently equals the skill's
  display name matched at line 125, so renaming the skill silently unlinks the Golden Thread
  self-feed guard.
- **`Tests/unit/test_cascade_resolution.gd:332`** — the comment reads "The governing
  principle behind this plan", a dangling reference to a deleted plan file. Restate it in
  terms of the code: `BeginEchoInstance` is called from exactly one place,
  `CascadeResolver`'s own instance loop.

Tests: the existing suite must stay green — this phase adds none of its own beyond updating
the strength-modifier tests to the new `CascadeStrength` type.

### 2. Fragility

Three latent defects. Each gets a regression test.

- **A contributor query with a side effect.**
  `weft_and_warp_trait.gd:61-64` zeroes `_pending_cut_the_cloth_instances` while *answering*
  whether it contributes, but `_ResolveContributions` can discard that answer at the dedup
  `continue` (`cascade_resolver.gd:118-119`) — silently eating the banked Tension.
  Contributors are polled speculatively; consuming state inside one is unsafe by
  construction. Move the consumption into the contribution's `resolve` callback: the
  contributor reads `_pending_cut_the_cloth_instances` for its count and leaves it alone;
  the `resolve` zeroes it on the first instance. Note the ordering constraint —
  `_ResolveContributions` reads `base.instances` once before the loop, so zeroing inside
  `resolve` cannot truncate the run.
  *Test:* with the Cut the Cloth dedup key already fired for the owner this action, the
  banked Tension survives to the next Skill_Resolved rather than vanishing.
- **Extenders burn their dedup slot before a Base is known to exist.**
  `cascade_resolver.gd:117-124` claims `_fired_this_action[key]` for every contribution,
  then line 125 returns if `bases.is_empty()`. Black Thread on a Base-less `Skill_Resolved`
  is spent for the action having done nothing. Restructure: collect candidate contributions
  with their keys, decide whether any Base survives, and claim dedup slots only for the
  contributions that actually run.
  *Test:* an Extender queried on an event with no Base still contributes to a later Base
  event in the same action.
- **`TriggerZones` drains mid-batch.**
  `zone_resolver.gd:108-111` calls `Drain()` at `_batch_depth >= 1`, bypassing `_EndBatch`'s
  rule that draining happens only at the outermost batch — an undocumented exception to the
  invariant stated in `CascadeResolver`'s own header comment and in
  `Technical_Design_Document.md` 7.8. It is there only to beat the zone-cleanup loop below
  it. Fix the ordering instead of adding a second drain policy: move the spent-zone sweep
  (`_zones[ID]._charges == 0` → `ClearZone` → `BroadcastEvent(Resource_Depleted)`) into a
  helper called from `TriggerZones` after the batch closes.
  *Test:* a Lantern of the Standing Ward zone Echo on a zone spending its last charge
  resolves against the still-present zone, and the zone is cleared exactly once afterwards.
  `Tests/unit/test_relic_effects_echo_zone_reagent.gd` already covers the Echo; extend it
  with the cleanup ordering.

### 3. Separate deferred triggers from Channel 3

The core of the plan, and the one phase with game-visible consequences.

**Overflow, Rush and Mirror Coat are not Channel 3 mechanics.** `Concept_Document.md` is
explicit: Overflow is **[Channel 1]**, "a delayed area hit, not a cascade contribution";
Rush is **[Channel 1]**, a delayed self-Stun on expiry; Mirror Coat is **[Enabler]**. None of
them produces an Echo. They need the post-and-drain queue for *ordering* — Mirror Coat must
resolve after the debuff lands, Overflow and Rush after expiry — and nothing else the cascade
machinery offers.

Today they get all of it, because `_ResolveEvent`'s loop routes them through
`BeginEchoInstance`. That is one call site producing five mis-categorizations:

1. They spend `MAX_CASCADE_INSTANCES_PER_ACTION` — Channel 3's fan-out budget. Three
   expiring Overflow stacks eat 3 of 16 Echo slots that belong to Channel 3.
2. They emit a `Cascade_Triggered` burst marker, so the battle view escalates their combat
   text as Concept Document 1.1.5 burst instances.
3. They fire `Cascade_Instance_Resolved`, so the Herald's Golden Thread gains Tension off an
   Overflow detonation or a Mirror Coat reflection.
4. `_echo_depth > 0` during them, so `battle_resolver.gd:942` labels their results
   "Echo N" rather than "base hit", and `_Emit` stamps a non-zero `cascade_depth`.
5. Threefold Bite (`threefold_bite_relic.gd:17-19`) counts them toward its every-Nth-Echo
   bonus.

The fix is to name the distinction and cut the Echo instrumentation, which makes
`_ResolveEvent`'s loop shorter than `_ResolveContributions`' rather than a copy of it.

- **`Scripts/Battle/cascade_resolver.gd`** — rename the listener vocabulary to say what it
  is: `Subscribe` → `SubscribeDeferredTrigger`, `class Listener` → `DeferredTrigger`,
  `_listeners` → `_deferred_triggers`. Its loop keeps `matches`, the once-per-action dedup,
  `instance_count` fan-out and depth stamping; it drops `BeginEchoInstance`/`EndEchoInstance`,
  `EmitBurstInstance`, `_NotifyCascadeInstanceResolved` and `_StrengthContributionsFor`.
  Document at the top of the class that this path is deliberately *not* Channel 3 and that a
  mechanic tagged Channel 3 in `Concept_Document.md` belongs on the contributor path.
- **Replace the lost termination bound.** `BeginEchoInstance` was what bounded these
  triggers' fan-out. Add a per-action deferred-trigger instance counter with its own
  constant (`MAX_DEFERRED_TRIGGER_INSTANCES_PER_ACTION`), reset beside `_fired_this_action`
  in `ResetForNextAction`. Concept Document 1.1.4's bounds must hold on this path too; they
  just must not be *shared* with Channel 3's budget.
- **`Scripts/Battle/status_effect_resolver.gd`** — rename `_RegisterCascadeListeners` to
  `_RegisterDeferredTriggers`, keeping the three registrations and all three mechanic keys
  byte-identical. `_CascadeOverflow`/`_CascadeRushStun`/`_CascadeMirrorCoat` are unchanged
  bodies; rename their `_Cascade` prefix to `_Deferred` so they stop reading as cascade
  handlers.
- **`Scripts/Battle/cascade_event.gd`** — `instance_count` stays, now used only by the
  deferred path. **Load-bearing:** the count is snapshotted at `Post` time
  (`_TriggerExistingCasterBuffs` sets it from `expiring_overflows.size()`), which is what
  `test_snapshotted_instance_count_is_unaffected_by_later_mutation` asserts. Do not recompute
  it at drain time.

**Accepted behaviour changes**, each needing a test that pins the new behaviour:

- Golden Thread gains no Tension from Overflow, Rush or Mirror Coat. Narrow in practice:
  `_EventConcernsEnemyOf` falls back to `subject_ID` when `target_IDs` is empty
  (`weft_and_warp_trait.gd:137`), and all three events' subject is the status *holder* — so
  the only income lost is from an **enemy's** expiring Rush or Overflow and an enemy's Mirror
  Coat reflection. A friendly holder never granted Tension in the first place.
- Threefold Bite no longer counts them toward its Echo ordinal.
- Their results carry `cascade_depth` 0 and the "base hit" label, and emit no
  `Cascade_Triggered` marker.
- Channel 3's 16-instance budget is no longer shared with them, so a Comorbidity or Cut the
  Cloth burst in the same action as an Overflow expiry now reaches its full count.

Tests: `test_overflow_cascade_triggered_precedes_its_instance_and_carries_depth` inverts —
rewrite it to assert Overflow emits *no* burst marker and stamps depth 0.
`test_trigger_fires_once_per_action_but_yields_its_full_instance_count` and
`test_snapshotted_instance_count_is_unaffected_by_later_mutation` must pass unchanged.
Add: an Overflow expiry does not raise a Golden Thread Herald's Tension; an Overflow expiry
does not reduce the Echo budget available to a Cut the Cloth burst in the same action; the
deferred path's own fan-out bound holds.

### 4. Consolidation and documentation

- **One composition law for strength.** `_StrengthContributionsFor` does
  `contributions[key] = multiplier - 1.0` (`cascade_resolver.gd:156`) — overwrite. Two
  modifiers sharing a key, one wins silently. `CombinedDamageModifier`'s documented law is
  that same-key contributions sum into one bucket. Make it accumulate.
  *Test:* two strength modifiers on one key compose rather than one clobbering the other.
- **One helper for contributions → factor.** `status_effect_resolver._ApplyEchoStrength`
  (`:484-500`) rebuilds contributions → `CombinedDamageModifier` → `Product()` → floor by
  hand, in a different shape from `damage_effect.gd:36-39`. Add
  `CombinedDamageModifier.ContributeAll(p_contributions: Dictionary[StringName, float])` and
  call it from both.
- **Trigger filtering belongs to the registrar.** Every contributor opens with a hand-written
  `if(Types.Cascade_Trigger.X != p_event.trigger …)` — six copies, and Weft and Warp's
  strength modifier has no trigger check at all. Add an optional trigger argument to
  `SubscribeCascadeContributor`, keying `_contributors` by trigger the way `_listeners` was
  keyed, and delete the six copies.
- **`Debuff_Tick_Forced` is a command wearing an event's clothes.**
  `_ContributeForcedDebuffTick` (`status_effect_resolver.gd:540-546`) has no condition but
  the trigger and always returns one Base. With the trigger argument above it collapses to a
  registration line plus `origin_for_instance`. Also make `ForceExtraDebuffTick` private
  (`_ForceExtraDebuffTick`) — it is only ever used as a Callable, and the public name and
  `CascadeEvent` signature no longer describe an API anyone calls. Update the two
  `kit_contribution_manifest.gd` citations that name it (`:977`, `:1012`).
- **Nit — bucket naming.** `damage_effect.gd` spells intrinsic Echo strength `(repeat)` for
  skills and `(strength)` for zones. Same concept, two names in the player-facing damage
  attribution. Settle on `(repeat)` for both, or state in 7.8 why they differ.

**`Documents/Technical_Design_Document.md` 7.8** — the owner document for all of this. Under
the net-neutral rule, each edit deletes the wording it supersedes:

- Rewrite **Listener matching** and **The ported effects** as one paragraph on the
  deferred-trigger path: what it is for, that it is deliberately not Channel 3, that
  Overflow, Rush and Mirror Coat live there because their `Concept_Document.md` channel tags
  are Channel 1 and Enabler, and that it carries its own fan-out bound rather than sharing
  Channel 3's.
- Amend **Termination** for the second bound, and delete the "not reachable by the
  contributor model … which is what keeps Black Thread off Overflow, Rush and Mirror Coat"
  clause — with those three off the Echo path entirely, the extender restriction is no longer
  what protects them.
- Amend **The governing rule** — `BeginEchoInstance` is called from one place, and that place
  now resolves only Channel 3 contributions.
- Amend **Post and drain** to describe the single drain policy once Phase 2 removes the
  `TriggerZones` exception.
- Amend **The strength channel** for `CascadeStrength`, the dropped `mechanic_key` argument,
  and the accumulate-not-overwrite law.

No `Concept_Document.md` change — this plan alters no game rule.

## Verification

Per phase, from the project root:

```
./Tests/run_tests.sh
gdlint Scripts/
```

Baseline to beat: 1297 passing, 13314 asserts, clean lint. No visual or in-game verification
— this is headless combat logic.

Cross-cutting checks after Phase 3:

- `test_begin_echo_instance_is_called_only_from_cascade_resolver` must still pass; it is the
  structural guard that makes the single-plumbing claim true rather than conventional.
- `grep -rn "BeginEchoInstance" Scripts/` hits only `cascade_resolver.gd`'s contribution loop
  and `battle_resolver.gd`'s definition — the deferred path no longer reaches it.
- `Tests/unit/test_burst_reachability.gd`, `test_weft_and_warp_trait.gd`,
  `test_sealed_docket_relic.gd`, `test_zone_skills.gd` and
  `test_relic_effects_echo_zone_reagent.gd` are the kits riding this plumbing; all five must
  pass unchanged except where a phase names an addition.

## Watch for

- Contributor registration order is load-bearing: `_ResolveContributions` breaks
  dominant-Base ties by it. Keep the registration order in `status_effect_resolver.gd` stable
  and say so in a comment.
- Phase 3 removes Overflow's and Mirror Coat's burst markers. If the battle view reads
  visibly worse for a delayed area detonation with no marker at all, the answer is a
  presentation-only marker distinct from `Cascade_Triggered`, not putting them back on the
  Echo path.
- `CascadeEvent` is a growing union (`distinct_debuff_type_count`, `repeating_source_ids`,
  and `instance_count`). Consistent with the file's stated flat-union style, but it grows
  every time a contributor needs private state. If it takes a fourth mechanic-specific field,
  that is the signal to reconsider the shape rather than add a fifth.
- Phase 1's `_EndBatch` reset and Phase 4's accumulate change are both invisible to the
  current suite by construction — they exist to stop a future edit from breaking silently.
  Each needs its own test, not just a green run.

## On completion

Per `README.md`: run `/review-implementation` against the plan, apply the
`Technical_Design_Document.md` 7.8 edits Phase 4 names, and delete this file with `rm`.
