extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Press the Advantage: whenever an allied attack hits a Spotted enemy, the holder
# gains one Momentum stack (Encounter_Design_Document.md section 1). A hit is a damaging effect
# that lands: misses do not count, lethal and fully absorbed hits do.

const HOLDER_ID: int = 3

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	var press_the_advantage: PressTheAdvantageTrait = PressTheAdvantageTrait.new()
	press_the_advantage.Init(Types.Rarity.Common)
	_roster[HOLDER_ID]._trait = press_the_advantage
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _spot(p_holder_ID: int) -> void:
	var spotted: StatusEffects.Debuff = StatusEffects.Debuff.new()
	spotted.type = Types.Debuff_Type.Spotted
	spotted.duration = 2
	_roster[p_holder_ID]._active_debuffs.append(spotted)

func _buff(p_type: Types.Buff_Type, p_value: float = 0.0) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.value = p_value
	buff.duration = 3
	return buff

func _momentum_stacks() -> int:
	for buff in _roster[HOLDER_ID]._active_buffs:
		if(Types.Buff_Type.Momentum == buff.type):
			return int(buff.trait_riders.get(&"stacks", 0))
	return 0

func test_an_allys_hit_on_the_spotted_champion_adds_a_stack() -> void:
	_spot(0)
	_resolver.ResolveSkill(4, [0], 0)
	assert_eq(_momentum_stacks(), 1)
	_resolver.ResolveSkill(5, [0], 0)
	assert_eq(_momentum_stacks(), 2, "Each allied hit on the Spotted champion should add a stack")

func test_a_hit_on_anyone_else_does_not_add_a_stack() -> void:
	_spot(0)
	_resolver.ResolveSkill(4, [1], 0)
	assert_eq(_momentum_stacks(), 0)

func test_the_holders_own_hit_counts() -> void:
	_spot(0)
	_resolver.ResolveSkill(HOLDER_ID, [0], 0)
	assert_eq(_momentum_stacks(), 1)

func test_the_stack_a_hit_earns_does_not_boost_that_hit() -> void:
	_spot(0)
	var results: Array[CombatResult] = _resolver.ResolveSkill(HOLDER_ID, [0], 0)
	var damage: Array = results.filter(
			func(result: CombatResult) -> bool: return CombatResult.Kind.Damage == result.kind)
	assert_eq(_momentum_stacks(), 1, "Sanity check: the hit should earn a stack")
	assert_eq(damage[0].combined_damage_modifier.Buckets().get(&"Momentum", 0.0), 0.0,
			"The stack applies from the next hit on")

func test_an_opposing_hit_on_a_spotted_ally_of_the_holder_does_not_count() -> void:
	_spot(5)
	_resolver.ResolveSkill(1, [5], 0)
	assert_eq(_momentum_stacks(), 0, "Only allied attacks feed Press the Advantage")

func test_a_lethal_hit_counts() -> void:
	_spot(0)
	_roster[0]._current_health = 1
	_resolver.ResolveSkill(4, [0], 0)
	assert_eq(_roster[0]._current_health, 0, "Sanity check: the hit should kill")
	assert_eq(_momentum_stacks(), 1, "The killing hit still landed on a Spotted champion")

func test_a_hit_fully_absorbed_by_a_barrier_counts() -> void:
	_spot(0)
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Barrier, 100000.0))
	var health_before: int = _roster[0]._current_health
	_resolver.ResolveSkill(4, [0], 0)
	assert_eq(_roster[0]._current_health, health_before, "Sanity check: the Barrier should absorb the hit")
	assert_eq(_momentum_stacks(), 1)

func test_a_missed_attack_does_not_count() -> void:
	_spot(0)
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Premonition))
	_resolver.ResolveSkill(4, [0], 0)
	assert_eq(_momentum_stacks(), 0, "Premonition makes the attack miss, so nothing hit")

func test_a_support_skill_on_the_spotted_champion_does_not_count() -> void:
	_spot(0)
	_roster[4]._skills[0] = TestFactory.make_empty_skill()
	_resolver.ResolveSkill(4, [0], 0)
	assert_eq(_momentum_stacks(), 0, "A skill with no damaging effect is not an attack")

func test_damage_over_time_ticks_do_not_count() -> void:
	_spot(0)
	var burning: StatusEffects.Debuff = StatusEffects.Debuff.new()
	burning.type = Types.Debuff_Type.Burning
	burning.duration = 3
	burning.source_ID = 4
	_roster[0]._active_debuffs.append(burning)
	var health_before: int = _roster[0]._current_health
	_resolver.GetStatusResolver()._TriggerExistingCasterDebuffs(0, _resolver.GetEffectiveAttributes(0))
	assert_lt(_roster[0]._current_health, health_before, "Burning should have ticked")
	assert_eq(_momentum_stacks(), 0, "A damage-over-time tick is not an attack")
