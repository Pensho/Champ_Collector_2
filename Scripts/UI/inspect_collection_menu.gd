class_name InspectCollectionMenu extends Control

const MENU_ITEM_SLOT = preload("uid://di0y70sbai3yw")
const BUTTON_WITH_OPTIONS_SCENE = preload("uid://c7smqpmfvs0ih")

@export var _attribute_labels: Dictionary[Types.Attribute, Label]
@export var _selected_char_label: Label
@export var _selected_char_level: Label
@export var _selected_char_nature: Label
@export var _selected_char_nature_tooltip: ToolTip
@export var _experience_bar: ProgressBar
@export var _experience_bar_text: Label

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

@onready var v_box_container_equipped_items: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer2

@onready var _scroll_container_characters: ScrollContainer = $MarginContainer/HBoxContainer2/ScrollContainer_Characters
@onready var _scroll_container_items: ScrollContainer = $MarginContainer/HBoxContainer2/ScrollContainer_Items
@onready var _grid_container_characters: GridContainer = (
		$MarginContainer/HBoxContainer2/ScrollContainer_Characters/GridContainer)
@onready var _grid_container_items: GridContainer = $MarginContainer/HBoxContainer2/ScrollContainer_Items/GridContainer
@onready var _selected_character_texture: TextureRect = $MarginContainer/ColorRect2/TextureRect
@onready var _reagent_window: Control = $ReagentWindow
@onready var _grid_container_reagents: GridContainer = (
		$ReagentWindow/ColorRect/MarginContainer/VBoxContainer/ScrollContainer/GridContainer)

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
		
		_displayed_character_ids[i] = _character_collection.keys()[i]
		_available_characters[i].SetHeldObjectTexture(
					main.GetInstance()._character_collection.GetCharacterTexture(
						_character_collection[_displayed_character_ids[i]]._name))
		_available_characters[i].level.text = str(_character_collection[_displayed_character_ids[i]]._level)
	
	_item_slots_equipped.append_array(GetMenuItemSlotChildren(v_box_container_equipped_items))
	for i in _item_slots_equipped.size():
		_item_slots_equipped[i]._ID = i
		_item_slots_equipped[i].ConnectButton(EquipedItemSlotButton)
	
	_selected_char_nature_tooltip.title_text = "Character Nature"
	_selected_char_nature_tooltip.description_text = ""
	
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

	ShowCharacters()

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
	for attr in _attribute_labels.keys():
		var total_attribute: int = (_character_collection[p_instance_ID]._attributes[attr]
				+ _character_collection[p_instance_ID].GetEquipmentBonus(attr))
		if(Types.Attribute.Health == attr):
			_attribute_labels[attr].text = str(total_attribute * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER)
		elif(Types.Attribute.CritChance == attr):
			_attribute_labels[attr].text = str(total_attribute) + "%"
		elif(Types.Attribute.CritDamage == attr):
			_attribute_labels[attr].text = str(total_attribute) + "%"
		else:
			_attribute_labels[attr].text = str(total_attribute)
	_selected_char_label.text = _character_collection[p_instance_ID]._name
	_selected_char_level.text = "Level: " + str(_character_collection[p_instance_ID]._level)
	_selected_char_nature.text = "Nature: " + str(_character_collection[p_instance_ID]._attributes_weights._name)
	_selected_char_nature_tooltip.title_text = str(
			_character_collection[p_instance_ID]._attributes_weights._name) + " Nature"
	_selected_char_nature_tooltip.description_text = str(
			_character_collection[p_instance_ID]._attributes_weights._description)
	
	_experience_bar.max_value = LevelSystem.GetExperienceRequirement(_character_collection[p_instance_ID]._level)
	_experience_bar.value = _character_collection[p_instance_ID]._experience
	_experience_bar_text.text = (str(_character_collection[p_instance_ID]._experience)
			+ " / " + str(int(_experience_bar.max_value)))
	
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Weapon)):
		_item_slots_equipped[0].SetHeldObjectTexture(
				main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Weapon))
		_item_slots_equipped[0].SetTextureOutline(
				_item_collection[_character_collection[p_instance_ID]._held_items[Types.Slot.Weapon]]._rarity)
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Shield)):
		_item_slots_equipped[1].SetHeldObjectTexture(
				main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Shield))
		_item_slots_equipped[1].SetTextureOutline(
				_item_collection[_character_collection[p_instance_ID]._held_items[Types.Slot.Shield]]._rarity)
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Boots)):
		_item_slots_equipped[2].SetHeldObjectTexture(
				main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Boots))
		_item_slots_equipped[2].SetTextureOutline(
				_item_collection[_character_collection[p_instance_ID]._held_items[Types.Slot.Boots]]._rarity)

