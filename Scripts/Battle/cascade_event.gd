class_name CascadeEvent extends RefCounted

## Flat union record posted to CascadeResolver (Concept_Document.md 1.1.3's cascade
## channel), in the same style as CombatResult: one shape carrying every field any
## trigger might need, rather than a subclass per trigger.

var trigger: Types.Cascade_Trigger
var subject_ID: int = -1
var origin_ID: int = -1
var buff_type: Types.Buff_Type = Types.Buff_Type.Invalid
var debuff_type: Types.Debuff_Type = Types.Debuff_Type.Invalid
var zone_ID: int = -1
var fraction: float = 0.0
var amount: int = 0
var instance_count: int = 1
## Skill_Resolved only: the caster's skill index (Character._skills) and the cast's
## resolved target IDs, so a listener can re-resolve that skill's effects.
var skill_ID: int = -1
var target_IDs: Array[int] = []
var distinct_debuff_type_count: int = 0
var repeating_source_ids: Array[int] = []
## Stamped by CascadeResolver.Post; never set by the poster. 0 means "not part of a
## cascade" — the first cascade level is 1, matching CombatResult.cascade_depth.
var depth: int = 0
## Stamped by CascadeResolver right before an instance's Cascade_Instance_Resolved
## notification: the mechanic that instance belongs to.
var mechanic_key: StringName = &""


func _init(p_trigger: Types.Cascade_Trigger) -> void:
	trigger = p_trigger

static func ForSkillResolved(p_caster_ID: int, p_skill_ID: int, p_target_IDs: Array[int]) -> CascadeEvent:
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Skill_Resolved)
	event.subject_ID = p_caster_ID
	event.skill_ID = p_skill_ID
	event.target_IDs = p_target_IDs
	return event
