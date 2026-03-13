class_name InspectCollectionMenu extends Control

const GAMEBALANCE = preload("res://Scripts/game_balance.gd")

@export var _attribute_labels: Dictionary[Types.Attribute, Label]
@export var _selected_char_label: Label
@export var _selected_char_level: Label

@onready var v_box_container: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer
@onready var v_box_container_2: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer2
@onready var _selected_character_texture: TextureRect = $MarginContainer/HBoxContainer2/VBoxContainer2/ColorRect2/TextureRect

var _available_menu_slots: Array[MenuItemSlot]
var _item_slots_equipped: Array[MenuItemSlot]
var _showing_items: bool = false
var _character_collection: Dictionary[int, Character] = main.GetInstance()._character_collection.GetAllCharacters()
var _item_collection: Dictionary[int, Equipment] = main.GetInstance()._item_collection._items
var _selected_character_ID: int = -1

var _displayed_item_ids: Array[int] = []
var _displayed_character_ids: Array[int] = []

func Init(_p_context_container: ContextContainer) -> void:
	_available_menu_slots.append_array(GetMenuItemSlotChildren(v_box_container))
	_displayed_item_ids.resize(_available_menu_slots.size())
	_displayed_character_ids.resize(_available_menu_slots.size())
	
	for slot_nr in _available_menu_slots.size():
		_available_menu_slots[slot_nr]._ID = slot_nr
		_available_menu_slots[slot_nr].ConnectButton(AvailableItemSlotButton)
		
		if(slot_nr < _character_collection.size()):
			_displayed_character_ids[slot_nr] = _character_collection.keys()[slot_nr]
			_available_menu_slots[slot_nr].SetHeldObjectTexture(main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[_displayed_character_ids[slot_nr]]._role))
			_available_menu_slots[slot_nr].level.text = str(_character_collection[_displayed_character_ids[slot_nr]]._level)
		else:
			_displayed_character_ids[slot_nr] = -1
		
		if(slot_nr < main.GetInstance()._item_collection.Size()):
			if(main.GetInstance()._item_collection.UNEQUIPPED == _item_collection[_item_collection.keys()[slot_nr]]._held_by):
				_displayed_item_ids[slot_nr] = _item_collection.keys()[slot_nr]
			else:
					_displayed_item_ids[slot_nr] = -1
		else:
			_displayed_item_ids[slot_nr] = -1
	
	_item_slots_equipped.append_array(GetMenuItemSlotChildren(v_box_container_2))
	for i in _item_slots_equipped.size():
		_item_slots_equipped[i]._ID = i
		_item_slots_equipped[i].ConnectButton(EquipedItemSlotButton)
	
	print("\n_item_collection.size(): ", _item_collection.size())
	print("\n_displayed_character_ids: ", _displayed_character_ids)
	print("\n_displayed_item_ids: ", _displayed_item_ids)

func GetMenuItemSlotChildren(p_start_node: Node) -> Array[MenuItemSlot]:
	var result: Array[MenuItemSlot] = []
	for child in p_start_node.get_children():
		if child is MenuItemSlot:
			result.append(child)
		result += GetMenuItemSlotChildren(child)
	return result

func ShowSelectedCharacter(p_instance_ID: int) -> void:
	_selected_character_texture.texture = main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[p_instance_ID]._role)
	for attr in _attribute_labels.keys():
		if(Types.Attribute.Health == attr):
			_attribute_labels[attr].text = str((_character_collection[p_instance_ID]._attributes[attr] + _character_collection[p_instance_ID].GetEquipmentBonus(attr)) * GAMEBALANCE.ATTRIBUTE_HEALTH_MULTIPLIER)
		elif(Types.Attribute.CritChance == attr):
			_attribute_labels[attr].text = str((_character_collection[p_instance_ID]._attributes[attr] + _character_collection[p_instance_ID].GetEquipmentBonus(attr))) + "%"
		elif(Types.Attribute.CritDamage == attr):
			_attribute_labels[attr].text = str(_character_collection[p_instance_ID]._attributes[attr] + _character_collection[p_instance_ID].GetEquipmentBonus(attr)) + "%"
		else:
			_attribute_labels[attr].text = str(_character_collection[p_instance_ID]._attributes[attr] + _character_collection[p_instance_ID].GetEquipmentBonus(attr))
	_selected_char_label.text = "Attributes for: " + _character_collection[p_instance_ID]._name
	_selected_char_level.text = "Level: " + str(_character_collection[p_instance_ID]._level)
	
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Weapon)):
		_item_slots_equipped[0].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Weapon))
		_item_slots_equipped[0].SetTextureOutline(_item_collection[_character_collection[p_instance_ID]._held_items[Types.Slot.Weapon]]._rarity)
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Shield)):
		_item_slots_equipped[1].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Shield))
		_item_slots_equipped[1].SetTextureOutline(_item_collection[_character_collection[p_instance_ID]._held_items[Types.Slot.Shield]]._rarity)
	if(_character_collection[p_instance_ID]._held_items.has(Types.Slot.Boots)):
		_item_slots_equipped[2].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Boots))
		_item_slots_equipped[2].SetTextureOutline(_item_collection[_character_collection[p_instance_ID]._held_items[Types.Slot.Boots]]._rarity)

