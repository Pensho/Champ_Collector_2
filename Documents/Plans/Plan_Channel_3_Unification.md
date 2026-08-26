# Plan: Channel 3 Unification

Every Echo in the game produced by one count computation and one strength computation, so that
Channel 3 contributions stack instead of running as isolated repeat loops. `Concept_Document.md`
1.1.3–1.1.4 owns the channel contract and `Role_Kit_Design.md` owns the per-kit ledger; this plan
owns the mechanism.

## Status

Created 2026-08-25. Not started. Steps land in order, each ending with a green suite and clean
`gdlint Scripts/`, and each separately committable.

## Context

The intended model: **a Cascade is a series of X Echoes, and every Channel 3 contribution adds to
that same X.** Contributions come in two kinds — a **Cascade enabler** creates a cascade where the
action had none (The Long Furrow makes Rending Charge cascade; Borrowed Time makes a plain attacker
cascade), and a **Cascade extender** adds Echoes to a cascade that already exists (Black Thread).
An effect can be either depending on what it lands on: Borrowed Time on a plain attacker enables a
1-Echo cascade; on a Herald holding 3 Tension it extends that cascade to 4.

The implementation has no such concept. Every Channel 3 effect builds its own private repeat loop,
so contributions sit side by side instead of stacking. Audit of the full roster:

