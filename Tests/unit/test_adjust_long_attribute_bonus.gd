extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func test_positive_delta_raises_combat_attribute() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var before: int = resolver.GetCombatAttributes(0)[Types.Attribute.Resistance]

	resolver.AdjustLongAttributeBonus(0, Types.Attribute.Resistance, 5)

	assert_eq(resolver.GetCombatAttributes(0)[Types.Attribute.Resistance], before + 5)

func test_negative_delta_lowers_combat_attribute() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var before: int = resolver.GetCombatAttributes(0)[Types.Attribute.Resistance]

	resolver.AdjustLongAttributeBonus(0, Types.Attribute.Resistance, -3)

	assert_eq(resolver.GetCombatAttributes(0)[Types.Attribute.Resistance], before - 3)

func test_two_attributes_on_one_character_accumulate_independently() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var before_resistance: int = resolver.GetCombatAttributes(0)[Types.Attribute.Resistance]
	var before_attack: int = resolver.GetCombatAttributes(0)[Types.Attribute.Attack]

	resolver.AdjustLongAttributeBonus(0, Types.Attribute.Resistance, 4)
	resolver.AdjustLongAttributeBonus(0, Types.Attribute.Attack, 7)

	assert_eq(resolver.GetCombatAttributes(0)[Types.Attribute.Resistance], before_resistance + 4)
	assert_eq(resolver.GetCombatAttributes(0)[Types.Attribute.Attack], before_attack + 7)
