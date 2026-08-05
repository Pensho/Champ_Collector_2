# Plan: Kit Blowout Audit

Phase 5 of `Plan_Blowout_Alignment.md`. Every Role passive in `Concept_Document.md` 3.1.3
and every skill in 3.2.4.2 is classified into one of the three damage channels in section
1.1.3 or into the enabler class, and checked against the rejection test in 1.1.6.

The corpus is **79 entries**: 19 Role passives (20 Roles, but Herald of the loom's passive is
blank in both the document and the data) and 60 role skills, three per Role. Section 3.2.4.3
adds two unassigned generics. In data these live as 21 `CharacterPreset` resources in
`Data/Character_Player_Variants/` — Lancer has two bodies (`Knight.tres`,
`Centaur_Lancer.tres`) and Scholar ships as `Centaur_Archivist.tres`, so all 20 Roles are
covered — 19 `.tres` shells in `Data/Character_Traits/` whose behaviour lives in
`Scripts/Character/character_traits/CharacterSpecificTraits/`, and 61 player-referenced skill
resources under `Data/Character_Skill_Variants/`.

**This plan audits; it does not rework.** Its output is a classification ledger, the channel
tags written into the Concept Document, a rework list, and a coverage verdict. Executing the
reworks belongs to `Plan_Kit_Reworks.md`, which this plan spawns and does not write. Writing
tags into 3.1.3 and 3.2.4.2 is the audit's output form — the precedent is 3.2.3, where Phase 2
tagged all 58 statuses inline — not a rework.

A kit entry is broken in one of three ways, and only these three:

* **It sits in no bucket** — it neither moves an attribute, nor supplies a factor to the
  combined modifier, nor triggers a separate resolution, nor passes the collapse test in
  1.1.6 as an enabler.
* **It is filed as a damage factor but delivers a linear bump.** The rejection test in 1.1.6
  verbatim: if a mechanic's best case is a linear improvement over not having it, it does not
  serve the pillar.
* **It duplicates a mechanic another kit already supplies.** New at this phase and not
  expressible in Phase 2's per-status taxonomy. Under the composition law, contributions
  grouped by mechanic identity *add* into one bucket — see `CombinedDamageModifier.Contribute`
  (`Scripts/Battle/combined_damage_modifier.gd:18-19`) — so two kits that both apply Empower,
  or that both contribute under the same skill effect key, supply one factor between them,
  not two. Section 1.1.3 makes this the whole point of collection: "more kits means more
  distinct mechanics in play, not additional bodies multiplying the same one." A roster whose
  kits converge on the same keys cannot reach 1.1.2's 26x no matter how many champions are
  fielded. This failure mode is invisible per entry and appears only across the roster, which
  is why Phase 5 exists and why the batches are cut by purpose, where convergence concentrates.

## Status

**Not started.** Prerequisites — Phases 1 through 4 of `Plan_Blowout_Alignment.md` — are
landed: `CombinedDamageModifier`, `CascadeResolver`, and `BurstPacing` all ship, and the 58
statuses each carry a settled channel verdict in 3.2.3.

## What each entry is asked

Three questions per entry, answered in the ledger row:

* **Which channel does it feed?** Channel 1 (moves an attribute, continuously and additively),
  channel 2 (supplies its own factor to the combined modifier), channel 3 (triggers a separate
  resolution), or enabler (produces no damage, judged by the collapse test). Two tags is a
  valid answer where mechanism and role differ — 3.2.3 does this for Blind and Warped.
* **Does it contribute a distinct mechanic key?** Named as the key the combined modifier would
  actually group it under: a `Types.Buff_Type` or `Types.Debuff_Type` value, a trait resource
  (`CombinedDamageModifier.TRAIT_RESOURCE_KEY`), or a skill effect key from `_SkillKey` /
  `_RampKey` in `Scripts/Battle/Skill_Effects/damage_effect.gd:42-51`. An entry that supplies
  no key at all is either channel 1 or an enabler, and saying so is part of the verdict.
* **Can it participate in a burst?** Or is it build-up-only — pressure during the rounds
  before the trigger, per section 1.1.1. Build-up-only is a legitimate answer; 1.1.1 requires
  most rounds to be spent building.

Verdict vocabulary follows Phase 2's: **conforms**, **rework**, **provisional**.

Two guardrails from the master plan hold throughout:

* **A kit carrying enablers rather than factors is a valid result, not a finding.** The target
  is not a roster where every skill touches damage. Section 1.1.3 is explicit that enablers
  are not to be converted into a damage channel.
