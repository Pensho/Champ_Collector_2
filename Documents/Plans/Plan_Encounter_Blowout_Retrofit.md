# Plan: Encounter Blowout Retrofit

Spawned by `Plan_Blowout_Alignment.md` Phase 7, the last phase of the master plan and the
only one aimed at the consumer of every system the preceding six built. Phases 0 through 6
landed the combined-modifier channel, the status reclassification, the cascade resolver,
burst presentation, the kit reachability scorer, and the itemization channels. None of them
touched the encounters those systems are supposed to detonate against.

Written as prescriptions to execute rather than questions to litigate: the four decisions
that shape it were settled with the plan's owner before it was written, and are recorded
under `Settled decisions` below.

## Status

Paused after Phase 2, pending the kit rework. Phase 1 (tier definitions) and Phase 2
(per-encounter channel audit and coverage-ledger tagging) are done. Phase 3 (boss
configuration rework) was on hold because it commits specific role/kit pairings to each
boss's configurations, and reshaping them against kits that were about to change would
have been wasted work. The kit rework has now landed (`Archive/Role_Kit_Design.md`) and the
combined-modifier gap the Findings entry below describes is closed — **Phase 3 is unblocked,
behind Phase 2b.** Phases 4 and 5 depend on Phase 3's output and remain paused until it runs.

Phase 2's audit was committed before the kit rework was written, and 17 of the 20 kits
changed after it, so its channel tags read a skill set that no longer exists. **Phase 2b
re-derives the audit before Phase 3 keys off its verdicts.**

## Context

Two things are unaligned with the design pillar in `Concept_Document.md` 1.1.

**The tier definitions never mention the burst.** Section 5.3 defines a mini-boss as "one
core mechanic; bringing an answer wins comfortably, ignoring it makes the fight
substantially slower or riskier but never impossible" — a lock being removed, not a payoff
being earned. None of the three tier bullets state a burst expectation, and none state the
threat-curve requirement from 1.1.1, even though 1.1.2 already carries per-tier burst
targets (fodder: none; mini-boss: ~10x; boss: 30–50x). The tier definitions and the
calibration targets are describing the same encounters and do not refer to each other.

Section 5.3 also directly contradicts 1.1.1. The pillar states "**Unsolved is a wall, not a
slow fight**" as a general property of a solved encounter; 5.3 reserves the wall for bosses
and gives a mini-boss "roughly double unsolved". All four mini-boss entries in the catalog
are written to 5.3's softer rule.

**The catalog was authored under those definitions.** All 14 entries in
`Encounter_Design_Document.md` name intended solutions that *remove an obstacle* — Severance
halting a Haste ramp, Signed Writ shearing durations, Suppress gutting Mysticism scaling,
Barrier and Fortify absorbing a kill-shot, Refutation clearing zones. Under
`Concept_Document.md` 1.1.3's taxonomy nearly all of those are **enablers**: they create or
protect the burst window and produce no damage themselves. Exactly one configuration in the
whole catalog describes a burst — the Warden of the Reliquary's configuration (3), the
Tactician plus Appraiser crit round that breaks the Barrier, kills into the Deathward, and
finishes the 1-Health Warden in the same round. That entry is this plan's reference shape.

An enabler-heavy catalog is not by itself a defect. Section 1.1.3 states outright that
enablers are not to be converted into damage channels, and 1.1.6 holds them to the collapse
test instead. What the pillar does require is that a **Boss-tier** encounter's answer set
end in a payoff somewhere, and that requirement is currently met by one boss out of three.

### Settled decisions

1. **The Health retune happens now**, not gated on the kit rework
   (`Archive/Role_Kit_Design.md`, complete). Its consequence is carried as a Finding below
   rather than absorbed silently.
2. **The "unsolved is a wall" property is scoped to Boss tier.** Section 1.1.1's bullet is
   amended to name the tier; the mini-boss keeps "roughly double unsolved" and gains 1.1.2's
   ~10x partial-burst expectation. This is consistent with 1.1.2, which already tiers the
   burst targets, and it means no mini-boss entry's `Unsolved texture` needs rewriting.
