# Plan: Kit Burst Reachability

Replaces `Documents/Plans/Plan_Kit_Blowout_Audit.md` and `Documents/Plans/Plan_Kit_Reworks.md`,
both of which are deleted when this plan lands. Phase 5 of `Plan_Blowout_Alignment.md`.

## Status

Phase 1 (kit contribution manifest), Phase 2 (the scorer), Phase 3 (live verification),
Phase 4 (team corpus slot), Phase 5 (distribution sweep), and Phase 6 (prescription) are
done. Phase 7 (documentation and handoff) is next.

Phase 4 note: seeding the provisional corpus required actually running the C(20,3) = 1140
sweep, not just naming it. The sweep lists the full known preset roster and reduces it to one
preset per Role via `TeamSweep.DedupeByRole` before scoring, rather than hand-curating the list:
several presets field the same Role's kit (e.g. `Centaur_Lancer.tres` and `Knight.tres` both
field Lancer — identical trait and three skills, per `kit_contribution_manifest.gd`'s Lancer
entry), and scoring more than one preset per Role would only add duplicate-kit teams to the
sweep without adding information; deduplicating at run time also means a future preset sharing
an existing Role is excluded automatically. A bare `-s Scripts/Debug/*.gd` SceneTree script
cannot do this —
`Character.new()` (which `BurstReachability.ScoreTeam` calls) permanently fails under that
entry path, because `character.gd`'s reference to the `main` autoload can't resolve before a
custom main-loop script's own static dependency graph compiles. `blowout_calibration.gd`
never hits this (it never touches `Character`); the GUT test suite doesn't either, since it
runs through `addons/gut/gut_cmdln.gd`, a different bootstrap path. The sweep therefore lives
at `Tests/manual/team_corpus_sweep.gd`, a GUT script run explicitly (not part of the default
`Tests/unit/` suite) via `Tests/run_tests.sh -gtest=res://Tests/manual/team_corpus_sweep.gd
-gexit`. It scored all 1140 teams in under a second. Phase 5's own sweep should use the same
entry path.

Phase 4 finding, for Phase 5 and Phase 6 to pick up: the sweep's top 10 teams by contrast ratio
are all the same pairing — Tidal Corsair's Wrangle the Sea (1.8) composed with Tactician's
unconditional Daunting Strength grant (Fatal Flaw), (1 + 1.8) * (1 + 1.0) = 5.6x product, 14.3x
contrast ratio — with an interchangeable, non-contributing third slot. No other pair in the
roster reaches a second distinct Channel-2/3 key at all. That is a single point of failure, not
a healthy top tail: Phase 5's histogram should be expected to show one narrow spike rather than
a distinct tail, and Phase 6 should treat "give a second kit a reachable Channel-2/3 key" as the
highest-priority prescription rather than retuning the Tidal-Corsair/Tactician pair further.

Phase 5 finding, confirming the above: the full-roster sweep's combined-modifier-product
distribution is **median 1.40x, 90th percentile 2.80x, max 5.60x**. The gap between the 90th
percentile and the max is the same single Tidal-Corsair/Tactician pairing repeated across every
top-decile row, not a spread of distinct pairs — a narrow spike, not a tail. The ceiling
(product 5.60x, contrast ratio 14.33x, buckets `trait_resource: 1.8, Daunting_Strength: 1.0`) is
the honest current bound against the 26x aggregate target: roughly 4.6x short at the product
level, before Phase 6 evaluates any prescription against it. The sweep also produced the
provisional corpus's control rows and confirmed the roster floor (product 1.0x, no reachable
bucket at all — a Channel-1-only resolution on every control team).

Running the sweep hits the same `Character.new()`-under-bare-`-s` failure Phase 4 found, since
`BurstReachability.ScoreTeam` (which the sweep calls for every team) constructs `Character`.
The sweep and the scored corpus table therefore both live in
`Tests/manual/team_corpus_sweep.gd` as GUT test functions, run via `Tests/run_tests.sh
-gtest=res://Tests/manual/team_corpus_sweep.gd -gexit` — see the amended Verification section.

Phase 6 finding: `BurstReachability.ScoreTeam` gained an optional `p_manifest` parameter
(defaulting to the real `Manifest.MANIFEST`), so a prescription is quantified by re-running the
same scorer against a duplicated, modified copy — never against the real manifest and never by
argument. `Tests/manual/prescription_sweep.gd` models all four prescriptions this way, each
against the full 1140-team sweep:

* **Spread a `bonus_per_debuff_on_target` hook** (0.3, matching Cataclysmic Surge) across up to
  4 Channel1-only skills: **no change to median, 90th percentile, or ceiling at any N.** The
  mechanism does reach the scorer (verified directly on the one team it composes best on), but
  an isolated hook only ever composes with Tactician's unconditionally granted
  Daunting_Strength — `(1+0.3)*(1+1.0)=2.6x` — short of even the 90th-percentile threshold
  (2.80x), let alone the 5.60x ceiling.
* **Retune every existing Channel2/Channel3 magnitude uniformly:** the retune now also scales
  an Enabler-classed entry's `granted_status` magnitude (Tactician's Fatal Flaw grants
  Daunting Strength — a real Channel-2 factor once it lands on a teammate, just carried on an
  Enabler-classed manifest entry), not only entries classed Channel2/Channel3_Cascade
  themselves. A modest 1.25x patch lifts the ceiling by +1.71x (median +0.40x, 90th +0.45x) —
  retuning alone reaches 26x at a **3.03x** uniform multiplier, which needs Wrangle the Sea's
  Steel stacks at 5.45 (from 1.8) and Daunting Strength at 3.03 (from 1.0). No stack-cap
  guardrail is implicated (the guardrail governs stack *count*, not magnitude-per-stack).
* **Add a distinct Channel2 key (0.3) to each zero-contribution kit** (Herald of the Loom,
  Bloodmage): **no change to median, 90th percentile, or ceiling**, for the identical reason as
  the spread-hook prescription — same 2.6x cap composing with Daunting_Strength alone.
* **Populate channel 3 via `CascadeEvent.instance_count`:** Miasma itself — already tagged
  Channel3_Cascade in the manifest — can **never** become a scored candidate at all, at any
  magnitude, because its damage lands via the zone-triggered Plague status rather than a direct
  `DamageEffect` on Miasma itself, so it fails `BurstReachability._HasDamageEffect` (verified
  directly). Modeling the same repeating-factor shape on Quarantine Breach (Plague_Doctor's own
  direct-damage skill) instead: flat through K=2, median +0.24x at K=4, and only at **K=16**
  (the per-action cascade cap) does the ceiling move at all (+1.20x, to 6.80x) — repetition is
  the cheapest route to a large number, but only once instance counts get large.

Ranked by ceiling delta at one unit of work: retune (+1.71x, magnitude only) > populate channel 3
(+1.20x, distinct-key growth) > spread-hook and zero-contribution-kit (+0.00x each, distinct-key
growth). The two zero-delta prescriptions are not failures of the mechanism — they are the
sharpest form of the Phase 4/5 finding: nothing in the roster composes with Tidal Corsair's own
caster-gated Wrangle the Sea, so any factor placed on a *different* character's skill can only
ever add to Tactician's lone team-wide Daunting_Strength, never to the actual ceiling pair. No
prescription here uncaps Momentum, Arcane Instability, or Steel and Sea.