* **The capped passives are correct as written.** Momentum (Lancer's Reckless Momentum),
  Arcane Instability (Sorcerer), and the Tidal Corsair's Steel and Sea stacks accrue
  automatically, and section 1.1.4 caps exactly what accrues automatically. Do not uncap them
  as part of this pass.

## Phase 1 — Batch 1: Damage roles

Thief, Lancer, Sorcerer, Jester, Bloodmage, Tidal Corsair. Six passives and eighteen skills.

First because this is where channel-2 factors should already be densest, and where the
distance between a real factor and a linear bump is easiest to see — the batch calibrates what
a **conforms** verdict looks like before the harder ones.

Ledger rows are grouped under a `###` heading per Role, passive first, then the three skills in
document order (the basic skill is always first). Row shape follows Phase 2's:

> * **Pilfer** (Thief passive, chance to steal a buff on skill use) — **verdict**.
>   Evidence with `file.gd:LINE` citations naming what the mechanic actually does in code,
>   which key it groups under, and why the verdict follows. `Rework:` direction if the verdict
>   is rework.

Watch for in this batch specifically: the three capped passives all sit here (Lancer, Sorcerer,
Tidal Corsair) and are pre-settled as correct; audit what they *contribute*, not their ceiling.

## Phase 2 — Batch 2: Debuffer and Control roles

Emissary, Alchemist, Scholar, Diviner, Appraiser, Cultist, Chronophage, Plague Doctor. Eight
passives and twenty-four skills.

The batch where the collapse test does the most work, and where failure mode three is most
likely: these kits mostly deliver their effect by applying statuses, and Phase 2 already
classified those 58 statuses. A skill whose entire contribution is "applies Enfeeble" inherits
Enfeeble's channel and Enfeeble's key — and so does every other skill in the roster that
applies Enfeeble. Record the inherited key in the row; Phase 5 counts the collisions.

The Emissary's Standing Record and the Plague Doctor's Comorbidity both scale off counts
(Infractions, active debuffs). Check each against failure mode two: a rate multiplied by a
count out of one summed bucket is linear, which is exactly the defect Phase 2 found in
Opportunist. `tick_bonus_per_debuff` (`Scripts/Battle/status_effect_resolver.gd:293-295`) is
the current shape of Comorbidity's scaling and is capped by `Game_Balance` — audit whether it
compounds or sums.

## Phase 3 — Batch 3: Buffer and Sustain roles

Tactician, Symbiote, Bar Brawler, Warlord, Architect. Five passives and fifteen skills.

Expect this batch to be enabler-heavy, and expect that to be correct. Section 1.1.3 names
buying a turn and protecting the setup as the enabler's job, and 1.1.1 requires the threat
curve to peak before the burst — these kits are what the player answers that threat with. The
question that matters here is the collapse test, applied honestly: does removing this make the
fight go materially differently, or is it merely useful to have.

The Symbiote's Graft is audited as one entry — the mechanism, not the pool. The eighteen graft
resources in `Data/Character_Traits/Grafts/` (catalogued in `Symbiote_Graft_Pool.md`) are a
coverage question for Phase 5, not eighteen ledger rows.

The Architect's Calibration kit was designed after the pillar (`Plan_Architect_Calibration_Kit.md`,
status Implemented) and is the roster's newest; if it conforms cleanly it is the reference
shape for what a post-pillar kit looks like, worth saying so in the row.

## Phase 4 — Batch 4: Herald of the loom and the unassigned skills

Herald of the loom's three skills (`Thread_Snap`, `Thread_Lash`, `Woven_Blessing`), plus the
entries that belong to no Role:

* **Weight of Law** (3.2.4.3, `Data/Character_Skill_Variants/Zone_Skills/Weight_of_Law.tres`) —
  documented as unassigned and shipped as a resource referenced by no preset.
* **Pagan Curse** (3.2.4.3) — documented, with no resource and no code reference anywhere.
* **Weigh the Mark** (`Support_Skills/Weigh_the_Mark.tres`) — the shipped form of the Thief's
  documented "Case the Target": same Opportunist-buff effect, different name, three turns in
  data against two in the document. Audited here rather than in Batch 1 because the row's
  finding is the drift, not the mechanic.
* **Power Tide** (`Support_Skills/Power_Tide.tres`) — referenced by no preset and named in no
  document section.

Herald of the loom's blank passive is recorded as a finding with a severity. Designing one is
rework, and belongs to the spawned plan.

## Phase 5 — Cross-kit independence pass

The only phase that reads the whole ledger at once, and the one that answers the composition
law. Failure mode three is not visible in the batches; it is visible here.

Two products:

* **A mechanic-key census.** Every distinct grouping key the roster supplies, with the kits
  that supply it: `Types.Buff_Type` and `Types.Debuff_Type` values applied by skills or
  passives, trait resources, and skill effect keys as `CombinedDamageModifier` sees them. Any
  key supplied by two or more kits is failure mode three, and the census is the only place it
  can be stated. The census also states the inverse and more important number: how many
  distinct channel-2 keys the roster supplies in total.
* **The three-champion arithmetic.** For two or three plausible teams drawn from the audited
  roster, count the distinct factors actually available at one resolution and compute the
  product, using `Scripts/Debug/blowout_calibration.gd` for the damage math. Compare against
  section 1.1.2's requirement: 26x on the scaled aggregate for a 50x burst, "one to two factors
  per champion, which normal kits can carry". This is the phase's real verdict — whether the
  pillar is reachable by the roster as it stands. If it is not, that is a coverage gap, not a
  list of reworks: aligning kits cannot manufacture keys the roster does not have.

