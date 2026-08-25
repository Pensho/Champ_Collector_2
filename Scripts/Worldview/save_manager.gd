class_name SaveManager extends Node

const GROUP_SAVEABLE: String = "saveable"
const SAVE_DIR: String = "user://"

var _active_profile_name: String

func _GetSlotPath(p_slot: int) -> String:
	return SAVE_DIR + "profile_" + str(p_slot) + ".save"

func HasSaveSlot(p_slot: int) -> bool:
	return FileAccess.file_exists(_GetSlotPath(p_slot))

func Save(p_slot: int) -> bool:
	var data := {}
	data["meta"] = BuildMetaData(p_slot)
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		data[node.name] = node.Serialize()

	var save_file: FileAccess = FileAccess.open(_GetSlotPath(p_slot), FileAccess.WRITE)
	if (not save_file):
		return false

	save_file.store_string(JSON.stringify(data, "\t"))
	return true

func Load(p_slot: int) -> bool:
	if (not HasSaveSlot(p_slot)):
		return false

	var save_file: FileAccess = FileAccess.open(_GetSlotPath(p_slot), FileAccess.READ)
	if (not save_file):
		return false

	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if (not (parsed is Dictionary)):
		return false
	var data: Dictionary = parsed

	# Items must load before characters so gear can be re-equipped
	_deserialize_group_by_type(data, ItemCollection)
	_deserialize_group_by_type(data, CharacterCollection)

	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		if not (node is ItemCollection) and not (node is CharacterCollection):
			node.Deserialize(data.get(node.name, {}))

	#_restore_equipped_gear()

	return true

func _deserialize_group_by_type(data: Dictionary, type) -> void:
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		if (is_instance_of(node, type)):
			node.Deserialize(data.get(node.name, {}))

func DeleteSave(p_slot: int) -> bool:
	if (not HasSaveSlot(p_slot)):
		return false
	return DirAccess.remove_absolute(_GetSlotPath(p_slot)) == OK

func BuildMetaData(p_slot: int) -> Dictionary:
	if(_active_profile_name.is_empty()):
		var data = GetSlotMetadata(p_slot)
		if (data.has("profile_name")):
			_active_profile_name = data["profile_name"]

	var main_instance = main.GetInstance()
	return {
		"profile_name": _active_profile_name,
		"saved_at": Time.get_datetime_string_from_system(),
		"highest_difficulty": main_instance._progress.GetHighestDifficulty(),
		"character_count": main_instance._character_collection.Size(),
		"character_capacity": main_instance._character_collection._current_max_amount,
		"highest_character_level": main_instance._character_collection.GetHighestCharacterLevel(),
		"unique_characters": main_instance._character_collection.GetCollectedTypeCount(),
		"silver": main_instance._resources.GetSilver(),
		"supplies": main_instance._resources.GetSupplies(),
		}

func GetSlotMetadata(p_slot: int) -> Dictionary:
	if (not HasSaveSlot(p_slot)):
		return {}

	var save_file: FileAccess = FileAccess.open(_GetSlotPath(p_slot), FileAccess.READ)
	if (not save_file):
		return {}

	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if (not (parsed is Dictionary)):
		return {}
	var data: Dictionary = parsed
	return data.get("meta", {})
