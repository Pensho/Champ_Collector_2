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

Phases 0-6 are done; **Phase 7 is the only remaining work in this plan, and is unblocked.**

Each completed phase's outcome lives in the documents it updated, not here: the combined modifier
and the cascade architecture in `Technical_Design_Document.md` 7.4 and 7.8, burst pacing in 7.9,
the status channel tags, modifier boundary and status cap in `Concept_Document.md` 1.1.4 and
3.2.3, the gear verdict in 3.3.1, and Phase 0's calibration findings in 1.1.2 and 1.1.4. Phase 0's
harness is kept at `Scripts/Debug/blowout_calibration.gd` and re-answers those questions whenever
the formula or the presets change. Every sub-plan spawned by Phases 1-6 is deleted per the
retention rule.

The roster sweep baseline these phases moved is `Role_Kit_Design.md` section 4's, which owns
the current figures; the pairing-web work it carried forward is complete.

## Phases

Phases 0-6 are complete and their sections are deleted per the retention rule.

### Phase 7 — Encounter tier and catalog retrofit — in progress

**Produced:** `Plan_Encounter_Blowout_Retrofit.md`, executed through Phase 2 (tier definitions
and the channel audit). The kit rework it waited on is complete
(`Role_Kit_Design.md`), so Phase 2b onward is unblocked.

Four decisions were settled with the plan's owner before the sub-plan was written, so it is
written as prescriptions rather than questions: the boss Health retune happens now rather than
waiting on the kit rework (its cost is carried as a Finding, see below);
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

Spawned to `Plan_System_Buildout.md`, which carries every open entry — the roster's cross-kit
composition thinness and the Sorcerer's repeat both closed instead, by `Plan_Role_Kit_Rework.md`'s
own final sweep (median 1.95x, 90th percentile 4.68x, ceiling 16.24x, 114 top-decile teams across
10 distinct pairings; the Sorcerer/Cataclysm pairing itself reaches the top decile at 19 teams).

## Watch for

* Sub-plans are written when their prerequisites land, not up front.
* **An under-populated channel is a result, not a null result.** Every phase asks its audit
  question — is each existing entry aligned — and a coverage question alongside it: does the
  existing corpus populate this channel densely enough to design against at all. A phase that
  finds nothing to rework has not thereby found nothing; record the gap above rather than
  closing the phase clean.
* The pillar outranks the rest of the Concept Document. When a phase finds a conflict, the
  other section is the one that changes — but flag it rather than rewriting silently.
* **The contrast baseline is unsettled.** Section 1.1.2 measures a burst against the bursting
  champion's own basic skill. Under the composition law a burst is a team product, so the honest
  baseline may instead be the team's average per-action output, which would move the target
  substantially. Left to settle against a playable burst rather than emulated now.
* **Defence going irrelevant at burst scale is a risk, not a settled win.** Deferred to
  `FeatureIdeas.md` ("Defence Relevance at Burst Scale"). Phase 7's encounter Defence tuning
  should treat the irrelevance as inherited from section 1.1.4, not re-litigate it. It
  load-bears the verdict that Expose_Weakness is channel 1, not channel 2 — that stands until
  the backlog item is picked up.

## Documentation

Phase 7 rewrites part of `Encounter_Design_Document.md` and updates section 5.3's tier
definitions.
