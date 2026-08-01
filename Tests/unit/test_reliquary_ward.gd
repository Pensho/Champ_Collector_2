extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Reliquary Ward: odd casts grant a Barrier worth 60% of the recipient's max
# Health, even casts grant Deathward instead, alternating via the same per-resolver
# use-count machinery Heap_On's ramp reads (Skill.alternating_buffs / barrier_from_target_
# max_health).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _reliquary_ward_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Reliquary Ward"
	skill.target = Types.Skill_Target.Single_Ally
	skill.duration = 2
	skill.skill_type = Types.Skill_Type.Status_Effect
	skill.buffs = {Types.Skill_Target.Single_Ally: [Types.Buff_Type.Barrier]}
	skill.alternating_buffs = {Types.Skill_Target.Single_Ally: [Types.Buff_Type.Deathward]}
	skill.barrier_from_target_max_health = 0.6
	return skill

func test_first_cast_grants_a_barrier_worth_sixty_percent_of_max_health() -> void:
	_roster[0]._skills.append(_reliquary_ward_skill())

	_resolver.ResolveSkill(0, [1], 0)

	var barrier: Array = _roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Barrier)
	assert_eq(barrier.size(), 1)
	assert_eq(barrier[0].value, float(_resolver.GetMaxHealth(1)) * 0.6)
	var deathward: Array = _roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Deathward)
	assert_eq(deathward.size(), 0)

func test_second_cast_grants_deathward_instead() -> void:
	_roster[0]._skills.append(_reliquary_ward_skill())

	_resolver.ResolveSkill(0, [1], 0)
	_resolver.ResolveSkill(0, [1], 0)

	var deathward: Array = _roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Deathward)
	assert_eq(deathward.size(), 1)

func test_third_cast_returns_to_barrier() -> void:
	_roster[0]._skills.append(_reliquary_ward_skill())

	_resolver.ResolveSkill(0, [1], 0)
	_resolver.ResolveSkill(0, [1], 0)
	_roster[1]._active_buffs.clear()
	_resolver.ResolveSkill(0, [1], 0)

	var barrier: Array = _roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Barrier)
	assert_eq(barrier.size(), 1)

func test_alternation_is_independent_per_resolver() -> void:
	var other_roster: Dictionary[int, Character] = {}
	other_roster.assign(TestFactory.make_full_roster())
	var other_resolver: BattleResolver = TestFactory.make_resolver(other_roster, TestFactory.make_full_sides())
	other_roster[0]._skills.append(_reliquary_ward_skill())
	_roster[0]._skills.append(_reliquary_ward_skill())

	_resolver.ResolveSkill(0, [1], 0)
	other_resolver.ResolveSkill(0, [1], 0)

	var barrier_here: Array = _roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Barrier)
	var barrier_there: Array = other_roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Barrier)
	assert_eq(barrier_here.size(), 1)
	assert_eq(barrier_there.size(), 1, "A separate resolver should start its own alternation from the first use")
