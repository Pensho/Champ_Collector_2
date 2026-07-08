extends GutTest

# Regression coverage for the shared-Skill-resource defect: Character.InstantiateNew
# must give every Character its own Skill instances, so mutating one character's
# cooldown never leaks to a sibling instance or back to the source preset.

func _make_preset_with_skill() -> CharacterPreset:
	var preset: CharacterPreset = CharacterPreset.new()
	preset._name = "SkillIsolationDummy"
	var skill: Skill = Skill.new()
	skill.name = "TestSkill"
	skill.cooldown = 3
	preset._skills = [skill]
	return preset

func test_two_instances_do_not_share_skill_state() -> void:
	var preset: CharacterPreset = _make_preset_with_skill()
	var first: Character = Character.new()
	var second: Character = Character.new()
	first.InstantiateNew(preset, 0)
	second.InstantiateNew(preset, 1)

	first._skills[0].cooldown_left = 2

	assert_eq(second._skills[0].cooldown_left, 0,
		"A sibling instance must not share cooldown_left with the mutated character")

func test_instance_does_not_mutate_source_preset() -> void:
	var preset: CharacterPreset = _make_preset_with_skill()
	var character: Character = Character.new()
	character.InstantiateNew(preset, 0)

	character._skills[0].cooldown_left = 2

	assert_eq(preset._skills[0].cooldown_left, 0,
		"Mutating a character's skill must not write back to the preset resource")
	assert_ne(character._skills[0], preset._skills[0],
		"A character's skill must be a distinct instance from the preset's skill")
