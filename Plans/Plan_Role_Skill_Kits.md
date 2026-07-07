# Plan: Role Skill Kits

Populate `Concept_Document.md` 3.2.4.2 with a full skill kit for every Role: one basic
skill (no cooldown) plus two signature skills, per the skill rules in 3.2.4. Kits must
fit each Role's theme and passive (3.1.3) and must not overlap each other too much in
which buffs, debuffs, and turn bar effects they apply. This is a **design-only pass** —
all output lands in `Concept_Document.md`; no code is written.

## Status

In progress. All four batches are written into 3.2.4.2; only the final pass
(step 5) remains. Open slots to revisit:

- Herald of the loom: the three thread stances live in the (currently empty) passive
  slot — stance selection at the start of the Herald's turn, to be defined in a
  later passive pass, not in the skills.

- Bloodmage: both signature skills.
- Sorcerer: Unstable Rift's second effect; the third skill.
- Tidal Corsair: the finisher's stack payloads may be revised.
- Emissary: both signature skills. Under consideration: a Signed Writ skill
  (cooldown 3) that reduces the target's buff durations by 1 turn and applies
  Signed Writ reworked as a 1-turn debuff (the target cannot resist other debuffs) —
  adopting it moves Signed Writ from the buff catalog to the debuff catalog in 3.2.3.2.
- Appraiser: third skill.

Independent of the implementation plans; can run at any time. One overlap:
the Architect's kit is already designed in `Plan_Architect_Calibration_Kit.md` — this
plan imports that kit sketch into 3.2.4.2 verbatim and does not redesign it.

## Design (confirmed decisions)

- **Kit size:** every Role gets a full kit of 3 (one basic + two signature skills),
  written into its heading in 3.2.4.2. Roles whose passive is still blank get a kit
  anyway; the passive can follow later.
- **Scope:** all 20 Roles in 3.1.3, including the "Not yet implemented" ones and the
  Appraiser. Unimplemented Roles stay doc-only.
- **Catalog-first:** skills draw their effects from the existing catalogs in 3.2.3
  (turn bar effects, common debuffs and buffs) and the zone rules in 3.2.4.1. A new
  effect is invented only when a Role's theme demands it, and is added to the 3.2.3
  catalog in the same edit.
- **Reagents:** very few skills touch reagents. Only the Alchemist and the Sorcerer —
  the two Roles whose passives already engage the reagent system — may have
  reagent-referencing skills. No other Role's kit mentions reagents.
- **No universal counterplay skills:** zone clearing stays exclusive to the Scholar's
  kit and the zone-clearing reagent (3.2.4.1); no kit gets a generic
  cleanse-everything or block-everything answer.
- **Numbers are welcome:** brainstormed skills may carry concrete numbers; they are
  balancing starting points, not commitments.
- **Durations are explicit:** a skill entry that applies a buff or debuff states the
  effect's duration, even when it matches the 2-turn default in 3.2.3.
- **Passive-driven kits are a niche, not the default:** skills may reference the
  Role's passive (the Tidal Corsair's stack generators, the Architect's charge
  economy), but most kits should stand on their own and cover unclaimed catalog
  effects — there is plenty of empty effect space to spend before leaning on
  passives.

## Overlap rules

The anti-overlap tool is the claims ledger below. Rules applied when picking skills:

- **Identity effects** (Warped, Catalyst, Plague, and any effect a passive or signature
  zone is built around) belong to exactly **one** Role.
- **Commodity effects** (the plain ±attribute buff/debuff family: Empower, Slow, Blind,
  Fortify, …) may appear in at most **two** kits.
- **Turn bar effects** (3.2.3.1) may appear in at most **one** kit each — there are
  only seven, and they are the Control identity space.
- Basic skills default to plain damage or plain healing with an attribute scaling that
  matches the Role — they should rarely spend an effect claim.
