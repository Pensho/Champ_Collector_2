extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Comorbidity at two levels: the trait itself (flags every debuff it casts to
# repeat as a cascade instance per distinct debuff type on the target), and the resolver's
# cascade-driven retick of any debuff carrying that flag.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _cascade: CascadeResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_cascade = _resolver.GetCascadeResolver()

func _add_debuff(
		p_character_ID: int,
		p_type: Types.Debuff_Type,
		p_source_ID: int,
		p_duration: int,
		p_repeats_per_distinct_debuff: bool = false) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	debuff.source_ID = p_source_ID
	debuff.trait_riders[&"repeats_per_distinct_debuff"] = p_repeats_per_distinct_debuff
	_roster[p_character_ID]._active_debuffs.append(debuff)

func _set_max_health(p_character_ID: int, p_max_health: int) -> void:
	_roster[p_character_ID]._attributes[Types.Attribute.Health] = p_max_health
	_roster[p_character_ID]._current_health = p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER

func _min_tick(p_max_health: int) -> int:
	return int(floor((p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.02))

func _max_tick(p_max_health: int) -> int:
	return int(floor((p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.1))

func _burning_ticks(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == CombatResult.Kind.Debuff_Tick)

# --- Trait hook ---

func test_on_skill_cast_flags_the_repeat() -> void:
	var comorbidity_trait: ComorbidityTrait = ComorbidityTrait.new()
	comorbidity_trait.Init(Types.Rarity.Epic)
	var result: TraitSkillResult = comorbidity_trait.OnSkillCast(0, [], "Zap", {}, _resolver)
	assert_true(result._trait_riders.get(&"repeats_per_distinct_debuff", false))

func test_cast_debuff_stamps_the_flag_onto_the_new_debuff() -> void:
	var skill: Skill = Skill.new()
	skill.name = "Toxin"
	skill.target = Types.Skill_Target.Single_Enemy
	var effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	effect.target = Types.Skill_Target.Single_Enemy
	effect.debuff_type = Types.Debuff_Type.Burning
	effect.duration = 2
	skill.effects = [effect]
	_roster[0]._skills = [skill]
	_roster[0]._trait = ComorbidityTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Rare)

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_roster[3]._active_debuffs[0].trait_riders.get(&"repeats_per_distinct_debuff", false))

func test_refreshing_an_existing_debuff_updates_the_flag() -> void:
	var skill: Skill = Skill.new()
	skill.name = "Toxin"
	skill.target = Types.Skill_Target.Single_Enemy
	var effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	effect.target = Types.Skill_Target.Single_Enemy
	effect.debuff_type = Types.Debuff_Type.Enfeeble
	effect.duration = 3
	skill.effects = [effect]
	_roster[0]._skills = [skill]
	_roster[0]._trait = ComorbidityTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Rare)
	# A non-stackable, overwritable debuff already sitting on the target from another,
	# non-Comorbidity source.
	_add_debuff(3, Types.Debuff_Type.Enfeeble, 5, 1, false)

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[3]._active_debuffs.size(), 1, "The existing Enfeeble should be refreshed in place, not stacked")
	assert_eq(_roster[3]._active_debuffs[0].duration, 3, "Duration should be refreshed to the new skill's duration")
	assert_true(_roster[3]._active_debuffs[0].trait_riders.get(&"repeats_per_distinct_debuff", false),
		"Refreshing should also stamp the Comorbidity-sourced flag")

# --- Cascade-driven retick ---

func _cascade_triggers(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result):
		return (result.kind == CombatResult.Kind.Cascade_Triggered
				and result.cascade_trigger == Types.Cascade_Trigger.Debuff_Ticked))

func test_base_tick_is_no_longer_multiplied() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Suppress, 1, 2)
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	var ticks: Array[CombatResult] = _burning_ticks(results)
	assert_between(ticks[0].amount, _min_tick(100), _max_tick(100), "The base tick stays at its own magnitude")

func test_repeats_once_per_other_distinct_debuff_type_as_cascade_instances() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Suppress, 1, 2)
	# 3 distinct types => 1 base tick + 2 cascade repeats.
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	assert_eq(_cascade_triggers(results).size(), 2)
	assert_eq(_burning_ticks(results).size(), 3)
	var total: int = 0
	for tick in _burning_ticks(results):
		total += tick.amount
	assert_between(total, _min_tick(100) * 3, _max_tick(100) * 3,
		"Total damage over the turn sums three independently rolled ticks")

