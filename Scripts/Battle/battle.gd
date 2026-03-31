class_name Battle extends Node2D

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
var _battlecontext: Context_Battle
var _characterIDs_turn: int = -1
var _selected_skill_ID: int = 0
var _initialized: bool = false
var _zones: Dictionary[int, Zone]
var _targeting_order: Array[int]

enum WinningTeam
{
	Ongoing,
	Player_Won,
	Monsters_Won,
}

func SetTargetingOrder() -> void:
	var sorted_keys = _characters.keys()
	
	sorted_keys.sort_custom(func(key_a, key_b):
		var obj_a = _characters[key_a]
		var obj_b = _characters[key_b]
		
		var sum_a = obj_a._attributes[Types.Attribute.Health] + obj_a._attributes[Types.Attribute.Defence]
		var sum_b = obj_b._attributes[Types.Attribute.Health] + obj_b._attributes[Types.Attribute.Defence]
		
		return sum_a > sum_b
		)
	_targeting_order = sorted_keys

func Init(p_context: ContextContainer) -> void:
	_battlecontext = p_context._static_context as Context_Battle
	_background.texture = load(_battlecontext._location)
	_global_scene_darkness.color = _battlecontext._global_scene_darkness
	_global_scene_darkness.height = _battlecontext._scene_darkness_height
	_global_scene_light.color = _battlecontext._global_scene_light
	_self_context = p_context
	
	if(_battlecontext._enemies_wave_1.is_empty()):
		print("Accidental load to battle scene without enemies, terminating application")
		get_tree().quit()
	elif(p_context._player_battle_characters.is_empty()):
		print("Accidental load to battle scene without player characters, terminating application")
		get_tree().quit()
	
	for i in p_context._player_battle_characters.size():
		_characters[i] = p_context._player_battle_characters[i]
		_characters[i]._currentHealth = _characters[i].GetBattleAttribute(Types.Attribute.Health)  * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
		_self_context._arguments["character_dmg_" + str(i)] = 0
		VisualizeCharacter(i)
	
	var difficulty: int = 1
	if(_self_context._arguments.has("Difficulty")):
		difficulty = _self_context._arguments["Difficulty"]
	else:
		_self_context._arguments["Difficulty"] = difficulty
	
	SetTargetingOrder()
	
	for i in _battlecontext._enemies_wave_1.size():
		_characters[i + 3] = Character.new()
		_characters[i + 3].InstantiateNew(_battlecontext._enemies_wave_1[i], -1)
		_characters[i + 3]._attributes[Types.Attribute.Speed] += randi_range(-3, 3)
		LevelSystem.SetOpponentLevel(_characters[i + 3], difficulty)
		if (p_context._arguments.has("Boss_Scale")):
			_character_repr[i + 3].scale = Vector2(p_context._arguments["Boss_Scale"], p_context._arguments["Boss_Scale"])
			_character_repr[i + 3].position.y -= (_character_repr[i + 3].position.y * p_context._arguments["Boss_Scale"]) * 0.5
			LevelSystem.SetOpponentLevel(_characters[i + 3], difficulty, true)
		else:
			LevelSystem.SetOpponentLevel(_characters[i + 3], difficulty)
		_characters[i + 3]._currentHealth = _characters[i + 3].GetBattleAttribute(Types.Attribute.Health)  * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
		VisualizeCharacter(i + 3)
	
	for i in _characters.keys():
		for j in _characters[i]._skills.size():
			_battle_ui.LoadSkillTexture(_characters[i]._skills[j].icon_path)
		if(null != _characters[i]._trait):
			if(_characters[i]._trait._execution_steps.has(Types.Combat_Event.Start_Combat)):
				_characters[i]._trait.StartOfBattle(_character_repr[i])
	
	GRAYSCALE_MATERIAL = ShaderMaterial.new()
	GRAYSCALE_MATERIAL.shader = GRAYSCALE
	
	_battle_ui.Init(_battlecontext._environment_effects)
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
	
	if (null != _characters[_characterIDs_turn]._trait):
		if(_characters[_characterIDs_turn]._trait._execution_steps.has(Types.Combat_Event.Start_Turn)):
			_characters[_characterIDs_turn]._trait.StartOfTurn(_character_repr[_characterIDs_turn])
	
	if(PLAYER_IDS.has(_characterIDs_turn)):
		for i in _battle_ui._skill_buttons.size():
			_battle_ui.SetSkill(
				_characters[_characterIDs_turn]._skills[i].icon_path,
				_characters[_characterIDs_turn]._skills[i].name,
				_characters[_characterIDs_turn]._skills[i].description,
				i)
			_battle_ui._skill_buttons[i].show()
			if(_characters[_characterIDs_turn]._skills[i].cooldown_left > 0):
				_battle_ui._skill_buttons[i].SetCooldown(_characters[_characterIDs_turn]._skills[i].cooldown_left)
			else:
				_battle_ui._skill_buttons[i].ClearCooldown()
		_selected_skill_ID = 0
		_battle_ui.ActiveSkillGlow(_selected_skill_ID)
	elif(ENEMY_IDS.has(_characterIDs_turn)):
		# TODO: Clean this nested mess up
		# Use skill in reverse order of ID
		for i in _characters[_characterIDs_turn]._skills.size():
			if(0 >= _characters[_characterIDs_turn]._skills[i].cooldown_left):
				match _characters[_characterIDs_turn]._skills[i].target:
					Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.ZoneAll:
						if(GameBalance.NUMBER_OF_TURN_BAR_ZONES <= _zones.size()):
							continue
				_selected_skill_ID = i
		
		match _characters[_characterIDs_turn]._skills[_selected_skill_ID].target:
			Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.ZoneAll:
				var available_zones: Array[int] = []
				for num in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
					if(num not in _zones.keys()):
						available_zones.append(num)
				if(available_zones.is_empty()):
					pass #if no available zones, choose another skill and go again.
				_battle_ui._turn_bar.DisableZones(false)
				print(_characters[_characterIDs_turn]._name, " used skill with ID: ", _selected_skill_ID)
				_on_turn_bar_zone_selected(available_zones.pick_random())
			_:
				for i in _targeting_order:
					if(_characters[i]._currentHealth >= 1):
						var target_IDs: Array[int] = Skills.FindSkillTargets(
							i, _characterIDs_turn, _characters[_characterIDs_turn]._skills[_selected_skill_ID])
						if(target_IDs.size() > 0):
							print(_characters[_characterIDs_turn]._name, " used skill with ID: ", _selected_skill_ID)
							ResolveSkill(_characterIDs_turn, target_IDs, _selected_skill_ID)
							
							var battle_state = IsTheBattleOver()
							if (WinningTeam.Ongoing != battle_state):
								EndBattle(battle_state)
								break
						else:
							print("Invalid target for skill by an enemy! Something is wrong.")
						break # A skill has resolved, break the loop for targeting.

