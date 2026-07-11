# Plan: Encounter Solution Design

The long-run plan for battle encounter content. Design encounters whose mechanics
are solved by the Role kits in `Concept_Document.md` 3.2.4.2: every encounter is
built as a lock whose keys already exist — catalog effects (3.2.3), zone rules
(3.2.4.1), and reagents (3.3.3). This is a **design-only pass** — all output lands
in the design documents (see Documentation); no code is written.

This plan operationalizes the two combat types in Concept 3.2: routine fights are a
numeric check that the right kit can shortcut, and puzzle fights require one of two
or three specific skill configurations (or a significantly over-leveled roster).

Encounters are designed **progression- and content-agnostic**: no encounter is bound
to a game mode, location, or point in the campaign at design time. Game progression
is still unsettled, so the plan produces a wide pool of encounters first and fits
them to modes, places, and progression later (see the placement pass in Steps).

## Status

Long-running. Step 1 (Reanimating Statues retrofit) is done: the three statue
encounters and Break Guard live in `Encounter_Design_Document.md`, the Concept
Document holds pointers, and the coverage ledger below is seeded. The
"solutions must exist" gap in Reanimating Statues 1 was resolved by expressing
the ramp as repeated self-applied Haste, answered by carried effects
(Severance, Signed Writ's duration strip, Dead Weight, Temporal Sinkhole);
Sequence Lock remains an intended future answer with no carrier, and Anchor was
dropped as an answer (it blocks turn-bar pushes, which never counters a speed
ramp). Next up: the proving batch (step 2), then volume batches.

Follow-up decisions (confirmed): the three Reanimating Statues are retiered
from fodder to mini-boss — all three mechanics only bite when the fight has
runway, which is the mini-boss texture — and fight length is now a tier
parameter with round budgets and a mechanic-onset rule (see Encounter tiers;
owned by Concept 5.3). Their coverage-ledger answers now count toward the
3-encounter review threshold; each answering effect currently sits at 1.
The Statues carry no theme tag by design — a theme for them is deliberately
unallocated for now.

Way-of-working revision (confirmed): batches are single-tier from now on, and
mini-boss and boss batches hold exactly one encounter worked in depth — the first
proving batch surfaced that mixing tiers produced interesting but shallow
mini-boss and boss sketches. Compositions are 1–3 enemies and supporting enemies
must earn their slot (see Production decisions). The fodder proving batch is
done: seven encounters (Sporeback Pack, Wake Skimmers, Ledger Clerks, Plains
Outriders, Ridge Marksmen, Flank Cutter, Line Breaker) live in
`Encounter_Design_Document.md` 2.1 with six new opponent skills. The positional
pair introduced party order and the Left-most / Right-most Enemy targeting
types into Concept 3.2 and 3.2.4 (positional targeting is absolute — Spotlight
does not redirect it). The mini-boss proving batch is done: The Ashen Oracle
(escalating Cinder Sermon; Cinder Husks as Ash Offering fuel, punishing
careless AoE) — it also settled that enemy passives are not inspectable in
battle (Concept 3.2; a reveal-on-trigger bestiary is parked in
`FeatureIdeas.md`). The boss proving batch is done: three candidates were
iterated in depth and the user kept all three — The Glyphbound Archivist,
The Collector of Debts, and The Warden of the Reliquary now live in
`Encounter_Design_Document.md` 2.3 with eight new opponent skills and no new
status effects. Keeping three was a one-off user redirect; volume batches
return to exactly one boss per batch. A fourth candidate (a turn-bar tyrant
answered by Steadfast/Anchor) was set aside because those effects have no kit
carrier yet — same situation as Sequence Lock. The existing Obsidian Stallion
enemy (Lava Zone placer) stays a mini-boss covering the simple zone-hazard
space below the Archivist; it still needs thematic flavor. With this, all
three proving batches are complete. Next up: volume batches.

Depends on `Plan_Role_Skill_Kits.md`: an encounter's intended solutions may only
reference effects that at least one designed kit in 3.2.4.2 or a reagent in 3.3.3
actually carries. That plan's claims ledger is the lookup table for carriers.

## Encounter tiers (confirmed decisions)

Solution anchoring is tiered: fodder and mini-bosses name catalog *effects* as
answers (any champion carrying the effect qualifies); full bosses may additionally
lean on *role signatures* (signature zones, the Scholar's zone clear, reagents), so
specific roster picks matter most at the top tier.

- **Fodder (routine fights):** the power-fantasy tier — tuned below the expected
  player power so the player most often crushes it and feels how far they have
  come. A stat check first: at most one visible mechanic with an effect-based
  shortcut (e.g. an enemy that spams self-healing, answered by Blight). The
  mechanic is fully circumventable by raw level and gear — under-leveled or
  under-geared players use the right kit for a simple solution; strong players
  ignore it.
- **Mini-boss:** the optional-puzzle tier. One core mechanic; a player who reads it
  and brings an answer wins comfortably, while ignoring it makes the fight
  substantially slower or riskier but not impossible. Names 2–3 alternative
  effect-based answers, each carried by a different role family, so multiple
  rosters qualify.
- **Boss:** the mandatory-puzzle tier. Two or three layered mechanics; beatable by
  one of two or three specific skill configurations, or by a significantly
  over-leveled roster (per Concept 3.2). Boss mechanics may demand role-signature
  answers — for example a zone only the Scholar's Refutation or Zone-Dissolving
  Salts can remove, or a window that only a specific reagent opens.

Fight length is a tier parameter, measured in rounds (each fielded champion
acting once). Targets — starting points, to be tuned: fodder is decided in 3–4
rounds; a mini-boss runs 6–10 rounds solved and roughly double that unsolved; a
boss runs 10–12 rounds solved, and unsolved is a wall rather than merely slow.
Every mechanic states its onset — by which enemy turn it becomes relevant — and
that onset must fall inside its tier's expected kill window: a mechanic that
comes online after the fight is normally decided is dead content. These tier
definitions are owned by `Concept_Document.md` section 5.3.

Mechanical load scales with progression: an early-game boss carries little for the
player to learn or adapt to, and the two-or-three-layer target above describes mid-
and late-game bosses. Since encounters are designed placement-agnostic, each boss
entry states its mechanical weight (light / full) so the placement pass can slot it.

## Production decisions (confirmed)

- **Volume floors, not ceilings:** at least 20 fodder encounters, at least 10
  mini-bosses, and at least 10 bosses. Coverage of the effect and answer space
  comes from this volume, never from cramming: each encounter keeps its narrow
  mechanic footprint per tier, and no encounter is widened just to cover unclaimed
  ground.
- **Overlap tolerance is tiered:** fodder overlap is nearly negligible — many
  fodder encounters may invite the same answers. Mini-bosses tolerate some overlap
  but no two may pose an identical ask (same core mechanic answered by the same
  effects). Bosses minimize overlap: no two bosses share their full set of valid
  configurations, and each boss keeps at least one configuration no other boss
  uses.
- **New opponent skills are the norm:** enemies get their own newly authored
  skills; design is not limited to re-using champion skills. What stays anchored is
  the answer side (see Rules).
- **Telegraph:** before committing a team the player sees the enemy composition,
  not enemy skills. In battle, enemy passives are not inspectable — the player
  learns mechanics by observing them (rule owned by Concept 3.2; a
  reveal-on-trigger bestiary upgrade is parked in `FeatureIdeas.md`). Mechanics
  must therefore be readable from who is fielded plus prior experience — which
  favors re-using enemy variants across encounters so knowledge transfers.
- **Difficulty options add mechanics:** higher difficulty versions of an encounter
  will very likely add mechanics on top of scaling numbers, not numbers alone.
- **Roster-slot budget:** battles field up to 3 champions (Concept 3.2). An
  encounter's intended answer may demand at most 2 dedicated roster slots at Boss
  tier, at most 1 at Mini-boss tier, and at most 1 optional slot at Fodder tier —
  the player always keeps at least one free pick.
- **Enemies are champions, data-wise:** enemy variants use the same
  `CharacterPreset` resource and skill data as playable champions. No enemy-only
  stat systems.
- **Single-tier batches, depth-first:** a batch is either 3–5 fodder encounters,
  or exactly one mini-boss, or exactly one boss. Mini-boss and boss batches
  iterate their one encounter in depth with the user before anything is written
  into the documents.
- **Compositions are 1–3 enemies:** an encounter fields 1, 2, or 3 enemies —
  never 3 by default. Any enemy fielded beside a mini-boss or boss must have a
  stated mechanical reason to be there (it carries, enables, or feeds the
  mechanic); no filler bodies.

## Theme palette (optional flavor, applied late)

Themes exist to invite theme-related skills, not to structure production. An
encounter may carry a theme tag, and the tag may be applied or swapped later — an
entry must stay mechanically valid if its theme changes. The palette, drawn from
the Concept 4.3 locations and the god zone families (order / unstable / momentum):

- **Reclaimed City** — spore beasts, Fae geometry, scavenger crews.
- **Clockwork Spire** — constructs and Logic-Chain guardians; order zones,
  high-Defense and speed-ramp patterns.
- **Pirate Coves** — Gilded Wake crews; buff economies and momentum zones.
- **Iron Ledger** — enforcers and adjudicators; debuff pressure and order zones.
- **Caravan plains** — Centaur regimes and plains beasts; momentum and speed
  pressure.
- **Ruins of the God of Magic** — corrupted mages and aberrations; unstable zones,
  AoE magical pressure.

No theme ledger is kept at this stage; one can be added once themes and progression
are locked, if overlap between themes needs tracking.

## Encounter entry template

Mini-boss and boss encounters record the full template. Fodder uses a compact
variant — one line each for composition, the single mechanic, and its answers — so
that tier can be produced in bulk without padding.

- **Name** and **tier** (Fodder / Mini-boss / Boss); bosses also state mechanical
  weight (light / full).
- **Theme (optional):** a tag from the theme palette; where zones are involved, the
  god zone family (order / unstable / momentum, 3.2.4.1).
- **Enemy composition:** the enemy variants fielded, 1–3 of them (this is what
  the player sees pre-battle). Each enemy fielded beside a mini-boss or boss
  states its mechanical reason.
- **Mechanics:** expressed as opponent skills, passives, or zones. Each mechanic
  states its onset (by which enemy turn it becomes relevant), which must fall
  inside the tier's expected kill window. Each new opponent skill is added to the
  opponent skill catalog in `Encounter_Design_Document.md` in the same edit; each
  new status effect to Concept 3.2.3.
- **Intended solutions:** effect names plus example carrier roles; for bosses, the
  2–3 valid configurations spelled out.
- **Unsolved texture:** what the fight looks like when the player ignores the
  mechanic (slower, riskier, or a hard wall — hard walls are boss-only).
- **Reward hook (deferred):** assigned during the placement pass, per Concept 5.2.

## Rules

- **Catalog-anchored answers, freely authored opponent skills:** the answer side of
  every mechanic draws from existing status effects (3.2.3) and zone rules (3.2.4.1)
  so player counterplay always exists. New opponent skills are the norm — they are
  authored per encounter and added to the opponent skill catalog in the same edit. A
  new status effect is invented only when the encounter's theme demands it, and is
  added to 3.2.3 in the same edit.
- **Solutions must exist:** an encounter must never require an answer that no
  designed kit or reagent carries, and no encounter's only answer may be a universal
  skill (none exist by design).
- **Answer diversity:** every mechanic names at least two distinct answers; every
  boss names 2–3 distinct valid configurations.
- **Enemies never use reagents** (3.3.3).
- **Numbers are welcome:** brainstormed encounters may carry concrete numbers; they
  are balancing starting points, not commitments. Stats are relative to an
  expected-power baseline, tuned when the encounter is placed.
- **Durations are explicit:** any buff or debuff an encounter's mechanics apply
  states its duration, even when it matches the 2-turn default in 3.2.3.

## Coverage ledger

The mirror image of the claims ledger in `Plan_Role_Skill_Kits.md`: one row per Role,
tracking which encounters its kit is an intended answer for. Rows per catalog effect
can be added later if role rows prove too coarse.

Review rules, checked after every batch:

- Over time, every implemented Role should be the best tool for at least one
  encounter.
- An effect answering more than 3 mini-boss or boss encounters triggers a review, so
  no single kit becomes the answer to everything. Fodder answers are not counted —
  overlap there is nearly negligible per the tiered overlap tolerance above.
- Boss configuration sets are compared game-wide per the overlap tolerance: each
  boss keeps at least one configuration unique to it.

One column per tier, so a Role's distribution across tiers is readable at a
glance (e.g. a Role that only ever answers fodder stands out). The Boss
column lists configuration membership only; incidental mitigations named in
an entry (e.g. Vault Slam's Enfeeble/Barrier softeners) are not tracked.

| Role | Fodder | Mini-boss | Boss |
|---|---|---|---|
| Emissary | Wake Skimmers (buff-duration strip); Ledger Clerks (Signed Writ) | Reanimating Statues 1 (Signed Writ → buff-duration strip) | The Collector of Debts (Signed Writ → strips seized buffs); The Warden of the Reliquary (Signed Writ → shears protection durations) |
| Thief | Wake Skimmers (Pilfer buff theft) | — | The Collector of Debts (Pilfer → steals seized buffs back) |
| Lancer | Line Breaker (Disarm → Enfeeble) | Reanimating Statues 2 (Disarm → Enfeeble) | — |
| Alchemist | Ledger Clerks (Dissolving Agent → Unravel) | — | — |
| Sorcerer | — | — | The Collector of Debts (Arcane Instability → amplified tincture/Fractured Idol configuration) |
| Scholar | — | — | The Glyphbound Archivist (Refutation → zone clear, role signature) |
| Diviner | Ridge Marksmen (Premonition) | The Ashen Oracle (Ill Omen → Hexed) | — |
| Appraiser | — | — | The Warden of the Reliquary (Full Appraisal → burst-window configuration) |
| Tactician | — | — | The Warden of the Reliquary (Daunting Strength → burst-window configuration) |
| Symbiote | — | — | — |
| Jester | — | Reanimating Statues 3 (Burning Bolas → Burning) | — |
| Cultist | — | Reanimating Statues 1 (Rite of Severance → Severance halts the Haste ramp) | The Collector of Debts (Devour Blessing → buff economy); The Warden of the Reliquary (Rite of Severance → blocks the protection grants) |
| Bar Brawler | — | Reanimating Statues 1 (Headbutt → Dead Weight) | The Glyphbound Archivist (charge-burn sustain) |
| Bloodmage | Ridge Marksmen, Line Breaker (Barrier) | Reanimating Statues 2 (Transfusion → Barrier); The Ashen Oracle (Tithe of Vitality → Mana Burn) | — |
| Herald of the loom | Sporeback Pack (Thread Lash → Suppress) | The Ashen Oracle (Thread Lash → Suppress) | — |
| Chronophage | Plains Outriders (Temporal Sinkhole) | Reanimating Statues 1 (Temporal Sinkhole → turn-bar pressure) | — |
| Architect | Ridge Marksmen, Flank Cutter (Barrier) | Reanimating Statues 3 (Final Calculation tier 2 → Expose Weakness); Reanimating Statues 2 (Raise the Frame → Barrier) | — |
| Tidal Corsair | Plains Outriders (Corsair's Reckoning → turn-bar strip) | — | — |
| Plague Doctor | Sporeback Pack (Quarantine Breach → Blight) | — | — |
| Warlord | Flank Cutter (Fortify) | Reanimating Statues 2 (Hold the Line → Fortify) | The Glyphbound Archivist (charge-burn sustain) |

Sequence Lock has no carrier in the claims ledger; it is noted in the
Reanimating Statues 1 entry as a future answer and becomes valid once a kit or
reagent carries it. Steadfast and Anchor are in the same situation — a
turn-bar-tyrant boss concept waits on one of them gaining a carrier. Fodder
answers are not counted against the 3-encounter review threshold.

Post-batch review check (boss proving batch): the Emissary's Signed Writ now
answers 3 mini-boss/boss encounters — exactly at the review threshold; the
next encounter leaning on it triggers the review. Severance sits at 2. Each
boss keeps at least one configuration no other boss uses (Archivist: all
three; Collector: the Cultist buff economy and the tincture reagent
configuration; Warden: the Tactician + Appraiser burst window).

Opponent skills authored so far (`Encounter_Design_Document.md` section 1):
Break Guard, Wind the Mainspring, Overwhelming Blow, Sporeburst Mend, Rally the
Crew, March Cadence, Aimed Shot, Flank Cut, Breaching Charge, Cinder Spit,
Cinder Sermon, Ash Offering (passive), Inscribe, Inscription Surge,
Foreclosure, Lien (passive), Writ of Seizure, Reliquary Ward, Vault Slam,
Warden's Failsafe (passive).

## Per-batch procedure

1. Run `/brainstorm` for the batch (single-tier: 3–5 fodder candidates, or one
   mini-boss, or one boss), prompting with: the tier template, the current
   coverage ledger, the rules above, and the 3.2.4.2 kit excerpts for the roles the
   batch intends to cover. Mini-boss and boss batches iterate the single
   encounter in depth before step 3.
2. The user picks from the candidates (or redirects).
3. Write the picked encounters into `Encounter_Design_Document.md`; add new opponent
   skills to its opponent skill catalog and new status effects to Concept 3.2.3 in
   the same edit.
4. Update the coverage ledger and check the review rules before the next batch.

## Steps

1. **Retrofit:** re-express Reanimating Statues 1, 2, and 3 (Concept 5.2.2) in the
   entry template and move them, together with Break Guard, into
   `Encounter_Design_Document.md` (leaving pointers in the Concept Document); seed
   the coverage ledger from them (rows above are the starting guess). Sharpen the
   5.2.2 wording only if the retrofit exposes gaps — note that Sequence Lock and
   Anchor currently have no kit carrier in the claims ledger, so Reanimating
   Statues 1 is the first "solutions must exist" test case.
2. **Proving batches:** one single-tier batch per tier — the fodder batch (done:
   five encounters), then one mini-boss, then one boss — via the per-batch
   procedure. Purpose: prove the templates and the ledger work end to end.
3. **Volume batches:** repeat the per-batch procedure toward the volume floors.
   Every batch is single-tier (3–5 fodder, or one mini-boss, or one boss) and
   stays placement-agnostic; themes are optional tags.
4. **Placement pass (later, once progression settles):** fit designed encounters to
   game modes, locations, and progression; assign reward hooks; tune stats to the
   placement's expected power. Placement rule: fodder sharing a boss's mechanic
   vocabulary is placed ahead of that boss, so fodder teaches what the boss demands.

## Watch for

- Encounters that are the same lock with a different coat of paint — differentiation
  must come from the mechanic's delivery (zones, turn bar pressure, buff economies,
  targeting behavior), not just from which debuff answers it.
- Boss configurations that all funnel through the same one or two roles — the point
  of 2–3 configurations is that different rosters qualify.
- Naming allowlist: encounter, skill, and effect names spelled out in full, no new
  acronyms.

## Documentation

Tier definitions stay in `Concept_Document.md` section 5 and new status effects in
3.2.3; encounter entries and opponent skills land in `Encounter_Design_Document.md`,
with Concept section 5 and 3.2.4.4 holding pointers. This plan stays alive as the
coverage ledger's home; if it is ever archived, the ledger moves into
`Encounter_Design_Document.md` first.
