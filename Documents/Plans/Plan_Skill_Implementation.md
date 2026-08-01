# Plan: Skill Implementation

Implement the skills specified in `Concept_Document.md` 3.2.4 (champion Role
kits, universal skills) and `Encounter_Design_Document.md` section 1 (opponent
skills), together with the resolver capabilities they need. The design side is
complete; this plan sequences the code work into batches that can each be
executed, tested, and reviewed on their own.

## Status

Batches 0–4 are complete; batches 5–6 remain, but every dependency they rested
on is now satisfied. The headless combat core (`BattleResolver`, `CombatResult`,
seeded generator — `Technical_Design_Document.md` section 7) and data-driven
status effects (section 6.1) both landed, and **`Plan_Status_Effect_Implementation.md`
is complete and deleted**: the full status effect catalog, the heal path
(`BattleResolver.ResolveTraitHeal`, emitting `CombatResult.Kind.Heal`), and the
placeholder icon generator this plan builds on are all in place. The status
effects several later skills need are already authored (e.g.
`Data/Status_Effects/Sanction.tres`, `Signed_Writ.tres`).

## Scope and exclusions

In scope: every champion skill in Concept Document 3.2.4.2/3.2.4.3 and every
opponent skill in Encounter Design Document section 1 (including the three
opponent passives — they are cataloged as skills), plus the targeting types
and resolver mechanics those skills require. Champion presets already exist
under `Data/Character_Player_Variants/`, each carrying placeholder skills
(e.g. the Emissary holds Bash/Disarm/Break Guard), so the champion-skill work
is attaching each Role's real skills to its existing preset rather than
creating it. Enemy presets that do not exist yet are created in the batch that
lands their skills (batch 6, via the `new-champion` workflow), so every skill
is attached and testable. Every new skill and passive is given an icon
directory and a placeholder icon up front in batch 0, via the placeholder icon
generator (`Scripts/Debug/generate_placeholder_icons.gd`, from the status
effect plan), so each skill is visually represented from the moment its `.tres`
lands.

Excluded (owned elsewhere or blocked on design):

- Status effects themselves — `Plan_Status_Effect_Implementation.md`
  (complete and deleted; its catalog is in place).
- The Architect kit (Cornerstone, Raise the Frame, Final Calculation) —
  `Plan_Architect_Calibration_Kit.md`. Since landed (`Cornerstone.tres`,
  `Raise_the_Frame.tres`, `Final_Calculation.tres`); still owned by that plan
  and out of scope here.
- Sorcerer reagent interactions — `Plan_Sorcerer_Arcane_Instability.md`; the
  Sorcerer's three skills are in scope here, the passive is not.
- The Alchemist's Fresh Batch passive and the reagent half of the Catalyst
  buff — the reagent plans. Catalyst Cloud (the zone) lands here.
- Champion passives (traits) in general: already-implemented ones are
  untouched, unimplemented ones are separate tasks. The Emissary's Standing
  Record — a prerequisite of the Emissary skills (they read the Infraction
  tally) — is already implemented
  (`standing_record_trait.gd` + `Standing_Record_Trait.tres`, wired to the
  Emissary preset), so batch 4 only authors the skills that consume it.
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

### Batch 0 — skill icon directories and placeholders (complete)

Give every skill and passive this plan will author its icon directory and a
flat-color placeholder before any `.tres` is written, so later batches can
point each skill's `icon_path` at an image that already exists. This mirrors
how the reagent and status-effect tables in
`Scripts/Debug/generate_placeholder_icons.gd` seed their art.

- Add a `SKILL_ICON_TABLE` to the generator alongside the existing
  `REAGENT_FAMILY_TABLE` and `STATUS_EFFECT_TABLE`, with one row per skill and
  passive across batches 1–6 (champion skills, opponent skills, opponent
  passives, and the Standing Record prerequisite trait). Skills are not
  rarity-tiered, so — like the status-effect rows — each row writes a single
  flat-color PNG rather than one per rarity tier.
- Each row targets the reorganized per-ability folder layout under `ICON_ROOT`
  — `Abilities/Role_Active_Skills/<Skill_Name>` for champion skills,
  `Abilities/Opponent_Active_Skills/<Skill_Name>` for opponent skills, and
  `Abilities/Passives/<Passive_Name>` for passives (matching the existing
  `Icons/Abilities/Role_Active_Skills/Stab/`, etc.) — and gives the skill a
  distinct base hue.
- Extend `_run()` (or factor a shared helper) so the new table is iterated with
  the same "skip if the file already exists" guard, so the real ability art
  already under `Icons/Abilities/` is never clobbered.
- Run the generator headless to create the directories and PNGs:
  `godot --headless -s res://Scripts/Debug/generate_placeholder_icons.gd`.
- Gate cycle applies: a GUT test asserting the table is well-formed (unique
  folders/names, expected row count), `gdlint Scripts/` clean, review. Only
  skills excluded from this plan's scope (see "Scope and exclusions") are
  omitted from the table.

Watch for: skills already shipping real art (Stab, Zap, the Tidal Corsair kit,
etc.) keep their existing files under `Icons/Abilities/Role_Active_Skills/` —
the skip guard protects them, and only the skills this plan actually authors
need new rows.

### Batch 1 — skills on existing machinery (complete)

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

### Batch 2 — healing and health costs (complete)