func ShowItemCollection() -> void:
	for slot in _available_menu_slots.size():
		_available_menu_slots[slot].level.text = ""
		if(slot < _item_collection.size()):
			if(main.GetInstance()._item_collection.UNEQUIPPED == _item_collection[_item_collection.keys()[slot]]._held_by):
				_available_menu_slots[slot].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(_item_collection[_displayed_item_ids[slot]]._slot))
				_available_menu_slots[slot].SetTextureOutline(_item_collection[_displayed_item_ids[slot]]._rarity)
				continue
		_available_menu_slots[slot].SetHeldObjectTexture(null)

func CanEquipFromMenuID(p_instance_ID: int) -> bool:
	var selected_item_type: Types.Slot = _item_collection[p_instance_ID]._slot
	return not _character_collection[_selected_character_ID]._held_items.has(selected_item_type)

func AvailableItemSlotButton(p_slot_ID: int) -> void:
	if(p_slot_ID < _character_collection.size() and not _showing_items):
		_showing_items = true
		_selected_character_ID = _displayed_character_ids[p_slot_ID]
		ShowSelectedCharacter(_displayed_character_ids[p_slot_ID])
		ShowItemCollection()
	elif (_item_collection.has(_displayed_item_ids[p_slot_ID]) and _showing_items):
		if(CanEquipFromMenuID(_displayed_item_ids[p_slot_ID])):
			TriggerEquipItem(p_slot_ID)

func TriggerEquipItem(p_slot_ID: int) -> void:
	_character_collection[_selected_character_ID].EquipItem(_displayed_item_ids[p_slot_ID])
	main.GetInstance()._item_collection.EquipCollectionItem(_displayed_item_ids[p_slot_ID])
	_available_menu_slots[p_slot_ID].SetHeldObjectTexture(null)
	_displayed_item_ids[p_slot_ID] = -1
	ShowSelectedCharacter(_selected_character_ID)

func TriggerUnequipItem(p_item_type: Types.Slot) -> void:
	var held_item_ID = _character_collection[_selected_character_ID]._held_items[p_item_type]
	var slot_for_held_item: int = -1
	for slot_nr in _displayed_item_ids.size():
		if(-1 == _displayed_item_ids[slot_nr]):
			slot_for_held_item = slot_nr
			_displayed_item_ids[slot_for_held_item] = held_item_ID
			break
	
	match p_item_type:
		Types.Slot.Weapon:
			_item_slots_equipped[0].SetHeldObjectTexture(null)
			_available_menu_slots[slot_for_held_item].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Weapon))
		Types.Slot.Shield:
			_item_slots_equipped[1].SetHeldObjectTexture(null)
			_available_menu_slots[slot_for_held_item].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Shield))
		Types.Slot.Boots:
			_item_slots_equipped[2].SetHeldObjectTexture(null)
			_available_menu_slots[slot_for_held_item].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Boots))
	_available_menu_slots[slot_for_held_item].SetTextureOutline(_item_collection[held_item_ID]._rarity)
	
	main.GetInstance()._item_collection.UnequipCollectionItem(held_item_ID)
	_character_collection[_selected_character_ID].UnequipItem(p_item_type)
	ShowSelectedCharacter(_selected_character_ID)

func EquipedItemSlotButton(p_slot_ID: int) -> void:
	if(_showing_items):
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
	if(_showing_items):
		_showing_items = false
		_selected_character_texture.texture = null
		for attr in _attribute_labels.keys():
			_attribute_labels[attr].text = "0"
		_selected_char_label.text = "Attributes for: "
		_selected_char_level.text = "Level: "
		for slot_nr in _available_menu_slots.size(): #_displayed_character_ids
			if(slot_nr < _character_collection.size()):
				_available_menu_slots[slot_nr].SetHeldObjectTexture(main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[_displayed_character_ids[slot_nr]]._role))
				_available_menu_slots[slot_nr].SetTextureOutline(_character_collection[_displayed_character_ids[slot_nr]]._rarity)
				_available_menu_slots[slot_nr].level.text = str(_character_collection[_displayed_character_ids[slot_nr]]._level)
			else:
				_available_menu_slots[slot_nr].SetHeldObjectTexture(null)
		for i in _item_slots_equipped.size():
			_item_slots_equipped[i].SetHeldObjectTexture(null)
		_selected_character_ID = -1

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)
