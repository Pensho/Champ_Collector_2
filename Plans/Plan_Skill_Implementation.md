# Plan: Skill Implementation

Implement the skills specified in `Concept_Document.md` 3.2.4 (champion Role
kits, universal skills) and `Encounter_Design_Document.md` section 1 (opponent
skills), together with the resolver capabilities they need. The design side is
complete; this plan sequences the code work into batches that can each be
executed, tested, and reviewed on their own.

## Status

Not started. Dependencies: the headless combat core (`BattleResolver`,
`CombatResult`, seeded generator — `Technical_Design_Document.md` section 7)
and data-driven status effects (section 6.1), both landed; and
**`Plan_Status_Effect_Implementation.md`**, which delivers the full status
effect catalog, the healing hook (`_ApplyHealthGain`), and the placeholder
icon generator this plan builds on. Batch 1 needs only that plan's batch 1;
later batches assume the catalog is complete.

## Scope and exclusions

In scope: every champion skill in Concept Document 3.2.4.2/3.2.4.3 and every
opponent skill in Encounter Design Document section 1 (including the three
opponent passives — they are cataloged as skills), plus the targeting types
and resolver mechanics those skills require. Presets for champions and
enemies that do not exist yet are created in the batch that lands their
skills (via the `new-champion` workflow), so every skill is attached and
testable. Every new skill and passive also gets a row in the placeholder icon
generator (`Scripts/Debug/generate_placeholder_icons.gd`, from the status
effect plan) so it is visually represented immediately.

Excluded (owned elsewhere or blocked on design):

- Status effects themselves — `Plan_Status_Effect_Implementation.md`.
- The Architect kit (Cornerstone, Raise the Frame, Final Calculation) —
  `Plan_Architect_Calibration_Kit.md`.
- Sorcerer reagent interactions — `Plan_Sorcerer_Arcane_Instability.md`; the
  Sorcerer's three skills are in scope here, the passive is not.
- The Alchemist's Fresh Batch passive and the reagent half of the Catalyst
  buff — the reagent plans. Catalyst Cloud (the zone) lands here.
- Champion passives (traits) in general: already-implemented ones are
  untouched, unimplemented ones are separate tasks — except the Emissary's
  Standing Record, which is a prerequisite of the Emissary skills (they read
  the Infraction tally) and therefore lands with them in batch 4.
- Pagan Curse — its cleanse depends on an undefined "Chant" mechanic; deferred
  until the Concept Document defines it.
- Already-implemented skills (Stab, Zap, Pierce Weakness, Disarm, Burning
  Bolas, the Tidal Corsair kit, Heap On, Flicker Zone, Fatal Flaw, Break
  Guard, Crush, Bash, Power Tide, Stalwart Hymn, Lava Zone) — only touched
  where a batch aligns them with the design docs (see Watch for).

## Approach (confirmed decisions)

- Skills stay data-driven: each lands as a `.tres` under
  `Data/Character_Skill_Variants/` in the matching subfolder, using the
  existing `Skill` resource (`Scripts/Character/skill_data.gd`). New mechanics
  extend the resolver (`Scripts/Battle/battle_resolver.gd`), the static
  helpers (`Scripts/Battle/skills.gd`), and the enums
  (`Scripts/common_enums.gd`) — never per-skill scripts.
- Batches are ordered by mechanical prerequisite, and within that by the
  coverage ledger in `Plan_Encounter_Solution_Design.md`, so the cataloged
  encounters get their intended answers as early as possible.
- Every batch runs the full gate cycle: GUT tests written alongside
  (`Tests/unit/test_*.gd`, using `helpers/test_factory.gd` and seeded
  resolvers), suite green, `gdlint Scripts/` clean, fresh-context review.
- Numbers marked "starting point" in the design docs are authored as stated
  and left for balancing; this plan never invents new values.

## Batches

### Batch 1 — skills on existing machinery

Everything expressible with the current `Skill` resource once the status
effect catalog exists: damage scaling, buff/debuff application, cooldowns,
defense ignore. No resolver changes.

- Champion skills: Thread Snap, Thread Lash, Woven Blessing (Herald of the
  loom); Case the Target (Thief); Acrid Splash, Dissolving Agent (Alchemist);
  Arc Lash (Sorcerer); Sharp Rebuttal, Expose Fallacy (Scholar); Sizing Cut,
  Flaw Analysis, Full Appraisal (Appraiser); Signal Strike, Battle Orders
  (Tactician); Spore Lash, Symbiotic Overdrive (Symbiote); Profane Bolt
  (Cultist); Septic Lance, Quarantine Breach (Plague Doctor); Shield Slam,
  Hold the Line, Brace for Impact (Warlord); Lance Thrust, Rending Charge
  (Lancer); Ill Omen, Premonition (Diviner); Headbutt (Bar Brawler).
- Opponent skills: Wind the Mainspring (self-Haste stacking), Overwhelming
  Blow (compare against the existing Crush before authoring a duplicate),
  Rally the Crew, Cinder Spit, Vault Slam.

### Batch 2 — healing and health costs

Skills that restore Health (through the status plan's `_ApplyHealthGain`,
routed through `ResolveSkill` with heal targeting) and skills that cost the
caster or allies Health. Includes most-injured-ally selection for heal
targeting.

