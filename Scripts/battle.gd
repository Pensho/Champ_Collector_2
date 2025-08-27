extends Node2D

@onready var battle_ui: Control = $"Battle UI"
@onready var background: TextureRect = %BattleBackground
@onready var boss_position: Node2D = $"Boss Position"

@onready var character_repr_1: CharacterRepresentation = $Character_1
@onready var character_repr_2: CharacterRepresentation = $Character_2
@onready var character_repr_3: CharacterRepresentation = $Character_3

#@onready var character_repr_1: Node2D = $Character_1
#@onready var character_repr_2: Node2D = $Character_2
#@onready var character_repr_3: Node2D = $Character_3

#const k_pos_char_1: Vector2 = Vector2(70,370)
#const k_pos_char_2: Vector2 = Vector2(280,430)
#const k_pos_char_3: Vector2 = Vector2(530,460)

func _ready() -> void:
	pass

func Init(context: ContextContainer) -> void:
	var battlecontext: Context_Battle = context._context as Context_Battle
	background.texture = load(battlecontext._location)
	
	var char_1: Character = context._current_collection.GetCharacter(0)
	var char_2: Character = context._current_collection.GetCharacter(1)
	var char_3: Character = context._current_collection.GetCharacter(2)
	
	character_repr_1._level.text = str(char_1._level)
	character_repr_2._level.text = str(char_2._level)
	character_repr_3._level.text = str(char_3._level)
	
	character_repr_1._character_texture.texture = load(char_1._texture)
	character_repr_2._character_texture.texture = load(char_2._texture)
	character_repr_3._character_texture.texture = load(char_3._texture)
	
	character_repr_1._lifebar.max_value = char_1._health
	character_repr_2._lifebar.max_value = char_2._health
	character_repr_3._lifebar.max_value = char_3._health
	
	character_repr_1._lifebar.value = char_1._currentHealth
	character_repr_2._lifebar.value = char_2._currentHealth
	character_repr_3._lifebar.value = char_3._currentHealth

	character_repr_1._lifebar_text.text = str(char_1._currentHealth) + "/" + str(char_1._health)
	character_repr_2._lifebar_text.text = str(char_2._currentHealth) + "/" + str(char_2._health)
	character_repr_3._lifebar_text.text = str(char_3._currentHealth) + "/" + str(char_3._health)
