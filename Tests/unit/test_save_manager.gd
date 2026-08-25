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

func test_delete_save_on_missing_slot_returns_false() -> void:
	var save_manager: SaveManager = _make_save_manager()
	assert_false(save_manager.DeleteSave(TEST_SLOT), "Deleting a slot with no save file should return false")

func test_delete_save_after_saving_removes_the_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(TEST_SLOT)
	assert_true(save_manager.DeleteSave(TEST_SLOT), "Deleting a slot that was just saved should return true")
	assert_false(save_manager.HasSaveSlot(TEST_SLOT), "The slot should no longer exist after deletion")

func test_build_metadata_includes_profile_name_and_stat_snapshot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager._active_profile_name = "Test Profile"
	var meta: Dictionary = save_manager.BuildMetaData(TEST_SLOT)

	assert_eq(meta["profile_name"], "Test Profile")
	assert_true(meta.has("saved_at"))
	assert_true(meta.has("highest_difficulty"))
	assert_true(meta.has("character_count"))
	assert_true(meta.has("character_capacity"))
	assert_true(meta.has("highest_character_level"))
	assert_true(meta.has("unique_characters"))
	assert_true(meta.has("silver"))
	assert_true(meta.has("supplies"))

func test_build_metadata_backfills_profile_name_from_existing_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager._active_profile_name = "Backfilled Name"
	save_manager.Save(TEST_SLOT)

	var fresh_save_manager: SaveManager = _make_save_manager()
	var meta: Dictionary = fresh_save_manager.BuildMetaData(TEST_SLOT)

	assert_eq(meta["profile_name"], "Backfilled Name",
		"BuildMetaData should recover the profile name from the existing slot when none is active")

func test_get_slot_metadata_on_missing_slot_returns_empty_dictionary() -> void:
	var save_manager: SaveManager = _make_save_manager()
	assert_eq(save_manager.GetSlotMetadata(TEST_SLOT), {})
