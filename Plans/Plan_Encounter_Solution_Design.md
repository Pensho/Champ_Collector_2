# Plan: Encounter Solution Design

Design encounters whose mechanics are solved by the Role kits in
`Concept_Document.md` 3.2.4.2. Every encounter is built as a lock whose keys already
exist: catalog effects (3.2.3), zone rules (3.2.4.1), and reagents (3.3.3). This is a
**design-only pass** — all output lands in `Concept_Document.md`; no code is written.

This plan operationalizes the two combat types in Concept 3.2: routine fights are a
numeric check that the right kit can shortcut, and puzzle fights require one of two
or three specific skill configurations (or a significantly over-leveled roster).

## Status

Long-running — batches are appended as new scenarios and locations are developed.
Not yet started; first up is the Reanimating Statues retrofit (step 1), then the
first batch (step 2).

Depends on `Plan_Role_Skill_Kits.md`: an encounter's intended solutions may only
reference effects that at least one designed kit in 3.2.4.2 or a reagent in 3.3.3
actually carries. That plan's claims ledger is the lookup table for carriers.

## Encounter tiers (confirmed decisions)

Solution anchoring is tiered: fodder and mini-bosses name catalog *effects* as
answers (any champion carrying the effect qualifies); full bosses may additionally
lean on *role signatures* (signature zones, the Scholar's zone clear, reagents), so
specific roster picks matter most at the top tier.

- **Fodder (routine fights):** a stat check first. At most one visible mechanic with
  an effect-based shortcut (e.g. the statue's self-haste answered by Sequence Lock or
  Anchor). The mechanic is fully circumventable by raw level and gear — under-leveled
  or under-geared players use the right kit for a simple solution; strong players
  ignore it.
- **Mini-boss:** one core mechanic. Ignoring it makes the fight substantially slower
  or riskier but not impossible. Names 2–3 alternative effect-based answers, each
  carried by a different role family, so multiple rosters qualify.
- **Boss:** two or three layered mechanics. Beatable by one of two or three specific
  skill configurations, or by a significantly over-leveled roster (per Concept 3.2).
  Boss mechanics may demand role-signature answers — for example a zone only the
  Scholar's Refutation or Zone-Dissolving Salts can remove, or a window that only a
  specific reagent opens.

## Encounter entry template

Every designed encounter records:

- **Name** and **tier** (Fodder / Mini-boss / Boss).
- **Location and lore family:** a section 4.3 location and, where zones are involved,
  the god zone family (order / unstable / momentum, 3.2.4.1).
- **Enemy composition:** the enemy variants fielded.
- **Mechanics:** expressed as opponent skills, passives, or zones. Each new opponent
  skill is added to 3.2.4.4 in the same edit; each new status effect to 3.2.3.
- **Intended solutions:** effect names plus example carrier roles; for bosses, the
  2–3 valid configurations spelled out.
- **Unsolved texture:** what the fight looks like when the player ignores the
  mechanic (slower, riskier, or a hard wall — hard walls are boss-only).
- **Reward hook:** the gear / experience / currency framing per Concept 5.2.

## Rules

- **Catalog-first:** mechanics are built from existing status effects (3.2.3), zone
  rules (3.2.4.1), and opponent skills (3.2.4.4). A new effect or opponent skill is
  invented only when the encounter's theme demands it, and is added to the catalog in
  the same edit.
- **Solutions must exist:** an encounter must never require an answer that no
  designed kit or reagent carries, and no encounter's only answer may be a universal
  skill (none exist by design).
- **Answer diversity:** every mechanic names at least two distinct answers; every
  boss names 2–3 distinct valid configurations.
- **Enemies never use reagents** (3.3.3).
- **Numbers are welcome:** brainstormed encounters may carry concrete numbers; they
  are balancing starting points, not commitments.
- **Durations are explicit:** any buff or debuff an encounter's mechanics apply
  states its duration, even when it matches the 2-turn default in 3.2.3.

## Coverage ledger

The mirror image of the claims ledger in `Plan_Role_Skill_Kits.md`: one row per Role,
tracking which encounters its kit is an intended answer for. Rows per catalog effect
can be added later if role rows prove too coarse.

Review rules, checked after every batch:

- Over time, every implemented Role should be the best tool for at least one
  encounter.
- An effect answering more than 3 encounters triggers a review, so no single kit
  becomes the answer to everything.

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
3. Write the picked encounters into `Concept_Document.md` section 5; add new opponent
   skills to 3.2.4.4 and new status effects to 3.2.3 in the same edit.
4. Update the coverage ledger and check the review rules before the next batch.

## Steps

1. **Retrofit:** re-express Reanimating Statues 1, 2, and 3 (Concept 5.2.2) in the
   entry template; seed the coverage ledger from them (rows above are the starting
   guess). Sharpen the 5.2.2 wording only if the retrofit exposes gaps — note that
   Sequence Lock and Anchor currently have no kit carrier in the claims ledger, so
   Reanimating Statues 1 is the first "solutions must exist" test case.
2. **First batch:** 2–3 fodder mechanics, one mini-boss, one full boss, via the
   per-batch procedure. Purpose: prove the templates and the ledger work end to end.
3. **Ongoing batches:** append as new scenarios, locations, or game modes are
   developed.

## Watch for

- Encounters that are the same lock with a different coat of paint — differentiation
  must come from the mechanic's delivery (zones, turn bar pressure, buff economies,
  targeting behavior), not just from which debuff answers it.
- Boss configurations that all funnel through the same one or two roles — the point
  of 2–3 configurations is that different rosters qualify.
- Naming allowlist: encounter, skill, and effect names spelled out in full, no new
  acronyms.

## Documentation

All output lands in `Concept_Document.md`: tier definitions in section 5, encounter
entries under 5.2.x (or the section matching the encounter's game mode), opponent
skills in 3.2.4.4, status effects in 3.2.3. This plan stays alive as the coverage
ledger's home; if it is ever archived, the ledger moves into the Concept Document
first.
