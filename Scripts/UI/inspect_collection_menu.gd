class_name InspectCollectionMenu extends Control

const MENU_ITEM_SLOT = preload("uid://di0y70sbai3yw")
const BUTTON_WITH_OPTIONS_SCENE = preload("uid://c7smqpmfvs0ih")
const ROSTER_SLOT_PLUS_TEXTURE = preload("uid://cavc4wk33n2m")

@export var _attribute_labels: Dictionary[Types.Attribute, Label]
@export var _attribute_renown_labels: Dictionary[Types.Attribute, Label]
@export var _selected_char_label: Label
@export var _selected_char_level: Label
@export var _selected_char_nature: Label
@export var _selected_char_nature_tooltip: ToolTip
@export var _experience_bar: ProgressBar
@export var _experience_bar_text: Label
@export var _skill_rows: Array[SkillListRow]
@export var _passive_row: SkillListRow
@export var v_box_container_equipped_items: VBoxContainer
@export var _tab_bar_collection: TabBar
@export var _characters_panel: ScrollContainer
@export var _scroll_container_items: ScrollContainer
@export var _scroll_container_reagents: ScrollContainer
@export var _grid_container_characters: GridContainer
@export var _button_sort_level: Button
@export var _cancel_sacrifice_button: Button
@export var _grid_container_items: GridContainer
@export var _selected_character_texture: TextureRect
@export var _release_button: Button
@export var _ascend_button: Button
@export var _renown_window: RenownWindow
@export var _buy_roster_slot: MenuItemSlot
@export var _selected_char_renown_pips: Array[TextureRect]
@export var _grid_container_reagents: GridContainer
@export var _tab_bar_gear_skills: TabBar
@export var _gear_tab_nodes: Array[Control]
@export var _skills_panel: Control

var _select_item_option: ButtonWithOptions
var _confirm_option: ButtonWithOptions
var _reagent_select_option: ButtonWithOptions
var _reagent_confirm_option: ButtonWithOptions

var _available_characters: Array[MenuItemSlot] = []
var _available_items: Array[MenuItemSlot] = []
var _item_slots_equipped: Array[MenuItemSlot] = []
var _reagent_slots: Array[MenuItemSlot] = []
var _displayed_item_ids: Array[int] = []
var _displayed_character_ids: Array[int] = []
var _displayed_reagent_keys: Array[String] = []
var _selected_reagent_key: String = ""

var _character_collection: Dictionary[int, Character] = main.GetInstance()._character_collection.GetAllCharacters()
var _item_collection: Dictionary[int, Equipment] = main.GetInstance()._item_collection._items
var _reagent_collection: ReagentCollection = main.GetInstance()._reagent_collection
var _selected_character_ID: int = -1
var _selected_item_slot_ID: int = -1
var _selected_equipped_item_ID: int = -1
var _selected_equipped_slot_type: Types.Slot = Types.Slot.Weapon
var _skills_tab_title: String = ""
var _sort_level_descending: bool = true

var _in_sacrifice_picker: bool = false
var _picker_candidate_ids: Array[int] = []
var _picker_selected_candidate_id: int = -1

@onready var _collection_tab_pages: Array[Control] = [
	_characters_panel,
	_scroll_container_items,
	_scroll_container_reagents,
]

