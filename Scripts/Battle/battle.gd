class_name Battle extends Node2D

## The battle scene: feeds input into BattleResolver and renders the CombatResult
## records it produces (life bars, combat text, status icons, turn-bar effects).
## Turn flow is an explicit state machine; all combat mutation lives in the resolver.

enum BattleState
{
	Advancing,
	Awaiting_Player_Input,
	Selecting_Zone,
	Selecting_Reagent_Target,
	Selecting_Reagent_Zone,
	Enemy_Acting,
	Resolving,
	Battle_Over,
}

const ZoneType = preload("uid://bdjrfif0s60v4")
const GRAYSCALE = preload("uid://ia57lns0336p")

const NO_CHARACTERS_TURN: int = -1
const ENEMY_ID_OFFSET: int = 3

@export var _character_representations: Array[CharacterRepresentation]

var GRAYSCALE_MATERIAL: ShaderMaterial

var _self_context: ContextContainer
var _battlecontext: Context_Battle
var _resolver: BattleResolver
var _state: BattleState = BattleState.Advancing
var _turn_character_ID: int = -1
var _selected_skill_ID: int = 0
var _initialized: bool = false
var _targeting_order: Array[int]
var _sides: CombatSides
# Maps resolver status-effect IDs to the representation's status-icon IDs.
var _status_visual_IDs: Dictionary[int, int] = {}
var _reagent_loadout: ReagentLoadout
var _selected_reagent_index: int = -1
var _pending_turn_bar_reset: Dictionary[int, float] = {}

@onready var _battle_ui: BattleUI = $"Battle UI"
@onready var _background: TextureRect = %BattleBackground
@onready var _turn_indicator: TextureRect = $Turn_Indicator
@onready var _characters: Dictionary[int, Character]
@onready var _global_scene_darkness: DirectionalLight2D = $DirectionalLight2D
@onready var _global_scene_light: PointLight2D = $PointLight2D

func ApplyAdventureEffects(p_character_ID: int) -> void:
	if _self_context._adventure_state == null:
		return
	for buff_type: Types.Buff_Type in _self_context._adventure_state.active_buffs.keys():
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = buff_type
		buff.duration = GameBalance.ADVENTURE_BUFF_COMBAT_DURATION
		buff.name = Types.Buff_Type.keys()[buff_type]
		_resolver.ApplyBuff(p_character_ID, buff)
	for debuff_type: Types.Debuff_Type in _self_context._adventure_state.active_debuffs.keys():
		var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
		debuff.type = debuff_type
		debuff.duration = GameBalance.ADVENTURE_BUFF_COMBAT_DURATION
		debuff.name = Types.Debuff_Type.keys()[debuff_type]
		_resolver.ApplyDebuff(p_character_ID, debuff)

func SetTargetingOrder() -> void:
	var sorted_keys = _characters.keys()

	sorted_keys.sort_custom(func(key_a, key_b):
		var obj_a = _characters[key_a]
		var obj_b = _characters[key_b]

		var defence_a: float = obj_a.GetTotalAttribute(Types.Attribute.Defence)
		if obj_a._trait != null:
			defence_a *= obj_a._trait.GetTargetingDefenceMultiplier()
		var defence_b: float = obj_b.GetTotalAttribute(Types.Attribute.Defence)
		if obj_b._trait != null:
			defence_b *= obj_b._trait.GetTargetingDefenceMultiplier()

		var sum_a = obj_a.GetTotalAttribute(Types.Attribute.Health) + defence_a
		var sum_b = obj_b.GetTotalAttribute(Types.Attribute.Health) + defence_b

		return sum_a > sum_b
		)
	_targeting_order = sorted_keys

