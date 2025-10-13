class_name GearData extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@export var _name: String = "item name"
@export var _type: Types.Slot
@export var _rarity: Types.Rarity
@export var _texture_path: String = ""
var _level: int = 1
var _attributes: Dictionary[Types.Attribute, int]

func Setup() -> void:
	var random_attribute_element: int = -1
	for i in range(_rarity):
		if(main.GAME_BALANCE.ITEM_TYPE_ATTRIBUTES.has(_type)):
			random_attribute_element = randi() % main.GAME_BALANCE.ITEM_TYPE_ATTRIBUTES[_type].size()
			_attributes[main.GAME_BALANCE.ITEM_TYPE_ATTRIBUTES[_type][random_attribute_element]] += main.GAME_BALANCE.ITEM_ATTRIBUTE_PER_RARITY