func Init(_p_context_container: ContextContainer) -> void:
	_available_items.resize(_item_collection.size())
	for i in _item_collection.size():
		var item_slot: MenuItemSlot = MENU_ITEM_SLOT.instantiate()
		_grid_container_items.add_child(item_slot)
		_available_items[i] = item_slot
		_available_items[i]._ID = i
		_available_items[i].ConnectButton(AvailableItemButton)
	RefreshDisplayedItems()

	_available_characters.resize(_character_collection.size())
	_displayed_character_ids.resize(_available_characters.size())
	for i in _character_collection.size():
		var character_slot: MenuItemSlot = MENU_ITEM_SLOT.instantiate()
		_grid_container_characters.add_child(character_slot)
		_available_characters[i] = character_slot
		_available_characters[i]._ID = i
		_available_characters[i].ConnectButton(AvailableCharacterButton)
	ApplyCharacterSort()

	_buy_roster_slot.SetHeldObjectTexture(ROSTER_SLOT_PLUS_TEXTURE)
	_buy_roster_slot.ConnectButton(BuyRosterSlotButton)
	_buy_roster_slot.SetToolTip("Expand Roster", "Increase your roster capacity by "
			+ str(Game_Balance.COLLECTION_SIZE_INCREMENT) + " for Silver.")
	_grid_container_characters.move_child(_buy_roster_slot, _grid_container_characters.get_child_count() - 1)

	_item_slots_equipped.append_array(GetMenuItemSlotChildren(v_box_container_equipped_items))
	for i in _item_slots_equipped.size():
		_item_slots_equipped[i]._ID = i
		_item_slots_equipped[i].ConnectButton(EquipedItemSlotButton)
	
	_selected_char_nature_tooltip.title_text = "Character Nature"
	_selected_char_nature_tooltip.description_text = ""

	_skills_tab_title = _tab_bar_gear_skills.get_tab_title(1)
	_tab_bar_gear_skills.remove_tab(1)
	_tab_bar_gear_skills.current_tab = 0

	_select_item_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_select_item_option)
	_select_item_option.SetText("Title", "Body")
	_select_item_option.SetLeftButton("Equip", Callable())
	_select_item_option.position = Vector2i((get_viewport_rect().size * 0.5) - (_select_item_option.GetSize() * 0.5))
	_select_item_option.hide()
	
	_confirm_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_confirm_option)
	_confirm_option.SetText("Title", "Body")
	_confirm_option.SetLeftButton("Equip", Callable())
	_confirm_option.position = Vector2i((get_viewport_rect().size * 0.5) - (_confirm_option.GetSize() * 0.5))
	_confirm_option.hide()

	_reagent_select_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_reagent_select_option)
	_reagent_select_option.SetMiddleButton("Sell", TryReagentSell)
	_reagent_select_option.position = (
			Vector2i((get_viewport_rect().size * 0.5) - (_reagent_select_option.GetSize() * 0.5)))
	_reagent_select_option.hide()

	_reagent_confirm_option = BUTTON_WITH_OPTIONS_SCENE.instantiate()
	add_child(_reagent_confirm_option)
	_reagent_confirm_option.SetLeftButton("Sell", SellReagent, Color(0.863, 0.0, 0.0, 1.0))
	_reagent_confirm_option.position = (
			Vector2i((get_viewport_rect().size * 0.5) - (_reagent_confirm_option.GetSize() * 0.5)))
	_reagent_confirm_option.hide()

	_tab_bar_collection.current_tab = 0
	_on_tab_bar_collection_tab_changed(0)
	RefreshItemGrid()

func RefreshDisplayedItems() -> void:
	_displayed_item_ids.clear()
	for item_id in _item_collection.keys():
		if main.GetInstance()._item_collection.UNEQUIPPED == _item_collection[item_id]._held_by:
			_displayed_item_ids.append(item_id)

func GetMenuItemSlotChildren(p_start_node: Node) -> Array[MenuItemSlot]:
	var result: Array[MenuItemSlot] = []
	for child in p_start_node.get_children():
		if child is MenuItemSlot:
			result.append(child)
		result += GetMenuItemSlotChildren(child)
	return result

