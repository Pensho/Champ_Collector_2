extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Skill.barrier_from_health_paid (Transfusion's shape): a skill-cast Barrier's
# value is `paid * multiplier`, where `paid` is what _ResolveHealthCosts actually took from
# the caster this cast (so an already-absorbed cost yields a proportionally smaller Barrier).

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()
	_resolver = TestFactory.make_resolver(_roster, _sides)

func _transfusion_like_skill(p_barrier_from_health_paid: float) -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Ally_Not_Self
	var cost_effect: HealthChangeEffect = HealthChangeEffect.new()
	cost_effect.target = Types.Skill_Target.Self
	cost_effect.fraction = -0.15
	var barrier_effect: BarrierEffect = BarrierEffect.new()
	barrier_effect.target = Types.Skill_Target.Ally_Not_Self
	barrier_effect.source = BarrierEffect.Source.Health_Paid
	barrier_effect.fraction = p_barrier_from_health_paid
	barrier_effect.duration = 2
	skill.effects = [cost_effect, barrier_effect]
	return skill

func _barrier_value(p_character: Character) -> float:
	for buff in p_character._active_buffs:
		if(Types.Buff_Type.Barrier == buff.type):
			return buff.value
	return -1.0

func _barrier_buff(p_value: float) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Barrier
	buff.duration = 2
	buff.value = p_value
	return buff


func test_barrier_pool_equals_paid_times_multiplier() -> void:
	var skill: Skill = _transfusion_like_skill(2.0)
	_roster[0]._skills.append(skill)
	var expected_paid: int = int(round(_resolver.GetMaxHealth(0) * 0.15))

	_resolver.ResolveSkill(0, [1], 0)

	assert_eq(_barrier_value(_roster[1]), float(expected_paid) * 2.0)


func test_a_barrier_that_absorbed_the_cost_yields_a_proportionally_smaller_new_one() -> void:
	var skill: Skill = _transfusion_like_skill(2.0)
	_roster[0]._skills.append(skill)
	var full_cost: int = int(round(_resolver.GetMaxHealth(0) * 0.15))
	var existing_barrier_value: float = float(full_cost) / 2.0
	_roster[0]._active_buffs.append(_barrier_buff(existing_barrier_value))
	var expected_paid: int = full_cost - int(existing_barrier_value)

	_resolver.ResolveSkill(0, [1], 0)

	assert_eq(_barrier_value(_roster[1]), float(expected_paid) * 2.0)
	assert_lt(_barrier_value(_roster[1]), float(full_cost) * 2.0,
		"The new Barrier should be smaller than if the cost had been paid in full")


func test_no_barrier_value_is_set_when_barrier_from_health_paid_is_0() -> void:
	var skill: Skill = _transfusion_like_skill(0.0)
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [1], 0)

	assert_eq(_barrier_value(_roster[1]), -1.0,
		"BarrierEffect skips granting entirely for a non-positive value rather than falling back to a registry default")
