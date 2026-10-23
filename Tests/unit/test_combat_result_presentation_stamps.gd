extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# The resolver stamps each result with the facts the battle view's presentation timeline
# needs: which section of ResolveSkill produced it, which top-level effect was resolving,
# and the target's Health right after it.

const CASTER_ID: int = 0
const TARGET_ID: int = 3

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _damage_effect() -> DamageEffect:
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.allow_critical = false
	return effect

func _cast(p_effects: Array[SkillEffect]) -> Array[CombatResult]:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Single_Enemy
	skill.effects = p_effects
	_roster[CASTER_ID]._skills.append(skill)
	var targets: Array[int] = [TARGET_ID]
	return _resolver.ResolveSkill(CASTER_ID, targets, _roster[CASTER_ID]._skills.size() - 1)

func _of_kind(p_results: Array[CombatResult], p_kind: CombatResult.Kind) -> Array[CombatResult]:
	var matching: Array[CombatResult] = []
	matching.assign(p_results.filter(func(p_result: CombatResult) -> bool: return p_result.kind == p_kind))
	return matching

func test_skill_effect_results_are_stamped_skill_effects_and_end_of_turn_results_post_cast() -> void:
	var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
	barrier.type = Types.Buff_Type.Barrier
	barrier.duration = 3
	barrier.value = 10.0
	_roster[CASTER_ID]._active_buffs.append(barrier)

	var results: Array[CombatResult] = _cast([_damage_effect()])

	var damage: Array[CombatResult] = _of_kind(results, CombatResult.Kind.Damage)
	var durations: Array[CombatResult] = _of_kind(results, CombatResult.Kind.Status_Duration)
	assert_eq(damage.size(), 1)
	assert_eq(durations.size(), 1, "The caster's buff should tick down at the end of the cast")
	assert_eq(damage[0].phase, CombatResult.Presentation_Phase.Skill_Effects)
	assert_eq(durations[0].phase, CombatResult.Presentation_Phase.Post_Cast)

func test_effect_index_names_the_top_level_effect_including_a_nested_one() -> void:
	var alternating: AlternatingEffect = AlternatingEffect.new()
	alternating.effects = [_damage_effect()]

	var results: Array[CombatResult] = _cast([_damage_effect(), alternating])

	var damage: Array[CombatResult] = _of_kind(results, CombatResult.Kind.Damage)
	assert_eq(damage.size(), 2)
	assert_eq(damage[0].effect_index, 0)
	assert_eq(damage[1].effect_index, 1, "A nested effect inherits its parent's index")

func test_results_outside_an_effect_have_no_effect_index() -> void:
	var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
	barrier.type = Types.Buff_Type.Barrier
	barrier.duration = 3
	barrier.value = 10.0
	_roster[CASTER_ID]._active_buffs.append(barrier)

	var results: Array[CombatResult] = _cast([_damage_effect()])

	assert_eq(_of_kind(results, CombatResult.Kind.Status_Duration)[0].effect_index, -1)

func test_each_hit_snapshots_the_targets_health_right_after_it() -> void:
	var health_before: int = _roster[TARGET_ID]._current_health

	var results: Array[CombatResult] = _cast([_damage_effect(), _damage_effect()])

	var damage: Array[CombatResult] = _of_kind(results, CombatResult.Kind.Damage)
	assert_eq(damage.size(), 2)
	assert_eq(damage[0].target_health_after, health_before - damage[0].amount)
	assert_eq(damage[1].target_health_after, _roster[TARGET_ID]._current_health)
	assert_eq(damage[1].target_max_health_after, _resolver.GetMaxHealth(TARGET_ID))