**Skill-replay cascades** (all five should feed one count on the cast's cascade):

| Effect | Role in the model | Today |
|---|---|---|
| Cut the Cloth | base, +Tension @ 90% | trait-local loop (`weft_and_warp_trait.gd:136-165`), never consults the count channel |
| Sorcerer Echo charges | base, +charges @ compounding | correct, but by coincidence of ordering |
| The Long Furrow | enabler, +1 @ 25–55% | its own standalone cascade; can't combine with another |
| Borrowed Time | enabler *or* extender, +1 @ 30–60% | always its own cascade; extra instances resolve empty |
| Black Thread | pure extender, +1 | unscoped, and misses Cut the Cloth entirely |

Four of these five contain the same nine lines — build a fresh `SkillCastContext` (use count 0,
new `TraitSkillResult`), set `repeat_bonus`, re-resolve only `DamageEffect`s. Collapsing them is
a genuine deduplication, not only plumbing.

**Echoes outside the Echo system entirely** — no `BeginEchoInstance`, so no fan-out budget, no
depth, no `Cascade_Triggered` marker, and `IsResolvingEcho()` reads false:
- Zone Echoes (`zone_resolver.gd:153-157`, used by Lantern of the Standing Ward). Threefold Bite
  therefore applies its −30% *non-Echo* penalty to a Lantern Echo, and Golden Thread never sees one.
- `ForceExtraDebuffTick` (`status_effect_resolver.gd:517`, used by `TriggerDebuffTicksEffect`) —
  a repeat of a status effect, which the definition of Echo covers.

**Comorbidity** is an enabler in exactly the same sense — it turns the Plague Doctor's damaging
debuffs into a cascade whose Echo count is the number of distinct debuff types on the target,
damaging or not, while only the damaging ones actually Echo (re-applying Blight or a stat-reducer
would do nothing). Its behavior is already correct: `_DistinctDebuffTypeCount` counts every type,
and `_ComputeDebuffTickDamage` skips any debuff without `applies_on_self_tick`, so a target with
Plague + Blight + Expose Weakness echoes Plague against a count of 3. Only its expression changes —
it is a Base contributor stated in the same vocabulary as the rest, not a hand-rolled
`instance_count`.

**Not Channel 3:** Overflow, Rush's self-Stun and Mirror Coat use the cascade machinery but are
Channel 1 (`Concept_Document.md:533`) — they keep a fixed count and stay unreachable by extenders.

**Missing implementation:** The Sealed Docket's "Echoes produced by anyone on the wearer's team
resolve at half strength" has no hook at all (`the_sealed_docket_relic.gd` is 11 lines of `Init`).

Outcome: every Echo in the game is produced by one count computation and one strength computation,
so "+1 Echo" adds one Echo to whatever cascade is running, and anything that scales Echoes scales
all of them.

**Decided with the user:** add a strength channel alongside the count channel; prevent Golden
Thread's self-feed by an explicit mechanic-key exclusion rather than by plumbing accident; a pure
extender reaches only the cascade the caster's own skill produced (`Skill_Resolved`), never a
status-triggered one; `ForceExtraDebuffTick` becomes a real Echo.

---

## Governing principle: one plumbing for every Echo

The root cause of every defect above is that producing an Echo was easy to do privately. Five
mechanics each grew their own loop because nothing stopped them, and each new one silently failed
to compose with the others. The structural goal is therefore stronger than fixing the five cases:

> **`CascadeResolver` is the only thing in the codebase that produces an Echo.** Every Channel 3
> effect — skill repeat, status re-tick, zone re-trigger — declares a contribution and a
> resolution, and never runs its own loop.

Consequences carried through the steps below:

- `BattleResolver.BeginEchoInstance` / `EndEchoInstance` are called from exactly one place,
  `CascadeResolver`'s instance loop. Nothing else calls them, so the fan-out bound, the depth
  bound, the `Cascade_Triggered` marker, `IsResolvingEcho()`, the strength channel and the
  `Cascade_Instance_Resolved` broadcast are unbypassable rather than merely conventional.
- The two paths that currently produce Echoes without touching the cascade channel at all
  (zone Echoes, forced debuff ticks) post events like everything else rather than being wrapped
  in `BeginEchoInstance` at their call sites (Step 6).
- A mechanic whose Echo is not a skill replay supplies a `resolve` callback; it still does not own
  the loop, the count, or the bounds. Today that is Comorbidity's re-tick, the Sorcerer's
  zone-amplification branch, the zone re-trigger and the forced debuff tick — four callbacks, one
  loop.
- Enforced by a test, not by discipline (Step 8): assert that no script outside
  `cascade_resolver.gd` references `BeginEchoInstance`. A future kit that reaches for a private
  loop fails the suite instead of shipping a sixth isolated handler.

## Step 1 — `cascade_resolver.gd`: enablers, extenders, and one attribution table

**Files:** `Scripts/Battle/cascade_resolver.gd`, `Scripts/Battle/cascade_event.gd`

Replace `SubscribeInstanceModifier` (`Array[Callable] -> int`) with a first-class contribution
model for the `Skill_Resolved` cascade.

New record `CascadeContribution` (own file, `Scripts/Battle/cascade_contribution.gd`):
```
mechanic_key: StringName
instances: int = 0
strength_multiplier: float = 1.0   # the intrinsic per-Echo strength this mechanic defines
kind: Kind                         # Base | Extender
resolve: Callable                  # optional; null means the canonical skill replay
```

`SubscribeCascadeContributor(callback: (CascadeEvent) -> CascadeContribution)` replaces both
`SubscribeInstanceModifier` and the per-mechanic `Subscribe` calls that skill-replay mechanics use
today (Sorcerer, Long Furrow, Borrowed Time). Contributors returning `null` or zero instances are
inert.

Resolution of a `Skill_Resolved` event:
1. Query every contributor. Sum `Base` instances and `Extender` instances separately.
2. **If no Base contributed, Extenders contribute nothing** — an extender extends, it cannot
   enable. This is the rule that makes Black Thread a pure extender and Borrowed Time dual-role.
3. Build the **attribution table**: each Base owns a slice of `instances` at its own
   `strength_multiplier` and `resolve`. Extender instances append to the slice of the Base with the
   most instances (ties resolved by registration order) — the cascade's dominant mechanic. So Black
   Thread's extra Cut the Cloth Echo is another 90% Cut the Cloth Echo, not a 100% one.
4. Loop the total, calling `BeginEchoInstance` per instance with that slice's strength; still
   truncated by `MAX_CASCADE_INSTANCES_PER_ACTION` and refused past `MAX_CASCADE_DEPTH`.

Contributors are queried for any trigger, so Comorbidity can express itself as a Base on
`Debuff_Ticked` (Step 4). **Extenders are queried only for `Skill_Resolved`** — that one
restriction is what keeps Black Thread off status cascades and makes
`Concept_Document.md:533`'s claim that Overflow "never yields an Echo count that can vary" true
without a separate flag.

`Subscribe` (unchanged shape) stays for the mechanics that are not Channel 3 and keep a fixed
count with their own callback: Overflow and Rush's expiry (`Status_Expired`) and Mirror Coat
(`Status_Landed`).

New `SubscribeStrengthModifier(callback: (CascadeEvent, StringName) -> Contribution)`: a scalar
applied to **every** Echo its scope matches, on any path, multiplied on top of the slice strength.
This is where the Herald's "+X% on Echoes" and The Sealed Docket's team-wide ×0.5 live.

## Step 2 — The canonical skill replay

**File:** `Scripts/Battle/battle_resolver.gd`

Add `ResolveSkillEcho(p_caster_ID, p_skill_ID, p_target_IDs, p_strength_multiplier)`: builds a
fresh `SkillCastContext` (use count 0, new `TraitSkillResult`), sets `repeat_bonus =
strength - 1.0`, and re-resolves only `DamageEffect` entries whose `ConditionMet` holds. This is
the default `resolve` for any contribution that does not supply one, and it replaces the four
near-identical copies in `weft_and_warp_trait.gd:158-164`, `sorcerer_trait.gd:135-142`,
`the_long_furrow_relic.gd:56-64` and `status_effect_resolver.gd:500-514`.

The Sorcerer's zone branch (`sorcerer_trait.gd:123-125` — amplify the zone this cast placed
*instead of* dealing damage) is the one genuine non-replay case and supplies its own `resolve`.

