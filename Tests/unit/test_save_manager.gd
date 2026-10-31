extends GutTest

const TEST_SLOT: int = 999
const TEST_DIRECTORY: String = "user://test_saves/"
const MAIN_MENU_SCRIPT = preload("res://Scripts/UI/main_menu.gd")
const ADVENTURE_PATH: String = "res://Data/Adventure_Data/Adventures/adventure_reclaimed_city_jungle.tres"

class CountingSaveManager extends SaveManager:
	var save_count: int = 0

	func Save(_p_slot: int) -> bool:
		save_count += 1
		return true

func _make_save_manager() -> SaveManager:
	var save_manager: SaveManager = SaveManager.new()
	add_child_autoqfree(save_manager)
	save_manager.UseSaveDirectory(TEST_DIRECTORY)
	return save_manager

func _write_file(p_path: String, p_text: String) -> void:
	var file: FileAccess = FileAccess.open(p_path, FileAccess.WRITE)
	file.store_string(p_text)
	file.close()

func _read_silver_saved_in(p_path: String) -> int:
	return int(JSON.parse_string(FileAccess.get_file_as_string(p_path))["meta"]["silver"])

func after_each() -> void:
	var cleaner: SaveManager = SaveManager.new()
	cleaner.UseSaveDirectory(TEST_DIRECTORY)
	for directory_name in DirAccess.get_directories_at(TEST_DIRECTORY):
		DirAccess.remove_absolute(TEST_DIRECTORY + directory_name)
	cleaner.EmptySaveDirectory()
	cleaner.free()
	DirAccess.remove_absolute(TEST_DIRECTORY)

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

func test_save_sets_active_and_last_active_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	assert_false(save_manager.HasActiveGame(), "A fresh session has no active slot")
	save_manager.Save(1)
	assert_eq(save_manager.GetActiveSlot(), 1)

	var next_session: SaveManager = _make_save_manager()
	assert_false(next_session.HasActiveGame(), "A launch leaves the active slot unset until the player picks a game")
	assert_eq(next_session.GetContinueSlot(), 1, "The last active slot survives into the next session")

func test_load_sets_active_slot_and_last_active_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(0)
	save_manager.Save(1)
	save_manager.Load(0)
	assert_eq(save_manager.GetActiveSlot(), 0)
	assert_eq(save_manager.GetContinueSlot(), 0)

func test_load_takes_the_profile_name_of_the_loaded_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager._active_profile_name = "First"
	save_manager.Save(0)
	save_manager._active_profile_name = "Second"
	save_manager.Save(1)
	save_manager.Load(0)
	assert_eq(save_manager.BuildMetaData(0)["profile_name"], "First")

func test_continue_slot_is_none_without_saves() -> void:
	assert_eq(_make_save_manager().GetContinueSlot(), SaveManager.NO_SLOT)

func test_continue_slot_falls_back_to_most_recently_saved_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	_write_file(save_manager._GetSlotPath(0), JSON.stringify({"meta": {"saved_at": "2026-01-01T00:00:00"}}))
	_write_file(save_manager._GetSlotPath(1), JSON.stringify({"meta": {"saved_at": "2026-06-01T00:00:00"}}))
	_write_file(save_manager._GetSlotPath(2), JSON.stringify({"meta": {"saved_at": "2026-03-01T00:00:00"}}))
	assert_eq(save_manager.GetContinueSlot(), 1, "With no last active slot, the newest save continues")

func test_continue_slot_falls_back_when_last_active_slot_is_deleted() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(0)
	save_manager.Save(1)
	save_manager.DeleteSave(1)
	assert_eq(save_manager.GetContinueSlot(), 0)
	assert_false(save_manager.HasActiveGame(), "Deleting the active slot unsets it")

func test_deleting_another_slot_keeps_the_active_slot() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(0)
	save_manager.Save(1)
	save_manager.DeleteSave(0)
	assert_eq(save_manager.GetActiveSlot(), 1)

