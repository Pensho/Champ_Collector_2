extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Mirror Coat: a debuff that lands on the holder is rolled again
# (holder's Accuracy vs. the attacker's Resistance) and copied onto the attacker if
# that roll succeeds too (Concept_Document.md 3.2.3.2). Landing and mirroring are
# forced deterministic by making one side's relevant attribute dominate the other's,
# so the outcome does not depend on the resolver's random seed.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(_debuff_skill())

func _debuff_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Debuff"
	skill.target = Types.Skill_Target.Single_Enemy
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: Types.Debuff_Type.Enfeeble}
	return skill

func _mirror_buff() -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Mirror_Coat
	buff.duration = 2
	return buff

func test_mirrored_debuff_copies_onto_the_attacker_when_the_mirror_roll_succeeds() -> void:
	# Original land: attacker Accuracy dominates holder Resistance.
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[0]._attributes[Types.Attribute.Resistance] = 1
	# Mirror roll: holder Accuracy dominates attacker Resistance.
	_roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[3]._attributes[Types.Attribute.Resistance] = 1
	_roster[0]._active_buffs.append(_mirror_buff())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(3, [0], 0)

	assert_eq(_roster[0]._active_debuffs.size(), 1, "The original debuff should land on the holder")
	assert_eq(_roster[0]._active_debuffs[0].type, Types.Debuff_Type.Enfeeble)
	assert_eq(_roster[3]._active_debuffs.size(), 1, "A mirrored copy should land on the attacker")
	assert_eq(_roster[3]._active_debuffs[0].type, Types.Debuff_Type.Enfeeble)

func test_no_mirrored_copy_when_the_mirror_roll_is_resisted() -> void:
	# Original land: attacker Accuracy dominates holder Resistance.
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[0]._attributes[Types.Attribute.Resistance] = 1
	# Mirror roll: attacker Resistance dominates holder Accuracy.
	_roster[0]._attributes[Types.Attribute.Accuracy] = 1
	_roster[3]._attributes[Types.Attribute.Resistance] = 1000
	_roster[0]._active_buffs.append(_mirror_buff())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(3, [0], 0)

	assert_eq(_roster[0]._active_debuffs.size(), 1, "The original debuff should still land on the holder")
	assert_eq(_roster[3]._active_debuffs.size(), 0, "A resisted mirror roll must not copy the debuff")

func test_no_mirror_trigger_when_the_original_debuff_is_resisted() -> void:
	# Original land: holder Resistance dominates attacker Accuracy, so it is resisted.
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1
	_roster[0]._attributes[Types.Attribute.Resistance] = 1000
	_roster[0]._active_buffs.append(_mirror_buff())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(3, [0], 0)

	assert_eq(_roster[0]._active_debuffs.size(), 0, "The original debuff should be resisted")
	assert_eq(_roster[3]._active_debuffs.size(), 0, "Nothing landed, so Mirror Coat must not trigger")
