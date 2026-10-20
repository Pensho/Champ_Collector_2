extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# A character's own ticking statuses resolve when their turn starts, before they choose a
# skill, so a tick that kills them leaves no turn to take.

class FakeStartOfTurnRecorder extends CharacterTrait:
	var call_count: int = 0
	var health_seen: int = -1

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
		call_count += 1
		health_seen = p_resolver._characters[p_owner_ID]._current_health

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _add_bleed(p_target_ID: int, p_source_attack: int) -> void:
	_roster[1]._attributes[Types.Attribute.Attack] = p_source_attack
	var bleed: StatusEffects.Debuff = StatusEffects.Debuff.new()
	bleed.type = Types.Debuff_Type.Bleed
	bleed.duration = 2
	bleed.source_ID = 1
	_resolver.GetStatusResolver().ApplyDebuff(p_target_ID, bleed)

func _debuff_ticks(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result): return CombatResult.Kind.Debuff_Tick == result.kind)

func test_the_tick_resolves_when_the_turn_begins() -> void:
	_add_bleed(0, 10)
	assert_eq(_debuff_ticks(_resolver.BeginTurn(0)).size(), 1, "Bleed should tick when the turn begins")

func test_casting_does_not_tick_the_casters_own_statuses() -> void:
	_add_bleed(0, 10)
	_resolver.BeginTurn(0)
	assert_eq(_debuff_ticks(_resolver.ResolveSkill(0, [], 0)).size(), 0,
		"The cast should not tick Bleed a second time")

func test_the_start_of_turn_hook_sees_health_after_the_tick() -> void:
	var recorder: FakeStartOfTurnRecorder = FakeStartOfTurnRecorder.new()
	_roster[0]._trait = recorder
	_add_bleed(0, 10)
	_resolver.BeginTurn(0)
	assert_eq(recorder.call_count, 1)
	assert_eq(recorder.health_seen, _roster[0]._current_health, "The tick should resolve before the hook")

func test_a_lethal_tick_skips_the_start_of_turn_hook() -> void:
	var recorder: FakeStartOfTurnRecorder = FakeStartOfTurnRecorder.new()
	_roster[0]._trait = recorder
	_roster[0]._current_health = 1
	_add_bleed(0, 9999)
	var results: Array[CombatResult] = _resolver.BeginTurn(0)
	assert_eq(_roster[0]._current_health, 0, "Sanity check: the tick must be lethal")
	assert_eq(recorder.call_count, 0, "A character killed by their tick must not receive Start_Turn")
	assert_eq(results.filter(func(result): return CombatResult.Kind.Death == result.kind).size(), 1)
