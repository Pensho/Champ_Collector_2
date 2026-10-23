# Plan: Threshold Triggers and Accelerators

Give the roster the engine parts `Concept_Document.md` 1.1.7 names but the kits barely carry:
threshold triggers, and accelerators that feed another kit's accumulator. Design first, then
code. Opens with the gap list from `Plan_Damage_Engine_Audit.md`; do not start step 2 before
that list exists.

## Gap list

Written by `Plan_Damage_Engine_Audit.md` step 4.

## Design constraints

- Adapt existing kits with the smallest change that closes a gap; a replacement skill or
  passive is the exception and is justified per Role.
- The per-Role contribution target in `Role_Kit_Design.md` section 4 holds; no Role is
  required to become an engine piece.
- Coupling stays indirect (`Role_Kit_Design.md` section 2): a threshold reads a mechanic class,
  and an accelerator feeds a mechanic class, never a named Role or skill.
- Concept 1.1.4 governs: a threshold whose payoff feeds its own accumulator is re-entry; a
  trigger fires once per originating action; automatic accrual is capped.
- An accumulator held as a status takes one of the eight status slots; prefer a trait resource
  unless the slot cost is the point.
- New sources interact with existing readers uniformly; no carve-outs for player sources.
- Accelerators for build-specific effects are applied deliberately, not by positional or
  automatic triggers.
- Stun- and Fatigue-class denial, and new Accuracy pressure, stay off the table.

## Brainstorm rules

Candidates are prompted with the constraints above and the gap list, never with example
mechanics. A threshold candidate states: the condition it reads, how the player sees progress
toward it, who can feed it, and whether firing is automatic or the player's call. Candidates
in one batch differ in the quantity the condition reads and in the channel the payoff lands
in. Rejected shapes:

- A threshold that fires on a fixed turn count with no player influence on timing.
- A condition only one Role can satisfy.
- An accelerator whose best case is a linear rate increase on a single source, failing 1.1.6.

## Steps

### 1. Settle the vocabulary
Decide with the user whether 1.1.7's parts become tags on kit entries alongside the channel
tags in Concept 1.1.3, or stay ledger-only in `Role_Kit_Design.md` 10.4.

### 2. Design batches
One `/brainstorm` batch per gap cluster, three to five Roles each. The user picks; accepted
designs are written into Concept 3.1.3 / 3.2.4.2 and the Role's `Role_Kit_Design.md` section 9
entry in the same edit, and the 10.4 ledger row is updated.

### 3. Technical design
Read `Technical_Design_Document.md` 7.8 (cascade resolution) and 9 (trait hooks) and decide
where a threshold lives: a trait hook, a cascade source, or a new resolver concept. Record the
decision in the Technical Design Document before implementing.

### 4. Implement per batch
Per accepted batch: data and scripts, a `KitContributionManifest` entry per changed kit, and
GUT tests for the threshold logic (condition met, fires once, respects caps, no re-entry). Lint
and run the suite after each Role.

### 5. Measure
Re-run burst reachability and, once `Plan_Engine_Build_Step_Metric.md` has shipped, the
build-step readout over the affected corpus teams; record the movement in
`Role_Kit_Design.md` section 4.

## Watch for
- Readability: a threshold whose progress the player cannot see breaks 1.1.7's guidance.
- A threshold that fires off the opponent's actions hands the engine's timing to the
  opponent; that is a lock surface (Concept 1.2), and is a choice, not a default.
- Coarse balancing: get the shape right; tune after playtests.

## Documentation
Concept 3.1.3, 3.2.4.2 (and 3.2.3 for any new status); `Role_Kit_Design.md` sections 4, 9,
10.4; `Technical_Design_Document.md` per step 3 and 7.10 for manifest changes.
