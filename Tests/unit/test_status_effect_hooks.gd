extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for status-effect primitives supporting turn-bar grafts: the Buff_Applied
# dispatch now passes the applied buff, a new receiver-side Debuff_Received event fires
# on the debuff's target, CastDebuff rolls a resist before landing a template debuff, and
# GetIncomingDebuffDurationBonus extends a landing debuff's duration.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

# --- Buff_Applied passes the applied buff ---

func test_buff_applied_hook_receives_the_applied_buff_instance() -> void:
	var recorder: TestFactory.FakeBuffGainedRecorder = TestFactory.FakeBuffGainedRecorder.new()
	_roster[0]._trait = recorder
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var buff: StatusEffects.Buff = _buff(Types.Buff_Type.Empower)

	_resolver.GetStatusResolver().ApplyBuff(0, buff)

	assert_eq(recorder.call_count, 1)
	assert_eq(recorder.last_owner_ID, 0)
	assert_eq(recorder.last_buff.type, Types.Buff_Type.Empower)

# --- Debuff_Received fires on the target, distinct from applier-side Debuff_Applied ---

func test_debuff_received_hook_fires_on_the_target_with_the_landed_debuff() -> void:
	var recorder: TestFactory.FakeDebuffReceivedRecorder = TestFactory.FakeDebuffReceivedRecorder.new()
	_roster[0]._trait = recorder
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var debuff: StatusEffects.Debuff = _debuff(Types.Debuff_Type.Enfeeble)
	debuff.source_ID = 3

	_resolver.GetStatusResolver().ApplyDebuff(0, debuff)

	assert_eq(recorder.call_count, 1)
	assert_eq(recorder.last_owner_ID, 0, "The hook should fire on the receiver, not the applier")
	assert_eq(recorder.last_debuff.type, Types.Debuff_Type.Enfeeble)

func test_debuff_received_does_not_fire_on_the_applier() -> void:
	var recorder: TestFactory.FakeDebuffReceivedRecorder = TestFactory.FakeDebuffReceivedRecorder.new()
	_roster[3]._trait = recorder
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var debuff: StatusEffects.Debuff = _debuff(Types.Debuff_Type.Enfeeble)
	debuff.source_ID = 3

	_resolver.GetStatusResolver().ApplyDebuff(0, debuff)

	assert_eq(recorder.call_count, 0)

# --- CastDebuff (the resist-rolled "attempt"; ApplyDebuff always lands unconditionally) ---

func test_cast_debuff_lands_when_accuracy_dominates_resistance() -> void:
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[0]._attributes[Types.Attribute.Resistance] = 1
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.GetStatusResolver().CastDebuff(0, _debuff(Types.Debuff_Type.Enfeeble), 3)

	assert_eq(_roster[0]._active_debuffs.size(), 1, "The debuff should land when Accuracy dominates")

func test_cast_debuff_is_resisted_when_resistance_dominates_accuracy() -> void:
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1
	_roster[0]._attributes[Types.Attribute.Resistance] = 1000
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.GetStatusResolver().CastDebuff(
			0, _debuff(Types.Debuff_Type.Enfeeble), 3)

	assert_eq(_roster[0]._active_debuffs.size(), 0, "The debuff should not land when Resistance dominates")
	var resisted: Array[CombatResult] = results.filter(
			func(r): return r.kind == CombatResult.Kind.Debuff_Resisted)
	assert_eq(resisted.size(), 1, "A Debuff_Resisted result should be emitted")

func test_apply_debuff_still_skips_the_resist_roll() -> void:
	_roster[0]._attributes[Types.Attribute.Resistance] = 1000
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.GetStatusResolver().ApplyDebuff(0, _debuff(Types.Debuff_Type.Enfeeble))

	assert_eq(_roster[0]._active_debuffs.size(), 1, "ApplyDebuff's own contract is unconditional application")

# --- GetIncomingDebuffDurationBonus ---

func test_incoming_debuff_duration_bonus_extends_a_landing_debuff() -> void:
	_roster[0]._trait = TestFactory.FakeDebuffDurationBonusTrait.new(2)
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.GetStatusResolver().ApplyDebuff(0, _debuff(Types.Debuff_Type.Enfeeble, 3))

	assert_eq(_roster[0]._active_debuffs[0].duration, 5, "3-turn debuff + 2-turn bonus should land at 5")

func test_incoming_debuff_duration_bonus_does_not_affect_buffs() -> void:
	_roster[0]._trait = TestFactory.FakeDebuffDurationBonusTrait.new(2)
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.GetStatusResolver().ApplyBuff(0, _buff(Types.Buff_Type.Empower, 3))

	assert_eq(_roster[0]._active_buffs[0].duration, 3, "The bonus is debuff-only and must not touch buffs")

func test_no_duration_bonus_for_a_normal_character() -> void:
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.GetStatusResolver().ApplyDebuff(0, _debuff(Types.Debuff_Type.Enfeeble, 3))

	assert_eq(_roster[0]._active_debuffs[0].duration, 3, "A character without the trait is unaffected")
