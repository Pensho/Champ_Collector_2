extends Node2D

@onready var _battle_ui: BattleUI = $"Battle UI"
@onready var _background: TextureRect = %BattleBackground

@export var _character_repr: Array[CharacterRepresentation]

@onready var _characters: Array[Character]

@onready var _turn_indicator: TextureRect = $Turn_Indicator

const TURN_POS_X_THRESHOLD: int = 360

var _characterIDs_turn: int = -1
var _initialized: bool = false

func _process(p_delta: float) -> void:
	if(_initialized):
		for i in _characters.size():
			Update(p_delta, i)

func Update(p_delta: float, p_characterID: int) -> void:
	if (-1 != _characterIDs_turn):
		return
	if(_characters[p_characterID]._currentHealth <= 0):
		return
	if(_battle_ui._char_turns[p_characterID].position.x + _battle_ui._char_turns[p_characterID].get_rect().size.x < TURN_POS_X_THRESHOLD):
		_battle_ui._char_turns[p_characterID].position = _battle_ui._char_turns[p_characterID].position + Vector2(_characters[p_characterID]._speed * p_delta, 0)
	else:
		_characterIDs_turn = p_characterID
		_turn_indicator.position.x = _character_repr[p_characterID].position.x + (_character_repr[p_characterID]._character_texture.size.x * 0.5) - (_turn_indicator.size.x * 0.5)
		_turn_indicator.position.y = _character_repr[p_characterID].position.y - _turn_indicator.size.y

func CharPreperations(p_characterID: int) -> void:
	_character_repr[p_characterID]._level.text = str(_characters[p_characterID]._level)
	_character_repr[p_characterID]._character_texture.texture = load(_characters[p_characterID]._texture)
	_character_repr[p_characterID]._lifebar.max_value = _characters[p_characterID]._health
	_character_repr[p_characterID]._lifebar.value = _characters[p_characterID]._currentHealth
	_character_repr[p_characterID]._lifebar_text.text = str(_characters[p_characterID]._currentHealth) + "/" + str(_characters[p_characterID]._health)
	_battle_ui._char_turns[p_characterID].texture = load(_characters[p_characterID]._texture)
	_character_repr[p_characterID].show()

func Init(p_context: ContextContainer) -> void:
	print("Entering a battle scene.")
	var battlecontext: Context_Battle = p_context._context as Context_Battle
	_background.texture = load(battlecontext._location)
	
	if(battlecontext._enemies_wave_1.is_empty()):
		print("Accidental load to battle scene without enemies, terminating application")
		get_tree().quit()
	elif(p_context._current_collection.GetAllCharacters().is_empty()):
		print("Accidental load to battle scene without player characters, terminating application")
		get_tree().quit()
	
	if(p_context._current_collection.GetAllCharacters().size() >= 3):
		for i in 3:
			_characters.append(p_context._current_collection.GetCharacter(i))
	else:
		for i in p_context._current_collection.GetAllCharacters():
			_characters.append(p_context._current_collection.GetCharacter(i))
	
	for i in _characters.size():
		CharPreperations(i)

	for i in battlecontext._enemies_wave_1.size():
		_characters.append(Character.new())
		_characters[i + 3].InstantiateNew(battlecontext._enemies_wave_1[i], -1)
		CharPreperations(i + 3)
		_battle_ui._char_turns[i + 3].texture = load(_characters[i + 3]._texture)
		_character_repr[i + 3].show()
		print("found enemy: ", _characters[i + 3]._name)
	
	_initialized = true
