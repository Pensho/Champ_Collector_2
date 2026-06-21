extends GutTest

# Guards against the Android bug where UI centering used get_window().size
# (physical OS-window pixels) instead of get_viewport_rect().size (logical
# canvas-space pixels), which spilled dialogs off-screen on Android.

func test_no_get_window_size_in_scripts() -> void:
	var offenders: Array = _scan_for_get_window_size("res://Scripts/")
	assert_eq(offenders.size(), 0, "get_window().size found in: " + str(offenders))

# Runs at test time from source (never from a packed Android build).
func _scan_for_get_window_size(path: String) -> Array:
	var hits: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return hits
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			hits.append_array(_scan_for_get_window_size(full_path))
		elif file_name.ends_with(".gd"):
			var contents := FileAccess.get_file_as_string(full_path)
			# Match actual API usage (get_window().size), not the bare words
			# in a comment, so explanatory comments don't trip the guard.
			if contents.contains("get_window().size"):
				hits.append(full_path)
		file_name = dir.get_next()
	return hits
