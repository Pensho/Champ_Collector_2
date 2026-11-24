class_name ProgressHandler extends Node

const STARTING_ACT: ActData = preload("res://Data/Adventure_Data/Acts/act_reclaimed_city.tres")

var _stage_difficulty: Dictionary[String, int]
var _current_act: ActData = STARTING_ACT

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

func Serialize() -> Dictionary:
	return {
		"stage_difficulty": _stage_difficulty.duplicate(true),
		"current_act": _current_act.resource_path,
	}

func Deserialize(p_data: Dictionary) -> void:
	_current_act = ActFromPath(p_data.get("current_act", ""))

	if(not p_data.has("stage_difficulty")):
		print("No stage difficulty found in save slot.")
		return

	_stage_difficulty.clear()
	for key in p_data["stage_difficulty"]:
		_stage_difficulty[key] = int(p_data["stage_difficulty"][key])

func Reset() -> void:
	_stage_difficulty.clear()
	_current_act = STARTING_ACT

## A missing or unreadable path (an older save, a removed act) falls back to the starting act.
static func ActFromPath(p_path: String) -> ActData:
	if(p_path.is_empty() or not ResourceLoader.exists(p_path)):
		return STARTING_ACT
	var act: ActData = load(p_path) as ActData
	return act if act != null else STARTING_ACT

func GetCurrentAct() -> ActData:
	return _current_act

func SetCurrentAct(p_act: ActData) -> void:
	_current_act = p_act

func RegisterEncounter(p_encounter_ID: String) -> void:
	print("RegisterEncounter for: ", p_encounter_ID)
	if (_stage_difficulty.has(p_encounter_ID)):
		return
	_stage_difficulty[p_encounter_ID] = 1

func GetCurrentEncounterDifficulty(p_encounter_ID: String) -> int:
	if (!_stage_difficulty.has(p_encounter_ID)):
		RegisterEncounter(p_encounter_ID)
	print("GetCurrentEncounterDifficulty for: ", p_encounter_ID, " has difficulty: ", _stage_difficulty[p_encounter_ID])
	return _stage_difficulty[p_encounter_ID]

func GetHighestDifficulty() -> int:
	if (_stage_difficulty.is_empty()):
		return 1
	return _stage_difficulty.values().max()

func MarkDifficultyCompleted(p_encounter_ID: String, p_difficulty: int) -> void:
	if (!_stage_difficulty.has(p_encounter_ID)):
		RegisterEncounter(p_encounter_ID)
		return
	if (_stage_difficulty[p_encounter_ID] > p_difficulty):
		return
	if (_stage_difficulty[p_encounter_ID] >= Game_Balance.MAX_DIFFICULTY):
		_stage_difficulty[p_encounter_ID] = Game_Balance.MAX_DIFFICULTY
		return
	_stage_difficulty[p_encounter_ID] = _stage_difficulty[p_encounter_ID] + 1
	
