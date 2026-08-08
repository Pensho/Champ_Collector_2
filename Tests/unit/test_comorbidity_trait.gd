extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Comorbidity at two levels: the trait itself (flags every debuff it casts to
# repeat its tick per distinct debuff type on the target), and the resolver's tick-time
# multiplication of any debuff carrying that flag.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

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
	debuff.repeats_per_distinct_debuff = p_repeats_per_distinct_debuff
	_roster[p_character_ID]._active_debuffs.append(debuff)

func _set_max_health(p_character_ID: int, p_max_health: int) -> void:
	_roster[p_character_ID]._attributes[Types.Attribute.Health] = p_max_health
	_roster[p_character_ID]._current_health = p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER

func _expected_tick(p_max_health: int) -> int:
	return int(floor((p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))

func _burning_ticks(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == CombatResult.Kind.Debuff_Tick)

# --- Trait hook ---

func test_on_skill_cast_flags_the_repeat() -> void:
	var comorbidity_trait: ComorbidityTrait = ComorbidityTrait.new()
	comorbidity_trait.Init(Types.Rarity.Epic)
	var result: TraitSkillResult = comorbidity_trait.OnSkillCast(0, [], "Zap", {}, _resolver)
	assert_true(result._repeats_tick_per_distinct_debuff)

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

	assert_true(_roster[3]._active_debuffs[0].repeats_per_distinct_debuff)

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
	assert_true(_roster[3]._active_debuffs[0].repeats_per_distinct_debuff,
		"Refreshing should also stamp the Comorbidity-sourced flag")

# --- Tick-time multiplication ---

func test_tick_multiplies_by_the_targets_distinct_debuff_type_count_at_tick_time() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Suppress, 1, 2)
	# 3 distinct types (the ticking Burning included) => tick x 3.
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount, _expected_tick(100) * 3)

func test_count_is_distinct_types_not_raw_instance_count() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	for i in 4:
		_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	# 2 distinct types (Burning, Enfeeble) despite 4 stacked Enfeeble instances => tick x 2.
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount, _expected_tick(100) * 2)

func test_count_is_uncapped() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	var other_types: Array[Types.Debuff_Type] = [
		Types.Debuff_Type.Enfeeble, Types.Debuff_Type.Suppress, Types.Debuff_Type.Unravel,
		Types.Debuff_Type.Confound, Types.Debuff_Type.Hexed, Types.Debuff_Type.Blight,
		Types.Debuff_Type.Slow,
	]
	for type in other_types:
		_add_debuff(0, type, 1, 2)
	# 8 distinct types total => tick x 8, no cap.
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount, _expected_tick(100) * 8)

func test_debuffs_from_other_casters_are_unaffected() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, true)
	_add_debuff(0, Types.Debuff_Type.Burning, 2, 2)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	# Source 1's own Burning is flagged and 1 distinct type is present => tick x 1.
	assert_eq(tick.amount_by_source[1], _expected_tick(100))
	# Source 2's Burning carries no flag, so it ticks at the unscaled base amount.
	assert_eq(tick.amount_by_source[2], _expected_tick(100))

func test_multiplier_recomputes_between_ticks() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 3, true)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 1)

	# First tick: 2 distinct types => tick x 2.
	var first_results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var first_tick: CombatResult = _burning_ticks(first_results)[0]
	assert_eq(first_tick.amount, _expected_tick(100) * 2)

	# The Enfeeble expired after the first tick; only the Burning itself remains.
	var second_results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var second_tick: CombatResult = _burning_ticks(second_results)[0]
	assert_eq(second_tick.amount, _expected_tick(100))
