extends GutTest

## The Relics whose effect and drawback both act on the wearer alone: The Quiet Mass, The
## Planted Heel, The Answering Boss, Kiln Brand, Sunderplate Nail, and The Ossuary Ledger.
## Each Relic effect is exercised at two rarity steps, plus its drawback.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _skill_with_cooldown(p_cooldown: int) -> Skill:
	var skill: Skill = TestFactory.make_strike_skill()
	skill.cooldown = p_cooldown
	return skill

func _damaging_debuff_skill(p_cooldown: int = 0) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Rending Blow"
	skill.cooldown = p_cooldown
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	var debuff: ApplyDebuffEffect = ApplyDebuffEffect.new()
	debuff.debuff_type = Types.Debuff_Type.Enfeeble
	debuff.duration = 2
	skill.effects = [damage, debuff]
	return skill

# --- The Quiet Mass ---

func test_quiet_mass_grants_max_health_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.30], [Types.Rarity.Legendary, 0.50]]:
		var relic: TheQuietMassRelic = TheQuietMassRelic.new()
		relic.Init(rarity_and_expected[0])

		var delta: int = relic.GetAttributeDelta(Types.Attribute.Health, 100)

		assert_eq(delta, int(ceilf(100 * rarity_and_expected[1])),
			"Rarity %s should grant its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_quiet_mass_reduces_targeting_priority() -> void:
	var relic: TheQuietMassRelic = TheQuietMassRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_almost_eq(relic.GetTargetingPriorityMultiplier(), 0.25, 0.0001,
		"Legendary's targeting-weight drawback should multiply by 0.25")

# --- The Answering Boss ---

func test_answering_boss_grants_damage_bonus_while_holding_barrier() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.30], [Types.Rarity.Legendary, 0.60]]:
		var character: Character = TestFactory.make_character()
		character._current_health = character._attributes[Types.Attribute.Health]
		var relic: TheAnsweringBossRelic = TheAnsweringBossRelic.new()
		relic.Init(rarity_and_expected[0])
		character._trait = relic
		var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())
		var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
		barrier.type = Types.Buff_Type.Barrier
		barrier.duration = 2
		barrier.value = 50
		resolver.GetStatusResolver().ApplyBuff(0, barrier)

		var bonus: float = Skills.OutgoingDamageBonus(character, 0, 3, resolver)

		assert_almost_eq(bonus, rarity_and_expected[1], 0.0001,
			"Rarity %s should grant its own ladder step while holding a Barrier" % Types.RarityName(rarity_and_expected[0]))

func test_answering_boss_grants_no_bonus_without_a_barrier() -> void:
	var character: Character = TestFactory.make_character()
	var relic: TheAnsweringBossRelic = TheAnsweringBossRelic.new()
	relic.Init(Types.Rarity.Legendary)
	character._trait = relic
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())

	assert_eq(Skills.OutgoingDamageBonus(character, 0, 3, resolver), 0.0)

func test_answering_boss_reduces_max_health() -> void:
	var relic: TheAnsweringBossRelic = TheAnsweringBossRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAttributeDelta(Types.Attribute.Health, 100), -30,
		"The Health drawback is a flat 30%, not rarity-scaled")

# --- Kiln Brand ---

func test_kiln_brand_boosts_cooldown_skills_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.30], [Types.Rarity.Legendary, 0.65]]:
		var character: Character = TestFactory.make_character()
		character._current_health = character._attributes[Types.Attribute.Health]
		var relic: KilnBrandRelic = KilnBrandRelic.new()
		relic.Init(rarity_and_expected[0])
		character._trait = relic
		character._skills = [_skill_with_cooldown(3)]
		var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())

		var result: TraitSkillResult = Skills.DispatchSkillCast(
				character, 0, [3], character._skills[0].name, resolver.GetEffectiveAttributes(0), resolver)

		assert_almost_eq(result._damage_multiplier, 1.0 + rarity_and_expected[1], 0.0001,
			"Rarity %s should boost a cooldown skill by its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_kiln_brand_gives_no_bonus_to_a_basic_skill() -> void:
	var character: Character = TestFactory.make_character()
	var relic: KilnBrandRelic = KilnBrandRelic.new()
	relic.Init(Types.Rarity.Legendary)
	character._trait = relic
	character._skills = [_skill_with_cooldown(0)]
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())

	var result: TraitSkillResult = Skills.DispatchSkillCast(
			character, 0, [3], character._skills[0].name, resolver.GetEffectiveAttributes(0), resolver)

	assert_almost_eq(result._damage_multiplier, 1.0, 0.0001)

func test_kiln_brand_penalizes_a_damaging_debuff_skill() -> void:
	var character: Character = TestFactory.make_character()
	var relic: KilnBrandRelic = KilnBrandRelic.new()
	relic.Init(Types.Rarity.Legendary)
	character._trait = relic
	character._skills = [_damaging_debuff_skill(0)]
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())

	var result: TraitSkillResult = Skills.DispatchSkillCast(
			character, 0, [3], character._skills[0].name, resolver.GetEffectiveAttributes(0), resolver)

	assert_almost_eq(result._damage_multiplier, 0.60, 0.0001,
		"A damaging skill able to apply a debuff should deal 40% less, independent of cooldown")