Two things worth recording that were silent in the first pass. First, `Fatal_Flaw.tres`'s
Daunting-Strength grant targets `All_Other_Allies` (target 12 — every ally but the caster), not
"one ally"; `Weigh_the_Mark.tres` targets `Self`; `Expose_Fallacy.tres`'s Opportunist grant
targets `All_Allies`. Which teammates a grant reaches now derives structurally from the granting
`SkillEffect`'s own target (`BurstReachability._GrantReachesCandidate`) rather than being assumed
reachable by every character regardless of scope — the retune numbers above and the ceiling
figures in this Status section were re-measured after that fix; neither the ceiling (5.60x
product, ranked-top team) nor the median/90th/max changed, because none of the Phase 4/5 top
teams ever had the Tactician bursting their own grant. Second, Opportunist's
`PerTargetDebuffDamagePercent` bonus keys to whatever debuff is actually present on the target
(`status_effect_resolver.gd:634`), not to a fixed bucket — for Sorcerer/Scholar/Tactician this
lands in the *same* bucket as Cataclysmic Surge's own Warped requirement and adds rather than
multiplying, which is why the scorer's 2.80x supersedes the deleted plan's hand-computed 3.12x
(the Context section's table, below) rather than confirming it.

## Context

The previous attempt classified all 79 kit entries into damage channels and wrote the tags inline
into `Concept_Document.md` 3.1.3 and 3.2.4.2. The tags are correct and are kept — but a tag is a
property of one entry, and the pillar's requirement is a property of a *team*. Nothing in the
audit's output could answer whether a team reaches 1.1.2's target, so it ended with 79 verdicts and
no verdict on the thing that matters.

The one piece of real evidence it produced is buried in the deleted `Plan_Kit_Reworks.md:32-40`,
computed by hand for two teams:

| Team | Combined modifier |
|---|---|
| Sorcerer + Scholar + Tactician (Cataclysmic Surge bursting) | **3.12x** |
| Tidal Corsair + Cultist + Warlord (Corsair's Reckoning bursting) | **2.80x** |
| Required for a 50x burst (`Concept_Document.md:36`) | **26x on the aggregate** |

Neither is within an order of magnitude. That number — not any channel tag — is the starting point.
Its problems are that it covers 2 samples out of ~1330 possible teams, was computed by hand, and
cannot be recomputed after a kit changes.

**This plan builds the plumbing that makes "what burst can this team reach?" an executable
function.** It does not curate teams and does not rework kits. The intended team sets do not exist
yet — they cannot be named until the kits start to form — so the deliverable is the machinery those
sets plug into later, plus what that machinery can already say about the roster as it stands today.

The objective is explicitly **not** to make every team reach 26x. Section 1.1's realisation requires
that assembling the *right* team is a discovery — a roster where any three champions detonate has no
discovery in it. The healthy shape is a distinct top tail against a low median. The tool measures
that shape as a first-class output, so that once curated sets do exist, the question "does this set
actually stand apart?" is already answerable.

## The measurement contract

Every number this plan produces is one of exactly two quantities, defined once here.

**Combined modifier product.** `CombinedDamageModifier.Product()`
(`Scripts/Battle/combined_damage_modifier.gd:21-25`) at the bursting resolution — the product of
`(1 + bucket)` across distinct mechanic keys. Same key adds, distinct keys multiply (`:18-19`). This
is the quantity compared against 26x.

**Burst contrast ratio.** Final damage of the burst resolution divided by final damage of the same
champion's basic skill in the same fight — 1.1.2's actual definition. It is *not* the product:
`Skills.MitigatedDamage` (`Scripts/Battle/skills.gd:288-293`) is nonlinear, and because the modifier
multiplies the pre-mitigation aggregate (`battle_resolver.gd:744`) a 33x product yields roughly 63x
damage against Defence 120. This is the quantity compared against 30-50x.

The ratio has two independent terms and both are reported separately, never only their product:
the **base term** — the burst skill's `damage_scaling` aggregate over the basic skill's — and the
**modifier term** — what the combined product contributes once run through mitigation. A skill can
raise the ratio purely by having a fatter channel-1 base, with nothing multiplicative happening at
all, and that is precisely the shape 1.1.6 rejects. Separating the terms is what makes the rejection
test mechanically checkable instead of a judgement call.

Cascade instance count multiplies on top of both: each instance builds its own modifier
(`Scripts/Battle/cascade_resolver.gd:91-100`), bounded by `MAX_CASCADE_DEPTH = 4` and
`MAX_CASCADE_INSTANCES_PER_ACTION = 16` (`:12-13`).

Both are computed by calling `Skills.MitigatedDamageUnrounded` — the unrounded `float` core
`Skills.MitigatedDamage` itself wraps with `int(ceil(...))` — directly, not a mirror of the
formula. `blowout_calibration.gd`'s private `_Damage` calls the same unrounded core, so this
plan carries exactly one copy of the formula, not a third.

## Phase 1 — Kit contribution manifest

New file `Scripts/Debug/kit_contribution_manifest.gd`: a `const` dictionary, one entry per Role,
declaring what each kit can put on the table by burst time. Per contribution:

* **Bucket key** exactly as the runtime forms it — a `Types.Buff_Type` / `Types.Debuff_Type` name,
  `CombinedDamageModifier.TRAIT_RESOURCE_KEY`, the trait's class name (the key used at
  `battle_resolver.gd:689`), `DamageEffect._SkillKey()` (the skill name), or `_RampKey()`
  (`"<skill> (ramp)"`) — see `Scripts/Battle/Skill_Effects/damage_effect.gd:24-28, 42-58, 60-65`.
* **Magnitude** at Legendary rarity, and whether it stacks and to what ceiling.
* **Preconditions** — what must be true for it to apply (target carries debuff X, N stacks held, N
  uses this battle, self-only versus team-wide).
* **Class** — channel 1 / 2 / 3 / enabler, taken from the existing `Concept_Document.md` tags. This
  is where the prior audit's work is consumed as input rather than discarded.
* **Source citation** in a comment: `file.gd:LINE`.

Entries are derived by reading the code, not the document, where the two disagree. Known traps the
manifest must capture, because they silently zero out contributions:

* Trait multipliers all land in the single `trait_resource` bucket (`damage_effect.gd:25-27`) — a
  team stacking two such traits gets one factor, not two.
* All non-ramp `bonus_per` sources on one skill collapse into that skill's single bucket
  (`damage_effect.gd:28, 52-58`).
* `ResolveTraitDamage` (`battle_resolver.gd:390-404`) passes an **empty** modifier, so trait-sourced
  damage (Sorcerer's Surge) skips every channel-2 bucket.
* Tidal Corsair's stacks key off literal skill names (`tidal_corsair_trait.gd:79-105`).
* Crit path, `IncomingDamageReduction`, and Barrier sit outside the modifier by design
  (`Concept_Document.md:63`).

Enablers are recorded with their key and class but carry no magnitude — they are counted, not
scored.

The manifest is the file that has to stay alive as kits change. It is structured so a new or
reworked kit is one added entry, and Phase 3 is what keeps it honest.

## Phase 2 — The scorer

New file `Scripts/Debug/burst_reachability.gd`. **Given three presets and nothing else**, it
enumerates every damaging skill across the team as a candidate burst resolution, composes the
manifest entries reachable at each, and returns the best one. Which champion bursts and which skill
they burst with are **outputs**, not inputs — no skill is a burst skill intrinsically; a resolution
becomes one when a large enough product lands on it, and deciding that in advance would bake the
answer into the question. The result carries both contract quantities, both terms of the ratio, and
the bucket decomposition.

A candidate resolution may optionally be **pinned** to compare one specific line — used by the two
regression fixtures below, which do name a bursting skill. Pinning is a comparison affordance, not
the normal path.

Rules it enforces, all with citations:

* Group by key, sum within, multiply across (`combined_damage_modifier.gd:18-25`), bucket clamped at
  `-1.0`.
* Status cap of eight shared across buffs and debuffs (`Scripts/game_balance.gd:76`) — a team whose
  entries exceed eight simultaneous statuses cannot land them all, and the scorer reports which were
  dropped rather than silently scoring them.
* Per-trait stack ceilings (3 Steel/Sea, 5 Arcane Instability, 9 Infractions).
* Cascade instance count as a multiplier, bounded by the two cascade caps.
* **Enabler floor** — a team below the configured enabler count is marked non-viable and excluded
  from ranked output. The floor is a named constant with a stated default, not a hardcoded literal,
  because the right value is a design call you make once teams exist. Enabler count is a reported
  column on every row regardless.

`blowout_calibration.gd` gains a public entry point taking a heterogeneous factor list and returning
the contrast ratio — today `_ReportFactorRequirements` (`:91-118`) only handles a uniform factor
raised to a count, so it cannot answer `[1.4, 1.25, 2.0]`. Its private `_Damage` is replaced by a
call to `Skills.MitigatedDamage`; its five existing reports keep working off the new entry point.

Tests in `Tests/unit/test_burst_reachability.gd`: bucket algebra against hand-computed cases,
same-key collapse, status-cap overflow, enabler floor, cascade bounds, candidate enumeration picking
the genuinely best resolution rather than the first, base-term and modifier-term separation, and the
two known team numbers (3.12x, 2.80x) as pinned regression fixtures so they survive the deletion of
the plan files that hold them.

## Phase 3 — Live verification

The manifest is hand-derived and every conclusion rests on it. A representative set of teams —
spanning each distinct bucket-key shape rather than each Role — is replayed through the real
resolver and the predicted product compared to the measured one.

`Tests/unit/helpers/test_factory.gd:200` constructs a `BattleResolver` headless with no scene tree;
`ResolveSkill` returns `Array[CombatResult]` and every `Damage` result carries the assembled
`CombinedDamageModifier` (`battle_resolver.gd:799`), whose `Buckets()` gives the exact
decomposition. `Tests/unit/test_combined_damage_modifier_resolution.gd:100-109` is the pattern.
Zero out crit chance and read `Product()` rather than damage, as that file already does at `:25` and
`:66`, so the comparison is clean.

Tests land in `Tests/unit/test_burst_reachability_live.gd`, one per verified shape. **A divergence
between predicted and measured is a manifest bug, fixed in Phase 1, not explained away here.** These
tests are also the guard that stops the manifest silently rotting as kits are reworked later.

## Phase 4 — Team corpus slot

The corpus is a pluggable input, not a fixed list, because the intended sets do not exist yet.

`Scripts/Debug/team_corpus.gd` holds an array of rows in a deliberately thin shape: **three presets,
a tier label, and an optional one-sentence note on the realisation the team is meant to deliver.**
Nothing more. The bursting champion and skill are not row fields — the scorer derives them, so the
corpus cannot accidentally assert which resolution should win. An optional pinned-resolution field
exists for the regression fixtures and is left empty on ordinary rows.

The scorer reads this file and nothing else knows the corpus exists — so replacing it later is
editing one data file, not touching the tool.

Tiers the shape supports, for when the sets are named:

* **Intent** — teams you believe should detonate.
* **Plausible-but-wrong** — teams that look similar to a player but should not work. If these score
  close to intent, the realisation is not discoverable.
* **Control** — teams drawn without regard to synergy. Establishes the floor.

Seeded today with a **provisional** corpus so the machinery is exercised end to end and ships with
real output rather than an empty table: the top teams the Phase 5 sweep finds, plus the two known
hand-computed teams, plus three controls. Provisional rows are marked as such in the data and are
expected to be struck when you supply real ones.

## Phase 5 — Distribution sweep

One sweep of all `C(20,3) = 1140` teams through the Phase 2 scorer, each at its best available
burst — the roster is reduced to one preset per Role before sweeping (`TeamSweep.DedupeByRole`),
since several presets field the same Role's kit and scoring more than one per Role would only
add duplicate-kit teams. Nearly free once the manifest exists, and with no curated corpus yet
available this is the only way to say anything about the roster today.

Two outputs:

* **The histogram** — median, 90th percentile, and maximum of the achievable product across the
  roster. This is the direct measurement of whether team choice matters. A flat distribution at any
  level means the roster has no discovery in it, and that is a finding regardless of how high the
  level sits.
* **The ceiling** — what the single best team in the roster reaches, and its bucket decomposition.
  Against 26x this is the honest current answer to "is the pillar reachable at all today", replacing
  the two hand-computed samples with a bound.

No ranked list of 1140 teams is produced or acted on; the sweep is a shape and a bound, not a
shopping list.

## Phase 6 — Prescription

What the machinery can already say, quantified by re-running the Phase 2 scorer against a modified
manifest rather than by argument:

* **Spread `bonus_per_debuff_on_target` hooks.** Only Sorcerer's Cataclysmic Surge declares one
  today. Model adding it to N damage skills; report the ceiling at each N.
* **Retune existing channel-2 magnitudes.** Report the multiplier the current factor *set* would
  need to reach 26x, so it is visible whether retuning alone can get there.
* **Add distinct keys to zero-contribution kits.** The deleted `Plan_Kit_Reworks.md` named Herald of
  the loom and Bloodmage; the manifest re-derives that list rather than inheriting it. Model one new
  factor of a stated size on each.
* **Populate channel 3.** Instance count multiplies against the product, so it is arithmetically the
  cheapest route to a large number, and the roster has almost none of it
  (`Plan_Blowout_Alignment.md:292-316`). Model repetition via `CascadeEvent.instance_count`, which
  needs no new `Types.Cascade_Trigger` value (`Scripts/common_enums.gd:227-231`).

Each is ranked by ceiling delta per unit of work and states whether it grows the distinct-key count
or only a magnitude — 1.1.3 prefers the former. Each also reports its effect on the *median*, not
only the ceiling: a prescription that lifts both equally fails the realisation requirement even if
it reaches 26x. Prescriptions violating a standing guardrail are excluded and the exclusion stated.

If no combination reaches 26x, that is a coverage gap, not a rework list, and it goes to
`Plan_Blowout_Alignment.md`'s `Coverage gaps` — which already meets the spawn condition for
`Plan_System_Buildout.md` (`Plan_Blowout_Alignment.md:330-333`).

## Phase 7 — Documentation and handoff

* `Concept_Document.md` — channel tags in 3.1.3 and 3.2.4.2 stay as written; corrections only where
  Phase 1 found a tag disagrees with the code. 1.1.2's ratios are **not** re-targeted here; the
  master plan defers the contrast baseline to Phase 7, against a playable burst.
* `Technical_Design_Document.md` — an entry for the scorer, the manifest, the corpus slot, and the
  `blowout_calibration` public entry point, including how to add a kit to the manifest.
* `Plan_Blowout_Alignment.md` — Phase 5 entry rewritten to what this plan actually produced,
  replacing the paragraph that cited a ledger which was never written. Coverage gaps updated with
  the ceiling and the distribution shape.
* Spawn the rework plan carrying Phase 6's prescriptions forward, named for its full meaning per the
  naming convention.
* Delete this plan file.
* Run `/check-design` over `Concept_Document.md`.

## Watch for

* **This plan ships plumbing, not conclusions about teams.** The provisional corpus is scaffolding;
  do not present its rows as design findings.
* **A high-scoring roster is not the goal; a discriminating one is.** A prescription that lifts the
  median as much as the ceiling fails even if it hits 26x.
* **The manifest is the risk.** Every conclusion rests on it and it is hand-derived. Phase 3 exists
  solely to catch that; do not weaken it.
* **A kit of enablers is a valid result, not a finding.** Do not convert enablers into damage
  factors.
* **Do not uncap Momentum, Arcane Instability, or Steel and Sea** — `Concept_Document.md` 1.1.4 caps
  them correctly.
* **Defence irrelevance at burst scale is inherited, not re-litigated** — under 2% across the full
  `Defense_Ignore_Factor` range.
* No code or data-file comment may name this plan, a phase, or a tier — plans are deleted on
  completion and the reference would dangle.
* Spell words out in full in identifiers and prose, per the naming convention.

## Verification

* `Tests/run_tests.sh` green, including `test_burst_reachability.gd` and
  `test_burst_reachability_live.gd`.
* `gdlint Scripts/` clean.
* `Tests/run_tests.sh -gtest=res://Tests/manual/team_corpus_sweep.gd -gexit` prints the corpus
  table — per row: the derived bursting champion and skill, product, contrast ratio split into
  its base and modifier terms, distinct-key count, enabler count — plus the Phase 5 histogram
  and ceiling. Not a bare `godot --headless -s Scripts/Debug/burst_reachability.gd` invocation:
  `BurstReachability.ScoreTeam` constructs `Character`, which hits the same failure the Phase 4
  status note documents for any bare `-s` entry path, so this runs through GUT instead, same as
  the Phase 4 sweep.
* `Tests/run_tests.sh -gtest=res://Tests/manual/blowout_calibration_report.gd -gexit` still
  produces `blowout_calibration.gd`'s five existing reports unchanged after the split to
  `Skills.MitigatedDamageUnrounded` (diffed against the pre-split bare-`-s` output: exact
  match). Not the bare `-s Scripts/Debug/blowout_calibration.gd` entry path any more —
  `Skills.MitigatedDamageUnrounded` transitively pulls in `Character` through `Skills`'s other
  static helpers, the same `Character.new()`-under-bare-`-s` failure this Status section
  documents for the sweeps, so this file moved to the same GUT entry path they use.
* Phase 3's predicted-versus-measured comparison agrees within floating-point tolerance for every
  verified shape.
* Adding one invented kit entry to the manifest changes the corpus table without touching the
  scorer — the plumbing test, in `test_burst_reachability.gd`.
* `Tests/run_tests.sh -gtest=res://Tests/manual/prescription_sweep.gd -gexit` prints all four
  Phase 6 prescriptions' median/90th-percentile/ceiling deltas against the unmodified baseline,
  and the ranking by ceiling delta per unit of work. Same GUT entry path as the other two manual
  sweeps, for the same `Character.new()` reason.
