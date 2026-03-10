class_name ResourceHandler extends Node

var _silver: int
var _supplies: int
var _fortunes_favor: int

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

func Serialize() -> Dictionary:
	return {"silver": _silver, "supplies": _supplies, "fortunes_favor": _fortunes_favor}

func Deserialize(p_data: Dictionary) -> void:
	_silver = p_data["silver"]
	_supplies = p_data["supplies"]
	_fortunes_favor = p_data["fortunes_favor"]
