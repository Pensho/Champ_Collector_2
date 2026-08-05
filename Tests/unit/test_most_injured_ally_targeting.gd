extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Types.Skill_Target.Most_Injured_Ally: Skills.MostInjured's ratio/tie-break
# rules directly, and its wiring as a caster-relative secondary status group (Fateful
# Glimpse's shape: damage a single enemy, heal the most injured ally) through the resolver.

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()
	_resolver = TestFactory.make_resolver(_roster, _sides)

func _test_max_health(p_character_ID: int) -> int:
	var character: Character = _roster[p_character_ID]
	return character._attributes[Types.Attribute.Health] * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER


func test_lowest_ratio_wins_over_lowest_absolute_health() -> void:
	# Character 0: 50/100 (50%). Character 1: 40/1000 (4%) - lower absolute Health,
	# but a much healthier ratio should still lose to it.
	_roster[0]._attributes[Types.Attribute.Health] = 25
	_roster[0]._current_health = 50
	_roster[1]._attributes[Types.Attribute.Health] = 250
	_roster[1]._current_health = 40

	var most_injured: int = Skills.MostInjured([0, 1], _roster, Callable(self, "_test_max_health"))

	assert_eq(most_injured, 1, "The lower current-Health-fraction character should be picked")


func test_ties_break_to_the_lowest_id() -> void:
	_roster[0]._attributes[Types.Attribute.Health] = 25
	_roster[0]._current_health = 50
	_roster[2]._attributes[Types.Attribute.Health] = 25
	_roster[2]._current_health = 50

	var most_injured: int = Skills.MostInjured([2, 0], _roster, Callable(self, "_test_max_health"))

	assert_eq(most_injured, 0, "A tied ratio should break to the lowest ID")


func test_dead_allies_are_excluded() -> void:
	_roster[0]._current_health = 0
	_roster[1]._attributes[Types.Attribute.Health] = 25
	_roster[1]._current_health = 10

	var most_injured: int = Skills.MostInjured([0, 1, 2], _roster, Callable(self, "_test_max_health"))

	assert_eq(most_injured, 1, "A dead character must not be selected")


func test_the_caster_is_eligible() -> void:
	_roster[0]._attributes[Types.Attribute.Health] = 25
	_roster[0]._current_health = 5

	var most_injured: int = Skills.MostInjured(_sides.AlliesOf(0).members, _roster, Callable(self, "_test_max_health"))

	assert_eq(most_injured, 0, "The caster should be a valid pick when it is the most injured")


func test_returns_negative_one_when_none_are_alive() -> void:
	for id in [0, 1, 2]:
		_roster[id]._current_health = 0

	var most_injured: int = Skills.MostInjured([0, 1, 2], _roster, Callable(self, "_test_max_health"))

	assert_eq(most_injured, -1)


func test_resolves_correctly_as_a_secondary_group_while_the_skills_own_target_is_an_enemy() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	var heal_effect: HealthChangeEffect = HealthChangeEffect.new()
	heal_effect.target = Types.Skill_Target.Most_Injured_Ally
	heal_effect.scaling = {Types.Attribute.Attack: 1.0}
	skill.effects.append(heal_effect)
	_roster[0]._skills.append(skill)
	_roster[1]._current_health = 1
	var target_health_before: int = _roster[3]._current_health
	var ally_0_health_before: int = _roster[0]._current_health
	var ally_1_health_before: int = _roster[1]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	assert_lt(_roster[3]._current_health, target_health_before, "The primary enemy target should still take damage")
	assert_gt(_roster[1]._current_health, ally_1_health_before, "The most injured ally should be healed")
	assert_eq(_roster[0]._current_health, ally_0_health_before, "The healthier caster should not receive the heal")
