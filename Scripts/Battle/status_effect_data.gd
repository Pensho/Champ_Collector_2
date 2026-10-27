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
	SelfTurnBarLossOnDamage,        # -magnitude turn bar to the holder when they take damage (Dead Weight)
	AllyTurnBarGainOnDamage,        # +magnitude turn bar to every living ally when the holder takes damage
	# (Battle Orders)
	IncomingDamageReduction,        # -magnitude fraction off any damage the holder takes (Spotlight)
	HolderMissingHealthDamagePercent,
	AttackerDamagePerHolderMissingHealth,
	HighestBasePrimaryAttributePercent, # +magnitude * the holder's own highest base primary
	# attribute (Health excluded)
	OutgoingDamagePercent,          # +value fraction to every hit the holder deals, never consumed
}

## When the status's effect plays: Triggered for a status that deals damage or heals, each time
## it does; Applied for every other status, each time it is applied or refreshed.
enum Effect_Moment {
	Applied,
	Triggered,
}

@export var magnitude_kind: MagnitudeKind
# Attributes this effect touches, mapped to their sign (+1.0 / -1.0). Applied with the
# shared `magnitude` below by AttributePercent and AttributePercentagePointAdd.
@export var attribute_modifiers: Dictionary[Types.Attribute, float] = {}
@export var magnitude: float = 0.0
# Upper bound of a rolled per-tick magnitude. When > magnitude, the tick rolls uniformly in
# [magnitude, magnitude_max] and the holder's Luck or Hexed biases the roll.
@export var magnitude_max: float = 0.0
@export var caster_scaled: bool = false
@export var duration_default: int = 2
@export var overwritable: bool = true
@export var stackable: bool = false
@export var permanent: bool = false
@export var max_stacks_in_place: int = 0
@export var applies_on_self_tick: bool = true
# Vestigial: attribute modifiers no longer read this flag (always live). Kept only so the 59
# existing .tres resources don't need a values migration; not consulted anywhere in code.
@export var applies_on_target_snapshot: bool = false
# Extra self-tick max-Health cost, independent of magnitude_kind.
@export var self_tick_max_health_cost_percent: float = 0.0
@export var damage_redirect_to_applier_fraction: float = 0.0
# Attacks against the holder gain this multiple of the instance's own value as a damage
# bucket, independent of magnitude_kind (e.g. Sanction's damage clause).
@export var attacker_damage_value_multiple: float = 0.0
@export var targeting_weight_multiplier: float = 1.0
@export var icon: Texture2D
## Null plays the default status effect showing the icon.
@export var effect_archetype: PackedScene
@export var effect_variant: EffectVariant
@export var effect_moment: Effect_Moment = Effect_Moment.Applied
@export_multiline var description: String = ""

## Fills the description's placeholders for one applied instance. {percent} shows the displayed
## fraction; {attribute_percent} scales it by attribute_modifiers' own weight, and
## {attacker_damage_percent} shows the attacker damage bucket built from the raw value.
func FormatDescription(p_amount: int, p_fraction: float, p_status_value: float) -> String:
	return (description.replace("{value}", str(p_amount))
			.replace("{attribute_percent}", str(roundi(p_fraction * AttributeModifierWeight() * 100.0)))
			.replace("{attacker_damage_percent}",
					str(roundi(p_status_value * attacker_damage_value_multiple * 100.0)))
			.replace("{percent}", str(roundi(p_fraction * 100.0)))
			.replace("{percent_decimal}", "%.1f" % (p_fraction * 100.0)))

## The magnitude of attribute_modifiers' weight, 1.0 for the usual +/-1.0 sign entries.
func AttributeModifierWeight() -> float:
	if(attribute_modifiers.is_empty()):
		return 1.0
	return absf(attribute_modifiers.values()[0])
