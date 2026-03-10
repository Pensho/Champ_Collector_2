class_name SaveManager extends Node

const GROUP_SAVEABLE: String = "saveable"
const SAVE_DIR: String = "user://"

var _active_profile_name: String
var _played_time: int

func HasSaveSlot(p_slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "profile_" + str(p_slot) + ".save")

func Save(p_slot: int) -> void:
	var data := {}
	data["meta"] = BuildMetaData(p_slot)
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		print("Calling save for node: ", node.name)
		data[node.name] = node.Serialize()
	
	var save_file: FileAccess = FileAccess.open(SAVE_DIR + "profile_" + str(p_slot) + ".save", FileAccess.WRITE)
	
	save_file.store_string(JSON.stringify(data, "\t"))

func Load(p_slot: int) -> void:
	if (not HasSaveSlot(p_slot)):
		print("There is no saved data for: ", SAVE_DIR + "profile_" + str(p_slot) + ".save")
		return
	
	var save_file: FileAccess = FileAccess.open(SAVE_DIR + "profile_" + str(p_slot) + ".save", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(save_file.get_as_text())
	
	# Items must load before characters so gear can be re-equipped
	_deserialize_group_by_type(data, ItemCollection)
	_deserialize_group_by_type(data, CharacterCollection)
	
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		if not (node is ItemCollection) and not (node is CharacterCollection):
			node.Deserialize(data[node.name])
	
	#_restore_equipped_gear()
	
	print ("Full data from load:\n\n", data)

func _deserialize_group_by_type(data: Dictionary, type) -> void:
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		if (is_instance_of(node, type)):
			node.Deserialize(data[node.name])

#func DeleteSave(p_slot: int) -> void:
	#pass

func BuildMetaData(p_slot: int) -> Dictionary:
	if(_active_profile_name.is_empty()):
		var data = GetSlotMetadata(p_slot)
		if (data.has("profile_name")):
			_active_profile_name = data["profile_name"]
	
	return {
		"profile_name": _active_profile_name,
		"saved_at": Time.get_datetime_string_from_system(),
		#"play_time_sec": _played_time,
		#"character_count": ...,   # queried from CharacterCollection
		#"highest_stage": ...      # queried from ProgressHandler
		}

func GetSlotMetadata(p_slot: int) -> Dictionary:
	if (not HasSaveSlot(p_slot)):
		print("There is no saved data for: ", "user://profile_" + str(p_slot) + ".save")
		return {}
	
	var save_file: FileAccess = FileAccess.open("user://profile_" + str(p_slot) + ".save", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(save_file.get_as_text())
	return data.get("meta", {})
