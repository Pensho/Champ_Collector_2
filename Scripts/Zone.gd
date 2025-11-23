class_name Zone
extends Node

const Types = preload("uid://bkpa0hv70oydy")

var _type: Types.Skill_Type
var _duration: int = -1
var _owner_ID: int = -1
var _target: Types.Skill_Target

func CreateNew(p_type: Types.Skill_Type, p_duration: int, p_owner_ID: int, p_target: Types.Skill_Target) -> void:
	_type = p_type
	_duration = p_duration
	_owner_ID = p_owner_ID
	match p_target:
		Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy:
			_target = p_target
		_:
			print("Invalid value as a target when creating a new zone: ", p_target)
