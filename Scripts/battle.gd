extends Node2D

@onready var battle_ui: BattleUI = $"Battle UI"
@onready var background: TextureRect = %BattleBackground

@onready var enemy_repr_1: CharacterRepresentation = $Enemy_1
@onready var enemy_repr_2: CharacterRepresentation = $Enemy_2
@onready var enemy_repr_3: CharacterRepresentation = $Enemy_3

@onready var character_repr_1: CharacterRepresentation = $Character_1
@onready var character_repr_2: CharacterRepresentation = $Character_2
@onready var character_repr_3: CharacterRepresentation = $Character_3

@onready var turn_indicator: TextureRect = $Turn_Indicator

var _char_1: Character
var _char_2: Character
var _char_3: Character

var _enemy_1: Character
var _enemy_2: Character
var _enemy_3: Character

const TURN_POS_X_THRESHOLD: int = 360

var _characters_turn: Character = null
var _initialized: bool = false

func _process(delta: float) -> void:
	if(_initialized):
		UpdateBattle(delta, _char_1, 0, character_repr_1)
		UpdateBattle(delta, _char_2, 1, character_repr_2)
		UpdateBattle(delta, _char_3, 2, character_repr_3)
		UpdateBattle(delta, _enemy_1, 3, enemy_repr_1)
		UpdateBattle(delta, _enemy_2, 4, enemy_repr_2)
		UpdateBattle(delta, _enemy_3, 5, enemy_repr_3)

func UpdateBattle(delta: float, character: Character, battleSlot: int, representation: CharacterRepresentation) -> void:
	if (null != _characters_turn):
		return
	if(character._currentHealth <= 0):
		return
	if(battle_ui._char_turns[battleSlot].position.x + battle_ui._char_turns[battleSlot].get_rect().size.x < TURN_POS_X_THRESHOLD):
		battle_ui._char_turns[battleSlot].position = battle_ui._char_turns[battleSlot].position + Vector2(character._speed * delta, 0)
	else:
		_characters_turn = character
		turn_indicator.position.x = representation.position.x + (representation._character_texture.size.x * 0.5) - (turn_indicator.size.x * 0.5)
		turn_indicator.position.y = representation.position.y - turn_indicator.size.y
		turn_indicator.show()

func CharPreperations(p_repr: CharacterRepresentation, p_character: Character) -> void:
	p_repr._level.text = str(p_character._level)
	p_repr._character_texture.texture = load(p_character._texture)
	p_repr._lifebar.max_value = p_character._health
	p_repr._lifebar.value = p_character._currentHealth
	p_repr._lifebar_text.text = str(p_character._currentHealth) + "/" + str(p_character._health)

func Init(p_context: ContextContainer) -> void:
	print("Entering a battle scene.")
	var battlecontext: Context_Battle = p_context._context as Context_Battle
	background.texture = load(battlecontext._location)
	
	_char_1 = p_context._current_collection.GetCharacter(0)
	_char_2 = p_context._current_collection.GetCharacter(1)
	_char_3 = p_context._current_collection.GetCharacter(2)
	
	CharPreperations(character_repr_1, _char_1)
	CharPreperations(character_repr_2, _char_2)
	CharPreperations(character_repr_3, _char_3)
	
	battle_ui._char_turns[0].texture = load(_char_1._texture)
	battle_ui._char_turns[1].texture = load(_char_2._texture)
	battle_ui._char_turns[2].texture = load(_char_3._texture)
	
	for enemy in battlecontext._enemies_wave_1:
		print("found enemy: ", enemy._name)
	
	if (battlecontext._enemies_wave_1.size() >= 1):
		_enemy_1 = Character.new()
		_enemy_1.InstantiateNew(battlecontext._enemies_wave_1[0], -1)
		CharPreperations(enemy_repr_1, _enemy_1)
		battle_ui._char_turns[3].texture = load(_enemy_1._texture)
	else:
		print("Accidental load to battle scene without enemies.")
		get_tree().quit()
	if (battlecontext._enemies_wave_1.size() >= 2):
		_enemy_2 = Character.new()
		_enemy_2.InstantiateNew(battlecontext._enemies_wave_1[1], -1)
		CharPreperations(enemy_repr_2, _enemy_2)
		battle_ui._char_turns[4].texture = load(_enemy_2._texture)
	else:
		enemy_repr_2.hide()
	if (battlecontext._enemies_wave_1.size() >= 3):
		_enemy_3 = Character.new()
		_enemy_3.InstantiateNew(battlecontext._enemies_wave_1[2], -1)
		CharPreperations(enemy_repr_3, _enemy_3)
		battle_ui._char_turns[5].texture = load(_enemy_3._texture)
	else:
		enemy_repr_3.hide()
	
	_initialized = true
