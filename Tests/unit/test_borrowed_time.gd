extends GutTest

## The Borrowed Time buff (Time Tithe's second half): its holder's next
## damaging skill resolves once more at the buff's own fraction, then the buff is gone.
## Grant-side gating (the alone-in-section clause) is covered by test_time_tithe_trait.gd.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _grant_borrowed_time(p_character_ID: int, p_fraction: float) -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Borrowed_Time
	buff.name = "Borrowed Time"
	buff.duration = 1
	buff.value = p_fraction
	_resolver.GetStatusResolver().ApplyBuff(p_character_ID, buff)

func _has_borrowed_time(p_character_ID: int) -> bool:
	for buff in _roster[p_character_ID]._active_buffs:
		if(Types.Buff_Type.Borrowed_Time == buff.type):
			return true
	return false

func _damage_results(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == p_target_ID)

func test_next_damaging_skill_resolves_twice() -> void:
	_grant_borrowed_time(0, 0.5)
	_roster[0]._skills.append(TestFactory.make_strike_skill())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	assert_eq(_damage_results(results, 3).size(), 2,
			"A held Borrowed Time should resolve the next damaging skill's DamageEffect twice")

func test_the_repeat_is_a_depth_1_cascade_instance() -> void:
	_grant_borrowed_time(0, 0.5)
	_roster[0]._skills.append(TestFactory.make_strike_skill())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	var damage_results: Array[CombatResult] = _damage_results(results, 3)
	assert_eq(damage_results[1].cascade_depth, 1, "The repeat is a depth-1 cascade instance")

func test_the_buff_is_consumed_and_does_not_fire_on_a_later_cast() -> void:
	_grant_borrowed_time(0, 0.5)
	_roster[0]._skills.append(TestFactory.make_strike_skill())

	_resolver.ResolveSkill(0, [3], 0)
	assert_false(_has_borrowed_time(0), "Borrowed Time should be consumed by the extra resolution")

	# Restore the target's Health so a second cast can still land — the first cast's
	# double hit is otherwise enough to kill it outright, which would confound "no
	# damage landed" with "the target was already dead".
	_roster[3]._current_health = _roster[3]._attributes[Types.Attribute.Health]
	var second_results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)
	assert_eq(_damage_results(second_results, 3).size(), 1,
			"A second cast with no Borrowed Time held must resolve only once")

func test_a_second_application_does_not_stack_into_two_extra_resolutions() -> void:
	_grant_borrowed_time(0, 0.5)
	_grant_borrowed_time(0, 0.5)
	assert_eq(_roster[0]._active_buffs.filter(
			func(b): return Types.Buff_Type.Borrowed_Time == b.type).size(), 1,
			"Borrowed Time is not stackable and refreshes in place")
	_roster[0]._skills.append(TestFactory.make_strike_skill())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	assert_eq(_damage_results(results, 3).size(), 2, "Two applications should still yield only one extra resolution")

func test_a_non_damaging_skill_consumes_nothing() -> void:
	_grant_borrowed_time(0, 0.5)
	_roster[0]._skills.append(TestFactory.make_empty_skill())

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_has_borrowed_time(0),
			"Casting a non-damaging skill must leave a held Borrowed Time for a later damaging one")