# A reproducible seed for the resolver when the encounter comes from a generated
# adventure (mirroring how adventure generation is seeded); -1 randomizes otherwise.
func BattleSeed() -> int:
	if(_self_context._adventure_state != null and _self_context._adventure_state._generation_seed >= 0):
		return abs(hash([
				_self_context._adventure_state._generation_seed,
				_self_context._adventure_state.current_node_index]))
	return -1

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

	var player_IDs: Array[int] = []
	for i in p_context._player_battle_characters.size():
		player_IDs.append(i)
	var enemy_IDs: Array[int] = []
	for i in _battlecontext._enemies_wave_1.size():
		enemy_IDs.append(ENEMY_ID_OFFSET + i)
	_sides = CombatSides.new(player_IDs, enemy_IDs)

	_resolver = BattleResolver.new(
			_characters, _sides, TurnBarPositions.new(_battle_ui._turn_bar), BattleSeed())
	_resolver.result_produced.connect(_on_resolver_result_produced)

	_reagent_loadout = ReagentLoadout.new(p_context._battle_reagents)

	for i in p_context._player_battle_characters.size():
		_characters[i] = p_context._player_battle_characters[i]
		_characters[i]._current_health = (_characters[i].GetTotalAttribute(Types.Attribute.Health) *
				Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
		_self_context._arguments["character_dmg_" + str(i)] = 0
		VisualizeCharacter(i)
		ApplyAdventureEffects(i)

	var difficulty: int = 1
	if(_self_context._arguments.has("Difficulty")):
		difficulty = _self_context._arguments["Difficulty"]
	else:
		_self_context._arguments["Difficulty"] = difficulty

	for i in _battlecontext._enemies_wave_1.size():
		var enemy_ID: int = ENEMY_ID_OFFSET + i
		_characters[enemy_ID] = Character.new()
		_characters[enemy_ID].InstantiateNew(_battlecontext._enemies_wave_1[i], -1)
		_characters[enemy_ID]._attributes[Types.Attribute.Speed] += _resolver.GetRandom().randi_range(-3, 3)
		var is_boss: bool = p_context._arguments.has("Boss_Scale")
		if (is_boss):
			var boss_scale: float = p_context._arguments["Boss_Scale"]
			_character_representations[enemy_ID].scale = Vector2(boss_scale, boss_scale)
			_character_representations[enemy_ID].position.y -= (
					_character_representations[enemy_ID].position.y * boss_scale) * 0.5
		# One levelling call carrying the boss flag, so the ×1.5 boss multiplier is
		# actually applied instead of being pre-empted by an earlier no-op call.
		LevelSystem.SetOpponentLevel(_characters[enemy_ID], difficulty, is_boss)
		_characters[enemy_ID]._current_health = (_characters[enemy_ID].GetTotalAttribute(Types.Attribute.Health) *
				Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
		VisualizeCharacter(enemy_ID)

	for i in _characters.keys():
		for j in _characters[i]._skills.size():
			_battle_ui.LoadSkillTexture(_characters[i]._skills[j].icon_path)
		if(null != _characters[i]._trait):
			if(_characters[i]._trait._execution_steps.has(Types.Combat_Event.Start_Combat)):
				_characters[i]._trait.StartOfBattle(i, _resolver)
			_characters[i]._trait.RefreshVisuals(_character_representations[i])

	SetTargetingOrder()

	GRAYSCALE_MATERIAL = ShaderMaterial.new()
	GRAYSCALE_MATERIAL.shader = GRAYSCALE

	_battle_ui.Init(_battlecontext._environment_effects)
	_battle_ui._turn_bar.Init(_characters, _on_turn_bar_zone_selected, _sides.player)
	_state = BattleState.Advancing
	_initialized = true

func _process(p_delta: float) -> void:
	if(not _initialized):
		return
	match _state:
		BattleState.Advancing:
			AdvanceTurnBar(p_delta)
		BattleState.Awaiting_Player_Input, BattleState.Selecting_Zone:
			_turn_indicator.position.y = (_character_representations[_turn_character_ID].position.y -
					_turn_indicator.size.y + (sin(Time.get_ticks_msec() * 0.005) * 5))
		_:
			pass

func AdvanceTurnBar(p_delta: float) -> void:
	for character_ID in _characters.keys():
		if(_characters[character_ID]._current_health <= 0):
			continue
		var moved_fraction: float = _battle_ui._turn_bar.Update(p_delta, character_ID)
		if(moved_fraction > 0.0):
			_resolver.AccumulateTurnBarMovement(character_ID, moved_fraction)
		_turn_character_ID = _battle_ui._turn_bar.GetActiveTurnID()
		if(NO_CHARACTERS_TURN != _turn_character_ID):
			StartTurn()
			return

func StartTurn() -> void:
	_turn_indicator.position.x = (_character_representations[_turn_character_ID].position.x +
			(_character_representations[_turn_character_ID]._character_texture.size.x * 0.5) - (_turn_indicator.size.x * 0.5))
	_turn_indicator.position.y = _character_representations[_turn_character_ID].position.y - _turn_indicator.size.y
	_turn_indicator.show()

	_resolver.BeginTurn(_turn_character_ID)
	RefreshAllTraitVisuals()

	if (CheckAndHandleBattleOver()):
		return

	if(IsStunned(_turn_character_ID)):
		_state = BattleState.Resolving
		_resolver.ResolveStunTurn(_turn_character_ID)
		CompleteTurn()
		return

	if(_sides.player.Has(_turn_character_ID)):
		for i in _battle_ui._skill_buttons.size():
			_battle_ui.SetSkill(
				_characters[_turn_character_ID]._skills[i].icon_path,
				_characters[_turn_character_ID]._skills[i].name,
				_characters[_turn_character_ID]._skills[i].description,
				i)
			_battle_ui._skill_buttons[i].show()
			if(_characters[_turn_character_ID]._skills[i].cooldown_left > 0):
				_battle_ui._skill_buttons[i].SetCooldown(_characters[_turn_character_ID]._skills[i].cooldown_left)
			else:
				_battle_ui._skill_buttons[i].ClearCooldown()
		_selected_skill_ID = 0
		_battle_ui.ActiveSkillGlow(_selected_skill_ID)
		for i in mini(_reagent_loadout.Size(), _battle_ui._reagent_buttons.size()):
			var reagent: ReagentData = ReagentRegistry.Get(_reagent_loadout.KeyAt(i))
			_battle_ui.SetReagent(reagent.icon, reagent.display_name, reagent.description, i)
			_battle_ui._reagent_buttons[i].show()
			if(_reagent_loadout.IsSpent(i)):
				_battle_ui._reagent_buttons[i].MarkSpent()
		_state = BattleState.Awaiting_Player_Input
	elif(_sides.enemy.Has(_turn_character_ID)):
		_state = BattleState.Enemy_Acting
		HandleEnemyTurn()

# Reverse-iterates the skills for the first one off cooldown, skipping zone skills
# when no turn-bar zone is free; skill 0 is the fallback.
func SelectEnemySkillID() -> int:
	var skills: Array[Skill] = _characters[_turn_character_ID]._skills
	for i in range(skills.size() - 1, -1, -1):
		if(0 < skills[i].cooldown_left):
			continue
		match skills[i].target:
			Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.ZoneAll:
				if(_resolver.AvailableZoneIDs().is_empty()):
					continue
		return i
	return 0

func HandleEnemyTurn() -> void:
	_selected_skill_ID = SelectEnemySkillID()
	var cast_skill: Skill = _characters[_turn_character_ID]._skills[_selected_skill_ID]

	match cast_skill.target:
		Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.ZoneAll:
			var available_zones: Array[int] = _resolver.AvailableZoneIDs()
			print(_characters[_turn_character_ID]._name, " used skill with ID: ", _selected_skill_ID)
			var zone_ID: int = available_zones[_resolver.GetRandom().randi_range(0, available_zones.size() - 1)]
			_resolver.PlaceZone(zone_ID, _turn_character_ID, cast_skill)
			ResolveTurn([])
		_:
			for i in _targeting_order:
				if(_characters[i]._current_health < 1):
					continue
				var target_IDs: Array[int] = _resolver.FindSkillTargets(i, _turn_character_ID, cast_skill.target)
				if(target_IDs.is_empty()):
					continue  # not a valid target for this caster (e.g. an ally), keep looking
				print(_characters[_turn_character_ID]._name, " used skill with ID: ", _selected_skill_ID)
				ResolveTurn(target_IDs)
				return  # A skill has resolved.

func ResolveTurn(p_target_IDs: Array[int]) -> void:
	_state = BattleState.Resolving
	_resolver.ResolveSkill(_turn_character_ID, p_target_IDs, _selected_skill_ID)
	CompleteTurn()

func IsStunned(p_character_ID: int) -> bool:
	for debuff in _characters[p_character_ID]._active_debuffs:
		if(Types.Debuff_Type.Stun == debuff.type):
			return true
	return false

func CompleteTurn() -> void:
	if(_pending_turn_bar_reset.has(_turn_character_ID)):
		_battle_ui._turn_bar.TurnCompleteForCharacter(_turn_character_ID, _pending_turn_bar_reset[_turn_character_ID])
		_pending_turn_bar_reset.erase(_turn_character_ID)
	else:
		_battle_ui._turn_bar.TurnCompleteForCharacter(_turn_character_ID)
	RefreshAllTraitVisuals()
	_turn_character_ID = NO_CHARACTERS_TURN
	_turn_indicator.hide()
	_battle_ui.HideSkillUI()
	_battle_ui.HideReagentUI()
	if(not CheckAndHandleBattleOver()):
		_state = BattleState.Advancing

func RefreshAllTraitVisuals() -> void:
	for i in _characters.keys():
		if(null != _characters[i]._trait):
			_characters[i]._trait.RefreshVisuals(_character_representations[i])

func CombatTextPosition(p_character_ID: int) -> Vector2:
	return _character_representations[p_character_ID].position + _battle_ui.COMBAT_TEXT_SPAWN_POINT

# Translates one resolver result into visuals (and post-battle damage attribution).
func _on_resolver_result_produced(p_result: CombatResult) -> void:
	match p_result.kind:
		CombatResult.Kind.Damage:
			if(p_result.critical):
				_battle_ui.SpawnCombatText(
						"Critical Strike!", CombatTextPosition(p_result.target_ID), Color(1.0, 0.729, 0.0, 1.0))
			if(p_result.amount > 0):
				_battle_ui.SpawnCombatText(str(p_result.amount), CombatTextPosition(p_result.target_ID))
				AttributeDamage(p_result.source_ID, p_result.amount)
			UpdateLifeBar(p_result.target_ID)
		CombatResult.Kind.Debuff_Tick:
			_battle_ui.SpawnCombatText(
					str(p_result.amount), CombatTextPosition(p_result.target_ID), Color(1.0, 0.45, 0.1, 1.0))
			for source_ID in p_result.amount_by_source.keys():
				AttributeDamage(source_ID, p_result.amount_by_source[source_ID])
			UpdateLifeBar(p_result.target_ID)
		CombatResult.Kind.Debuff_Resisted:
			_battle_ui.SpawnCombatText(
					"Resisted debuff!", CombatTextPosition(p_result.target_ID), Color(0.801, 0.0, 0.0, 1.0))
		CombatResult.Kind.Status_Applied:
			ShowStatusApplied(p_result)
		CombatResult.Kind.Status_Duration:
			if(_status_visual_IDs.has(p_result.status_ID)):
				_character_representations[p_result.target_ID].SetStatusEffectDuration(
						_status_visual_IDs[p_result.status_ID], p_result.duration)
		CombatResult.Kind.Statuses_Removed:
			var repr_effect_IDs: Array[int] = []
			for status_ID in p_result.status_IDs:
				if(_status_visual_IDs.has(status_ID)):
					repr_effect_IDs.append(_status_visual_IDs[status_ID])
					_status_visual_IDs.erase(status_ID)
			_character_representations[p_result.target_ID].RemoveStatusEffects(repr_effect_IDs)
		CombatResult.Kind.Statuses_Cleared:
			_character_representations[p_result.target_ID].ClearAllStatusEffects()
		CombatResult.Kind.Turn_Bar_Bump:
			_battle_ui._turn_bar.BumpCharacter(p_result.target_ID, p_result.fraction)
		CombatResult.Kind.Zone_Placed:
			_battle_ui._turn_bar.SpawnZoneEffect(
					p_result.zone_ID,
					p_result.duration,
					_sides.player.Has(p_result.source_ID),
					p_result.skill_type)
		CombatResult.Kind.Zone_Triggered:
			_battle_ui._turn_bar.ZoneTriggered(p_result.zone_ID, p_result.duration)
		CombatResult.Kind.Zone_Cleared:
			_battle_ui._turn_bar.RemoveZoneEffect(p_result.zone_ID)
		CombatResult.Kind.Turn_Bar_Reset_Pending:
			_pending_turn_bar_reset[p_result.target_ID] = p_result.fraction
		CombatResult.Kind.Heal:
			if(p_result.amount > 0):
				_battle_ui.SpawnCombatText(
						str(p_result.amount), CombatTextPosition(p_result.target_ID), Color(0.2, 0.85, 0.3, 1.0))
			UpdateLifeBar(p_result.target_ID)
		CombatResult.Kind.Trait_Text:
			_battle_ui.SpawnCombatText(p_result.text, CombatTextPosition(p_result.target_ID), p_result.color)
		CombatResult.Kind.Turn_Skipped:
			_battle_ui.SpawnCombatText(
					"Stunned!", CombatTextPosition(p_result.target_ID), Color(0.801, 0.68, 0.0, 1.0))
		CombatResult.Kind.Death:
			_battle_ui._turn_bar.ShowCharacterAsDead(p_result.target_ID)
			_character_representations[p_result.target_ID]._character_texture.material = GRAYSCALE_MATERIAL
			UpdateLifeBar(p_result.target_ID)

# Credits damage to the player who dealt it, for the post-battle totals.
func AttributeDamage(p_source_ID: int, p_amount: int) -> void:
	if(_sides.player.Has(p_source_ID)):
		_self_context._arguments["character_dmg_" + str(p_source_ID)] += p_amount

func ShowStatusApplied(p_result: CombatResult) -> void:
	var texture: Texture
	var text_color: Color
	if(p_result.is_buff):
		texture = StatusEffectRegistry.BuffData(p_result.buff_type).icon
		text_color = Color(0.335, 0.575, 0.838, 1.0)
	else:
		texture = StatusEffectRegistry.DebuffData(p_result.debuff_type).icon
		text_color = Color(0.681, 0.152, 0.31, 1.0)
	_status_visual_IDs[p_result.status_ID] = _character_representations[p_result.target_ID].AddStatusEffect(
			texture, p_result.duration)
	if("" != p_result.text):
		_battle_ui.SpawnCombatText(p_result.text, CombatTextPosition(p_result.target_ID), text_color)

# Display-only: combat mutation (clamping, death handling) happens in the resolver.
func UpdateLifeBar(p_characterID: int) -> void:
	_character_representations[p_characterID]._lifebar.value = _characters[p_characterID]._current_health
	var max_health: int = (_characters[p_characterID].GetTotalAttribute(Types.Attribute.Health) *
			Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
	_character_representations[p_characterID]._lifebar_text.text = (
			str(_characters[p_characterID]._current_health) + "/" + str(max_health))

func VisualizeCharacter(p_characterID: int) -> void:
	_character_representations[p_characterID]._level.text = str(_characters[p_characterID]._level)
	var character_canvas_texture = CanvasTexture.new()
	if(_sides.player.Has(p_characterID)):
		character_canvas_texture.diffuse_texture = (main.GetInstance()._character_collection
				.GetCharacterTexture(_characters[p_characterID]._name))
	else:
		character_canvas_texture.diffuse_texture = load(_characters[p_characterID]._texture)
	if("" != _characters[p_characterID]._normal_map):
		character_canvas_texture.normal_texture = load(_characters[p_characterID]._normal_map)
	_character_representations[p_characterID]._character_texture.texture = character_canvas_texture
	_character_representations[p_characterID]._lifebar.max_value = (
			_characters[p_characterID].GetTotalAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
	UpdateLifeBar(p_characterID)
	_character_representations[p_characterID].show()

func CheckAndHandleBattleOver() -> bool:
	var battle_state: BattleResolver.Winner = _resolver.IsTheBattleOver()
	if (BattleResolver.Winner.Ongoing != battle_state):
		EndBattle(battle_state)
		return true
	return false

func EndBattle(p_winner: BattleResolver.Winner) -> void:
	_state = BattleState.Battle_Over
	_battle_ui.CleanUp()

	if(p_winner == BattleResolver.Winner.Monsters_Won):
		_self_context._arguments["Battle_Result"] = "Loss"
	elif(p_winner == BattleResolver.Winner.Player_Won):
		_self_context._arguments["Battle_Result"] = "Victory"
		_battlecontext._loot_table._budget = LootManager.CalculateBudget(_self_context._arguments["Difficulty"])
		LootManager.DistributeRewards(_battlecontext._loot_table, _self_context._arguments["Difficulty"])
		if (null != _battlecontext._loot_table._drop_result._equipment):
			main.GetInstance()._item_collection.AddPreset(_battlecontext._loot_table._drop_result._equipment)

	for i in _characters.keys():
		if(_sides.player.Has(i)):
			_characters[i]._active_buffs.clear()
			_characters[i]._active_debuffs.clear()
			for j in _characters[i]._skills.size():
				_characters[i]._skills[j].cooldown_left = 0

			if(p_winner == BattleResolver.Winner.Player_Won):
				LevelSystem.AddExperience(_characters[i], _battlecontext._loot_table._drop_result._experience)
			_characters[i]._current_health = (_characters[i].GetTotalAttribute(Types.Attribute.Health) *
				Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)

	_self_context._scene = "uid://d3ooarqabyw0p"

	main.GetInstance().change_scene(_self_context)

func _on_character_battle_target_selected(p_target_ID: int) -> void:
	if(BattleState.Selecting_Reagent_Target == _state):
		_OnReagentTargetSelected(p_target_ID)
		return
	if(BattleState.Awaiting_Player_Input != _state):
		return
	if(_characters[p_target_ID]._current_health <= 0):
		print("Invalid target for skill, target is dead.")
		return
	var target_IDs: Array[int] = _resolver.FindSkillTargets(
			p_target_ID,
			_turn_character_ID,
			_characters[_turn_character_ID]._skills[_selected_skill_ID].target)
	if(target_IDs.size() > 0):
		ResolveTurn(target_IDs)
	else:
		print("Invalid target for skill")

func _OnReagentTargetSelected(p_target_ID: int) -> void:
	if(_characters[p_target_ID]._current_health <= 0):
		print("Invalid target for reagent, target is dead.")
		return
	var reagent: ReagentData = ReagentRegistry.Get(_reagent_loadout.KeyAt(_selected_reagent_index))
	var mapped_target: Types.Skill_Target = (
			Types.Skill_Target.Single_Ally if ReagentData.TargetKind.One_Ally == reagent.target_kind
			else Types.Skill_Target.Single_Enemy)
	var target_IDs: Array[int] = _resolver.FindSkillTargets(p_target_ID, _turn_character_ID, mapped_target)
	if(target_IDs.is_empty()):
		print("Invalid target for reagent")
		return
	_ResolveReagentConsumption(_selected_reagent_index, p_target_ID)

func _on_battle_ui_battle_skill_selected(p_skill_ID: int) -> void:
	if(BattleState.Awaiting_Player_Input != _state and BattleState.Selecting_Zone != _state):
		return
	if(_characters[_turn_character_ID]._skills[p_skill_ID].cooldown_left > 0):
		print("Selected skill: ", p_skill_ID, " is on cooldown with: ",
				_characters[_turn_character_ID]._skills[p_skill_ID].cooldown_left, " more turns left.")
		return
	_selected_skill_ID = p_skill_ID
	match _characters[_turn_character_ID]._skills[_selected_skill_ID].target:
		Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.ZoneAll:
			_state = BattleState.Selecting_Zone
			_battle_ui._turn_bar.DisableZones(false)
		_:
			_state = BattleState.Awaiting_Player_Input
			_battle_ui._turn_bar.DisableZones(true)

func _on_turn_bar_zone_selected(p_zone_ID: int) -> void:
	if(BattleState.Selecting_Reagent_Zone == _state):
		if(not _resolver.HasZone(p_zone_ID)):
			print("No zone to clear there")
			return
		_ResolveReagentConsumption(_selected_reagent_index, p_zone_ID)
		return
	if(_resolver.HasZone(p_zone_ID)):
		print("Zone is already used")
		return
	_resolver.PlaceZone(
			p_zone_ID, _turn_character_ID, _characters[_turn_character_ID]._skills[_selected_skill_ID])
	ResolveTurn([])

func _on_battle_ui_battle_reagent_selected(p_reagent_index: int) -> void:
	if(BattleState.Awaiting_Player_Input != _state):
		return
	if(_reagent_loadout.IsSpent(p_reagent_index)):
		print("Reagent at index ", p_reagent_index, " has already been consumed this battle.")
		return
	var reagent: ReagentData = ReagentRegistry.Get(_reagent_loadout.KeyAt(p_reagent_index))
	_battle_ui.ShowReagentConfirm(p_reagent_index, reagent.display_name, reagent.description)

func _on_battle_ui_reagent_confirmed(p_reagent_index: int) -> void:
	if(BattleState.Awaiting_Player_Input != _state or _reagent_loadout.IsSpent(p_reagent_index)):
		return
	var reagent: ReagentData = ReagentRegistry.Get(_reagent_loadout.KeyAt(p_reagent_index))
	match reagent.target_kind:
		ReagentData.TargetKind.Self_Target:
			_ResolveReagentConsumption(p_reagent_index, _turn_character_ID)
		ReagentData.TargetKind.One_Ally, ReagentData.TargetKind.One_Enemy:
			_selected_reagent_index = p_reagent_index
			_state = BattleState.Selecting_Reagent_Target
		ReagentData.TargetKind.Zone_Section:
			_selected_reagent_index = p_reagent_index
			_state = BattleState.Selecting_Reagent_Zone
			_battle_ui._turn_bar.DisableZones(false)

func _ResolveReagentConsumption(p_reagent_index: int, p_target_ID: int) -> void:
	if(not _reagent_loadout.TryConsume(p_reagent_index, main.GetInstance()._reagent_collection)):
		return
	var reagent: ReagentData = ReagentRegistry.Get(_reagent_loadout.KeyAt(p_reagent_index))
	_resolver.ResolveReagent(_turn_character_ID, _reagent_loadout.KeyAt(p_reagent_index), p_target_ID)
	_battle_ui._reagent_buttons[p_reagent_index].MarkSpent()
	_battle_ui.SpawnCombatText(reagent.display_name, CombatTextPosition(_turn_character_ID), Color(0.6, 0.9, 1.0, 1.0))
	RefreshAllTraitVisuals()
	_selected_reagent_index = -1
	_state = BattleState.Awaiting_Player_Input
	_battle_ui._turn_bar.DisableZones(true)
