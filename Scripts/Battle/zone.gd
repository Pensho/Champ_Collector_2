class_name Zone
extends Node

var _charges: int = -1
var _owner_ID: int = -1
var _target: Types.Skill_Target
var _owner_knowledge: int = 0
var _owner_attributes: Dictionary[Types.Attribute, int] = {}
var _on_trigger: Array[SkillEffect] = []
var _visual_scene: PackedScene
# Characters currently standing in the zone who have already been affected by it this
# visit; cleared per-character when ZoneResolver detects they have left the section.
var _affected_since_entry: Array[int] = []
var _source_name: String = ""
# Multiplies every future on_trigger DamageEffect this zone resolves, applied as its own
# CombinedDamageModifier bucket (see damage_effect.gd) rather than mutating damage_scaling —
# set by ZoneResolver.AmplifyZoneDamage, e.g. the Sorcerer's Echo compounding on Unstable Rift.
var _damage_multiplier: float = 1.0

func CreateNew(
		p_charges: int,
		p_owner_ID: int,
		p_target: Types.Skill_Target,
		p_owner_attributes: Dictionary[Types.Attribute, int] = {},
		p_on_trigger: Array[SkillEffect] = [],
		p_visual_scene: PackedScene = null,
		p_source_name: String = "") -> void:
	_charges = p_charges
	_owner_ID = p_owner_ID
	_owner_attributes = p_owner_attributes
	_owner_knowledge = p_owner_attributes.get(Types.Attribute.Knowledge, 0)
	_on_trigger = p_on_trigger
	_visual_scene = p_visual_scene
	_source_name = p_source_name
	match p_target:
		Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy:
			_target = p_target
		_:
			print("Invalid value as a target when creating a new zone: ", p_target)
