extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Stun's turn-skip path and Fatigue's cooldown freeze
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

func test_resolve_stun_turn_decrements_and_clears_a_one_turn_stun() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Stun, 1))

	var results: Array[CombatResult] = _resolver.ResolveStunTurn(0)

	assert_eq(_roster[0]._active_debuffs.size(), 0, "A 1-turn Stun should clear itself after the skipped turn")
	assert_eq(results.filter(func(r): return r.kind == CombatResult.Kind.Turn_Skipped).size(), 1,
		"ResolveStunTurn should report the skip")

func test_resolve_stun_turn_still_ticks_other_debuffs() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Stun, 1))
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Burning, 2))
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveStunTurn(0)

	assert_true(_roster[0]._current_health < health_before,
		"A Stunned character should still suffer their other debuff ticks (e.g. Burning)")

func test_fatigue_blocks_the_cooldown_decrement() -> void:
	var idle: Skill = TestFactory.make_empty_skill()
	var on_cooldown: Skill = TestFactory.make_empty_skill()
	on_cooldown.cooldown = 3
	on_cooldown.cooldown_left = 2
	_roster[0]._skills = [idle, on_cooldown]
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Fatigue))

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._skills[1].cooldown_left, 2, "Fatigue should block the cooldown decrement")

func test_cooldowns_tick_down_normally_without_fatigue() -> void:
	var idle: Skill = TestFactory.make_empty_skill()
	var on_cooldown: Skill = TestFactory.make_empty_skill()
	on_cooldown.cooldown = 3
	on_cooldown.cooldown_left = 2
	_roster[0]._skills = [idle, on_cooldown]

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._skills[1].cooldown_left, 1, "Cooldowns should tick down normally without Fatigue")
