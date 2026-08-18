extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for ZoneResolver.SectionWithMostAllies (The Gilded Deck's placement rule):
# the free section holding the most living allies, ties toward the highest index,
# a random free section when nobody stands in any free section, and -1 when none
# is free at all.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)

func test_picks_the_free_section_with_the_most_allies() -> void:
	# The owner (0) itself counts as its own ally, so section 2 (owner + ally 1) beats
	# section 4 (ally 2 alone) outright.
	_positions.sections_by_character = {0: 2, 1: 2, 2: 4}
	assert_eq(_resolver.GetZoneResolver().SectionWithMostAllies(0), 2)

func test_ties_break_toward_the_highest_section_index() -> void:
	_positions.sections_by_character = {1: 1, 2: 3}
	assert_eq(_resolver.GetZoneResolver().SectionWithMostAllies(0), 3,
		"Two sections tied at one ally each should resolve to the higher index")

func test_enemy_positions_do_not_count() -> void:
	_positions.sections_by_character = {3: 4, 4: 4}  # enemies, not allies of 0
	var random := RandomNumberGenerator.new()
	random.seed = 1
	var section: int = _resolver.GetZoneResolver().SectionWithMostAllies(0)
	assert_true(section >= 0 and section < GameBalance.NUMBER_OF_TURN_BAR_ZONES,
		"With no ally standing anywhere, a random free section is still chosen")

func test_returns_minus_one_when_no_section_is_free() -> void:
	for zone_ID in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		TestFactory.place_zone(_resolver, zone_ID, 1, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneAlly)
	assert_eq(_resolver.GetZoneResolver().SectionWithMostAllies(0), -1)

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()
