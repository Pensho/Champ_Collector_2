class_name InspectCollectionMenu extends Control

const Types = preload("res://Scripts/common_enums.gd")
const GameBalance = preload("res://Scripts/game_balance.gd")

@export var _attribute_labels: Dictionary[Types.Attribute, Label]
@export var _selected_char_label: Label

@onready var v_box_container: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer
@onready var v_box_container_2: VBoxContainer = $MarginContainer/HBoxContainer2/VBoxContainer2
@onready var _selected_character_texture: TextureRect = $MarginContainer/HBoxContainer2/VBoxContainer2/ColorRect2/TextureRect

var _available_item_slots: Array[MenuItemSlot]
var _item_slots_equiped: Array[MenuItemSlot]
var _showing_items: bool = false
var _character_collection: Array[Character] = main._character_collection.GetAllCharacters().values()

func Init(p_context_container: ContextContainer) -> void:
	_available_item_slots.append_array(GetMenuItemSlotChildren(v_box_container))
	print("There now are ", _available_item_slots.size(), " elements in _available_item_slots")
	var character_collection_size: int = main._character_collection.Size()
	
	for i in _available_item_slots.size():
		_available_item_slots[i]._ID = i
		_available_item_slots[i].button.button_up.connect(AvailableItemSlotButton.bind(i))
		if(i < character_collection_size):
			_available_item_slots[i].SetHeldObjectTexture(main._character_collection.GetCharacterTexture(_character_collection[i]._role))
	
	_item_slots_equiped.append_array(GetMenuItemSlotChildren(v_box_container_2))
	print("There now are ", _item_slots_equiped.size(), " elements in _available_item_slots")
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

func AvailableItemSlotButton(p_ID: int) -> void:
	if(p_ID < _character_collection.size() and not _showing_items):
		_selected_character_texture.texture = main._character_collection.GetCharacterTexture(_character_collection[p_ID]._role)
		_showing_items = true
		for attr in _attribute_labels.keys():
			if(Types.Attribute.Health == attr):
				_attribute_labels[attr].text = str(_character_collection[p_ID]._attributes[attr] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER)
			else:
				_attribute_labels[attr].text = str(_character_collection[p_ID]._attributes[attr])
		_selected_char_label.text = "Attributes for: " + _character_collection[p_ID]._name
		print("AvailableItemSlotButton Button nr: ", p_ID, " called.")

func EquipedItemSlotButton(p_ID: int) -> void:
	print("EquipedItemSlotButton Button nr: ", p_ID, " called.")

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/MainMenu.tscn"
	main.change_scene(context_container)

func _on_button_deselect_char_button_up() -> void:
	if(_showing_items):
		_showing_items = false
		_selected_character_texture.texture = null
		for attr in _attribute_labels.keys():
			_attribute_labels[attr].text = "0"
		_selected_char_label.text = "Attributes for: "