Skills that restore Health and skills that cost the caster or allies Health.
A heal path already exists (`BattleResolver.ResolveTraitHeal`, emitting
`CombatResult.Kind.Heal`); this batch routes heal-targeted skills through
`ResolveSkill` onto that same health-gain application rather than building a new
hook. Includes most-injured-ally selection for heal targeting.

- Champion skills: Fateful Glimpse (Diviner); Grafted Flesh (Symbiote);
  Liquid Courage (Bar Brawler); Blood Bolt, Transfusion, Tithe of Vitality
  (Bloodmage).
- Opponent skills: Sporeburst Mend.

### Batch 3 — targeting extensions and per-battle ramps (complete)

New `Skill_Target` variants: Left-most Enemy, Right-most Enemy (absolute,
party-order based — resolved directly off `CombatSides`/`CombatTeam`'s
already-ordered party arrays, no new `Character` field needed; Spotlight does
not redirect these, since they never touch `Battle._targeting_order`), and
most-injured-enemy selection. Generalized the Heap_On per-resolver ramp into
`Skill.ramp_per_use` (keyed per caster+skill, so any skill can declare
per-use growth independent of the caster's other skills), and migrated Heap
On itself onto it (a follow-up beyond this batch's original scope, since the
two mechanisms turned out to be mathematically identical — see
`Skill_Type.Heap_On`'s vestigial-but-kept enum entry). Added ally-side
turn-bar pushes (needed no resolver change — `_EmitTurnBarBump` was already
side-agnostic). Spotlight's targeting-weight half (dormant since the status
plan) is live: `StatusEffectData.targeting_weight_multiplier`, read by
`Battle.SetTargetingOrder()`, which now also runs every turn rather than only
at battle start, so a targeting-weight buff gained mid-battle takes effect
immediately.

- Champion skills: none (champion kits do not use positional targeting).
- Opponent skills: Flank Cut, Breaching Charge (+15% per use), Aimed Shot,
  March Cadence (+10% turn bar to all other allies), Cinder Sermon (per-cast
  permanent ramp on an AoE).

### Batch 4 — buff manipulation and the Emissary (complete)

New resolver primitives: removing a buff from a target and re-applying it
elsewhere (theft), reducing buff durations, consuming a set of buffs and
counting them, and per-buff-count damage scaling.

- Prerequisite trait: Standing Record (Emissary passive — per-enemy
  Infraction tally, capped at 9, fed by buff gains, zone placements, and
  debuffs landed) is already implemented (`standing_record_trait.gd` +
  `Standing_Record_Trait.tres`); this batch only wires the skills that read the
  tally, and takes the Sanction debuff's dormant magnitude source live.
- Champion skills: Citation, Signed Writ, Levied Sanction (Emissary); Devour
  Blessing, Rite of Severance (Cultist); Pratfall Sting (avoided-attack bonus
  read from the Jester's trait state) and Center Stage (Jester).
- Opponent skills: Foreclosure (+20% per held buff), Writ of Seizure (steal
  to the designated ward), Reliquary Ward (alternating Barrier / Deathward).

The flat `Skill` fields this batch introduced (`buff_duration_overrides`,
`consume_buffs`, `damage_bonus_per_buff`, `steal_buff_count`/`steal_buff_to`,
`alternating_buffs`, `escalated_at_infractions`,
`bonus_damage_on_trait_condition`, `barrier_from_target_max_health`) are
replaced by effect components in `Plan_Skill_Effect_Components.md`; the skills
themselves are unchanged. Author any further skill against the effect schema,
not these fields.

### Batch 5 — zone system alignment and new zones

Align zones with Concept Document 3.2.4.1 — charges instead of durations,
player-chosen section placement, blocked placement into occupied sections —
and make zone effects data-driven (a zone-effect definition on the `Skill` or
a dedicated resource, replacing the per-type effect logic). The zone lifecycle
now lives in `Scripts/Battle/zone_resolver.gd` (`ZoneResolver`, with its
`ActiveHook`), not a `_ResolveZoneEffect` match arm in `battle_resolver.gd`, and
zones are still `_duration`-based — so target the charge/section rework and the
data-driven effect definition at `ZoneResolver`. Migrate Flicker Zone and Lava
Zone onto the new model.

`Plan_Skill_Effect_Components.md` moved zone **placement** onto a `ZoneEffect`
component: a zone skill's duration and debuff list now come from that effect
rather than the `Skill.duration`/`Skill.debuffs` fields, which no longer exist,
and `ZoneResolver.PlaceZone` reads it. Everything inside `ZoneResolver` after
placement — the lifecycle, per-type effect logic, and `ActiveHook` — was
deliberately left untouched and is still this batch's job. Build the charge and
section rework, and the data-driven zone-effect definition, on `ZoneEffect`
rather than introducing a second zone-data resource.

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
- `Break_Guard.tres` is currently attached to the Bar Brawler (and now also to
  the Cultist and Emissary presets, all as placeholders), but the design docs
  catalog Break Guard as an opponent skill and give the Bar Brawler Headbutt
  instead; `Headbutt.tres` does not exist yet — realign in batch 1.
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
  architecture — the zone rework in batch 5 certainly will. The heal path and
  status catalog are already documented, having landed with the completed
  status-effect and Architect plans.
- Strike the remaining skill-related "(Not yet implemented)" markers in
  Concept Document 3.1.3 as passives and kits land.
- On completion: run `/review-implementation` against this plan, update the
  documents above, then delete this file per the `Plans/README.md` retention
  rule.
