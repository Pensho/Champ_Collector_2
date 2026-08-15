extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Skill_Effects components that run alongside the flat-field skill
# pipeline: each effect class is exercised directly via effect.Resolve(context),
# bypassing ResolveSkill's turn machinery, using a SkillCastContext built by the new
# TestFactory.make_context() helper.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null
var _caught: Array[CombatResult] = []

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_caught = []
	_resolver.result_produced.connect(func(r: CombatResult) -> void: _caught.append(r))

func _kinds(p_kind: CombatResult.Kind) -> Array[CombatResult]:
	return _caught.filter(func(r): return r.kind == p_kind)

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

# --- DamageEffect ---

func test_damage_effect_deals_scaled_damage_to_its_targets() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)
	var health_before: int = _roster[3]._current_health

	effect.Resolve(context)

	assert_lt(_roster[3]._current_health, health_before)

func test_damage_effect_bonus_per_buffs_on_caster_increases_damage() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Buffs_On_Caster: 0.3}
	var baseline_context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)
	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(baseline_context)
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	var buffed_context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)
	var buffed_before: int = _roster[3]._current_health

	effect.Resolve(buffed_context)

	var buffed_damage: int = buffed_before - _roster[3]._current_health
	assert_gt(buffed_damage, baseline_damage, "Buffs_On_Caster should scale up the damage bonus")

func test_damage_effect_bonus_per_buffs_consumed_reads_the_context_accumulator() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Buffs_Consumed: 0.3}
	var baseline_context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)
	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(baseline_context)
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var consumed_context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)
	consumed_context.buffs_consumed = 3
	var consumed_before: int = _roster[3]._current_health

	effect.Resolve(consumed_context)

	var consumed_damage: int = consumed_before - _roster[3]._current_health
	assert_gt(consumed_damage, baseline_damage, "Buffs_Consumed should scale up the damage bonus")

func test_damage_effect_uses_this_battle_ramps_the_pre_mitigation_aggregate() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Uses_This_Battle: 0.5}

	var first_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill, 0))
	var first_damage: int = first_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var ramped_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill, 6))
	var ramped_damage: int = ramped_before - _roster[3]._current_health

	assert_true(ramped_damage > first_damage,
		"A ramping Uses_This_Battle bonus must deal noticeably more damage after several casts")

func test_damage_effect_trait_condition_reads_the_casters_trait() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Trait_Condition: 0.5}

	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[0]._trait = TestFactory.FakeConditionCountTrait.new(Types.Trait_Count_Source.Trait_Condition, 1.0)
	var conditioned_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var conditioned_damage: int = conditioned_before - _roster[3]._current_health

	assert_gt(conditioned_damage, baseline_damage, "An active Trait_Condition should add its bonus fraction")

func test_damage_effect_trait_condition_with_no_trait_attached_deals_only_base_damage() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Trait_Condition: 0.3}

	var health_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))

	assert_gt(health_before - _roster[3]._current_health, 0,
		"A bonus_per source with no matching trait should still deal the effect's base damage")

func test_damage_effect_trait_counter_on_target_reads_the_traits_own_rate() -> void:
	# The skill authors fraction 1.0; the trait's GetConditionCount already carries the
	# per-unit rate (Concept 3.1.3: skills state what scales, never their own rate).
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Trait_Counter_On_Target: 1.0}

	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[0]._trait = TestFactory.FakeConditionCountTrait.new(Types.Trait_Count_Source.Trait_Counter_On_Target, 0.3)
	var boosted_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var boosted_damage: int = boosted_before - _roster[3]._current_health

	assert_gt(boosted_damage, baseline_damage,
		"Trait_Counter_On_Target should add the trait's own already-scaled count")

func test_damage_effect_defense_ignore_factor_reduces_the_targets_effective_defence() -> void:
	# Defence's mitigation ratio is taken against GameBalance.DEFENCE_SCALE_CONSTANT (100), not
	# the caster's own aggregate — the fixture's default Defence (6) is too small relative to
	# that constant to move an 8-Attack hit's rounded damage at all, so this test raises target
	# Defence to a boss-tier value to make the ignore-factor's effect visible.
	var skill: Skill = TestFactory.make_strike_skill()
	var full_defence_effect: DamageEffect = DamageEffect.new()
	full_defence_effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	full_defence_effect.defense_ignore_factor = 1.0
	_roster[3]._attributes[Types.Attribute.Defence] = 120
	var full_defence_before: int = _roster[3]._current_health
	full_defence_effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var full_defence_damage: int = full_defence_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var ignoring_effect: DamageEffect = DamageEffect.new()
	ignoring_effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	ignoring_effect.defense_ignore_factor = 0.0
	_roster[3]._attributes[Types.Attribute.Defence] = 120
	var ignoring_before: int = _roster[3]._current_health
	ignoring_effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var ignoring_damage: int = ignoring_before - _roster[3]._current_health

	assert_gt(ignoring_damage, full_defence_damage,
		"A lower defense_ignore_factor should shrink effective Defence and deal more damage")

