extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Signed Writ (the holder cannot resist debuffs, including a Mirror Coat
# reflection) and Severance (the holder cannot gain new buffs), both blanket rule
# checks alongside Sequence Lock's precedent (Concept_Document.md 3.2.3.2).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

func _debuff_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Debuff"
	skill.target = Types.Skill_Target.Single_Enemy
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: Types.Debuff_Type.Enfeeble}
	return skill

func test_signed_writ_holder_never_resists_a_debuff() -> void:
	# Defender Resistance dominates attacker Accuracy, so this would normally resist.
	_roster[0]._attributes[Types.Attribute.Resistance] = 1000
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Signed_Writ))
	_roster[3]._skills.append(_debuff_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(3, [0], 0)

	assert_eq(results.filter(func(r): return r.kind == CombatResult.Kind.Debuff_Resisted).size(), 0,
		"A Signed Writ holder must never resist")
	var landed: Array = _roster[0]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Enfeeble)
	assert_eq(landed.size(), 1, "The debuff should land despite dominant Resistance")

func test_signed_writ_on_the_attacker_prevents_resisting_a_mirrored_debuff() -> void:
	# Original land: attacker Accuracy dominates holder Resistance.
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[0]._attributes[Types.Attribute.Resistance] = 1
	# Mirror roll would normally resist: attacker Resistance dominates holder Accuracy.
	_roster[0]._attributes[Types.Attribute.Accuracy] = 1
	_roster[3]._attributes[Types.Attribute.Resistance] = 1000
	_roster[3]._active_debuffs.append(_debuff(Types.Debuff_Type.Signed_Writ))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Mirror_Coat))
	_roster[3]._skills.append(_debuff_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(3, [0], 0)

	var mirrored: Array = _roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Enfeeble)
	assert_eq(mirrored.size(), 1, "Signed Writ on the attacker should prevent resisting the mirrored debuff")

func test_severance_blocks_a_new_buff_via_apply_buff() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Severance))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ApplyBuff(0, _buff(Types.Buff_Type.Empower))

	assert_eq(_roster[0]._active_buffs.size(), 0, "Severance should block a template-applied buff")

func test_severance_blocks_a_new_buff_via_skill_cast() -> void:
	var buff_skill: Skill = Skill.new()
	buff_skill.name = "Buff"
	buff_skill.target = Types.Skill_Target.Single_Ally
	buff_skill.duration = 2
	buff_skill.buffs = {Types.Skill_Target.Single_Ally: Types.Buff_Type.Empower}
	_roster[3]._skills.append(buff_skill)
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Severance))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(3, [0], 0)

	assert_eq(_roster[0]._active_buffs.size(), 0, "Severance should block a skill-cast buff")