- **Zones stay signature.** Only Roles with a declared signature zone (Alchemist,
  Sorcerer, Chronophage, Plague Doctor, Architect) get zone-placing skills; Weight of
  Law is assigned to at most one Role or stays generic.

## Batches

Roles are brainstormed in batches grouped by purpose, so the Roles most likely to
collide are designed in the same session where overlap is visible. Order within the
pass:

1. **Damage:** Thief, Lancer, Bloodmage, Tidal Corsair, Sorcerer.
2. **Debuffer / Control:** Emissary, Diviner, Plague Doctor, Cultist, Appraiser,
   Chronophage.
3. **Buffer / Support:** Tactician, Scholar, Alchemist, Herald of the loom, Architect.
4. **Sustain / Tank:** Jester, Symbiote, Bar Brawler, Warlord.

Per-batch procedure:

1. Run `/brainstorm` for the batch, prompting with: each Role's 3.1.3 entry, the
   current claims ledger, the overlap rules, and any per-role constraint below.
2. The user picks from the candidates (or redirects).
3. Write the picked kits into 3.2.4.2 under the Role's heading; move any claimed
   generic skill out of 3.2.4.3; add newly invented effects to 3.2.3.
4. Update the claims ledger and check no rule is violated before the next batch.

## Per-role constraints

- **Lancer:** the kit must contain at least one offensive and one defensive skill —
  Reckless Momentum depends on both existing.
- **Emissary:** no hard skill sealing, no turn bar manipulation; punishments are
  gradual (cooldown extension, debuff duration extension, buff redaction) and scale
  with Infractions. Skills are Edicts per the 3.1.3 entry.
- **Scholar:** the kit must contain the zone-clearing skill — the Scholar is one of
  only two zone-clearing paths in the game.
- **Chronophage:** both signature zones already exist; Flicker Zone currently sits
  unassigned in 3.2.4.3 and moves under the Chronophage heading. The remaining slots
  are Speed-scaling.
