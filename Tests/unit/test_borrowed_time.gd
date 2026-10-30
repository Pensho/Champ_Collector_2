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

func test_the_repeat_names_the_cast_skill_it_echoes() -> void:
	_grant_borrowed_time(0, 0.5)
	_roster[0]._skills.append(TestFactory.make_strike_skill())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	var brackets: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Cascade_Triggered)
	assert_eq(brackets.size(), 1)
	assert_eq(brackets[0].skill_ID, 0, "A skill echo names the caster's skill index")
	assert_eq(brackets[0].debuff_type, Types.Debuff_Type.Invalid)

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

# --- The replay repeats what the cast consumed or read ---

func _plain_skill(p_name: String) -> Skill:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.name = p_name
	skill.effects[0].allow_critical = false
	return skill

func _assert_full_strength_replay(p_results: Array[CombatResult], p_message: String) -> void:
	var damage_results: Array[CombatResult] = _damage_results(p_results, 3)
	assert_eq(damage_results.size(), 2)
	# The damage-variance roll can move a full-strength replay by a point or two.
	assert_almost_eq(damage_results[1].amount, damage_results[0].amount, 2, p_message)

func test_replay_repeats_a_three_steel_reckoning() -> void:
	var corsair: TidalCorsairTrait = TidalCorsairTrait.new()
	corsair.Init(Types.Rarity.Legendary)
	_roster[0]._trait = corsair
	for i in 3:
		corsair.OnSkillCast(0, [], "Boarding Strike", {}, _resolver)
	_grant_borrowed_time(0, 1.0)
	_roster[0]._skills.append(_plain_skill("Corsairs Reckoning"))

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	_assert_full_strength_replay(results, "The replay should keep the Steel the cast spent")
	assert_eq(corsair._held_stacks[0], TidalCorsairTrait.Stack_Type.Empty, "The replay must not refill the hand")

func test_replay_repeats_the_bonus_for_buffs_consumed_without_consuming_again() -> void:
	var skill: Skill = _plain_skill("Devour")
	skill.effects[0].bonus_per[Types.Trait_Count_Source.Buffs_Consumed] = 0.25
	var consume: ConsumeBuffsEffect = ConsumeBuffsEffect.new()
	consume.target = Types.Skill_Target.Most_Buffed_Ally
	skill.effects.push_front(consume)
	_roster[0]._skills.append(skill)
	for buff_type: Types.Buff_Type in [Types.Buff_Type.Fortify, Types.Buff_Type.Haste, Types.Buff_Type.Empower]:
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = buff_type
		buff.duration = 3
		_resolver.GetStatusResolver().ApplyBuff(1, buff)
	_grant_borrowed_time(0, 1.0)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	_assert_full_strength_replay(results, "The replay should keep the per-buff bonus")
	assert_gt(_damage_results(results, 3)[0].amount, 8, "The cast should have consumed buffs")

func test_replay_repeats_a_consumed_daunting_strength() -> void:
	_roster[0]._skills.append(_plain_skill("Strike"))
	var plain_results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)
	var plain_damage: int = _damage_results(plain_results, 3)[0].amount
	_roster[3]._current_health = _roster[3]._attributes[Types.Attribute.Health]
	var daunting_strength: StatusEffects.Buff = StatusEffects.Buff.new()
	daunting_strength.type = Types.Buff_Type.Daunting_Strength
	daunting_strength.duration = 1
	daunting_strength.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Daunting_Strength).magnitude
	_resolver.GetStatusResolver().ApplyBuff(0, daunting_strength)
	_grant_borrowed_time(0, 1.0)

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	_assert_full_strength_replay(results, "The replay should keep the Daunting Strength the cast spent")
	assert_gt(_damage_results(results, 3)[1].amount, plain_damage, "The replay should carry the doubling")
	assert_false(_roster[0]._active_buffs.any(
			func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Daunting_Strength == b.type))

func test_replay_on_several_targets_repeats_a_daunting_strength_on_one_hit() -> void:
	var skill: Skill = _plain_skill("Sweep")
	skill.target = Types.Skill_Target.All_Enemies
	_roster[0]._skills.append(skill)
	var daunting_strength: StatusEffects.Buff = StatusEffects.Buff.new()
	daunting_strength.type = Types.Buff_Type.Daunting_Strength
	daunting_strength.duration = 1
	daunting_strength.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Daunting_Strength).magnitude
	_resolver.GetStatusResolver().ApplyBuff(0, daunting_strength)
	_grant_borrowed_time(0, 1.0)
	for target_ID: int in [3, 4, 5]:
		_roster[target_ID]._current_health = 1000

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3, 4, 5], 0)

	assert_gt(_damage_results(results, 3)[1].amount, _damage_results(results, 4)[1].amount,
			"Only the replay's first hit should repeat the doubling, as only the cast's first hit had it")

func test_replay_repeats_the_use_count_ramp() -> void:
	var skill: Skill = _plain_skill("Ramp")
	skill.effects[0].bonus_per[Types.Trait_Count_Source.Uses_This_Battle] = 1.0
	_roster[0]._skills.append(skill)
	_resolver.ResolveSkill(0, [3], 0)
	_grant_borrowed_time(0, 1.0)

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	_assert_full_strength_replay(results, "The replay should keep the cast's own ramp")

func test_replay_repeats_a_charge_span_bonus_with_one_recoil() -> void:
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.sections_by_character = {0: 0, 3: 2}
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), positions)
	var lancer: LancerTrait = LancerTrait.new()
	lancer.Init(Types.Rarity.Legendary)
	_roster[0]._trait = lancer
	var skill: Skill = _plain_skill("Rending Charge")
	skill.effects[0].bonus_per[Types.Trait_Count_Source.Turn_Bar_Section_Span] = 1.0
	_roster[0]._skills.append(skill)
	_grant_borrowed_time(0, 1.0)

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	_assert_full_strength_replay(results, "The replay should keep the section span the cast read")
	var bumps: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Turn_Bar_Bump == r.kind and 0 == r.target_ID)
	assert_eq(bumps.size(), 1, "The replay must not throw the Lancer back again")
