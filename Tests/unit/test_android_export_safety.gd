extends GutTest

# Static source scans guarding against Android packed-export bugs:
# - DirAccess directory scans fail on packed exports.
# - get_window().size returns physical OS-window pixels instead of logical
#   viewport pixels, which spilled dialogs off-screen on Android.

func test_no_diraccess_in_scripts() -> void:
	var offenders: Array = _scan_for_string("res://Scripts/", "DirAccess.")
	assert_eq(offenders.size(), 0, "DirAccess found in: " + str(offenders))

func test_no_get_window_size_in_scripts() -> void:
	var offenders: Array = _scan_for_string("res://Scripts/", "get_window().size")
	assert_eq(offenders.size(), 0, "get_window().size found in: " + str(offenders))

# Runs at test time from source (never from a packed Android build), so using
# DirAccess here is fine — it is exactly what we are asserting the game code
# does not do at runtime.
func _scan_for_string(path: String, needle: String) -> Array:
	var hits: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return hits
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			hits.append_array(_scan_for_string(full_path, needle))
		elif file_name.ends_with(".gd"):
			var contents := FileAccess.get_file_as_string(full_path)
			# Match actual API usage, not the bare words in a comment, so
			# explanatory comments don't trip the guard.
			if contents.contains(needle):
				hits.append(full_path)
		file_name = dir.get_next()
	return hits
