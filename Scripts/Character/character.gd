class_name Character extends Node

const Types = preload("res://Scripts/Character/character_types.gd")

func InstantiateNew(preset: CharacterPreset, instanceID: int) -> void:
	_instanceID = instanceID
	
	_name = preset._name
	_texture = preset._texture
	_rarity = preset._rarity
	_faction = preset._faction
	_role = preset._role
	_skills = preset._skills
	_speed = preset._speed
	_attack = preset._attack
	_defence = preset._defence
	_accuracy = preset._accuracy
	_resistance = preset._resistance
	_mysticism = preset._mysticism
	_knowledge = preset._knowledge
	_pressence = preset._pressence
	_critChance = preset._critChance
	_critDamage = preset._critDamage
	_health = preset._health * 10
	_currentHealth = _health

# Preset Data
var _name: String = ""
var _texture: String = ""

var _rarity: Types.Rarity
var _faction: Types.Faction
var _role: Types.Role

var _instanceID : int = 0
var _experience : int = 0
var _level: int = 1

var _skills: Array[Skill] = []

# Attributes
var _speed: int = 0
var _attack: int = 0
var _defence: int = 0
var _accuracy: int = 0
var _resistance: int = 0
var _mysticism: int = 0
var _knowledge: int = 0
var _pressence: int = 0
var _critChance: int = 0
var _critDamage: int = 0

var _health: int = 0
var _currentHealth: int = 0
