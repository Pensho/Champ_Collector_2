class_name PreBattleMenu extends Control

enum Part
{
	Briefing,
	Team,
	Reagents,
}

const MENU_ITEM_SLOT = preload("uid://di0y70sbai3yw")
const DROP_PREVIEW_SLOT_SCENE = preload("res://Scenes/ui/Battle_UI/Drop_Preview_Slot.tscn")

const NR_OF_CHARACTERS_IN_BATTLE: int = 3
const CHARACTER_CHOSEN_COLOR: Color = Color(0.1, 0.1, 0.1)
const CHARACTER_AVAILABLE_COLOR: Color = Color(1,1,1)
const NR_OF_REAGENTS_IN_BATTLE: int = 3
const TAP_MAX_HOLD_MS: int = int(ToolTip.PRESSED_TIME * 1000.0)

@export var _difficulty_option: OptionButton
@export var _chosen_character_slots: Array[MenuItemSlot]
@export var _chosen_reagent_slots: Array[MenuItemSlot]
@export var _grid_container_characters: GridContainer
@export var _grid_container_reagents: GridContainer
@export var _opponent_slots: Array[OpponentPreview]
@export var _h_box_container_drops: HBoxContainer

@export var _part_briefing: Control
@export var _part_team: Control
@export var _part_reagents: Control
@export var _footer: Control
@export var _button_back: Button
@export var _button_next: Button
@export var _button_start: Button

var _chosen_characters: Dictionary[int, Character]
var _character_collection: Array[Character]
var _available_to_chosen_ids: Dictionary[int, int] = {0: -1, 1: -1, 2: -1}
var _available_character_slots: Array[MenuItemSlot]
var _character_collection_size: int

# Reagent selection: chosen slot index -> reagent registry key.
var _chosen_reagents: Dictionary[int, String]
var _available_reagent_slots: Array[MenuItemSlot]
var _displayed_reagent_keys: Array[String]
var _reagent_collection: ReagentCollection

var _self_context: ContextContainer
var _current_part: Part = Part.Briefing
var _press_start_ms: int = -1

func Init(p_context_container: ContextContainer) -> void:
	if(null == p_context_container._static_context):
		print("There is no static context to infer what battle has been chosen.")
		return
	_self_context = p_context_container

	_character_collection_size = main.GetInstance()._character_collection.Size()
	_character_collection = main.GetInstance()._character_collection.GetAllCharacters().values()
	_BuildCharacterGrid()

	for i in _chosen_character_slots.size():
		_chosen_character_slots[i]._ID = i
		_chosen_character_slots[i].ConnectButton(_on_remove_char_button_up)

	_reagent_collection = main.GetInstance()._reagent_collection
	for i in _chosen_reagent_slots.size():
		_chosen_reagent_slots[i]._ID = i
		_chosen_reagent_slots[i].ConnectButton(_on_remove_reagent_button_up)
	RefreshAvailableReagents()

	var encounter_id: String = _self_context._static_context.resource_path
	if _self_context._adventure_state != null:
		_difficulty_option.visible = false
	elif encounter_id.is_empty():
		_difficulty_option.add_item("Difficulty " + str(_self_context._arguments.get("Difficulty", 1)), 1)
		_difficulty_option.select(_difficulty_option.item_count - 1)
		_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()
	else:
		for i in range(1, main.GetInstance()._progress.GetCurrentEncounterDifficulty(encounter_id) + 1):
			_difficulty_option.add_item("Difficulty " + str(i), i)
		_difficulty_option.select(_difficulty_option.item_count - 1)
		_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()

	_BuildBriefing()
	_RefreshDrops()
	_ShowPart(Part.Briefing)

func _BuildBriefing() -> void:
	var battle_context: Context_Battle = _self_context._static_context as Context_Battle
	if(null == battle_context):
		return
	for i in _opponent_slots.size():
		if(i < battle_context._enemies_wave_1.size()):
			_opponent_slots[i].Setup(battle_context._enemies_wave_1[i])
		else:
			_opponent_slots[i].visible = false

func _RefreshDrops() -> void:
	for child in _h_box_container_drops.get_children():
		child.queue_free()

	var battle_context: Context_Battle = _self_context._static_context as Context_Battle
	if(null == battle_context or null == battle_context._loot_table):
		return
	var difficulty: int = int(_self_context._arguments.get("Difficulty", 1))
	for entry in DropPreview.Entries(battle_context._loot_table, difficulty):
		var slot: DropPreviewSlot = DROP_PREVIEW_SLOT_SCENE.instantiate()
		_h_box_container_drops.add_child(slot)
		slot.Setup(entry, _IconForEntry(entry, battle_context._loot_table))

