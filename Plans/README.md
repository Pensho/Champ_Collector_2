# Plans

One document per topic, sized so each can be executed and reviewed as an isolated
body of work. Findings behind these plans are recorded in
`Technical_Design_Document.md` sections 15.7–15.9.

Suggested order (dependencies noted inside each plan):

1. `Plan_Team_And_Roster_Abstraction.md` — replace magic slot IDs with teams.
2. `Plan_Headless_Combat_Core.md` — extract testable combat resolution
   (largest; builds on the completed combat-correctness fixes and ideally 1).
3. `Plan_Data_Driven_Status_Effects.md` — status effects as resources
   (independent; hooks into 2 if done after it).
4. `Plan_Naming_Convention_Alignment.md` — align written conventions and code;
   mechanical, schedule last.
5. Reagent system, split into four sequential plans (independent of 1–4, but the
   combat-facing ones coordinate ordering with `Plan_Headless_Combat_Core.md` —
   whichever lands second adapts):
   1. `Plan_Reagent_Data_And_Catalog.md` — `ReagentData`, registry, authored catalog.
   2. `Plan_Reagent_Inventory_And_Storage_UI.md` — persistent inventory, loot
      drops, storage view.
   3. `Plan_Reagent_Combat_Application.md` — loadout, in-battle free-action
      consumption, `Reagent_Consumed` hook.
   4. `Plan_Sorcerer_Arcane_Instability.md` — the Sorcerer passive consuming that
      hook (Sorcerer champion itself is a separate prerequisite task).

Design-only plans (no code; can run at any time):

- `Plan_Role_Skill_Kits.md` — populate `Concept_Document.md` 3.2.4.2 with a full
  skill kit per Role, batch-brainstormed with a claims ledger to control
  buff/debuff/turn-bar overlap. Imports the Architect kit from
  `Plan_Architect_Calibration_Kit.md`.
- `Plan_Encounter_Solution_Design.md` — long-running framework for designing
  encounters the Role kits solve (fodder / mini-boss / boss tiers), with a
  coverage ledger tracking which kit answers which encounter. Depends on the
  kits from `Plan_Role_Skill_Kits.md`; batches append as scenarios are developed.
- `Plan_Particle_Effects.md` — living inventory of battle and environmental
  particle effects (archetype library, Adventure map overlays, hub ambience).
  Mostly design; its battle-effect infrastructure section spawns a future code
  plan. Soft ties to `Plan_Data_Driven_Status_Effects.md` (status-effect mapping
  home) and `Adventure_Background_Visuals_Checklist.md` (fog and campfire props).
- `Plan_Lighting.md` — systemized 2D lighting for battles, the Adventure map, and
  hubs: one `LightingProfile` mood resource, a shared ambient rig, living
  (flicker/pulse) light archetypes. Design with a staged rollout; independent, but
  soft ties to `Plan_Particle_Effects.md` (paired light/emitter scenes) and
  `Adventure_Background_Visuals_Checklist.md` (glow-accent props).

When a plan completes: run `/review-implementation` against the plan, then update
the documentation sections it names, strike the matching entries from
`Technical_Design_Document.md` section 15, and delete or archive the plan file.
