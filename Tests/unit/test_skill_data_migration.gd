extends GutTest

# Every shipped skill resource must load and carry at least one effect, so a skill can
# never silently regress to doing nothing.

const SKILL_ROOT: String = "res://Data/Character_Skill_Variants"

func test_every_shipped_skill_loads_and_carries_at_least_one_effect() -> void:
	var paths: Array[String] = []
	_collect_tres_paths(SKILL_ROOT, paths)
	assert_gt(paths.size(), 0, "Sanity check: the skill directory scan should find files")
	for path in paths:
		var skill: Skill = load(path)
		assert_not_null(skill, "%s should load as a Skill resource" % path)
		assert_gt(skill.effects.size(), 0, "%s should carry at least one effect" % path)

func _collect_tres_paths(p_dir_path: String, p_out: Array[String]) -> void:
	var dir := DirAccess.open(p_dir_path)
	assert_not_null(dir, "Could not open directory: " + p_dir_path)
	if null == dir:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while "" != entry:
		if not entry.begins_with("."):
			var full_path: String = "%s/%s" % [p_dir_path, entry]
			if dir.current_is_dir():
				_collect_tres_paths(full_path, p_out)
			elif entry.ends_with(".tres"):
				p_out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
