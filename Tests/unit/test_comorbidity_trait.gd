extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Comorbidity at two levels: the trait itself (flags every debuff it casts to
# repeat as a cascade instance per distinct debuff type on the target), and the resolver's
# cascade-driven retick of any debuff carrying that flag.

class FakeCascadeInstanceListenerTrait extends CharacterTrait:
	var _notified_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Cascade_Instance_Resolved] = Callable(self, "OnCascadeInstanceResolved")

	func OnCascadeInstanceResolved(
			_p_owner_ID: int, _p_event: CascadeEvent, _p_resolver: BattleResolver) -> void:
		_notified_count += 1

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
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var ticks: Array[CombatResult] = _burning_ticks(results)
	assert_between(ticks[0].amount, _min_tick(100), _max_tick(100), "The base tick stays at its own magnitude")

func test_repeats_once_per_other_distinct_debuff_type_as_cascade_instances() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Suppress, 1, 2)
	# 3 distinct types => 1 base tick + 2 cascade repeats.
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	assert_eq(_cascade_triggers(results).size(), 2)
	assert_eq(_burning_ticks(results).size(), 3)
	var total: int = 0
	for tick in _burning_ticks(results):
		total += tick.amount
	assert_between(total, _min_tick(100) * 3, _max_tick(100) * 3,
		"Total damage over the turn sums three independently rolled ticks")

func test_count_is_distinct_types_not_raw_instance_count() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	for i in 4:
		_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	# 2 distinct types (Burning, Enfeeble) despite 4 stacked Enfeeble instances => 1 repeat.
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
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
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	assert_eq(_cascade_triggers(results).size(), 7)
	assert_eq(_burning_ticks(results).size(), 8)

func test_debuffs_from_other_casters_are_unaffected() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Burning, 2, 2)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
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
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var ticks: Array[CombatResult] = _burning_ticks(results)
	assert_eq(ticks.size(), 2)
	assert_between(ticks[1].amount_by_source.get(1, 0), _min_tick(100), _max_tick(100))
	assert_false(ticks[1].amount_by_source.has(2), "The unflagged Enfeeble source must not repeat")

func test_recomputes_between_turns_as_debuffs_expire() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 3, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 1)

	# First turn: 2 distinct types => 1 repeat.
	var first_results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	assert_eq(_cascade_triggers(first_results).size(), 1)

	# The Enfeeble expired after the first tick; only the Burning itself remains.
	var second_results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	assert_eq(_cascade_triggers(second_results).size(), 0)
	var second_ticks: Array[CombatResult] = _burning_ticks(second_results)
	assert_eq(second_ticks.size(), 1)
	assert_between(second_ticks[0].amount, _min_tick(100), _max_tick(100))

func test_a_target_killed_by_the_base_tick_produces_no_cascade_instances() -> void:
	_set_max_health(0, 1)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	assert_eq(_cascade_triggers(results).size(), 0)

func test_instances_are_visible_to_the_cascade_instance_resolved_hook() -> void:
	_set_max_health(0, 100)
	var listener: FakeCascadeInstanceListenerTrait = FakeCascadeInstanceListenerTrait.new()
	listener.Init(Types.Rarity.Common)
	_roster[3]._trait = listener

	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Suppress, 1, 2)
	_resolver.ResolveSkill(0, [], 0)

	assert_eq(listener._notified_count, 2, "One notification per real cascade instance (2 repeats)")
