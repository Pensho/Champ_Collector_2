class_name GearData extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@export var _name: String = "item name"
@export var _slot: Types.Slot
@export var _rarity: Types.Rarity
var _level: int = 1

# Attributes
@export var _health: int = 0
@export var _speed: int = 0
@export var _attack: int = 0
@export var _defence: int = 0
@export var _accuracy: int = 0
@export var _resistance: int = 0
@export var _mysticism: int = 0
@export var _knowledge: int = 0
@export var _pressence: int = 0
@export var _critChance: int = 0
@export var _critDamage: int = 0
