extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary = {}
var _sides: CombatSides = null

func before_each() -> void:
	_roster = TestFactory.make_full_roster()
	_sides = TestFactory.make_full_sides()

# Thin wrapper so the many targeting cases below read the same as before the
# characters dictionary and the sides became required arguments.
func _find(p_target_ID: int, p_caster_ID: int, p_target_type: Types.Skill_Target) -> Array[int]:
	return Skills.FindSkillTargets(p_target_ID, p_caster_ID, p_target_type, _roster, _sides, null, _MaxHealth)

func _MaxHealth(p_character_ID: int) -> int:
	var character: Character = _roster[p_character_ID]
	return character.GetTotalAttribute(Types.Attribute.Health)

# --- FindSkillTargets ---

func test_single_enemy_player_vs_monster() -> void:
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 1, "Single Enemy should return exactly one target")
	assert_eq(targets[0], 3, "Target ID should be the chosen enemy")

func test_single_enemy_monster_vs_player() -> void:
	var targets: Array[int] = _find(1, 3, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 1, "Monster caster should hit the chosen player")
	assert_eq(targets[0], 1)

func test_single_enemy_rejects_friendly_target() -> void:
	# Player caster targeting another player — not a valid Single_Enemy target
	var targets: Array[int] = _find(1, 0, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 0, "Single_Enemy must not target a friendly")

func test_all_enemies_player_caster() -> void:
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.All_Enemies)
	assert_eq(targets.size(), 3, "All_Enemies from a player should return all 3 monster IDs")
	for id in [3, 4, 5]:
		assert_true(targets.has(id), "Monster ID %d must be in All_Enemies targets" % id)

func test_all_enemies_monster_caster() -> void:
	var targets: Array[int] = _find(0, 3, Types.Skill_Target.All_Enemies)
	assert_eq(targets.size(), 3, "All_Enemies from a monster should return all 3 player IDs")
	for id in [0, 1, 2]:
		assert_true(targets.has(id), "Player ID %d must be in All_Enemies targets" % id)

func test_single_ally_player_caster() -> void:
	var targets: Array[int] = _find(1, 0, Types.Skill_Target.Single_Ally)
	assert_eq(targets.size(), 1)
	assert_eq(targets[0], 1, "Single_Ally should target the chosen ally")

func test_single_ally_rejects_enemy_target() -> void:
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Single_Ally)
	assert_eq(targets.size(), 0, "Single_Ally must not target an enemy")

func test_all_allies_player_caster() -> void:
	var targets: Array[int] = _find(1, 0, Types.Skill_Target.All_Allies)
	assert_eq(targets.size(), 3, "All_Allies from player should return all 3 player IDs")
	for id in [0, 1, 2]:
		assert_true(targets.has(id), "Player ID %d must be in All_Allies targets" % id)

func test_all_allies_returns_empty_when_target_is_enemy() -> void:
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.All_Allies)
	assert_eq(targets.size(), 0, "All_Allies should be empty when the target is an enemy")

func test_ally_not_self_excludes_caster() -> void:
	var targets: Array[int] = _find(0, 0, Types.Skill_Target.Ally_Not_Self)
	assert_eq(targets.size(), 0, "Ally_Not_Self must not return the caster's own ID")

func test_ally_not_self_allows_other_ally() -> void:
	var targets: Array[int] = _find(1, 0, Types.Skill_Target.Ally_Not_Self)
	assert_eq(targets.size(), 1)
	assert_eq(targets[0], 1)

func test_all_target() -> void:
	var targets: Array[int] = _find(0, 0, Types.Skill_Target.All)
	assert_eq(targets.size(), 6, "All should return all 6 combatant IDs")

func test_all_other_allies_excludes_caster() -> void:
	var targets: Array[int] = _find(1, 0, Types.Skill_Target.All_Other_Allies)
	assert_false(targets.has(0), "All_Other_Allies should exclude the caster (ID 0)")
	assert_true(targets.has(1), "All_Other_Allies should include other ally IDs")
	assert_true(targets.has(2), "All_Other_Allies should include other ally IDs")

# --- Left_Most_Enemy / Right_Most_Enemy / Most_Injured_Enemy ---

func test_left_most_enemy_is_the_first_slot_in_party_order() -> void:
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Left_Most_Enemy)
	assert_eq(targets, [3], "Left_Most_Enemy should resolve to the first enemy slot (ID 3)")

func test_right_most_enemy_is_the_last_slot_in_party_order() -> void:
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Right_Most_Enemy)
	assert_eq(targets, [5], "Right_Most_Enemy should resolve to the last enemy slot (ID 5)")

