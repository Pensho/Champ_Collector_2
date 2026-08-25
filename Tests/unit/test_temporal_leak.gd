extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Temporal Leak: BattleResolver.AccumulateTurnBarMovement is the resolver
# entry point the view calls each frame with the fraction of the bar the character just
# crossed (TurnBar.Update's return value). The resolver owns all the actual behavior —
# accumulation, the GameBalance.TURN_BAR_PROGRESS_TRIGGER_FRACTION threshold, and the
# Speed-scaled damage — so it is fully testable without the view.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _add_temporal_leak(p_character_ID: int) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Temporal_Leak
	debuff.duration = 2
	_roster[p_character_ID]._active_debuffs.append(debuff)

## Applies through the resolver rather than by direct construction, so
## StatusEffectResolver.SnapshotStatusValue freezes the source's persistent damage
## factors at this moment, matching how a real cast would apply the debuff.
func _add_temporal_leak_with_source(p_target_ID: int, p_source_ID: int) -> void:
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Temporal_Leak
	template.duration = 2
	template.source_ID = p_source_ID
	_resolver.GetStatusResolver().ApplyDebuff(p_target_ID, template)

func _expected_tick(p_speed: int) -> int:
	return int(floor(p_speed * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Temporal_Leak).magnitude))

func test_no_damage_below_the_trigger_fraction() -> void:
	_add_temporal_leak(0)
	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION * 0.5)
	assert_eq(results.size(), 0, "Less than the trigger fraction of movement should not proc Temporal Leak")

func test_damage_procs_once_at_the_trigger_fraction() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 20
	_add_temporal_leak(0)

	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION)

	var ticks: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)
	assert_eq(ticks.size(), 1)
	assert_eq(ticks[0].amount, _expected_tick(20))

func test_large_movement_can_proc_multiple_times_in_one_call() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 20
	_add_temporal_leak(0)

	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION * 3.0)

	var ticks: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)
	assert_eq(ticks.size(), 3, "Three trigger-fraction crossings in one call should proc three times")

func test_progress_carries_over_between_calls() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 20
	_add_temporal_leak(0)

	_resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION * 0.6)
	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION * 0.6)

	var ticks: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)
	assert_eq(ticks.size(), 1, "0.6 + 0.6 trigger fractions should cross the threshold once")

func test_no_effect_without_the_debuff() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 20
	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, 1.0)
	assert_eq(results.size(), 0, "Movement without Temporal Leak active should do nothing")

func test_damage_scales_with_live_speed_not_just_base() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 20
	_add_temporal_leak(0)
	var haste: StatusEffects.Buff = StatusEffects.Buff.new()
	haste.type = Types.Buff_Type.Haste
	haste.duration = 2
	_roster[0]._active_buffs.append(haste)

	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION)

	var ticks: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)
	assert_eq(ticks.size(), 1)
	# Haste's live +20% Speed (20 -> 24) must be read, not the base 20 GetCombatAttributes
	# used to return before attribute modifiers became always-live.
	assert_eq(ticks[0].amount, _expected_tick(24),
		"Temporal Leak's tick damage must scale off live Speed, including active Speed buffs")

func test_fractional_damage_accumulates_across_crossings_instead_of_being_discarded() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 49
	_add_temporal_leak(0)

	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(
		0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION * 3.0)

	var ticks: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)
	var total: int = 0
	for tick in ticks:
		total += tick.amount
	var naive_total: int = 3 * _expected_tick(49)
	assert_gt(total, naive_total,
		"Per-crossing fractional damage must accumulate across ticks instead of being floored away every time")

func test_damage_scales_with_the_appliers_persistent_damage_factors_at_application() -> void:
	_roster[0]._attributes[Types.Attribute.Speed] = 40
	# The applier's channel-2 factor at the moment of application is baked into the
	# frozen multiplier alongside the debuff itself; live Speed keeps being read every tick.
	_resolver.AggregateDamageMultipliers(1, 0.5)
	_add_temporal_leak_with_source(0, 1)
	# A further change to the applier's factors after application must not retroactively
	# change the already-ticking Temporal Leak.
	_resolver.AggregateDamageMultipliers(1, 2.0)

	var results: Array[CombatResult] = _resolver.AccumulateTurnBarMovement(0, Game_Balance.TURN_BAR_PROGRESS_TRIGGER_FRACTION)

	var ticks: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Tick)
	assert_eq(ticks.size(), 1)
	assert_eq(ticks[0].amount, int(floor(_expected_tick(40) * 1.5)),
		"Temporal Leak's tick must be scaled by the applier's persistent damage factors as they stood at application")
	assert_eq(ticks[0].source_ID, 1, "The tick should credit the debuff's applier as its source")
