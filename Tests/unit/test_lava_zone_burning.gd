extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Lava zone Burning through the resolver: Burning stacks by design
# (Concept_Document.md 3.2.3.2), so each zone trigger adds another independent
# Burning debuff up to the status-effect cap. Zone occupancy comes from the
# TurnPositions stub, so the tests run fully headless.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.characters_in_zones = true
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	# Only the zone owner (0) and one victim (3) participate; everyone else is dead so
	# the single trigger-per-round lands on the victim deterministically.
	for id in [1, 2, 4, 5]:
		_roster[id]._current_health = 0

func after_each() -> void:
	for zone in _resolver.GetZones().values():
		zone.free()

func _place_lava_zone() -> void:
	var results: Array[CombatResult] = _resolver.PlaceZone(0, 0, TestFactory.make_lava_zone_skill())
	assert_eq(results.size(), 1, "Placing a lava zone should report Zone_Placed")

func test_lava_zone_stacks_burning() -> void:
	_place_lava_zone()

	_resolver.TriggerZones(0)
	_resolver.TriggerZones(0)

	assert_eq(_roster[3]._active_debuffs.size(), 2,
		"Each Lava-zone trigger should add another stacking Burning debuff")
	for debuff in _roster[3]._active_debuffs:
		assert_eq(debuff.type, Types.Debuff_Type.Burning, "Every stack should be a Burning debuff")

func test_lava_zone_respects_status_cap() -> void:
	_place_lava_zone()

	for _i in range(GameBalance.MAX_STATUS_EFFECTS + 3):
		_resolver.TriggerZones(0)

	assert_eq(_roster[3]._active_debuffs.size(), GameBalance.MAX_STATUS_EFFECTS,
		"Stacking Burning must not exceed the status-effect cap")

func test_zone_expires_after_duration_charges() -> void:
	_place_lava_zone()

	for _i in range(TestFactory.make_lava_zone_skill().duration):
		_resolver.TriggerZones(0)

	assert_false(_resolver.HasZone(0), "A zone should be erased once its charges are spent")
