class_name ItemCollection extends Node

const Types = preload("res://Scripts/common_enums.gd")
const GEARDATA = preload("res://Scripts/Gear/equipment_preset.gd")

var _collected_types: Dictionary[Types.Slot, String]
var _used_item_textures: Dictionary[Types.Slot, Texture]

var _items: Dictionary[int, Equipment] = {}

func LoadTextures() -> void:
	for type in _collected_types.keys():
		_used_item_textures[type] = load(_collected_types[type])

func GetItemTexture(p_item_type: Types.Slot) -> Texture:
	match p_item_type:
		Types.Slot.Helmet:
			return _used_item_textures[Types.Slot.Helmet]
		Types.Slot.Weapon:
			return _used_item_textures[Types.Slot.Weapon]
		Types.Slot.Shield:
			return _used_item_textures[Types.Slot.Shield]
		Types.Slot.Chest:
			return _used_item_textures[Types.Slot.Chest]
		Types.Slot.Pants:
			return _used_item_textures[Types.Slot.Pants]
		Types.Slot.Boots:
			return _used_item_textures[Types.Slot.Boots]
		Types.Slot.Gloves:
			return _used_item_textures[Types.Slot.Gloves]
		Types.Slot.Ring:
			return _used_item_textures[Types.Slot.Ring]
		Types.Slot.Amulet:
			return _used_item_textures[Types.Slot.Amulet]
		Types.Slot.Trinket:
			return _used_item_textures[Types.Slot.Trinket]
		_:
			print("Item_Collection.gd/GetItemTexture() Unspecified item type!")
	return null

func AddPreset(preset: EquipmentPreset) -> void:
	var new_equipment: Equipment = load("res://Scenes/Equipment/Equipment.tscn").instantiate()
	new_equipment.InstantiateNew(preset, CreateNextInstanceID())
	_items[new_equipment._instanceID] = new_equipment
	
	# Debug print for gear attribute bonuses
	#for i in new_equipment._attributes.keys():
		#print("Item has attribute value: ", new_equipment._attributes[i])
	
	if(!_collected_types.has(new_equipment._slot)):
		_collected_types[new_equipment._slot] = new_equipment._texture
		_used_item_textures[new_equipment._slot] = load(new_equipment._texture)

func AddEquipment(p_equipment: Equipment) -> void:
	if(_items.has(p_equipment._instanceID)):
		p_equipment._instanceID = CreateNextInstanceID()
	_items[p_equipment._instanceID] = p_equipment

func Remove(instanceID: int) -> void:
	if(!_items.erase(instanceID)):
		print("There was no such item to be removed! ID: ", instanceID)
	# TODO: If there no longer is a type of role in the collection, remove it from _collected_types.

func CreateNextInstanceID() -> int:
	var nextID: int = 0
	if(_items.size() == 0):
		return nextID
	while _items.has(nextID):
		nextID += 1
	return nextID

func TakeEquipment(p_instanseID: int) -> Equipment:
	var item: Equipment
	if(not _items.has(p_instanseID)):
		print("There is no item at ID: ", p_instanseID)
		return null
	item = _items[p_instanseID]
	_items.erase(p_instanseID)
	return item