func ShowSelectedCharacter(p_instance_ID: int) -> void:
	_selected_character_texture.texture = main.GetInstance()._character_collection.GetCharacterTexture(
			_character_collection[p_instance_ID]._name)
	var character: Character = _character_collection[p_instance_ID]
	for attr in _attribute_labels.keys():
		var total_attribute: int = character.GetBaseAttributes()[attr] + character.GetEquipmentBonus(attr)
		if(Types.Attribute.Health == attr):
			_attribute_labels[attr].text = str(total_attribute * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
		elif(Types.Attribute.CritChance == attr):
			_attribute_labels[attr].text = str(total_attribute) + "%"
		elif(Types.Attribute.CritDamage == attr):
			_attribute_labels[attr].text = str(total_attribute) + "%"
		else:
			_attribute_labels[attr].text = str(total_attribute)
		var renown_percent: int = character.GetRenownPercentBonus(attr)
		_attribute_renown_labels[attr].text = "+" + str(renown_percent) + "%" if renown_percent > 0 else ""
	_selected_char_label.text = _character_collection[p_instance_ID]._name
	_selected_char_level.text = "Level: " + str(_character_collection[p_instance_ID]._level)
	UpdateSelectedCharacterRenownPips(_character_collection[p_instance_ID].GetRenownRank())
	_ascend_button.disabled = not _character_collection[p_instance_ID].CanGainRenown()
	_selected_char_nature.text = "Nature: " + str(_character_collection[p_instance_ID]._attributes_weights._name)
	_selected_char_nature_tooltip.title_text = str(
			_character_collection[p_instance_ID]._attributes_weights._name) + " Nature"
	_selected_char_nature_tooltip.description_text = str(
			_character_collection[p_instance_ID]._attributes_weights._description)

	_experience_bar.max_value = LevelSystem.GetExperienceRequirement(_character_collection[p_instance_ID]._level)
	_experience_bar.value = _character_collection[p_instance_ID]._experience
	_experience_bar_text.text = "experience: " + (str(_character_collection[p_instance_ID]._experience)
			+ " / " + str(int(_experience_bar.max_value)))
	
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Weapon)):
		var weapon_ID: int = _character_collection[p_instance_ID]._held_items[Types.Slot.Weapon]
		_item_slots_equipped[0].SetHeldObjectTexture(
				main.GetInstance()._item_collection.GetItemTexture(weapon_ID))
		_item_slots_equipped[0].SetTextureOutline(_item_collection[weapon_ID]._rarity)
		_item_slots_equipped[0].level.text = str(_item_collection[weapon_ID]._level)
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.OffHand)):
		var off_hand_ID: int = _character_collection[p_instance_ID]._held_items[Types.Slot.OffHand]
		_item_slots_equipped[1].SetHeldObjectTexture(
				main.GetInstance()._item_collection.GetItemTexture(off_hand_ID))
		_item_slots_equipped[1].SetTextureOutline(_item_collection[off_hand_ID]._rarity)
		_item_slots_equipped[1].level.text = str(_item_collection[off_hand_ID]._level)
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Boots)):
		var boots_ID: int = _character_collection[p_instance_ID]._held_items[Types.Slot.Boots]
		_item_slots_equipped[2].SetHeldObjectTexture(
				main.GetInstance()._item_collection.GetItemTexture(boots_ID))
		_item_slots_equipped[2].SetTextureOutline(_item_collection[boots_ID]._rarity)
		_item_slots_equipped[2].level.text = str(_item_collection[boots_ID]._level)

	if(1 == _tab_bar_gear_skills.tab_count):
		_tab_bar_gear_skills.add_tab(_skills_tab_title)
	RefreshSkillsTab(p_instance_ID)

func UpdateSelectedCharacterRenownPips(p_rank: int) -> void:
	for i in _selected_char_renown_pips.size():
		_selected_char_renown_pips[i].texture = (
				MenuItemSlot.PIP_FILLED_TEXTURE if i < p_rank else MenuItemSlot.PIP_EMPTY_TEXTURE)

func RefreshSkillsTab(p_instance_ID: int) -> void:
	var character: Character = _character_collection[p_instance_ID]
	for i in _skill_rows.size():
		if(i < character._skills.size()):
			_skill_rows[i].SetSkill(character._skills[i])
			_skill_rows[i].show()
		else:
			_skill_rows[i].hide()

	if(null != character._trait):
		_passive_row.SetPassive(character._trait, SkillListRow.PassiveLabel(character))
		_passive_row.show()
	else:
		_passive_row.hide()

func _on_tab_bar_gear_skills_tab_changed(p_tab: int) -> void:
	for node in _gear_tab_nodes:
		node.visible = (0 == p_tab)
	_skills_panel.visible = (1 == p_tab)

func _on_tab_bar_collection_tab_changed(p_tab: int) -> void:
	for i in _collection_tab_pages.size():
		_collection_tab_pages[i].visible = (i == p_tab)
	if(2 == p_tab):
		RefreshReagentGrid()

func RefreshItemGrid() -> void:
	for slot in _available_items.size():
		if slot < _displayed_item_ids.size():
			var item_id: int = _displayed_item_ids[slot]
			_available_items[slot].show()
			_available_items[slot].SetHeldObjectTexture(
					main.GetInstance()._item_collection.GetItemTexture(item_id))
			_available_items[slot].SetTextureOutline(_item_collection[item_id]._rarity)
			_available_items[slot].level.text = str(_item_collection[item_id]._level)
		else:
			_available_items[slot].SetHeldObjectTexture(null)
			_available_items[slot].level.text = ""
			_available_items[slot].hide()

