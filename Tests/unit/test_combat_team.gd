extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary = {}
var _sides: CombatSides = null


func before_each() -> void:
	_roster = TestFactory.make_full_roster()
	_sides = CombatSides.new([0, 1, 2], [3, 4, 5])


# --- CombatTeam membership ---

func test_has_accepts_member() -> void:
	var team: CombatTeam = CombatTeam.new([0, 1, 2])
	assert_true(team.Has(0))
	assert_true(team.Has(2))


func test_has_rejects_non_member() -> void:
	var team: CombatTeam = CombatTeam.new([0, 1, 2])
	assert_false(team.Has(3), "An ID outside the team must not be a member")
	assert_false(team.Has(-1), "The no-turn sentinel must not be a member")


func test_empty_team_has_nothing() -> void:
	var team: CombatTeam = CombatTeam.new()
	assert_false(team.Has(0))
	assert_eq(team.members.size(), 0)


func test_members_are_copied_from_the_constructor_argument() -> void:
	var source_IDs: Array[int] = [0, 1]
	var team: CombatTeam = CombatTeam.new(source_IDs)
	source_IDs.append(2)
	assert_false(team.Has(2), "Mutating the source array must not change the team")


# --- CombatTeam alive filtering ---

func test_alive_members_returns_all_when_all_alive() -> void:
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	assert_eq(team.AliveMembers(_roster), [3, 4, 5])


func test_alive_members_excludes_dead() -> void:
	_roster[4]._current_health = 0
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	assert_eq(team.AliveMembers(_roster), [3, 5])


func test_alive_members_excludes_missing_slot() -> void:
	_roster.erase(5)
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	assert_eq(team.AliveMembers(_roster), [3, 4], "A never-filled slot must not count as alive")


func test_alive_members_empty_when_all_dead() -> void:
	for character_ID in [3, 4, 5]:
		_roster[character_ID]._current_health = 0
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	assert_eq(team.AliveMembers(_roster).size(), 0)


func test_alive_members_of_empty_team_is_empty() -> void:
	var team: CombatTeam = CombatTeam.new()
	assert_eq(team.AliveMembers(_roster).size(), 0)


# --- CombatTeam random selection ---

func test_random_alive_member_only_picks_living() -> void:
	_roster[3]._current_health = 0
	_roster[5]._current_health = 0
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	for _i in range(100):
		assert_eq(team.RandomAliveMember(_roster), 4, "Only the living member may be picked")


func test_random_alive_member_returns_minus_one_when_all_dead() -> void:
	for character_ID in [3, 4, 5]:
		_roster[character_ID]._current_health = 0
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	assert_eq(team.RandomAliveMember(_roster), -1)


func test_random_alive_member_returns_minus_one_for_empty_team() -> void:
	var team: CombatTeam = CombatTeam.new()
	assert_eq(team.RandomAliveMember(_roster), -1)


func test_random_alive_member_with_seeded_generator_is_deterministic() -> void:
	var team: CombatTeam = CombatTeam.new([3, 4, 5])
	var generator_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var generator_b: RandomNumberGenerator = RandomNumberGenerator.new()
	generator_a.seed = 1234
	generator_b.seed = 1234
	for _i in range(20):
		assert_eq(
				team.RandomAliveMember(_roster, generator_a),
				team.RandomAliveMember(_roster, generator_b),
				"Identically seeded generators must produce identical picks")


# --- CombatSides membership and lookups ---

func test_side_of_returns_the_owning_team() -> void:
	assert_eq(_sides.SideOf(0), _sides.player)
	assert_eq(_sides.SideOf(5), _sides.enemy)


func test_side_of_unknown_id_is_null() -> void:
	assert_null(_sides.SideOf(6))
	assert_null(_sides.SideOf(-1))


func test_allies_of_and_enemies_of() -> void:
	assert_eq(_sides.AlliesOf(1), _sides.player)
	assert_eq(_sides.EnemiesOf(1), _sides.enemy)
	assert_eq(_sides.AlliesOf(4), _sides.enemy)
	assert_eq(_sides.EnemiesOf(4), _sides.player)


func test_enemies_of_unknown_id_is_null() -> void:
	assert_null(_sides.EnemiesOf(9))


func test_has_spans_both_teams() -> void:
	assert_true(_sides.Has(0))
	assert_true(_sides.Has(5))
	assert_false(_sides.Has(6))


# --- CombatSides relationship checks ---

func test_are_allies() -> void:
	assert_true(_sides.AreAllies(0, 1))
	assert_true(_sides.AreAllies(3, 4))
	assert_true(_sides.AreAllies(2, 2), "A character is its own ally")
	assert_false(_sides.AreAllies(0, 3))
	assert_false(_sides.AreAllies(0, 7), "An unknown ID is nobody's ally")


func test_are_enemies() -> void:
	assert_true(_sides.AreEnemies(0, 3))
	assert_true(_sides.AreEnemies(5, 2))
	assert_false(_sides.AreEnemies(0, 1))
	assert_false(_sides.AreEnemies(3, 3), "A character is not its own enemy")
	assert_false(_sides.AreEnemies(0, 7), "An unknown ID is nobody's enemy")


# --- CombatSides cross-team helpers ---

func test_all_members_spans_both_teams() -> void:
	assert_eq(_sides.AllMembers(), [0, 1, 2, 3, 4, 5])


func test_sides_random_alive_member_spans_both_teams() -> void:
	for character_ID in [0, 1, 2, 3, 5]:
		_roster[character_ID]._current_health = 0
	for _i in range(100):
		assert_eq(_sides.RandomAliveMember(_roster), 4, "The one living combatant must be picked")


func test_sides_random_alive_member_returns_minus_one_when_everyone_is_dead() -> void:
	for character_ID in _roster.keys():
		_roster[character_ID]._current_health = 0
	assert_eq(_sides.RandomAliveMember(_roster), -1)


# --- Non-3-versus-3 rosters ---

func test_two_enemy_wave_has_no_phantom_slot() -> void:
	_roster.erase(5)
	var sides: CombatSides = CombatSides.new([0, 1, 2], [3, 4])
	assert_false(sides.enemy.Has(5), "A two-enemy wave must not contain slot 5")
	assert_eq(sides.enemy.AliveMembers(_roster), [3, 4])
	for _i in range(100):
		assert_true([3, 4].has(sides.enemy.RandomAliveMember(_roster)))


func test_single_enemy_wave() -> void:
	_roster.erase(4)
	_roster.erase(5)
	var sides: CombatSides = CombatSides.new([0, 1, 2], [3])
	assert_eq(sides.enemy.AliveMembers(_roster), [3])
	assert_eq(sides.EnemiesOf(0).RandomAliveMember(_roster), 3)
