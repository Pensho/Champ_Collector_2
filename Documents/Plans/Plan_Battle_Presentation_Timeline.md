# Plan: Battle Presentation Timeline

`BattleResolver` produces and applies every `CombatResult` of an action in one frame, and
`Battle._on_resolver_result_produced` presents each one as it arrives. Only floating combat
text is paced (`Technical_Design_Document.md` 7.9). This plan holds an action's results in the
view and releases them on markers fired by the skill's effect scene, so damage lands when the
effect visibly hits, and releases a cascade one echo at a time, each with its own effect.

Effects are built cheaply: a few archetype scenes reused through per-skill variants, with a
default derived for every skill that has none. The archetype inventory and its skill and
status mappings live in `Plan_Particle_Effects.md`; this plan builds the mechanism.

Already in place: `CombatResult` carries `phase`, `effect_index`, `target_health_after` and
`target_max_health_after`; `PresentationTimeline`, `SkillPresentation` and `SkillEffectScene`
exist in a first form that the steps below reshape.

## Conventions

- **The resolver stays headless and synchronous** (7.8). The timeline is view-only. It
  changes when a result is shown, never when it is applied.
- **A released result drives all of its visuals together:** combat text, bars, status icon,
  impact reaction, flash, reaction particles, sounds and death.
- **Results are released immediately when** the skip setting is on, the turn is a Stun turn,
  the action is a reagent or graft, the action has no effect instance, or the skill's derived
  default archetype is not built yet. Each step can land with no visible change.
- **Hit-stop stays out** (9.3).
- **Pooled, never instanced mid-battle.** Every effect scene a battle can play is instanced
  at `Battle.Init`; variants are applied at play time.

## Steps

### 1. Archetype scenes and variants
- `EffectVariant` (`Scripts/Battle/effect_variant.gd`, `Resource`): `texture`,
  `particle_texture`, `tint`, `scale`, `cast_cue`, `impact_cue`. Null fields keep the
  archetype's own look.
- `SkillEffectScene` gains:
  - `anchor: Anchor` (`Caster`, `Caster_Feet`, `Target`, `Target_Feet`, `Field_Center`) and
    `aim_at_target: bool`. `Play` places the scene at its anchor and rotates it toward the
    target when aiming, or mirrors it to face away from the caster otherwise.
  - `variant_sprites` and `variant_particles` exports, which `Play` hands the variant's
    texture, particle texture and tint.
  - `PlayCastSound()` and `PlayImpactSound()` method keys, which play the variant's cues, so
    the archetype sets the timing and the variant the sound. `PlaySound(cue)` stays for
    bespoke scenes.
  - A scale argument on `Play`, multiplied with the variant's scale.
- Character views expose a feet point for the `_Feet` anchors.

### 2. Presentation data
- `SkillPresentation`: `archetype: PackedScene` (a `SkillEffectScene`), `variant`,
  `spawn_mode`, `stagger_seconds`, and `echo_archetype` plus `echo_variant` for the skill's
  echoes. A bespoke scene is an archetype with no variant. A null echo archetype replays the
  skill's own.
- `StatusEffectData` gains `echo_archetype` and `echo_variant`. A null echo archetype plays
  the generic echo pulse with the status's icon as its texture.
- `CharacterPreset` gains `_hurt_cue`, `_death_cue` (null is silent) and
  `_vocal_pitch: float = 1.0`, carried onto `Character` like `_texture`.

### 3. Defaults
`PresentationDefaults` (`Scripts/Battle/presentation_defaults.gd`, static) reads a defaults
resource (`Data/Presentation/Presentation_Defaults.tres`) holding one archetype per category
in `Plan_Particle_Effects.md`'s library, plus the generic echo pulse. A null slot is an
archetype not built yet.
- `ForSkill(skill)` returns `skill.presentation`, or derives one: the first damage effect
  picks the physical or arcane impact by its scaling attributes; otherwise the first heal,
  barrier, buff or debuff effect picks its category. Spawn mode `Per_Target`.
- `ForSkillEcho(skill)` and `ForStatusEcho(status)` resolve the echo archetype and variant.

Tests: `Tests/unit/test_presentation_defaults.gd` covers each category, precedence when a
skill mixes effects, an explicit presentation winning, and a null slot.

### 4. Echo identity
`Cascade_Triggered` results name what the instance echoes: the skill (`source_ID` plus a
skill index) or the status type. `CascadeContribution` supplies it per instance, the way
`origin_for_instance` supplies the origin, and `BeginEchoInstance` stamps it.

Tests: extend `Tests/unit/test_cascade_resolution.gd` with a skill echo (Borrowed Time) and a
status echo (Comorbidity).

### 5. Timeline rules
`PresentationTimeline` changes:
- A result whose target has no instance releases at its own effect's impact, on the final
  instance. Only `effect_index == -1` results go with the final impact of the final instance.
