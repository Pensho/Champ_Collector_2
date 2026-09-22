extends GutTest

func after_each() -> void:
	GameModeRegistry.ClearPin()

func _make_preset(p_name: String) -> CharacterPreset:
	var preset: CharacterPreset = CharacterPreset.new()
	preset._name = p_name
	return preset

func _make_pool(p_starting: Array[CharacterPreset],
		p_recruitable: Array[CharacterPreset]) -> ContentPool:
	var pool: ContentPool = ContentPool.new()
	pool.starting_champions = p_starting
	pool.recruitable_champions = p_recruitable
	return pool

func test_player_presets_come_from_the_active_pool() -> void:
	var starter: CharacterPreset = _make_preset("Starter")
	var recruit: CharacterPreset = _make_preset("Recruit")
	GameModeRegistry.PinForTest(_make_pool([starter], [recruit]))
	var presets: Dictionary[String, CharacterPreset] = DebugCatalog.GetPlayerCharacterPresets()
	assert_eq(presets.size(), 2, "Both the starting and the recruitable champions should appear")
	assert_eq(presets.get("Starter"), starter)
	assert_eq(presets.get("Recruit"), recruit)

func test_player_presets_exclude_champions_the_mode_omits() -> void:
	GameModeRegistry.PinForTest(_make_pool([], [_make_preset("Recruit")]))
	assert_false(DebugCatalog.GetPlayerCharacterPresets().has("Starter"),
			"A champion outside the active pool should not be offered by the debug page")

func test_player_presets_list_a_champion_in_both_lists_once() -> void:
	var champion: CharacterPreset = _make_preset("Champion")
	GameModeRegistry.PinForTest(_make_pool([champion], [champion]))
	assert_eq(DebugCatalog.GetPlayerCharacterPresets().size(), 1)