func test_the_base_tick_and_each_repeat_name_the_debuff_that_ticked() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	var ticks: Array[CombatResult] = []
	ticks.assign(_burning_ticks(results))
	assert_eq(ticks.size(), 2, "One base tick and one repeat")
	for tick in ticks:
		assert_eq(tick.triggered_by, [StatusEffectRegistry.DebuffData(Types.Debuff_Type.Burning)],
				"Enfeeble does not tick, so only Burning triggered")
	assert_eq(_cascade_triggers(results)[0].skill_ID, -1, "A status echo names no skill")

func test_count_is_distinct_types_not_raw_instance_count() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	for i in 4:
		_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	# 2 distinct types (Burning, Enfeeble) despite 4 stacked Enfeeble instances => 1 repeat.
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	assert_eq(_cascade_triggers(results).size(), 1)
	assert_eq(_burning_ticks(results).size(), 2)

func test_count_is_uncapped_but_bounded_by_the_cascade_fan_out_cap() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	var other_types: Array[Types.Debuff_Type] = [
		Types.Debuff_Type.Enfeeble, Types.Debuff_Type.Suppress, Types.Debuff_Type.Unravel,
		Types.Debuff_Type.Confound, Types.Debuff_Type.Hexed, Types.Debuff_Type.Blight,
		Types.Debuff_Type.Slow,
	]
	for type in other_types:
		_add_debuff(0, type, 1, 2)
	# 8 distinct types total => 7 repeats, well under the fan-out cap.
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	assert_eq(_cascade_triggers(results).size(), 7)
	assert_eq(_burning_ticks(results).size(), 8)

func test_debuffs_from_other_casters_are_unaffected() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Burning, 2, 2)
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	var ticks: Array[CombatResult] = _burning_ticks(results)
	# Source 1's own Burning is flagged and 1 distinct type is present => no repeat, one base tick.
	assert_eq(ticks.size(), 1)
	assert_between(ticks[0].amount_by_source[1], _min_tick(100), _max_tick(100))
	# Source 2's Burning carries no flag, and contributes to the same base tick unscaled.
	assert_between(ticks[0].amount_by_source[2], _min_tick(100), _max_tick(100))

func test_only_the_flagged_source_repeats_when_multiple_casters_debuff_the_same_target() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 2, 2)
	# 2 distinct types => 1 repeat, and the repeat re-ticks only source 1's flagged Burning.
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	var ticks: Array[CombatResult] = _burning_ticks(results)
	assert_eq(ticks.size(), 2)
	assert_between(ticks[1].amount_by_source.get(1, 0), _min_tick(100), _max_tick(100))
	assert_false(ticks[1].amount_by_source.has(2), "The unflagged Enfeeble source must not repeat")

func test_recomputes_between_turns_as_debuffs_expire() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 3, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 1)

	# First turn: 2 distinct types => 1 repeat.
	var first_results: Array[CombatResult] = _resolver.BeginTurn(0)
	assert_eq(_cascade_triggers(first_results).size(), 1)
	_resolver.ResolveSkill(0, [], 0)

	# The Enfeeble expired at the end of the first turn; only the Burning itself remains.
	var second_results: Array[CombatResult] = _resolver.BeginTurn(0)
	assert_eq(_cascade_triggers(second_results).size(), 0)
	var second_ticks: Array[CombatResult] = _burning_ticks(second_results)
	assert_eq(second_ticks.size(), 1)
	assert_between(second_ticks[0].amount, _min_tick(100), _max_tick(100))

func test_a_target_killed_by_the_base_tick_produces_no_cascade_instances() -> void:
	_set_max_health(0, 1)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)

	var results: Array[CombatResult] = _resolver.BeginTurn(0)

	assert_eq(_cascade_triggers(results).size(), 0)

# --- Rolled ticks read the target's battle ID ---

func _rolled_burning_tick(p_status: StatusEffects.Effect) -> int:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_set_max_health(3, 100000)
	_add_debuff(3, Types.Debuff_Type.Burning, 0, 5)
	if(p_status is StatusEffects.Buff):
		_roster[3]._active_buffs.append(p_status)
	elif(p_status is StatusEffects.Debuff):
		_roster[3]._active_debuffs.append(p_status)
	return _burning_ticks(_resolver.BeginTurn(3))[0].amount

func test_luck_and_hexed_on_the_target_favor_its_rolled_tick() -> void:
	var luck: StatusEffects.Buff = StatusEffects.Buff.new()
	luck.type = Types.Buff_Type.Luck
	luck.duration = 5
	var hexed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	hexed.type = Types.Debuff_Type.Hexed
	hexed.duration = 5
	assert_lt(_rolled_burning_tick(luck), _rolled_burning_tick(hexed),
		"Luck keeps the lower roll and Hexed the higher, whatever the character's roster ID")