static func SortCharacterIDsByLevel(
		p_collection: Dictionary[int, Character],
		p_character_ids: Array[int],
		p_descending: bool) -> Array[int]:
	var sorted_ids: Array[int] = p_character_ids.duplicate()
	sorted_ids.sort_custom(func(a: int, b: int) -> bool:
		if p_collection[a]._level != p_collection[b]._level:
			if p_descending:
				return p_collection[a]._level > p_collection[b]._level
			return p_collection[a]._level < p_collection[b]._level
		return a < b)
	return sorted_ids

static func GetDuplicateCandidateIDs(
		p_collection: Dictionary[int, Character], p_character_id: int) -> Array[int]:
	var character_name: String = p_collection[p_character_id]._name
	var candidate_ids: Array[int] = []
	for id: int in p_collection.keys():
		if id != p_character_id and p_collection[id]._name == character_name:
			candidate_ids.append(id)
	candidate_ids.sort()
	return candidate_ids

static func CanReleaseCharacter(p_collection: Dictionary[int, Character], p_character_id: int) -> bool:
	return -1 != p_character_id and p_collection.has(p_character_id) and p_collection.size() > 1

func ApplyCharacterSort() -> void:
	_displayed_character_ids = SortCharacterIDsByLevel(
			_character_collection, _character_collection.keys(), _sort_level_descending)
	_button_sort_level.text = "Level ↓" if _sort_level_descending else "Level ↑"
	RefreshCharacterGrid()

static func GetSlotModulate(p_slot_character_id: int, p_selected_character_id: int) -> Color:
	if(p_slot_character_id == p_selected_character_id):
		return Color(0.45, 0.45, 0.45, 1.0)
	return Color(1.0, 1.0, 1.0, 1.0)

func RefreshCharacterGrid() -> void:
	for slot_nr in _available_characters.size():
		if(slot_nr < _displayed_character_ids.size()):
			_available_characters[slot_nr].show()
			_available_characters[slot_nr].SetHeldObjectTexture(
					main.GetInstance()._character_collection.GetCharacterTexture(
						_character_collection[_displayed_character_ids[slot_nr]]._name))
			_available_characters[slot_nr].SetTextureOutline(
					_character_collection[_displayed_character_ids[slot_nr]]._rarity)
			_available_characters[slot_nr].level.text = str(
					_character_collection[_displayed_character_ids[slot_nr]]._level)
			_available_characters[slot_nr].SetRenownRank(
					_character_collection[_displayed_character_ids[slot_nr]].GetRenownRank())
			_available_characters[slot_nr].SetHeldObjectModulate(
					GetSlotModulate(_displayed_character_ids[slot_nr], _selected_character_ID))
		else:
			_available_characters[slot_nr].SetHeldObjectTexture(null)
			_available_characters[slot_nr].level.text = ""
			_available_characters[slot_nr].ClearRenownPips()
			_available_characters[slot_nr].hide()

func _on_button_sort_level_button_up() -> void:
	_sort_level_descending = not _sort_level_descending
	ApplyCharacterSort()

func CanEquipFromMenuID(p_instance_ID: int) -> bool:
	var selected_item_type: Types.Slot = _item_collection[p_instance_ID]._slot
	return not _character_collection[_selected_character_ID]._held_items.has(selected_item_type)

func GetItemDescriptionText(p_item: Equipment, p_compare_item: Equipment = null) -> String:
	var description_text: String = ""
	if(null != p_compare_item):
		var differing_value: int = 0
		for type in p_item._attributes.keys():
			differing_value = p_item._attributes[type] - p_compare_item._attributes[type]
			if(0 < differing_value):
				description_text += Types.Attribute.keys()[type] + " +" + str(differing_value) + "\n"
			elif(0 > differing_value):
				description_text += Types.Attribute.keys()[type] + " -" + str(differing_value) + "\n"
	else:
		return Equipment.DescriptionText(p_item._slot, p_item._attributes, p_item._relic_effect)

	if(null != p_item._relic_effect):
		description_text += "\n" + p_item._relic_effect._body
	return description_text

