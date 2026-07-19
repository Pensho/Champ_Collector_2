extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Exhert: a batch-1-style AttributePercent buff (all primary attributes
# except Health, +20%) layered with self_tick_max_health_cost_percent, the new
# StatusEffectData field that lets a buff cost Health each self-tick independent of its
# magnitude_kind.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _exhert_buff() -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Exhert
	buff.duration = 4
	return buff

func test_exhert_raises_the_casters_own_damage_output() -> void:
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	var baseline: BattleResolver = TestFactory.make_resolver(
		TestFactory.make_full_roster(), TestFactory.make_full_sides())
	for id in baseline.GetCharacters().keys():
		baseline.GetCharacters()[id]._skills.append(TestFactory.make_strike_skill())
	baseline.GetCharacters()[0]._attributes[Types.Attribute.CritChance] = 0

	_roster[0]._active_buffs.append(_exhert_buff())
	var baseline_damage: int = _first_damage(baseline.ResolveSkill(0, [3], 0))
	var buffed_damage: int = _first_damage(_resolver.ResolveSkill(0, [3], 0))

	assert_gt(buffed_damage, baseline_damage, "Exhert's Attack bonus should raise the caster's own damage")

func test_exhert_costs_5_percent_max_health_on_the_holders_own_turn() -> void:
	var max_health: int = _roster[0]._attributes[Types.Attribute.Health] * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	_roster[0]._current_health = max_health
	_roster[0]._active_buffs.append(_exhert_buff())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	var expected_cost: int = int(ceil(max_health * 0.05))
	assert_eq(_roster[0]._current_health, max_health - expected_cost,
		"Exhert should cost 5% of max Health on the holder's own turn")
	var self_damage: Array = results.filter(
		func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 0 and r.amount == expected_cost)
	assert_eq(self_damage.size(), 1, "The self-cost should be reported as a Damage result")

func _first_damage(p_results: Array[CombatResult]) -> int:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.source_ID == 0)
	return damage[0].amount if not damage.is_empty() else -1
