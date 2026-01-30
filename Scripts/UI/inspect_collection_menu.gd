class_name InspectCollectionMenu extends Control

const Types = preload("res://Scripts/common_enums.gd")
const GAMEBALANCE = preload("res://Scripts/game_balance.gd")

@export var _attribute_labels: Dictionary[Types.Attribute, Label]
@export var _selected_char_label: Label
@export var _selected_char_level: Label

@onready var v_box_container: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer
@onready var v_box_container_2: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer2
@onready var _selected_character_texture: TextureRect = $MarginContainer/HBoxContainer2/VBoxContainer2/ColorRect2/TextureRect

var _available_item_slots: Array[MenuItemSlot]
var _item_slots_equiped: Array[MenuItemSlot]
var _showing_items: bool = false
var _character_collection: Array[Character] = main.GetInstance()._character_collection.GetAllCharacters().values()
var _character_collection_size: int
var _selected_character_ID: int = -1

func Init(_p_context_container: ContextContainer) -> void:
	_available_item_slots.append_array(GetMenuItemSlotChildren(v_box_container))
	_character_collection_size = main.GetInstance()._character_collection.Size()
	
	for i in _available_item_slots.size():
		_available_item_slots[i]._ID = i
		_available_item_slots[i].button.button_up.connect(AvailableItemSlotButton.bind(i))
		if(i < _character_collection_size):
			_available_item_slots[i].SetHeldObjectTexture(main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[i]._role))
			_available_item_slots[i].level.text = str(_character_collection[i]._level)
	
	_item_slots_equiped.append_array(GetMenuItemSlotChildren(v_box_container_2))
	for i in _item_slots_equiped.size():
		_item_slots_equiped[i]._ID = i
		_item_slots_equiped[i].button.button_up.connect(EquipedItemSlotButton.bind(i))

func GetMenuItemSlotChildren(p_start_node: Node) -> Array[MenuItemSlot]:
	var result: Array[MenuItemSlot] = []
	for child in p_start_node.get_children():
		if child is MenuItemSlot:
			result.append(child)
		result += GetMenuItemSlotChildren(child)
	return result

func ShowSelectedCharacter(p_ID: int) -> void:
	_selected_character_texture.texture = main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[p_ID]._role)
	for attr in _attribute_labels.keys():
		if(Types.Attribute.Health == attr):
			_attribute_labels[attr].text = str((_character_collection[p_ID]._attributes[attr] + _character_collection[p_ID].GetEquipmentBonus(attr)) * GAMEBALANCE.ATTRIBUTE_HEALTH_MULTIPLIER)
		elif(Types.Attribute.CritChance == attr):
			_attribute_labels[attr].text = str((_character_collection[p_ID]._attributes[attr] + _character_collection[p_ID].GetEquipmentBonus(attr))) + "%"
		elif(Types.Attribute.CritDamage == attr):
			_attribute_labels[attr].text = str(_character_collection[p_ID]._attributes[attr] + _character_collection[p_ID].GetEquipmentBonus(attr)) + "%"
		else:
			_attribute_labels[attr].text = str(_character_collection[p_ID]._attributes[attr] + _character_collection[p_ID].GetEquipmentBonus(attr))
	_selected_char_label.text = "Attributes for: " + _character_collection[p_ID]._name
	_selected_char_level.text = "Level: " + str(_character_collection[p_ID]._level)
	
	if(_character_collection[p_ID]._held_items.has(Types.Slot.Weapon)):
		_item_slots_equiped[0].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Weapon))
		_item_slots_equiped[0].SetTextureOutline(_character_collection[p_ID]._held_items[Types.Slot.Weapon]._rarity)
	if(_character_collection[p_ID]._held_items.has(Types.Slot.Shield)):
		_item_slots_equiped[1].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Shield))
		_item_slots_equiped[1].SetTextureOutline(_character_collection[p_ID]._held_items[Types.Slot.Shield]._rarity)
	if(_character_collection[p_ID]._held_items.has(Types.Slot.Boots)):
		_item_slots_equiped[2].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Boots))
		_item_slots_equiped[2].SetTextureOutline(_character_collection[p_ID]._held_items[Types.Slot.Boots]._rarity)

func ShowItemCollection() -> void:
	for slot in _available_item_slots.size():
		_available_item_slots[slot].level.text = ""
		
		if(main.GetInstance()._item_collection._items.has(slot)):
			_available_item_slots[slot].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(main.GetInstance()._item_collection._items[slot]._slot))
			_available_item_slots[slot].SetTextureOutline(main.GetInstance()._item_collection._items[slot]._rarity)
		else:
			_available_item_slots[slot].SetHeldObjectTexture(null)

