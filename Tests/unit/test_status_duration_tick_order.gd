extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Status durations count down as the last step of the holder's turn, after the skill,
# cooldowns, zones and the end-of-turn trait hook. A status with one turn left is therefore
# still in force for every check made during that turn, and a status placed during a turn
# does not lose a count to that same turn's tick. Per-turn damage and healing (Burning,
# Regeneration) still resolve before the skill.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())

func _buff(p_type: Types.Buff_Type, p_duration: int) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _debuff(p_type: Types.Debuff_Type, p_duration: int) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

func _self_buff_skill(p_duration: int = 2) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Self Buff"
	skill.target = Types.Skill_Target.Self
	var effect: ApplyBuffEffect = ApplyBuffEffect.new()
	effect.target = Types.Skill_Target.Self
	effect.buff_type = Types.Buff_Type.Empower
	effect.duration = p_duration
	skill.effects = [effect]
	return skill

func _ally_buff_skill(p_duration: int = 2) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Ally Buff"
	skill.target = Types.Skill_Target.Single_Ally
	var effect: ApplyBuffEffect = ApplyBuffEffect.new()
	effect.target = Types.Skill_Target.Single_Ally
	effect.buff_type = Types.Buff_Type.Empower
	effect.duration = p_duration
	skill.effects = [effect]
	return skill

func _first_buff_of(p_character_ID: int, p_type: Types.Buff_Type) -> StatusEffects.Buff:
	for buff in _roster[p_character_ID]._active_buffs:
		if(p_type == buff.type):
			return buff
	return null

func test_severance_on_its_last_turn_still_blocks_the_holders_own_cast() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Severance, 1))
	_roster[0]._skills.append(_self_buff_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(0, [0], 0)

	assert_null(_first_buff_of(0, Types.Buff_Type.Empower),
		"Severance with one turn left should still block the buff cast on that turn")
	assert_eq(_roster[0]._active_debuffs.filter(
			func(d): return Types.Debuff_Type.Severance == d.type).size(), 0,
		"Severance should expire at the end of that same turn")

func test_a_debuff_from_another_character_ticks_at_the_end_of_the_holders_turn() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Enfeeble, 2))
	_roster[0]._skills.append(_self_buff_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(0, [0], 0)

	assert_eq(_roster[0]._active_debuffs[0].duration, 1,
		"A debuff the holder did not gain this turn should count down once")

func test_a_self_applied_buff_keeps_its_full_duration_through_the_turn_it_lands() -> void:
	_roster[0]._skills.append(_self_buff_skill(2))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(0, [0], 0)

	var empower: StatusEffects.Buff = _first_buff_of(0, Types.Buff_Type.Empower)
	assert_not_null(empower, "The self-buff should land")
	assert_eq(empower.duration, 2,
		"A buff placed this turn should not be counted down by this turn's own tick")

func test_a_buff_from_an_ally_ticks_on_the_holders_next_turn() -> void:
	_roster[1]._skills.append(_ally_buff_skill(2))
	_roster[0]._skills.append(_self_buff_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(1, [0], 0)
	var empower: StatusEffects.Buff = _first_buff_of(0, Types.Buff_Type.Empower)
	assert_not_null(empower, "The ally's buff should land")
	assert_eq(empower.duration, 2, "The ally's turn should not count down a buff it just placed")

	_resolver.ResolveSkill(0, [0], 0)
	assert_eq(empower.duration, 1, "The holder's own next turn should count it down")

func test_a_stun_turn_still_counts_statuses_down() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Enfeeble, 2))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 2))
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveStunTurn(0)

	assert_eq(_roster[0]._active_debuffs[0].duration, 1, "A skipped turn should still tick debuffs")
	assert_eq(_roster[0]._active_buffs[0].duration, 1, "A skipped turn should still tick buffs")

func test_a_debuff_on_its_last_turn_still_deals_its_tick_damage() -> void:
	_roster[0]._active_debuffs.append(_debuff(Types.Debuff_Type.Burning, 1))
	_roster[0]._skills.append(_self_buff_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [0], 0)

	assert_gt(results.filter(func(r): return CombatResult.Kind.Debuff_Tick == r.kind).size(), 0,
		"Burning should still tick on the turn it expires")
	assert_eq(_roster[0]._active_debuffs.size(), 0, "Burning should then expire")
