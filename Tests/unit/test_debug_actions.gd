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

