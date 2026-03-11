class_name ProgressHandler extends Node

var _stage_difficulty: Dictionary[String, int]

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

func Serialize() -> Dictionary:
	return {"stage_difficulty": _stage_difficulty.duplicate(true)}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("stage_difficulty")):
		print("No stage difficulty found in save slot.")
		return
	
	_stage_difficulty.clear()
	for key in p_data["stage_difficulty"]:
		_stage_difficulty[key] = int(p_data["stage_difficulty"][key])

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
	
