extends GutTest

# Verifies the biome list actually populates.

func test_biomes_preloaded() -> void:
	var script := load("res://Scripts/UI/Adventure/pre_adventure_menu.gd")
	var biomes: Array = script.BIOME_RESOURCES
	assert_gt(biomes.size(), 0, "BIOME_RESOURCES should not be empty.")
	for biome in biomes:
		assert_true(biome is BiomeData, "Every BIOME_RESOURCES entry should be a BiomeData.")
