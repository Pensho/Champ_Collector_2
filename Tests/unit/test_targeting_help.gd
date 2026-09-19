extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()

func _highlighted(p_target_type: Types.Skill_Target, p_caster_ID: int = 0) -> Array[int]:
	return TargetingHelp.HighlightedCharacters(p_target_type, p_caster_ID, _roster, _sides, _MaxHealth)

func _MaxHealth(p_character_ID: int) -> int:
	return _roster[p_character_ID].GetTotalAttribute(Types.Attribute.Health)

func _sorted(p_IDs: Array[int]) -> Array[int]:
	var copy: Array[int] = p_IDs.duplicate()
	copy.sort()
	return copy

# --- HighlightedCharacters ---

func test_enemy_target_types_highlight_every_alive_enemy() -> void:
	for target_type: Types.Skill_Target in [
			Types.Skill_Target.Single_Enemy, Types.Skill_Target.All_Enemies, Types.Skill_Target.Random_Enemy]:
		assert_eq(_sorted(_highlighted(target_type)), [3, 4, 5] as Array[int],
				"%s should highlight every enemy" % Types.Skill_Target.keys()[target_type])

func test_ally_target_types_highlight_every_alive_ally_including_caster() -> void:
	for target_type: Types.Skill_Target in [
			Types.Skill_Target.Single_Ally, Types.Skill_Target.All_Allies, Types.Skill_Target.Random_Ally]:
		assert_eq(_sorted(_highlighted(target_type)), [0, 1, 2] as Array[int],
				"%s should highlight every ally" % Types.Skill_Target.keys()[target_type])

func test_other_ally_target_types_exclude_the_caster() -> void:
	for target_type: Types.Skill_Target in [
			Types.Skill_Target.Ally_Not_Self, Types.Skill_Target.All_Other_Allies]:
		assert_eq(_sorted(_highlighted(target_type, 1)), [0, 2] as Array[int],
				"%s should skip the caster" % Types.Skill_Target.keys()[target_type])

func test_random_one_and_all_highlight_everyone_alive() -> void:
	assert_eq(_sorted(_highlighted(Types.Skill_Target.Random_One)), [0, 1, 2, 3, 4, 5] as Array[int])
	assert_eq(_sorted(_highlighted(Types.Skill_Target.All)), [0, 1, 2, 3, 4, 5] as Array[int])

func test_self_highlights_only_the_caster() -> void:
	assert_eq(_highlighted(Types.Skill_Target.Self, 2), [2] as Array[int])

func test_enemy_caster_sees_players_as_enemies() -> void:
	assert_eq(_sorted(_highlighted(Types.Skill_Target.Single_Enemy, 4)), [0, 1, 2] as Array[int])

func test_dead_characters_are_never_highlighted() -> void:
	_roster[4]._current_health = 0
	_roster[1]._current_health = 0
	assert_eq(_sorted(_highlighted(Types.Skill_Target.All_Enemies)), [3, 5] as Array[int])
	assert_eq(_sorted(_highlighted(Types.Skill_Target.All)), [0, 2, 3, 5] as Array[int])

func test_most_injured_ally_highlights_the_lowest_health_ratio() -> void:
	_roster[2]._current_health = 1
	assert_eq(_highlighted(Types.Skill_Target.Most_Injured_Ally), [2] as Array[int])

func test_most_injured_enemy_highlights_the_lowest_health_ratio() -> void:
	_roster[5]._current_health = 1
	assert_eq(_highlighted(Types.Skill_Target.Most_Injured_Enemy), [5] as Array[int])

func test_edge_most_enemy_skips_dead_edges() -> void:
	_roster[3]._current_health = 0
	assert_eq(_highlighted(Types.Skill_Target.Left_Most_Enemy), [4] as Array[int])
	assert_eq(_highlighted(Types.Skill_Target.Right_Most_Enemy), [5] as Array[int])

func test_zone_target_types_highlight_no_characters() -> void:
	for target_type: Types.Skill_Target in [
			Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy]:
		assert_eq(_highlighted(target_type), [] as Array[int])

# --- HighlightedSections ---

func test_placing_highlights_empty_sections_and_clearing_highlights_occupied_ones() -> void:
	var resolver: BattleResolver = TestFactory.make_resolver(_roster, _sides)
	TestFactory.place_zone(resolver, 1, 0, TestFactory.make_zone_effect(3), Types.Skill_Target.ZoneEnemy)

	var empty_sections: Array[int] = TargetingHelp.HighlightedSections(false, resolver.GetZoneResolver())
	assert_false(empty_sections.has(1), "An occupied section cannot take a new zone")
	assert_eq(empty_sections.size(), GameBalance.NUMBER_OF_TURN_BAR_ZONES - 1)
	assert_eq(TargetingHelp.HighlightedSections(true, resolver.GetZoneResolver()), [1] as Array[int])

# --- ReagentTargetType ---

func test_reagent_target_kinds_map_to_single_target_types() -> void:
	assert_eq(TargetingHelp.ReagentTargetType(ReagentData.TargetKind.One_Ally), Types.Skill_Target.Single_Ally)
	assert_eq(TargetingHelp.ReagentTargetType(ReagentData.TargetKind.One_Enemy), Types.Skill_Target.Single_Enemy)