func test_damage_effect_bonus_per_zones_on_turn_bar_scales_with_zone_count() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Zones_On_Turn_Bar: 0.3}
	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneAll)
	var zoned_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var zoned_damage: int = zoned_before - _roster[3]._current_health

	assert_gt(zoned_damage, baseline_damage, "A zone standing on the bar should add its bonus fraction")
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func test_damage_effect_bonus_per_target_debuff_count_scales_with_distinct_types_not_stacks() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per = {Types.Trait_Count_Source.Target_Debuff_Count: 0.08}
	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Enfeeble, 2))
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Enfeeble, 2))
	var stacked_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var stacked_damage: int = stacked_before - _roster[3]._current_health

	assert_eq(stacked_damage, baseline_damage,
		"Two stacks of the same debuff type must count as zero distinct types beyond the first")

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Enfeeble, 2))
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Suppress, 2))
	var distinct_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var distinct_damage: int = distinct_before - _roster[3]._current_health

	assert_gt(distinct_damage, stacked_damage,
		"A second distinct debuff type on the target should add another bonus fraction")

func test_damage_effect_bonus_per_absence_means_no_bonus_regardless_of_an_active_trait_condition() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[0]._trait = TestFactory.FakeConditionCountTrait.new(Types.Trait_Count_Source.Trait_Counter_On_Target, 5.0)
	var conditioned_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var conditioned_damage: int = conditioned_before - _roster[3]._current_health

	assert_eq(conditioned_damage, baseline_damage,
		"An empty bonus_per must not gain a bonus, even from an active counting trait")

func test_damage_effect_bonus_per_debuff_on_target_applies_only_when_the_target_carries_it() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.bonus_per_debuff_on_target = {Types.Debuff_Type.Warped: 0.3}
	var baseline_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	_roster[3]._active_debuffs.append(warped)
	var warped_before: int = _roster[3]._current_health
	effect.Resolve(TestFactory.make_context(_resolver, 0, [3], skill))
	var warped_damage: int = warped_before - _roster[3]._current_health

	assert_gt(warped_damage, baseline_damage, "A target carrying the bonus debuff should take increased damage")

# --- ApplyBuffEffect / ApplyDebuffEffect ---

func test_apply_buff_effect_applies_a_buff_with_its_own_duration() -> void:
	var effect: ApplyBuffEffect = ApplyBuffEffect.new()
	effect.buff_type = Types.Buff_Type.Empower
	effect.duration = 4
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [0], TestFactory.make_empty_skill())

	effect.Resolve(context)

	assert_eq(_roster[0]._active_buffs.size(), 1)
	assert_eq(_roster[0]._active_buffs[0].type, Types.Buff_Type.Empower)
	assert_eq(_roster[0]._active_buffs[0].duration, 4)

func test_apply_debuff_effect_applies_a_debuff_with_its_own_duration() -> void:
	var effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	effect.debuff_type = Types.Debuff_Type.Bleed
	effect.duration = 3
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	effect.Resolve(context)

	assert_eq(_roster[3]._active_debuffs.size(), 1)
	assert_eq(_roster[3]._active_debuffs[0].type, Types.Debuff_Type.Bleed)
	assert_eq(_roster[3]._active_debuffs[0].duration, 3)

# --- BarrierEffect ---

func test_barrier_effect_sources_from_health_paid() -> void:
	var effect: BarrierEffect = BarrierEffect.new()
	effect.source = BarrierEffect.Source.Health_Paid
	effect.fraction = 0.5
	effect.duration = 2
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [0], TestFactory.make_empty_skill())
	context.health_paid = 10

	effect.Resolve(context)

	assert_eq(_roster[0]._active_buffs.size(), 1)
	assert_eq(_roster[0]._active_buffs[0].type, Types.Buff_Type.Barrier)
	assert_eq(_roster[0]._active_buffs[0].value, 5.0)

func test_barrier_effect_sources_from_target_max_health() -> void:
	var effect: BarrierEffect = BarrierEffect.new()
	effect.source = BarrierEffect.Source.Target_Max_Health
	effect.fraction = 0.1
	effect.duration = 2
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	effect.Resolve(context)

	var expected: float = float(_resolver.GetMaxHealth(3)) * 0.1
	assert_eq(_roster[3]._active_buffs[0].value, expected)

