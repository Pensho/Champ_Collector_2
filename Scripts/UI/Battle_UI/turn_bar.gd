class_name TurnBar extends Panel

const TURN_BAR_BUMP_GOOD = preload("uid://7aqjlq70jbhi")
const TURN_BAR_LAVA_ZONE = preload("uid://bognvuid7w2ti")

const DEFAULT_THEME = preload("uid://c8irweh6md2jy")
const GRAYSCALE = preload("uid://ia57lns0336p")
const NO_CHARACTERS_TURN: int = -1

@export var _character_turn_markers: Array[TextureRect]

var _base_velocity: float = self.size.x / Game_Balance.TURN_DURATION_SECONDS
var _grayscale_material: ShaderMaterial
var _characters_normalized_speed: Dictionary[int, float]
var _characters_turn_id = -1
var _zone_dividers: Array[ColorRect]
var _zone_buttons: Array[Button]
var _zone_effects: Array[Node2D]

func Init(p_characters: Dictionary[int, Character], p_zone_callable: Callable, p_player_team: CombatTeam):
	var speeds: Dictionary[int, int] = {}
	for i in p_characters.keys():
		speeds[i] = p_characters[i].GetBattleAttribute(Types.Attribute.Speed)
	_characters_normalized_speed = NormalizeSpeeds(speeds)
	for i in p_characters.keys():
		_character_turn_markers[i].size.y = self.size.y * 0.7
		_character_turn_markers[i].size.x = _character_turn_markers[i].size.y
		_character_turn_markers[i].position.y = -15 + (i * 10)
		_character_turn_markers[i].texture = load(p_characters[i]._texture)
	_grayscale_material = ShaderMaterial.new()
	_grayscale_material.shader = GRAYSCALE
	
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
	SetupPlanReachOverlays(p_characters, p_player_team)

# Normalizes each character's speed against the fastest one, so the leader advances
# at 1.0 and everyone else in proportion. Both the maximum and the normalization must
# read the same (geared) speed source, or a gear-boosted character can exceed 1.0.
static func NormalizeSpeeds(p_speeds: Dictionary[int, int]) -> Dictionary[int, float]:
	var highest_speed: int = 0
	for id in p_speeds.keys():
		if (p_speeds[id] > highest_speed):
			highest_speed = p_speeds[id]
	var normalized: Dictionary[int, float] = {}
	for id in p_speeds.keys():
		if (highest_speed <= 0):
			normalized[id] = 0.0
		else:
			normalized[id] = float(p_speeds[id]) / float(highest_speed)
	return normalized

func SetupPlanReachOverlays(p_characters: Dictionary[int, Character], p_player_team: CombatTeam) -> void:
	var owner_ids: Array[int]
	for i in p_characters.keys():
		if (_GetReachThreshold(p_characters[i]) > 0.0):
			owner_ids.append(i)
	if (owner_ids.is_empty()):
		return

	var has_player_owner: bool = false
	var has_enemy_owner: bool = false
	for id in owner_ids:
		if (p_player_team.Has(id)):
			has_player_owner = true
		else:
			has_enemy_owner = true

	for id in owner_ids:
		var tint: Color = Color.WHITE
		if (has_player_owner and has_enemy_owner):
			tint = Color(0.6, 1.0, 0.6) if p_player_team.Has(id) else Color(1.0, 0.6, 0.6)
		var threshold: float = _GetReachThreshold(p_characters[id])
		var overlay := PlanReachOverlay.new()
		self.add_child(overlay)
		overlay.Setup(_character_turn_markers[id], threshold * self.size.x, tint, p_characters[id], self.size.y)

# Reach-threshold traits (Plan, Foresight) each expose a static GetReachThreshold by
# rarity; this dispatches to whichever one the character carries, 0.0 for neither.
func _GetReachThreshold(p_character: Character) -> float:
	if (p_character._trait is PlanTrait):
		return PlanTrait.GetReachThreshold(p_character._rarity)
	if (p_character._trait is ForesightTrait):
		return ForesightTrait.GetReachThreshold(p_character._rarity)
	return 0.0

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
	_zone_effects[p_zone_ID].z_index = 10
	_zone_effects[p_zone_ID].position = Vector2(
		_zone_buttons[p_zone_ID].position.x + (_zone_buttons[p_zone_ID].size.x * 0.5),
		_zone_buttons[p_zone_ID].position.y + _zone_buttons[p_zone_ID].size.y)
	self.add_child(_zone_effects[p_zone_ID])
	
	if(0 > p_duration):
		_zone_effects[p_zone_ID].label.text = "inf"
	else:
		_zone_effects[p_zone_ID].label.text = str(p_duration)
	if(p_allySide):
		_zone_effects[p_zone_ID].label.position = Vector2(
			-(_zone_buttons[p_zone_ID].size.x * 0.25), -(_zone_buttons[p_zone_ID].size.y * 0.95))
		_zone_effects[p_zone_ID].label.modulate = Color(0.0, 0.653, 0.0, 1.0)
	else:
		_zone_effects[p_zone_ID].label.position = Vector2(
			(_zone_buttons[p_zone_ID].size.x * 0.15), -(_zone_buttons[p_zone_ID].size.y * 0.95))
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