## Step 3 — Echo strength reaches `DamageEffect`

**Files:** `battle_resolver.gd`, `Scripts/Battle/Skill_Effects/damage_effect.gd`

`BeginEchoInstance` is already the single choke point every Echo path calls (commit b8d5a3e);
make it the choke point for strength too:

- Signature gains `p_strength_contributions: Dictionary[StringName, float] = {}` — keyed by
  contributing mechanic, so `Concept_Document.md`'s composition law (contributions group by
  mechanic identity; distinct mechanics multiply) is preserved rather than collapsed into one
  anonymous scalar.
- Push/pop it alongside `_echo_depth_stack`; expose `CurrentEchoStrengthContributions()`.
- `DamageEffect.Resolve` contributes each entry to `CombinedDamageModifier` under its own key,
  beside the existing `repeat_bonus` bucket (`damage_effect.gd:34-35`). Every Echo path picks this
  up for free, including ones that build their own context.

`repeat_bonus` keeps its current job — the *intrinsic* strength a mechanic defines for its own
Echoes. External scalars go through the new channel. Do not merge the two.

## Step 4 — Port the five skill-replay mechanics to contributors

- **Cut the Cloth** (`weft_and_warp_trait.gd`): delete `_ResolveExtraCutTheClothInstances` and the
  `Skill_Effects_Resolved` hook. `OnSkillCast` keeps banking `_pending_cut_the_cloth_instances =
  _tension` and zeroing Tension; a Base contributor returns those instances at strength 0.9 (moved
  out of `Cut_the_Cloth.tres`'s scaling if that is where the 90% lives — check before moving).
  Watch: zero Tension yields zero Echoes (the base cast is not an Echo), and the pending counter
  must clear even when the contributor never fires.
- **Sorcerer** (`sorcerer_trait.gd`): one Base contributor returning `_echoes_for_this_cast` at
  `REPEAT_FRACTION * compounding^index`. Since strength now varies per Echo within one slice,
  `CascadeContribution.strength_multiplier` needs a per-index form — either a `Callable(index) ->
  float` alongside the flat float, or keep the Sorcerer on a custom `resolve` that reads its own
  `_echo_index`. Prefer the latter: it changes less and the compounding is genuinely the mechanic's
  own business.
- **The Long Furrow** (`the_long_furrow_relic.gd`): Base contributor, 1 instance at `Magnitude()`,
  gated on the existing `_charge_span` check. It becomes combinable — a Lancer with Long Furrow and
  Borrowed Time now gets one 2-Echo cascade instead of two 1-Echo ones.
- **Borrowed Time** (`status_effect_resolver.gd`): Base contributor, 1 instance at `buff.value`,
  gated on the holder carrying the buff and `_CastSkillHasDamageEffect` (keep as-is). Consumes the
  buff. Consumption must happen at most once per action even though contributors may be queried
  more than once — guard with a per-action flag in the same shape as the `"mechanic_key:subject_ID"`
  dedup set. Delete the `Subscribe`d listener and `_CascadeBorrowedTime`. Being a Base, it enables
  on a plain attacker and extends on a Herald, with no code distinguishing the two cases.
- **Comorbidity** (`status_effect_resolver.gd`): Base contributor on `Debuff_Ticked`, replacing
  `_PostComorbidityCascadeIfAny`'s hand-rolled `instance_count`. Keeps its own `resolve`
  (`_CascadeComorbidityRetick` — a debuff re-tick, not a skill replay), its per-source keying, and
  its current count (all distinct debuff types; only damaging ones re-tick). Behavior-preserving —
  this step is about expressing it in the shared vocabulary, so its tests must stay green
  unchanged.
- **Black Thread** (`weft_and_warp_trait.gd`): Extender contributor, 1 instance, once per
  originating action (reset in `OnSkillCast`), keeping the owner-is-caster and concerns-an-enemy
  guards. **Self-only, never external:** it extends the Herald's own cast and nothing else — not an
  ally's cascade, not an enemy's. The owner-is-caster guard is what enforces this and must be
  asserted, not merely present. Because contributors are queried only for `Skill_Resolved` and
  extenders need a Base, it also can no longer inflate Comorbidity, Mirror Coat or Overflow.

## Step 5 — Herald: Golden Thread exclusion and a genuinely generic self-bonus

**File:** `weft_and_warp_trait.gd`

- Add `mechanic_key: StringName` to `CascadeEvent`, stamped before
  `_NotifyCascadeInstanceResolved`. `OnCascadeInstanceResolved` returns early on
  `&"Cut the Cloth"`. Replaces today's "prevented by construction" arrangement, which stops being
  true once Cut the Cloth joins the channel.
- The self-bonus moves from Cut the Cloth's local `_damage_multiplier` to a
  `SubscribeStrengthModifier` scoped to Echoes the Herald produced — making
  `Role_Kit_Design.md:435-437`'s "applies to any Echo the Herald produces" true, which it is not
  today.

## Step 6 — The two uncounted Echo paths

**Files:** `Scripts/common_enums.gd`, `zone_resolver.gd`,
`Scripts/Character/character_traits/Relics/lantern_of_the_standing_ward_relic.gd`,
`status_effect_resolver.gd`, `Scripts/Battle/Skill_Effects/trigger_debuff_ticks_effect.gd`

Both join the channel properly rather than being wrapped at their call sites — per the governing
principle, neither may call `BeginEchoInstance` itself.

- Add `Types.Cascade_Trigger.Zone_Triggered` and `Types.Cascade_Trigger.Debuff_Tick_Forced`.
- Lantern of the Standing Ward posts a `Zone_Triggered` event (zone ID, affected character) with a
  Base contribution of 1 instance at `Magnitude()`, whose `resolve` calls
  `ZoneResolver.ResolveZoneEffectEcho`. `ResolveZoneEffectEcho` loses its bounds responsibility
  entirely and becomes a plain "resolve this zone against this character at this strength".
- `TriggerDebuffTicksEffect` posts a `Debuff_Tick_Forced` event per target with a Base contribution
  of 1 instance, whose `resolve` is the existing `ForceExtraDebuffTick` body. Note the ordering
  consequence: a forced tick that itself enables a Comorbidity cascade now nests one level deeper,
  which `MAX_CASCADE_DEPTH` (4) accommodates — verify it in a test rather than assuming.

Consequences to verify rather than suppress: Threefold Bite stops applying its −30% non-Echo
penalty to these, Golden Thread now sees them, and they consume fan-out budget.

## Step 7 — The Sealed Docket's drawback

**File:** `the_sealed_docket_relic.gd`

Add a `Start_Combat` execution step (the pattern `the_long_furrow_relic.gd:23-30` uses) that
registers a `SubscribeStrengthModifier` returning 0.5 for every Echo produced by anyone on the
wearer's team, checked against `CombatSides`.

## Step 8 — Tests

Update: `test_cascade_resolution.gd`, `test_weft_and_warp_trait.gd`, `test_borrowed_time.gd`,
`test_time_tithe_trait.gd`, `test_sorcerer_trait.gd`, `test_relic_effects_echo_zone_reagent.gd`.

New coverage (logic only — assert Echo *counts* and per-Echo strengths, not description text):

- **Enabler vs extender.** Borrowed Time on a plain attacker → exactly 1 Echo at the buff's
  fraction. Black Thread on a plain attacker → 0 Echoes (an extender cannot enable). Black Thread
  on a Herald with 0 Tension → 0 Echoes.
- **Stacking is additive on one cascade.** Herald at N Tension: N Echoes; +Black Thread: N+1;
  +Borrowed Time: N+2. All in one cascade at one `cascade_depth`.
- **Enablers combine.** Lancer with The Long Furrow *and* Borrowed Time casting Rending Charge at
  qualifying range → one cascade of 2 Echoes, one at 25–55%, one at 30–60%.
- **Attribution.** Extender Echoes inherit the dominant Base's strength: on a Herald, Black
  Thread's Echo is at Cut the Cloth's 90%, while Borrowed Time's is at its own fraction.
- **Comorbidity is unchanged in behavior.** A target carrying Plague, Blight and Expose Weakness
  echoes Plague against a count of 3; Blight and Expose Weakness contribute to the count and
  produce no damage of their own. Existing Comorbidity tests pass without edits.
- **Extenders cannot reach status cascades.** Black Thread does not change the instance count of a
  Comorbidity re-tick, an Overflow expiry, or Mirror Coat.
- **Black Thread is self-only.** A Herald on Black Thread adds no Echo to an ally's cascade (a
  Sorcerer's Echo charges, a Lancer's Long Furrow) or to an enemy's — only to its own cast.