- Champion skills: Fateful Glimpse (Diviner); Grafted Flesh (Symbiote);
  Liquid Courage (Bar Brawler); Blood Bolt, Transfusion, Tithe of Vitality
  (Bloodmage).
- Opponent skills: Sporeburst Mend.

### Batch 3 — targeting extensions and per-battle ramps

New `Skill_Target` variants: Left-most Enemy, Right-most Enemy (absolute,
party-order based — characters need a battlefield slot index the resolver can
read; Spotlight must not redirect these), and most-injured-enemy selection.
Generalize the Heap_On per-resolver ramp so any skill can declare per-use
growth, and support ally-side turn-bar pushes. Spotlight's targeting-weight
half (dormant since the status plan) goes live with the enemy-targeting work
here.

- Champion skills: none (champion kits do not use positional targeting).
- Opponent skills: Flank Cut, Breaching Charge (+15% per use), Aimed Shot,
  March Cadence (+10% turn bar to all other allies), Cinder Sermon (per-cast
  permanent ramp on an AoE).

### Batch 4 — buff manipulation and the Emissary

New resolver primitives: removing a buff from a target and re-applying it
elsewhere (theft), reducing buff durations, consuming a set of buffs and
counting them, and per-buff-count damage scaling.

- Prerequisite trait: Standing Record (Emissary passive — per-enemy
  Infraction tally, capped at 9, fed by buff gains, zone placements, and
  debuffs landed; the Sanction debuff's dormant magnitude source goes live).
- Champion skills: Citation, Signed Writ, Levied Sanction (Emissary); Devour
  Blessing, Rite of Severance (Cultist); Pratfall Sting (avoided-attack bonus
  read from the Jester's trait state) and Center Stage (Jester).
- Opponent skills: Foreclosure (+20% per held buff), Writ of Seizure (steal
  to the designated ward), Reliquary Ward (alternating Barrier / Deathward).

### Batch 5 — zone system alignment and new zones

Align zones with Concept Document 3.2.4.1 — charges instead of durations,
player-chosen section placement, blocked placement into occupied sections —
and make zone effects data-driven (a zone-effect definition on the `Skill` or
a dedicated resource, replacing the per-type match arm in
`_ResolveZoneEffect`). Migrate Flicker Zone and Lava Zone onto the new model.

- Champion skills: Catalyst Cloud (Alchemist); Unstable Rift, Cataclysmic
  Surge (Sorcerer); Refutation (Scholar — zone removal, per-charge
  punishment, ally-cooldown refund); Temporal Sinkhole (Chronophage); Miasma
  (Plague Doctor); Weight of Law (unassigned zone).
- Opponent skills: Inscribe (Wild Glyph), Inscription Surge
  (per-standing-zone scaling).

### Batch 6 — opponent passives and encounter assembly

Opponent passives as `CharacterTrait` subclasses. The `OnDeath` hook fires
but carries no context — extend its signature so a trait can react to an
*ally's* death (Ash Offering, Warden's Failsafe) and so Lien can run a
turn-start check with an internal 4-turn cooldown.

- Passives: Ash Offering, Lien, Warden's Failsafe.
- Assembly: enemy presets (`Data/Character_Enemy_Variants/`) and battle
  definitions (`Data/Battle_Variants/`) for the encounters cataloged in
  Encounter Design Document section 2, wiring the skills from all prior
  batches to their owners (Sporeback Matron, Bosun, War Drummer, Ridge
  Marksman, Flank Cutter, Plains Charger, Cinder Husks, the Ashen Oracle, the
  Glyphbound Archivist, the Collector of Debts and Warded Notary, the Vault
  Warden and Reliquary Core, the Warded Clerks, the Reanimating Statues).

## Watch for

- The enemy-turn invariant that skill slot 0 has zero cooldown
  (`test_character_preset_skill_invariant.gd`) must hold for every new preset.
- Skills are deep-copied per character instance; any new per-battle skill
  state (ramps, alternation counters like Reliquary Ward's) belongs on the
  resolver, not the `Skill` resource — follow the Heap_On precedent.
- `Break_Guard.tres` is currently attached to the Bar Brawler, but the design
  docs catalog Break Guard as an opponent skill and give the Bar Brawler
  Headbutt instead — realign in batch 1.
- `Fatal_Flaw.tres` targets All Other Allies; Concept 3.2.4.2 says one ally —
  flag with the user before changing either side.
- If the Concept Document and the Encounter Design Document disagree on a
  skill, the Concept Document wins — flag the conflict instead of silently
  picking.
- The coverage-ledger review threshold (an effect answering more than 3
  mini-boss/boss encounters) is a design constraint, not a code one, but
  batch-6 assembly should re-check it before wiring presets.

## Documentation

- Update `Technical_Design_Document.md` sections 6.1 (resource templates),
  7.4 (skill resolution), and 7.5 (zones) whenever a batch changes the
  architecture — the zone rework in batch 5 and the heal path in batch 2
  certainly will.
- Strike the remaining skill-related "(Not yet implemented)" markers in
  Concept Document 3.1.3 as passives and kits land.
- On completion: run `/review-implementation` against this plan, update the
  documents above, then delete this file per the `Plans/README.md` retention
  rule.
