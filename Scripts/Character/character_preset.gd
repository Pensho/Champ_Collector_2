class_name CharacterPreset extends Resource

const Types = preload("res://Scripts/common_enums.gd")

@warning_ignore_start("unused_private_class_variable")

@export var _name: String
@export var _texture: String
@export var _rarity: Types.Rarity
@export var _faction: Types.Faction
@export var _role: Types.Role
@export var _skills: Array[Skill]

# Default Attributes
@export var _health: int = 0
@export var _speed: int = 0
@export var _attack: int = 0
@export var _defence: int = 0
@export var _accuracy: int = 0
@export var _resistance: int = 0
@export var _mysticism: int = 0
@export var _knowledge: int = 0
@export var _pressence: int = 0
@export var _critChance: int = 5
@export var _critDamage: int = 15

@warning_ignore_restore("unused_private_class_variable")
