class_name TurnBar extends Panel

const TURN_BAR_BUMP_GOOD = preload("uid://7aqjlq70jbhi")
const TURN_BAR_LAVA_ZONE = preload("uid://bognvuid7w2ti")

const Types = preload("res://Scripts/common_enums.gd")
const DEFAULT_THEME = preload("uid://c8irweh6md2jy")
const GRAYSCALE = preload("uid://ia57lns0336p")
const NO_CHARACTERS_TURN: int = -1
var BASE_VELOCITY: float = self.size.x / Game_Balance.TURN_DURATION_SECONDS
var GRAYSCALE_MATERIAL: ShaderMaterial

@export var _char_turns: Array[TextureRect]
var _highest_speed: int = 0
var _characters_normalized_speed: Dictionary[int, float]
var _characters_turn_ID = -1
var _zone_dividers: Array[ColorRect]
var _zone_buttons: Array[Button]
var _zone_effects: Array[Node2D]

func Init(p_characters: Dictionary[int, Character], p_zone_callable: Callable):
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
	
	var stylebox: StyleBoxFlat
	_zone_buttons.resize(Game_Balance.NUMBER_OF_TURN_BAR_ZONES)
	_zone_effects.resize(Game_Balance.NUMBER_OF_TURN_BAR_ZONES)
	for i in _zone_buttons.size():
		_zone_buttons[i] = Button.new()
		_zone_buttons[i].position = Vector2((self.size.x / Game_Balance.NUMBER_OF_TURN_BAR_ZONES) * i, 0.0)
		_zone_buttons[i].size = Vector2(self.size.x / Game_Balance.NUMBER_OF_TURN_BAR_ZONES, self.size.y)
		_zone_buttons[i].theme = DEFAULT_THEME
		_zone_buttons[i].connect("button_up", p_zone_callable.bind(i))
		stylebox = _zone_buttons[i].get_theme_stylebox("normal")
		stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.196)
		_zone_buttons[i].add_theme_stylebox_override("normal", stylebox)
		self.add_child(_zone_buttons[i])
	
	_zone_dividers.resize(Game_Balance.NUMBER_OF_TURN_BAR_ZONES - 1)
	for i in range(_zone_dividers.size()):
		_zone_dividers[i] = ColorRect.new()
		_zone_dividers[i].color = Color(0.0, 0.0, 0.0, 0.49)
		_zone_dividers[i].size = Vector2(3.0, self.size.y)
		_zone_dividers[i].position = Vector2((self.size.x / Game_Balance.NUMBER_OF_TURN_BAR_ZONES) * (i + 1), 0.0)
		self.add_child(_zone_dividers[i])
	
	DisableZones(true)

func SpawnZoneEffect(p_zone_ID: int, p_duration: int, p_allySide: bool, p_zone_type: Types.Skill_Type):
	var effect: TurnBarContainer
	match p_zone_type:
		Types.Skill_Type.Flicker_Zone:
			effect = TURN_BAR_BUMP_GOOD.instantiate()
		Types.Skill_Type.Lava_Zone:
			effect = TURN_BAR_LAVA_ZONE.instantiate()
			effect.cpu_particles_2d_side_1.emission_rect_extents.x = _zone_buttons[p_zone_ID].size.x * 0.5
		_:
			print("Invalid zone type! value: ", p_zone_type)
			return
	effect.background.position = Vector2(-(_zone_buttons[p_zone_ID].size.x * 0.5), -_zone_buttons[p_zone_ID].size.y)
	effect.background.size = _zone_buttons[p_zone_ID].size
	effect.cpu_particles_2d_up_1.emission_rect_extents.x = _zone_buttons[p_zone_ID].size.x * 0.5
	effect.cpu_particles_2d_up_2.emission_rect_extents.x = _zone_buttons[p_zone_ID].size.x * 0.5
	_zone_effects[p_zone_ID] = effect
	_zone_effects[p_zone_ID].position = Vector2(
		_zone_buttons[p_zone_ID].position.x + (_zone_buttons[p_zone_ID].size.x * 0.5),
		_zone_buttons[p_zone_ID].position.y + _zone_buttons[p_zone_ID].size.y)
	self.add_child(_zone_effects[p_zone_ID])
	
	if(0 > p_duration):
		_zone_effects[p_zone_ID].label.text = "inf"
	else:
		_zone_effects[p_zone_ID].label.text = str(p_duration)
	if(p_allySide):
		_zone_effects[p_zone_ID].label.position = Vector2(-(_zone_buttons[p_zone_ID].size.x * 0.25), -(_zone_buttons[p_zone_ID].size.y * 0.95))
		_zone_effects[p_zone_ID].label.modulate = Color(0.0, 0.653, 0.0, 1.0)
	else:
		_zone_effects[p_zone_ID].label.position = Vector2((_zone_buttons[p_zone_ID].size.x * 0.15), -(_zone_buttons[p_zone_ID].size.y * 0.95))
		_zone_effects[p_zone_ID].label.modulate = Color(0.85, 0.0, 0.0, 1.0)
	
	_zone_effects[p_zone_ID].show()

func RemoveZoneEffect(p_zone_ID: int):
	_zone_effects[p_zone_ID].hide()
	_zone_effects[p_zone_ID].queue_free()
	_zone_effects[p_zone_ID] = null

func ZoneTriggered(p_zone_ID: int, p_duration: int):
	if(0 == p_duration):
		RemoveZoneEffect(p_zone_ID)
		return
	if(0 > p_duration):
		_zone_effects[p_zone_ID].label.text = "inf"
	else:
		_zone_effects[p_zone_ID].label.text = str(p_duration)

func _zone_button() -> void:
	DisableZones(true)

func GetActiveTurnID() -> int:
	return _characters_turn_ID

func DisableZones(p_disable: bool):
	for button in _zone_buttons:
		button.disabled = p_disable

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

func BumpCharacter(p_character_ID: int, p_percent_change: float):
	_char_turns[p_character_ID].position.x += p_percent_change * self.size.x
	ConstrictTurnLocation(p_character_ID)

func ConstrictTurnLocation(p_character_ID: int) -> void:
	_char_turns[p_character_ID].position.x = clamp(_char_turns[p_character_ID].position.x, 0, self.size.x - _char_turns[p_character_ID].size.x)

func ShowCharacterAsDead(p_dead_char_ID: int):
	_char_turns[p_dead_char_ID].material = GRAYSCALE_MATERIAL

func IsCharacterInZone(p_character_ID: int, p_zone_ID: int) -> bool:
	if(null == _zone_effects[p_zone_ID]):
		return false
	if(!_char_turns[p_character_ID].get_rect().intersects(_zone_buttons[p_zone_ID].get_rect())):
		return false
	return true
	
