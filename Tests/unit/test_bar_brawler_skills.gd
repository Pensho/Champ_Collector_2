extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const BAR_FIGHT = preload("res://Data/Character_Skill_Variants/Attack_Skills/Bar_Fight.tres")
const HEAP_ON = preload("res://Data/Character_Skill_Variants/Attack_Skills/Heap_On.tres")
const LIQUID_COURAGE = preload("res://Data/Character_Skill_Variants/Support_Skills/Liquid_Courage.tres")

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in [0, 1, 2]:
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_roster[0]._skills = [HEAP_ON, BAR_FIGHT, LIQUID_COURAGE]
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _sources_of_damage(p_results: Array[CombatResult]) -> Array:
	var sources: Array = []
	for result in p_results:
		if(CombatResult.Kind.Damage == result.kind and 3 == result.target_ID):
			sources.append(result.source_ID)
	return sources

func _add_debuff(p_character_ID: int, p_type: Types.Debuff_Type) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = 3
	_roster[p_character_ID]._active_debuffs.append(debuff)

func test_bar_fight_has_every_living_ally_use_their_basic_on_the_target() -> void:
	var sources: Array = _sources_of_damage(_resolver.ResolveSkill(0, [3], 1))
	assert_eq(sources, [0, 1, 2], "The Bar Brawler and both allies each hit once")

func test_bar_fight_applies_dead_weight_before_the_hits() -> void:
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 1)
	var dead_weight_index: int = results.find_custom(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Status_Applied == r.kind and 3 == r.target_ID)
	var first_hit_index: int = results.find_custom(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and 3 == r.target_ID)
	assert_gte(dead_weight_index, 0, "Dead Weight must land")
	assert_lt(dead_weight_index, first_hit_index, "Dead Weight goes first so every hit pushes the target back")

func test_bar_fight_advances_heap_on() -> void:
	_resolver.ResolveSkill(0, [3], 1)
	var modifier: CombinedDamageModifier = null
	for result in _resolver.ResolveSkill(0, [3], 0):
		if(CombatResult.Kind.Damage == result.kind and 0 == result.source_ID):
			modifier = result.combined_damage_modifier
	assert_almost_eq(modifier.Buckets()[&"Heap On (ramp)"], 0.2, 0.0001,
		"Bar Fight's resolution must count as a use of Heap On")

func test_a_stunned_ally_does_not_join() -> void:
	_add_debuff(1, Types.Debuff_Type.Stun)
	assert_eq(_sources_of_damage(_resolver.ResolveSkill(0, [3], 1)), [0, 2])

func test_a_dead_ally_does_not_join() -> void:
	_roster[2]._current_health = 0
	assert_eq(_sources_of_damage(_resolver.ResolveSkill(0, [3], 1)), [0, 1])

func test_liquid_courage_removes_exactly_one_debuff_from_self() -> void:
	_add_debuff(0, Types.Debuff_Type.Enfeeble)
	_add_debuff(0, Types.Debuff_Type.Suppress)
	_add_debuff(1, Types.Debuff_Type.Enfeeble)
	_resolver.ResolveSkill(0, [0], 2)
	assert_eq(_roster[0]._active_debuffs.size(), 1, "One of the caster's two debuffs is removed")
	assert_eq(_roster[1]._active_debuffs.size(), 1, "An ally's debuffs are untouched")

func test_liquid_courage_with_no_debuffs_still_resolves() -> void:
	_resolver.ResolveSkill(0, [0], 2)
	assert_true(_resolver._HasBuff(0, Types.Buff_Type.Vigor), "Vigor lands with nothing to remove")

func test_effective_health_reads_vigor_the_same_way_max_health_does() -> void:
	_resolver.ResolveSkill(0, [0], 2)
	assert_true(_resolver._HasBuff(0, Types.Buff_Type.Vigor))
	assert_eq(_resolver.GetEffectiveAttributes(0)[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER,
		_resolver.GetMaxHealth(0))

func test_heap_on_scales_with_vigors_raised_health() -> void:
	_roster[0]._attributes[Types.Attribute.Health] = 1000
	_roster[0]._current_health = 4000
	var plain_setup: BattleResolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var plain: int = _heap_on_damage(plain_setup)
	_roster[0]._skills[0].cooldown_left = 0
	var vigor: StatusEffects.Buff = StatusEffects.Buff.new()
	vigor.type = Types.Buff_Type.Vigor
	vigor.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Vigor).magnitude
	vigor.duration = 2
	_roster[0]._active_buffs.append(vigor)
	var buffed: int = _heap_on_damage(TestFactory.make_resolver(_roster, TestFactory.make_full_sides()))
	assert_almost_eq(float(buffed), plain * 1.3, plain * 0.02, "Vigor's +30% Health reaches Heap On's damage")

func _heap_on_damage(p_resolver: BattleResolver) -> int:
	var total: int = 0
	for result in p_resolver.ResolveSkill(0, [3], 0):
		if(CombatResult.Kind.Damage == result.kind and 3 == result.target_ID):
			total += result.amount
	return total
