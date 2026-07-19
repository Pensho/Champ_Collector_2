extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Burning ticks through the resolver: a tick must be reported as a
# Debuff_Tick result (the view renders it as combat text), and must carry its damage
# keyed by the source that applied it, so the post-battle screen can credit the
# applier. Ticks run when the burning character acts, so the tests resolve an
# effect-free skill for the burning character.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _add_burning(p_character_ID: int, p_source_ID: int) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Burning
	debuff.duration = 2
	debuff.source_ID = p_source_ID
	_roster[p_character_ID]._active_debuffs.append(debuff)

func _set_max_health(p_character_ID: int, p_max_health: int) -> void:
	_roster[p_character_ID]._attributes[Types.Attribute.Health] = p_max_health
	_roster[p_character_ID]._current_health = p_max_health * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER

func _expected_tick(p_max_health: int) -> int:
	return int(floor((p_max_health * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))

func _burning_ticks(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == CombatResult.Kind.Debuff_Tick)

func test_burning_tick_produces_burning_result() -> void:
	_set_max_health(0, 100)
	_add_burning(0, 1)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	assert_eq(_burning_ticks(results).size(), 1, "A burning character's action should report one Debuff_Tick")

func test_burning_tick_reduces_health_by_expected_amount() -> void:
	_set_max_health(0, 100)
	_add_burning(0, 1)
	var health_before: int = _roster[0]._current_health
	_resolver.ResolveSkill(0, [], 0)
	assert_eq(_roster[0]._current_health, health_before - _expected_tick(100),
		"Burning should reduce health by 4% of max Health")

func test_burning_damage_attributed_to_source() -> void:
	_set_max_health(0, 100)
	_add_burning(0, 1)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_true(tick.amount_by_source.has(1), "Damage should be keyed by the applying source ID")
	assert_eq(tick.amount_by_source[1], _expected_tick(100),
		"The source should be credited with the full Burning tick damage")

func test_stacked_burning_from_same_source_accumulates() -> void:
	_set_max_health(0, 100)
	_add_burning(0, 2)
	_add_burning(0, 2)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount_by_source[2], _expected_tick(100) * 2,
		"Two Burning stacks from one source should sum in that source's attribution")

func test_stacked_burning_from_different_sources_kept_separate() -> void:
	_set_max_health(0, 100)
	_add_burning(0, 3)
	_add_burning(0, 4)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _burning_ticks(results)[0]
	assert_eq(tick.amount_by_source[3], _expected_tick(100), "Source 3 credited with its own stack")
	assert_eq(tick.amount_by_source[4], _expected_tick(100), "Source 4 credited with its own stack")

func test_non_damaging_debuff_reports_no_burning_tick() -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 2
	_roster[0]._active_debuffs.append(debuff)
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	assert_eq(_burning_ticks(results).size(), 0,
		"A non-damaging debuff should report no Burning tick")

func test_burning_can_kill_and_reports_death() -> void:
	_set_max_health(0, 100)
	_add_burning(0, 1)
	_roster[0]._current_health = 1
	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var deaths: Array[CombatResult] = results.filter(
		func(result): return result.kind == CombatResult.Kind.Death)
	assert_eq(deaths.size(), 1, "A lethal Burning tick should report the death")
	assert_eq(deaths[0].target_ID, 0)
	assert_eq(_roster[0]._current_health, 0, "Health must clamp at zero")
