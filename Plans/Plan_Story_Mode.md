# Plan: Story Mode

The design plan for the narrative campaign (`Concept_Document.md` 3.4.1, currently
TODO): a story mode built on the `World_Building.md` lore, played through the hub
areas and battle encounters. This is a **design-only plan** — all output lands in
the design documents (see Documentation); presentation and implementation get their
own plan once the design settles.

## Status

Not started as a document pass. The material below was brainstormed 2026-07-05 and
has had no written home until this plan. The four-act skeleton is a working
decision pending a drama-curve pass (step 2); the slum-arc beats are chosen.

## Captured material (brainstormed 2026-07-05)

### Four-act hub order (working decision, pending drama-curve rework)

1. **Reclaimed City** — the call to action.
2. **Clockwork Spire** — the trail points to the Iron Ledger; the player cannot
   get in.
3. **Pirate Coves** — forged entry papers, obtained via the Ink-Stained Reef
   (`World_Building.md` 4.2.2).
4. **The Iron Ledger** — resolution.

Through-line candidate: a Chant found in the Ossuary of Stolen Hues
(`World_Building.md` 5.4.1) that only the Ghost Scholar in the Aethelgard basement
(`World_Building.md` 6.1.3) can read.

### The slum arc (chosen beats)

Set in the Margins, where the Iron Ledger hub stands (`Concept_Document.md` 4.3.4;
`World_Building.md` 5.5, 6.3). In order:

1. The Arrears take the player in on credit; every favor goes into the Grey Ledger.
2. The Arrears settle the player to the Ledger — the double-cross, executed per the
   Settlement of Accounts (`World_Building.md` 6.3.4).
3. Marn warns the player before the settlement is executed.
4. Escape sequence through the Queue (`World_Building.md` 5.5.4).
5. The Consolidation follows: the Ledger seizes the Grey Ledger; the Debt-Mother
   survives, bookless.
6. Vessa "the Collector" returns as a mini-boss — as a story event or a guest
   Adventure boss (open which; see Open questions).

### Lore gaps to fill (agreed, in priority order)

1. The debt-forgiveness sect in the Voided Blocks — referenced in
   `World_Building.md` 5.5.2 and 6.3.4 ("the Struck Lines"), not yet designed.
2. The Grease-Pits strata (`World_Building.md` 5.1).
3. The Cove Pirate Lords — the Council of Coves as individuals
   (`World_Building.md` 4.2).
4. The Symbiote Slums community (`World_Building.md` 1.2.1).

## Confirmed decisions (2026-07-12)

- **Story mode is its own feature:** the Adventure feature carries no required
  story elements.
- **Presentation format:** a dialogue overlay (speaker portrait, name, text,
  choices), usable from any scene — not only hubs.
- **Act gating:** completing an act's closing beat unlocks the next hub/area
  directly; no currency is involved. Flagged conflict: the role of the Area
  unlock currency (`Concept_Document.md` 3.3.2) is now undecided.
- **Delivery systems:** captured in `Plan_Story_Mode_Systems.md` (story state
  handler, dialogue overlay, flag-driven hub variants, act gating, scripted
  battle openings, guest champions). Alternative battle objectives are backlog
  (`FeatureIdeas.md`), not planned.

## Open questions (settled before or during the act passes)

- **Player identity:** who the player is in the story and what pulls them into the
  act 1 call to action; how champion collecting reads in the fiction (the
  Adventurer's Guild is the natural frame — every hub has one, and the Holy City
  guildhall is established neutral ground).
- **Drama curve:** where the low point sits (candidate: the settlement
  double-cross), and what stakes acts 2 and 3 carry so the middle does not sag —
  this is the rework the four-act skeleton is waiting on.
- **Game structure:** whether story mode is the Longform content of
  `Concept_Document.md` 5.1 or a separate mode beside it (it is not a layer over
  Adventure mode — see Confirmed decisions).
- **Encounter sourcing:** which story battles draw from the placement-agnostic
  encounter pool (the placement pass in `Plan_Encounter_Solution_Design.md`) and
  which are story-exclusive (e.g. the Vessa mini-boss).
- **Biome implications:** each act's hub implies a biome for its adventures
  (Remaining_Scope_Checklist "Additional biomes"); the act order is the natural
  biome production order.

## Rules

- **Story beats are not world facts:** campaign material lands in the story
  document, never in `World_Building.md`. `World_Building.md` gains only facts
  that hold independent of the campaign (factions, locations, doctrines) — the
  split already made for the slum arc.
- **Decisions only:** record what is decided and its parameters; no rationale for
  rejected alternatives.
- **Story battles are encounters:** any named story battle is designed under the
  template and rules of `Plan_Encounter_Solution_Design.md` and lands in
  `Encounter_Design_Document.md`; the story document references it by name.
- **Concept wins:** `Concept_Document.md` is authoritative; conflicts are flagged,
  not silently reconciled.
- **Naming allowlist:** names spelled out in full, no new acronyms — the story
  document included.

## Steps

1. **Create `Story_Design_Document.md`:** move the captured material above into it
   as the skeleton (act list, through-line candidate, slum arc, lore-gap list),
   subordinate to `Concept_Document.md` in the same way as
   `Encounter_Design_Document.md`. `Concept_Document.md` 3.4.1 gets a short
   summary and a pointer.
2. **Drama-curve pass:** iterate the four-act skeleton with the user — confirm or
   rework the act order, fix the low point, give acts 2 and 3 their stakes, and
   confirm the through-line. Output: a confirmed act skeleton in the story
   document.
3. **Act beat sheets, one act per batch:** depth-first like the encounter batches —
   each batch drafts one act's beats (locations, characters, player goal, battles
   by name or ask) and iterates with the user before it is written in. Act 4
   imports the slum arc.
4. **Lore-gap fill:** design the four gaps in priority order; each lands in
   `World_Building.md` as world facts, with any campaign-specific use staying in
   the story document.
5. **Integration pass:** map the confirmed beats to game structure — hub unlock
   order, adventures per act, encounter placement (handshake with the placement
   pass in `Plan_Encounter_Solution_Design.md`), and the biome list. Output lands
   in `Concept_Document.md` 3.4.1 and 5.1.
6. **Systems handshake:** keep `Plan_Story_Mode_Systems.md` aligned as the beat
   sheets land — any new system a beat demands is surfaced there, not invented
   mid-beat-sheet.

## Watch for

- Story-mode material leaking into `World_Building.md` as world fact.
- Acts that read as lore tours — each act needs a player want and an obstacle, not
  just a new location.
- The through-line depending on characters the player never meets in play.
- New-system appetite: story mode should consume existing content types
  (encounters, hubs) and demand new systems sparingly; anything new it demands is
  surfaced through step 6, not invented mid-beat-sheet.

## Documentation

Output homes: `Story_Design_Document.md` (new — campaign structure, act beat
sheets, story-only material), `Concept_Document.md` 3.4.1 and 5.1 (mode structure,
summary, pointer), `World_Building.md` (lore-gap fills), and
`Encounter_Design_Document.md` (story battles). When the story document is
created, add it to the document-roles list in the project `CLAUDE.md`.
