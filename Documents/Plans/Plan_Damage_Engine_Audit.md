# Plan: Damage Engine Audit

Sweep every Role's kit against `Concept_Document.md` 1.1.7: which engine parts each passive and
skill supplies, and which step properties a team built from them can show. The result is a
ledger of engine parts and a gap list, which opens `Plan_Threshold_Triggers_And_Accelerators.md`.
This is a **design-only pass**; no code is written.

Sources per Role: Concept 3.1.3 (passive), 3.2.4.2 (skills), and `Role_Kit_Design.md` section 9,
cross-checked against `Scripts/Debug/kit_contribution_manifest.gd`. Where the manifest and the
Concept Document disagree, the manifest describes what ships; record the disagreement in the
ledger cell.

## Steps

### 1. Settle the ledger shape
Agree the table with the user before sweeping. Starting proposal: one row per Role; columns
Accumulator, Accelerator, Threshold trigger, Protector, each naming the passive or skill that
supplies the part (or `—`); a final column for the step properties the Role's parts can
contribute to a team. An accelerator cell names the mechanic class it speeds up, never a
specific Role (`Role_Kit_Design.md` section 2).

### 2. Sweep the Roles
Four batches of five Roles, in the order of Concept 3.2.4.2. The user reviews each batch
before the next. Classify by what the mechanic does in play, not by its channel tag.

### 3. Team-level read
Run the classification over the teams in `Scripts/Debug/team_corpus.gd`: for each team, which
parts it assembles and whether it meets 1.1.7's two-property guidance. List the teams that
fall short and the missing property for each.

### 4. Gap list
From steps 2 and 3: parts missing or thin across the roster, step properties no team reaches,
and Roles whose only contribution is a single-snapshot factor. A Role whose identity is
Enabler and supplies only Protector parts is a full pass, not a gap. Write the gap list as the
opening section of `Plan_Threshold_Triggers_And_Accelerators.md`.

## Watch for
- Classifying a capped automatic stack as an accumulator is correct; whether it gives the player
  a cash-out choice is a separate column, and usually it does not.
- Interactions that work by accident (a skill that happens to fire another kit's accumulator)
  count as accelerators in the ledger; flag them so plan 2 decides whether to keep them.
- Naming allowlist applies to ledger labels.

## Documentation
The ledger lands in `Role_Kit_Design.md` as a new section 10.4, Engine parts. The gap list
moves into the next plan. Delete this plan once both are written.