3. **Channel tagging takes two forms:** a new per-encounter audit table in
   `Encounter_Design_Document.md`, plus inline channel tags in the existing Role × Tier
   coverage ledger in `Plan_Encounter_Solution_Design.md`.
4. **Scope guard, inherited from the master plan:** this plan aligns what exists, it does
   not author new content. Reshaping an existing boss's intended-solution configurations
   toward a burst payoff, using effects already in `Concept_Document.md` 3.2.3 and kits
   already in 3.2.4.2, is alignment and is in scope. Authoring new opponent skills, new
   statuses, or new encounter entries is not — those go to the master plan's
   `Coverage gaps` and to `Plan_Encounter_Solution_Design.md`'s volume batches.

## Phases

### Phase 1 — Tier definitions — done

`Concept_Document.md` 5.3 and 1.1.1.

Amend 1.1.1's second bullet so "unsolved is a wall, not a slow fight" names Boss tier
explicitly and stops contradicting 5.3's mini-boss line. This is the pillar section
changing rather than the section it conflicts with, which inverts the master plan's usual
precedence rule — flag it in the edit, since 1.1.2 is the tie-breaker (it already tiers the
burst targets, so tiered unsolved-textures follow from it).

Rewrite 5.3's three tier bullets to state, per tier, the burst expectation from 1.1.2 and
the threat-curve requirement from 1.1.1. The round budgets are unchanged — Phase 0 measured
them sound and explicitly recorded "no change needed":

* **Fodder** — no dedicated burst; blowout here is overkill on trash. 3–4 rounds.
* **Mini-boss** — one realisation, a partial burst, around 10x the champion's own basic
  skill. The threat curve peaks before it. 6–10 rounds solved, roughly double unsolved.
* **Boss** — layered realisations, a full burst at 30–50x carrying 60–80% of total damage
  dealt. The threat curve peaks before the burst, not after. 10–12 rounds solved; unsolved
  is a wall, not merely slow.

Keep 5.3's existing closing pointer to `Encounter_Design_Document.md` and
`Plan_Encounter_Solution_Design.md`.

Watch for: 5.3 is owned by the Concept Document but restated in two other places — the
`Encounter_Design_Document.md` preamble and `Plan_Encounter_Solution_Design.md`'s
`Encounter tiers (confirmed decisions)` section. Bring both into sync or re-point them at
5.3 in the same edit.

### Phase 2 — Per-encounter channel audit — done

One row per encounter, covering all 14 catalog entries: 7 fodder (Sporeback Pack, Wake
Skimmers, Ledger Clerks, Plains Outriders, Ridge Marksmen, Flank Cutter, Line Breaker), 4
mini-boss (The Ashen Oracle, Reanimating Statues 1, 2, and 3), and 3 boss (The Glyphbound
Archivist, The Collector of Debts, The Warden of the Reliquary). Columns: encounter, tier,
intended answers, the channel each answer feeds, the tier's burst target, and a verdict.
The table lands in `Encounter_Design_Document.md` as its own section, since it is keyed by
encounter and that document is the encounter catalog.

The channel per answer is **derived, not invented**. Two settled sources already carry the
classification, and this phase reads them rather than re-classifying:

* `Concept_Document.md` 3.2.3 — every one of the 58 statuses carries a settled channel or
  enabler tag, landed by the master plan's Phase 2.
* `Scripts/Debug/kit_contribution_manifest.gd` — a machine-readable `Contribution_Class`
  (`Channel1`, `Channel2`, `Channel3_Cascade`, `Enabler`) per kit entry, each with a
  `file:line` citation to the code it was derived from.

Where the two disagree, that is a finding, not a judgement call to make here.

The verdict per encounter is one of **has a payoff** — at least one intended answer feeds
channel 1, 2, or 3 toward the tier's burst target — or **enabler-only**, where every answer
merely removes the lock. Record the verdict for every tier, but note in the table's preamble
that only a Boss-tier `enabler-only` verdict is a defect: fodder has no burst by definition,
and a mini-boss whose answer is a strong enabler alongside a ~10x partial burst is correct
as written.