func test_left_most_enemy_skips_a_dead_edge_slot() -> void:
	_roster[3]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Left_Most_Enemy)
	assert_eq(targets, [4], "Left_Most_Enemy must skip a dead left-edge slot for the next alive one")

func test_right_most_enemy_skips_a_dead_edge_slot() -> void:
	_roster[5]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Right_Most_Enemy)
	assert_eq(targets, [4], "Right_Most_Enemy must skip a dead right-edge slot for the next alive one")

func test_left_most_enemy_empty_when_all_enemies_dead() -> void:
	for id in [3, 4, 5]:
		_roster[id]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Left_Most_Enemy)
	assert_eq(targets.size(), 0, "Left_Most_Enemy returns nothing when every enemy is dead")

func test_left_most_enemy_reads_the_static_party_order_not_caster_relative() -> void:
	# From a monster caster, "enemies" is the player side [0, 1, 2]; left-most is still
	# the first slot in that side's fixed order, not related to the monster's own slot.
	var targets: Array[int] = _find(0, 3, Types.Skill_Target.Left_Most_Enemy)
	assert_eq(targets, [0], "Left_Most_Enemy from a monster caster should hit player slot 0")

func test_most_injured_enemy_picks_the_lowest_health_ratio() -> void:
	_roster[4]._current_health = 3
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Most_Injured_Enemy)
	assert_eq(targets, [4], "Most_Injured_Enemy should pick the enemy with the lowest Health ratio")

func test_left_most_enemy_is_not_redirected_by_spotlight() -> void:
	# Positional targeting is absolute and must not be pulled toward a Spotlight holder
	# that isn't the actual left-most slot.
	var spotlight: StatusEffects.Buff = StatusEffects.Buff.new()
	spotlight.type = Types.Buff_Type.Spotlight
	_roster[5]._active_buffs.append(spotlight)
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Left_Most_Enemy)
	assert_eq(targets, [3], "Left_Most_Enemy must ignore Spotlight and still resolve to the left-most slot")

func test_most_injured_enemy_ignores_a_dead_enemy() -> void:
	_roster[4]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Most_Injured_Enemy)
	assert_false(targets.has(4), "Most_Injured_Enemy must not select a dead enemy")
	assert_eq(targets.size(), 1)

# --- Dead / missing target exclusion ---

func test_all_enemies_excludes_dead_enemy() -> void:
	_roster[4]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.All_Enemies)
	assert_false(targets.has(4), "All_Enemies must not include a dead enemy")
	assert_true(targets.has(3) and targets.has(5), "All_Enemies keeps the living enemies")
	assert_eq(targets.size(), 2, "Only the two living enemies remain")

func test_random_enemy_never_returns_dead_enemy() -> void:
	_roster[3]._current_health = 0
	_roster[5]._current_health = 0
	for _i in range(200):
		var targets: Array[int] = _find(3, 0, Types.Skill_Target.Random_Enemy)
		assert_eq(targets.size(), 1, "Random_Enemy should still find the one living enemy")
		assert_eq(targets[0], 4, "Random_Enemy must only pick the living enemy")

func test_random_enemy_empty_when_all_enemies_dead() -> void:
	for id in [3, 4, 5]:
		_roster[id]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Random_Enemy)
	assert_eq(targets.size(), 0, "Random_Enemy returns nothing when every enemy is dead")

func test_single_enemy_excludes_dead_target() -> void:
	_roster[3]._current_health = 0
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 0, "Single_Enemy must not resolve against a dead target")

func test_missing_slot_is_excluded() -> void:
	_roster.erase(4)
	var targets: Array[int] = _find(3, 0, Types.Skill_Target.All_Enemies)
	assert_false(targets.has(4), "A missing character slot must not be targeted")

# --- RollsCritical ---

func test_zero_crit_chance_never_crits() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	for _i in range(1000):
		assert_false(Skills.RollsCritical(0, random), "0%% crit chance must never roll a critical")

func test_full_crit_chance_always_crits() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	for _i in range(1000):
		assert_true(Skills.RollsCritical(100, random), "100%% crit chance must always roll a critical")

# --- CorrectZoneTarget ---

func test_zone_all_always_triggers() -> void:
	assert_true(Skills.CorrectZoneTarget(0, 3, Types.Skill_Target.ZoneAll, _sides),
		"ZoneAll should trigger for any combatant")
	assert_true(Skills.CorrectZoneTarget(3, 0, Types.Skill_Target.ZoneAll, _sides),
		"ZoneAll should trigger for any combatant")