func test_kiln_brand_bonus_and_penalty_both_apply_to_the_same_skill() -> void:
	var character: Character = TestFactory.make_character()
	var relic: KilnBrandRelic = KilnBrandRelic.new()
	relic.Init(Types.Rarity.Legendary)
	character._trait = relic
	character._skills = [_damaging_debuff_skill(3)]
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())

	var result: TraitSkillResult = Skills.DispatchSkillCast(
			character, 0, [3], character._skills[0].name, resolver.GetEffectiveAttributes(0), resolver)

	assert_almost_eq(result._damage_multiplier, 1.0 + 0.65 - 0.40, 0.0001,
		"A cooldown skill that can also apply a debuff gets both the bonus and the penalty")

# --- Sunderplate Nail ---

func test_sunderplate_nail_reduces_defence_ignore_factor_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.20], [Types.Rarity.Legendary, 0.32]]:
		var relic: SunderplateNailRelic = SunderplateNailRelic.new()
		relic.Init(rarity_and_expected[0])

		var factor: float = relic.GetOutgoingDefenceIgnoreFactor(0, 1, null)

		assert_almost_eq(factor, 1.0 - rarity_and_expected[1], 0.0001,
			"Rarity %s should scale the target's Defence down by its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_sunderplate_nail_costs_health_when_the_wearer_gains_a_buff() -> void:
	var character: Character = TestFactory.make_character()
	character._current_health = character._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var relic: SunderplateNailRelic = SunderplateNailRelic.new()
	relic.Init(Types.Rarity.Legendary)
	character._trait = relic
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())
	var max_health: int = resolver.GetMaxHealth(0)
	var health_before: int = character._current_health

	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	resolver.GetStatusResolver().ApplyBuff(0, fortify)

	assert_eq(character._current_health, health_before - roundi(max_health * 0.10),
		"Gaining a buff should cost 10% of the wearer's max Health")

# --- The Ossuary Ledger ---

func test_ossuary_ledger_grants_damage_after_an_ally_death_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.30], [Types.Rarity.Legendary, 0.60]]:
		var relic: TheOssuaryLedgerRelic = TheOssuaryLedgerRelic.new()
		relic.Init(rarity_and_expected[0])

		assert_eq(Skills.OutgoingDamageBonus(_character_with_trait(relic), 0, 1, null), 0.0,
			"No bonus before an ally has died")

		relic.OnAllyDeath(0, 1, null)

		assert_almost_eq(Skills.OutgoingDamageBonus(_character_with_trait(relic), 0, 1, null),
			rarity_and_expected[1], 0.0001,
			"Rarity %s should grant its own ladder step once an ally has died" % Types.RarityName(rarity_and_expected[0]))

func _character_with_trait(p_trait: CharacterTrait) -> Character:
	var character: Character = TestFactory.make_character()
	character._trait = p_trait
	return character

func test_ossuary_ledger_blocks_the_wearer_from_gaining_a_buff() -> void:
	var character: Character = TestFactory.make_character()
	character._current_health = character._attributes[Types.Attribute.Health]
	var relic: TheOssuaryLedgerRelic = TheOssuaryLedgerRelic.new()
	relic.Init(Types.Rarity.Legendary)
	character._trait = relic
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, TestFactory.make_full_sides())
	relic.StartOfBattle(0, resolver)

	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	resolver.GetStatusResolver().ApplyBuff(0, fortify)

	assert_true(character._active_buffs.is_empty(), "Severance should block every buff, permanently")

# --- The Planted Heel ---

func test_planted_heel_boosts_the_next_damaging_skill_after_a_big_hit_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.35], [Types.Rarity.Legendary, 0.65]]:
		var wearer: Character = TestFactory.make_character()
		wearer._current_health = wearer._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
		var relic: ThePlantedHeelRelic = ThePlantedHeelRelic.new()
		relic.Init(rarity_and_expected[0])
		wearer._trait = relic
		wearer._skills = [TestFactory.make_strike_skill()]
		var attacker: Character = TestFactory.make_character()
		attacker._current_health = attacker._attributes[Types.Attribute.Health]
		var resolver: BattleResolver = TestFactory.make_resolver(
				{0: wearer, 1: attacker}, CombatSides.new([0], [1]))
		relic.StartOfBattle(0, resolver)

		resolver.ResolveEffectDamage(1, 0, resolver.GetEffectiveAttributes(1),
				{Types.Attribute.Attack: 100.0}, 1.0, CombinedDamageModifier.new())
		var result: TraitSkillResult = Skills.DispatchSkillCast(
				wearer, 0, [1], wearer._skills[0].name, resolver.GetEffectiveAttributes(0), resolver)

		assert_almost_eq(result._damage_multiplier, 1.0 + rarity_and_expected[1], 0.0001,
			"Rarity %s should boost the next damaging skill after a big hit" % Types.RarityName(rarity_and_expected[0]))

func test_planted_heel_gives_no_bonus_without_a_big_hit() -> void:
	var wearer: Character = TestFactory.make_character()
	wearer._current_health = wearer._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var relic: ThePlantedHeelRelic = ThePlantedHeelRelic.new()
	relic.Init(Types.Rarity.Legendary)
	wearer._trait = relic
	wearer._skills = [TestFactory.make_strike_skill()]
	var resolver: BattleResolver = TestFactory.make_resolver({0: wearer}, TestFactory.make_full_sides())
	relic.StartOfBattle(0, resolver)

	var result: TraitSkillResult = Skills.DispatchSkillCast(
			wearer, 0, [3], wearer._skills[0].name, resolver.GetEffectiveAttributes(0), resolver)

	assert_almost_eq(result._damage_multiplier, 1.0, 0.0001)

func test_planted_heel_increases_targeting_priority() -> void:
	var relic: ThePlantedHeelRelic = ThePlantedHeelRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_almost_eq(relic.GetTargetingPriorityMultiplier(), 1.5, 0.0001)
