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
4. Naming convention alignment — completed and deleted; file and identifier casing
   now matches the stated `snake_case`/`PascalCase` conventions (see
   `Technical_Design_Document.md` section 15.3).
5. Reagent system, split into four sequential plans (independent of 1–4; the
   combat-facing ones apply their effects through `BattleResolver`, since the
   headless combat core has landed):
   1. Reagent data and catalog — completed and deleted; `ReagentData`
      (`Scripts/Battle/reagent_data.gd`), `ReagentRegistry`, and the authored
      feasible-subset catalog (`Data/Reagents/`) are live (see
      `Technical_Design_Document.md` section 6.1).
   2. Reagent inventory and storage UI — completed and deleted; `ReagentCollection`
      (`Scripts/Gear/reagent_collection.gd`), loot-drop acquisition through
      `LootManager`/`LootTable`, and the storage/sell view in
      `Inspect_Collection_Menu` are live (see `Technical_Design_Document.md`
      sections 6.1 and 10.1).
   3. Reagent combat application — completed and deleted; pre-battle loadout
      selection, headless free-action resolution (`BattleResolver.ResolveReagent`,
      `ReagentResolver`, `ReagentLoadout`), the `Reagent_Consumed` trait hook, and
      the in-battle reagent tray are live (see `Technical_Design_Document.md`
      section 7.7).
   4. Sorcerer Arcane Instability passive — completed and deleted; the trait
      (`Scripts/Character/character_traits/CharacterSpecificTraits/sorcerer_trait.gd`)
      consumes the `Reagent_Consumed` hook and the new `BattleResolver.ResolveTraitDamage`
      entry point for the Surge (see `Technical_Design_Document.md` section 9).
      Assigning it to the Sorcerer champion itself is a separate prerequisite task
      (the champion preset does not exist yet).

6. `Plan_Status_Effect_Implementation.md` — completed and deleted; the full status
   effect catalog (`Concept_Document.md` 3.2.3) lives as `StatusEffectData`
   resources looked up through `StatusEffectRegistry`, plus the placeholder icon
   generator (also serving skills and passives later) (see
   `Technical_Design_Document.md` section 6.1).

7. `Plan_Skill_Implementation.md` — the skill catalog made real: champion Role
   kits (`Concept_Document.md` 3.2.4) and opponent skills
   (`Encounter_Design_Document.md` section 1) in six mechanical batches.
   Depends on `Plan_Status_Effect_Implementation.md` (effects, healing hook,
   icon generator); the final batch assembles the enemy presets the encounter
   catalog needs, so it feeds `Plan_Encounter_Solution_Design.md` playability.

8. `Plan_Story_Mode_Systems.md` — the systems that deliver story mode (story
   state handler, dialogue overlay, flag-driven hub variants, act gating,
   scripted battle openings, guest champions). The state handler and dialogue
   overlay are independent and can start any time; scripted openings apply
   through the landed `BattleResolver`, and guest champions ride on the
   completed team and roster abstraction (`CombatTeam`/`CombatSides`).
   Design counterpart: `Plan_Story_Mode.md`.

9. `Plan_Missing_Role_Champions.md` — completed and deleted; all nine roles that
   lacked a playable champion (Emissary, Alchemist, Sorcerer, Diviner, Appraiser,
   Symbiote, Cultist, Plague Doctor, Warlord) now have a preset with its role
   passive as a trait, placeholder skill kit, and placeholder art (see
   `Technical_Design_Document.md` sections 3.1 and 9). The placeholder kits are
   superseded by `Plan_Skill_Implementation.md`'s Role kits when those land.

10. `Plan_Symbiote_Graft_Passive.md` — the machinery for the Symbiote's `Graft`
    passive (`Concept_Document.md` 3.1.3): a `GraftEffect` resource extending
    `CharacterTrait` (effect via the existing `_trait` dispatch) plus a derived
    attribute layer (mirroring equipment), a per-enemy `_graft_effect` preset
    field, one-time in-battle free-action grafting modeled on reagent consumption,
    persistence by graft UID, and the Inspect Collection display. Depends on the
    Symbiote preset from `Plan_Missing_Role_Champions.md`. Ships no graft content;
    the concrete pool comes from a future brainstorm / design document.
    Implemented — pending reconciliation (review, fold into
    `Technical_Design_Document.md`, strike section 15, delete) once its suite is
    confirmed green.

11. `Plan_Symbiote_Graft_Pool.md` — the concrete graft content from
    `Symbiote_Graft_Pool.md` (18 grafts), turned into `GraftEffect` subclasses on the
    landed machinery (item 10). Phased: this plan implements **Batch 1**, the four grafts
    buildable with no new engine code (Wretched Conscript, Spreading Rot, Reactive Plating,
    Strength in Numbers). Enemy-to-graft sourcing stays deferred until more opponents exist.
    The remaining 14 grafts each need a new engine primitive and live in their own plans:
    - `Plan_Graft_Healing_Primitives.md` — public heal + lifesteal (Hollow Hunger, Carrion
      Bloom, Overgrowth).
    - `Plan_Graft_Turn_Bar_Control.md` — resolver turn-bar ordering + push/pull (Caravan
      Cadence, Gravitic Rot, Contagion Bond).
    - `Plan_Graft_Retaliation.md` — attacker-aware damage-taken reaction (Glass Refraction,
      Undertow, Glamour).
    - `Plan_Graft_On_Kill_And_Conditional_Damage.md` — killing-blow hook + conditional
      damage (Bloodscent).
    - `Plan_Graft_Zone_Extensions.md` — dual-faction zone, charge replenishment,
      affected-by-zone hook (Living Bloom, Rootfeeder).
    - `Plan_Graft_Event_Triggers.md` — buff-expired / zone-dissipated triggers, broadened
      `Reagent_Consumed` (Detritivore).
    - `Plan_Graft_Tether.md` — random-ally tether with attribute sharing (Symbiotic Anchor).

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