func AvailableItemButton(p_slot_ID: int) -> void:
	var item: Equipment = _item_collection[_displayed_item_ids[p_slot_ID]]
	var compare_item: Equipment = null
	if(-1 != _selected_character_ID and _character_collection[_selected_character_ID]._held_items.has(item._slot)):
		compare_item = _item_collection[_character_collection[_selected_character_ID]._held_items[item._slot]]

	_select_item_option.SetText(item._name, GetItemDescriptionText(item, compare_item))
	if(-1 != _selected_character_ID):
		_select_item_option.SetLeftButton("Equip", TriggerEquipItem)
	else:
		_select_item_option.HideLeftButton()
	_select_item_option.SetMiddleButton("Sell", TrySell)
	_select_item_option.SetUpgradeButton("Upgrade", TryUpgrade)
	_select_item_option.show()
	_selected_item_slot_ID = p_slot_ID
	_selected_equipped_item_ID = -1

func TrySell() -> void:
	var sell_value: int = LootManager.GetSellValue(_item_collection[_displayed_item_ids[_selected_item_slot_ID]]._rarity)
	_confirm_option.SetText(
			"Sell", "Are you sure you want to sell this item? You will gain " + str(sell_value) + " silver.")
	_confirm_option.SetLeftButton("Sell", SellItem, Color(0.863, 0.0, 0.0, 1.0))
	_confirm_option.show()

func SellItem() -> void:
	var item_id: int = _displayed_item_ids[_selected_item_slot_ID]
	main.GetInstance()._resources._silver += LootManager.GetSellValue(_item_collection[item_id]._rarity)
	main.GetInstance()._item_collection.Remove(item_id)
	RefreshDisplayedItems()
	RefreshItemGrid()
	_confirm_option.hide()
	_select_item_option.hide()

func _on_button_release_button_up() -> void:
	TryRelease()

func TryRelease() -> void:
	if(not CanReleaseCharacter(_character_collection, _selected_character_ID)):
		return
	var character: Character = _character_collection[_selected_character_ID]
	var payout: Dictionary = LootManager.GetReleaseValue(character._rarity, character._level)
	_confirm_option.SetText(
			"Release", "Are you sure you want to release this champion? You will gain "
			+ str(payout["silver"]) + " silver, " + str(payout["supplies"]) + " supplies, and "
			+ str(payout["tallies"]) + " tallies.")
	_confirm_option.SetLeftButton("Release", ReleaseCharacter, Color(0.863, 0.0, 0.0, 1.0))
	_confirm_option.show()

func ReleaseCharacter() -> void:
	var character: Character = _character_collection[_selected_character_ID]
	var payout: Dictionary = LootManager.GetReleaseValue(character._rarity, character._level)
	main.GetInstance()._resources.AddSilver(payout["silver"])
	main.GetInstance()._resources.AddSupplies(payout["supplies"])
	main.GetInstance()._resources.AddTallies(payout["tallies"])

	main.GetInstance()._item_collection.UnequipAllHeldItems(character)
	main.GetInstance()._character_collection.Remove(_selected_character_ID)
	_character_collection.erase(_selected_character_ID)
	RefreshDisplayedItems()

	_confirm_option.hide()
	ApplyCharacterSort()
	_on_button_deselect_char_button_up()

func _on_button_ascend_button_up() -> void:
	TryAscend()

func TryAscend() -> void:
	if(-1 == _selected_character_ID):
		return
	if(GetDuplicateCandidateIDs(_character_collection, _selected_character_ID).is_empty()):
		_confirm_option.SetText("Ascend", "You need a duplicate of this champion to Ascend.")
		_confirm_option.HideLeftButton()
		_confirm_option.show()
		return
	EnterSacrificePicker()

func EnterSacrificePicker() -> void:
	_picker_candidate_ids = GetDuplicateCandidateIDs(_character_collection, _selected_character_ID)
	_in_sacrifice_picker = true
	for slot: MenuItemSlot in _available_characters:
		slot.ConnectButton(SacrificeCharacterButton)
	_cancel_sacrifice_button.show()
	_buy_roster_slot.hide()
	_tab_bar_collection.set_tab_disabled(1, true)
	_tab_bar_collection.set_tab_disabled(2, true)
	_tab_bar_collection.current_tab = 0
	_on_tab_bar_collection_tab_changed(0)
	RefreshSacrificeGrid()

