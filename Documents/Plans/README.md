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
   channels) are done and their sub-plans deleted; Phase 5 produced
   `Plan_Channel_Population_Rework.md`, carrying its prescriptions forward, and Phase 7
   produced `Plan_Encounter_Blowout_Retrofit.md`, partially executed then paused pending kit
   rework. `Plan_Channel_Population_Rework.md` is superseded by `Plan_Role_Kit_Rework.md`
   below and is deleted by that plan's Phase 0. Sub-plans
   are written when their prerequisites land and deleted under the retention rule below. It aligns existing systems and does not author
   new content — channels it finds too thinly populated to align are recorded in its
   `Coverage gaps` section, which spawns `Plan_System_Buildout.md` once it holds more
   than one entry.

1. `Plan_Role_Kit_Rework.md` — the authoring counterpart to the master plan, superseding
   `Plan_Channel_Population_Rework.md`. Reworks the skill kits of all 20 Roles so the three
   damage channels are populated and several *independent* team combinations reach the
   aggregate target, rather than the single ceiling pairing the roster has today. Phase 0
   gates the rest: it makes Defence matter at burst scale (rejecting the `Concept_Document.md`
   1.1.4 bullet on legibility grounds) and re-derives 1.1.2's calibration figures, so kits are
   designed once against real targets. Output lands in a new `Documents/Role_Kit_Design.md`
   (the living channel and synergy ledger) and `Concept_Document.md` 3.2.4.2. Unblocks
   `Plan_Encounter_Blowout_Retrofit.md`, which was paused pending kit rework.

2. `Plan_Story_Mode_Systems.md` — the systems that deliver story mode (story
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
  done; **paused** before the boss configuration rework, since it would commit specific
  kit/role pairings to each boss ahead of `Plan_Role_Kit_Rework.md` reworking kit
  contributions — resume once that plan lands. Note that its Phase 4 Health retune is also
  downstream of that plan's Phase 0, which changes the mitigation formula.
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
reference in its own right — content the living documents do not absorb.
`Plan_Role_Skill_Kits.md` is the example: its claims ledger is the balancing
reference for effect assignments.
