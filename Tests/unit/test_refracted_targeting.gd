extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Refracted: a holder's single-target skills redirect to a random living
# combatant on either side, even overriding an otherwise-invalid clicked target
# (Concept_Document.md 3.2.3.2).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

func test_refracted_redirects_single_enemy_targeting_even_for_an_invalid_click() -> void:
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Refracted))

	# 4 is on the same side as caster 3, so Single_Enemy would normally reject it.
	var target_IDs: Array[int] = _resolver.FindSkillTargets(4, 3, Types.Skill_Target.Single_Enemy)

	assert_eq(target_IDs.size(), 1, "Refracted should still produce exactly one target")
	assert_true(_roster.has(target_IDs[0]), "Redirected target should be a valid living combatant")

func test_refracted_redirects_single_ally_targeting_even_for_an_invalid_click() -> void:
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Refracted))

	# 0 is an enemy of caster 3, so Single_Ally would normally reject it.
	var target_IDs: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Single_Ally)

	assert_eq(target_IDs.size(), 1, "Refracted should still produce exactly one target")
	assert_true(_roster.has(target_IDs[0]), "Redirected target should be a valid living combatant")

func test_non_single_target_skills_are_unaffected_by_refracted() -> void:
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Refracted))

	var target_IDs: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.All_Enemies)

	assert_eq(target_IDs, [0, 1, 2], "All_Enemies should resolve normally, untouched by Refracted")

func test_without_refracted_targeting_resolves_normally() -> void:
	var target_IDs: Array[int] = _resolver.FindSkillTargets(4, 3, Types.Skill_Target.Single_Enemy)

	assert_eq(target_IDs, [], "Without Refracted, an invalid same-side click should be rejected")
