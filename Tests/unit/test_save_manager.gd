extends GutTest

const TEST_SLOT: int = 999

func _make_save_manager() -> SaveManager:
	var save_manager: SaveManager = SaveManager.new()
	add_child_autoqfree(save_manager)
	return save_manager

func after_each() -> void:
	var path: String = SaveManager.SAVE_DIR + "profile_" + str(TEST_SLOT) + ".save"
	if (FileAccess.file_exists(path)):
		DirAccess.remove_absolute(path)

func test_load_on_missing_slot_returns_false() -> void:
	var save_manager: SaveManager = _make_save_manager()
	assert_false(save_manager.Load(TEST_SLOT), "Loading a slot with no save file should return false")

func test_save_then_load_round_trip_returns_true() -> void:
	var save_manager: SaveManager = _make_save_manager()
	assert_true(save_manager.Save(TEST_SLOT), "Saving to a fresh slot should return true")
	assert_true(save_manager.Load(TEST_SLOT), "Loading a slot that was just saved should return true")
