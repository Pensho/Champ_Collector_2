class_name Battle extends Node2D

const Types = preload("res://Scripts/common_enums.gd")
const ZoneType = preload("uid://bdjrfif0s60v4")
const GRAYSCALE = preload("uid://ia57lns0336p")

const NO_CHARACTERS_TURN: int = -1
const PLAYER_IDS: Array[int] = [0,1,2]
const ENEMY_IDS: Array[int] = [3,4,5]
var GRAYSCALE_MATERIAL: ShaderMaterial

@export var _character_repr: Array[CharacterRepresentation]

@onready var _battle_ui: BattleUI = $"Battle UI"
@onready var _background: TextureRect = %BattleBackground
@onready var _turn_indicator: TextureRect = $Turn_Indicator
@onready var _characters: Dictionary[int, Character]
@onready var _global_scene_darkness: DirectionalLight2D = $DirectionalLight2D
@onready var _global_scene_light: PointLight2D = $PointLight2D

var _self_context: ContextContainer

var _characterIDs_turn: int = -1
var _selected_skill_ID: int = 0
var _initialized: bool = false

var _zones: Dictionary[int, Zone]

enum WinningTeam
{
	Ongoing,
	Player_Won,
	Monsters_Won,
}

func Init(p_context: ContextContainer) -> void:
	var battlecontext: Context_Battle = p_context._static_context as Context_Battle
	_background.texture = load(battlecontext._location)
	_global_scene_darkness.color = battlecontext._global_scene_darkness
	_global_scene_darkness.height = battlecontext._scene_darkness_height
	_global_scene_light.color = battlecontext._global_scene_light
	_self_context = p_context
	_self_context._previous_scene = p_context._scene
	
	if(battlecontext._enemies_wave_1.is_empty()):
		print("Accidental load to battle scene without enemies, terminating application")
		get_tree().quit()
	elif(p_context._player_battle_characters.is_empty()):
		print("Accidental load to battle scene without player characters, terminating application")
		get_tree().quit()
	
	for i in p_context._player_battle_characters.size():
		_characters[i] = p_context._player_battle_characters[i]
		_characters[i]._currentHealth = _characters[i].GetBattleAttribute(Types.Attribute.Health)  * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
		VisualizeCharacter(i)
	
	for i in battlecontext._enemies_wave_1.size():
		_characters[i + 3] = Character.new()
		_characters[i + 3].InstantiateNew(battlecontext._enemies_wave_1[i], -1)
		_characters[i + 3]._attributes[Types.Attribute.Speed] += randi_range(-3, 3)
		_characters[i + 3]._currentHealth = _characters[i + 3].GetBattleAttribute(Types.Attribute.Health)  * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
		VisualizeCharacter(i + 3)
	
	for i in _characters.keys():
		for j in _characters[i]._skills.size():
			_battle_ui.LoadSkillTexture(_characters[i]._skills[j].icon_path)
	
	GRAYSCALE_MATERIAL = ShaderMaterial.new()
	GRAYSCALE_MATERIAL.shader = GRAYSCALE
	
	_battle_ui.Init()
	_battle_ui._turn_bar.Init(_characters, _on_turn_bar_zone_selected)
	_initialized = true

func _process(p_delta: float) -> void:
	if(_initialized):
		for i in _characters.keys():
			Update(p_delta, i)
	
	if(Input.is_key_pressed(KEY_A)):
		for i in _characters.keys():
			if (PLAYER_IDS.has(i)):
				_characters[i]._currentHealth = 1
				UpdateLifeBar(i)
	elif(Input.is_key_pressed(KEY_M)):
		for i in _characters.keys():
			if (ENEMY_IDS.has(i)):
				_characters[i]._currentHealth = 1
				UpdateLifeBar(i)