- **Golden Thread does not self-feed:** dumping N Tension returns 0 Tension; a non-Cut-the-Cloth
  Echo on an enemy still grants 1.
- **The formerly-uncounted paths are Echoes:** a Lantern zone Echo and a forced debuff tick each
  increment the fan-out counter, set `IsResolvingEcho()`, are seen by Golden Thread, and no longer
  take Threefold Bite's −30%.
- **Sealed Docket** halves every team Echo and stacks multiplicatively with the Herald's
  self-bonus (distinct mechanic keys ⇒ separate factors).
- **Bounds hold on every path:** 7 Tension + Black + Borrowed + a zone Echo cannot exceed
  `MAX_CASCADE_INSTANCES_PER_ACTION`; depth still refuses past `MAX_CASCADE_DEPTH`, including a
  forced debuff tick that enables a Comorbidity cascade one level down.
- **A plain debuff tick posts but echoes nothing** (Step 9): a target carrying only Burning posts
  `Debuff_Ticked`, resolves 0 Echoes, and grants a Black/Golden Herald no Tension. With a
  Comorbidity-flagged debuff present the same path echoes as before.
- **The single-plumbing invariant, enforced mechanically:** a test that scans `Scripts/` and fails
  if any file other than `cascade_resolver.gd` references `BeginEchoInstance`. This is the guard
  against a sixth isolated Channel 3 handler appearing later; it is the one test here that checks
  structure rather than logic, and it is deliberate.