func RefreshSacrificeGrid() -> void:
	for slot_nr in _available_characters.size():
		if(slot_nr < _picker_candidate_ids.size()):
			var candidate_id: int = _picker_candidate_ids[slot_nr]
			_available_characters[slot_nr].show()
			_available_characters[slot_nr].SetHeldObjectTexture(
					main.GetInstance()._character_collection.GetCharacterTexture(
						_character_collection[candidate_id]._name))
			_available_characters[slot_nr].SetTextureOutline(_character_collection[candidate_id]._rarity)
			_available_characters[slot_nr].level.text = str(_character_collection[candidate_id]._level)
			_available_characters[slot_nr].SetRenownRank(_character_collection[candidate_id].GetRenownRank())
			_available_characters[slot_nr].SetHeldObjectModulate(Color(1.0, 1.0, 1.0, 1.0))
		else:
			_available_characters[slot_nr].SetHeldObjectTexture(null)
			_available_characters[slot_nr].level.text = ""
			_available_characters[slot_nr].ClearRenownPips()
			_available_characters[slot_nr].hide()

func SacrificeCharacterButton(p_slot_ID: int) -> void:
	_picker_selected_candidate_id = _picker_candidate_ids[p_slot_ID]
	var candidate: Character = _character_collection[_picker_selected_candidate_id]
	_confirm_option.SetText(
			"Ascend", "Ascend using " + candidate._name + " (Level " + str(candidate._level) + ", "
			+ str(candidate._attributes_weights._name) + " Nature)? It is spent once you choose the bonus.")
	_confirm_option.SetLeftButton("Continue", OpenRenownWindow)
	_confirm_option.show()

func OpenRenownWindow() -> void:
	_confirm_option.hide()
	ExitSacrificePicker()
	_renown_window.Refresh(_character_collection[_selected_character_ID])
	_renown_window.show()

func ConsumeSacrificeCandidate() -> void:
	var candidate: Character = _character_collection[_picker_selected_candidate_id]
	main.GetInstance()._item_collection.UnequipAllHeldItems(candidate)
	main.GetInstance()._character_collection.Remove(_picker_selected_candidate_id)
	_character_collection.erase(_picker_selected_candidate_id)
	_picker_selected_candidate_id = -1
	RefreshDisplayedItems()
	ApplyCharacterSort()

func _on_renown_window_attribute_selected(p_attribute: Types.Attribute) -> void:
	_character_collection[_selected_character_ID].AddRenown(p_attribute)
	ConsumeSacrificeCandidate()
	_renown_window.hide()
	ShowSelectedCharacter(_selected_character_ID)

func _on_renown_window_cancelled() -> void:
	_picker_selected_candidate_id = -1
	_renown_window.hide()
	ShowSelectedCharacter(_selected_character_ID)

func ExitSacrificePicker() -> void:
	_in_sacrifice_picker = false
	_cancel_sacrifice_button.hide()
	_buy_roster_slot.show()
	for slot: MenuItemSlot in _available_characters:
		slot.ConnectButton(AvailableCharacterButton)
	_tab_bar_collection.set_tab_disabled(1, false)
	_tab_bar_collection.set_tab_disabled(2, false)
	ApplyCharacterSort()
	RefreshItemGrid()
	ShowSelectedCharacter(_selected_character_ID)

func _on_button_cancel_sacrifice_button_up() -> void:
	ExitSacrificePicker()

func GetSelectedItemID() -> int:
	if(-1 != _selected_equipped_item_ID):
		return _selected_equipped_item_ID
	return _displayed_item_ids[_selected_item_slot_ID]

func TryUpgrade() -> void:
	var item: Equipment = _item_collection[GetSelectedItemID()]
	if(not item.CanUpgrade()):
		_confirm_option.SetText("Upgrade", "This item is already at maximum level.")
		_confirm_option.HideLeftButton()
		_confirm_option.show()
		return

	var cost: int = LootManager.GetUpgradeCost(item._rarity, item._level)
	_confirm_option.SetText("Upgrade", "Upgrade to level " + str(item._level + 1) + " for " + str(cost) + " silver.")
	_confirm_option.SetLeftButton("Upgrade", UpgradeItem)
	_confirm_option.show()

