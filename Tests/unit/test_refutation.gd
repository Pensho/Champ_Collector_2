extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

## Coverage for Refutation's ClearZoneEffect (Concept_Document.md 3.2.4.2): the
## enemy-placed damage branch, the ally-placed cooldown-refund branch, and the
## no-zone-to-clear no-op.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _cast_refutation(p_caster_ID: int, p_zone_ID: int) -> void:
	var skill: Skill = load("res://Data/Character_Skill_Variants/Support_Skills/Refutation.tres").duplicate(true)
	_roster[p_caster_ID]._skills = [skill]
	_resolver.SetPendingZoneSection(p_zone_ID)
	_resolver.ResolveSkill(p_caster_ID, [], 0)

func test_clearing_an_enemy_placed_zone_damages_the_placing_enemy_scaled_by_remaining_charges() -> void:
	TestFactory.place_zone(_resolver, 0, 3, TestFactory.make_zone_effect(5), Types.Skill_Target.ZoneAll)
	var enemy_health_before: int = _roster[3]._current_health

	_cast_refutation(0, 0)

	assert_false(_resolver.GetZoneResolver().HasZone(0), "The zone should be removed from the turn bar")
	assert_lt(_roster[3]._current_health, enemy_health_before,
		"The enemy who placed the zone should take damage scaling with its remaining charges")

func test_clearing_an_ally_placed_zone_reduces_the_placing_allys_zone_skill_cooldown() -> void:
	var catalyst_cloud: Skill = load("res://Data/Character_Skill_Variants/Zone_Skills/Catalyst_Cloud.tres").duplicate(true)
	catalyst_cloud.cooldown_left = 3
	_roster[1]._skills = [catalyst_cloud]
	TestFactory.place_zone(_resolver, 0, 1, TestFactory.make_zone_effect(5), Types.Skill_Target.ZoneAll,
			"Catalyst Cloud")

	_cast_refutation(0, 0)

	assert_false(_resolver.GetZoneResolver().HasZone(0), "The zone should be removed from the turn bar")
	assert_eq(catalyst_cloud.cooldown_left, 1, "Cooldown should be reduced by 2")

func test_clearing_an_ally_placed_zone_clamps_the_cooldown_reduction_at_zero() -> void:
	var catalyst_cloud: Skill = load("res://Data/Character_Skill_Variants/Zone_Skills/Catalyst_Cloud.tres").duplicate(true)
	catalyst_cloud.cooldown_left = 1
	_roster[1]._skills = [catalyst_cloud]
	TestFactory.place_zone(_resolver, 0, 1, TestFactory.make_zone_effect(5), Types.Skill_Target.ZoneAll,
			"Catalyst Cloud")

	_cast_refutation(0, 0)

	assert_eq(catalyst_cloud.cooldown_left, 0)

func test_refutation_with_no_zones_on_the_bar_is_a_safe_no_op() -> void:
	_cast_refutation(0, 0)  # Must not error even with nothing to clear.

	assert_eq(_resolver.GetZoneResolver().GetZones().size(), 0)
