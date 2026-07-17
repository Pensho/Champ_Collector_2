# Plans

One document per topic, sized so each can be executed and reviewed as an isolated
body of work. Findings behind these plans are recorded in
`Technical_Design_Document.md` sections 15.7–15.9.

Suggested order (dependencies noted inside each plan):

1. Team and roster abstraction — completed and deleted; combat now runs on
   `CombatTeam`/`CombatSides` (see `Technical_Design_Document.md` section 4).
2. Headless combat core — completed and deleted; combat resolution lives in
   `BattleResolver` with `CombatResult` records and a seeded generator (see
   `Technical_Design_Document.md` section 7).
3. Data-driven status effects — completed and deleted; buff/debuff magnitude,
   overwrite/stack rules, and icons live on `StatusEffectData` resources looked up
   through `StatusEffectRegistry` (see `Technical_Design_Document.md` section 6.1).
4. `Plan_Naming_Convention_Alignment.md` — align written conventions and code;
   mechanical, schedule last.
5. Reagent system, split into four sequential plans (independent of 1–4; the
   combat-facing ones apply their effects through `BattleResolver`, since the
   headless combat core has landed):
   1. `Plan_Reagent_Data_And_Catalog.md` — `ReagentData`, registry, authored catalog.
   2. `Plan_Reagent_Inventory_And_Storage_UI.md` — persistent inventory, loot
      drops, storage view.
   3. `Plan_Reagent_Combat_Application.md` — loadout, in-battle free-action
      consumption, `Reagent_Consumed` hook.
   4. `Plan_Sorcerer_Arcane_Instability.md` — the Sorcerer passive consuming that
      hook (Sorcerer champion itself is a separate prerequisite task).

6. `Plan_Story_Mode_Systems.md` — the systems that deliver story mode (story
   state handler, dialogue overlay, flag-driven hub variants, act gating,
   scripted battle openings, guest champions). The state handler and dialogue
   overlay are independent and can start any time; scripted openings apply
   through the landed `BattleResolver`, and guest champions ride on the
   completed team and roster abstraction (`CombatTeam`/`CombatSides`).
   Design counterpart: `Plan_Story_Mode.md`.

Design-only plans (no code; can run at any time):

- `Plan_Encounter_Solution_Design.md` — the long-run encounter content plan:
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

When a plan completes: run `/review-implementation` against the plan, then update
the documentation sections it names, strike the matching entries from
`Technical_Design_Document.md` section 15, and **delete** the plan file. A completed
plan's content belongs in the living documents; the file itself is history and git
keeps that. Archive to `Archive/` only when the file stays useful as a future
reference in its own right — content the living documents do not absorb.
`Plan_Role_Skill_Kits.md` is the example: its claims ledger is the balancing
reference for effect assignments.
