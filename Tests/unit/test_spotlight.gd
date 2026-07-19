extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Spotlight's damage-reduction half: the holder takes 10% less damage
# (Concept_Document.md 3.2.3.2). The targeting-weight half is dormant, deferred to
# the enemy-AI targeting work.

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _damage_amount(p_results: Array[CombatResult]) -> int:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	return damage[0].amount if not damage.is_empty() else 0

func test_spotlight_reduces_incoming_damage_by_ten_percent() -> void:
	var baseline: Dictionary = TestFactory.make_full_roster()
	baseline[3]._skills.append(TestFactory.make_strike_skill())
	var resolver_a: BattleResolver = TestFactory.make_resolver(baseline, TestFactory.make_full_sides())
	var results_a: Array[CombatResult] = resolver_a.ResolveSkill(3, [0], 0)

	var spotlighted: Dictionary = TestFactory.make_full_roster()
	spotlighted[3]._skills.append(TestFactory.make_strike_skill())
	spotlighted[0]._active_buffs.append(_buff(Types.Buff_Type.Spotlight))
	var resolver_b: BattleResolver = TestFactory.make_resolver(spotlighted, TestFactory.make_full_sides())
	var results_b: Array[CombatResult] = resolver_b.ResolveSkill(3, [0], 0)

	var damage_without: int = _damage_amount(results_a)
	var damage_with: int = _damage_amount(results_b)
	assert_almost_eq(float(damage_with), float(damage_without) * 0.9, 1.0,
		"Spotlight should reduce incoming damage by 10%")