func test_lowest_empty_slot_skips_used_slots() -> void:
	var save_manager: SaveManager = _make_save_manager()
	assert_eq(save_manager.GetLowestEmptySlot(), 0)
	save_manager.Save(0)
	assert_eq(save_manager.GetLowestEmptySlot(), 1)

func test_save_keeps_previous_version_as_backup() -> void:
	var save_manager: SaveManager = _make_save_manager()
	var resources: ResourceHandler = main.GetInstance()._resources
	var starting_silver: int = resources.GetSilver()
	save_manager.Save(TEST_SLOT)
	resources.AddSilver(5)
	save_manager.Save(TEST_SLOT)
	resources.AddSilver(-5)

	assert_eq(_read_silver_saved_in(save_manager._GetBackupPath(TEST_SLOT)), starting_silver)
	assert_eq(_read_silver_saved_in(save_manager._GetSlotPath(TEST_SLOT)), starting_silver + 5)
	assert_false(FileAccess.file_exists(save_manager._GetTemporaryPath(TEST_SLOT)),
		"A finished save leaves no temporary file behind")

func test_failed_write_preserves_the_previous_save() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(TEST_SLOT)
	var saved_text: String = FileAccess.get_file_as_string(save_manager._GetSlotPath(TEST_SLOT))
	# A directory at the temporary path makes the write fail.
	DirAccess.make_dir_absolute(save_manager._GetTemporaryPath(TEST_SLOT))

	assert_false(save_manager.Save(TEST_SLOT), "A failed write reports failure")
	assert_eq(FileAccess.get_file_as_string(save_manager._GetSlotPath(TEST_SLOT)), saved_text)

func test_leftover_temporary_file_does_not_block_saving() -> void:
	var save_manager: SaveManager = _make_save_manager()
	_write_file(save_manager._GetTemporaryPath(TEST_SLOT), "{\"meta\": ")
	assert_true(save_manager.Save(TEST_SLOT))
	assert_false(save_manager._ReadSaveFile(save_manager._GetSlotPath(TEST_SLOT)).is_empty())

func test_load_uses_backup_when_slot_file_is_corrupt() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(TEST_SLOT)
	save_manager.Save(TEST_SLOT)
	_write_file(save_manager._GetSlotPath(TEST_SLOT), "{\"meta\": {\"silver\": 1")

	assert_true(save_manager.Load(TEST_SLOT), "A corrupt slot should load from its backup")
	assert_true(save_manager.GetSlotMetadata(TEST_SLOT).has("saved_at"))

func test_load_uses_backup_when_slot_file_is_missing() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(TEST_SLOT)
	save_manager.Save(TEST_SLOT)
	DirAccess.remove_absolute(save_manager._GetSlotPath(TEST_SLOT))

	assert_true(save_manager.HasSaveSlot(TEST_SLOT), "A backup alone still counts as a save")
	assert_true(save_manager.Load(TEST_SLOT))

func test_saving_over_a_corrupt_slot_keeps_the_good_backup() -> void:
	var save_manager: SaveManager = _make_save_manager()
	var resources: ResourceHandler = main.GetInstance()._resources
	var starting_silver: int = resources.GetSilver()
	save_manager.Save(TEST_SLOT)
	save_manager.Save(TEST_SLOT)
	_write_file(save_manager._GetSlotPath(TEST_SLOT), "{\"meta\": {\"silver\": 1")
	resources.AddSilver(5)
	save_manager.Save(TEST_SLOT)
	resources.AddSilver(-5)

	assert_eq(_read_silver_saved_in(save_manager._GetBackupPath(TEST_SLOT)), starting_silver)
	assert_eq(_read_silver_saved_in(save_manager._GetSlotPath(TEST_SLOT)), starting_silver + 5)

func test_load_fails_when_slot_and_backup_are_both_corrupt() -> void:
	var save_manager: SaveManager = _make_save_manager()
	_write_file(save_manager._GetSlotPath(TEST_SLOT), "not json")
	_write_file(save_manager._GetBackupPath(TEST_SLOT), "[]")
	assert_false(save_manager.Load(TEST_SLOT))
	assert_false(save_manager.HasActiveGame(), "A failed load must not make the slot active")

