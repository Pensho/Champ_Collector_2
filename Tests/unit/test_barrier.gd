extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Barrier: a Health-loss pool consumed before Health itself, replaced
# by a reapplication only if the new value is larger (Concept_Document.md 3.2.3.2).
# Damage is delivered through Bleed's self-tick, since its tick amount is exactly
# derivable from the source's snapshotted Attack (see test_bleed_plague_ticks.gd).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _barrier_buff(p_value: float) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Barrier
	buff.duration = 2
	buff.value = p_value
	return buff

func _apply_self_bleed(p_target_ID: int, p_attack: int) -> int:
	_roster[p_target_ID]._attributes[Types.Attribute.Attack] = p_attack
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Bleed
	template.duration = 2
	template.source_ID = p_target_ID
	_resolver.ApplyDebuff(p_target_ID, template)
	return int(floor(p_attack * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Bleed).magnitude))

func test_damage_under_the_barrier_value_is_fully_absorbed() -> void:
	_roster[0]._active_buffs.append(_barrier_buff(50.0))
	var tick_damage: int = _apply_self_bleed(0, 100)  # 40 damage
	var health_before: int = _roster[0]._current_health

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._current_health, health_before, "Damage under the Barrier value must not touch Health")
	assert_eq(_roster[0]._active_buffs.size(), 1, "The Barrier should survive a hit smaller than its value")
	assert_almost_eq(_roster[0]._active_buffs[0].value, 50.0 - tick_damage, 0.0001)
	var absorbed: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Barrier_Absorbed)
	assert_eq(absorbed[0].amount, tick_damage)

func test_damage_exceeding_the_barrier_value_consumes_it_and_the_remainder_reaches_health() -> void:
	_roster[0]._active_buffs.append(_barrier_buff(5.0))
	var tick_damage: int = _apply_self_bleed(0, 30)  # 12 damage, less than the holder's 10 Health
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._current_health, health_before - (tick_damage - 5),
		"Only the remainder past the Barrier's value should reach Health")
	var remaining_barriers: Array = _roster[0]._active_buffs.filter(
		func(b): return b.type == Types.Buff_Type.Barrier)
	assert_eq(remaining_barriers.size(), 0, "An exhausted Barrier should be removed")

func test_apply_buff_keeps_the_existing_barrier_when_the_new_value_is_smaller() -> void:
	_roster[0]._active_buffs.append(_barrier_buff(50.0))
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Barrier
	template.duration = 2
	template.value = 30.0

	_resolver.ApplyBuff(0, template)

	assert_eq(_roster[0]._active_buffs.size(), 1)
	assert_almost_eq(_roster[0]._active_buffs[0].value, 50.0, 0.0001,
		"A smaller reapplication must not replace the larger existing Barrier")

func test_apply_buff_replaces_the_existing_barrier_when_the_new_value_is_larger() -> void:
	_roster[0]._active_buffs.append(_barrier_buff(50.0))
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Barrier
	template.duration = 2
	template.value = 80.0

	_resolver.ApplyBuff(0, template)

	assert_eq(_roster[0]._active_buffs.size(), 1)
	assert_almost_eq(_roster[0]._active_buffs[0].value, 80.0, 0.0001,
		"A larger reapplication must replace the existing Barrier")
