# Plan: Burst Presentation

Phase 4 of `Plan_Blowout_Alignment.md`. Delivers the presentation half of the design pillar:
`Concept_Document.md` 1.1.5 requires a burst to resolve as a **visible sequence** —
"each instance lands one at a time, attributed to its source, with the tempo and magnitude
escalating through the cascade rather than flushing at once."

Today a turn resolves in a single frame. `Battle._on_resolver_result_produced`
(`Scripts/Battle/battle.gd`) applies every `CombatResult` instantly — health bars, status
icons, death — and `ResolveTurn` calls `CompleteTurn()` immediately after. The one existing
pacing mechanism is the floating-text spawn queue in `Scripts/UI/Battle_UI/battle_ui.gd`,
which releases one pooled `CombatEffectText` every fixed 0.25 seconds regardless of what
produced it. A sixteen-instance cascade therefore reads exactly like a basic attack, only
longer.

Phase 3 left the hooks this phase consumes: `CombatResult.cascade_depth` is stamped centrally
in `BattleResolver._Emit`, and one `Kind.Cascade_Triggered` result is emitted immediately
before each cascade instance resolves. `battle.gd` currently handles that marker with an
explicit `pass` reserved for this work.

## Scope

**Paced: the floating text only.** Game state keeps applying instantly. There is no
result-replay layer, no health-after value on `CombatResult`, and no rewrite of the turn-flow
state machine. `BattleResolver` stays headless and synchronous; everything this plan adds
lives in the view.

**Escalation is expressed through the existing spawner** — a shrinking per-item delay, a
growing per-item size, and a shift toward red across a cascade, fully red by step ten. No new
UI surface: no banner, no combat log, no labelled text.

**Turn completion waits for the text queue to drain, capped at 2.0 seconds**, after which the
remainder is flushed and the turn completes regardless.

**Visual only.** Audio escalation is not in this phase.

## Steps

### Step 1 — `BurstPacing` (new, pure logic)

`Scripts/Battle/burst_pacing.gd`. The escalation curve as static functions. It lives under
`Scripts/Battle/` rather than `Scripts/UI/Battle_UI/` because `Test_Design_Document.md`
excludes all of `Scripts/UI/` from unit tests, and this is the only part of the phase with
logic worth testing.

```
class_name BurstPacing

const BASE_DELAY: float = 0.25
const MINIMUM_DELAY: float = 0.06
const DELAY_FALLOFF: float = 0.82
const BASE_SCALE: float = 1.0
const SCALE_GROWTH: float = 0.12
const MAXIMUM_SCALE: float = 2.0
const FULL_RED_STEP: int = 10

static func DelayForStep(p_step: int) -> float
static func ScaleForStep(p_step: int) -> float
static func ColorForStep(p_base_color: Color, p_step: int) -> Color
```

`p_step` is the cascade instance ordinal within the current action. Step `0` means "not part
of a cascade": `DelayForStep(0)` returns `BASE_DELAY`, `ScaleForStep(0)` returns `BASE_SCALE`,
and `ColorForStep(color, 0)` returns `color` unchanged, so every non-cascade text behaves
exactly as it does today. The step is bounded by
`CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION`, so all three curves are bounded by
construction — at the constants above, sixteen escalating releases total roughly 1.4 seconds.

