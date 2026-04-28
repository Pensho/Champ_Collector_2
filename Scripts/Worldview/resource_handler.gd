class_name ResourceHandler extends Node

const SILVER_COIN_TEXTURE = preload("uid://cqc2eqqmdc30j")
const SUPPLIES_TEXTURE = preload("uid://64keags07tr4")
const FORTUNES_FAVOR_BONE_1 = preload("uid://d3ribnb76plyc")
const FORTUNES_FAVOR_BRASS_1 = preload("uid://dq3fohqivkweb")
const FORTUNES_FAVOR_PARCHMENT_1 = preload("uid://d1le2k5exvc1b")

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

func SpendSupplies(amount: int) -> bool:
	if (_supplies >= amount):
		_supplies -= amount
		return true
	return false