## Step 9 — Channel 3 trigger vocabulary

Carried from the now-deleted `Plan_System_Buildout.md`, which owned these before this plan existed.

**Every debuff tick posts `Debuff_Ticked`.** Today the only `Post` on the tick path is
`_PostComorbidityCascadeIfAny` (`status_effect_resolver.gd:459-464`), which fires only when a
Comorbidity-flagged debuff is present. That makes Step 4's Comorbidity port dishonest — a
contributor on a trigger that one mechanic also owns the posting of is not a shared channel.
Move the `Post` to the tick path itself (`_ResolveDebuffTicks` / `ForceExtraDebuffTick`), carrying
the tick's distinct-type count and repeating-source list on the event, and let Comorbidity's
contributor read them.

Note what this does *not* change: a plain Plague or Burning tick posts an event, no contributor
contributes, zero Echoes resolve, and the Herald's Golden Thread still gains nothing. That is
correct — a status's ordinary tick is not a repeat of anything, so it is not an Echo. The gap is
the missing `Post`, not the absence of Tension; the Tension behavior is the Echo definition
working as intended.

**Still open, owned by this plan, not scheduled in it:**

* **Cascade-on-cascade (an effect listening for another Echo landing).** Named by
  `Concept_Document.md` 1.1.3, no content authored against it. Under the contributor model this is
  a new `Types.Cascade_Trigger.Echo_Resolved` posted from `_NotifyCascadeInstanceResolved`, which
  already fires once per real Echo — the re-entry risk is what `MAX_CASCADE_DEPTH` exists for, and
  a contributor on this trigger must be depth-guarded rather than dedup-guarded, since the point of
  the shape is to fire repeatedly. Author it when a kit needs it.