func test_barrier_effect_grants_nothing_when_health_paid_is_zero() -> void:
	var effect: BarrierEffect = BarrierEffect.new()
	effect.source = BarrierEffect.Source.Health_Paid
	effect.fraction = 0.5
	effect.duration = 2
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [0], TestFactory.make_empty_skill())
	context.health_paid = 0

	effect.Resolve(context)

	assert_eq(_roster[0]._active_buffs.size(), 0,
		"No Health paid should grant no Barrier, not a registry-sized one")

# --- HealthChangeEffect ---

func test_health_change_effect_negative_fraction_costs_health_and_records_it() -> void:
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.fraction = -0.5
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [0], TestFactory.make_empty_skill())
	var health_before: int = _roster[0]._current_health

	effect.Resolve(context)

	assert_lt(_roster[0]._current_health, health_before)
	assert_gt(context.health_paid, 0)

func test_health_change_effect_positive_fraction_heals() -> void:
	_roster[3]._current_health = 1
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.fraction = 1.0
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	effect.Resolve(context)

	assert_gt(_roster[3]._current_health, 1)

func test_health_change_effect_scaling_adds_attribute_scaled_healing() -> void:
	_roster[3]._current_health = 1
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.scaling = {Types.Attribute.Mysticism: 1.0}
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	effect.Resolve(context)

	assert_gt(_roster[3]._current_health, 1)

# --- StealBuffEffect ---

func test_steal_buff_effect_moves_buffs_from_targets_to_the_rolled_recipient() -> void:
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	var effect: StealBuffEffect = StealBuffEffect.new()
	effect.count = 1
	effect.to = Types.Skill_Target.Self
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_strike_skill())

	effect.Resolve(context)

	assert_eq(_roster[3]._active_buffs.size(), 0, "The target should lose the stolen buff")
	assert_eq(_roster[0]._active_buffs.size(), 1, "The caster should gain it")

func test_steal_buff_effect_can_grant_a_fresh_duration() -> void:
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Empower, 1))
	var effect: StealBuffEffect = StealBuffEffect.new()
	effect.count = 1
	effect.to = Types.Skill_Target.Self
	effect.duration_override = 5
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_strike_skill())

	effect.Resolve(context)

	assert_eq(_roster[0]._active_buffs[0].duration, 5)

# --- ConsumeBuffsEffect ---

func test_consume_buffs_effect_removes_buffs_and_accumulates_the_count() -> void:
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	var effect: ConsumeBuffsEffect = ConsumeBuffsEffect.new()
	effect.count = -1
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_strike_skill())

	effect.Resolve(context)

	assert_eq(_roster[3]._active_buffs.size(), 0)
	assert_eq(context.buffs_consumed, 2)

# --- ReduceBuffDurationsEffect ---

func test_reduce_buff_durations_effect_shears_every_buff_on_the_target() -> void:
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Empower, 3))
	var effect: ReduceBuffDurationsEffect = ReduceBuffDurationsEffect.new()
	effect.amount = 2
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_strike_skill())

	effect.Resolve(context)

	assert_eq(_roster[3]._active_buffs[0].duration, 1)

# --- TurnBarEffect ---

func test_turn_bar_effect_bumps_its_targets_by_its_own_fraction_only() -> void:
	var effect: TurnBarEffect = TurnBarEffect.new()
	effect.fraction = 0.25
	var trait_result: TraitSkillResult = TraitSkillResult.new()
	trait_result._turn_bar_bump = 0.5
	var context: SkillCastContext = TestFactory.make_context(
			_resolver, 0, [3], TestFactory.make_strike_skill(), 0, trait_result)

	effect.Resolve(context)

	var bumps: Array[CombatResult] = _kinds(CombatResult.Kind.Turn_Bar_Bump)
	assert_eq(bumps[0].target_ID, 3)
	assert_eq(bumps[0].fraction, 0.25,
		"TurnBarEffect must apply only the skill's own fraction; the trait bump is turn machinery, not skill data")

# --- AlternatingEffect ---