func ShowCharacters() -> void:
	_scroll_container_characters.show()
	_scroll_container_items.hide()
	for i in _item_slots_equipped.size():
		_item_slots_equipped[i].SetHeldObjectTexture(null)

func ShowItems() -> void:
	_scroll_container_characters.hide()
	_scroll_container_items.show()
	for slot in _available_items.size():
		if slot < _displayed_item_ids.size():
			var item_id: int = _displayed_item_ids[slot]
			_available_items[slot].show()
			_available_items[slot].SetHeldObjectTexture(
					main.GetInstance()._item_collection.GetItemTexture(_item_collection[item_id]._slot))
			_available_items[slot].SetTextureOutline(_item_collection[item_id]._rarity)
			_available_items[slot].level.text = str(_item_collection[item_id]._level)
		else:
			_available_items[slot].SetHeldObjectTexture(null)
			_available_items[slot].level.text = ""
			_available_items[slot].hide()

func CanEquipFromMenuID(p_instance_ID: int) -> bool:
	var selected_item_type: Types.Slot = _item_collection[p_instance_ID]._slot
	return not _character_collection[_selected_character_ID]._held_items.has(selected_item_type)

func AvailableItemButton(p_slot_ID: int) -> void:
	var equip_difference_text: String = ""
	var item : Equipment = _item_collection[_displayed_item_ids[p_slot_ID]]
	if(_character_collection[_selected_character_ID]._held_items.has(item._slot)):
		var held_item_id = _character_collection[_selected_character_ID]._held_items[item._slot]
		var differing_value: int = 0
		for type in item._attributes.keys():
			differing_value = item._attributes[type] - _item_collection[held_item_id]._attributes[type]
			if(0 < differing_value):
				equip_difference_text += Types.Attribute.keys()[type] + " +" + str(differing_value) + "\n"
			elif(0 > differing_value):
				equip_difference_text += Types.Attribute.keys()[type] + " -" + str(differing_value) + "\n"
	else:
		for type in item._attributes.keys():
			if(0 < item._attributes[type]):
				equip_difference_text += Types.Attribute.keys()[type] + " +" + str(item._attributes[type]) + "\n"
			elif (0 > item._attributes[type]):
				equip_difference_text += Types.Attribute.keys()[type] + " -" + str(item._attributes[type]) + "\n"
	
	_select_item_option.SetText(item._name, equip_difference_text)
	_select_item_option.SetLeftButton("Equip", TriggerEquipItem)
	_select_item_option.SetMiddleButton("Sell", TrySell)
	_select_item_option.SetUpgradeButton("Upgrade", TryUpgrade)
	_select_item_option.show()
	_selected_item_slot_ID = p_slot_ID

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
	ShowItems()
	_confirm_option.hide()
	_select_item_option.hide()

func TryUpgrade() -> void:
	var item: Equipment = _item_collection[_displayed_item_ids[_selected_item_slot_ID]]
	if(not item.CanUpgrade()):
		_confirm_option.SetText("Upgrade", "This item is already at maximum level.")
		_confirm_option.show()
		return

	var cost: int = LootManager.GetUpgradeCost(item._rarity, item._level)
	_confirm_option.SetText("Upgrade", "Upgrade to level " + str(item._level + 1) + " for " + str(cost) + " silver.")
	_confirm_option.SetLeftButton("Upgrade", UpgradeItem)
	_confirm_option.show()

