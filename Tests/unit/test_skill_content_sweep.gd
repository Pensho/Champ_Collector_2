extends GutTest

# Loads every shipped skill resource and asserts every authored enum on it resolves —
# real content coverage that a test built from a hand-assembled replica Skill object
# would never touch.

const SKILL_ROOT: String = "res://Data/Character_Skill_Variants"

func test_every_shipped_skill_has_only_resolvable_enums() -> void:
	var paths: Array[String] = []
	_CollectTresPaths(SKILL_ROOT, paths)
	assert_gt(paths.size(), 0, "Sanity check: the skill directory scan should find files")
	for path in paths:
		var skill: Skill = load(path)
		for effect: SkillEffect in skill.effects:
			_AssertSkillTargetInRange(effect.target, path, "target")
			_AssertEnumInRange(Types.Skill_Condition, effect.condition, path, "condition")
			_AssertEnumInRange(Types.Condition_Test, effect.condition_test, path, "condition_test")
			if effect is ApplyBuffEffect:
				_AssertBuffResolves((effect as ApplyBuffEffect).buff_type, path)
			elif effect is ApplyDebuffEffect:
				_AssertDebuffResolves((effect as ApplyDebuffEffect).debuff_type, path)
			elif effect is StealBuffEffect:
				_AssertSkillTargetInRange((effect as StealBuffEffect).to, path, "to")
			elif effect is DamageEffect:
				for source: Types.Trait_Count_Source in (effect as DamageEffect).bonus_per:
					_AssertEnumInRange(Types.Trait_Count_Source, source, path, "bonus_per source")
				for debuff_type: Types.Debuff_Type in (effect as DamageEffect).bonus_per_debuff_on_target:
					_AssertDebuffResolves(debuff_type, path)

func _AssertSkillTargetInRange(p_target: Types.Skill_Target, p_path: String, p_field: String) -> void:
	_AssertEnumInRange(Types.Skill_Target, p_target, p_path, p_field)

func _AssertEnumInRange(p_enum: Dictionary, p_value: int, p_path: String, p_field: String) -> void:
	assert_true(p_enum.values().has(p_value), "%s: %s value %s is not a valid enum member" %
			[p_path, p_field, p_value])

func _AssertBuffResolves(p_buff_type: Types.Buff_Type, p_path: String) -> void:
	assert_ne(p_buff_type, Types.Buff_Type.Invalid, "%s: buff_type must not be Invalid" % p_path)
	assert_not_null(StatusEffectRegistry.BuffData(p_buff_type),
			"%s: buff_type %s has no StatusEffectRegistry entry" % [p_path, p_buff_type])

func _AssertDebuffResolves(p_debuff_type: Types.Debuff_Type, p_path: String) -> void:
	assert_ne(p_debuff_type, Types.Debuff_Type.Invalid, "%s: debuff_type must not be Invalid" % p_path)
	assert_not_null(StatusEffectRegistry.DebuffData(p_debuff_type),
			"%s: debuff_type %s has no StatusEffectRegistry entry" % [p_path, p_debuff_type])

func _CollectTresPaths(p_dir_path: String, p_out: Array[String]) -> void:
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
				_CollectTresPaths(full_path, p_out)
			elif entry.ends_with(".tres"):
				p_out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