func CanEquipFromMenuID(p_ID: int) -> bool:
	var selected_item_type: Types.Slot = main.GetInstance()._item_collection._items[p_ID]._slot
	return not _character_collection[_selected_character_ID]._held_items.has(selected_item_type)

func AvailableItemSlotButton(p_ID: int) -> void:
	if(p_ID < _character_collection.size() and not _showing_items):
		_showing_items = true
		_selected_character_ID = p_ID
		ShowSelectedCharacter(p_ID)
		ShowItemCollection()
	elif (main.GetInstance()._item_collection._items.has(p_ID) and _showing_items):
		if(CanEquipFromMenuID(p_ID)):
			print("Can equip!")
			EquipItem(p_ID)

func EquipItem(p_ID: int) -> void:
	var item: Equipment =  main.GetInstance()._item_collection.TakeEquipment(p_ID)
	_character_collection[_selected_character_ID].AddEquipment(item)
	_available_item_slots[p_ID].SetHeldObjectTexture(null)
	ShowSelectedCharacter(_selected_character_ID)

func UnequipItem(p_slot: Types.Slot) -> void:
	var held_item = _character_collection[_selected_character_ID]._held_items[p_slot]
	main.GetInstance()._item_collection.AddEquipment(held_item)
	_character_collection[_selected_character_ID]._held_items.erase(p_slot)
	match p_slot:
		Types.Slot.Weapon:
			_item_slots_equiped[0].SetHeldObjectTexture(null)
			_available_item_slots[held_item._instanceID].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Weapon))
		Types.Slot.Shield:
			_item_slots_equiped[1].SetHeldObjectTexture(null)
			_available_item_slots[held_item._instanceID].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Shield))
		Types.Slot.Boots:
			_item_slots_equiped[2].SetHeldObjectTexture(null)
			_available_item_slots[held_item._instanceID].SetHeldObjectTexture(main.GetInstance()._item_collection.GetItemTexture(Types.Slot.Boots))
	_available_item_slots[held_item._instanceID].SetTextureOutline(held_item._rarity)
	ShowSelectedCharacter(_selected_character_ID)
	print(_character_collection[_selected_character_ID], " now holds these items: ", _character_collection[_selected_character_ID]._held_items)
	print("item collection now holds these items: ", main.GetInstance()._item_collection._items)

func EquipedItemSlotButton(p_ID: int) -> void:
	if(_showing_items):
		match p_ID:
			0:
				print("Trying to remove weapon from ", _character_collection[_selected_character_ID]._name)
				if(_character_collection[_selected_character_ID]._held_items.has(Types.Slot.Weapon)):
					UnequipItem(Types.Slot.Weapon)
			1:
				print("Trying to remove shield from ", _character_collection[_selected_character_ID]._name)
				if(_character_collection[_selected_character_ID]._held_items.has(Types.Slot.Shield)):
					UnequipItem(Types.Slot.Shield)
			2:
				print("Trying to remove boots from ", _character_collection[_selected_character_ID]._name)
				if(_character_collection[_selected_character_ID]._held_items.has(Types.Slot.Boots)):
					UnequipItem(Types.Slot.Boots)

func _on_button_deselect_char_button_up() -> void:
	if(_showing_items):
		_showing_items = false
		_selected_character_texture.texture = null
		for attr in _attribute_labels.keys():
			_attribute_labels[attr].text = "0"
		SetAvailableSlots(_showing_items)
		_selected_char_label.text = "Attributes for: "
		_selected_char_level.text = "Level: "
		for i in _available_item_slots.size():
			if(i < _character_collection_size):
				_available_item_slots[i].SetHeldObjectTexture(main.GetInstance()._character_collection.GetCharacterTexture(_character_collection[i]._role))
				_available_item_slots[i].SetTextureOutline(_character_collection[i]._rarity)
				_available_item_slots[i].level.text = str(_character_collection[i]._level)
			else:
				_available_item_slots[i].SetHeldObjectTexture(null)
		for i in _item_slots_equiped.size():
			_item_slots_equiped[i].SetHeldObjectTexture(null)
		_selected_character_ID = -1

func SetAvailableSlots(p_show_items: bool) -> void:
	if(p_show_items):
		pass
	else:
		pass

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)
