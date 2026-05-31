extends GutTest

# Guards against the Android bug where biomes were discovered with a res://
# DirAccess directory scan (fails on packed exports). Also verifies the biome
# list actually populates.

func test_no_diraccess_in_scripts() -> void:
	var offenders: Array = _scan_for_diraccess("res://Scripts/")
	assert_eq(offenders.size(), 0, "DirAccess found in: " + str(offenders))

func test_biomes_preloaded() -> void:
	var script := load("res://Scripts/UI/Adventure/pre_adventure_menu.gd")
	var biomes: Array = script.BIOME_RESOURCES
	assert_gt(biomes.size(), 0, "BIOME_RESOURCES should not be empty.")
	for biome in biomes:
		assert_true(biome is BiomeData, "Every BIOME_RESOURCES entry should be a BiomeData.")

# Runs at test time from source (never from a packed Android build), so using
# DirAccess here is fine — it is exactly what we are asserting the game code
# does not do at runtime.
func _scan_for_diraccess(path: String) -> Array:
	var hits: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return hits
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			hits.append_array(_scan_for_diraccess(full_path))
		elif file_name.ends_with(".gd"):
			var contents := FileAccess.get_file_as_string(full_path)
			# Match actual API usage (DirAccess.open(...), etc.), not the bare
			# word in a comment, so explanatory comments don't trip the guard.
			if contents.contains("DirAccess."):
				hits.append(full_path)
		file_name = dir.get_next()
	return hits