func UpgradeItem() -> void:
	var item: Equipment = _item_collection[GetSelectedItemID()]
	if(not item.CanUpgrade()):
		return

	var cost: int = LootManager.GetUpgradeCost(item._rarity, item._level)
	if(not main.GetInstance()._resources.SpendSilver(cost)):
		return

	item.Upgrade()
	if(-1 != _selected_item_slot_ID):
		_available_items[_selected_item_slot_ID].level.text = str(item._level)
	if(-1 != _selected_character_ID):
		ShowSelectedCharacter(_selected_character_ID)
	_confirm_option.hide()
	_select_item_option.hide()

func RefreshReagentGrid() -> void:
	for slot in _reagent_slots:
		slot.queue_free()
	_reagent_slots.clear()
	_displayed_reagent_keys.clear()

	var owned: Dictionary[String, int] = _reagent_collection.GetAllOwned()
	for reagent_key in owned.keys():
		var reagent_data: ReagentData = ReagentRegistry.Get(reagent_key)
		var slot: MenuItemSlot = MENU_ITEM_SLOT.instantiate()
		_grid_container_reagents.add_child(slot)
		slot._ID = _displayed_reagent_keys.size()
		slot.ConnectButton(ReagentSlotButton)
		slot.SetHeldObjectTexture(reagent_data.icon)
		slot.SetTextureOutline(reagent_data.rarity)
		slot.level.text = str(owned[reagent_key])
		_reagent_slots.append(slot)
		_displayed_reagent_keys.append(reagent_key)

func ReagentSlotButton(p_slot_ID: int) -> void:
	_selected_reagent_key = _displayed_reagent_keys[p_slot_ID]
	var reagent_data: ReagentData = ReagentRegistry.Get(_selected_reagent_key)
	_reagent_select_option.SetText(reagent_data.display_name, reagent_data.description)
	_reagent_select_option.show()

func TryReagentSell() -> void:
	var reagent_data: ReagentData = ReagentRegistry.Get(_selected_reagent_key)
	var sell_value: int = LootManager.GetReagentSellValue(reagent_data.rarity)
	_reagent_confirm_option.SetText(
			"Sell", "Are you sure you want to sell this reagent? You will gain " + str(sell_value) + " silver.")
	_reagent_confirm_option.show()

func SellReagent() -> void:
	var reagent_data: ReagentData = ReagentRegistry.Get(_selected_reagent_key)
	main.GetInstance()._resources.AddSilver(LootManager.GetReagentSellValue(reagent_data.rarity))
	_reagent_collection.Consume(_selected_reagent_key)
	RefreshReagentGrid()
	_reagent_confirm_option.hide()
	_reagent_select_option.hide()

func BuyRosterSlotButton(_p_slot_ID: int) -> void:
	TryBuyRosterSlot()

func TryBuyRosterSlot() -> void:
	var collection: CharacterCollection = main.GetInstance()._character_collection
	if(collection.IsRosterAtMaxSize()):
		_confirm_option.SetText("Expand Roster", "Your roster is already at its maximum capacity.")
		_confirm_option.HideLeftButton()
		_confirm_option.show()
		return

	var price: int = CharacterCollection.GetRosterSlotPrice(collection._current_max_amount)
	_confirm_option.SetText(
			"Expand Roster", "Increase your roster capacity by "
			+ str(Game_Balance.COLLECTION_SIZE_INCREMENT) + " for " + str(price) + " silver?")
	_confirm_option.SetLeftButton("Buy", BuyRosterSlot)
	_confirm_option.show()

func BuyRosterSlot() -> void:
	var collection: CharacterCollection = main.GetInstance()._character_collection
	var price: int = CharacterCollection.GetRosterSlotPrice(collection._current_max_amount)
	if(main.GetInstance()._resources.SpendSilver(price)):
		collection.IncreaseCollectionSize()
	_confirm_option.hide()

func AvailableCharacterButton(p_slot_ID: int) -> void:
	_selected_character_ID = _displayed_character_ids[p_slot_ID]
	ShowSelectedCharacter(_displayed_character_ids[p_slot_ID])
	RefreshCharacterGrid()
	RefreshItemGrid()
	_release_button.show()
	_ascend_button.show()

