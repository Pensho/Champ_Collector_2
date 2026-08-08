extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for DamageEffect.bonus_per's Target_Debuff_Count source (Outbreak): scales with
# the target's total distinct debuff-type count, any source, uncapped by design.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _debuff(p_type: Types.Debuff_Type) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = 2
	return debuff

func _outbreak_like_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Outbreak"
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Mysticism: 1.2}
	effect.bonus_per = {Types.Trait_Count_Source.Target_Debuff_Count: 0.08}
	skill.effects = [effect]
	return skill

func test_scales_with_the_targets_distinct_debuff_type_count() -> void:
	_roster[0]._skills.append(_outbreak_like_skill())
	var health_before_no_debuffs: int = _roster[3]._current_health
	_resolver.ResolveSkill(0, [3], 0)
	var damage_without_debuffs: int = health_before_no_debuffs - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Enfeeble))
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Suppress))
	_roster[0]._skills.append(_outbreak_like_skill())
	var health_before_with_debuffs: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	var damage_with_debuffs: int = health_before_with_debuffs - _roster[3]._current_health
	assert_gt(damage_with_debuffs, damage_without_debuffs,
		"More distinct debuff types on the target should increase damage")

func test_does_not_double_count_a_stacked_debuff_type() -> void:
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Plague))
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Plague))
	_roster[0]._skills.append(_outbreak_like_skill())
	var health_before_stacked: int = _roster[3]._current_health
	_resolver.ResolveSkill(0, [3], 0)
	var damage_with_stacked_plague: int = health_before_stacked - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Plague))
	_roster[0]._skills.append(_outbreak_like_skill())
	var health_before_single: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	var damage_with_single_plague: int = health_before_single - _roster[3]._current_health
	assert_eq(damage_with_stacked_plague, damage_with_single_plague,
		"Two stacks of the same debuff type must count as one distinct type, not two")

func test_uncapped_at_eight_distinct_types() -> void:
	var types: Array[Types.Debuff_Type] = [
		Types.Debuff_Type.Enfeeble, Types.Debuff_Type.Suppress, Types.Debuff_Type.Unravel,
		Types.Debuff_Type.Confound, Types.Debuff_Type.Hexed, Types.Debuff_Type.Blight,
		Types.Debuff_Type.Slow, Types.Debuff_Type.Plague,
	]
	for type in types:
		_roster[3]._active_debuffs.append(_debuff(type))
	_roster[0]._skills.append(_outbreak_like_skill())
	var health_before_eight: int = _roster[3]._current_health
	_resolver.ResolveSkill(0, [3], 0)
	var damage_with_eight: int = health_before_eight - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	for type in types.slice(0, 4):
		_roster[3]._active_debuffs.append(_debuff(type))
	_roster[0]._skills.append(_outbreak_like_skill())
	var health_before_four: int = _roster[3]._current_health
	_resolver.ResolveSkill(0, [3], 0)
	var damage_with_four: int = health_before_four - _roster[3]._current_health

	assert_gt(damage_with_eight, damage_with_four,
		"The bonus must keep scaling past any artificial cap, up to and beyond the shared 8-status cap")