Then tag the Role × Tier coverage ledger in `Plan_Encounter_Solution_Design.md` inline —
for example `Reanimating Statues 1 (Signed Writ → buff-duration strip) [Enabler]`. Fodder
cells may be tagged for completeness but carry no burst expectation.

### Phase 2b — Re-derive the audit against the reworked kits

`Encounter_Design_Document.md` section 3.

Phase 2's tables were derived from the pre-rework kits; the reworked skills they name behave
differently now (Corsair's Reckoning composes off the hand, Dissolving Agent gained damage,
Expose Weakness scales with charges spent, Field of Study amplifies attributes, Premonition
counter-attacks). Re-read every row's channel tag off the current
`Scripts/Debug/kit_contribution_manifest.gd` and `Concept_Document.md` 3.2.3 / 3.2.4.2, and
rewrite the tags and verdicts in place.

Expect flips to run enabler-only → has a payoff, since the rework added damage surfaces; a
flip in the other direction is a finding worth raising before Phase 3 consumes it. What Phase
3 actually keys off is the Boss table's two `enabler-only` verdicts, so re-derive that table
first and let its result set Phase 3's scope.

### Phase 3 — Boss configuration rework — paused, see Status

`Encounter_Design_Document.md` section 2.3.

For each boss whose Phase 2 verdict is `enabler-only`, reshape or add one of its 2–3
intended configurations so it ends in a burst, using only cataloged effects and existing
kits. Expected per boss:

* **The Warden of the Reliquary** — already conforms. Configuration (3) is the Tactician
  plus Appraiser crit round. Confirm against the Phase 2 audit and cite it as the model
  rather than reworking it.
* **The Glyphbound Archivist** — the hard one, and the likeliest to end in a coverage gap.
  All three configurations are zone-clearing or sustain. The standing-zone count would be the
  natural quantity for the player side to read as a channel-2 factor or channel-3 instance
  count, but **no kit reads a zone count as a `bonus_per` factor** in the current manifest,
  and Refutation still carries no damage parameters (`Plan_System_Buildout.md`'s open entry).
  Reaching a payoff here without a new mechanism is unproven — settle that question before
  reshaping configurations, and take the coverage-gap branch below rather than authoring.
* **The Collector of Debts** — configurations are buff denial, buff repossession, and a
  reagent roster. The Alchemist's team-wide channel-2 factor on ally reagent consumption and
  the Sorcerer's channel-3 repeat both still gate on `reagent_consumed` after the rework (the
  repeat now runs on Echo charges, four instances at 1.70 compounding), and both live in
  exactly the reagent space configuration (3) already names. The payoff is available with no
  new content at all.

Every reworked configuration must still satisfy `Plan_Encounter_Solution_Design.md`'s
production rules: 2–3 distinct valid configurations per boss, at most 2 dedicated roster
slots at Boss tier, each boss keeping at least one configuration no other boss uses, and the
review threshold on any effect answering more than 3 mini-boss or boss encounters — the
Emissary's Signed Writ is already *at* 3, so no rework may lean on it again.

Where a boss cannot reach a payoff without a new opponent skill or status, stop and record
it under the master plan's `Coverage gaps`. Do not author it here.

### Phase 4 — Health retune — paused, see Status

`Data/Character_Enemy_Variants/*.tres`, `Scripts/Debug/blowout_calibration.gd`, and
`Concept_Document.md` 1.1.2.

Phase 0 found that for a 50x burst to land as 60–80% of a boss rather than 150–283% of it,
boss Health attributes need to roughly triple, to the 900–1000 band. Hit points are the
attribute times `GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER` (`Scripts/game_balance.gd`).

* **Boss tier moves to the ~900–1000 band.** `Glyphbound_Archivist.tres` (currently 500),
  `Collector_of_Debts.tres` (350), `Vault_Warden.tres` (300).
* **Mini-boss tier does not move.** Section 1.1.2's own extrapolation — 50x needs about
  triple, 30x needs about double — puts a 10x partial burst below the current values.
  `Ashen_Oracle.tres` (260), `Statue_Boots.tres` / Vael (300), `Statue_Weapon.tres` / Ulfrac
  (270), `Statue_Shield.tres` / Bor Bulwark (280), and `Obsidian_Stallion.tres` (330) are
  unchanged. State this explicitly in the edit: "triple boss Health" must not be read as
  "triple everything", and three of Phase 0's five named balanced bosses are mini-boss-tier
  statues.
