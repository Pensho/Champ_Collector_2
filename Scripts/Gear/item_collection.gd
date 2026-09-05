class_name ItemCollection extends Node

const GEARDATA = preload("res://Scripts/Gear/equipment_preset.gd")

const UNEQUIPPED: int = -1

var _items: Dictionary[int, Equipment] = {}
var _next_id: int = 0

var _texture_cache: Dictionary[String, Texture] = {}

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)
	_PreloadItemTextures()

func _PreloadItemTextures() -> void:
	for preset: EquipmentPreset in EquipmentPresetRegistry.PRESETS.values():
		_CachedTexture(preset._texture_path)
	for preset: EquipmentPreset in EquipmentPresetRegistry.RELIC_PRESETS.values():
		_CachedTexture(preset._texture_path)

func Serialize() -> Dictionary:
	var items_data: Array = []
	for item: Equipment in _items.values():
		items_data.append({
			"preset_path": item._preset_path,
			"attributes": item._attributes.duplicate(true),
			"instance_ID": item._instance_ID,
			"held_by": item._held_by,
			"rarity": item._rarity,
			"item_type": item._item_type,
			"level": item._level,
		})
	return {"items": items_data, "next_ID": _next_id}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("items")):
		print("No items found in save slot.")
		return
	
	if(p_data.has("next_ID")):
		_next_id = p_data["next_ID"]
	_items.clear()
	for item_data in p_data["items"]:
		var preset_path: String = item_data.get("preset_path", item_data.get("preset_UID", ""))
		if preset_path.is_empty():
			push_error("Skipping item with empty preset_path (instance_ID: %d)" % item_data.get("instance_ID", -1))
			continue
		var preset_resource: Resource = load(preset_path)
		if preset_resource == null:
			push_error("Skipping item with unresolvable preset_path '%s' (instance_ID: %d)" %
				[preset_path, item_data.get("instance_ID", -1)])
			continue
		var preset: EquipmentPreset = preset_resource.duplicate(true)
		if(item_data.has("rarity")):
			preset._rarity = item_data["rarity"]
		var new_equipment: Equipment = Equipment.new()
		new_equipment.InstantiateNew(preset, item_data["instance_ID"])

		for attribute in item_data["attributes"].keys():
			new_equipment._attributes[int(attribute)] = item_data["attributes"][attribute] as int

		new_equipment._held_by = item_data["held_by"]
		new_equipment._item_type = item_data.get("item_type", Types.Item_Type.Standard) as Types.Item_Type
		new_equipment._level = item_data.get("level", 0)

		_items[new_equipment._instance_ID] = new_equipment
	print("Calling Deserialize for ItemCollection, data:\n", p_data)

static func _LoadItemTexture(p_path: String) -> Texture:
	if(ResourceLoader.exists(p_path)):
		return load(p_path)
	return null

func _CachedTexture(p_path: String) -> Texture:
	if(not _texture_cache.has(p_path)):
		_texture_cache[p_path] = _LoadItemTexture(p_path)
	return _texture_cache[p_path]

func GetItemTexture(p_instance_ID: int) -> Texture:
	if(not _items.has(p_instance_ID)):
		return null
	return _CachedTexture(_items[p_instance_ID]._texture)

func AddPreset(preset: EquipmentPreset) -> void:
	var new_equipment: Equipment = Equipment.new()
	new_equipment.InstantiateNew(preset, CreateNextInstanceID())
	_items[new_equipment._instance_ID] = new_equipment

func UnequipCollectionItem(p_instanceID: int) -> void:
	_items[p_instanceID]._held_by = UNEQUIPPED

func UnequipAllHeldItems(p_character: Character) -> void:
	for held_item_ID: int in p_character._held_items.values():
		if(_items.has(held_item_ID)):
			UnequipCollectionItem(held_item_ID)
	p_character._held_items.clear()

func Remove(instanceID: int) -> void:
	if(!_items.erase(instanceID)):
		print("There was no such item to be removed! ID: ", instanceID)

func CreateNextInstanceID() -> int:
	_next_id += 1
	return _next_id - 1

func EquipCollectionItem(p_instanceID: int) -> void:
	_items[p_instanceID]._held_by = p_instanceID

func Size() -> int:
	return _items.size()
