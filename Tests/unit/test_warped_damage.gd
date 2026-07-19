extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Warped: a caster's damage scaling is redirected entirely onto
# Mysticism instead of the skill's normal attribute (Concept_Document.md 3.2.3.2).
# Damage only, per the catalog's own open question about broader forcing.

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

func _damage_amount(p_results: Array[CombatResult]) -> int:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	return damage[0].amount if not damage.is_empty() else 0

func test_warped_redirects_damage_scaling_to_the_lower_mysticism() -> void:
	var without_warped: Dictionary = TestFactory.make_full_roster()
	without_warped[3]._attributes[Types.Attribute.Attack] = 100
	without_warped[3]._attributes[Types.Attribute.Mysticism] = 5
	without_warped[3]._skills.append(TestFactory.make_strike_skill())
	var resolver_a: BattleResolver = TestFactory.make_resolver(without_warped, TestFactory.make_full_sides())
	var results_a: Array[CombatResult] = resolver_a.ResolveSkill(3, [0], 0)

	var with_warped: Dictionary = TestFactory.make_full_roster()
	with_warped[3]._attributes[Types.Attribute.Attack] = 100
	with_warped[3]._attributes[Types.Attribute.Mysticism] = 5
	with_warped[3]._skills.append(TestFactory.make_strike_skill())
	with_warped[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Warped))
	var resolver_b: BattleResolver = TestFactory.make_resolver(with_warped, TestFactory.make_full_sides())
	var results_b: Array[CombatResult] = resolver_b.ResolveSkill(3, [0], 0)

	assert_true(_damage_amount(results_b) < _damage_amount(results_a),
		"Warped should redirect scaling from Attack (100) to the much lower Mysticism (5)")

func test_without_warped_damage_scales_with_the_skills_own_attribute() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[3]._attributes[Types.Attribute.Attack] = 100
	roster[3]._attributes[Types.Attribute.Mysticism] = 5
	roster[3]._skills.append(TestFactory.make_strike_skill())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = resolver.ResolveSkill(3, [0], 0)

	assert_true(_damage_amount(results) > 0, "Damage should scale with Attack as normal")
