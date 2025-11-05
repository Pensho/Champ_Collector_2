class_name TurnBar extends Panel

const Types = preload("res://Scripts/common_enums.gd")
const GRAYSCALE = preload("uid://ia57lns0336p")
const NO_CHARACTERS_TURN: int = -1
var BASE_VELOCITY: float = self.size.x / main.GAME_BALANCE.TURN_DURATION_SECONDS
var GRAYSCALE_MATERIAL: ShaderMaterial

@export var _char_turns: Array[TextureRect]
var _highest_speed: int = 0
var _characters_normalized_speed: Dictionary[int, float]
var _characters_turn_ID = -1

func Init(p_characters: Dictionary[int, Character]):
	for i in p_characters.keys():
		if (p_characters[i]._attributes[Types.Attribute.Speed] > _highest_speed):
			_highest_speed = p_characters[i].GetBattleAttribute(Types.Attribute.Speed)
	for i in p_characters.keys():
		_characters_normalized_speed[i] = float(p_characters[i].GetBattleAttribute(Types.Attribute.Speed)) / float(_highest_speed)
		_char_turns[i].size.y = self.size.y * 0.7
		_char_turns[i].size.x = _char_turns[i].size.y
		_char_turns[i].position.y = -15 + (i * 10)
		_char_turns[i].texture = load(p_characters[i]._texture)
	GRAYSCALE_MATERIAL = ShaderMaterial.new()
	GRAYSCALE_MATERIAL.shader = GRAYSCALE

func GetActiveTurnID() -> int:
	return _characters_turn_ID

func TurnCompleteForCharacter(p_character_ID) -> void:
	_char_turns[p_character_ID].position.x = 0
	_characters_turn_ID = NO_CHARACTERS_TURN

func Update(p_delta: float, p_character_ID) -> void:
	if(_characters_turn_ID != NO_CHARACTERS_TURN):
		return
	
	var frame_distance: float = BASE_VELOCITY * _characters_normalized_speed[p_character_ID] * p_delta
	_char_turns[p_character_ID].position.x += frame_distance
	
	if((_char_turns[p_character_ID].position.x + _char_turns[p_character_ID].size.x) > self.size.x):
		_char_turns[p_character_ID].position.x = self.size.x - _char_turns[p_character_ID].size.x
		_characters_turn_ID = p_character_ID

func BumpCharacter(p_character_ID: int, p_progress_change: float):
	_char_turns[p_character_ID].position.x += p_progress_change * self.size.x
	ConstrictTurnLocation(p_character_ID)

func ConstrictTurnLocation(p_character_ID: int) -> void:
	_char_turns[p_character_ID].position.x = clamp(_char_turns[p_character_ID].position.x, 0, self.size.x - _char_turns[p_character_ID].size.x)

func ShowCharacterAsDead(p_dead_char_ID: int):
	_char_turns[p_dead_char_ID].material = GRAYSCALE_MATERIAL
