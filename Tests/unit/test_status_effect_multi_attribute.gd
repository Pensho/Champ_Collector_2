extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the multi-attribute StatusEffectData extension (batch 1 of
# Plan_Status_Effect_Implementation.md): Skills.ApplyAttributeModifiers must apply every
# attribute in attribute_modifiers with its own sign, and buffs/debuffs must resolve their
# instance value the same way (unifying the previous buff-only `value` convention).

func _buff(p_type: Types.Buff_Type) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.value = StatusEffectRegistry.BuffData(p_type).magnitude
	return buff

func _debuff(p_type: Types.Debuff_Type) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.value = StatusEffectRegistry.DebuffData(p_type).magnitude
	return debuff

func test_frenzy_target_snapshot_moves_all_four_attributes() -> void:
	var character: Character = TestFactory.make_character()
	character._active_buffs.append(_buff(Types.Buff_Type.Frenzy))
	var attrs: Dictionary[Types.Attribute, int] = {
		Types.Attribute.Attack: 100,
		Types.Attribute.Speed: 100,
		Types.Attribute.Defence: 100,
		Types.Attribute.Accuracy: 100,
	}
	Skills.TriggerTargetBuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Attack], 130, "Frenzy should raise Attack by 30%")
	assert_eq(attrs[Types.Attribute.Speed], 130, "Frenzy should raise Speed by 30%")
	assert_eq(attrs[Types.Attribute.Defence], 70, "Frenzy should lower Defence by 30%")
	assert_eq(attrs[Types.Attribute.Accuracy], 70, "Frenzy should lower Accuracy by 30%")

func test_suppress_reduces_target_snapshot_mysticism_using_debuff_value() -> void:
	var character: Character = TestFactory.make_character()
	character._active_debuffs.append(_debuff(Types.Debuff_Type.Suppress))
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	# Suppress applies at self-tick, not target-snapshot, so route it through the
	# same generic helper the self-tick sites use.
	Skills.ApplyAttributeModifiers(StatusEffectRegistry.DebuffData(Types.Debuff_Type.Suppress),
			character._active_debuffs[0].value, attrs)
	assert_eq(attrs[Types.Attribute.Mysticism], 70, "Suppress should lower Mysticism by 30%")

func test_unravel_reduces_target_snapshot_resistance() -> void:
	var character: Character = TestFactory.make_character()
	character._active_debuffs.append(_debuff(Types.Debuff_Type.Unravel))
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Resistance: 100}
	Skills.TriggerTargetDebuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Resistance], 70, "Unravel should lower Resistance by 30%")

func test_keen_edge_adds_flat_crit_chance_points_not_a_percent() -> void:
	var character: Character = TestFactory.make_character()
	character._active_buffs.append(_buff(Types.Buff_Type.Keen_Edge))
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.CritChance: 20}
	Skills.ApplyAttributeModifiers(StatusEffectRegistry.BuffData(Types.Buff_Type.Keen_Edge),
			character._active_buffs[0].value, attrs)
	assert_eq(attrs[Types.Attribute.CritChance], 35,
		"Keen Edge should add 15 flat crit-chance points, not 15% of the current value")

func test_lethal_precision_adds_flat_crit_damage_points() -> void:
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.CritDamage: 150}
	Skills.ApplyAttributeModifiers(StatusEffectRegistry.BuffData(Types.Buff_Type.Lethal_Precision), 50.0, attrs)
	assert_eq(attrs[Types.Attribute.CritDamage], 200)

# --- Debuff instance value unification (ApplyDebuff / _CastDebuff) ---

func test_apply_debuff_resolves_registry_default_when_template_leaves_value_unset() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Suppress
	template.duration = 2

	resolver.ApplyDebuff(0, template)

	assert_almost_eq(roster[0]._active_debuffs[0].value,
		StatusEffectRegistry.DebuffData(Types.Debuff_Type.Suppress).magnitude, 0.0001,
		"ApplyDebuff must default the instance value to the registry magnitude, mirroring ApplyBuff")

func test_cast_debuff_sets_instance_value_from_registry() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var skill: Skill = TestFactory.make_strike_skill()
	skill.damage_scaling = {}
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: Types.Debuff_Type.Blind}
	roster[0]._skills.append(skill)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	roster[3]._attributes[Types.Attribute.Resistance] = 0

	resolver.ResolveSkill(0, [3], 0)

	var blind: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Blind)
	assert_eq(blind.size(), 1, "Blind should have landed")
	assert_almost_eq(blind[0].value, StatusEffectRegistry.DebuffData(Types.Debuff_Type.Blind).magnitude, 0.0001)