func TriggerZones() -> void:
	for character_ID in _characters.keys():
		if(character_ID == _characterIDs_turn or _characters[character_ID]._currentHealth <= 0):
			continue
		for ID in _zones.keys():
			if(_zones[ID]._duration == 0):
				continue
			if(!_battle_ui._turn_bar.IsCharacterInZone(character_ID, ID)):
				continue
			if(_zones[ID]._target == Types.Skill_Target.ZoneAlly):
				if(PLAYER_IDS.has(character_ID) and ENEMY_IDS.has(_zones[ID]._owner_ID)):
					continue
				if(ENEMY_IDS.has(character_ID) and PLAYER_IDS.has(_zones[ID]._owner_ID)):
					continue
			if(_zones[ID]._target == Types.Skill_Target.ZoneEnemy):
				if(PLAYER_IDS.has(character_ID) and PLAYER_IDS.has(_zones[ID]._owner_ID)):
					continue
				if(ENEMY_IDS.has(character_ID) and ENEMY_IDS.has(_zones[ID]._owner_ID)):
					continue
			Skills.ResolveZoneEffect(
				_zones[ID], _characters[character_ID], character_ID, _battle_ui, _character_repr[character_ID])
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
		_character_repr[p_characterID].ClearAllStatusEffects()
		_battle_ui._turn_bar.ShowCharacterAsDead(p_characterID)
		_character_repr[p_characterID]._character_texture.material = GRAYSCALE_MATERIAL
		if (null != _characters[p_characterID]._trait):
			if(_characters[p_characterID]._trait._execution_steps.has(Types.Combat_Event.On_Death)):
				_characters[p_characterID]._trait.OnDeath(_character_repr[p_characterID])
	
	_character_repr[p_characterID]._lifebar.value = _characters[p_characterID]._currentHealth
	_character_repr[p_characterID]._lifebar_text.text = str(_characters[p_characterID]._currentHealth) + "/" + str(_characters[p_characterID].GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)

