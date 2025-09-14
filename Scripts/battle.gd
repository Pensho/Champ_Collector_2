extends Node2D

const Common_Enums = preload("res://Scripts/common_enums.gd")

const TURN_POS_X_THRESHOLD: int = 360
const PLAYER_IDS: Array[int] = [0,1,2]
const MONSTER_IDS: Array[int] = [3,4,5]

@export var _character_repr: Array[CharacterRepresentation]

@onready var _battle_ui: BattleUI = $"Battle UI"
@onready var _background: TextureRect = %BattleBackground
@onready var _turn_indicator: TextureRect = $Turn_Indicator
@onready var _characters: Array[Character]

var _characterIDs_turn: int = -1
var _selected_skill_ID: int = 0
var _initialized: bool = false

func _process(p_delta: float) -> void:
	if(_initialized):
		for i in _characters.size():
			Update(p_delta, i)

func ConstrictTurnLocation(p_characterID: int) -> void:
	if(_battle_ui._char_turns[p_characterID].position.x + _battle_ui._char_turns[p_characterID].get_rect().size.x > TURN_POS_X_THRESHOLD):
		_battle_ui._char_turns[p_characterID].position.x = TURN_POS_X_THRESHOLD - _battle_ui._char_turns[p_characterID].get_rect().size.x
	elif(_battle_ui._char_turns[p_characterID].position.x < 0):
		_battle_ui._char_turns[p_characterID].position.x = 0

func Update(p_delta: float, p_characterID: int) -> void:
	if (PLAYER_IDS.has(_characterIDs_turn) or MONSTER_IDS.has(_characterIDs_turn)):
		return
	if(_characters[p_characterID]._currentHealth <= 0):
		return
	if(_battle_ui._char_turns[p_characterID].position.x + _battle_ui._char_turns[p_characterID].get_rect().size.x < TURN_POS_X_THRESHOLD):
		_battle_ui._char_turns[p_characterID].position += Vector2(_characters[p_characterID]._speed * p_delta, 0)
	else:
		_characterIDs_turn = p_characterID
		_turn_indicator.position.x = _character_repr[p_characterID].position.x + (_character_repr[p_characterID]._character_texture.size.x * 0.5) - (_turn_indicator.size.x * 0.5)
		_turn_indicator.position.y = _character_repr[p_characterID].position.y - _turn_indicator.size.y
		_turn_indicator.show()
		if(PLAYER_IDS.has(p_characterID)):
			_battle_ui.SetSkill1Texture(_characters[p_characterID]._skills[0].icon_path)
			_battle_ui.SetSkill2Texture(_characters[p_characterID]._skills[1].icon_path)
			_battle_ui.SetSkill3Texture(_characters[p_characterID]._skills[2].icon_path)
			_battle_ui._skill_button_1.show()
			_battle_ui._skill_button_2.show()
			_battle_ui._skill_button_3.show()

func UpdateLifeBar(p_characterID: int) -> void:
	_character_repr[p_characterID]._lifebar.max_value = _characters[p_characterID]._health
	_character_repr[p_characterID]._lifebar.value = _characters[p_characterID]._currentHealth
	_character_repr[p_characterID]._lifebar_text.text = str(_characters[p_characterID]._currentHealth) + "/" + str(_characters[p_characterID]._health)

func VisualizeCharacter(p_characterID: int) -> void:
	_character_repr[p_characterID]._level.text = str(_characters[p_characterID]._level)
	_character_repr[p_characterID]._character_texture.texture = load(_characters[p_characterID]._texture)
	UpdateLifeBar(p_characterID)
	_battle_ui._char_turns[p_characterID].texture = load(_characters[p_characterID]._texture)
	_character_repr[p_characterID].show()

func Init(p_context: ContextContainer) -> void:
	print("Entering a battle scene.")
	var battlecontext: Context_Battle = p_context._static_context as Context_Battle
	_background.texture = load(battlecontext._location)
	
	if(battlecontext._enemies_wave_1.is_empty()):
		print("Accidental load to battle scene without enemies, terminating application")
		get_tree().quit()
	elif(p_context._player_battle_characters.is_empty()):
		print("Accidental load to battle scene without player characters, terminating application")
		get_tree().quit()
	
	for i in p_context._player_battle_characters.size():
		_characters.append(p_context._player_battle_characters[i])
		VisualizeCharacter(i)

	for i in battlecontext._enemies_wave_1.size():
		_characters.append(Character.new())
		_characters[i + 3].InstantiateNew(battlecontext._enemies_wave_1[i], -1)
		VisualizeCharacter(i + 3)
		_battle_ui._char_turns[i + 3].texture = load(_characters[i + 3]._texture)
		_character_repr[i + 3].show()
		print("found enemy: ", _characters[i + 3]._name)
	
	_initialized = true