func UpgradeItem() -> void:
	var item: Equipment = _item_collection[_displayed_item_ids[_selected_item_slot_ID]]
	if(not item.CanUpgrade()):
		return

	var cost: int = LootManager.GetUpgradeCost(item._rarity, item._level)
	if(not main.GetInstance()._resources.SpendSilver(cost)):
		return

	item.Upgrade()
	_available_items[_selected_item_slot_ID].level.text = str(item._level)
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

func _on_button_reagents_button_up() -> void:
	RefreshReagentGrid()
	_reagent_window.show()

func _on_reagent_window_close_button_up() -> void:
	_reagent_window.hide()

func AvailableCharacterButton(p_slot_ID: int) -> void:
	_selected_character_ID = _displayed_character_ids[p_slot_ID]
	ShowSelectedCharacter(_displayed_character_ids[p_slot_ID])
	ShowItems()

func TriggerEquipItem() -> void:
	var item_id: int = _displayed_item_ids[_selected_item_slot_ID]

	var slot_type: Types.Slot = _item_collection[item_id]._slot
	if(_character_collection[_selected_character_ID]._held_items.has(slot_type)):
		TriggerUnequipItem(slot_type)

	_character_collection[_selected_character_ID].EquipItem(item_id)
	main.GetInstance()._item_collection.EquipCollectionItem(item_id)
	RefreshDisplayedItems()
	ShowItems()
	ShowSelectedCharacter(_selected_character_ID)
	_selected_item_slot_ID = -1
	_select_item_option.hide()

func TriggerUnequipItem(p_item_type: Types.Slot) -> void:
	var held_item_ID: int = _character_collection[_selected_character_ID]._held_items[p_item_type]

	match p_item_type:
		Types.Slot.Weapon:
			_item_slots_equipped[0].SetHeldObjectTexture(null)
		Types.Slot.Shield:
			_item_slots_equipped[1].SetHeldObjectTexture(null)
		Types.Slot.Boots:
			_item_slots_equipped[2].SetHeldObjectTexture(null)

	main.GetInstance()._item_collection.UnequipCollectionItem(held_item_ID)
	_character_collection[_selected_character_ID].UnequipItem(p_item_type)

	RefreshDisplayedItems()
	ShowItems()
	ShowSelectedCharacter(_selected_character_ID)

func EquipedItemSlotButton(p_slot_ID: int) -> void:
	if _selected_character_ID == -1:
		return
	match p_slot_ID:
		0:
			if(_character_collection[_selected_character_ID]._held_items.has(Types.Slot.Weapon)):
				TriggerUnequipItem(Types.Slot.Weapon)
		1:
			if(_character_collection[_selected_character_ID]._held_items.has(Types.Slot.Shield)):
				TriggerUnequipItem(Types.Slot.Shield)
		2:
			if(_character_collection[_selected_character_ID]._held_items.has(Types.Slot.Boots)):
				TriggerUnequipItem(Types.Slot.Boots)

func _on_button_deselect_char_button_up() -> void:
	_selected_character_texture.texture = null
	for attr in _attribute_labels.keys():
		_attribute_labels[attr].text = "0"
	_selected_char_label.text = ""
	_selected_char_level.text = ""
	_selected_char_nature.text = "Nature: "
	_selected_char_nature_tooltip.title_text = "Character Nature"
	_selected_char_nature_tooltip.description_text = ""
	_experience_bar.max_value = 100.0
	_experience_bar.value = 0.0
	_experience_bar_text.text = ""
	for slot_nr in _available_characters.size(): #_displayed_character_ids
		if(slot_nr < _character_collection.size()):
			_available_characters[slot_nr].SetHeldObjectTexture(
					main.GetInstance()._character_collection.GetCharacterTexture(
						_character_collection[_displayed_character_ids[slot_nr]]._name))
			_available_characters[slot_nr].SetTextureOutline(
					_character_collection[_displayed_character_ids[slot_nr]]._rarity)
			_available_characters[slot_nr].level.text = str(
					_character_collection[_displayed_character_ids[slot_nr]]._level)
		else:
			_available_characters[slot_nr].SetHeldObjectTexture(null)
	for i in _item_slots_equipped.size():
		_item_slots_equipped[i].SetHeldObjectTexture(null)
	_selected_character_ID = -1
	ShowCharacters()

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)
