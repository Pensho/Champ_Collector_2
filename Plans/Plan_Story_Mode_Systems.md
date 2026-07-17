# Plan: Story Mode Systems

The implementation plan for the systems that deliver story mode. The campaign
design itself lives in `Plan_Story_Mode.md` (and, once created,
`Story_Design_Document.md`); this plan owns the code side: story state,
presentation, hub reactivity, act gating, and story-flavored battle setup.

## Status

Created 2026-07-12 from the story-mode systems brainstorm; nothing implemented.
The story state handler and the dialogue overlay are design-independent and can
start before the act beat sheets exist; the remaining systems sequence per the
dependencies noted in each section.

## Boundary (confirmed)

Story mode is its own feature. The Adventure feature carries no required story
elements — no story node type, no story gating inside adventure graphs.

## Systems

### 1. Story state handler

- `StoryProgressHandler`, a node in `Scripts/Worldview/` joining
  `SaveManager.GROUP_SAVEABLE` and following the `ProgressHandler` pattern
  (`Serialize`/`Deserialize`).
- Holds: the current act, completed beat IDs (strings namespaced by act, e.g.
  `act1_ossuary_chant_found`), and a flag dictionary for choices and world-state
  toggles.
- Emits signals on beat completion and flag changes so hubs and UI react without
  direct calls.
- Tests: serialize/deserialize round-trip, beat-completion idempotence, signal
  emission.

### 2. Dialogue overlay

- A reusable UI layer (scene under `Scenes/ui`, script under `Scripts/UI/`):
  speaker portrait, speaker name, line text, advance input, and optional choice
  buttons.
- Playable from any scene — hubs, menus, world atlas, pre/post battle — not only
  hubs.
- Data-driven: a dialogue is a resource holding an ordered list of entries
  (speaker, portrait, line, optional choices; a choice names the flags it sets).
  Dialogue resources live in a new `Data/` domain subfolder (e.g. `Data/Story/`
  — confirm the name when the first resource lands).
- Completing a dialogue or picking a choice writes to the story state handler;
  the overlay never mutates other systems directly.
- Tests: dialogue traversal (linear and choice branch) and the resulting flag
  writes, as pure logic.

### 3. Flag-driven hub variants

- Hub scenes react to the story state handler: NPCs, props, and building
  availability toggle on flags or act.
- Implementation: a small reusable gate script (e.g. `StoryVisibilityGate`) that
  shows/hides or enables/disables its parent node from a named flag, so hub
  scenes are wired in the editor rather than in per-hub code.
- Depends on hubs beyond Reclaimed City existing; wiring lands per hub as hubs
  are built.

### 4. Act gating

- Completing an act's closing beat unlocks the next hub/area directly; no
  currency is involved.
- Unlock state is read from the story state handler; the world atlas and hub
  travel UI consult it.
- Flagged conflict, resolve before implementing: `Concept_Document.md` 3.3.2
  lists an "Area unlock currency" — its role once story completion unlocks areas
  directly is undecided.

### 5. Scripted battle openings

- A story encounter may declare a pre-battle state, applied by a setup hook
  before the first turn:
  - pre-placed zones (section index, zone type, charges, owning side),
  - starting turn-bar offsets per side or per character (e.g. party starts at
    +40%),
  - pre-applied buffs/debuffs with explicit durations.
- Pure data on the encounter definition; reuses the existing zone, status, and
  turn-bar systems — no new combat rules.
- The headless combat core has landed: scripted battle openings apply their
  effects through `BattleResolver` (`ApplyBuff`/`ApplyDebuff`/`PlaceZone`), not
  `battle.gd`/`Skills.gd` directly.
- Tests: setup application as pure logic — zones placed, offsets applied,
  effects present with correct durations at battle start.

### 6. Guest champions (good-to-have, not necessary)

- A story beat can add a temporary roster entry flagged as story-loaned: fielded
  like a normal champion, excluded from permanent roster operations, removed at
  its act boundary.
- Rides on the completed team and roster abstraction (`CombatTeam`/`CombatSides`);
  deferred until an act beat sheet actually fields a guest.

## Suggested order

1. Story state handler — independent; everything else reads it.
2. Dialogue overlay and the dialogue resource format.
3. Scripted battle openings — coordinate ordering with the headless combat core.
4. Flag-driven hub variants — as hubs land.
5. Act gating — after the Area-unlock-currency question is resolved.
6. Guest champions — after the team/roster abstraction, on demand from beat
   sheets.

## Watch for

- Project conventions: signals over direct calls, full type hints, naming
  allowlist (no new acronyms).
- The dialogue overlay staying presentation-only — story logic lives in the
  dialogue data and the state handler.
- Scripted openings interact with the tier round budgets (`Concept_Document.md`
  5.3): a story encounter with a modified opening states its intended fight
  length.

## Documentation

`Technical_Design_Document.md` gains the story-state and dialogue architecture
as each system is implemented. Mode-structure decisions land in
`Concept_Document.md` 3.4.1 via `Plan_Story_Mode.md` step 5. This plan is the
implementation plan anticipated by `Plan_Story_Mode.md` step 6.
