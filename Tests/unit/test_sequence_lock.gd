extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Sequence Lock blocks any Speed-touching status from being applied, through both the
# template path (ApplyBuff/ApplyDebuff) and the skill path (_CastBuff/_CastDebuff via
# ResolveSkill), per the "works through both" watch item in
# Plan_Status_Effect_Implementation.md. Non-Speed statuses must still land normally.

func _sequence_locked_roster() -> Dictionary[int, Character]:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var lock: StatusEffects.Debuff = StatusEffects.Debuff.new()
	lock.type = Types.Debuff_Type.Sequence_Lock
	lock.duration = 5
	roster[3]._active_debuffs.append(lock)
	return roster

func test_apply_buff_is_blocked_for_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Haste
	template.duration = 2

	resolver.ApplyBuff(3, template)

	var haste: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Haste)
	assert_eq(haste.size(), 0, "Haste must not be applied while Sequence Lock is active")

func test_apply_debuff_is_blocked_for_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Slow
	template.duration = 2

	resolver.ApplyDebuff(3, template)

	var slow: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Slow)
	assert_eq(slow.size(), 0, "Slow must not be applied while Sequence Lock is active")

func test_apply_buff_still_lands_for_non_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Empower
	template.duration = 2

	resolver.ApplyBuff(3, template)

	var empower: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Empower)
	assert_eq(empower.size(), 1, "Empower does not touch Speed and must still land")

func test_cast_debuff_is_blocked_for_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var skill: Skill = TestFactory.make_strike_skill()
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: Types.Debuff_Type.Slow}
	roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	roster[3]._attributes[Types.Attribute.Resistance] = 0

	resolver.ResolveSkill(0, [3], 0)

	var slow: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Slow)
	assert_eq(slow.size(), 0, "Slow must not land through the skill-cast path while Sequence Lock is active")

func test_cast_buff_is_blocked_for_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var skill: Skill = TestFactory.make_strike_skill()
	skill.damage_scaling = {}
	skill.target = Types.Skill_Target.Single_Ally
	skill.duration = 2
	skill.buffs = {Types.Skill_Target.Single_Ally: Types.Buff_Type.Haste}
	roster[3]._skills.append(skill)

	resolver.ResolveSkill(3, [3], 1)

	var haste: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Haste)
	assert_eq(haste.size(), 0, "Haste must not land through the skill-cast path while Sequence Lock is active")
