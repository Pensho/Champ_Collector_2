extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Skill.buffs/debuffs as Dictionary[Skill_Target, Array]: each key is a
# target group, and its array can hold more than one buff/debuff, so one cast can grant
# several statuses to the same group (Full Appraisal) or affect more than one group at
# once (Wind the Mainspring damages an enemy while buffing the caster).

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()
	_resolver = TestFactory.make_resolver(_roster, _sides)

func _has_buff(p_character: Character, p_type: Types.Buff_Type) -> bool:
	return not p_character._active_buffs.filter(func(b): return b.type == p_type).is_empty()

func _has_debuff(p_character: Character, p_type: Types.Debuff_Type) -> bool:
	return not p_character._active_debuffs.filter(func(d): return d.type == p_type).is_empty()


func test_multiple_buffs_land_on_the_same_target_group() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.target = Types.Skill_Target.Single_Ally
	skill.damage_scaling = {}
	skill.duration = 2
	skill.buffs = {Types.Skill_Target.Single_Ally: [Types.Buff_Type.Keen_Edge, Types.Buff_Type.Lethal_Precision]}
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [1], 0)

	assert_true(_has_buff(_roster[1], Types.Buff_Type.Keen_Edge), "First buff in the array should land")
	assert_true(_has_buff(_roster[1], Types.Buff_Type.Lethal_Precision), "Second buff in the array should land")


func test_a_second_target_group_key_buffs_the_caster_while_attacking_an_enemy() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.duration = 2
	skill.buffs = {Types.Skill_Target.Self: [Types.Buff_Type.Haste]}
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_has_buff(_roster[0], Types.Buff_Type.Haste),
		"The Self key should resolve to the caster and grant them the buff")
	assert_false(_has_buff(_roster[3], Types.Buff_Type.Haste),
		"The enemy target group (damage) should not receive the other group's buff")


func test_a_second_target_group_key_can_buff_all_allies_while_debuffing_an_enemy() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.damage_scaling = {}
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: [Types.Debuff_Type.Confound]}
	skill.buffs = {Types.Skill_Target.All_Allies: [Types.Buff_Type.Opportunist]}
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_has_debuff(_roster[3], Types.Debuff_Type.Confound), "Enemy should be debuffed")
	for ally_ID in [0, 1, 2]:
		assert_true(_has_buff(_roster[ally_ID], Types.Buff_Type.Opportunist),
			"Ally %d should gain the All_Allies group's buff" % ally_ID)
	assert_false(_has_buff(_roster[3], Types.Buff_Type.Opportunist), "The debuffed enemy should not gain the buff")


func test_a_second_target_group_key_can_debuff_all_enemies_while_buffing_the_caster() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.duration = 2
	skill.buffs = {Types.Skill_Target.Self: [Types.Buff_Type.Haste]}
	skill.debuffs = {Types.Skill_Target.All_Enemies: [Types.Debuff_Type.Confound]}
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_has_buff(_roster[0], Types.Buff_Type.Haste), "Caster should gain the self-buff")
	for enemy_ID in [3, 4, 5]:
		assert_true(_has_debuff(_roster[enemy_ID], Types.Debuff_Type.Confound),
			"Enemy %d should be debuffed via the independently-resolved All_Enemies group" % enemy_ID)


func test_multiple_debuffs_land_on_the_same_target_group() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.damage_scaling = {}
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: [Types.Debuff_Type.Confound, Types.Debuff_Type.Unravel]}
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [3], 0)

	assert_true(_has_debuff(_roster[3], Types.Debuff_Type.Confound), "First debuff in the array should land")
	assert_true(_has_debuff(_roster[3], Types.Debuff_Type.Unravel), "Second debuff in the array should land")


func test_self_buff_skill_grants_the_caster_a_buff_with_no_damage() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.target = Types.Skill_Target.Self
	skill.damage_scaling = {}
	skill.duration = 4
	skill.buffs = {Types.Skill_Target.Self: [Types.Buff_Type.Exhert]}
	_roster[0]._skills.append(skill)

	_resolver.ResolveSkill(0, [0], 0)

	assert_true(_has_buff(_roster[0], Types.Buff_Type.Exhert), "Self-cast skill should buff the caster")


func test_pure_debuff_skill_applies_no_damage() -> void:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.damage_scaling = {}
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: [Types.Debuff_Type.Unravel]}
	_roster[0]._skills.append(skill)
	var health_before: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[3]._current_health, health_before, "A pure-debuff skill should not deal damage")
	assert_true(_has_debuff(_roster[3], Types.Debuff_Type.Unravel), "Debuff should still land")
