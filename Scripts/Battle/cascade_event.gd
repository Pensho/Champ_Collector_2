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
## Stamped by CascadeResolver.Post; never set by the poster. 0 means "not part of a
## cascade" — the first cascade level is 1, matching CombatResult.cascade_depth.
var depth: int = 0


func _init(p_trigger: Types.Cascade_Trigger) -> void:
	trigger = p_trigger