func test_alternating_effect_cycles_by_use_count() -> void:
	var even_effect: ApplyBuffEffect = ApplyBuffEffect.new()
	even_effect.buff_type = Types.Buff_Type.Empower
	even_effect.duration = 2
	var odd_effect: ApplyBuffEffect = ApplyBuffEffect.new()
	odd_effect.buff_type = Types.Buff_Type.Fortify
	odd_effect.duration = 2

	var effect: AlternatingEffect = AlternatingEffect.new()
	effect.effects = [even_effect, odd_effect]

	var skill: Skill = TestFactory.make_empty_skill()
	effect.Resolve(TestFactory.make_context(_resolver, 0, [0], skill, 0))
	assert_eq(_roster[0]._active_buffs[0].type, Types.Buff_Type.Empower)

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	effect.Resolve(TestFactory.make_context(_resolver, 0, [0], skill, 1))
	assert_eq(_roster[0]._active_buffs[0].type, Types.Buff_Type.Fortify)

func test_alternating_effect_use_count_is_independent_per_resolver() -> void:
	# ResolveSkill's own per-(resolver, skill name) use-count bookkeeping, not
	# AlternatingEffect's cycling logic, is under test here: a fresh resolver must start
	# its own alternation from the first use rather than sharing state with another.
	var even_effect: ApplyBuffEffect = ApplyBuffEffect.new()
	even_effect.target = Types.Skill_Target.Single_Ally
	even_effect.buff_type = Types.Buff_Type.Empower
	even_effect.duration = 2
	var odd_effect: ApplyBuffEffect = ApplyBuffEffect.new()
	odd_effect.target = Types.Skill_Target.Single_Ally
	odd_effect.buff_type = Types.Buff_Type.Fortify
	odd_effect.duration = 2
	var alternating: AlternatingEffect = AlternatingEffect.new()
	alternating.effects = [even_effect, odd_effect]
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Alternating Strike"
	skill.target = Types.Skill_Target.Single_Ally
	skill.effects = [alternating]

	var other_roster: Dictionary[int, Character] = {}
	other_roster.assign(TestFactory.make_full_roster())
	var other_resolver: BattleResolver = TestFactory.make_resolver(other_roster, TestFactory.make_full_sides())
	other_roster[0]._skills.append(skill)
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [1], 0)
	other_resolver.ResolveSkill(0, [1], 0)

	var empower_here: Array = _roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Empower)
	var empower_there: Array = other_roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Empower)
	assert_eq(empower_here.size(), 1)
	assert_eq(empower_there.size(), 1, "A separate resolver should start its own alternation from the first use")

# --- SkillCastContext.TargetsFor ---

func test_targets_for_uses_the_skills_own_targets_by_default() -> void:
	var effect: SkillEffect = SkillEffect.new()
	var skill: Skill = TestFactory.make_strike_skill()
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)

	assert_eq(context.TargetsFor(effect), [3])

func test_targets_for_resolves_independently_when_the_effect_overrides_the_target() -> void:
	var effect: SkillEffect = SkillEffect.new()
	effect.target = Types.Skill_Target.Self
	var skill: Skill = TestFactory.make_strike_skill()
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], skill)

	assert_eq(context.TargetsFor(effect), [0],
		"An overriding effect.target must resolve on its own, ignoring the skill's own [3] targets")

# --- SkillCastContext.ConditionMet ---

func test_condition_met_is_true_with_no_condition_authored() -> void:
	var effect: SkillEffect = SkillEffect.new()
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_true(context.ConditionMet(effect))

func test_condition_met_at_least_is_never_satisfied_without_a_trait() -> void:
	var effect: SkillEffect = SkillEffect.new()
	effect.condition = Types.Skill_Condition.Trait_Condition
	effect.condition_test = Types.Condition_Test.At_Least
	effect.condition_threshold = 1.0
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_false(context.ConditionMet(effect))

func test_condition_met_below_is_satisfied_without_a_trait() -> void:
	# A missing trait means a condition count of 0.0, which is below any positive
	# threshold — Condition_Test.Below must not treat a missing trait as automatically
	# unmet the way At_Least does.
	var effect: SkillEffect = SkillEffect.new()
	effect.condition = Types.Skill_Condition.Trait_Condition
	effect.condition_test = Types.Condition_Test.Below
	effect.condition_threshold = 6.0
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_true(context.ConditionMet(effect))

func test_condition_met_below_is_unmet_once_the_traits_count_reaches_the_threshold() -> void:
	var effect: SkillEffect = SkillEffect.new()
	effect.condition = Types.Skill_Condition.Trait_Condition
	effect.condition_test = Types.Condition_Test.Below
	effect.condition_threshold = 6.0
	_roster[0]._trait = TestFactory.FakeConditionCountTrait.new(Types.Trait_Count_Source.Trait_Condition, 9.0)
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_false(context.ConditionMet(effect))