func _IconForEntry(p_entry: Dictionary, p_loot_table: LootTable) -> Texture:
	match p_entry["type"]:
		LootManager.LootType.Silver:
			return ResourceHandler.SILVER_COIN_TEXTURE
		LootManager.LootType.Supplies:
			return ResourceHandler.SUPPLIES_TEXTURE
		LootManager.LootType.Equipment:
			return load(p_loot_table._gear_loot._texture_path) if null != p_loot_table._gear_loot else null
		LootManager.LootType.Fortunes_Favor:
			return _FortuneFavorIcon(p_entry["rarity"])
		_:
			return null

func _FortuneFavorIcon(p_tier: int) -> Texture:
	match p_tier:
		FortuneFavorTier.TierType.BONE:
			return ResourceHandler.FORTUNES_FAVOR_BONE_1
		FortuneFavorTier.TierType.BRASS:
			return ResourceHandler.FORTUNES_FAVOR_BRASS_1
		FortuneFavorTier.TierType.PARCHMENT:
			return ResourceHandler.FORTUNES_FAVOR_PARCHMENT_1
		_:
			return null

func _BuildCharacterGrid() -> void:
	for i in _character_collection_size:
		var slot: MenuItemSlot = MENU_ITEM_SLOT.instantiate()
		_grid_container_characters.add_child(slot)
		slot._ID = i
		slot.ConnectButton(_on_add_char_button_up)
		slot.SetHeldObjectTexture(
				main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[i]._name))
		slot.level.text = str(_character_collection[i]._level)
		_available_character_slots.append(slot)

func _ShowPart(p_part: Part) -> void:
	_current_part = p_part
	_part_briefing.visible = (Part.Briefing == p_part)
	_part_team.visible = (Part.Team == p_part)
	_part_reagents.visible = (Part.Reagents == p_part)
	_footer.visible = (Part.Briefing != p_part)
	if(Part.Briefing == p_part):
		return

	_button_back.visible = true
	var has_reagents: bool = ShouldShowReagentStep(_reagent_collection.GetAllOwned())
	_button_next.visible = (Part.Team == p_part) and has_reagents
	_button_start.visible = (Part.Reagents == p_part) or (Part.Team == p_part and not has_reagents)

static func ShouldShowReagentStep(p_owned: Dictionary) -> bool:
	return not p_owned.is_empty()

func _on_part_briefing_gui_input(event: InputEvent) -> void:
	if(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if(event.pressed):
			_press_start_ms = Time.get_ticks_msec()
		else:
			if(_press_start_ms >= 0 and (Time.get_ticks_msec() - _press_start_ms) < TAP_MAX_HOLD_MS):
				_ShowPart(Part.Team)
			_press_start_ms = -1

func _on_difficulty_option_item_selected(_index: int) -> void:
	_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()
	_RefreshDrops()

func _on_next_button_up() -> void:
	_ShowPart(Part.Reagents)

func _on_back_button_up() -> void:
	if(Part.Reagents == _current_part):
		_ShowPart(Part.Team)
	elif(Part.Team == _current_part):
		_ShowPart(Part.Briefing)

func _on_exit_button_up() -> void:
	_self_context._scene = _self_context._previous_scene
	main.GetInstance().change_scene(_self_context)

func _on_start_button_up() -> void:
	if (_chosen_characters.size() <= 0):
		print("Trying to start a battle without any selected characters.")
		return

	var total: int = int(_self_context._arguments.get("Supply_Cost", GameBalance.ENCOUNTER_BASE_SUPPLY_COST))
	if not main.GetInstance()._resources.SpendSupplies(total):
		print("Not enough supplies to start this encounter.")
		return
	_self_context._arguments["Supply_Cost_Paid"] = total

	if _self_context._adventure_state == null:
		_self_context._arguments["Difficulty"] = _difficulty_option.get_selected_id()
	_self_context._scene = "uid://cc883blynrgq2"
	_self_context._player_battle_characters = _chosen_characters.values()
	_self_context._battle_reagents.assign(_chosen_reagents.values())

	main.GetInstance().change_scene(_self_context)
	hide()

func _on_remove_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.has(p_char_slot)):
		_chosen_characters.erase(p_char_slot)
		_chosen_character_slots[p_char_slot].SetHeldObjectTexture(null)
		_available_character_slots[_available_to_chosen_ids[p_char_slot]].SetHeldObjectModulate(
				CHARACTER_AVAILABLE_COLOR)
	else:
		print("trying to remove a character from an empty slot nr: ", p_char_slot)