* **Threshold-crossing (a status or zone detonating on a Health or status-count crossing).** Also
  named by `Concept_Document.md` 1.1.3 with no content behind it. Needs a trigger value and a
  `Post` call site at the crossing, plus the design decision of which status or zone claims it.

## Step 10 — Documents

Per `CLAUDE.md`'s net-neutral rule these edits replace wording rather than append to it.

- **`Concept_Document.md`** — 1.1.4's "a trigger fires once" bullet states the composition rule for
  counts (contributions to one cascade add) and the enabler/extender distinction. Restate Borrowed
  Time (`:540`), Black Thread (`:301`), and Cut the Cloth (`:791`). Comorbidity (`:333`) restated
  in the enabler vocabulary, saying explicitly that non-damaging debuff types raise the Echo count
  without echoing themselves — currently implied by omission.
- **`Technical_Design_Document.md`** — §7.8 rewritten around contributors, the attribution table,
  the canonical skill replay, and the strength channel, opening with the single-plumbing invariant
  as a stated architectural rule so a future kit reads it before reaching for a private loop.
  Delete the stale claim at `:1638-1641`
  that Borrowed Time bypasses the cascade channel (it already didn't) and the "Cut the Cloth's own
  repeats never call `Post`" sentence, which stops being true. "What counts as an Echo" gains zone
  Echoes and forced debuff ticks.
- **`Role_Kit_Design.md`** — §9.2's "enforced by construction" note (`:429-430`) replaced by the
  explicit mechanic-key exclusion; Black Thread stated as an extender, once per action, self-only;
  the Herald's self-bonus now genuinely generic. §9.9's Borrowed Time restated as an
  enabler/extender. §9.1's Plague Doctor restated in the enabler vocabulary; its projected numbers
  are unaffected.
- **`Relic_Design.md`** — The Long Furrow and The Sealed Docket's rows in the Echo coverage table
  (`:416`); clear any Placeholder marker the Docket carries now that it is implemented.
- **`Scripts/Debug/kit_contribution_manifest.gd`** — the Herald's entries at `:792-796` and
  `:812-822` describe the trait-local loop and the unscoped modifier by name; both descriptions
  become false.

---

## Verification

1. `./Tests/run_tests.sh` — full suite green. Iterate with `-gtest=` on the six touched files.
2. `gdlint Scripts/` clean (`Scripts/` only, never `Tests/`).
3. The scenario from the request, asserted directly: Herald at 3 Tension, Black Thread, holding
   Borrowed Time, casting Cut the Cloth → **5** `Cascade_Triggered` results in the `CombatResult`
   stream, at one `cascade_depth`, four at 90% and one at the Chronophage's fraction.
4. Headless only — no in-game or screenshot verification available here.

## Risk

`Role_Kit_Design.md:458-463` already flags the Herald's kit factor at 8.64x against a ~2x per-Role
target. Making Black Thread actually apply to Cut the Cloth (it does not today) raises it. That is
the design doc's stated intent, so the change stands; the new number belongs in §9.2 rather than
being absorbed quietly in code.

Everything else here is behavior-preserving except where a mechanic was already broken: Cut the
Cloth becoming reachable by extenders, Borrowed Time and The Long Furrow becoming combinable, zone
Echoes and forced debuff ticks joining the fan-out budget, and The Sealed Docket's drawback
existing at all.
