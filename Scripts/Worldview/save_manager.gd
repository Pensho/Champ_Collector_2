class_name SaveManager extends Node

const GROUP_SAVEABLE: String = "saveable"
const SAVE_DIR: String = "user://"
const BLANK_SAVE_DIR: String = "user://blank_saves/"
## Editor-only development switch: every launch starts from an empty BLANK_SAVE_DIR.
const BLANK_SAVES_SETTING: String = "champ_collector/build/use_blank_saves"
const SLOT_COUNT: int = 3
const NO_SLOT: int = -1
const LAST_ACTIVE_FILE_NAME: String = "last_active_slot.cfg"
const LAST_ACTIVE_SECTION: String = "save"
const LAST_ACTIVE_KEY: String = "last_active_slot"

var _active_profile_name: String
var _save_directory: String = SAVE_DIR
var _active_slot: int = NO_SLOT
var _is_autosave_pending: bool = false

static func ResolveSaveDirectory(p_is_editor: bool, p_use_blank_saves: bool) -> String:
	if (p_is_editor and p_use_blank_saves):
		return BLANK_SAVE_DIR
	return SAVE_DIR

func PrepareSaveDirectory() -> void:
	UseSaveDirectory(ResolveSaveDirectory(
			OS.has_feature("editor"), bool(ProjectSettings.get_setting(BLANK_SAVES_SETTING, false))))
	if (_save_directory == BLANK_SAVE_DIR):
		EmptySaveDirectory()

func UseSaveDirectory(p_directory: String) -> void:
	_save_directory = p_directory
	DirAccess.make_dir_recursive_absolute(_save_directory)

static func CanEmptyDirectory(p_directory: String) -> bool:
	return p_directory != SAVE_DIR

func EmptySaveDirectory() -> void:
	if (not CanEmptyDirectory(_save_directory)):
		return
	for file_name in DirAccess.get_files_at(_save_directory):
		DirAccess.remove_absolute(_save_directory + file_name)

func _GetSlotPath(p_slot: int) -> String:
	return _save_directory + "profile_" + str(p_slot) + ".save"

func _GetBackupPath(p_slot: int) -> String:
	return _GetSlotPath(p_slot) + ".backup"

func _GetTemporaryPath(p_slot: int) -> String:
	return _GetSlotPath(p_slot) + ".temporary"

func _GetLastActivePath() -> String:
	return _save_directory + LAST_ACTIVE_FILE_NAME

func HasSaveSlot(p_slot: int) -> bool:
	return FileAccess.file_exists(_GetSlotPath(p_slot)) or FileAccess.file_exists(_GetBackupPath(p_slot))

func HasActiveGame() -> bool:
	return _active_slot != NO_SLOT

func GetActiveSlot() -> int:
	return _active_slot

## Forgets the slot and profile the session was tied to; the save files stay.
func ClearSession() -> void:
	_active_slot = NO_SLOT
	_active_profile_name = ""

## The slot Continue loads: the last active one, else the most recently saved one.
func GetContinueSlot() -> int:
	var last_active_slot: int = _ReadLastActiveSlot()
	if (last_active_slot != NO_SLOT and HasSaveSlot(last_active_slot)):
		return last_active_slot

	var newest_slot: int = NO_SLOT
	var newest_saved_at: String = ""
	for slot in SLOT_COUNT:
		if (not HasSaveSlot(slot)):
			continue
		var saved_at: String = str(GetSlotMetadata(slot).get("saved_at", ""))
		if (newest_slot == NO_SLOT or saved_at > newest_saved_at):
			newest_slot = slot
			newest_saved_at = saved_at
	return newest_slot

func GetLowestEmptySlot() -> int:
	for slot in SLOT_COUNT:
		if (not HasSaveSlot(slot)):
			return slot
	return NO_SLOT

func Save(p_slot: int) -> bool:
	var data := {}
	data["meta"] = BuildMetaData(p_slot)
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		data[node.name] = node.Serialize()

	if (not _WriteSlotFile(p_slot, JSON.stringify(data, "\t"))):
		return false

	_SetActiveSlot(p_slot)
	return true

