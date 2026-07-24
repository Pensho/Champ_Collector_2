extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func test_build_equipment_preset_sets_exact_attributes() -> void:
	var attributes: Dictionary[Types.Attribute, int] = {
		Types.Attribute.Defence: 12,
		Types.Attribute.Speed: 3,
	}
	var preset: EquipmentPreset = DebugActions.build_equipment_preset(
		"Debug Boots", Types.Slot.Boots, Types.Rarity.Epic, attributes)

	assert_eq(preset._name, "Debug Boots", "Preset should keep the requested name")
	assert_eq(preset._slot, Types.Slot.Boots, "Preset should keep the requested slot")
	assert_eq(preset._rarity, Types.Rarity.Epic, "Preset should keep the requested rarity")
	assert_eq(preset._attributes[Types.Attribute.Defence], 12, "Defence should be set exactly")
	assert_eq(preset._attributes[Types.Attribute.Speed], 3, "Speed should be set exactly")
	assert_eq(preset._attributes[Types.Attribute.Health], 0, "Untouched attributes should remain at their default")
	assert_ne(preset._texture_path, "", "Preset should have a usable texture path")

func test_build_battle_context_assembles_context_container() -> void:
	var player_characters: Array[Character] = [TestFactory.make_character()]
	var battle_context: Context_Battle = Context_Battle.new()

	var context: ContextContainer = DebugActions.build_battle_context(
		player_characters, battle_context, 5, "uid://previous_scene")

	assert_eq(context._scene, DebugCatalog.BATTLE_SCENE_UID, "Should target the battle scene")
	assert_eq(context._static_context, battle_context, "Should carry the chosen enemy wave")
	assert_eq(context._player_battle_characters, player_characters, "Should carry the chosen player characters")
	assert_eq(context._arguments["Difficulty"], 5, "Should set the requested difficulty")
	assert_eq(context._previous_scene, "uid://previous_scene", "Should carry the previous scene")

func _make_character_with_weights() -> Character:
	var c: Character = TestFactory.make_character()
	var weights: AttributeWeightPreset = AttributeWeightPreset.new()
	for attribute in weights._weights.keys():
		weights._weights[attribute] = 1
	c._attributes_weights = weights
	return c

func test_set_character_level_raises_level_and_attributes() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 1
	var attack_before: int = c._attributes[Types.Attribute.Attack]
	DebugActions.set_character_level(c, 2)
	assert_eq(c._level, 2, "Level should reach the target")
	assert_gt(c._attributes[Types.Attribute.Attack], attack_before,
		"Real level-up reward should increase an attribute")

func test_set_character_level_raises_multiple_levels() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 1
	DebugActions.set_character_level(c, 5)
	assert_eq(c._level, 5, "Level should reach the target after several level-ups")

func test_set_character_level_clamps_above_max_level() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 1
	DebugActions.set_character_level(c, Game_Balance.MAX_LEVEL + 50)
	assert_eq(c._level, Game_Balance.MAX_LEVEL, "Level should clamp at Game_Balance.MAX_LEVEL")

func test_set_character_level_lowering_is_raw_assignment() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 10
	var attack_before: int = c._attributes[Types.Attribute.Attack]
	DebugActions.set_character_level(c, 3)
	assert_eq(c._level, 3, "Lowering should set the level directly")
	assert_eq(c._attributes[Types.Attribute.Attack], attack_before,
		"Lowering should not touch attributes")

func test_set_character_level_same_level_is_noop() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 4
	var attack_before: int = c._attributes[Types.Attribute.Attack]
	DebugActions.set_character_level(c, 4)
	assert_eq(c._level, 4, "Setting the same level should be a no-op")
	assert_eq(c._attributes[Types.Attribute.Attack], attack_before,
		"No-op should not touch attributes")

