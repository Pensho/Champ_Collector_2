class_name Zone
extends Node

var _type: Types.Skill_Type
var _duration: int = -1
var _owner_ID: int = -1
var _target: Types.Skill_Target
var _owner_knowledge: int = 0
var _debuff_types: Array[Types.Debuff_Type] = []

func CreateNew(
		p_type: Types.Skill_Type,
		p_duration: int,
		p_owner_ID: int,
		p_target: Types.Skill_Target,
		p_owner_knowledge: int = 0,
		p_debuff_types: Array[Types.Debuff_Type] = []) -> void:
	_type = p_type
	_duration = p_duration
	_owner_ID = p_owner_ID
	_owner_knowledge = p_owner_knowledge
	_debuff_types = p_debuff_types
	match p_target:
		Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy:
			_target = p_target
		_:
			print("Invalid value as a target when creating a new zone: ", p_target)
