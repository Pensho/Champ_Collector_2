class_name Skill extends Resource

const Statuses = preload("uid://bp3pvvar4437")

@export var name: String = "New Skill"
@export var description: String = ""
@export var icon_path: String = ""
@export var target: Types.Skill_Target

# turn_effect is used as a percentage. -1.0 - 1.0
@export var turn_effect: float
@export var damage_scaling: Dictionary[Types.Attribute, float]
# cooldown is the amount of turns until the skill can be used again.
@export var cooldown: int = 0
@export var duration: int = 0

@export var skill_type: Types.Skill_Type
# defense_ignore_factor goes between 0.0 - 1.0
# lower the value = more damage that bypasses defense
@export var defense_ignore_factor: float = 1.0

@export var buffs: Dictionary[Types.Skill_Target, Array]
@export var debuffs: Dictionary[Types.Skill_Target, Array]

# Fraction of max Health each target group gains (positive) or pays (negative).
@export var health_change: Dictionary[Types.Skill_Target, float]
# Attribute-scaled healing per target group: group -> Dictionary[Types.Attribute, float].
@export var heal_scaling: Dictionary[Types.Skill_Target, Dictionary]
# Multiplier turning the Health the caster paid this cast into the granted Barrier's pool.
@export var barrier_from_health_paid: float = 0.0
@export var ramp_per_use: float = 0.0

# Per-buff duration; a buff type not present here uses `duration`.
@export var buff_duration_overrides: Dictionary[Types.Buff_Type, int]
# Turns shaved off every buff already on the target group.
@export var buff_duration_reduction: Dictionary[Types.Skill_Target, int]
# Buffs consumed from the target group (-1 = all) before damage resolves.
@export var consume_buffs: Dictionary[Types.Skill_Target, int]
# Additive damage fraction per buff counted (consumed, or held by the caster if
# consume_buffs is empty).
@export var damage_bonus_per_buff: float = 0.0
# Buffs stolen from the primary targets and re-applied to steal_buff_to.
@export var steal_buff_count: int = 0
@export var steal_buff_to: Types.Skill_Target
# Barrier pool as a fraction of the recipient's own max Health, mirroring
# barrier_from_health_paid.
@export var barrier_from_target_max_health: float = 0.0
# Buff set used instead of `buffs` on even-numbered casts of this skill.
@export var alternating_buffs: Dictionary[Types.Skill_Target, Array]
# At or above this Infraction tally on the primary target, duration and
# buff_duration_reduction each gain +1. 0 = off.
@export var escalated_at_infractions: int = 0
# Additive damage fraction applied when the caster's trait condition is met.
@export var bonus_damage_on_trait_condition: float = 0.0

var cooldown_left: int = 0
