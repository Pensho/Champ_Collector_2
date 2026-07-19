extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the consume-on-trigger buffs: each blocks or negates exactly one
# incoming event, then removes itself (Concept_Document.md 3.2.3.2).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _results_of_kind(p_results: Array[CombatResult], p_kind: CombatResult.Kind) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == p_kind)

func test_premonition_negates_one_hit_then_is_removed() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Attack_Missed).size(), 1)
	assert_eq(_results_of_kind(results, CombatResult.Kind.Damage).size(), 0)
	assert_eq(_roster[0]._active_buffs.size(), 0, "Premonition should be consumed after negating the hit")
	assert_eq(_roster[0]._current_health, _roster[0]._attributes[Types.Attribute.Health],
		"The negated hit must not have reduced the holder's Health")

func test_deathward_clamps_a_fatal_hit_to_one_health_then_is_removed() -> void:
	_roster[0]._current_health = 1
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Deathward))
	_roster[3]._attributes[Types.Attribute.Attack] = 999
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_roster[0]._current_health, 1, "Deathward must clamp a fatal hit to 1 Health")
	assert_eq(_roster[0]._active_buffs.size(), 0, "Deathward should be consumed after saving its holder")
	assert_eq(_results_of_kind(results, CombatResult.Kind.Death).size(), 0, "The holder must not die")

func test_aegis_blocks_one_debuff_then_is_removed() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Aegis))
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Enfeeble
	template.duration = 2
	template.source_ID = 3

	var results: Array[CombatResult] = _resolver.ApplyDebuff(0, template)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Debuff_Blocked).size(), 1)
	assert_eq(_roster[0]._active_debuffs.size(), 0, "The blocked debuff must not land")
	assert_eq(_roster[0]._active_buffs.size(), 0, "Aegis should be consumed after blocking one debuff")

	_resolver.ApplyDebuff(0, template)
	assert_eq(_roster[0]._active_debuffs.size(), 1, "A second debuff should land normally once Aegis is gone")

func test_rehearsed_skips_one_non_basic_cooldown_then_is_removed() -> void:
	var non_basic: Skill = TestFactory.make_empty_skill()
	non_basic.cooldown = 3
	_roster[0]._skills[0] = non_basic
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Rehearsed))

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._skills[0].cooldown_left, 0, "Rehearsed should skip the cooldown assignment")
	assert_eq(_roster[0]._active_buffs.size(), 0, "Rehearsed should be consumed after skipping one cooldown")

	_resolver.ResolveSkill(0, [], 0)
	assert_eq(_roster[0]._skills[0].cooldown_left, 3, "A second non-basic cast should set cooldown normally")
