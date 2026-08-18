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
	# Holder's own basic (skill 0) stays the damage-less Idle skill from before_each, so
	# the counter fires but resolves nothing — this test is about the miss, not the counter.

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Attack_Missed).size(), 1)
	assert_eq(_results_of_kind(results, CombatResult.Kind.Damage).size(), 0)
	assert_eq(_roster[0]._active_buffs.size(), 0, "Premonition should be consumed after negating the hit")
	assert_eq(_roster[0]._current_health, _roster[0]._attributes[Types.Attribute.Health],
		"The negated hit must not have reduced the holder's Health")

func test_premonition_counter_damages_the_attacker_with_the_holders_basic() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[0]._skills[0] = TestFactory.make_strike_skill()
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	var counter_damage: Array[CombatResult] = _results_of_kind(results, CombatResult.Kind.Damage)
	assert_eq(counter_damage.size(), 1, "The negated attack should be answered by one counter hit")
	assert_eq(counter_damage[0].source_ID, 0, "The counter is dealt by the Premonition holder")
	assert_eq(counter_damage[0].target_ID, 3, "The counter targets the original attacker")
	assert_eq(_roster[0]._current_health, _roster[0]._attributes[Types.Attribute.Health],
		"The negated hit must not have reduced the holder's own Health")

func test_premonition_counter_resolves_the_basics_non_damage_effects() -> void:
	var basic: Skill = Skill.new()
	basic.name = "Fateful Glimpse"
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	var heal: HealthChangeEffect = HealthChangeEffect.new()
	heal.target = Types.Skill_Target.Most_Injured_Ally
	heal.scaling = {Types.Attribute.Attack: 1.0}
	heal.fraction = 0.0
	basic.effects = [damage, heal]
	_roster[0]._skills[0] = basic
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[1]._current_health = 1
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	_resolver.ResolveSkill(3, [0], 0)

	assert_gt(_roster[1]._current_health, 1, "The counter's heal should reach the most injured ally")

func test_premonition_counter_reads_and_advances_the_holders_use_count() -> void:
	var ramping: Skill = Skill.new()
	ramping.name = "Heap On"
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	damage.bonus_per = {Types.Trait_Count_Source.Uses_This_Battle: 0.2}
	ramping.effects = [damage]
	_roster[0]._skills[0] = ramping
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[3]._skills[0] = TestFactory.make_strike_skill()
	_roster[3]._current_health = 10000
	_roster[3]._attributes[Types.Attribute.Health] = 10000
	_roster[3]._attributes[Types.Attribute.Defence] = 0

	_resolver.ResolveSkill(0, [3], 0)
	_resolver.ResolveSkill(0, [3], 0)
	var health_before_counter: int = _roster[3]._current_health

	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_resolver.ResolveSkill(3, [0], 0)
	var counter_damage: int = health_before_counter - _roster[3]._current_health
	var health_before_normal_cast: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)
	var normal_cast_damage: int = health_before_normal_cast - _roster[3]._current_health

	assert_gt(counter_damage, 0, "The counter should have dealt damage")
	assert_gt(normal_cast_damage, counter_damage,
		"A normal cast made after the counter should ramp further, since the counter itself was a use")

func test_premonition_counter_runs_the_holders_skill_cast_trait_hook() -> void:
	_roster[0]._skills[0] = TestFactory.make_strike_skill()
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	var boosting_trait: TestFactory.FakeSkillCastTrait = TestFactory.FakeSkillCastTrait.new(2.0)
	_roster[0]._trait = boosting_trait
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	_resolver.ResolveSkill(3, [0], 0)

	assert_eq(boosting_trait.call_count, 1, "The counter should run the holder's Skill_Cast hook once")

func test_premonition_counter_costs_the_holder_nothing() -> void:
	var non_basic: Skill = TestFactory.make_empty_skill()
	non_basic.cooldown = 3
	_roster[0]._skills.append(non_basic)
	_roster[0]._skills[0] = TestFactory.make_strike_skill()
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Turn_Bar_Bump).filter(
		func(r: CombatResult) -> bool: return r.target_ID == 0).size(), 0,
		"The counter must not bump the holder's own turn bar")
	assert_eq(_roster[0]._skills[1].cooldown_left, 0, "The counter must not touch any of the holder's cooldowns")

func test_premonition_counters_from_both_holders_in_an_aoe() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[0]._skills[0] = TestFactory.make_strike_skill()
	_roster[1]._skills[0] = TestFactory.make_strike_skill()
	var aoe: Skill = TestFactory.make_strike_skill()
	aoe.target = Types.Skill_Target.All_Enemies
	_roster[3]._skills[0] = aoe

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0, 1], 0)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Attack_Missed).size(), 2)
	assert_eq(_results_of_kind(results, CombatResult.Kind.Damage).filter(
		func(r: CombatResult) -> bool: return r.target_ID == 3).size(), 2,
		"Each Premonition holder in the AoE should land its own counter on the attacker")

func test_mutual_premonition_terminates_once_both_buffs_are_spent() -> void:
	# Attacker (3) and holder (0) both carry Premonition: the original attack misses and
	# counters, the counter itself misses and counters back — but by the third resolution
	# both buffs are already consumed, so it lands rather than looping forever.
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_roster[0]._skills[0] = TestFactory.make_strike_skill()
	_roster[3]._skills[0] = TestFactory.make_strike_skill()

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Attack_Missed).size(), 2,
		"Each side's Premonition should negate one hit in the chain")
	assert_eq(_results_of_kind(results, CombatResult.Kind.Damage).size(), 1,
		"The chain should terminate once both buffs are spent, landing exactly one hit")
	assert_eq(_roster[0]._active_buffs.size(), 0)
	assert_eq(_roster[3]._active_buffs.size(), 0)

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

	var results: Array[CombatResult] = _resolver.GetStatusResolver().ApplyDebuff(0, template)

	assert_eq(_results_of_kind(results, CombatResult.Kind.Debuff_Blocked).size(), 1)
	assert_eq(_roster[0]._active_debuffs.size(), 0, "The blocked debuff must not land")
	assert_eq(_roster[0]._active_buffs.size(), 0, "Aegis should be consumed after blocking one debuff")

	_resolver.GetStatusResolver().ApplyDebuff(0, template)
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