func StartTurn() -> void:
	_turn_indicator.position.x = _character_repr[_characterIDs_turn].position.x + (_character_repr[_characterIDs_turn]._character_texture.size.x * 0.5) - (_turn_indicator.size.x * 0.5)
	_turn_indicator.position.y = _character_repr[_characterIDs_turn].position.y - _turn_indicator.size.y
	_turn_indicator.show()
	for i in _characters[_characterIDs_turn]._skills.size():
		if(_characters[_characterIDs_turn]._skills[i].cooldown_left > 0):
			_characters[_characterIDs_turn]._skills[i].cooldown_left -= 1
	if(PLAYER_IDS.has(_characterIDs_turn)):
		_battle_ui.SetSkill1Texture(_characters[_characterIDs_turn]._skills[0].icon_path)
		_battle_ui.SetSkill2Texture(_characters[_characterIDs_turn]._skills[1].icon_path)
		_battle_ui.SetSkill3Texture(_characters[_characterIDs_turn]._skills[2].icon_path)
		_battle_ui._skill_button_1.show()
		_battle_ui._skill_button_2.show()
		_battle_ui._skill_button_3.show()
		_selected_skill_ID = 0
		_battle_ui.ActiveSkillGlow(_selected_skill_ID)
	elif(ENEMY_IDS.has(_characterIDs_turn)):
		# TODO: Clean this nested mess up
		# Using only the first skill for now.
		_selected_skill_ID = 0
		# Targets the first in order for now.
		for i in PLAYER_IDS:
			if(_characters.has(i) and _characters[i]._currentHealth >= 1):
				var target_IDs: Array[int] = Skills.FindSkillTargets(i, _characterIDs_turn, _characters[_characterIDs_turn]._skills[_selected_skill_ID])
				if(target_IDs.size() > 0):
					ResolveSkill(_characterIDs_turn, target_IDs, _selected_skill_ID)
					
					var battle_state = IsTheBattleOver()
					if (WinningTeam.Ongoing != battle_state):
						EndBattle(battle_state)
						break
				else:
					print("Invalid target for skill by an enemy! Something is wrong.")
				# A skill has resolved, break the loop for targeting.
				break
	TriggerZones()

func TriggerZones() -> void:
	if(!PLAYER_IDS.has(_characterIDs_turn)):
		return
	for character_ID in _characters.keys():
		for ID in _zones.keys():
			if(_battle_ui._turn_bar.IsCharacterInZone(character_ID, ID) and _zones[ID]._duration != 0):
				Skills.ResolveZoneEffect(_zones[ID], _characters[character_ID], character_ID, _battle_ui)
				_zones[ID]._duration -= 1
				_battle_ui._turn_bar.ZoneTriggered(ID, _zones[ID]._duration)
				# Restrict the trigger to one zone per character.
				break
	for ID in _zones.keys():
		if (_zones[ID]._duration == 0):
			_zones.erase(ID)

func Update(p_delta: float, p_characterID: int) -> void:
	# It already is someones turn, so return early.
	if (PLAYER_IDS.has(_characterIDs_turn) or ENEMY_IDS.has(_characterIDs_turn)):
		_turn_indicator.position.y = _character_repr[_characterIDs_turn].position.y - _turn_indicator.size.y + (sin(Time.get_ticks_msec() * 0.005) * 5)
		return
	# It isn't someones turn, but this character is dead so return early.
	if(_characters[p_characterID]._currentHealth <= 0):
		return
	# No ones turn yet, so move along the turn order.
	_battle_ui._turn_bar.Update(p_delta, p_characterID)
	_characterIDs_turn = _battle_ui._turn_bar.GetActiveTurnID()
	if(NO_CHARACTERS_TURN == _characterIDs_turn):
		return
	StartTurn()