func VisualizeCharacter(p_characterID: int) -> void:
	_character_repr[p_characterID]._level.text = str(_characters[p_characterID]._level)
	var character_canvas_texture = CanvasTexture.new()
	if(PLAYER_IDS.has(p_characterID)):
		character_canvas_texture.diffuse_texture = main.GetInstance()._character_collection.GetCharacterTexture(_characters[p_characterID]._name)
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
	
	var trait_result: TraitSkillResult = TraitSkillResult.new()
	if (null != _characters[p_caster_ID]._trait):
		if(_characters[p_caster_ID]._trait._execution_steps.has(Types.Combat_Event.Skill_Cast)):
			trait_result = _characters[p_caster_ID]._trait.OnSkillCast(cast_skill.name, _character_repr[p_caster_ID])
	
	if (not _characters[p_caster_ID]._active_debuffs.is_empty()):
		Skills.TriggerExistingCasterDebuffs(
			_characters[p_caster_ID],
			caster_attributes,
			_character_repr[p_caster_ID])
		UpdateLifeBar(p_caster_ID)
	
	if (not _characters[p_caster_ID]._active_buffs.is_empty()):
		Skills.TriggerExistingCasterBuffs(_characters[p_caster_ID], caster_attributes, _character_repr[p_caster_ID])
	
	Skills.ResolveSkillEffect(p_caster_ID, caster_attributes, cast_skill)
	
	var target_attributes: Dictionary[Types.Attribute, int]
	for target_ID in p_target_IDs:
		if(!_characters.has(target_ID)):
			continue
		if(p_caster_ID != target_ID):
			target_attributes = _characters[target_ID].GetBattleAttributes()
			
			Skills.TriggerTargetBuffs(_characters[target_ID], target_attributes)
			Skills.TriggerTargetDebuffs(_characters[target_ID], target_attributes)
		
		if(not cast_skill.buffs.is_empty() and _characters[target_ID]._currentHealth > 0):
			Skills.CastBuff(_characters[target_ID], cast_skill, _character_repr[target_ID], _battle_ui)
		
		if(not cast_skill.debuffs.is_empty() and _characters[target_ID]._currentHealth > 0):
			Skills.CastDebuff(
				_characters[target_ID],
				target_attributes,
				caster_attributes[Types.Attribute.Accuracy],
				cast_skill,
				_character_repr[target_ID],
				_battle_ui)
		
		if(not cast_skill.damage_scaling.is_empty()):
			var damage_dealt: int = Skills.DamageDealt(
				caster_attributes,
				target_attributes,
				cast_skill,
				trait_result._damage_multiplier,
				_character_repr[target_ID],
				_battle_ui)
			if(damage_dealt != 0):
				if (PLAYER_IDS.has(p_caster_ID)):
					_self_context._arguments["character_dmg_" + str(p_caster_ID)] += damage_dealt
				_battle_ui.SpawnCombatText(str(damage_dealt), _character_repr[target_ID].position + _battle_ui.COMBAT_TEXT_SPAWN_POINT)
				_characters[target_ID]._currentHealth -= damage_dealt
				UpdateLifeBar(target_ID)
				if (null != _characters[target_ID]._trait):
					if(_characters[target_ID]._trait._execution_steps.has(Types.Combat_Event.Damage_Taken)):
						_characters[target_ID]._trait.OnDamageTaken(_character_repr[target_ID])
		
		var total_bump: float = cast_skill.turn_effect + trait_result._turn_bar_bump
		if(0.0 != total_bump):
			_battle_ui._turn_bar.BumpCharacter(target_ID, total_bump)
	
	for i in _characters[_characterIDs_turn]._skills.size():
		if(_characters[_characterIDs_turn]._skills[i].cooldown_left > 0):
			_characters[_characterIDs_turn]._skills[i].cooldown_left -= 1
	_characters[p_caster_ID]._skills[p_skill_ID].cooldown_left = _characters[p_caster_ID]._skills[p_skill_ID].cooldown
	_battle_ui._turn_bar.TurnCompleteForCharacter(_characterIDs_turn)
	TriggerZones()
	if (null != _characters[p_caster_ID]._trait):
		if(_characters[p_caster_ID]._trait._execution_steps.has(Types.Combat_Event.End_Turn)):
			_characters[p_caster_ID]._trait.EndOfTurn(_character_repr[p_caster_ID])
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
	Skills.Reset()
	_battle_ui.CleanUp()
	
	if(p_winner == WinningTeam.Monsters_Won):
		_self_context._arguments["Battle_Result"] = "Loss"
	elif(p_winner == WinningTeam.Player_Won):
		_self_context._arguments["Battle_Result"] = "Victory"
		_battlecontext._loot_table._budget = LootManager.CalculateBudget(_self_context._arguments["Difficulty"])
		LootManager.DistributeRewards(_battlecontext._loot_table, _self_context._arguments["Difficulty"])
		if (null != _battlecontext._loot_table._drop_result._equipment):
			main.GetInstance()._item_collection.AddPreset(_battlecontext._loot_table._drop_result._equipment)
	
	for i in _characters.keys():
		if(PLAYER_IDS.has(i)):
			_characters[i]._active_buffs.clear()
			_characters[i]._active_debuffs.clear()
			for j in _characters[i]._skills.size():
				_characters[i]._skills[j].cooldown_left = 0
				
			if(p_winner == WinningTeam.Player_Won):
				LevelSystem.AddExperience(_characters[i], _battlecontext._loot_table._drop_result._experience)
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
	if(_zones.has(p_zone_ID)):
		print("Zone is already used")
		return
	_zones[p_zone_ID] = Zone.new()
	_zones[p_zone_ID].CreateNew(_characters[_characterIDs_turn]._skills[_selected_skill_ID].skill_type,
								_characters[_characterIDs_turn]._skills[_selected_skill_ID].duration,
								_characterIDs_turn,
								_characters[_characterIDs_turn]._skills[_selected_skill_ID].target)
	_battle_ui._turn_bar.SpawnZoneEffect(
								p_zone_ID,
								_zones[p_zone_ID]._duration,
								PLAYER_IDS.has(_zones[p_zone_ID]._owner_ID),
								_characters[_characterIDs_turn]._skills[_selected_skill_ID].skill_type)
	ResolveSkill(_characterIDs_turn, [], _selected_skill_ID)
	var battle_state = IsTheBattleOver()
	if (WinningTeam.Ongoing != battle_state):
		EndBattle(battle_state)
