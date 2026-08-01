extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Jester's kit: Pratfall Sting (Skill.bonus_damage_on_trait_condition,
# reading DoubleTheFunTrait.IsConditionActive) and Center Stage (a single skill granting
# two buffs with different durations via Skill.buff_duration_overrides).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _pratfall_sting_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Pratfall Sting"
	skill.damage_scaling = {Types.Attribute.Accuracy: 0.9}
	skill.bonus_damage_on_trait_condition = 0.3
	return skill

func _center_stage_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Center Stage"
	skill.target = Types.Skill_Target.Self
	skill.cooldown = 3
	skill.duration = 2
	skill.skill_type = Types.Skill_Type.Status_Effect
	skill.buffs = {Types.Skill_Target.Self: [Types.Buff_Type.Spotlight, Types.Buff_Type.Luck]}
	skill.buff_duration_overrides = {Types.Buff_Type.Luck: 1}
	return skill

# --- Pratfall Sting ---

func test_pratfall_sting_deals_bonus_damage_after_an_avoidance() -> void:
	var baseline_roster: Dictionary[int, Character] = {}
	baseline_roster.assign(TestFactory.make_full_roster())
	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	baseline_roster[0]._trait = DoubleTheFunTrait.new()
	baseline_roster[0]._trait.Init(Types.Rarity.Uncommon)
	baseline_roster[0]._skills.append(_pratfall_sting_skill())
	var baseline_health_before: int = baseline_roster[3]._current_health
	baseline_resolver.ResolveSkill(0, [3], 0)
	var baseline_damage: int = baseline_health_before - baseline_roster[3]._current_health

	var jester_trait: DoubleTheFunTrait = DoubleTheFunTrait.new()
	jester_trait.Init(Types.Rarity.Uncommon)
	jester_trait._avoided_since_last_turn = true
	_roster[0]._trait = jester_trait
	_roster[0]._skills.append(_pratfall_sting_skill())
	var health_before: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	var damage: int = health_before - _roster[3]._current_health
	assert_gt(damage, baseline_damage, "Pratfall Sting should deal bonus damage after an avoidance")

func test_pratfall_sting_avoidance_bonus_clears_after_the_jesters_own_turn_ends() -> void:
	var jester_trait: DoubleTheFunTrait = DoubleTheFunTrait.new()
	jester_trait.Init(Types.Rarity.Uncommon)
	jester_trait._avoided_since_last_turn = true
	_roster[0]._trait = jester_trait
	_roster[0]._skills.append(_pratfall_sting_skill())

	_resolver.ResolveSkill(0, [3], 0)

	assert_false(jester_trait.IsConditionActive(),
		"The avoidance flag should clear at the end of the Jester's own turn")

func test_pratfall_sting_deals_no_bonus_without_a_trait() -> void:
	_roster[0]._skills.append(_pratfall_sting_skill())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)

	assert_gt(results.filter(func(r): return r.kind == CombatResult.Kind.Damage).size(), 0,
		"Pratfall Sting should still deal its base damage with no trait attached")

# --- Center Stage ---

func test_center_stage_grants_spotlight_for_two_turns_and_luck_for_one() -> void:
	_roster[0]._skills.append(_center_stage_skill())

	_resolver.ResolveSkill(0, [0], 0)

	var spotlight: Array = _roster[0]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Spotlight)
	var luck: Array = _roster[0]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Luck)
	assert_eq(spotlight.size(), 1)
	assert_eq(spotlight[0].duration, 2)
	assert_eq(luck.size(), 1)
	assert_eq(luck[0].duration, 1)
