extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for ZoneResolver.ReplenishZoneCharge: caps the increment, no-ops at/above
# the cap, and is safe on a missing zone ID.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _place_zone(p_charges: int) -> void:
	var zone_effect: ZoneEffect = TestFactory.make_zone_effect(p_charges)
	TestFactory.place_zone(_resolver, 0, 0, zone_effect, Types.Skill_Target.ZoneAll)

func test_replenish_raises_duration_up_to_the_cap() -> void:
	_place_zone(2)

	_resolver.GetZoneResolver().ReplenishZoneCharge(0, 1, 5)

	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 3)

func test_replenish_emits_zone_duration_changed() -> void:
	_place_zone(2)
	_resolver._batch.clear()

	_resolver.GetZoneResolver().ReplenishZoneCharge(0, 1, 5)

	var changes: Array[CombatResult] = _resolver._batch.filter(
			func(r): return r.kind == CombatResult.Kind.Zone_Charges_Changed)
	assert_eq(changes.size(), 1)
	assert_eq(changes[0].zone_ID, 0)
	assert_eq(changes[0].charges, 3)

func test_replenish_is_capped_and_does_not_exceed_max_charges() -> void:
	_place_zone(4)

	_resolver.GetZoneResolver().ReplenishZoneCharge(0, 3, 5)

	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 5)

func test_replenish_is_a_no_op_at_the_cap() -> void:
	_place_zone(5)
	_resolver._batch.clear()

	_resolver.GetZoneResolver().ReplenishZoneCharge(0, 1, 5)

	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 5)
	var changes: Array[CombatResult] = _resolver._batch.filter(
			func(r): return r.kind == CombatResult.Kind.Zone_Charges_Changed)
	assert_true(changes.is_empty(), "No-op at the cap should not emit Zone_Charges_Changed")

func test_replenish_is_a_no_op_above_the_cap() -> void:
	_place_zone(7)
	_resolver._batch.clear()

	_resolver.GetZoneResolver().ReplenishZoneCharge(0, 1, 5)

	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 7)
	var changes: Array[CombatResult] = _resolver._batch.filter(
			func(r): return r.kind == CombatResult.Kind.Zone_Charges_Changed)
	assert_true(changes.is_empty(), "No-op above the cap should not emit Zone_Charges_Changed")

func test_replenish_is_safe_on_a_missing_zone_ID() -> void:
	_resolver.GetZoneResolver().ReplenishZoneCharge(3, 1, 5)

	assert_false(_resolver.GetZoneResolver().HasZone(3))
