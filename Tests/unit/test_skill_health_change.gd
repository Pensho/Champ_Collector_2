extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Skill.health_change: a signed max-Health-fraction transfer, negative
# entries paid through _ApplyHealthCost (never lethal, absorbed by a Barrier like any
# other Health loss) and positive entries healed through _ApplyHeal (so Blight and a
# max-Health buff granted by the same skill both apply the normal way).

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()
	_resolver = TestFactory.make_resolver(_roster, _sides)

func _barrier_buff(p_value: float) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Barrier
	buff.duration = 2
	buff.value = p_value
	return buff

func _blight_debuff() -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Blight
	debuff.duration = 2
	return debuff


func test_self_cost_is_paid_and_reported() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.fraction = -0.1
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	var max_health: int = _resolver.GetMaxHealth(0)
	var expected_cost: int = int(round(max_health * 0.1))
	var health_before: int = _roster[0]._current_health

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._current_health, health_before - expected_cost)
	var costs: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 0)
	assert_eq(costs.size(), 1, "The self cost should report one Damage result")
	assert_eq(costs[0].amount, expected_cost)


func test_a_cost_floors_the_payer_at_1_health_instead_of_killing_them() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.fraction = -1.0
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	_roster[0]._current_health = 5

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._current_health, 1, "A Health cost must never be lethal to the payer")


func test_a_caster_already_at_1_health_pays_nothing_and_the_skill_still_resolves() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.fraction = -0.1
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	_roster[0]._current_health = 1
	var target_health_before: int = _roster[3]._current_health

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[0]._current_health, 1, "A caster at 1 Health should pay nothing")
	var costs: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 0)
	assert_true(costs.is_empty(), "No cost should be reported when nothing was paid")
	assert_lt(_roster[3]._current_health, target_health_before, "The skill's other effects should still resolve")


func test_all_other_allies_drain_hits_every_living_ally_and_skips_the_caster_and_the_dead() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.All_Other_Allies
	effect.fraction = -0.1
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	_roster[2]._current_health = 0
	var caster_health_before: int = _roster[0]._current_health
	var ally_health_before: int = _roster[1]._current_health
	var expected_drain: int = int(round(_resolver.GetMaxHealth(1) * 0.1))

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._current_health, caster_health_before, "The caster should be excluded from the drain")
	assert_eq(_roster[1]._current_health, ally_health_before - expected_drain)
	assert_eq(_roster[2]._current_health, 0, "A dead ally should not be drained")


func test_an_active_barrier_absorbs_a_cost() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.fraction = -0.1
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	_roster[0]._active_buffs.append(_barrier_buff(1000.0))
	var health_before: int = _roster[0]._current_health
	var expected_cost: int = int(round(_resolver.GetMaxHealth(0) * 0.1))

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._current_health, health_before, "A Barrier should absorb the cost before Health is touched")
	assert_eq(_roster[0]._active_buffs[0].value, 1000.0 - expected_cost)
	var costs: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 0)
	assert_true(costs.is_empty(), "A fully-absorbed cost should not report a Health-loss result")


func test_positive_health_change_heals_as_a_max_health_fraction() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.fraction = 0.2
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	_roster[0]._current_health = 1
	var expected_heal: int = int(round(_resolver.GetMaxHealth(0) * 0.2))

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._current_health, 1 + expected_heal)


func test_blight_halves_a_skill_heal() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.fraction = 0.2
	skill.effects.append(effect)
	_roster[0]._skills.append(skill)
	_roster[0]._current_health = 1
	_roster[0]._active_debuffs.append(_blight_debuff())
	var full_heal: int = int(round(_resolver.GetMaxHealth(0) * 0.2))
	var expected_heal: int = int(floor(full_heal * 0.5))

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._current_health, 1 + expected_heal, "Blight should halve a skill heal like any other healing")


func test_a_buff_that_raises_max_health_lands_before_the_heal_is_computed() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var buff_effect: ApplyBuffEffect = ApplyBuffEffect.new()
	buff_effect.target = Types.Skill_Target.Self
	buff_effect.buff_type = Types.Buff_Type.Vigor
	buff_effect.duration = 2
	var heal_effect: HealthChangeEffect = HealthChangeEffect.new()
	heal_effect.target = Types.Skill_Target.Self
	heal_effect.fraction = 0.15
	skill.effects = [buff_effect, heal_effect]
	_roster[0]._skills.append(skill)
	_roster[0]._attributes[Types.Attribute.Health] = 100
	_roster[0]._current_health = 1
	var max_health_before_vigor: int = _resolver.GetMaxHealth(0)
	var heal_without_vigor: int = int(round(max_health_before_vigor * 0.15))

	_resolver.ResolveSkill(0, [0], 0)

	var actual_heal: int = _roster[0]._current_health - 1
	assert_gt(actual_heal, heal_without_vigor,
		"The heal should be computed off max Health after Vigor has already been applied")
