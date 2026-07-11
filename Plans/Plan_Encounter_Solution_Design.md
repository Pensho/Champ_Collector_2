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

Long-running. Not yet started; first up is the Reanimating Statues retrofit
(step 1), then the proving batch (step 2), then volume batches.

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
  shortcut (e.g. the statue's self-haste answered by Sequence Lock or Anchor). The
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
  not enemy skills. Mechanics must therefore be readable from who is fielded plus
  prior experience — which favors re-using enemy variants across encounters so
  knowledge transfers.
- **Difficulty options add mechanics:** higher difficulty versions of an encounter
  will very likely add mechanics on top of scaling numbers, not numbers alone.
- **Roster-slot budget:** battles field up to 3 champions (Concept 3.2). An
  encounter's intended answer may demand at most 2 dedicated roster slots at Boss
  tier, at most 1 at Mini-boss tier, and at most 1 optional slot at Fodder tier —
  the player always keeps at least one free pick.
- **Enemies are champions, data-wise:** enemy variants use the same
  `CharacterPreset` resource and skill data as playable champions. No enemy-only
  stat systems.

## Theme palette (optional flavor, applied late)

Themes exist to invite theme-related skills, not to structure production. An
encounter may carry a theme tag, and the tag may be applied or swapped later — an
entry must stay mechanically valid if its theme changes. The palette, drawn from
the Concept 4.3 locations and the god zone families (order / unstable / momentum):

- **Reclaimed City** — spore beasts, Fae geometry, scavenger crews.
- **Clockwork Spire** — constructs and Logic-Chain guardians; order zones,
  high-Defense and speed-ramp patterns (natural home for the Statues).
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
- **Enemy composition:** the enemy variants fielded (this is what the player sees
  pre-battle).
- **Mechanics:** expressed as opponent skills, passives, or zones. Each new opponent
  skill is added to the opponent skill catalog in `Encounter_Design_Document.md` in
  the same edit; each new status effect to Concept 3.2.3.
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

| Role | Intended answer for |
|---|---|
| Emissary | — |
| Thief | — |
| Lancer | Reanimating Statues 2 (Disarm → Enfeeble) |
| Alchemist | — |
| Sorcerer | — |
| Scholar | — |
| Diviner | — |
| Appraiser | — |
| Tactician | — |
| Symbiote | — |
| Jester | Reanimating Statues 3 (Burning Bolas → Burning) |
| Cultist | — |
| Bar Brawler | — |
| Bloodmage | — |
| Herald of the loom | — |
| Chronophage | Reanimating Statues 1 (speed control; Sequence Lock / Anchor carrier pending — see step 1) |
| Architect | Reanimating Statues 3 (Final Calculation tier 2 → Expose Weakness) |
| Tidal Corsair | — |
| Plague Doctor | — |
| Warlord | Reanimating Statues 2 (Sustain-side answer) |

Existing opponent-skill precedent: Break Guard (3.2.4.4).

## Per-batch procedure

1. Run `/brainstorm` for the batch, prompting with: the tier template, the current
   coverage ledger, the rules above, and the 3.2.4.2 kit excerpts for the roles the
   batch intends to cover.
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
2. **Proving batch:** 2–3 fodder mechanics, one mini-boss, one full boss, via the
   per-batch procedure. Purpose: prove the templates and the ledger work end to end.
3. **Volume batches:** repeat the per-batch procedure toward the volume floors.
   A batch mixes tiers (roughly 3–5 fodder, 1–2 mini-bosses, 1 boss) and stays
   placement-agnostic; themes are optional tags.
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
