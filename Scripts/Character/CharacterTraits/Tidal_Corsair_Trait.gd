class_name TidalCorsairTrait extends CharacterTrait

var _sea_stack_texture: Texture2D
var _steel_stack_texture: Texture2D

func Init() -> void:
	_sea_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Sea.png")
	_steel_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")

func StartOfBattle() -> void:
	pass
