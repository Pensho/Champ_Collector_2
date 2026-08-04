extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the two resolution-level properties the Combined_Modifier channel must
# hold (Concept_Document.md 1.1.3-1.1.4, Plan_Combined_Modifier.md step 5): it multiplies
# the pre-mitigation scaled aggregate rather than final damage, and it is assembled fresh
# for every damage resolution rather than cached.

func _first_damage(p_results: Array[CombatResult]) -> int:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	return damage[0].amount if not damage.is_empty() else -1

func _damage_amounts(p_results: Array[CombatResult]) -> Array:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	return damage.map(func(r): return r.amount)

# --- Placement: the modifier multiplies the scaled aggregate, not final damage ---

func test_a_2x_modifier_against_a_defended_target_yields_strictly_more_than_2x_damage() -> void:
	var baseline_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	baseline_roster[0]._skills.append(TestFactory.make_strike_skill())
	baseline_roster[0]._attributes[Types.Attribute.Attack] = 800
	baseline_roster[3]._attributes[Types.Attribute.Defence] = 100
	baseline_roster[0]._attributes[Types.Attribute.CritChance] = 0
	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var baseline_damage: int = _first_damage(baseline_resolver.ResolveSkill(0, [3], 0))

	var buffed_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	buffed_roster[0]._skills.append(TestFactory.make_strike_skill())
	buffed_roster[0]._attributes[Types.Attribute.Attack] = 800
	buffed_roster[3]._attributes[Types.Attribute.Defence] = 100
	buffed_roster[0]._attributes[Types.Attribute.CritChance] = 0
	var daunting_strength: StatusEffects.Buff = StatusEffects.Buff.new()
	daunting_strength.type = Types.Buff_Type.Daunting_Strength
	daunting_strength.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Daunting_Strength).magnitude
	buffed_roster[0]._active_buffs.append(daunting_strength)
	var buffed_resolver: BattleResolver = TestFactory.make_resolver(buffed_roster, TestFactory.make_full_sides())
	var buffed_damage: int = _first_damage(buffed_resolver.ResolveSkill(0, [3], 0))

	assert_gt(buffed_damage, baseline_damage * 2,
		"A 2x Combined_Modifier also raises the mitigation ratio, so damage against a defended target " +
		"must land at strictly more than 2x baseline")

# --- Freshness: each damage resolution in one action assembles its own modifier ---

func _buffs_on_caster_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Twin Strike"
	var first_hit: DamageEffect = DamageEffect.new()
	first_hit.damage_scaling = {Types.Attribute.Attack: 1.0}
	first_hit.bonus_per = {Types.Trait_Count_Source.Buffs_On_Caster: 0.5}
	var consume: ConsumeBuffsEffect = ConsumeBuffsEffect.new()
	consume.target = Types.Skill_Target.Self
	consume.count = -1
	var second_hit: DamageEffect = DamageEffect.new()
	second_hit.damage_scaling = {Types.Attribute.Attack: 1.0}
	second_hit.bonus_per = {Types.Trait_Count_Source.Buffs_On_Caster: 0.5}
	skill.effects = [first_hit, consume, second_hit]
	return skill

func test_a_condition_consumed_between_two_resolutions_in_one_action_lowers_the_second() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._skills.append(_buffs_on_caster_skill())
	roster[0]._attributes[Types.Attribute.CritChance] = 0
	# Enough Health that neither hit is lethal, so both land and are counted.
	roster[3]._attributes[Types.Attribute.Health] = 1000
	roster[3]._current_health = 1000
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 5
	roster[0]._active_buffs.append(buff)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var amounts: Array = _damage_amounts(resolver.ResolveSkill(0, [3], 0))

	assert_eq(amounts.size(), 2, "Both hits of the skill should land")
	assert_gt(amounts[0], amounts[1],
		"The buff consumed between the two hits must not still pay out the second hit's own, freshly built modifier")