- **Tidal Corsair:** the three skills are already named in the passive (Boarding
  Strike, Saltwater Shot, Corsair's Reckoning) — the batch writes out their effects,
  it does not rename or replace them.
- **Architect:** import the kit sketch (basic, zone construction, tiered finisher)
  from `Plan_Architect_Calibration_Kit.md`; Expose Weakness and the Barrier buff
  (formerly the Sound Structure working name) are claimed by it.
- **Herald of the loom:** the thread stances live in the passive slot (decided in
  batch 3); the skills stand alone and stances modify them from the passive side.
- **Symbiote:** the monster-combine mechanic is undefined; its kit may hold one
  placeholder slot referencing that mechanic rather than forcing a design now.
  Symbiotic Overdrive already exists and stays.
- **Alchemist / Sorcerer:** the only kits allowed to reference reagents (see
  confirmed decisions). Their signature zones already exist.

## Claims ledger

One row per catalog effect; "Claimed by" grows as batches complete. Seeded with the
claims that already exist in the documents. Effects with no claim at the end of the
pass are reviewed in the final step (acceptable orphans vs. catalog cuts).

**Turn bar effects (3.2.3.1)**

| Effect | Claimed by |
|---|---|
| Anchor | — |
| Temporal Leak | — |
| Dead Weight | Bar Brawler (Headbutt) |
| Slipstream | — |
| Steadfast | — |
| Resonance | — |
| Battle Orders | Tactician (Battle Orders) |

**Debuffs (3.2.3.2)**

| Effect | Claimed by |
|---|---|
| Expose Weakness | Architect (finisher tier 2, per its plan); Break Guard (opponent skill) |
| Enfeeble | Lancer (Disarm) |
| Mana Burn | — |
| Burning | Jester (Burning Bolas) |
| Sequence Lock | — |
| Suppress | Herald of the loom (Thread Lash) |
| Slow | — |
| Blind | — |
| Unravel | Alchemist (Dissolving Agent) |
| Confound | Scholar (Expose Fallacy) |
| Exposed Facet | Appraiser (Flaw Analysis) |
| Bleed | Lancer (Rending Charge) |
| Plague | Plague Doctor (Miasma) |
| Blight | Plague Doctor (Quarantine Breach) |
| Severance | Cultist (Rite of Severance) |
| Hexed | Diviner (Ill Omen) |
| Stun | Weight of Law (generic zone, unassigned); Rush expiry (self-inflicted) |
| Fatigue | — |
| Refracted | — |
| Warped | Sorcerer (Unstable Rift) |

**Buffs (3.2.3.2)**

| Effect | Claimed by |
|---|---|
| Empower | — |
| Fortify | Warlord (Hold the Line) |
| Daunting Strength | Tactician (Fatal Flaw) |
| Frenzy | — |
| Rush | Warlord (Brace for Impact) |
| Exhert | Symbiote (Symbiotic Overdrive) |
| Luck | Jester (Center Stage) |
| Phalanx Guard | Lancer (passive, role-unique) |
| Attune | Herald of the loom (Woven Blessing) |
| Haste | — |
| True Aim | — |
| Clarity | — |
| Keen Edge | — |
| Insight | — |
| Regeneration | Symbiote (Grafted Flesh) |
| Barrier | Architect (Raise the Frame; replaced the Sound Structure working name) |
| Deathward | — |
| Aegis | Warlord (Brace for Impact) |
| Mirror Coat | — |
| Opportunist | Thief (Case the Target) |
| Catalyst | Alchemist (Catalyst Cloud) |
| Signed Writ | — |
| Wanderlust | — |
| Overflow | — |
| Vigor | Bar Brawler (Liquid Courage) |
| Lethal Precision | — |
| Spotlight | Jester (Center Stage) |
| Premonition | Diviner (Premonition) |
| Rehearsed | — |

**Existing generic skills (3.2.4.3)** — candidates for claiming during batches:
Weight of Law, Pagan Curse. Whatever remains unclaimed stays in 3.2.4.3.
Stab and Zap stay universal (fodder enemies fall back on them) while also serving
as the Thief's and Chronophage's basic skills. Flicker Zone moved under the
Chronophage in batch 2; Heap on moved under the Bar Brawler in batch 4 (not
dual-listed).

## Steps

1. **Batch 1 — Damage** (Thief, Lancer, Bloodmage, Tidal Corsair, Sorcerer): brainstorm,
   pick, write to 3.2.4.2, update ledger.
2. **Batch 2 — Debuffer / Control** (Emissary, Diviner, Plague Doctor, Cultist,
   Appraiser, Chronophage): same procedure.
3. **Batch 3 — Buffer / Support** (Tactician, Scholar, Alchemist, Herald of the loom,
   Architect): same procedure; Architect is an import, not a redesign.
4. **Batch 4 — Sustain / Tank** (Jester, Symbiote, Bar Brawler, Warlord): same
   procedure.
5. **Final pass:** run `/check-design` on the updated `Concept_Document.md`; audit the
   ledger for rule violations and orphaned effects; confirm 3.2.4.3 only holds
   genuinely unassigned skills; verify placeholder headings in 3.2.4.2 are all gone.

## Watch for

- Kits that read as the same character with a different coat of paint — the purpose
  tags overlap heavily (eight Roles are Debuffers, seven are Buffers); the
  differentiation must come from the delivery mechanic (Edicts, concoctions, stances,
  charges, stacks), not just from which effect is applied.
- Naming allowlist: skill and effect names spelled out in full, no new acronyms.

## Documentation

All output lands in `Concept_Document.md` (3.2.4.2 kits, 3.2.3 catalog additions,
3.2.4.3 removals). On completion, delete or archive this plan per `Plans/README.md`;
the claims ledger's final state may be worth preserving as a balancing reference —
decide at the end.
