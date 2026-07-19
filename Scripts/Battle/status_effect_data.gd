class_name StatusEffectData extends Resource

## Data-driven definition of one buff or debuff type, replacing the hardcoded match
## blocks in skills.gd/battle_resolver.gd. One resource per effect lives under
## Data/Status_Effects/ and is looked up through StatusEffectRegistry.

enum MagnitudeKind {
	AttributePercent,             # +/- magnitude * attribute, per attribute_modifiers sign
	MaxHealthPercent,             # magnitude * max Health
	DamageMultiplier,             # multiplies the holder's next damage roll
	TurnBarBump,                  # reserved for future turn-bar-effect statuses
	AttributePercentagePointAdd,  # +/- magnitude added directly (not percent-of-attribute), for
	# the crit stats
	MaxHealthAttributePercent,    # +magnitude to max Health
	PerTargetDebuffDamagePercent, # +magnitude damage per debuff on the target
	AttackerCritChanceBonus,      # +magnitude crit-chance points to the attacker
	AttackerCritDamageBonus,      # +magnitude crit-damage points to the attacker
	CasterAttributeSnapshotPercent, # tick value = magnitude * the applier's attribute, snapshotted at application
	IncomingHealReduction,          # -magnitude fraction off any heal the holder receives
	TurnBarMovementDamagePercent,   # magnitude * own Speed, dealt on each turn-bar progress trigger
	DamageAbsorb,                   # per-instance value is a Health pool consumed before Health itself (Barrier)
	RandomAttributePercent,         # magnitude on one random attribute, re-rolled each self-tick (Wanderlust)
}

@export var magnitude_kind: MagnitudeKind
# Attributes this effect touches, mapped to their sign (+1.0 / -1.0). Applied with the
# shared `magnitude` below by AttributePercent and AttributePercentagePointAdd.
@export var attribute_modifiers: Dictionary[Types.Attribute, float] = {}
@export var magnitude: float = 0.0
@export var duration_default: int = 2
@export var overwritable: bool = true
@export var stackable: bool = false
@export var applies_on_self_tick: bool = true
@export var applies_on_target_snapshot: bool = false
# Extra self-tick max-Health cost, independent of magnitude_kind.
@export var self_tick_max_health_cost_percent: float = 0.0
@export var icon: Texture2D