func _on_add_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.size() >= NR_OF_CHARACTERS_IN_BATTLE):
		print("Trying to add a character when the roster is full.")
		return
	if (_character_collection.size() <= p_char_slot):
		print("Trying to add a character from an empty slot.")
		return
	for i in _chosen_characters.keys():
		if (_chosen_characters[i]._instance_ID == _character_collection[p_char_slot]._instance_ID):
			print("Trying to add a character already in the chosen roster.")
			return
		if (_chosen_characters[i]._name == _character_collection[p_char_slot]._name):
			print("Trying to add two of the same type of character.")
			return
	for i in NR_OF_CHARACTERS_IN_BATTLE:
		if (!_chosen_characters.has(i)):
			_chosen_characters[i] = _character_collection[p_char_slot]
			_chosen_character_slots[i].SetHeldObjectTexture(
					_available_character_slots[p_char_slot].texture_rect.texture)
			_available_character_slots[p_char_slot].SetHeldObjectModulate(CHARACTER_CHOSEN_COLOR)
			_available_to_chosen_ids[i] = p_char_slot
			return

func RefreshAvailableReagents() -> void:
	for slot in _available_reagent_slots:
		slot.queue_free()
	_available_reagent_slots.clear()
	_displayed_reagent_keys.clear()

	var owned: Dictionary[String, int] = _reagent_collection.GetAllOwned()
	for reagent_key in owned.keys():
		var reagent_data: ReagentData = ReagentRegistry.Get(reagent_key)
		var slot: MenuItemSlot = MENU_ITEM_SLOT.instantiate()
		_grid_container_reagents.add_child(slot)
		slot._ID = _displayed_reagent_keys.size()
		slot.ConnectButton(_on_add_reagent_button_up)
		slot.SetHeldObjectTexture(reagent_data.icon)
		slot.SetTextureOutline(reagent_data.rarity)
		slot.SetToolTip(reagent_data.display_name, reagent_data.description)
		slot.level.text = str(owned[reagent_key])
		_available_reagent_slots.append(slot)
		_displayed_reagent_keys.append(reagent_key)

func RemainingAvailableCount(p_reagent_key: String) -> int:
	var chosen_count: int = 0
	for key in _chosen_reagents.values():
		if (key == p_reagent_key):
			chosen_count += 1
	return _reagent_collection.GetCount(p_reagent_key) - chosen_count

func _on_add_reagent_button_up(p_reagent_slot: int) -> void:
	if (_chosen_reagents.size() >= NR_OF_REAGENTS_IN_BATTLE):
		print("Trying to add a reagent when the loadout is full.")
		return
	if (_displayed_reagent_keys.size() <= p_reagent_slot):
		print("Trying to add a reagent from an empty slot.")
		return
	var reagent_key: String = _displayed_reagent_keys[p_reagent_slot]
	if (RemainingAvailableCount(reagent_key) <= 0):
		print("Trying to add more of a reagent than is owned.")
		return
	var reagent_data: ReagentData = ReagentRegistry.Get(reagent_key)
	for i in NR_OF_REAGENTS_IN_BATTLE:
		if (!_chosen_reagents.has(i)):
			_chosen_reagents[i] = reagent_key
			_chosen_reagent_slots[i].SetHeldObjectTexture(reagent_data.icon)
			_chosen_reagent_slots[i].SetTextureOutline(reagent_data.rarity)
			_chosen_reagent_slots[i].SetToolTip(reagent_data.display_name, reagent_data.description)
			if (RemainingAvailableCount(reagent_key) <= 0):
				_available_reagent_slots[p_reagent_slot].SetHeldObjectModulate(CHARACTER_CHOSEN_COLOR)
			return

func _on_remove_reagent_button_up(p_reagent_slot: int) -> void:
	if (!_chosen_reagents.has(p_reagent_slot)):
		print("trying to remove a reagent from an empty slot nr: ", p_reagent_slot)
		return
	var reagent_key: String = _chosen_reagents[p_reagent_slot]
	_chosen_reagents.erase(p_reagent_slot)
	_chosen_reagent_slots[p_reagent_slot].SetHeldObjectTexture(null)
	_chosen_reagent_slots[p_reagent_slot].ClearToolTip()
	for i in _displayed_reagent_keys.size():
		if (_displayed_reagent_keys[i] == reagent_key):
			_available_reagent_slots[i].SetHeldObjectModulate(CHARACTER_AVAILABLE_COLOR)
			break