func test_delete_removes_slot_and_backup() -> void:
	var save_manager: SaveManager = _make_save_manager()
	save_manager.Save(TEST_SLOT)
	save_manager.Save(TEST_SLOT)
	assert_true(save_manager.DeleteSave(TEST_SLOT))
	assert_false(FileAccess.file_exists(save_manager._GetSlotPath(TEST_SLOT)))
	assert_false(FileAccess.file_exists(save_manager._GetBackupPath(TEST_SLOT)))

func test_autosave_without_active_slot_writes_nothing() -> void:
	var save_manager: CountingSaveManager = CountingSaveManager.new()
	add_child_autoqfree(save_manager)
	save_manager.RequestAutosave()
	await wait_physics_frames(2)
	assert_eq(save_manager.save_count, 0)

func test_autosave_coalesces_requests_within_a_frame() -> void:
	var save_manager: CountingSaveManager = CountingSaveManager.new()
	add_child_autoqfree(save_manager)
	save_manager._active_slot = TEST_SLOT
	save_manager.RequestAutosave()
	save_manager.RequestAutosave()
	save_manager.RequestAutosave()
	assert_eq(save_manager.save_count, 0, "The save waits for the end of the frame")
	await wait_physics_frames(2)
	assert_eq(save_manager.save_count, 1)

	save_manager.RequestAutosave()
	await wait_physics_frames(2)
	assert_eq(save_manager.save_count, 2, "A later request saves again")

func test_blank_saves_are_ignored_outside_the_editor() -> void:
	assert_eq(SaveManager.ResolveSaveDirectory(false, true), SaveManager.SAVE_DIR)

func test_blank_saves_setting_selects_the_blank_directory_in_the_editor() -> void:
	assert_eq(SaveManager.ResolveSaveDirectory(true, true), SaveManager.BLANK_SAVE_DIR)
	assert_eq(SaveManager.ResolveSaveDirectory(true, false), SaveManager.SAVE_DIR)

func test_emptying_refuses_the_real_save_directory() -> void:
	assert_false(SaveManager.CanEmptyDirectory(SaveManager.SAVE_DIR))
	assert_true(SaveManager.CanEmptyDirectory(SaveManager.BLANK_SAVE_DIR))

func test_emptying_removes_files_from_the_current_directory_only() -> void:
	var save_manager: SaveManager = _make_save_manager()
	var sibling_path: String = TEST_DIRECTORY + "sibling.save"
	_write_file(sibling_path, "sibling")
	save_manager.UseSaveDirectory(TEST_DIRECTORY + "emptied/")
	save_manager.Save(TEST_SLOT)
	save_manager.EmptySaveDirectory()
	assert_eq(DirAccess.get_files_at(TEST_DIRECTORY + "emptied/").size(), 0)
	assert_true(FileAccess.file_exists(sibling_path))

func test_top_button_text_follows_continue_slot() -> void:
	assert_eq(MAIN_MENU_SCRIPT.TopButtonText(SaveManager.NO_SLOT), "Start Game")
	assert_eq(MAIN_MENU_SCRIPT.TopButtonText(0), "Continue")

func test_loading_a_slot_with_no_run_clears_the_run_in_memory() -> void:
	var handler: AdventureStateHandler = AdventureStateHandler.new()
	handler._state.is_active = true
	handler.Deserialize({})
	assert_false(handler._state.is_active)
	handler.free()

func test_loading_a_run_does_not_fix_the_random_stream() -> void:
	var data: Dictionary = {"adventure_path": ADVENTURE_PATH, "generation_seed": 12345, "is_active": true}
	AdventureState.new().Deserialize(data)
	var first_roll: int = randi()
	AdventureState.new().Deserialize(data)
	assert_ne(randi(), first_roll, "Two loads of one run must not repeat later rolls")