func TriggerEquipItem() -> void:
	var item_id: int = _displayed_item_ids[_selected_item_slot_ID]

	var slot_type: Types.Slot = _item_collection[item_id]._slot
	if(_character_collection[_selected_character_ID]._held_items.has(slot_type)):
		TriggerUnequipItem(slot_type)

	_character_collection[_selected_character_ID].EquipItem(item_id)
	main.GetInstance()._item_collection.EquipCollectionItem(item_id)
	RefreshDisplayedItems()
	RefreshItemGrid()
	ShowSelectedCharacter(_selected_character_ID)
	_selected_item_slot_ID = -1
	_select_item_option.hide()

func TriggerUnequipItem(p_item_type: Types.Slot) -> void:
	var held_item_ID: int = _character_collection[_selected_character_ID]._held_items[p_item_type]

	match p_item_type:
		Types.Slot.Weapon:
			_item_slots_equipped[0].SetHeldObjectTexture(null)
			_item_slots_equipped[0].level.text = ""
		Types.Slot.OffHand:
			_item_slots_equipped[1].SetHeldObjectTexture(null)
			_item_slots_equipped[1].level.text = ""
		Types.Slot.Boots:
			_item_slots_equipped[2].SetHeldObjectTexture(null)
			_item_slots_equipped[2].level.text = ""

	main.GetInstance()._item_collection.UnequipCollectionItem(held_item_ID)
	_character_collection[_selected_character_ID].UnequipItem(p_item_type)

	RefreshDisplayedItems()
	RefreshItemGrid()
	ShowSelectedCharacter(_selected_character_ID)

func EquipedItemSlotButton(p_slot_ID: int) -> void:
	if _selected_character_ID == -1:
		return
	var slot_type: Types.Slot
	match p_slot_ID:
		0: slot_type = Types.Slot.Weapon
		1: slot_type = Types.Slot.OffHand
		2: slot_type = Types.Slot.Boots
	if(not _character_collection[_selected_character_ID]._held_items.has(slot_type)):
		return

	var item_id: int = _character_collection[_selected_character_ID]._held_items[slot_type]
	var item: Equipment = _item_collection[item_id]
	_selected_equipped_item_ID = item_id
	_selected_equipped_slot_type = slot_type
	_selected_item_slot_ID = -1

	_select_item_option.SetText(item._name, GetItemDescriptionText(item))
	_select_item_option.SetLeftButton("Unequip", TriggerUnequipSelectedItem)
	_select_item_option.HideMiddleButton()
	_select_item_option.SetUpgradeButton("Upgrade", TryUpgrade)
	_select_item_option.show()

func TriggerUnequipSelectedItem() -> void:
	TriggerUnequipItem(_selected_equipped_slot_type)
	_selected_equipped_item_ID = -1
	_select_item_option.hide()

func _on_button_deselect_char_button_up() -> void:
	if(_renown_window.visible):
		return
	if(_in_sacrifice_picker):
		ExitSacrificePicker()
	_selected_character_texture.texture = null
	for attr in _attribute_labels.keys():
		_attribute_labels[attr].text = "0"
		_attribute_renown_labels[attr].text = ""
	_selected_char_label.text = ""
	_selected_char_level.text = ""
	UpdateSelectedCharacterRenownPips(0)
	_selected_char_nature.text = "Nature: "
	_selected_char_nature_tooltip.title_text = "Character Nature"
	_selected_char_nature_tooltip.description_text = ""
	_experience_bar.max_value = 100.0
	_experience_bar.value = 0.0
	_experience_bar_text.text = ""
	if(1 < _tab_bar_gear_skills.tab_count):
		_tab_bar_gear_skills.remove_tab(1)
	_tab_bar_gear_skills.current_tab = 0
	_on_tab_bar_gear_skills_tab_changed(0)
	for i in _item_slots_equipped.size():
		_item_slots_equipped[i].SetHeldObjectTexture(null)
		_item_slots_equipped[i].level.text = ""
	_selected_character_ID = -1
	_release_button.hide()
	_ascend_button.hide()
	RefreshCharacterGrid()

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)