## Writes beside the slot and swaps the finished file in, so an interrupted write never
## touches the slot itself. The slot's previous version becomes its backup, unless it is
## unreadable: that would replace a good backup with a damaged file.
func _WriteSlotFile(p_slot: int, p_text: String) -> bool:
	var temporary_path: String = _GetTemporaryPath(p_slot)
	var save_file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if (not save_file):
		return false

	var is_written: bool = save_file.store_string(p_text) and save_file.get_error() == OK
	save_file.close()
	if (not is_written):
		DirAccess.remove_absolute(temporary_path)
		return false

	var slot_path: String = _GetSlotPath(p_slot)
	if (not _ReadSaveFile(slot_path).is_empty()
			and DirAccess.rename_absolute(slot_path, _GetBackupPath(p_slot)) != OK):
		return false
	return DirAccess.rename_absolute(temporary_path, slot_path) == OK

## Coalesces every request made within a frame into one save of the active slot.
func RequestAutosave() -> void:
	if (not HasActiveGame() or _is_autosave_pending):
		return
	_is_autosave_pending = true
	_FlushAutosave.call_deferred()

func _FlushAutosave() -> void:
	_is_autosave_pending = false
	if (not HasActiveGame()):
		return
	if (not Save(_active_slot)):
		Notification_Handler.Notify("Could not save the game", Types.Notification_Kind.Failure)

func Load(p_slot: int) -> bool:
	var data: Dictionary = _ReadSaveFile(_GetSlotPath(p_slot))
	var is_from_backup: bool = data.is_empty()
	if (is_from_backup):
		data = _ReadSaveFile(_GetBackupPath(p_slot))
	if (data.is_empty()):
		return false

	# Items must load before characters so gear can be re-equipped
	_deserialize_group_by_type(data, ItemCollection)
	_deserialize_group_by_type(data, CharacterCollection)

	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		if not (node is ItemCollection) and not (node is CharacterCollection):
			node.Deserialize(data.get(node.name, {}))

	#_restore_equipped_gear()

	_active_profile_name = str(data["meta"].get("profile_name", ""))
	_SetActiveSlot(p_slot)
	if (is_from_backup):
		Notification_Handler.Notify("Your save was damaged, so its previous version was restored")
	return true

## An empty result means the file is missing, unreadable, or not a whole save.
func _ReadSaveFile(p_path: String) -> Dictionary:
	if (not FileAccess.file_exists(p_path)):
		return {}

	var save_file: FileAccess = FileAccess.open(p_path, FileAccess.READ)
	if (not save_file):
		return {}

	var json: JSON = JSON.new()
	if (json.parse(save_file.get_as_text()) != OK or not (json.data is Dictionary)):
		return {}
	var data: Dictionary = json.data
	if (not (data.get("meta") is Dictionary)):
		return {}
	return data

func _deserialize_group_by_type(data: Dictionary, type) -> void:
	for node in get_tree().get_nodes_in_group(GROUP_SAVEABLE):
		if (is_instance_of(node, type)):
			node.Deserialize(data.get(node.name, {}))

func DeleteSave(p_slot: int) -> bool:
	if (not HasSaveSlot(p_slot)):
		return false

	for path: String in [_GetSlotPath(p_slot), _GetBackupPath(p_slot), _GetTemporaryPath(p_slot)]:
		if (FileAccess.file_exists(path)):
			DirAccess.remove_absolute(path)
	if (HasSaveSlot(p_slot)):
		return false

	if (_active_slot == p_slot):
		ClearSession()
	if (_ReadLastActiveSlot() == p_slot):
		DirAccess.remove_absolute(_GetLastActivePath())
	return true

func BuildMetaData(p_slot: int) -> Dictionary:
	if(_active_profile_name.is_empty() and p_slot != _active_slot):
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
	var data: Dictionary = _ReadSaveFile(_GetSlotPath(p_slot))
	if (data.is_empty()):
		data = _ReadSaveFile(_GetBackupPath(p_slot))
	return data.get("meta", {})

func _SetActiveSlot(p_slot: int) -> void:
	_active_slot = p_slot
	if (_ReadLastActiveSlot() == p_slot):
		return
	var config: ConfigFile = ConfigFile.new()
	config.set_value(LAST_ACTIVE_SECTION, LAST_ACTIVE_KEY, p_slot)
	config.save(_GetLastActivePath())

func _ReadLastActiveSlot() -> int:
	var config: ConfigFile = ConfigFile.new()
	if (config.load(_GetLastActivePath()) != OK):
		return NO_SLOT
	return int(config.get_value(LAST_ACTIVE_SECTION, LAST_ACTIVE_KEY, NO_SLOT))