func FoundSkillTargets(p_target_ID: int, p_caster_ID: int) -> Array[int]:
	print("p_target_ID: ", p_target_ID, " p_caster_ID: ", p_caster_ID)
	var target_IDs: Array[int]
	if(_characters[p_target_ID]._currentHealth > 0):
		match _characters[p_caster_ID]._skills[_selected_skill_ID].target:
			Common_Enums.Skill_Target.Single_Enemy:
				if(PLAYER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
				elif(MONSTER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
			Common_Enums.Skill_Target.All_Enemies:
				if(PLAYER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append_array(MONSTER_IDS)
				elif(MONSTER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append_array(PLAYER_IDS)
			Common_Enums.Skill_Target.Random_Enemy:
				if(PLAYER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(3 + (randi() % 3))
				elif(MONSTER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(randi() % 3)
			Common_Enums.Skill_Target.Single_Ally:
				if(PLAYER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
				elif(MONSTER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
			Common_Enums.Skill_Target.All_Allies:
				if(PLAYER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append_array(PLAYER_IDS)
				elif(MONSTER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append_array(MONSTER_IDS)
			Common_Enums.Skill_Target.Random_Ally:
				if(PLAYER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(randi() % 3)
				elif(MONSTER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(3 + (randi() % 3))
			Common_Enums.Skill_Target.Ally_Not_Self:
				if (p_caster_ID != p_target_ID):
					if(PLAYER_IDS.has(p_caster_ID) and PLAYER_IDS.has(p_target_ID)):
						target_IDs.append(p_target_ID)
					elif(MONSTER_IDS.has(p_caster_ID) and MONSTER_IDS.has(p_target_ID)):
						target_IDs.append(p_target_ID)
			Common_Enums.Skill_Target.Random_One:
				target_IDs.append(randi() % 6)
			Common_Enums.Skill_Target.All:
				target_IDs.append_array(PLAYER_IDS)
				target_IDs.append_array(MONSTER_IDS)
			var INVALID_TYPE:
				print("Invalid argument for skill target enum passed: ", INVALID_TYPE)
	return target_IDs

func DamageDealt(p_attacker: Character, p_defender: Character, p_Skill_ID: int) -> int:
	var randomVal: float			= randf_range(0.95, 1.05)
	var initial_damage: float 		= (p_attacker._attack * p_attacker._skills[p_Skill_ID].damage) * randomVal
	var added: float 				= p_defender._defence + p_attacker._attack
	var mitigation_factor: float	= 0.5 + (0.5 * (p_attacker._attack / added))
	return initial_damage * mitigation_factor

func ResolveSkill(p_caster_ID: int, p_target_IDs: Array[int], p_skill_ID) -> void:
	var cast_skill: Skill = _characters[p_caster_ID]._skills[p_skill_ID]
	for target_ID in p_target_IDs:
		_characters[target_ID]._currentHealth -= DamageDealt(_characters[p_caster_ID], _characters[target_ID], p_skill_ID)
		if(_characters[target_ID]._currentHealth < 0):
			_characters[target_ID]._currentHealth = 0
		elif (_characters[target_ID]._currentHealth > _characters[target_ID]._health):
			_characters[target_ID]._currentHealth = _characters[target_ID]._health
		UpdateLifeBar(target_ID)
		print("_characters[target_ID]._currentHealth: ", _characters[target_ID]._currentHealth)

		_battle_ui._char_turns[target_ID].position += Vector2(cast_skill.turn_effect, 0)
		ConstrictTurnLocation(target_ID)

func _on_character_battle_target_selected(p_target_ID: int) -> void:
	if(PLAYER_IDS.has(_characterIDs_turn) or MONSTER_IDS.has(_characterIDs_turn)):
		var target_IDs: Array[int] = FoundSkillTargets(p_target_ID, _characterIDs_turn)
		if(target_IDs.size() > 0):
			print("Targets for skill found!")
			ResolveSkill(_characterIDs_turn, target_IDs, _selected_skill_ID)
			_battle_ui._skill_button_1.hide()
			_battle_ui._skill_button_2.hide()
			_battle_ui._skill_button_3.hide()
			_battle_ui._char_turns[_characterIDs_turn].position -= Vector2(TURN_POS_X_THRESHOLD - _battle_ui._char_turns[_characterIDs_turn].get_rect().size.x, 0)
			_characterIDs_turn = -1
			_turn_indicator.hide()
		else:
			print("Invalid target for skill")

func _on_battle_ui_battle_skill_selected(p_skill_ID: int) -> void:
	_selected_skill_ID = p_skill_ID
	print("_on_battle_ui_battle_skill_selected with ID: ", p_skill_ID)
