extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Regression coverage for an emit-before-apply ordering bug: BattleResolver.result_produced
# fires synchronously and drives Battle.UpdateLifeBar immediately, so any health-changing
# CombatResult (Damage, Debuff_Tick, Heal) must be emitted AFTER the character's
# _current_health is actually mutated — emitting first left the life bar reading stale
# health until that character was touched again by a later event.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _captures: Array[Dictionary] = []

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_captures.clear()
	_resolver.result_produced.connect(_capture_health_at_emit)

func _capture_health_at_emit(p_result: CombatResult) -> void:
	if(_roster.has(p_result.target_ID)):
		_captures.append({
			"kind": p_result.kind,
			"target_ID": p_result.target_ID,
			"health": _roster[p_result.target_ID]._current_health,
		})

func _health_at_emit(p_kind: CombatResult.Kind, p_target_ID: int) -> int:
	for capture in _captures:
		if(capture["kind"] == p_kind and capture["target_ID"] == p_target_ID):
			return capture["health"]
	return -1

func test_damage_result_reports_health_already_reduced() -> void:
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	var health_before: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	assert_lt(_health_at_emit(CombatResult.Kind.Damage, 3), health_before,
		"Health must already be reduced when the Damage result fires")
	assert_eq(_health_at_emit(CombatResult.Kind.Damage, 3), _roster[3]._current_health,
		"The health at emit time should match the final health")

func test_debuff_tick_result_reports_health_already_reduced() -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Burning
	debuff.duration = 2
	debuff.source_ID = 1
	_roster[0]._active_debuffs.append(debuff)
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveSkill(0, [], 0)

	assert_lt(_health_at_emit(CombatResult.Kind.Debuff_Tick, 0), health_before,
		"Health must already be reduced when the Debuff_Tick result fires")
	assert_eq(_health_at_emit(CombatResult.Kind.Debuff_Tick, 0), _roster[0]._current_health,
		"The health at emit time should match the final health")

func test_exhert_self_cost_damage_result_reports_health_already_reduced() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Exhert
	buff.duration = 4
	_roster[0]._active_buffs.append(buff)
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	assert_lt(_health_at_emit(CombatResult.Kind.Damage, 0), health_before,
		"Health must already be reduced when Exhert's self-cost Damage result fires")
	assert_eq(_health_at_emit(CombatResult.Kind.Damage, 0), _roster[0]._current_health,
		"The health at emit time should match the final health")

func test_temporal_leak_tick_result_reports_health_already_reduced() -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Temporal_Leak
	debuff.duration = 2
	_roster[0]._active_debuffs.append(debuff)
	_roster[0]._attributes[Types.Attribute.Speed] = 20
	var health_before: int = _roster[0]._current_health

	_resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION)

	assert_lt(_health_at_emit(CombatResult.Kind.Debuff_Tick, 0), health_before,
		"Health must already be reduced when Temporal Leak's Debuff_Tick result fires")
	assert_eq(_health_at_emit(CombatResult.Kind.Debuff_Tick, 0), _roster[0]._current_health,
		"The health at emit time should match the final health")

func test_heal_result_reports_health_already_increased() -> void:
	_roster[0]._current_health = 1
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Regeneration
	buff.duration = 2
	_roster[0]._active_buffs.append(buff)
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveSkill(0, [], 0)

	assert_gt(_health_at_emit(CombatResult.Kind.Heal, 0), health_before,
		"Health must already be increased when the Heal result fires")
	assert_eq(_health_at_emit(CombatResult.Kind.Heal, 0), _roster[0]._current_health,
		"The health at emit time should match the final health")
