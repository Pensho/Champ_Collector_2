extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Opportunist: +10% damage per debuff currently on the target, read from the caster's
# own active buffs in BattleResolver._ResolveDamage.

func _resolver_with_caster_buff(p_buff_type: Types.Buff_Type) -> Dictionary:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	if(Types.Buff_Type.Invalid != p_buff_type):
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = p_buff_type
		buff.value = StatusEffectRegistry.BuffData(p_buff_type).magnitude
		buff.duration = 5
		roster[0]._active_buffs.append(buff)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	resolver.GetCharacters()[0]._attributes[Types.Attribute.CritChance] = 0
	# Large enough that the ceil() rounding on the final damage roll can't mask the
	# 20%-ish Opportunist swing (small numbers can round the same either way).
	resolver.GetCharacters()[0]._attributes[Types.Attribute.Attack] = 1000
	return {"roster": roster, "resolver": resolver}

func _first_damage(p_results: Array[CombatResult]) -> int:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	return damage[0].amount if not damage.is_empty() else -1

func test_opportunist_increases_damage_per_target_debuff() -> void:
	var baseline: Dictionary = _resolver_with_caster_buff(Types.Buff_Type.Invalid)
	var buffed: Dictionary = _resolver_with_caster_buff(Types.Buff_Type.Opportunist)
	for setup in [baseline, buffed]:
		var target: Character = setup["roster"][3]
		for i in 2:
			var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			debuff.type = Types.Debuff_Type.Enfeeble if i == 0 else Types.Debuff_Type.Blind
			debuff.duration = 5
			target._active_debuffs.append(debuff)

	var baseline_resolver: BattleResolver = baseline["resolver"]
	var buffed_resolver: BattleResolver = buffed["resolver"]
	var baseline_damage: int = _first_damage(baseline_resolver.ResolveSkill(0, [3], 0))
	var buffed_damage: int = _first_damage(buffed_resolver.ResolveSkill(0, [3], 0))

	# +10% per debuff, 2 debuffs on the target -> roughly +20% damage (each side rounds
	# independently via ceil, so assert the direction and rough magnitude, not an exact value).
	assert_gt(buffed_damage, baseline_damage, "Opportunist should add damage per debuff on the target")
	assert_almost_eq(float(buffed_damage) / float(baseline_damage), 1.2, 0.05)

func test_opportunist_has_no_effect_with_no_target_debuffs() -> void:
	var baseline: Dictionary = _resolver_with_caster_buff(Types.Buff_Type.Invalid)
	var buffed: Dictionary = _resolver_with_caster_buff(Types.Buff_Type.Opportunist)

	var baseline_resolver: BattleResolver = baseline["resolver"]
	var buffed_resolver: BattleResolver = buffed["resolver"]
	var baseline_damage: int = _first_damage(baseline_resolver.ResolveSkill(0, [3], 0))
	var buffed_damage: int = _first_damage(buffed_resolver.ResolveSkill(0, [3], 0))

	assert_eq(buffed_damage, baseline_damage, "No target debuffs means no Opportunist bonus")
