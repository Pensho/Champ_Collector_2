class_name ItemCollection extends Node

const GEARDATA = preload("res://Scripts/Gear/equipment_preset.gd")

const UNEQUIPPED: int = -1

var _collected_types: Dictionary[Types.Slot, String]
var _used_item_textures: Dictionary[Types.Slot, Texture]
var _items: Dictionary[int, Equipment] = {}
var _next_ID: int = 0

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

func Serialize() -> Dictionary:
	var items_data: Array = []
	for item: Equipment in _items.values():
		items_data.append({
			"preset_UID": item._preset_UID,
			"attributes": item._attributes.duplicate(true),
			"instance_ID": item._instanceID,
			"held_by": item._held_by,
			"rarity": item._rarity,
		})
	return {"items": items_data, "next_ID": _next_ID}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("items")):
		print("No items found in save slot.")
		return
	
	if(p_data.has("next_ID")):
		_next_ID = p_data["next_ID"]
	_items.clear()
	for item_data in p_data["items"]:
		var preset: EquipmentPreset = load(item_data["preset_UID"]).duplicate(true)
		var new_equipment: Equipment = Equipment.new()
		new_equipment.InstantiateNew(preset, item_data["instance_ID"])
		
		for attribute in item_data["attributes"].keys():
			new_equipment._attributes[int(attribute)] = item_data["attributes"][attribute] as int
		
		new_equipment._held_by = item_data["held_by"]
		if(item_data.has("rarity")):
			new_equipment._rarity = item_data["rarity"]
		
		_items[new_equipment._instanceID] = new_equipment
		if(!_collected_types.has(new_equipment._slot)):
			_collected_types[new_equipment._slot] = new_equipment._texture
			_used_item_textures[new_equipment._slot] = load(new_equipment._texture)
	print("Calling Deserialize for ItemCollection, data:\n", p_data)

func LoadTextures() -> void:
	for type in _collected_types.keys():
		if(!_used_item_textures.has(type)):
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
	var new_equipment: Equipment = Equipment.new()
	new_equipment.InstantiateNew(preset, CreateNextInstanceID())
	_items[new_equipment._instanceID] = new_equipment
	
	if(!_collected_types.has(new_equipment._slot)):
		_collected_types[new_equipment._slot] = new_equipment._texture
		_used_item_textures[new_equipment._slot] = load(new_equipment._texture)

func UnequipCollectionItem(p_instanceID: int) -> void:
	_items[p_instanceID]._held_by = UNEQUIPPED

func Remove(instanceID: int) -> void:
	if(!_items.erase(instanceID)):
		print("There was no such item to be removed! ID: ", instanceID)
	# TODO: If there no longer is a type of role in the collection, remove it from _collected_types.

func CreateNextInstanceID() -> int:
	_next_ID += 1
	return _next_ID - 1

func EquipCollectionItem(p_instanceID: int) -> void:
	_items[p_instanceID]._held_by = p_instanceID

func Size() -> int:
	return _items.size()
