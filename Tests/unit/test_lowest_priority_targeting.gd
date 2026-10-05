extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Lowest_Priority_Enemy: the alive enemy of the caster with the lowest
# targeting priority, (Health + Defence) times the trait and buff multipliers
# (Concept_Document.md 3.2.1 "5. Enemy Target Selection").

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()
	_resolver = TestFactory.make_resolver(_roster, _sides)

func _spotlight() -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Spotlight
	return buff

func test_priority_is_health_plus_defence() -> void:
	var expected: float = (_roster[0]._attributes[Types.Attribute.Health]
			+ _roster[0]._attributes[Types.Attribute.Defence])
	assert_eq(Skills.TargetingPriority(_roster[0]), expected, "Priority should be Health + Defence")

func test_picks_the_enemy_with_the_lowest_health_plus_defence() -> void:
	_roster[1]._attributes[Types.Attribute.Defence] = 1
	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Lowest_Priority_Enemy)
	assert_eq(targets, [1], "Lowest_Priority_Enemy should pick the enemy with the lowest Health + Defence")

func test_current_health_does_not_lower_priority() -> void:
	_roster[2]._current_health = 1
	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Lowest_Priority_Enemy)
	assert_eq(targets, [0], "Priority reads total Health, so an injured enemy is not preferred; ties go to the lower ID")

func test_spotlight_multiplier_moves_the_pick() -> void:
	_roster[0]._attributes[Types.Attribute.Defence] = 4
	_roster[0]._active_buffs.append(_spotlight())
	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Lowest_Priority_Enemy)
	assert_eq(targets, [1], "Spotlight's 1.5x should lift the otherwise-lowest enemy above the others")

func test_dead_characters_are_skipped() -> void:
	_roster[1]._attributes[Types.Attribute.Defence] = 1
	_roster[1]._current_health = 0
	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Lowest_Priority_Enemy)
	assert_eq(targets, [0], "A dead enemy should never be picked")

func test_empty_when_every_enemy_is_dead() -> void:
	for id in [0, 1, 2]:
		_roster[id]._current_health = 0
	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Lowest_Priority_Enemy)
	assert_eq(targets, [] as Array[int], "No living enemy should resolve to no target")

func test_works_as_an_effect_target_beside_a_different_skill_target() -> void:
	_roster[2]._attributes[Types.Attribute.Defence] = 1
	var skill: Skill = TestFactory.make_strike_skill()
	var targets: Array[int] = SkillCastContext.ResolveStatusGroupTargets(
			_resolver, 3, [0], skill, Types.Skill_Target.Lowest_Priority_Enemy)
	assert_eq(targets, [2], "An effect targeting Lowest_Priority_Enemy should resolve apart from the skill's chosen target")

func test_targeting_help_highlights_the_lowest_priority_enemy() -> void:
	_roster[5]._attributes[Types.Attribute.Health] = 2
	var highlighted: Array[int] = TargetingHelp.HighlightedCharacters(
			Types.Skill_Target.Lowest_Priority_Enemy, 0, _roster, _sides, _resolver.GetMaxHealth)
	assert_eq(highlighted, [5] as Array[int], "Targeting help should highlight the lowest priority enemy")