Expect channel 3 to come out near-empty across all 79 entries. `Types.Cascade_Trigger`
(`Scripts/common_enums.gd:232`) ships two values, `Status_Expired` and `Status_Landed`, and no
skill or passive posts to either — the four registered listeners are all statuses. Per the
master plan's standing rule, an under-populated channel is a result, not a null result: record
it in `Coverage gaps` rather than closing the phase clean.

## Phase 6 — Documentation

* **Tag 3.1.3 and 3.2.4.2 inline**, in the exact bracket vocabulary 3.2.3 already uses:
  `[Channel 1]`, `[Channel 2]`, `[Channel 3 — Cascade]`, `[Enabler]`, dual tags joined with
  `/`, and a `+` where an entry genuinely contributes to two channels (Bleed's
  `[Channel 1 + Channel 2]` is the precedent). Passives take the tag after the passive name;
  skills take it on the `Effect:` line. Add a preamble paragraph to 3.2.4 mirroring the one at
  `Concept_Document.md:401-407`, and one to 3.1.3 for the passives.
* **Flag, do not silently rewrite, any conflict with section 1.1.** The pillar outranks the
  rest of the document, but the master plan requires conflicts to be surfaced. Two are already
  visible and should be resolved or recorded here: 3.1.3's Architect entry claims its
  construction-zone skill does not exist yet, though `Raise_the_Frame.tres` ships; and 3.2.4.2
  documents "Case the Target" where the data ships "Weigh the Mark".
* **Mark Phase 5 done in `Plan_Blowout_Alignment.md`**, in the style its Phase 4 entry uses,
  naming both what this plan produced and `Plan_Kit_Reworks.md` as the plan carrying the
  reworks forward.
* **Move roster-level under-coverage into the master plan's `Coverage gaps`.** Phase 5 is
  named there as the phase expected to produce the bulk of that list, and the list holding
  more than the cascade entry is the trigger to spawn `Plan_System_Buildout.md` and migrate
  the entries. If this audit's coverage verdict pushes the list past one entry, that spawn is
  due — say so in the handoff rather than leaving it implied.
* Run `/check-design` over the updated `Concept_Document.md`.

## Handoff — `Plan_Kit_Reworks.md`

Input for the spawned plan, assembled from the ledger: every **rework** and **provisional**
verdict, with its entry, which of the three failure modes it hit, and a one-line direction.
No implementation steps here — that plan is written when this one closes, per the master
plan's rule that sub-plans are written when their prerequisites land.

Rework is not always upward. A skill that reads as a linear bump may be correct as a
build-up-tier effect and wrong only in how the document describes it.

Where a genuine rework is needed, prefer the direction that adds a new distinct mechanic
key over the direction that merely retunes an existing one — a fix that gives a kit a new
factor or an enabler that gates a real burst grows the mechanic-key census from Phase 5,
where a fix that only changes a magnitude does not. This is a preference for the spawned
plan to weigh, not a mandate: it does not override the standing guardrails above (do not
uncap the capped passives, do not convert enablers into damage factors) or the collapse
test that judges an enabler on its own terms.

## The contrast baseline

The master plan's `Watch for` flags the contrast baseline as unsettled — 1.1.2 measures a
burst against the bursting champion's own basic skill, where the composition law suggests the
honest baseline may be the team's average per-action output — and defers it to this phase.

**This plan reports evidence and does not settle it.** Phase 5's team arithmetic produces
exactly what the question needs: how many kits a real burst spans, and how much of its product
comes from champions other than the one casting. Record that number and hand it to Phase 7,
which will have playable encounters to feel the ratio against rather than compute it. Do not
re-target 1.1.2's ratios here; the master plan's own reasoning is that the baseline is a design
question to settle against a playable burst.

## Watch for

* **A kit of enablers is a valid result, not a finding.** Do not convert enablers into damage
  factors.
* **Do not uncap the capped passives** (Momentum, Arcane Instability, Steel and Sea) — section
  1.1.4 caps them correctly.
* **Dual classification is a valid result**, not an unresolved one. 3.2.3 already carries
  Blind and Warped that way.
* **An under-populated channel is a result, not a null result.** A batch that finds nothing to
  rework has not thereby found nothing.
* **Defence going irrelevant at burst scale is inherited, not re-litigated.** Any row whose
  verdict rests on it (a Defence debuff, a defence-ignore skill) cites section 1.1.4 and the
  `FeatureIdeas.md` backlog item rather than reopening it.
* No code or data-file comment written by this plan may name the plan, a phase, or a batch —
  plans are deleted on completion and the reference would dangle.

## Documentation

`Concept_Document.md` 3.1.3 and 3.2.4.2 gain the inline channel tags and their preambles;
3.2.4.3 gains a verdict on its two unassigned entries. `Plan_Blowout_Alignment.md` gains the
Phase 5 completion entry and whatever coverage gaps this audit produces. No
`Technical_Design_Document.md` entry: this phase ships no architecture.

On completion, run `/review-implementation` against this plan, then delete it per the
retention rule in `Plans/README.md` — its ledger's living home is the Concept Document tags,
and its open work has moved to `Plan_Kit_Reworks.md`.
