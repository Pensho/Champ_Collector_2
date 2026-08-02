extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Sequence Lock blocks any Speed-touching status from being applied, through both the
# template path (ApplyBuff/ApplyDebuff) and the skill path (the ApplyBuffEffect/
# ApplyDebuffEffect/CastDebuff route via ResolveSkill). Non-Speed statuses must still
# land normally.

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

	resolver.GetStatusResolver().ApplyBuff(3, template)

	var haste: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Haste)
	assert_eq(haste.size(), 0, "Haste must not be applied while Sequence Lock is active")

func test_apply_debuff_is_blocked_for_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Slow
	template.duration = 2

	resolver.GetStatusResolver().ApplyDebuff(3, template)

	var slow: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Slow)
	assert_eq(slow.size(), 0, "Slow must not be applied while Sequence Lock is active")

func test_apply_buff_still_lands_for_non_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Empower
	template.duration = 2

	resolver.GetStatusResolver().ApplyBuff(3, template)

	var empower: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Empower)
	assert_eq(empower.size(), 1, "Empower does not touch Speed and must still land")

func test_cast_debuff_is_blocked_for_speed_effect() -> void:
	var roster: Dictionary[int, Character] = _sequence_locked_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var skill: Skill = TestFactory.make_strike_skill()
	var debuff_effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	debuff_effect.target = Types.Skill_Target.Single_Enemy
	debuff_effect.debuff_type = Types.Debuff_Type.Slow
	debuff_effect.duration = 2
	skill.effects.append(debuff_effect)
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
	var skill: Skill = TestFactory.make_empty_skill()
	skill.target = Types.Skill_Target.Single_Ally
	var buff_effect: ApplyBuffEffect = ApplyBuffEffect.new()
	buff_effect.target = Types.Skill_Target.Single_Ally
	buff_effect.buff_type = Types.Buff_Type.Haste
	buff_effect.duration = 2
	skill.effects = [buff_effect]
	roster[3]._skills.append(skill)

	resolver.ResolveSkill(3, [3], 1)

	var haste: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Haste)
	assert_eq(haste.size(), 0, "Haste must not land through the skill-cast path while Sequence Lock is active")
