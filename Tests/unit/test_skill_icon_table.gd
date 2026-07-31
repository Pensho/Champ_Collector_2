extends GutTest

## Verifies the placeholder icon generator's SKILL_ICON_TABLE is well-formed: the
## expected number of rows, unique folders and base names, valid row shape, and every
## folder rooted under one of the three ability subfolders. Guards against duplicate or
## malformed rows as skills are added to the table.

const GENERATOR_PATH: String = "res://Scripts/Debug/generate_placeholder_icons.gd"
const EXPECTED_ROW_COUNT: int = 67
const ALLOWED_PREFIXES: Array = [
	"Abilities/Role_Active_Skills/",
	"Abilities/Opponent_Active_Skills/",
	"Abilities/Passives/",
]

var _table: Array = []


func before_all() -> void:
	var generator: GDScript = load(GENERATOR_PATH)
	_table = generator.get_script_constant_map()["SKILL_ICON_TABLE"]


func test_expected_row_count() -> void:
	assert_eq(_table.size(), EXPECTED_ROW_COUNT, "SKILL_ICON_TABLE row count changed")


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


func test_folders_use_ability_subfolder_and_match_base_name() -> void:
	for row in _table:
		var folder: String = row["folder"]
		var base_name: String = row["base_name"]
		var has_allowed_prefix: bool = false
		for prefix in ALLOWED_PREFIXES:
			if folder.begins_with(prefix):
				has_allowed_prefix = true
				break
		assert_true(has_allowed_prefix, "folder outside ability subfolders: %s" % folder)
		assert_eq(folder.get_file(), base_name, "folder leaf must match base_name: %s" % folder)
