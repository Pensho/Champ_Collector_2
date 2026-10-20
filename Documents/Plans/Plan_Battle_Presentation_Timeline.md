# Plan: Battle Presentation Timeline

`BattleResolver` produces and applies every `CombatResult` of an action in one frame, and
`Battle._on_resolver_result_produced` presents each one as it arrives. Only floating combat
text is paced (`Technical_Design_Document.md` 7.9). Health bars, status icons and the impact
reaction land the moment the skill is chosen. This plan holds an action's results in the view
and releases them on markers fired by a skill's effect scene, so damage lands when the effect
visibly hits.

Prerequisite: caster status ticks fire at the start of the turn, as `Concept_Document.md`
3.2.3.2 states, not inside `ResolveSkill`. That bug fix ships separately, before step 1.

## Conventions

- **The resolver stays headless and synchronous** (7.8). The timeline is view-only. It
  changes when a result is shown, never when it is applied.
- **A released result drives all of its visuals together:** combat text, bars, status icon,
  impact reaction and death.
- **Results are released immediately, as today, when** the skill has no presentation, the
  skip setting is on, the turn is a Stun turn, or the action is a reagent or graft. Step 5 can
  land with no visible change.
- **Hit-stop stays out** (9.3).

## Steps

### 1. Stamp results with presentation facts
`_Emit` already stamps `cascade_depth`. It now also stamps:
- `phase: Presentation_Phase` — `Skill_Effects` (from the start of `ResolveSkill` through
  the `Skill_Resolved` drain) or `Post_Cast` (everything after). `ResolveSkill` sets the
  resolver's current phase around each section.
- `effect_index: int = -1` — the top-level index into `Skill.effects` while that effect
  resolves. Nested effects inherit their parent's index.
- `target_health_after` and `target_max_health_after` — the target's values as they stand
  right after this result, so the bars can show each hit's own state.

Tests: `Tests/unit/test_combat_result_presentation_stamps.gd` covers the phase per section,
the effect index (including a nested effect), and the health snapshot across a two-hit skill.

### 2. Presentation data
- `SkillPresentation` (`Scripts/Battle/skill_presentation.gd`, `extends Resource`):
  `effect_scene: PackedScene`; `spawn_mode: Spawn_Mode` (`Per_Target`,
  `Per_Target_Staggered`, `Field_Wide`); `stagger_seconds: float`.
- `Skill.presentation: SkillPresentation`. Leaving it `null` means immediate release.
- `SkillEffect.impact: int = 0` — the impact marker that releases this effect's results.

### 3. Effect scene contract
`SkillEffectScene` (`Scripts/Battle/skill_effect_scene.gd`, `extends Node2D`) is the root of
every effect scene. Its `AnimationPlayer` holds one animation, and its method tracks call:
- `Impact(index: int)` → emits `impact_reached(index)`
- `CasterLunge()` → emits `lunge_requested`
- `PlaySound(cue: SoundCue)`, `StartLoop(cue: SoundCue, key: StringName)`,
  `StopLoop(key: StringName)` → `Audio_Handler`. Open loops stop when the animation ends.

`Play(caster_position: Vector2, target_position: Vector2)` positions the scene and starts the
animation. `finished` is emitted when the animation ends. `ImpactCount()` scans the
animation's method track for `Impact` keys. `Length()` returns the animation length.

### 4. `PresentationTimeline`
`Scripts/Battle/presentation_timeline.gd`, `RefCounted`, no nodes. Built from one action's
results, the skill's per-effect `impact` values, the spawn mode, the instance targets, and
the impact count. Every query returns results in their original order, and returns each
result exactly once:
- `ResultsForImpact(instance_target_ID, impact_index)` — `Skill_Effects` results outside any
  cascade, whose effect's `impact` matches and whose target matches the instance (any target
  for `Field_Wide`). An `impact` past the last marker counts as the last marker. Results
  with `effect_index == -1`, or whose target has no instance, go with the final impact of the
  final instance.
- `ResultsAfterFinalImpact()` — `Skill_Effects` cascade results, with their
  `Cascade_Triggered` brackets, so `BurstPacing` keeps escalating them.
- `RemainingResults()` — `Post_Cast`, plus anything not yet released. This is used at
  `finished` and at the deadline.

Tests: `Tests/unit/test_presentation_timeline.gd` covers each query, the three spawn modes,
clamping past the last impact, unmatched targets, cascade grouping, order preservation, and
a deadline flush after partial release.

### 5. Wire it into `Battle`
- Split the body of `_on_resolver_result_produced` into `PresentResult(result)`. While an
  action with a presentation is resolving, the handler buffers results; otherwise it calls
  `PresentResult` directly.
- `ResolveTurn` with a presentation: buffer, resolve, build the timeline, start the instances (staggered by index for `Per_Target_Staggered`),
  and route their signals to the timeline queries. `lunge_requested` replaces the immediate
  `_PlayAttackLunge`. Without a presentation, today's lunge stays.
- `UpdateLifeBar` takes the health values from the result being presented, instead of reading
  live state.
- `Resolving` completes once every instance has finished and `IsPresenting()` is false. The
  deadline becomes `PRESENTATION_DEADLINE` plus the longest instance's `Length()` plus its
  stagger. On the deadline, release `RemainingResults()`, stop the instances, and flush the
  combat text.

### 6. Effect instance pool
- A `Battle_Effect_Layer` node is authored in the battle scene.
- At `Battle.Init`, for each distinct `effect_scene` among every combatant's skills
  (including phase 2 skills), instance one copy per possible target (the larger side's size)
  under the layer, hidden. Instances are reused and reset on `finished`; none are freed
  during battle.

### 7. Skip setting
`Settings.skip_skill_effects` (persisted, default `false`), with a check box row in
`Settings_Menu.tscn` wired in `settings_menu.gd`. When on, every skill releases immediately.

### 8. Placeholder effect
`Scenes/Battle_Visual_Effects/placeholder_strike.tscn`: a `SkillEffectScene` with no art, a
`CasterLunge` key, one `Impact(0)` key and a short tail. Assign it to Stab so the path can be
checked in game. The first archetype replaces it.

### 9. Documentation
- `Technical_Design_Document.md`: rewrite 7.9 around the timeline (bars and reactions land on
  release); update 9.3 (lunge from the marker, reaction on release), 7.4 (result stamps) and
  3.4 (skip setting).
- `Concept_Document.md` 1.1.5: a skill's results land when its effect visibly hits.
- Delete this plan per `Documents/Plans/README.md`.

## Watch for

- Every live-state read in `PresentResult` (`_RefreshHealthLabel`, the barrier arithmetic,
  `Phase_Changed`'s skill list) must use the released result's own values.
- Traits subscribed to `result_produced` (Flintbrace, Standing Record) react on emission,
  not release. Buffering must not change that.
- Buffering is active only inside `ResolveTurn`. Reagent, graft and debug paths present
  immediately.
- The battle-over check stays in `CompleteTurn`, after everything is released.
- `gdlint Scripts/` passes. No plan or step references in code comments.
