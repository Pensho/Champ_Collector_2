extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Skill.damage_bonus_per_buff: Devour Blessing (consumes the most-buffed
# ally's buffs and scales off the consumed count) and Foreclosure (scales off buffs the
# caster itself currently holds, without consuming them).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func _devour_blessing_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Devour Blessing"
	skill.cooldown = 3
	skill.damage_scaling = {Types.Attribute.Mysticism: 1.3}
	skill.consume_buffs = {Types.Skill_Target.Most_Buffed_Ally: -1}
	skill.damage_bonus_per_buff = 0.25
	return skill

func _foreclosure_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Foreclosure"
	skill.damage_scaling = {Types.Attribute.Attack: 0.9}
	skill.damage_bonus_per_buff = 0.2
	return skill

# --- Devour Blessing ---

func test_devour_blessing_consumes_the_most_buffed_allys_buffs() -> void:
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	_roster[2]._active_buffs.append(_buff(Types.Buff_Type.Haste))
	_roster[0]._skills.append(_devour_blessing_skill())

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[1]._active_buffs.size(), 0, "The most-buffed ally should be consumed")
	assert_eq(_roster[2]._active_buffs.size(), 1, "A less-buffed ally should be left alone")

func test_devour_blessing_scales_damage_with_buffs_consumed() -> void:
	_roster[0]._skills.append(_devour_blessing_skill())
	var health_before_no_buffs: int = _roster[3]._current_health
	_resolver.ResolveSkill(0, [3], 0)
	var damage_without_buffs: int = health_before_no_buffs - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[1]._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	_roster[0]._skills.append(_devour_blessing_skill())
	var health_before_with_buffs: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	var damage_with_buffs: int = health_before_with_buffs - _roster[3]._current_health
	assert_gt(damage_with_buffs, damage_without_buffs,
		"Consuming buffs should increase Devour Blessing's damage")

# --- Foreclosure ---

func test_foreclosure_scales_with_buffs_the_caster_holds() -> void:
	var baseline_roster: Dictionary[int, Character] = {}
	baseline_roster.assign(TestFactory.make_full_roster())
	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	baseline_roster[0]._skills.append(_foreclosure_skill())
	var baseline_health_before: int = baseline_roster[3]._current_health
	baseline_resolver.ResolveSkill(0, [3], 0)
	var baseline_damage: int = baseline_health_before - baseline_roster[3]._current_health

	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	_roster[0]._skills.append(_foreclosure_skill())
	var health_before: int = _roster[3]._current_health

	_resolver.ResolveSkill(0, [3], 0)

	var damage_with_buffs: int = health_before - _roster[3]._current_health
	assert_gt(damage_with_buffs, baseline_damage,
		"Foreclosure should deal more damage the more buffs its caster holds")

func test_foreclosure_does_not_consume_the_casters_buffs() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[0]._skills.append(_foreclosure_skill())

	_resolver.ResolveSkill(0, [3], 0)

	assert_eq(_roster[0]._active_buffs.size(), 1,
		"Foreclosure only reads the caster's buffs, it does not consume them")
