extends GutTest

# HandleEnemyTurn() falls back to skill slot 0 when no higher-index skill is
# off cooldown. That fallback is only safe if slot 0 never has a cooldown, so
# this locks in the invariant across every CharacterPreset resource.

const PRESET_DIRECTORIES: Array[String] = [
	"res://Data/Character_Player_Variants/",
	"res://Data/Character_Enemy_Variants/",
]

func test_slot_zero_skill_has_no_cooldown() -> void:
	for directory in PRESET_DIRECTORIES:
		var dir := DirAccess.open(directory)
		assert_not_null(dir, "Could not open directory: " + directory)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var preset: CharacterPreset = load(directory.path_join(file_name))
				if preset._skills.size() > 0:
					assert_eq(preset._skills[0].cooldown, 0,
						"%s: skill slot 0 (%s) must have cooldown 0" % [file_name, preset._skills[0].name])
			file_name = dir.get_next()