`ColorForStep` linearly interpolates the given base color toward `Color.RED` as `p_step` rises
from `1` to `FULL_RED_STEP`, and clamps to `Color.RED` from `FULL_RED_STEP` on. It takes the
caller's color rather than assuming white, since `SpawnCombatText` is already called with
different colors per result kind (plain damage, the orange debuff tick, the grey "Status
Effects Full!" denial) and all of them should redden the same way rather than only the default
case.

The constants are starting points chosen to be retuned against a playable burst, not settled
values.

### Step 2 — Spawn queue escalation

`Scripts/UI/Battle_UI/battle_ui.gd` and `Scripts/UI/Battle_UI/combat_effect_text_.gd`.

* `CombatEffectText` gains an `escalation_step: int` field, set when the text is queued.
* `SpawnCombatText` gains a defaulted fourth parameter `p_escalation_step: int = 0`, so the
  existing call sites keep working unchanged.
* `_process` reads the released text's step: applies `BurstPacing.ScaleForStep()` and
  `BurstPacing.ColorForStep()` (against the color already set on the text via `SetValue`)
  before `Animate()`, and sets the spawn timer from `BurstPacing.DelayForStep()` rather than
  the fixed constant.
* New `IsPresenting() -> bool` and `FlushCombatText()`, which releases everything remaining
  in one frame.
* `TEXT_SPAWN_DELAY` is removed in favour of `BurstPacing.BASE_DELAY`, so the number has one
  home.

Watch for: `CombatEffectText.Animate()` plays an `AnimationPlayer` track plus a position
tween. If that animation keys `scale`, setting `scale` directly is overwritten on the first
frame — apply the size through the Label's font size or a parent node instead. Check this
before committing to the mechanism; it is the phase's one implementation unknown.

### Step 3 — Escalation step and turn gating

`Scripts/Battle/battle.gd`.

**Step tracking.** Add `_cascade_instance_ordinal: int`, reset to `0` at the top of
`StartTurn` and `ResolveTurn`. The `Cascade_Triggered` branch stops being a `pass` and
increments it. Every `SpawnCombatText` call in `_on_resolver_result_produced` passes the
ordinal. Because `Cascade_Triggered` is emitted before the instance's own results, the ordinal
is already correct when those results arrive.

**Turn gating.** `ResolveTurn` and the stunned-turn path currently call `CompleteTurn()`
inline. Both instead arm a wait — a presentation deadline of 2.0 seconds, with `_state` left
at `BattleState.Resolving`. `_process` gains a `Resolving` branch that counts the deadline
down and holds while the queue is presenting; when either the queue empties or the deadline
expires, it flushes and calls `CompleteTurn()`.

`CompleteTurn()` itself is unchanged, so battle-over handling, turn-bar completion and the
transition to `Advancing` keep their current order — they simply happen up to two seconds
later.

### Step 4 — Tests

`Tests/unit/test_burst_pacing.gd`, covering `BurstPacing` only. `battle.gd` and `Scripts/UI/`
stay untested per the exclusions in `Test_Design_Document.md`.

* Step `0` returns exactly `BASE_DELAY`, `BASE_SCALE`, and the input color unchanged —
  non-cascade behaviour is unchanged.
* Delay decreases strictly until it reaches the floor, then holds at `MINIMUM_DELAY`.
* Scale increases strictly until it reaches `MAXIMUM_SCALE`, then holds.
* `ColorForStep` returns exactly `Color.RED` at step `FULL_RED_STEP` and at every step beyond
  it, regardless of the input color.
* None of the three functions returns an out-of-bounds value for any step from `0` to
  `MAX_CASCADE_INSTANCES_PER_ACTION`.
* Summed delay across a full-fan-out cascade stays under the two-second cap, so the cap is a
  safety valve rather than the normal exit path.

Run with `./Tests/run_tests.sh`; lint with `gdlint Scripts/`.

### Step 5 — Documentation

* `Technical_Design_Document.md` gains a subsection under 7 for the presentation pacing layer:
  that the resolver stays headless and synchronous, that pacing lives entirely in the view,
  that `Cascade_Triggered` is the escalation signal, and that turn completion is gated on the
  text queue with a two-second ceiling. Cross-reference 7.8.
* `Concept_Document.md` 1.1.5 already states the requirement correctly and needs no edit.
* `Plan_Blowout_Alignment.md`: mark Phase 4 done in `## Status` and on the phase entry, in the
  pattern used for Phases 1 through 3.

## Deliberately not done

**Per-source attribution.** Section 1.1.5 asks for each instance to be "attributed to its
source"; this phase delivers the sequence, the tempo and the magnitude, but not the
attribution. Nothing in battle names a source today — floating text spawns at the target, and
there is no combat log. The cheapest available step is splitting the `Debuff_Tick` branch in
`battle.gd`, which collapses `amount_by_source` into a single aggregate number even though the
per-source breakdown is already carried on the result. Every fuller option — labelled text, a
cascade banner, a combat log — is a new UI surface and out of scope here.

Recorded as a `FeatureIdeas.md` entry so it survives this plan's deletion.

## Watch for

* The pacing curve is a feel question and cannot be settled on paper. Expect to retune
  `DELAY_FALLOFF`, `SCALE_GROWTH` and both caps after seeing a burst play.
* Health bars still drop to their final value in the first frame while the numbers are still
  arriving. This is a deliberate consequence of pacing the text only, and it is the first
  thing to revisit if the sequence does not read.
* `StartTurn` resolves the turn-start debuff ticks before player input is offered, and those
  texts are not gated by this phase's wait. If tick numbers start bleeding into the next
  action visibly, gate that path too rather than shortening the delays.
* The two-second cap exists so a long cascade cannot stall the battle. It is a ceiling, not
  a budget — if normal bursts are hitting it, the curve is wrong, not the cap.
