extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for GameBalance.MAX_STATUS_EFFECTS: the shared buff/debuff pool blocks a new
# status once full, and reports the drop instead of dropping it silently.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _fill_status_pool(p_target_ID: int) -> void:
	var buff_types: Array = Types.Buff_Type.values()
	for i in GameBalance.MAX_STATUS_EFFECTS:
		var filler: StatusEffects.Buff = StatusEffects.Buff.new()
		filler.type = buff_types[i + 1]
		filler.duration = 5
		_roster[p_target_ID]._active_buffs.append(filler)

func _results_of_kind(p_results: Array[CombatResult], p_kind: CombatResult.Kind) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == p_kind)

func test_buff_denied_when_pool_is_full() -> void:
	_fill_status_pool(0)
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Haste
	buff.duration = 2

	var results: Array[CombatResult] = _resolver.GetStatusResolver().ApplyBuff(0, buff)

	var denied: Array[CombatResult] = _results_of_kind(results, CombatResult.Kind.Status_Effect_Denied)
	assert_eq(denied.size(), 1)
	assert_true(denied[0].is_buff)
	assert_eq(denied[0].buff_type, Types.Buff_Type.Haste)
	assert_eq(denied[0].target_ID, 0)
	assert_eq(_roster[0]._active_buffs.size(), GameBalance.MAX_STATUS_EFFECTS,
		"The denied buff must not land")

func test_debuff_denied_when_pool_is_full() -> void:
	_fill_status_pool(0)
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Slow
	debuff.duration = 2
	debuff.source_ID = 3

	var results: Array[CombatResult] = _resolver.GetStatusResolver().ApplyDebuff(0, debuff)

	var denied: Array[CombatResult] = _results_of_kind(results, CombatResult.Kind.Status_Effect_Denied)
	assert_eq(denied.size(), 1)
	assert_false(denied[0].is_buff)
	assert_eq(denied[0].debuff_type, Types.Debuff_Type.Slow)
	assert_true(_roster[0]._active_debuffs.is_empty(), "The denied debuff must not land")

func test_status_lands_normally_below_the_cap() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Haste
	buff.duration = 2

	var results: Array[CombatResult] = _resolver.GetStatusResolver().ApplyBuff(0, buff)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Status_Effect_Denied).size(), 0)
	assert_eq(_roster[0]._active_buffs.size(), 1)
