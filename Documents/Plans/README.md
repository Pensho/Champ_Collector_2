# Plans

One document per topic, sized so each can be executed and reviewed as an isolated
body of work. Findings behind these plans are recorded in
`Technical_Design_Document.md` sections 15.7–15.9.

Suggested order (dependencies noted inside each plan):

0. `Plan_Blowout_Alignment.md` — the master plan for aligning every system with the
   design pillar in `Concept_Document.md` section 1.1. Orders the work into phases
   (calibration, damage math, status channels, cascade, presentation, kits,
   itemization, encounters) and spawns a sub-plan per phase. Takes precedence over
   the plans below where they overlap; `Plan_Encounter_Solution_Design.md` is paused
   until Phase 7's `Plan_Encounter_Blowout_Retrofit.md` is executed. Phases 0–6 (calibration, combined modifier, status
   channels, cascade, burst presentation, kit burst reachability, itemization
   channels) are done and their sub-plans deleted; the kit rework Phase 5 spawned is
   complete, with `Role_Kit_Design.md` as its living record. Phase 7 produced
   `Plan_Encounter_Blowout_Retrofit.md`, executed through Phase 2 and now unblocked. Sub-plans
   are written when their prerequisites land and deleted under the retention rule below. It aligns existing systems and does not author
   new content — channels it finds too thinly populated to align are recorded in its
   `Coverage gaps` section, which spawned the now-completed and deleted `Plan_System_Buildout.md`.

1. `Plan_Relic_Implementation.md` — the Relic item type's code mechanism, spawned by
   the now-deleted `Plan_System_Buildout.md`'s coverage gap: splitting item type from rarity,
   carrying a Relic's effect, dispatching it alongside the wearer's trait, and implementing
   `Relic_Design.md`'s 24-entry catalog. Blocks nothing else; not yet started.

2. `Plan_Cascade_Channel_Cleanup.md` — the follow-up to the completed Channel 3 unification:
   retires the leftover Echo plumbing, moves Overflow, Rush and Mirror Coat off the Channel 3
   machinery their `Concept_Document.md` channel tags exclude them from, and realigns
   `Technical_Design_Document.md` 7.8. Blocks nothing; not yet started.

3. `Plan_Story_Mode_Systems.md` — the systems that deliver story mode (story
   state handler, dialogue overlay, flag-driven hub variants, act gating,
   scripted battle openings, guest champions). The state handler and dialogue
   overlay are independent and can start any time; scripted openings apply
   through the landed `BattleResolver`, and guest champions ride on the
   completed team and roster abstraction (`CombatTeam`/`CombatSides`).
   Design counterpart: `Plan_Story_Mode.md`.

Design-only plans (no code; can run at any time):

- `Plan_Encounter_Blowout_Retrofit.md` — Phase 7 of `Plan_Blowout_Alignment.md`. Retrofits
  the encounter tier definitions and the existing 14-entry catalog against the pillar: 5.3's
  tiers state a burst expectation, every encounter's answers are audited for which damage
  channel they feed (enabler included), Boss-tier entries with no payoff anywhere in their
  configuration set are reworked, and boss Health triples so a burst reads as 60–80% of the
  bar. Unpauses the plan below once it completes. Tier definitions and the channel audit are
  done; the boss configuration rework waited on the Role Kit Rework and **resumes now that it
  has landed** (`Role_Kit_Design.md`), behind a Phase 2b that re-derives the audit's
  channel tags against the reworked kits.
- `Plan_Encounter_Solution_Design.md` — **paused** pending execution of
  `Plan_Encounter_Blowout_Retrofit.md`; further volume batches authored under the current
  production rules add to the retrofit backlog. The long-run encounter content plan:
  designing encounters the Role kits solve (fodder / mini-boss / boss tiers),
  progression-agnostic with volume floors (at least 20 fodder / 10 mini-boss /
  10 boss), tiered overlap tolerance, an optional theme palette, and a coverage
  ledger tracking which kit answers which encounter. The Role kits it depends on
  are complete (`Concept_Document.md` 3.2.4.2); output lands in
  `Encounter_Design_Document.md`.
- `Plan_Story_Mode.md` — the narrative campaign: captures the four-act hub order
  and slum arc, then iterates a drama-curve pass, act beat sheets, lore-gap fills,
  and an integration pass. Output lands in a new `Story_Design_Document.md` plus
  `Concept_Document.md` 3.4.1; story battles route through
  `Plan_Encounter_Solution_Design.md`.
- `Plan_Particle_Effects.md` — living inventory of battle and environmental
  particle effects (archetype library, Adventure map overlays, hub ambience).
  Mostly design; its battle-effect infrastructure section spawns a future code
  plan. Soft ties to the completed data-driven status effects work (status-effect
  mapping home, see `StatusEffectData`) and `Adventure_Background_Visuals_Checklist.md`
  (fog and campfire props).
- `Plan_Lighting.md` — systemized 2D lighting for battles, the Adventure map, and
  hubs: one `LightingProfile` mood resource, a shared ambient rig, living
  (flicker/pulse) light archetypes. Design with a staged rollout; independent, but
  soft ties to `Plan_Particle_Effects.md` (paired light/emitter scenes) and
  `Adventure_Background_Visuals_Checklist.md` (glow-accent props).

## Findings section

A plan reviewed mid-flight (`/review-implementation` against a phase, or a fresh-context
reviewer) carries the surviving findings in a `## Findings` section, placed after the
phases and before `Watch for`. Each finding names a severity — **Blocker** (the phase it
names cannot be authored correctly until it is resolved), **Concern** (a real defect or
gap; fix within the named phase), **Nit** (cosmetic or bookkeeping) — and the phase that
resolves it.

The section lists **open work only**: fixing a finding deletes it, rather than annotating
it as fixed. A finding that is a standing property to preserve rather than a piece of work
belongs in `Watch for` instead, and a deviation from the plan belongs in its own phase
entry, phrased as what shipped. Plans with no open findings have no such section.

When a plan completes: run `/review-implementation` against the plan, then update
the documentation sections it names, **delete** the matching entries from
`Technical_Design_Document.md` section 15 — never annotate them as resolved — and
**delete** the plan file. A completed
plan's content belongs in the living documents; the file itself is history and git
keeps that. Archive to `Archive/` only when the file stays useful as a future
reference in its own right but doesn't fit the shape of an existing living document —
content the living documents do not absorb. If it does fit that shape, it moves to
`Documents/` as a design doc in its own right instead. `Role_Kit_Design.md` is the
latter case: the channel contract, synergy grammar, and per-Role coverage ledger
`Plan_Role_Kit_Rework.md` produced remain the balancing reference for every kit,
superseding the older `Plan_Role_Skill_Kits.md` it replaced there.
