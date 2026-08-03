extends GutTest

## Verifies the placeholder icon generator's CREATURE_PLACEHOLDER_TABLE is well-formed:
## the expected number of rows, unique folders and base names, and valid row shape.
## Guards against duplicate or malformed rows as opponent bodies are added.

const GENERATOR_PATH: String = "res://Scripts/Debug/generate_placeholder_icons.gd"
const EXPECTED_ROW_COUNT: int = 19

var _table: Array = []


func before_all() -> void:
	var generator: GDScript = load(GENERATOR_PATH)
	_table = generator.get_script_constant_map()["CREATURE_PLACEHOLDER_TABLE"]


func test_expected_row_count() -> void:
	assert_eq(_table.size(), EXPECTED_ROW_COUNT, "CREATURE_PLACEHOLDER_TABLE row count changed")


func test_rows_have_valid_shape() -> void:
	for row in _table:
		assert_true(row is Dictionary, "row is not a Dictionary")
		assert_true(row.has("folder") and row["folder"] is String, "row missing String folder")
		assert_true(
				row.has("base_name") and row["base_name"] is String, "row missing String base_name")
		assert_true(row.has("size") and row["size"] is int, "row missing int size")
		assert_true(row.has("color") and row["color"] is Color, "row missing Color color")


func test_folders_are_unique() -> void:
	var seen: Dictionary = {}
	for row in _table:
		var folder: String = row["folder"]
		assert_false(seen.has(folder), "duplicate folder: %s" % folder)
		seen[folder] = true


func test_base_names_are_unique() -> void:
	var seen: Dictionary = {}
	for row in _table:
		var base_name: String = row["base_name"]
		assert_false(seen.has(base_name), "duplicate base_name: %s" % base_name)
		seen[base_name] = true


func test_folders_match_base_name() -> void:
	for row in _table:
		assert_eq(row["folder"], row["base_name"], "folder must match base_name: %s" % row["folder"])
