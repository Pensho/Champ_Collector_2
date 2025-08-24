extends Node2D

@onready var battle_ui: Control = $"Battle UI"
@onready var background: TextureRect = %BattleBackground
@onready var boss_position: Node2D = $"Boss Position"

@onready var character_1: Character = $Character_1
@onready var character_2: Character = $Character_2
@onready var character_3: Character = $Character_3

const k_pos_char_1: Vector2 = Vector2(70,370)
const k_pos_char_2: Vector2 = Vector2(280,430)
const k_pos_char_3: Vector2 = Vector2(510,460)

func _ready() -> void:
	pass

func Init(context: ContextContainer) -> void:
	var battlecontext: Context_Battle = context._context as Context_Battle
	background.texture = load(battlecontext._location)
	
	#character_1 = context._current_collection.GetCharacter(0)
	#character_2 = context._current_collection.GetCharacter(1)
	#character_3 = context._current_collection.GetCharacter(2)
	
	character_1.position = k_pos_char_1
	character_2.position = k_pos_char_2
	character_3.position = k_pos_char_3
	
	character_1.texture_rect.texture = load(context._current_collection.GetCharacter(0)._texture)#character_1._texture)
	character_2.texture_rect.texture = load(context._current_collection.GetCharacter(1)._texture)#character_2._texture)
	character_3.texture_rect.texture = load(context._current_collection.GetCharacter(2)._texture)#character_3._texture)
