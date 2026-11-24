extends GutTest

const PIRATE_COVES_ACT_PATH: String = "res://Data/Adventure_Data/Acts/act_pirate_coves.tres"

var _progress: ProgressHandler

func before_each() -> void:
	_progress = ProgressHandler.new()

func after_each() -> void:
	_progress.free()

func test_new_progress_starts_in_the_starting_act() -> void:
	assert_eq(_progress.GetCurrentAct(), ProgressHandler.STARTING_ACT)

func test_current_act_survives_a_save_round_trip() -> void:
	_progress.SetCurrentAct(load(PIRATE_COVES_ACT_PATH))
	var restored: ProgressHandler = ProgressHandler.new()
	restored.Deserialize(_progress.Serialize())
	assert_eq(restored.GetCurrentAct().resource_path, PIRATE_COVES_ACT_PATH)
	restored.free()

func test_save_without_a_current_act_falls_back_to_the_starting_act() -> void:
	_progress.SetCurrentAct(load(PIRATE_COVES_ACT_PATH))
	_progress.Deserialize({"stage_difficulty": {}})
	assert_eq(_progress.GetCurrentAct(), ProgressHandler.STARTING_ACT,
		"A save from before acts were tracked should resume in the starting act.")

func test_missing_act_path_falls_back_to_the_starting_act() -> void:
	assert_eq(ProgressHandler.ActFromPath("res://Data/Adventure_Data/Acts/act_removed.tres"),
		ProgressHandler.STARTING_ACT)

func test_path_to_a_non_act_resource_falls_back_to_the_starting_act() -> void:
	assert_eq(ProgressHandler.ActFromPath("res://Data/Sound_Cues/Sound_Cue_Profiles/button_standard.tres"),
		ProgressHandler.STARTING_ACT)

func test_reset_returns_to_the_starting_act() -> void:
	_progress.SetCurrentAct(load(PIRATE_COVES_ACT_PATH))
	_progress.Reset()
	assert_eq(_progress.GetCurrentAct(), ProgressHandler.STARTING_ACT)
