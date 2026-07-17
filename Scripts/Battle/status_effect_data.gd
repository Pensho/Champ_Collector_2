class_name StatusEffectData extends Resource

## Data-driven definition of one buff or debuff type, replacing the hardcoded match
## blocks in skills.gd/battle_resolver.gd. One resource per effect lives under
## Data/Status_Effects/ and is looked up through StatusEffectRegistry.

enum MagnitudeKind {
	AttributePercent,  # +/- magnitude * affected_attribute
	MaxHealthPercent,  # damage-over-time: magnitude * max Health
	DamageMultiplier,  # multiplies the holder's next damage roll
	TurnBarBump,       # reserved for future turn-bar-effect statuses
}

@export var magnitude_kind: MagnitudeKind
@export var affected_attribute: Types.Attribute
# Default per-instance value (StatusEffects.Effect.value) applied when a status is
# created. 0.0 means there is no static default and the applier must set the
# instance's value directly (e.g. Phalanx Guard scales with the caster's rarity).
@export var magnitude: float = 0.0
@export var duration_default: int = 2
# Whether re-applying while already active refreshes the duration instead of no-op.
@export var overwritable: bool = true
# Whether re-applying while already active adds an independent stacked instance
# instead of refreshing/no-op (e.g. Burning from a Lava zone).
@export var stackable: bool = false
# Whether this effect ticks on the holder's own turn (self-tick, e.g. Enfeeble
# reducing the holder's Attack when they act).
@export var applies_on_self_tick: bool = true
# Whether this effect applies to the attribute snapshot taken whenever the holder is
# targeted by a skill (target-snapshot, e.g. Expose Weakness lowering Defence for an
# incoming hit).
@export var applies_on_target_snapshot: bool = false
@export var icon: Texture2D