* **The Warden and Core pair needs a per-entry judgement.** The entry sizes the Vault Warden
  at "a standard champion's expected Health" and the Reliquary Core at "3× a champion's"
  (already 900). The burst's target is the Warden, not the Core — tripling the Warden to 900
  makes the two equal and erases the relationship the entry describes. Decide whether the
  Core scales alongside it or the entry's framing is restated, and write the decision into
  the entry text.
* **Defence and Knowledge do not move.** Defence is inherited from `Concept_Document.md`
  1.1.4, not re-litigated: varying `Defense_Ignore_Factor` across its full range moves a burst
  by under 2%. Both are hard-coupled to the scorer — `Scripts/Debug/burst_reachability.gd`
  resolves every reachability score against `BlowoutCalibration.BOSSES[0][2]` (Troll's Defence
  of 120) and `BOSSES[0][3]` (its Knowledge of 10, which blunts critical damage) — so moving
  either would silently invalidate every measurement the master plan's Phases 5 and 6 and the
  kit rework's sweeps recorded. Nothing reads `BOSSES[i][1]`, so the Health retune cannot move
  a reachability figure; that is what makes the sweep a usable tripwire under Verification.
* **Data-only enemies.** `Troll.tres` (300) and `Obsidian_Stallion.tres` (330) sit in Phase
  0's balanced-boss list but have no `Encounter_Design_Document.md` entry;
  `Plan_Encounter_Solution_Design.md` calls the Obsidian Stallion a mini-boss and the Troll
  is unclassified. Assign each a tier here and retune to that tier's band. Authoring their
  catalog entries — and that of `Battle_Militia.tres`, the third battle variant with no
  entry — is `Plan_Encounter_Solution_Design.md`'s volume work, recorded as a coverage gap.

**The duplication is the trap.** `blowout_calibration.gd`'s `BOSSES` constant is a hardcoded
copy of five preset values with no link to the `.tres` files that hold them. Edit both in the
same commit.

Tests, in `Tests/unit/` following the house shape (`extends GutTest`, a file-top docblock
citing the design-doc section, snake_case sentence-style test names, every assert carrying an
interpolated message — `Tests/unit/test_burst_pacing.gd` is representative):

* A test asserting `BlowoutCalibration.BOSSES` matches the Health, Defence and Knowledge
  values in the corresponding `Data/Character_Enemy_Variants/*.tres`, which closes the
  duplication risk permanently rather than only for this retune. Only Troll and the Obsidian
  Stallion have presets; the other three rows take the Troll's Knowledge as a stand-in and
  have nothing to compare against.
* A test asserting each boss-tier preset's Health sits in the band 5.3 now names, and each
  mini-boss preset's likewise.
* `Tests/unit/test_encounter_assembly.gd` asserts compositions and skill membership, not
  attributes, so it should stay green. Confirm it rather than assuming it.

### Phase 5 — Adopt the pillar in the production rules, and unpause — paused, see Status

`Plan_Encounter_Solution_Design.md` and `Plans/README.md`.

* Add the burst expectation to the encounter entry template: a mini-boss or boss entry
  states which channel its intended answers feed and where the payoff lands, the same way it
  already states each mechanic's onset.
* Add a rule to `## Rules` binding new encounters to the rejection test in
  `Concept_Document.md` 1.1.6 — a boss whose answer set only removes a lock is rejected, and
  an enabler answer is held to the collapse test rather than converted into damage.
* Land Phase 2's inline channel tags in the coverage ledger, and point the ledger at the new
  per-encounter table in `Encounter_Design_Document.md` as its companion view.
* Remove the paused marker from `Plan_Encounter_Solution_Design.md`'s entry in
  `Plans/README.md`, and from Phase 7's text in `Plan_Blowout_Alignment.md`.

## Findings

