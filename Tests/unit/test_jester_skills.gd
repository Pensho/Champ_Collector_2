extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Regression coverage for the Jester's shipped skills. General content coverage lives in
# test_skill_content_sweep.gd; this covers Burning Bolas' two-debuff application.

func _guarantee_debuffs_land(p_roster: Dictionary[int, Character]) -> void:
	p_roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	p_roster[3]._attributes[Types.Attribute.Resistance] = 0

func test_burning_bolas_applies_both_burning_and_hexed() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var skill: Skill = load("res://Data/Character_Skill_Variants/Attack_Skills/Burning_Bolas.tres")
	roster[0]._skills = [skill]
	_guarantee_debuffs_land(roster)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveSkill(0, [3], 0)

	var debuff_types: Array[Types.Debuff_Type] = []
	for debuff in roster[3]._active_debuffs:
		debuff_types.append(debuff.type)
	assert_true(debuff_types.has(Types.Debuff_Type.Burning), "Burning Bolas should apply Burning")
	assert_true(debuff_types.has(Types.Debuff_Type.Hexed), "Burning Bolas should apply Hexed")

func test_burning_bolas_hexed_lasts_two_turns() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var skill: Skill = load("res://Data/Character_Skill_Variants/Attack_Skills/Burning_Bolas.tres")
	roster[0]._skills = [skill]
	_guarantee_debuffs_land(roster)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveSkill(0, [3], 0)

	var hexed: StatusEffects.Debuff = null
	for debuff in roster[3]._active_debuffs:
		if(debuff.type == Types.Debuff_Type.Hexed):
			hexed = debuff
	assert_not_null(hexed, "Hexed should have landed")
	assert_eq(hexed.duration, 2, "Hexed should last 2 turns")
