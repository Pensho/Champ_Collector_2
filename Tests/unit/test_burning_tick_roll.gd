extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Burning's rolled per-stack tick (Concept_Document.md 3.2.3): each stack rolls
# independently in [2%, 10%] of max Health, biased by the ticking character's own Luck or
# Hexed, rather than a flat 4%.

func _resolver_with_burning(p_seed: int, p_status: Variant = null) -> BattleResolver:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_empty_skill())
	roster[0]._attributes[Types.Attribute.Health] = 100
	roster[0]._current_health = 100 * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Burning
	debuff.duration = 5
	debuff.source_ID = 1
	roster[0]._active_debuffs.append(debuff)
	if(p_status == Types.Buff_Type.Luck):
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = p_status
		buff.duration = 5
		roster[0]._active_buffs.append(buff)
	elif(p_status == Types.Debuff_Type.Hexed):
		var hexed: StatusEffects.Debuff = StatusEffects.Debuff.new()
		hexed.type = p_status
		hexed.duration = 5
		roster[0]._active_debuffs.append(hexed)
	return TestFactory.make_resolver(roster, TestFactory.make_full_sides(), null, p_seed)

func _tick_amount(p_resolver: BattleResolver) -> int:
	var results: Array[CombatResult] = p_resolver.ResolveSkill(0, [], 0)
	for r in results:
		if(r.kind == CombatResult.Kind.Debuff_Tick):
			return r.amount
	return -1

func _min_tick() -> int:
	return int(floor((100 * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.02))

func _max_tick() -> int:
	return int(floor((100 * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.1))

func test_each_tick_lands_within_the_rolled_bounds() -> void:
	for sample_seed in range(50):
		var amount: int = _tick_amount(_resolver_with_burning(sample_seed))
		assert_between(amount, _min_tick(), _max_tick(),
			"A Burning tick must land within 2-10%% of max Health (seed %d)" % sample_seed)

func _two_stack_tick(p_seed: int) -> CombatResult:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_empty_skill())
	roster[0]._attributes[Types.Attribute.Health] = 100
	roster[0]._current_health = 100 * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	for source in [1, 2]:
		var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
		debuff.type = Types.Debuff_Type.Burning
		debuff.duration = 5
		debuff.source_ID = source
		roster[0]._active_debuffs.append(debuff)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), null, p_seed)
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [], 0)
	return results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)[0]

func test_two_stacks_roll_independently() -> void:
	# Two independent rolls over a wide [2%,10%] range landing on the exact same integer
	# tick every time would mean the roll isn't actually independent per stack; require at
	# least one differing pair across several seeds.
	var saw_a_difference: bool = false
	for sample_seed in range(20):
		var tick: CombatResult = _two_stack_tick(sample_seed)
		if(tick.amount_by_source[1] != tick.amount_by_source[2]):
			saw_a_difference = true
			break
	assert_true(saw_a_difference, "Two Burning stacks should roll independently, not share one draw")

func test_hexed_raises_the_mean_tick_over_many_samples() -> void:
	var baseline_total: int = 0
	var hexed_total: int = 0
	var samples: int = 60
	for sample_seed in range(samples):
		baseline_total += _tick_amount(_resolver_with_burning(sample_seed))
		hexed_total += _tick_amount(_resolver_with_burning(sample_seed, Types.Debuff_Type.Hexed))
	assert_gt(float(hexed_total) / samples, float(baseline_total) / samples,
		"Hexed should take the worse (higher) of two Burning-tick rolls, raising the mean")

func test_luck_lowers_the_mean_tick_over_many_samples() -> void:
	var baseline_total: int = 0
	var luck_total: int = 0
	var samples: int = 60
	for sample_seed in range(samples):
		baseline_total += _tick_amount(_resolver_with_burning(sample_seed))
		luck_total += _tick_amount(_resolver_with_burning(sample_seed, Types.Buff_Type.Luck))
	assert_lt(float(luck_total) / samples, float(baseline_total) / samples,
		"Luck should take the better (lower) of two Burning-tick rolls, lowering the mean")