func UpdateLifeBar(p_characterID: int) -> void:
	clampi(_characters[p_characterID]._currentHealth, 0, _characters[p_characterID].GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
	if(_characters[p_characterID]._currentHealth <= 0):
		_characters[p_characterID]._currentHealth = 0
		_characters[p_characterID]._active_buffs.clear()
		_characters[p_characterID]._active_debuffs.clear()
		_character_repr[p_characterID].ClearStatusEffects()
		_battle_ui._turn_bar.ShowCharacterAsDead(p_characterID)
		_character_repr[p_characterID]._character_texture.material = GRAYSCALE_MATERIAL
	
	_character_repr[p_characterID]._lifebar.value = _characters[p_characterID]._currentHealth
	_character_repr[p_characterID]._lifebar_text.text = str(_characters[p_characterID]._currentHealth) + "/" + str(_characters[p_characterID].GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)

func VisualizeCharacter(p_characterID: int) -> void:
	_character_repr[p_characterID]._level.text = str(_characters[p_characterID]._level)
	var character_canvas_texture = CanvasTexture.new()
	if(PLAYER_IDS.has(p_characterID)):
		character_canvas_texture.diffuse_texture = main.GetInstance()._character_collection.GetCharacterTexture(_characters[p_characterID]._role)
	else:
		character_canvas_texture.diffuse_texture = load(_characters[p_characterID]._texture)
	if("" != _characters[p_characterID]._normal_map):
		character_canvas_texture.normal_texture = load(_characters[p_characterID]._normal_map)
	_character_repr[p_characterID]._character_texture.texture = character_canvas_texture
	_character_repr[p_characterID]._lifebar.max_value = (_characters[p_characterID].GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
	UpdateLifeBar(p_characterID)
	_character_repr[p_characterID].show()

func ResolveSkill(p_caster_ID: int, p_target_IDs: Array[int], p_skill_ID) -> void:
	var cast_skill: Skill = _characters[p_caster_ID]._skills[p_skill_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = _characters[p_caster_ID].GetBattleAttributes()
	var target_attributes: Dictionary[Types.Attribute, int]
	
	if (not _characters[p_caster_ID]._active_debuffs.is_empty()):
		Skills.TriggerExistingCasterDebuffs(
			_characters[p_caster_ID],
			caster_attributes,
			_character_repr[p_caster_ID])
		UpdateLifeBar(p_caster_ID)
	
	if (not _characters[p_caster_ID]._active_buffs.is_empty()):
		Skills.TriggerCasterBuffs(_characters[p_caster_ID],
		caster_attributes,
		cast_skill,
		p_target_IDs.has(p_caster_ID),
		_character_repr[p_caster_ID])
	
	Skills.ResolveSkillEffect(p_caster_ID, caster_attributes, p_target_IDs, cast_skill, _characters)
	
	for target_ID in p_target_IDs:
		if(p_caster_ID != target_ID):
			target_attributes = _characters[target_ID].GetBattleAttributes()
			Skills.TriggerTargetBuffs(
				_characters[target_ID],
				target_attributes,
				cast_skill,
				_character_repr[target_ID])
			Skills.TriggerTargetDebuffs(
				_characters[target_ID],
				target_attributes,
				cast_skill,
				_character_repr[target_ID])
		
		Skills.PlaceBuff(
			_characters[target_ID],
			cast_skill,
			_character_repr[target_ID])
		
		Skills.PlaceDebuff(
			_characters[target_ID],
			target_attributes,
			caster_attributes[Types.Attribute.Accuracy],
			cast_skill,
			_character_repr[target_ID])
		
		if(not cast_skill.damage_scaling.is_empty()):
			var damage_dealt: int = Skills.DamageDealt(caster_attributes, target_attributes, cast_skill)
			if(damage_dealt != 0):
				_battle_ui.SpawnDamageNumber(damage_dealt, _character_repr[target_ID].position + Vector2(100, 70))
				_characters[target_ID]._currentHealth -= damage_dealt
				UpdateLifeBar(target_ID)
		
		if(0.0 != cast_skill.turn_effect):
			_battle_ui._turn_bar.BumpCharacter(target_ID, cast_skill.turn_effect)
	
	_characters[p_caster_ID]._skills[p_skill_ID].cooldown_left = _characters[p_caster_ID]._skills[p_skill_ID].cooldown
	_battle_ui._turn_bar.TurnCompleteForCharacter(_characterIDs_turn)
	_characterIDs_turn = NO_CHARACTERS_TURN
	_turn_indicator.hide()
	_battle_ui.HideSkillUI()

func IsTheBattleOver() -> WinningTeam:
	var player_alive: bool = false
	var monsters_alive: bool = false
	for character_ID in ENEMY_IDS:
		if(_characters.has(character_ID)):
			if(_characters[character_ID]._currentHealth > 0):
				monsters_alive = true
	for character_ID in PLAYER_IDS:
		if(_characters.has(character_ID)):
			if(_characters[character_ID]._currentHealth > 0):
				player_alive = true
	
	if (false == monsters_alive):
		return WinningTeam.Player_Won
	elif (false == player_alive):
		return WinningTeam.Monsters_Won

	return WinningTeam.Ongoing

func EndBattle(p_winner: WinningTeam) -> void:
	# TODO: implement a more refined experience reward.
	var experience_gained: int = 0
	Skills.Reset()
	_battle_ui.CleanUp()
	
	if(p_winner == WinningTeam.Monsters_Won):
		_self_context._util_text = "Loss"
	elif(p_winner == WinningTeam.Player_Won):
		experience_gained += 5
		_self_context._util_text = "Victory"
	
	for i in _characters.keys():
		if(ENEMY_IDS.has(i) and p_winner == WinningTeam.Player_Won):
			experience_gained += 5
	for i in _characters.keys():
		if(PLAYER_IDS.has(i)):
			LevelSystem.AddExperience(_characters[i], experience_gained)
			_characters[i]._currentHealth = _characters[i]._attributes[Types.Attribute.Health] * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	
	_self_context._scene = "res://Scenes/ui/Battle_Over.tscn"
	
	main.GetInstance().change_scene(_self_context)

func _on_character_battle_target_selected(p_target_ID: int) -> void:
	if(PLAYER_IDS.has(_characterIDs_turn)):
		if(_characters[p_target_ID]._currentHealth <= 0):
			print("Invalid target for skill, target is dead.")
			return
		var target_IDs: Array[int] = Skills.FindSkillTargets(p_target_ID, _characterIDs_turn, _characters[_characterIDs_turn]._skills[_selected_skill_ID])
		if(target_IDs.size() > 0):
			ResolveSkill(_characterIDs_turn, target_IDs, _selected_skill_ID)
			var battle_state = IsTheBattleOver()
			if (WinningTeam.Ongoing != battle_state):
				EndBattle(battle_state)
		else:
			print("Invalid target for skill")

func _on_battle_ui_battle_skill_selected(p_skill_ID: int) -> void:
	if(_characters[_characterIDs_turn]._skills[p_skill_ID].cooldown_left > 0):
		print("Selected skill: ", p_skill_ID, " is on cooldown with: ", _characters[_characterIDs_turn]._skills[p_skill_ID].cooldown_left, " more turns left.")
		return
	_selected_skill_ID = p_skill_ID
	match _characters[_characterIDs_turn]._skills[_selected_skill_ID].target:
		Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.ZoneAll:
			_battle_ui._turn_bar.DisableZones(false)

func _on_turn_bar_zone_selected(p_zone_ID: int) -> void:
	print("_on_turn_bar_zone_selected called with ID: ", p_zone_ID)
	if(_zones.has(p_zone_ID)):
		print("Zone is already used")
		return
	_zones[p_zone_ID] = Zone.new()
	_zones[p_zone_ID].CreateNew(_characters[_characterIDs_turn]._skills[_selected_skill_ID].skill_type,
								_characters[_characterIDs_turn]._skills[_selected_skill_ID].duration,
								_characterIDs_turn,
								_characters[_characterIDs_turn]._skills[_selected_skill_ID].target)
	_battle_ui._turn_bar.SpawnZoneEffect(p_zone_ID, _zones[p_zone_ID]._duration, PLAYER_IDS.has(_zones[p_zone_ID]._owner_ID))
	ResolveSkill(_characterIDs_turn, [], _selected_skill_ID)
	var battle_state = IsTheBattleOver()
	if (WinningTeam.Ongoing != battle_state):
		EndBattle(battle_state)
