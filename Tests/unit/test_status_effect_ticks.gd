extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the generic, registry-driven status-effect application that replaced
# the hardcoded match blocks in Skills.gd/battle_resolver.gd (Plan_Data_Driven_Status_Effects).
# Locks in the exact magnitudes the old match blocks used, split by application site:
# target-snapshot (Skills.TriggerTargetBuffs/Debuffs, unit-tested directly) and
# self-tick (BattleResolver.ResolveSkill, tested end-to-end since the tick methods
# are private).

# --- Target-snapshot site (Skills.TriggerTargetBuffs / TriggerTargetDebuffs) ---

func _buff(p_type: Types.Buff_Type) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.value = StatusEffectRegistry.BuffData(p_type).magnitude
	return buff

func test_empower_increases_target_snapshot_attack_by_30_percent() -> void:
	var character: Character = TestFactory.make_character()
	character._active_buffs.append(_buff(Types.Buff_Type.Empower))
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100}
	Skills.TriggerTargetBuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Attack], 130)

func test_fortify_increases_target_snapshot_defence_by_30_percent() -> void:
	var character: Character = TestFactory.make_character()
	character._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	Skills.TriggerTargetBuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Defence], 130)

func test_phalanx_guard_uses_its_own_instance_value_not_the_registry_default() -> void:
	var character: Character = TestFactory.make_character()
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Phalanx_Guard
	buff.value = 0.08  # rarity-scaled value set by LancerTrait, not a static default
	character._active_buffs.append(buff)
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	Skills.TriggerTargetBuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Defence], 108)

func test_daunting_strength_does_not_affect_target_snapshot_attributes() -> void:
	var character: Character = TestFactory.make_character()
	character._active_buffs.append(_buff(Types.Buff_Type.Daunting_Strength))
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100, Types.Attribute.Defence: 100}
	Skills.TriggerTargetBuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Attack], 100)
	assert_eq(attrs[Types.Attribute.Defence], 100)

func test_expose_weakness_reduces_target_snapshot_defence_by_30_percent() -> void:
	var character: Character = TestFactory.make_character()
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Expose_Weakness
	character._active_debuffs.append(debuff)
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Defence: 100}
	Skills.TriggerTargetDebuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Defence], 70)

func test_enfeeble_does_not_apply_at_the_target_snapshot_site() -> void:
	var character: Character = TestFactory.make_character()
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	character._active_debuffs.append(debuff)
	var attrs: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100}
	Skills.TriggerTargetDebuffs(character, attrs)
	assert_eq(attrs[Types.Attribute.Attack], 100,
		"Enfeeble only reduces Attack on the holder's own turn, not when they are targeted")

# --- Self-tick site (BattleResolver.ResolveSkill) ---

func _resolver_with_buff(p_buff_type: Types.Buff_Type) -> BattleResolver:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	if(Types.Buff_Type.Invalid != p_buff_type):
		roster[0]._active_buffs.append(_buff(p_buff_type))
	return TestFactory.make_resolver(roster, TestFactory.make_full_sides())

func _first_damage(p_results: Array[CombatResult]) -> int:
	var damage: Array = p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	return damage[0].amount if not damage.is_empty() else -1

func test_daunting_strength_doubles_the_next_damage_roll() -> void:
	var baseline: BattleResolver = _resolver_with_buff(Types.Buff_Type.Invalid)
	var buffed: BattleResolver = _resolver_with_buff(Types.Buff_Type.Daunting_Strength)
	for r in [baseline, buffed]:
		r.GetCharacters()[0]._attributes[Types.Attribute.CritChance] = 0

	var baseline_damage: int = _first_damage(baseline.ResolveSkill(0, [3], 0))
	var buffed_damage: int = _first_damage(buffed.ResolveSkill(0, [3], 0))

	assert_eq(buffed_damage, baseline_damage * 2,
		"Daunting Strength should exactly double the first attack's damage")

func test_empower_increases_the_casters_own_attack_on_self_tick() -> void:
	var baseline: BattleResolver = _resolver_with_buff(Types.Buff_Type.Invalid)
	var buffed: BattleResolver = _resolver_with_buff(Types.Buff_Type.Empower)
	for r in [baseline, buffed]:
		r.GetCharacters()[0]._attributes[Types.Attribute.CritChance] = 0

	var baseline_damage: int = _first_damage(baseline.ResolveSkill(0, [3], 0))
	var buffed_damage: int = _first_damage(buffed.ResolveSkill(0, [3], 0))

	assert_gt(buffed_damage, baseline_damage, "Empower should raise the caster's own damage output")

# --- ApplyBuff/ApplyDebuff default-magnitude resolution (adventure effects, traits, debug) ---

func test_apply_buff_resolves_registry_default_when_template_leaves_value_unset() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Empower
	template.duration = 2

	resolver.ApplyBuff(0, template)

	assert_almost_eq(roster[0]._active_buffs[0].value,
		StatusEffectRegistry.BuffData(Types.Buff_Type.Empower).magnitude, 0.0001,
		"ApplyBuff must default the instance value to the registry magnitude, as ApplyAdventureEffects relies on")

func test_apply_buff_keeps_an_explicit_template_value_like_phalanx_guard() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var template: StatusEffects.Buff = StatusEffects.Buff.new()
	template.type = Types.Buff_Type.Phalanx_Guard
	template.duration = 2
	template.value = 0.08

	resolver.ApplyBuff(0, template)

	assert_almost_eq(roster[0]._active_buffs[0].value, 0.08, 0.0001,
		"A caller-supplied value (rarity-scaled Phalanx Guard) must not be overridden by the registry default")
