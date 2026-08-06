# Plan: Channel Population Rework

Spawned by `Plan_Blowout_Alignment.md` Phase 5, carrying forward the ranked prescriptions
`Plan_Kit_Burst_Reachability.md` Phase 6 quantified. That plan built the machinery (a kit
contribution manifest and a burst-reachability scorer, Technical Design Document 7.10) and used
it to measure the roster as it stands, not to rework anything — this plan is the rework the
machinery's findings call for.

## Status

Not started.

## Context

The full `C(20,3) = 1140`-team sweep (`Tests/manual/team_corpus_sweep.gd`, which reduces the
known preset roster to one preset per Role via `TeamSweep.DedupeByRole` before scoring — several
presets field the same Role's kit, e.g. `Centaur_Lancer.tres` and `Knight.tres` both field
Lancer, and scoring both would only add duplicate-kit teams) found the roster's
combined-modifier-product distribution at median 1.40x, 90th percentile 2.80x, maximum 5.60x —
against `Concept_Document.md` 1.1.2's 26x aggregate target, roughly 4.6x short at the product
level even at the ceiling. The gap between the 90th percentile and the maximum is one pairing
repeated across every top-decile team (Tidal Corsair's Wrangle the Sea composed with Tactician's
unconditional Daunting Strength grant), not a spread of distinct pairs: no other pair in the
roster reaches a second distinct Channel-2/3 key at all. That is a single point of failure, not
a discriminating top tail — the roster currently has one detonating pairing, not a roster where
assembling the right team is a discovery.

Phase 6 of `Plan_Kit_Burst_Reachability.md` quantified four candidate fixes against this sweep,
each re-run through the real scorer against a modified manifest copy, ranked by ceiling delta per
unit of work:

1. **Retune every existing Channel-2/3 magnitude uniformly** — including an Enabler-classed
   entry's `granted_status` magnitude (Tactician's Fatal Flaw grants Daunting Strength, a real
   Channel-2 factor once it lands on a teammate, carried on an Enabler-classed manifest entry) —
   the largest single-unit-of-work ceiling gain (+1.71x at a modest 1.25x patch); reaches 26x at a
   3.03x uniform multiplier (Wrangle the Sea's Steel stacks to 5.45 from 1.8, Daunting Strength to
   3.03 from 1.0). No stack-cap guardrail is implicated (the guardrail governs stack *count*, not
   magnitude-per-stack).
2. **Populate channel 3** via `CascadeEvent.instance_count` on a repeating skill — the next
   largest ceiling gain per unit of work (+1.20x modeled on Quarantine Breach, at K=16), though it
   stays flat until instance counts get large (K=16, the per-action cascade cap, before the
   ceiling moves at all). Needs no new `Types.Cascade_Trigger` value; repetition is already
   expressible.
3. **Spread a `bonus_per_debuff_on_target` hook across more Channel-1-only skills** — no change to
   median, 90th percentile, or ceiling at any tested count. An isolated hook only ever composes
   with Tactician's unconditionally granted Daunting Strength, short of even the 90th-percentile
   threshold, let alone the ceiling.
4. **Add a distinct Channel-2 key to each zero-contribution kit** (Herald of the Loom, Bloodmage)
   — same zero-delta outcome as (3) and for the identical reason: nothing in the roster composes
   with Tidal Corsair's own caster-gated Wrangle the Sea, so a factor on a different character's
   skill can only ever add to Tactician's lone team-wide grant, never to the actual ceiling pair.

Prescriptions (3) and (4) are not failures of the mechanism — they are the sharpest form of the
finding: the roster needs a *second* character that composes with Tidal Corsair specifically (or
a wholly separate ceiling pairing not gated on Tidal Corsair at all), not more factors that only
ever stack onto Tactician's grant.

Two known implementation bugs, found while building the manifest and left uncorrected there
(`Scripts/Debug/kit_contribution_manifest.gd`) and in `Concept_Document.md` 3.1.3/3.2.4.2 per
section 1.1's precedence rule, are free wins in the same direction — each is a kit that already
has design intent for a working Channel-1 or Channel-2 contribution, currently shipping inert:

* **Lancer's Reckless Momentum** matches "offensive skill" and "defensive skill" against a
  hardcoded name set (`lancer_trait.gd`) that doesn't reach the Lancer's own kit: the offensive
  set names "Stab" (a Thief skill) instead of "Lance Thrust", so only Disarm actually grants
  Momentum among Lancer's three skills; the defensive set is never populated by any preset, so
  Phalanx Guard is unreachable and Momentum stacks accrue but are never spent.
* **Plague Doctor's Comorbidity** sets its tick-bonus parameter on every cast, but the zone-trigger
  debuff path Miasma uses (`StatusEffectResolver.ApplyDebuff`) hardcodes `tick_bonus_per_debuff =
  0.0` and never reads it — Comorbidity is structurally inert on the kit's own signature,
  self-ticking debuff regardless of rarity.

Neither bug moves the current ceiling pairing (both are Channel-1/passive-adjacent effects, not
new Channel-2/3 keys), but both are pure downside with no offsetting cost to fix, and fixing
Comorbidity in particular gives the Plague Doctor kit a working per-debuff-count multiplier that
did not previously exist anywhere the scorer could see it.

## Phases

### Phase 1 — Fix the two known implementation bugs

Fix `lancer_trait.gd` so `OFFENSIVE_SKILL_NAMES`/`defensive_skill_names` (or an equivalent
role-relative check) actually match the Lancer's own three skills, and fix the zone-trigger debuff
path (`StatusEffectResolver.ApplyDebuff`) to thread `tick_bonus_per_debuff` through so Comorbidity
reaches Miasma. Re-run `Tests/manual/team_corpus_sweep.gd` after each fix to confirm what, if
anything, moves — neither is expected to move the ceiling pairing, but both remove a currently
inert design intent. Update the two `Concept_Document.md` notes this plan's predecessor added
(3.1.3 Lancer, 3.1.3 Plague Doctor / Comorbidity) from "known bug" to reflect the fix, or delete
the note if the fix makes the shipped behavior match the description exactly.

### Phase 2 — Populate channel 3

Design and implement a repeating Channel-3 contribution via `CascadeEvent.instance_count` on a
candidate direct-damage skill (Phase 6 modeled this on Quarantine Breach; confirm or pick a
different skill against current kit identity). Bounded by the existing
`CascadeResolver.MAX_CASCADE_DEPTH` and `MAX_CASCADE_INSTANCES_PER_ACTION` — no new architecture,
per `Plan_Blowout_Alignment.md`'s `Coverage gaps` repetition entry. Add the resulting entry to
`Scripts/Debug/kit_contribution_manifest.gd` and re-run the sweep to measure the actual ceiling
and median delta against the modeled +1.20x.

### Phase 3 — Decide on a retune, and re-measure against 26x

With Phase 1 and 2 landed, re-run the sweep. If the ceiling still falls meaningfully short of 26x,
decide whether a targeted (not uniform) retune of the specific ceiling-pair magnitudes is
acceptable, sized against the actual remaining gap rather than the 3.03x uniform figure Phase 6
computed against the unmodified baseline. If no combination reaches 26x, that stays a coverage
gap for `Plan_System_Buildout.md`, not a further rework here.

## Watch for

* **Do not uncap Momentum, Arcane Instability, or Steel and Sea** — `Concept_Document.md` 1.1.4
  caps them correctly; none of the above prescriptions touch their caps.
* **A high-scoring roster is not the goal; a discriminating one is.** A retune or new factor that
  lifts the median as much as the ceiling fails the realisation requirement even if it reaches
  26x — re-check the median on every change, not only the ceiling.
* **Verify every change through `Scripts/Debug/burst_reachability.gd`'s sweep, not by hand** — the
  entire point of the machinery this plan consumes is that a kit change is one manifest edit and
  a sweep re-run, not a hand computation.
* Spell words out in full in identifiers and prose, per the naming convention.

## Verification

* `Tests/run_tests.sh` green, including the existing `test_burst_reachability*.gd` suite updated
  for any new manifest entries.
* `gdlint Scripts/` clean.
* `Tests/run_tests.sh -gtest=res://Tests/manual/team_corpus_sweep.gd -gexit` re-run after each
  phase, with the resulting median/90th-percentile/ceiling recorded in this plan's Status.
* Phase 1's two bug fixes each have a passing regression test proving the fixed trigger path
  (Lancer's own skills grant Momentum and Phalanx Guard; Comorbidity's tick bonus reaches a
  zone-triggered debuff).
