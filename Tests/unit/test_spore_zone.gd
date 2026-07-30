extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the dual-faction Spore zone through the resolver: one placement should
# regenerate allies standing in it and blight enemies standing in it, magnitude scaled
# by the owner's snapshotted Knowledge (Skills.ZoneMagnitude).

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.characters_in_zones = true
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	# Only the zone owner (0), one ally (1), and one enemy (3) participate; everyone
	# else is dead so the single trigger-per-round lands on them deterministically.
	for id in [2, 4, 5]:
		_roster[id]._current_health = 0

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _place_spore_zone(p_owner_knowledge: int) -> void:
	_roster[0]._attributes[Types.Attribute.Knowledge] = p_owner_knowledge
	var zone_skill: Skill = Skill.new()
	zone_skill.name = "Spore Bloom"
	zone_skill.target = Types.Skill_Target.ZoneAll
	zone_skill.skill_type = Types.Skill_Type.Spore_Zone
	zone_skill.duration = 5
	var results: Array[CombatResult] = _resolver.GetZoneResolver().PlaceZone(0, 0, zone_skill)
	assert_eq(results.size(), 1, "Placing a Spore zone should report Zone_Placed")

func test_spore_zone_regenerates_the_ally_and_blights_the_enemy() -> void:
	_place_spore_zone(0)

	_resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(_roster[1]._active_buffs.size(), 1, "The ally standing in the zone should be regenerated")
	assert_eq(_roster[1]._active_buffs[0].type, Types.Buff_Type.Regeneration)
	assert_eq(_roster[1]._active_buffs[0].duration, 1)

	assert_eq(_roster[3]._active_debuffs.size(), 1, "The enemy standing in the zone should be blighted")
	assert_eq(_roster[3]._active_debuffs[0].type, Types.Debuff_Type.Blight)
	assert_eq(_roster[3]._active_debuffs[0].duration, 1)
	assert_eq(_roster[3]._active_debuffs[0].source_ID, 0)

func test_spore_zone_regeneration_value_matches_zone_magnitude_at_low_knowledge() -> void:
	_place_spore_zone(0)

	_resolver.GetZoneResolver().TriggerZones(0)

	var expected: float = Skills.ZoneMagnitude(
			StatusEffectRegistry.BuffData(Types.Buff_Type.Regeneration).magnitude, 0)
	assert_almost_eq(_roster[1]._active_buffs[0].value, expected, 0.0001)

func test_spore_zone_regeneration_value_matches_zone_magnitude_at_high_knowledge() -> void:
	_place_spore_zone(200)

	_resolver.GetZoneResolver().TriggerZones(0)

	var expected: float = Skills.ZoneMagnitude(
			StatusEffectRegistry.BuffData(Types.Buff_Type.Regeneration).magnitude, 200)
	assert_almost_eq(_roster[1]._active_buffs[0].value, expected, 0.0001)
	assert_gt(expected, StatusEffectRegistry.BuffData(Types.Buff_Type.Regeneration).magnitude,
			"Higher owner Knowledge should scale the Regeneration value above its base")

func test_spore_zone_blight_value_matches_zone_magnitude_at_high_knowledge() -> void:
	_place_spore_zone(200)

	_resolver.GetZoneResolver().TriggerZones(0)

	var expected: float = Skills.ZoneMagnitude(
			StatusEffectRegistry.DebuffData(Types.Debuff_Type.Blight).magnitude, 200)
	assert_almost_eq(_roster[3]._active_debuffs[0].value, expected, 0.0001)
