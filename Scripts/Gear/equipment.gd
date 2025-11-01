class_name Equipment extends Node

const Types = preload("res://Scripts/common_enums.gd")

func InstantiateNew(preset: EquipmentPreset, instanceID: int) -> void:
	_instanceID = instanceID
	
	_name = preset._name
	_texture = preset._texture_path
	_rarity = preset._rarity
	_slot = preset._slot
	
	_attributes[Types.Attribute.Health] = preset._attributes[Types.Attribute.Health]
	_attributes[Types.Attribute.Speed] = preset._attributes[Types.Attribute.Speed]
	_attributes[Types.Attribute.Attack] = preset._attributes[Types.Attribute.Attack]
	_attributes[Types.Attribute.Defence] = preset._attributes[Types.Attribute.Defence]
	_attributes[Types.Attribute.Accuracy] = preset._attributes[Types.Attribute.Accuracy]
	_attributes[Types.Attribute.Resistance] = preset._attributes[Types.Attribute.Resistance]
	_attributes[Types.Attribute.Mysticism] = preset._attributes[Types.Attribute.Mysticism]
	_attributes[Types.Attribute.Knowledge] = preset._attributes[Types.Attribute.Knowledge]
	_attributes[Types.Attribute.CritChance] = preset._attributes[Types.Attribute.CritChance]
	_attributes[Types.Attribute.CritDamage] = preset._attributes[Types.Attribute.CritDamage]

var _instanceID : int = 0

# Preset Data
var _name: String = ""
var _texture: String = ""

var _rarity: Types.Rarity
var _slot: Types.Slot

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