func GetActiveTurnID() -> int:
	return _characters_turn_id

func DisableZones(p_disable: bool):
	for button in _zone_buttons:
		button.disabled = p_disable

func TurnCompleteForCharacter(p_character_ID, p_reset_percent: float = 0.0) -> void:
	_character_turn_markers[p_character_ID].position.x = self.size.x * p_reset_percent
	_characters_turn_id = NO_CHARACTERS_TURN

## Returns the fraction of the bar's width this character just moved (0.0 while it is
## already someone's turn).
func Update(p_delta: float, p_character_ID) -> float:
	if(_characters_turn_id != NO_CHARACTERS_TURN):
		return 0.0

	var frame_distance: float = _base_velocity * _characters_normalized_speed[p_character_ID] * p_delta
	_character_turn_markers[p_character_ID].position.x += frame_distance

	var marker: TextureRect = _character_turn_markers[p_character_ID]
	if((marker.position.x + marker.size.x) > self.size.x):
		marker.position.x = self.size.x - marker.size.x
		_characters_turn_id = p_character_ID
	return frame_distance / self.size.x

func BumpCharacter(p_character_ID: int, p_percent_change: float):
	_character_turn_markers[p_character_ID].position.x += p_percent_change * self.size.x
	ConstrictTurnLocation(p_character_ID)

func ConstrictTurnLocation(p_character_ID: int) -> void:
	_character_turn_markers[p_character_ID].position.x = clamp(
		_character_turn_markers[p_character_ID].position.x, 0.0, self.size.x - _character_turn_markers[p_character_ID].size.x)

## p_character_ID is from which character it is measured.
## p_bar_percent is how far along the bar a character must have passed to be included. 0.0 - 1.0
func GetCharactersWithinRange(p_character_ID: int, p_bar_percent: float) -> Array[int]:
	var character_ids: Array[int]
	if (0.0 > p_bar_percent or p_bar_percent > 1.0):
		print("GetCharactersWithinRange, span supplied is not within range: ", p_bar_percent)
		return character_ids
	
	for id in _character_turn_markers.size():
		if(0.0 == _character_turn_markers[id].position.x):
			continue
		if(_character_turn_markers[id].position.x < (p_bar_percent * self.size.x)):
			continue
		if(p_character_ID == id):
			continue
		character_ids.append(id)
	
	return character_ids

## p_owner_ID is the character the distance is measured from.
## p_bar_percent is the maximum span behind the owner another character may be to be
## included, as a fraction of the bar (0.0 - 1.0). Characters at or ahead of the owner
## are excluded.
func GetCharactersBehindBy(p_owner_ID: int, p_bar_percent: float) -> Array[int]:
	var character_ids: Array[int]
	if (0.0 > p_bar_percent or p_bar_percent > 1.0):
		print("GetCharactersBehindBy, span supplied is not within range: ", p_bar_percent)
		return character_ids

	var owner_position: float = _character_turn_markers[p_owner_ID].position.x
	for id in _character_turn_markers.size():
		if (p_owner_ID == id):
			continue
		var distance_behind: float = owner_position - _character_turn_markers[id].position.x
		if (distance_behind <= 0.0 or distance_behind > (p_bar_percent * self.size.x)):
			continue
		character_ids.append(id)

	return character_ids

func ShowCharacterAsDead(p_dead_char_ID: int):
	_character_turn_markers[p_dead_char_ID].material = _grayscale_material

func IsCharacterInZone(p_character_ID: int, p_zone_ID: int) -> bool:
	if(null == _zone_effects[p_zone_ID]):
		return false
	if(!_character_turn_markers[p_character_ID].get_rect().intersects(_zone_buttons[p_zone_ID].get_rect())):
		return false
	return true
	