* **Concern — boss fight length sits outside its round budget until re-measured.**

  Phase 4 triples boss Health on the strength of a 50x burst the roster could not produce when
  this was written; the kit rework has since put the combined-modifier ceiling at 16.24x, 21.12x
  contrast (`Archive/Role_Kit_Design.md` section 4). `blowout_calibration.gd`'s
  `_ReportBaselines()` measured three champions at basic-skill output clearing a balanced boss
  in 5.9–11.1 rounds against 5.3's 10–12 budget before the retune; tripling Health pushed that
  to roughly 18–33 rounds with no burst available to shorten it. The retune-now sequencing was
  the owner's decision, taken with this consequence stated. Re-measure via
  `Tests/manual/blowout_calibration_report.gd` now that the kit rework has landed, and record
  the real figure here in place of the estimate. (The 5.9–11.1
  round range is unchanged by Phase 0's mitigation-formula change — it was calibrated to
  reproduce the old formula's basic-hit damage almost exactly.)

## Watch for

* **Do not convert enablers into damage.** `Concept_Document.md` 1.1.3 forbids it outright
  and 1.1.6 holds enablers to the collapse test instead. Only a **Boss-tier** encounter with
  no payoff anywhere in its configuration set is a defect; an enabler-only fodder or
  mini-boss verdict is a correct result, not a rework backlog.
* **Alignment, not authoring.** New opponent skills, statuses, or encounter entries belong
  to `Coverage gaps` and the volume batches, never to this retrofit.
* **The `BOSSES` constant and the `.tres` files move together**, and Defence moves not at
  all.
* **`Plan_System_Buildout.md` is still due.** The master plan already flags it as overdue
  against a one-entry spawn threshold, and this plan adds at least one more entry (catalog
  entries for the data-only Troll, Obsidian Stallion, and Militia battles). Spawning it
  is a separate decision with the plan's owner rather than this plan's work — but Phase 7
  must not close without raising it, since the retention rule in `Plans/README.md` deletes
  `Plan_Blowout_Alignment.md` on completion and its open work has to land somewhere living.
* Spell words out in full in identifiers and prose, per the naming convention.

## Verification

* `Tests/run_tests.sh` green, including the new Health-band and `BOSSES`-synchronisation
  tests. `test_encounter_assembly.gd`, `test_burst_reachability*.gd`, and `test_team_sweep.gd`
  must stay green untouched — they are what a stray Defence change would break, so their
  staying green is the evidence that only Health moved.
* `gdlint Scripts/` clean. Only `Scripts/Debug/blowout_calibration.gd` changes.
* `Tests/run_tests.sh -gtest=res://Tests/manual/blowout_calibration_report.gd -gexit` re-run
  after Phase 4. `_ReportBaselines()` gives the new rounds-to-kill, which replaces the
  estimate in the Findings entry above; `_ReportHealthImplications()` should report the
  retuned bosses satisfying the 60–80% burst share at 30–50x.
* `Tests/run_tests.sh -gtest=res://Tests/manual/team_corpus_sweep.gd -gexit` re-run after
  Phase 4, still reading the post-rework distribution: median 1.95x, 90th percentile 4.68x,
  ceiling 16.24x, contrast-ratio ceiling 21.12x (`Archive/Role_Kit_Design.md` section 4). A
  moved number means the Defence or Knowledge coupling in `burst_reachability.gd` was
  disturbed.
* One boss played end to end through a reworked configuration, launched via
  `Scripts/Debug/debug_catalog.gd`'s battle picker, confirming the fight reads as
  long-but-survivable rather than a stalemate.
* `/check-design` run against the changed sections — 5.3, 1.1.1, 1.1.2, the catalog entries,
  and both ledgers — to catch the tier-definition restatements drifting.

## Documentation

Tier definitions stay owned by `Concept_Document.md` section 5.3, with 1.1.1 and 1.1.2
amended alongside them. The per-encounter channel audit table and the reworked boss entries
land in `Encounter_Design_Document.md`. The coverage ledger's inline channel tags and the
production-rule changes land in `Plan_Encounter_Solution_Design.md`, which stays alive as the
ledger's home. `Plan_Blowout_Alignment.md` Phase 7 and `Plans/README.md` record completion
and the unpausing. No `Technical_Design_Document.md` entry is expected — this phase changes
data values and documents, not architecture.
