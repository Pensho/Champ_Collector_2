class_name EquipmentPreset extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@warning_ignore_start("unused_private_class_variable")

@export var _name: String = "item name"
@export var _slot: Types.Slot
@export var _rarity: Types.Rarity
@export var _texture_path: String = ""
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

@warning_ignore_restore("unused_private_class_variable")

func Setup() -> void:
	var random_attribute_element: int = -1
	for i in _rarity:
		if(Game_Balance.ITEM_TYPE_ATTRIBUTES.has(_slot)):
			random_attribute_element = randi() % Game_Balance.ITEM_TYPE_ATTRIBUTES[_slot].size()
			if(Types.Attribute.CritDamage != random_attribute_element):
				_attributes[Game_Balance.ITEM_TYPE_ATTRIBUTES[_slot][random_attribute_element]] += Game_Balance.ITEM_ATTRIBUTE_PER_RARITY
			else:
				_attributes[Game_Balance.ITEM_TYPE_ATTRIBUTES[_slot][random_attribute_element]] += Game_Balance.ITEM_ATTRIBUTE_PER_RARITY