func test_condition_met_chance_zero_never_resolves() -> void:
	var effect: SkillEffect = SkillEffect.new()
	effect.chance = 0.0
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_false(context.ConditionMet(effect))

func test_condition_met_chance_one_always_resolves() -> void:
	var effect: SkillEffect = SkillEffect.new()
	effect.chance = 1.0
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_true(context.ConditionMet(effect))

func test_condition_met_chance_rolls_independently_of_condition() -> void:
	# A chance of 0.0 must gate the effect out even when its authored condition would
	# otherwise pass.
	var effect: SkillEffect = SkillEffect.new()
	effect.chance = 0.0
	effect.condition = Types.Skill_Condition.Trait_Condition
	effect.condition_test = Types.Condition_Test.Below
	effect.condition_threshold = 6.0
	var context: SkillCastContext = TestFactory.make_context(_resolver, 0, [3], TestFactory.make_empty_skill())

	assert_false(context.ConditionMet(effect))

# --- ResolveSkill wiring (effects array runs alongside the flat-field pipeline) ---

func test_resolve_skill_runs_the_effects_array_in_authored_order() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	var first: ApplyBuffEffect = ApplyBuffEffect.new()
	first.buff_type = Types.Buff_Type.Empower
	first.duration = 2
	var second: ApplyBuffEffect = ApplyBuffEffect.new()
	second.buff_type = Types.Buff_Type.Fortify
	second.duration = 2
	skill.effects = [first, second]
	skill.target = Types.Skill_Target.Self
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._active_buffs.size(), 2)
	assert_eq(_roster[0]._active_buffs[0].type, Types.Buff_Type.Empower)
	assert_eq(_roster[0]._active_buffs[1].type, Types.Buff_Type.Fortify)

func test_resolve_skill_skips_an_effect_whose_condition_is_not_met() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var conditional: ApplyBuffEffect = ApplyBuffEffect.new()
	conditional.buff_type = Types.Buff_Type.Empower
	conditional.duration = 2
	conditional.condition = Types.Skill_Condition.Trait_Condition
	conditional.condition_test = Types.Condition_Test.At_Least
	conditional.condition_threshold = 1.0
	skill.effects = [conditional]
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._active_buffs.size(), 0, "No trait means Trait_Condition can never be met")

func test_condition_mutual_exclusion_below_vs_at_least_on_one_threshold_makes_only_one_attempt() -> void:
	# Two effects authored as a Below/At_Least split on the same threshold must be mutually
	# exclusive, not two independent attempts — otherwise a single Aegis on the target would
	# block only one and leave the other free to land.
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Single_Enemy
	var below_effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	below_effect.debuff_type = Types.Debuff_Type.Bleed
	below_effect.duration = 1
	below_effect.condition = Types.Skill_Condition.Trait_Condition
	below_effect.condition_test = Types.Condition_Test.Below
	below_effect.condition_threshold = 5.0
	var at_least_effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	at_least_effect.debuff_type = Types.Debuff_Type.Bleed
	at_least_effect.duration = 2
	at_least_effect.condition = Types.Skill_Condition.Trait_Condition
	at_least_effect.condition_test = Types.Condition_Test.At_Least
	at_least_effect.condition_threshold = 5.0
	skill.effects = [below_effect, at_least_effect]
	_roster[0]._trait = TestFactory.FakeConditionCountTrait.new(Types.Trait_Count_Source.Trait_Condition, 5.0)
	_roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[3]._attributes[Types.Attribute.Resistance] = 0
	var aegis: StatusEffects.Buff = StatusEffects.Buff.new()
	aegis.type = Types.Buff_Type.Aegis
	aegis.duration = 10
	_roster[3]._active_buffs.append(aegis)
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[3]._active_debuffs.size(), 0,
		"A single Aegis should block the one attempt whose condition is met")
	assert_eq(_roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Aegis).size(), 0,
		"Aegis should be consumed by blocking the attempt")

func test_resolve_skill_runs_an_effect_whose_condition_is_met() -> void:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Self
	var conditional: ApplyBuffEffect = ApplyBuffEffect.new()
	conditional.buff_type = Types.Buff_Type.Empower
	conditional.duration = 2
	conditional.condition = Types.Skill_Condition.Trait_Condition
	conditional.condition_test = Types.Condition_Test.At_Least
	conditional.condition_threshold = 1.0
	skill.effects = [conditional]
	_roster[0]._trait = TestFactory.FakeConditionCountTrait.new(Types.Trait_Count_Source.Trait_Condition, 1.0)
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._active_buffs.size(), 1, "An active Trait_Condition should let the effect run")