# --- Tick growth ---

func _add_snapshot_tick(p_target_ID: int, p_flagged: bool, p_value: float = 1000.0) -> void:
	_add_debuff(p_target_ID, Types.Debuff_Type.Plague, 0, 9, p_flagged)
	_roster[p_target_ID]._active_debuffs.back().value = p_value
	_roster[p_target_ID]._active_debuffs.back().trait_riders[StatusEffectResolver.TICK_GROWTH_SCALE_RIDER_KEY] = 4.0

func _tick_once(p_target_ID: int) -> int:
	_set_max_health(p_target_ID, 100000)
	var ticks: Array[CombatResult] = _burning_ticks(_resolver.BeginTurn(p_target_ID))
	return ticks[0].amount

func test_flagged_tick_grows_with_each_resolution_on_its_target() -> void:
	_add_snapshot_tick(3, true)
	assert_eq(_tick_once(3), 1000, "The first resolution is flat")
	assert_eq(_tick_once(3), 1100, "1 + 4*1/(1+39) after one resolution")
	assert_eq(_tick_once(3), 1195, "1 + 4*2/(2+39) after two resolutions")

func test_stacks_in_one_resolution_count_once_and_share_its_factor() -> void:
	_add_snapshot_tick(3, true)
	_add_snapshot_tick(3, true)
	assert_eq(_tick_once(3), 2000, "Two stacks at the flat first factor")
	assert_eq(_tick_once(3), 2200, "Both stacks at the factor of one resolution")

func test_growth_reads_the_rarity_of_the_debuffs_source() -> void:
	var expected_second_tick: Dictionary[Types.Rarity, int] = {Types.Rarity.Uncommon: 1070, Types.Rarity.Rare: 1080,
			Types.Rarity.Epic: 1090, Types.Rarity.Legendary: 1100}
	for rarity: Types.Rarity in expected_second_tick:
		before_each()
		var comorbidity_trait: ComorbidityTrait = ComorbidityTrait.new()
		comorbidity_trait.Init(rarity)
		_add_snapshot_tick(3, true)
		_roster[3]._active_debuffs.back().trait_riders = comorbidity_trait.OnSkillCast(
				0, [], "", {}, _resolver)._trait_riders
		_tick_once(3)
		assert_eq(_tick_once(3), expected_second_tick[rarity])

func test_growth_counts_echoes_and_rises_through_them() -> void:
	_add_snapshot_tick(3, true)
	_add_debuff(3, Types.Debuff_Type.Blight, 0, 9)
	_set_max_health(3, 100000)
	var amounts: Array = _burning_ticks(_resolver.BeginTurn(3)).map(
			func(result: CombatResult) -> int: return result.amount)
	assert_eq(amounts, [1000, 1100], "The Echo reads the factor the base tick raised")

func test_growth_is_per_target() -> void:
	_add_snapshot_tick(3, true)
	_add_snapshot_tick(4, true)
	_tick_once(3)
	assert_eq(_tick_once(4), 1000, "Another target's resolutions must not raise this one")

func test_growth_survives_a_lapse_of_the_debuff() -> void:
	_add_snapshot_tick(3, true)
	_tick_once(3)
	_roster[3]._active_debuffs.clear()
	_add_snapshot_tick(3, true)
	assert_eq(_tick_once(3), 1100, "A lapse or cleanse keeps the count")

func test_unflagged_debuffs_neither_grow_nor_count() -> void:
	_add_snapshot_tick(3, false)
	_tick_once(3)
	assert_eq(_tick_once(3), 1000, "An unflagged tick stays flat")
	_add_snapshot_tick(3, true)
	assert_eq(_tick_once(3), 2000, "Unflagged resolutions must not have advanced the count")
	assert_eq(_tick_once(3), 2100, "Only the flagged half of a mixed tick grows")

func test_manifest_tick_growth_matches_the_resolver() -> void:
	var outbreak: Dictionary = {}
	for skill: Dictionary in KitContributionManifest.MANIFEST[Types.Role.Plague_Doctor]["skills"]:
		if("Outbreak" == skill["name"]):
			outbreak = skill
	var growth: Dictionary = outbreak["gated_bonus"]["tick_growth"]
	assert_eq(growth["scale"], ComorbidityTrait.TICK_GROWTH_SCALE[Types.Rarity.Legendary])
	assert_eq(growth["half_count"], StatusEffectResolver.TICK_GROWTH_HALF_COUNT)