- `ResultsAfterFinalImpact()` is replaced by `EchoCount()` and `ResultsForEcho(ordinal)`: the
  ordinal-th `Cascade_Triggered` bracket in emission order and the results up to the next
  bracket.

`BurstPacing.EffectScaleForStep(step)` grows an echo effect's scale per echo, bounded like
the other curves.

Tests: update `Tests/unit/test_presentation_timeline.gd` for both rules, nested echo
brackets, and the effect scale curve in `Tests/unit/test_burst_pacing.gd`.

### 6. Result reactions
A `ResultReactions` resource (`Data/Presentation/Result_Reactions.tres`) maps Damage, Heal,
Death, buff applied and debuff applied to a flash color, a reaction archetype and variant, and
a sound cue. `PresentResult` plays the row for each released result at the target, plus the
target's hurt cue (on Damage and Debuff_Tick with an amount) or death cue at
`_vocal_pitch`. `CharacterSpriteAnimator` takes the flash color; a heal flashes without the
squash and knockback.

Tests: the row lookup per result kind, in `Tests/unit/test_result_reactions.gd`.

### 7. Wire it into `Battle`
- Split the body of `_on_resolver_result_produced` into `PresentResult(result)`. While a
  presented action resolves, the handler buffers results; otherwise it calls `PresentResult`.
- `ResolveTurn`: buffer, resolve, resolve the presentation through `PresentationDefaults`,
  build the timeline, and start the instances per spawn mode (staggered by index for
  `Per_Target_Staggered`). Only the first instance's `lunge_requested` lunges the caster.
  Without a presentation, today's lunge stays.
- After the final instance's final impact, release echoes one at a time,
  `BurstPacing.DelayForStep` apart: each plays its echo effect on the bracket's subject at
  `EffectScaleForStep` and releases `ResultsForEcho`.
- `UpdateLifeBar` and the barrier arithmetic take values from the presented result.
- `Resolving` completes once every instance has finished, every echo is released, and
  `IsPresenting()` is false; then `RemainingResults()` is released. The deadline becomes
  `PRESENTATION_DEADLINE` plus the longest instance's `Length()` plus its stagger. On the
  deadline, release `RemainingResults()`, stop the instances, and flush the combat text.

### 8. Effect pool
A `Battle_Effect_Layer` node is authored in the battle scene. At `Battle.Init`, for each
distinct archetype among every combatant's resolved presentations (phase 2 skills included),
their echoes, and the reaction rows, instance:
- skill archetypes: one per possible target (the larger side's size);
- echo archetypes: enough to cover overlap, its `Length()` over `BurstPacing.MINIMUM_DELAY`,
  capped at `CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION`;
- reaction archetypes: one per combatant.

Instances are hidden, reset on `finished`, and never freed during battle.

### 9. Skip setting
`Settings.skip_skill_effects` (persisted, default `false`), with a check box row in
`Settings_Menu.tscn` wired in `settings_menu.gd`. When on, every skill releases immediately.

### 10. First archetypes
- `Scenes/Battle_Visual_Effects/slash.tscn`: anchor `Caster`, aimed; `PlayCastSound` and
  `CasterLunge` at the start, the sprite fading in and out quickly, `Impact(0)` at full
  opacity. Stab gets a variant on it, and the defaults resource's physical impact slot
  points at it.
- `Scenes/Battle_Visual_Effects/echo_pulse.tscn`: the generic echo pulse.

### 11. Documentation
- `Technical_Design_Document.md`: rewrite 7.9 around the timeline and echo release; update
  9.3 (lunge from the marker, reactions on release), 7.4 (result stamps), 7.8 (echo
  identity), 6.1 (`StatusEffectData` echo fields) and 3.4 (skip setting).
- `Concept_Document.md` 1.1.5: a skill's results land when its effect visibly hits, and each
  echo lands with its own effect, growing through the cascade.
- `Plan_Particle_Effects.md`: point its infrastructure section at the Technical Design
  Document.
- Delete this plan per `Documents/Plans/README.md`.

## Watch for

- Every live-state read in `PresentResult` (`_RefreshHealthLabel`, the barrier arithmetic,
  `Phase_Changed`'s skill list) must use the released result's own values.
- Traits subscribed to `result_produced` (Flintbrace, Standing Record) react on emission,
  not release. Buffering must not change that.
- Buffering is active only inside `ResolveTurn`. Start-of-turn, reagent, graft and debug
  results present immediately.
- An echo's combat text spawns with its release; the text queue's own delay must not stack
  on top of the echo spacing.
- The battle-over check stays in `CompleteTurn`, after everything is released.
- `gdlint Scripts/` passes. No plan or step references in code comments.