func test_loading_a_run_rebuilds_the_same_map() -> void:
	var data: Dictionary = {"adventure_path": ADVENTURE_PATH, "generation_seed": 12345, "is_active": true}
	var first: AdventureState = AdventureState.new()
	first.Deserialize(data)
	var second: AdventureState = AdventureState.new()
	second.Deserialize(data)
	assert_eq(first.nodes.map(func(p_node: NodeData) -> int: return p_node.node_type),
		second.nodes.map(func(p_node: NodeData) -> int: return p_node.node_type))

func test_node_rewards_roll_the_same_for_one_node() -> void:
	var state: AdventureState = AdventureState.new()
	state._generation_seed = 777
	var node: NodeData = NodeData.new()
	node.index = 3
	var table: LootTable = LootTable.new()
	table._secondary_loot[LootManager.LootType.Silver] = 1
	table._secondary_loot[LootManager.LootType.Supplies] = 1
	table._secondary_loot[LootManager.LootType.Reagent] = 1

	table._budget = 5000
	state.DistributeNodeRewards(node, table, 5)
	var first_result: LootTable.DropResult = table._drop_result
	var roll_after_first: int = randi()

	table._budget = 5000
	state.DistributeNodeRewards(node, table, 5)
	assert_eq(table._drop_result._silver, first_result._silver)
	assert_eq(table._drop_result._supplies, first_result._supplies)
	assert_eq(table._drop_result._reagents, first_result._reagents)
	assert_ne(randi(), roll_after_first, "Rolling node rewards must not fix the random stream")

func test_start_new_game_replaces_everything_in_memory() -> void:
	var instance: Main_Instance = Main_Instance.new()
	instance._character_collection = CharacterCollection.new()
	instance._item_collection = ItemCollection.new()
	instance._reagent_collection = ReagentCollection.new()
	instance._resources = ResourceHandler.new()
	instance._progress = ProgressHandler.new()
	instance._shop = ShopHandler.new()
	instance._tally_board = TallyBoardHandler.new()
	instance._save_manager = SaveManager.new()
	instance._adventure_state_handler = AdventureStateHandler.new()
	for node: Node in [instance._character_collection, instance._item_collection, instance._reagent_collection,
			instance._resources, instance._progress, instance._shop, instance._tally_board,
			instance._save_manager, instance._adventure_state_handler]:
		instance.add_child(node)
	add_child_autoqfree(instance)

	var content_pool: ContentPool = GameModeRegistry.Active()
	instance._resources.AddSilver(content_pool.starting_silver + 99)
	instance._resources.AddTallies(7)
	instance._resources.IncrementFortunesFavorPity(FortuneFavorTier.TierType.BONE)
	instance._progress.RegisterEncounter("previous game")
	instance._shop._stock.append({"sold_out": true})
	instance._shop._restock_anchor_unix = 100
	instance._tally_board._offers.append({"sold_out": true})
	instance._tally_board._restock_anchor_unix = 100
	instance._item_collection._next_id = 40
	instance._character_collection._current_max_amount = 500
	instance._adventure_state_handler._state.is_active = true
	instance._save_manager._active_slot = 2
	instance._save_manager._active_profile_name = "Previous"

	instance.StartNewGame()

	assert_eq(instance._resources.GetSilver(), content_pool.starting_silver)
	assert_eq(instance._resources.GetTallies(), 0)
	assert_eq(instance._resources.GetFortunesFavorPity(FortuneFavorTier.TierType.BONE), 0)
	assert_true(instance._progress._stage_difficulty.is_empty())
	assert_true(instance._shop._stock.is_empty())
	assert_eq(instance._shop._restock_anchor_unix, 0)
	assert_true(instance._tally_board._offers.is_empty())
	assert_eq(instance._tally_board._restock_anchor_unix, 0)
	assert_eq(instance._item_collection._next_id, 0)
	assert_eq(instance._character_collection._current_max_amount, Game_Balance.COLLECTION_START_ROSTER_SIZE)
	assert_eq(instance._character_collection.Size(), content_pool.starting_champions.size())
	assert_false(instance._adventure_state_handler._state.is_active)
	assert_false(instance._save_manager.HasActiveGame())
	assert_eq(instance._save_manager._active_profile_name, "")