func test_zone_ally_triggers_for_same_team() -> void:
	assert_true(Skills.CorrectZoneTarget(0, 1, Types.Skill_Target.ZoneAlly, _sides),
		"ZoneAlly: player zone owner, player trigger → true")
	assert_true(Skills.CorrectZoneTarget(3, 4, Types.Skill_Target.ZoneAlly, _sides),
		"ZoneAlly: monster zone owner, monster trigger → true")

func test_zone_ally_does_not_trigger_for_enemy() -> void:
	assert_false(Skills.CorrectZoneTarget(0, 3, Types.Skill_Target.ZoneAlly, _sides),
		"ZoneAlly: player zone, monster trigger → false")
	assert_false(Skills.CorrectZoneTarget(3, 0, Types.Skill_Target.ZoneAlly, _sides),
		"ZoneAlly: monster zone, player trigger → false")

func test_zone_enemy_triggers_for_opposing_team() -> void:
	assert_true(Skills.CorrectZoneTarget(0, 3, Types.Skill_Target.ZoneEnemy, _sides),
		"ZoneEnemy: player zone owner, monster trigger → true")
	assert_true(Skills.CorrectZoneTarget(3, 0, Types.Skill_Target.ZoneEnemy, _sides),
		"ZoneEnemy: monster zone owner, player trigger → true")

func test_zone_enemy_does_not_trigger_for_ally() -> void:
	assert_false(Skills.CorrectZoneTarget(0, 1, Types.Skill_Target.ZoneEnemy, _sides),
		"ZoneEnemy: player zone, player trigger → false")
	assert_false(Skills.CorrectZoneTarget(3, 4, Types.Skill_Target.ZoneEnemy, _sides),
		"ZoneEnemy: monster zone, monster trigger → false")

# --- Non-3-versus-3 rosters ---

func test_all_enemies_two_enemy_wave_has_no_phantom_slot() -> void:
	_roster.erase(5)
	var two_enemy_sides: CombatSides = CombatSides.new([0, 1, 2], [3, 4])
	var targets: Array[int] = Skills.FindSkillTargets(
			3, 0, Types.Skill_Target.All_Enemies, _roster, two_enemy_sides)
	assert_eq(targets.size(), 2, "A two-enemy wave yields exactly two targets")
	assert_false(targets.has(5), "The never-filled slot 5 must not be targeted")

func test_random_enemy_two_enemy_wave_only_picks_fielded_slots() -> void:
	_roster.erase(5)
	var two_enemy_sides: CombatSides = CombatSides.new([0, 1, 2], [3, 4])
	for _i in range(100):
		var targets: Array[int] = Skills.FindSkillTargets(
				3, 0, Types.Skill_Target.Random_Enemy, _roster, two_enemy_sides)
		assert_eq(targets.size(), 1)
		assert_true([3, 4].has(targets[0]), "Random_Enemy must only pick fielded enemies")

# --- Barrier ---

func test_barrier_with_zero_attribute_and_bonus_returns_ceiled_base() -> void:
	assert_eq(Skills.Barrier(24.5, 1.0, 0), 25)

func test_barrier_scales_additively_with_the_attribute() -> void:
	var low: int = Skills.Barrier(25.0, 0.75, 10)
	var high: int = Skills.Barrier(25.0, 0.75, 100)
	assert_true(high > low, "A higher attribute value must yield a larger Barrier")

func test_barrier_applies_bonus_as_a_multiplier_on_top_of_base_plus_attribute() -> void:
	var raw: float = 25.0 + 0.75 * 75
	var with_bonus: int = Skills.Barrier(25.0, 0.75, 75, 0.24)
	assert_eq(with_bonus, int(ceil(raw * 1.24)))

# --- MostBuffed ---

func test_most_buffed_picks_the_highest_buff_count() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	_roster[0]._active_buffs.append(buff)
	_roster[1]._active_buffs.append(buff)
	_roster[1]._active_buffs.append(buff)

	assert_eq(Skills.MostBuffed([0, 1, 2], _roster), 1, "The ally with the most buffs should be picked")

func test_most_buffed_ties_break_to_the_earliest_id() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	_roster[0]._active_buffs.append(buff)
	_roster[2]._active_buffs.append(buff)

	assert_eq(Skills.MostBuffed([2, 0], _roster), 2, "The earliest candidate in the given order should win a tie")

func test_most_buffed_excludes_dead_candidates() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	_roster[0]._active_buffs.append(buff)
	_roster[0]._active_buffs.append(buff)
	_roster[0]._current_health = 0

	assert_eq(Skills.MostBuffed([0, 1], _roster), 1, "A dead character must not be selected")

func test_most_buffed_returns_negative_one_when_none_are_alive() -> void:
	for id in [0, 1, 2]:
		_roster[id]._current_health = 0

	assert_eq(Skills.MostBuffed([0, 1, 2], _roster), -1)
