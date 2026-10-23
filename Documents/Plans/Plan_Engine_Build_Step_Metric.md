# Plan: Engine Build-Step Metric

Report the build-step readout `Concept_Document.md` 1.1.2 defines — turns-to-threshold and
fragility — per team. `BurstReachability` (`Technical_Design_Document.md` 7.10) scores one
snapshot at burst time: it scores uncapped per-instance sources at one instance and applies no
accumulated trait mutation, so accumulators and accelerators are invisible to it. This plan
adds the turn dimension.

## Steps

### 1. Choose the simulation basis
Decide with the user:
- **Manifest simulation:** extend `KitContributionManifest` entries with per-turn data
  (cooldown, gain per use, what feeds the accumulator) and step a model of the team turn by
  turn. Cheap and fast to sweep; it is a second description of the code and can drift.
- **Scripted real battle:** drive the real battle code with a fixed action sequence against a
  passive dummy built from `BlowoutCalibration.REFERENCE_PROFILES`. Faithful to the code;
  battle code reaches `main.GetInstance()`, so it runs inside GUT rather than as a standalone
  debug script.

### 2. Choose the sequence source
Hand-authored ideal sequence per corpus row, or a bounded search over action orders within
the tier's round budget (Concept 5.3). The search finds sequences nobody wrote down; its cost
grows with skills per champion and rounds.

### 3. Define the interruption set for fragility
A small fixed set, each applied once at the step that hurts most: strip one buff, deny one
status application, delay one champion's turn. Fragility is the turns-to-threshold increase
under the worst single interruption.

### 4. Implement
The simulator, reporting turns and rounds (one round is each fielded champion acting once)
until a resolution reaches the tier ratio, plus fragility. GUT tests for the pure logic:
cooldown gating, accrual per action, threshold detection, interruption application. Lint
`Scripts/` and run the suite.

### 5. Baseline
Run over `TeamCorpus` and record the baseline per team in `Role_Kit_Design.md` section 4,
next to the burst figures.

## Watch for
- Turn count depends on Speed and turn order; state which turn-bar model the simulator uses.
- The tier ratio is read from `BlowoutCalibration`, never restated in the simulator.
- An engine that never reaches the ratio inside the round budget reports that, rather than a
  number past the budget.

## Documentation
`Technical_Design_Document.md` 7.10 (new file and report); `Role_Kit_Design.md` section 4.
