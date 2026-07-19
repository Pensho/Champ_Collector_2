extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the turn-bar bump gate: Anchor blocks any skill-driven push, Steadfast
# blocks only pushback, and the damage-taken reactions (Dead Weight, Battle Orders)
# route through that same gate (Concept_Document.md 3.2.3.1).

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

func _push_skill(p_turn_effect: float) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Push"
	skill.target = Types.Skill_Target.Single_Enemy
	skill.turn_effect = p_turn_effect
	return skill

func _bumps_for(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump and r.target_ID == p_target_ID)

func test_anchor_blocks_a_positive_turn_bar_bump() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Anchor))
	_roster[3]._skills.append(_push_skill(0.2))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 0).size(), 0, "Anchor should block a forward push")

func test_anchor_blocks_a_negative_turn_bar_bump() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Anchor))
	_roster[3]._skills.append(_push_skill(-0.2))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 0).size(), 0, "Anchor should block a backward push too")

func test_steadfast_blocks_only_a_backward_bump() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Steadfast))
	_roster[3]._skills.append(_push_skill(-0.2))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 0).size(), 0, "Steadfast should block a backward push")

func test_steadfast_allows_a_forward_bump() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Steadfast))
	_roster[3]._skills.append(_push_skill(0.2))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 0).size(), 1, "Steadfast should not block a forward push")

func test_dead_weight_bumps_the_holder_backward_on_taking_damage() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Dead_Weight))
	_roster[3]._skills.append(TestFactory.make_strike_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	var bumps: Array[CombatResult] = _bumps_for(results, 0)
	assert_eq(bumps.size(), 1, "Dead Weight should bump its holder once on taking damage")
	assert_almost_eq(bumps[0].fraction, -0.03, 0.0001, "Dead Weight should lose 3% turn bar")

func test_battle_orders_bumps_living_allies_forward_on_the_holders_damage_taken() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Battle_Orders))
	_roster[3]._skills.append(TestFactory.make_strike_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_bumps_for(results, 0).size(), 0, "Battle Orders bumps allies, not the holder")
	for ally_ID in [1, 2]:
		var bumps: Array[CombatResult] = _bumps_for(results, ally_ID)
		assert_eq(bumps.size(), 1, "Ally %d should be bumped once" % ally_ID)
		assert_almost_eq(bumps[0].fraction, 0.05, 0.0001, "Battle Orders should grant 5% turn bar")
