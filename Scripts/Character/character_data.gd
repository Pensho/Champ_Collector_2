class_name CharacterData extends Resource

const Types = preload("res://Scripts/Character/character_types.gd")

@export var name: String
@export var rarity: Types.Rarity
@export var faction: Types.Faction
@export var role: Types.Role
@export var skills: Array[Skill]
