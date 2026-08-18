extends GutTest

## Coverage for Sharp Rebuttal's zone-gated Suppress rider (Role_Kit_Design.md 9.14):
## the damage effect always resolves, and Suppress applies only with a zone standing on
## the turn bar — read off the caster's own Field of Study trait via GetConditionCount.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	var scholar: Character = _roster[0]
	scholar._trait = FieldOfStudyTrait.new()
	scholar._trait.Init(Types.Rarity.Legendary)
	scholar._skills = [load("res://Data/Character_Skill_Variants/Attack_Skills/Sharp_Rebuttal.tres").duplicate(true)]
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func test_suppress_applies_with_a_zone_standing_on_the_turn_bar() -> void:
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(3), Types.Skill_Target.Skill_Default)

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_roster[3]._active_debuffs.any(func(d): return Types.Debuff_Type.Suppress == d.type))

func test_suppress_does_not_apply_with_no_zones_on_the_turn_bar() -> void:
	_resolver.ResolveSkill(0, [3], 0)

	assert_false(_roster[3]._active_debuffs.any(func(d): return Types.Debuff_Type.Suppress == d.type))

func test_damage_resolves_regardless_of_the_suppress_gate() -> void:
	var health_before: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	assert_lt(_roster[3]._current_health, health_before)
