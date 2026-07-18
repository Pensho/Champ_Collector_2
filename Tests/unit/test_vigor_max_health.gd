extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Vigor raises max Health by reading MaxHealthAttributePercent buffs directly in
# BattleResolver._MaxHealth (not through the self-tick/target-snapshot loops), and its
# expiry must reclamp current health down to the new, smaller max.

func _vigor_buff(p_duration: int) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Vigor
	buff.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Vigor).magnitude
	buff.duration = p_duration
	return buff

func test_vigor_raises_the_clamp_bound_current_health_can_heal_into() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_empty_skill())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	# Base Health is 10 -> base max is 40 (x4). Vigor adds 30%.
	var baseline_max: int = 10 * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	roster[0]._active_buffs.append(_vigor_buff(5))
	resolver.SetCurrentHealth(0, 1000)

	assert_eq(roster[0]._current_health, int(ceilf(10 * 1.3)) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER,
		"SetCurrentHealth should clamp to Vigor's raised max, not the base max (%d)" % baseline_max)

func test_vigor_expiry_reclamps_current_health_to_the_lower_max() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_empty_skill())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._active_buffs.append(_vigor_buff(1))
	resolver.SetCurrentHealth(0, 1000)
	var raised_health: int = roster[0]._current_health
	var base_max: int = 10 * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	assert_gt(raised_health, base_max, "Sanity check: health should exceed the base max while Vigor is active")

	resolver.ResolveSkill(0, [], 0)

	assert_eq(roster[0]._current_health, base_max,
		"Current health must be reclamped to the base max once Vigor expires")
