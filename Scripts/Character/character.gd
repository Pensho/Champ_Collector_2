class_name Character extends Node

const Types = preload("res://Scripts/common_enums.gd")
const Statuses = preload("res://Scripts/status_effects.gd")

func InstantiateNew(preset: CharacterPreset, instanceID: int) -> void:
	_instanceID = instanceID
	
	_name = preset._name
	_texture = preset._texture
	_normal_map = preset._normal_map
	_rarity = preset._rarity
	_faction = preset._faction
	_role = preset._role
	_skills = preset._skills
	_attributes_weights = preset._attributes_weights
	
	_attributes[Types.Attribute.Health] = preset._health
	_attributes[Types.Attribute.Speed] = preset._speed
	_attributes[Types.Attribute.Attack] = preset._attack
	_attributes[Types.Attribute.Defence] = preset._defence
	_attributes[Types.Attribute.Accuracy] = preset._accuracy
	_attributes[Types.Attribute.Resistance] = preset._resistance
	_attributes[Types.Attribute.Mysticism] = preset._mysticism
	_attributes[Types.Attribute.Knowledge] = preset._knowledge
	_attributes[Types.Attribute.CritChance] = preset._critChance
	_attributes[Types.Attribute.CritDamage] = preset._critDamage
	
	_currentHealth = GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER

func GetEquipmentBonus(p_attribute: Types.Attribute) -> int:
	var bonus_stat: int = 0
	for i in _held_items.keys():
		bonus_stat += _held_items[i]._attributes[p_attribute]
	return bonus_stat

func GetBattleAttributes() -> Dictionary[Types.Attribute, int]:
	var battle_attributes: Dictionary[Types.Attribute, int] = _attributes.duplicate(true)
	for attribute in battle_attributes.keys():
		battle_attributes[attribute] += GetEquipmentBonus(attribute)
	return battle_attributes

func GetBattleAttribute(p_attribute: Types.Attribute) -> int:
	var attribute_val: int = _attributes[p_attribute]
	attribute_val += GetEquipmentBonus(p_attribute)
	return attribute_val

func AddEquipment(p_equipment: Equipment) -> void:
	if(not _held_items.has(p_equipment._slot)):
		_held_items[p_equipment._slot] = p_equipment
	else:
		print(_name + " already has equipment for ", p_equipment._slot)

# Preset Data
var _name: String = ""
var _texture: String = ""
var _normal_map: String = ""

var _rarity: Types.Rarity
var _faction: Types.Faction
var _role: Types.Role

var _instanceID : int = 0
@warning_ignore_start("unused_private_class_variable")
var _experience : int = 0
var _level: int = 1
@warning_ignore_restore("unused_private_class_variable")

var _skills: Array[Skill] = []

var _attributes: Dictionary[Types.Attribute, int] = {
	Types.Attribute.Health: 0,
	Types.Attribute.Speed: 0,
	Types.Attribute.Attack: 0,
	Types.Attribute.Defence: 0,
	Types.Attribute.Accuracy: 0,
	Types.Attribute.Resistance: 0,
	Types.Attribute.Mysticism: 0,
	Types.Attribute.Knowledge: 0,
	Types.Attribute.CritChance: 0,
	Types.Attribute.CritDamage: 0,
}

var _held_items: Dictionary[Types.Slot, Equipment]

var _currentHealth: int = 0
var _attributes_weights: Array[Types.Attribute]

@warning_ignore_start("unused_private_class_variable")
var _active_buffs: Array[StatusEffects.Buff] = []
var _active_debuffs: Array[StatusEffects.Debuff] = []
@warning_ignore_restore("unused_private_class_variable")
