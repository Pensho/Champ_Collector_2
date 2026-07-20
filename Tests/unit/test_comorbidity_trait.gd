extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Comorbidity at two levels: the trait itself (returns the rarity-dependent
# per-debuff fraction, and the resolver stamps it onto newly cast debuffs), and the
# resolver's tick-time scaling of any debuff that carries a tick_bonus_per_debuff.

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
		p_tick_bonus_per_debuff: float = 0.0) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	debuff.source_ID = p_source_ID
	debuff.tick_bonus_per_debuff = p_tick_bonus_per_debuff
	_roster[p_character_ID]._active_debuffs.append(debuff)

func _set_max_health(p_character_ID: int, p_max_health: int) -> void:
	_roster[p_character_ID]._attributes[Types.Attribute.Health] = p_max_health
	_roster[p_character_ID]._current_health = p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER

func _expected_tick(p_max_health: int) -> int:
	return int(floor((p_max_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))

func _burning_ticks(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == CombatResult.Kind.Debuff_Tick)

# --- Rarity table ---

func test_tick_bonus_per_debuff_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.05,
		Types.Rarity.Rare: 0.07,
		Types.Rarity.Epic: 0.09,
		Types.Rarity.Legendary: 0.11,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(ComorbidityTrait.GetTickBonusPerDebuff(rarity), expected[rarity],
			"TICK_BONUS_PER_DEBUFF at %s" % Types.RarityName(rarity))

# --- Trait hook ---

func test_on_skill_cast_returns_the_rarity_bonus() -> void:
	var comorbidity_trait: ComorbidityTrait = ComorbidityTrait.new()
	comorbidity_trait.Init(Types.Rarity.Epic)
	var result: TraitSkillResult = comorbidity_trait.OnSkillCast(0, [], "Zap", {}, _resolver)
	assert_eq(result._tick_bonus_per_debuff, 0.09)

func test_cast_debuff_stamps_the_bonus_onto_the_new_debuff() -> void:
	var skill: Skill = Skill.new()
	skill.name = "Toxin"
	skill.target = Types.Skill_Target.Single_Enemy
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: Types.Debuff_Type.Burning}
	_roster[0]._skills = [skill]
	_roster[0]._trait = ComorbidityTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Rare)

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[3]._active_debuffs[0].tick_bonus_per_debuff, 0.07)

func test_refreshing_an_existing_debuff_updates_its_bonus() -> void:
	var skill: Skill = Skill.new()
	skill.name = "Toxin"
	skill.target = Types.Skill_Target.Single_Enemy
	skill.duration = 3
	skill.debuffs = {Types.Skill_Target.Single_Enemy: Types.Debuff_Type.Enfeeble}
	_roster[0]._skills = [skill]
	_roster[0]._trait = ComorbidityTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Rare)
	# A non-stackable, overwritable debuff already sitting on the target from another,
	# non-Comorbidity source.
	_add_debuff(3, Types.Debuff_Type.Enfeeble, 5, 1, 0.0)

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[3]._active_debuffs.size(), 1, "The existing Enfeeble should be refreshed in place, not stacked")
	assert_eq(_roster[3]._active_debuffs[0].duration, 3, "Duration should be refreshed to the new skill's duration")
	assert_eq(_roster[3]._active_debuffs[0].tick_bonus_per_debuff, 0.07,
		"Refreshing should also update the bonus to the Plague Doctor's own rarity value")

# --- Tick-time scaling ---

func test_tick_scales_with_the_targets_total_debuff_count_at_tick_time() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, 0.05)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	_add_debuff(0, Types.Debuff_Type.Suppress, 1, 2)
	# 3 active debuffs (the ticking Burning included) => 1 + 0.05 x 3 = 1.15
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount, int(floor(_expected_tick(100) * 1.15)))

func test_stack_count_is_capped_at_five() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, 0.05)
	for i in 6:
		_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 2)
	# 7 active debuffs total, capped at 5 => 1 + 0.05 x 5 = 1.25
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount, int(floor(_expected_tick(100) * 1.25)))

func test_debuffs_from_other_casters_are_unaffected() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 2, 0.05)
	_add_debuff(0, Types.Debuff_Type.Burning, 2, 2)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	# Source 1 (Comorbidity, 2 active debuffs): 1 + 0.05 x 2 = 1.10
	assert_eq(tick.amount_by_source[1], int(floor(_expected_tick(100) * 1.10)))
	# Source 2's own Burning carries no bonus, so it ticks at the unscaled base amount.
	assert_eq(tick.amount_by_source[2], _expected_tick(100))

func test_scaling_recomputes_between_ticks() -> void:
	_set_max_health(0, 100)
	_add_debuff(0, Types.Debuff_Type.Burning, 1, 3, 0.05)
	_add_debuff(0, Types.Debuff_Type.Enfeeble, 1, 1)

	# First tick: 2 active debuffs => 1 + 0.05 x 2 = 1.10.
	var first_results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var first_tick: CombatResult = _burning_ticks(first_results)[0]
	assert_eq(first_tick.amount, int(floor(_expected_tick(100) * 1.10)))

	# The Enfeeble expired after the first tick; only the Burning itself remains.
	var second_results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var second_tick: CombatResult = _burning_ticks(second_results)[0]
	assert_eq(second_tick.amount, int(floor(_expected_tick(100) * 1.05)))
