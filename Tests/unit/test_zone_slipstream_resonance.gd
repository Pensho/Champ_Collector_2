extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Slipstream (passes through an enemy zone untriggered) and Resonance
# (an ally zone affects the holder at double effect), both read at zone-trigger time
# in BattleResolver.TriggerZones (Concept_Document.md 3.2.3.1). Zone occupancy comes
# from the TurnPositions stub, so the tests run fully headless.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.characters_in_zones = true
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)

func after_each() -> void:
	for zone in _resolver.GetZones().values():
		zone.free()

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _flicker_skill(p_target: Types.Skill_Target) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Flicker Zone"
	skill.target = p_target
	skill.skill_type = Types.Skill_Type.Flicker_Zone
	skill.duration = 10
	return skill

func test_slipstream_passes_through_an_enemy_zone_untriggered() -> void:
	for id in [1, 2, 4, 5]:
		_roster[id]._current_health = 0
	_roster[3]._active_buffs.append(_buff(Types.Buff_Type.Slipstream))
	_resolver.PlaceZone(0, 0, TestFactory.make_lava_zone_skill())

	var results: Array[CombatResult] = _resolver.TriggerZones(0)

	assert_eq(_roster[3]._active_debuffs.size(), 0, "Slipstream should prevent the enemy zone's effect")
	assert_eq(results.filter(func(r): return r.kind == CombatResult.Kind.Zone_Triggered).size(), 0,
		"A Slipstream pass-through should not report a trigger")
	assert_eq(_resolver.GetZones()[0]._duration, 10, "The zone's duration must not decrement on a pass-through")

func test_slipstream_does_not_block_an_ally_zone() -> void:
	for id in [2, 3, 4, 5]:
		_roster[id]._current_health = 0
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Slipstream))
	_resolver.PlaceZone(0, 0, _flicker_skill(Types.Skill_Target.ZoneAll))

	var results: Array[CombatResult] = _resolver.TriggerZones(0)

	assert_eq(results.filter(func(r): return r.kind == CombatResult.Kind.Zone_Triggered).size(), 1,
		"Slipstream should only block zones placed by an enemy")

func test_resonance_doubles_an_ally_zones_effect() -> void:
	for id in [2, 3, 4, 5]:
		_roster[id]._current_health = 0
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Resonance))
	_resolver.PlaceZone(0, 0, _flicker_skill(Types.Skill_Target.ZoneAlly))

	var results: Array[CombatResult] = _resolver.TriggerZones(0)

	var bumps: Array[CombatResult] = results.filter(
			func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump and r.target_ID == 1)
	assert_eq(bumps.size(), 2, "Resonance should double an ally zone's effect")

func test_without_resonance_an_ally_zone_effect_is_not_doubled() -> void:
	for id in [2, 3, 4, 5]:
		_roster[id]._current_health = 0
	_resolver.PlaceZone(0, 0, _flicker_skill(Types.Skill_Target.ZoneAlly))

	var results: Array[CombatResult] = _resolver.TriggerZones(0)

	var bumps: Array[CombatResult] = results.filter(
			func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump and r.target_ID == 1)
	assert_eq(bumps.size(), 1, "Without Resonance, an ally zone should trigger its effect once")
