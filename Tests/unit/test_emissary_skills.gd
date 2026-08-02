extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Emissary's Iron Ledger kit: Citation (damage bonus from the target's
# Standing Record tally via a Trait_Counter_On_Target DamageEffect), Signed Writ
# (buff-duration shear + its own debuff, escalating past 6 Infractions), and Levied
# Sanction (Sanction's magnitude set from the tally at the moment of application).

func _make_setup(p_rarity: Types.Rarity = Types.Rarity.Uncommon) -> Dictionary:
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var record_trait: StandingRecordTrait = StandingRecordTrait.new()
	record_trait.Init(p_rarity)
	roster[0]._trait = record_trait
	record_trait.StartOfBattle(0, resolver)
	return {"roster": roster, "resolver": resolver, "trait": record_trait}

## Signed Writ's escalation threshold: a raw Infraction count, rarity-independent.
const SIGNED_WRIT_CONDITION_THRESHOLD: float = 6.0

func _citation_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Citation"
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Knowledge: 0.7}
	effect.bonus_per = {Types.Trait_Count_Source.Trait_Counter_On_Target: 1.0}
	skill.effects = [effect]
	return skill

func _signed_writ_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Signed Writ"
	skill.cooldown = 3
	var reduction: ReduceBuffDurationsEffect = ReduceBuffDurationsEffect.new()
	reduction.target = Types.Skill_Target.Single_Enemy
	reduction.amount = 1
	var escalated_reduction: ReduceBuffDurationsEffect = ReduceBuffDurationsEffect.new()
	escalated_reduction.target = Types.Skill_Target.Single_Enemy
	escalated_reduction.amount = 1
	escalated_reduction.condition = Types.Skill_Condition.Trait_Counter_Raw_On_Target
	escalated_reduction.condition_test = Types.Condition_Test.At_Least
	escalated_reduction.condition_threshold = SIGNED_WRIT_CONDITION_THRESHOLD
	var debuff: ApplyDebuffEffect = ApplyDebuffEffect.new()
	debuff.target = Types.Skill_Target.Single_Enemy
	debuff.debuff_type = Types.Debuff_Type.Signed_Writ
	debuff.duration = 1
	debuff.condition = Types.Skill_Condition.Trait_Counter_Raw_On_Target
	debuff.condition_test = Types.Condition_Test.Below
	debuff.condition_threshold = SIGNED_WRIT_CONDITION_THRESHOLD
	var escalated_debuff: ApplyDebuffEffect = ApplyDebuffEffect.new()
	escalated_debuff.target = Types.Skill_Target.Single_Enemy
	escalated_debuff.debuff_type = Types.Debuff_Type.Signed_Writ
	escalated_debuff.duration = 2
	escalated_debuff.condition = Types.Skill_Condition.Trait_Counter_Raw_On_Target
	escalated_debuff.condition_test = Types.Condition_Test.At_Least
	escalated_debuff.condition_threshold = SIGNED_WRIT_CONDITION_THRESHOLD
	skill.effects = [reduction, escalated_reduction, debuff, escalated_debuff]
	return skill

func _levied_sanction_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Levied Sanction"
	skill.cooldown = 4
	var effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	effect.target = Types.Skill_Target.Single_Enemy
	effect.debuff_type = Types.Debuff_Type.Sanction
	effect.duration = 2
	skill.effects = [effect]
	return skill

func _buff(p_type: Types.Buff_Type, p_duration: int) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

## Removes debuff-resist as a source of flakiness for the debuff-landing tests below.
func _guarantee_debuffs_land(p_roster: Dictionary[int, Character]) -> void:
	p_roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	p_roster[3]._attributes[Types.Attribute.Resistance] = 0

# --- Citation ---

func test_condition_count_scales_with_infractions_and_rate() -> void:
	var setup: Dictionary = _make_setup()
	var record_trait: StandingRecordTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	for i in 4:
		record_trait._AddInfraction(3)

	var bonus: float = record_trait.GetConditionCount(
			0, 3, Types.Trait_Count_Source.Trait_Counter_On_Target, resolver)

	assert_eq(bonus, 4.0 * StandingRecordTrait.GetRatePerInfraction(Types.Rarity.Uncommon))

func test_condition_count_raw_is_the_unmultiplied_infraction_tally() -> void:
	var setup: Dictionary = _make_setup()
	var record_trait: StandingRecordTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	for i in 4:
		record_trait._AddInfraction(3)

	var count: float = record_trait.GetConditionCount(
			0, 3, Types.Trait_Count_Source.Trait_Counter_Raw_On_Target, resolver)

	assert_eq(count, 4.0)

func test_citation_deals_no_infraction_bonus_without_bonus_per() -> void:
	# Regression test: Citation's Infraction scaling must come only from its own
	# DamageEffect.bonus_per, not from every damaging skill an Emissary casts. A plain
	# damage skill authoring no bonus_per must deal identical damage regardless of the
	# target's Infraction tally.
	var baseline: Dictionary = _make_setup()
	var baseline_roster: Dictionary[int, Character] = baseline["roster"]
	var baseline_resolver: BattleResolver = baseline["resolver"]
	var plain_skill: Skill = TestFactory.make_empty_skill()
	plain_skill.name = "Plain Strike"
	var plain_effect: DamageEffect = DamageEffect.new()
	plain_effect.damage_scaling = {Types.Attribute.Knowledge: 0.7}
	plain_skill.effects = [plain_effect]
	baseline_roster[0]._skills.append(plain_skill)
	var baseline_health_before: int = baseline_roster[3]._current_health
	baseline_resolver.ResolveSkill(0, [3], 0)
	var baseline_damage: int = baseline_health_before - baseline_roster[3]._current_health

	var scaled: Dictionary = _make_setup()
	var scaled_roster: Dictionary[int, Character] = scaled["roster"]
	var scaled_resolver: BattleResolver = scaled["resolver"]
	var scaled_trait: StandingRecordTrait = scaled["trait"]
	for i in 9:
		scaled_trait._AddInfraction(3)
	var scaled_plain_skill: Skill = TestFactory.make_empty_skill()
	scaled_plain_skill.name = "Plain Strike"
	var scaled_plain_effect: DamageEffect = DamageEffect.new()
	scaled_plain_effect.damage_scaling = {Types.Attribute.Knowledge: 0.7}
	scaled_plain_skill.effects = [scaled_plain_effect]
	scaled_roster[0]._skills.append(scaled_plain_skill)
	var scaled_health_before: int = scaled_roster[3]._current_health
	scaled_resolver.ResolveSkill(0, [3], 0)
	var scaled_damage: int = scaled_health_before - scaled_roster[3]._current_health

	assert_gt(baseline_damage, 0)
	assert_eq(scaled_damage, baseline_damage,
		"A skill with no bonus_per must not gain Standing Record's Infraction bonus")

func test_citation_deals_more_damage_when_the_target_has_infractions() -> void:
	var baseline: Dictionary = _make_setup()
	var baseline_roster: Dictionary[int, Character] = baseline["roster"]
	var baseline_resolver: BattleResolver = baseline["resolver"]
	baseline_roster[0]._skills.append(_citation_skill())
	var baseline_health_before: int = baseline_roster[3]._current_health
	baseline_resolver.ResolveSkill(0, [3], 0)
	var baseline_damage: int = baseline_health_before - baseline_roster[3]._current_health

	var scaled: Dictionary = _make_setup()
	var scaled_roster: Dictionary[int, Character] = scaled["roster"]
	var scaled_resolver: BattleResolver = scaled["resolver"]
	var scaled_trait: StandingRecordTrait = scaled["trait"]
	for i in 9:
		scaled_trait._AddInfraction(3)
	scaled_roster[0]._skills.append(_citation_skill())
	var scaled_health_before: int = scaled_roster[3]._current_health
	scaled_resolver.ResolveSkill(0, [3], 0)
	var scaled_damage: int = scaled_health_before - scaled_roster[3]._current_health

	assert_gt(scaled_damage, baseline_damage,
		"Citation should deal more damage to a target with a high Infraction tally")

# --- Signed Writ ---

func test_signed_writ_shears_target_buff_durations_by_one() -> void:
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	_guarantee_debuffs_land(roster)
	roster[3]._active_buffs.append(_buff(Types.Buff_Type.Empower, 3))
	roster[0]._skills.append(_signed_writ_skill())

	resolver.ResolveSkill(0, [3], 0)

	assert_eq(roster[3]._active_buffs[0].duration, 2)

func test_signed_writ_applies_its_own_debuff_for_one_turn() -> void:
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	_guarantee_debuffs_land(roster)
	roster[0]._skills.append(_signed_writ_skill())

	resolver.ResolveSkill(0, [3], 0)

	var applied: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Signed_Writ)
	assert_eq(applied.size(), 1)
	assert_eq(applied[0].duration, 1)

func test_signed_writ_escalates_at_six_or_more_infractions() -> void:
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var record_trait: StandingRecordTrait = setup["trait"]
	_guarantee_debuffs_land(roster)
	for i in 6:
		record_trait._AddInfraction(3)
	roster[3]._active_buffs.append(_buff(Types.Buff_Type.Empower, 5))
	roster[0]._skills.append(_signed_writ_skill())

	resolver.ResolveSkill(0, [3], 0)

	assert_eq(roster[3]._active_buffs[0].duration, 3, "Escalated shear should be 2 turns, not 1")
	var applied: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Signed_Writ)
	assert_eq(applied[0].duration, 2, "Escalated Signed Writ should last 2 turns")

func test_signed_writ_escalation_makes_only_one_debuff_attempt() -> void:
	# The base and escalated ApplyDebuffEffects must be mutually exclusive (Below vs.
	# At_Least on the same threshold), not two independent CastDebuff calls — otherwise an
	# Aegis on the target would be consumed by one attempt and leave the other free to land.
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var record_trait: StandingRecordTrait = setup["trait"]
	_guarantee_debuffs_land(roster)
	for i in 6:
		record_trait._AddInfraction(3)
	# A long duration so Signed Writ's own buff-duration-shear effects (which also reduce
	# Aegis, an ordinary buff, by up to 2) cannot expire it before the debuff effect runs —
	# this test isolates Aegis-vs-repeated-CastDebuff, not Aegis-vs-duration-decay.
	var aegis: StatusEffects.Buff = StatusEffects.Buff.new()
	aegis.type = Types.Buff_Type.Aegis
	aegis.duration = 10
	roster[3]._active_buffs.append(aegis)
	roster[0]._skills.append(_signed_writ_skill())

	resolver.ResolveSkill(0, [3], 0)

	var applied: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Signed_Writ)
	assert_eq(applied.size(), 0, "A single Aegis should block the escalated cast's one debuff attempt entirely")
	var aegis_remaining: Array = roster[3]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Aegis)
	assert_eq(aegis_remaining.size(), 0, "Aegis should be consumed by blocking the attempt")

func test_signed_writ_does_not_escalate_below_six_infractions() -> void:
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var record_trait: StandingRecordTrait = setup["trait"]
	_guarantee_debuffs_land(roster)
	for i in 5:
		record_trait._AddInfraction(3)
	roster[0]._skills.append(_signed_writ_skill())

	resolver.ResolveSkill(0, [3], 0)

	var applied: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Signed_Writ)
	assert_eq(applied[0].duration, 1)

func test_signed_writ_escalation_threshold_is_rarity_independent() -> void:
	# Before this phase, the escalation threshold was a rate-multiplied count baked into
	# the .tres (0.15 == 6 x the Uncommon rate). A Legendary Emissary (rate 0.04) would
	# have crossed that threshold at only 5 Infractions instead of 6.
	var setup: Dictionary = _make_setup(Types.Rarity.Legendary)
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var record_trait: StandingRecordTrait = setup["trait"]
	_guarantee_debuffs_land(roster)
	for i in 5:
		record_trait._AddInfraction(3)
	roster[0]._skills.append(_signed_writ_skill())

	resolver.ResolveSkill(0, [3], 0)

	var applied: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Signed_Writ)
	assert_eq(applied[0].duration, 1,
		"5 Infractions should not escalate Signed Writ at any rarity")

# --- Levied Sanction ---

func test_levied_sanction_value_is_set_from_the_targets_infraction_tally() -> void:
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var record_trait: StandingRecordTrait = setup["trait"]
	_guarantee_debuffs_land(roster)
	for i in 4:
		record_trait._AddInfraction(3)
	roster[0]._skills.append(_levied_sanction_skill())

	resolver.ResolveSkill(0, [3], 0)

	var sanction: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Sanction)
	assert_eq(sanction.size(), 1)
	assert_eq(sanction[0].value, 4.0 * StandingRecordTrait.GetRatePerInfraction(Types.Rarity.Uncommon))

func test_levied_sanction_lowers_the_targets_effective_attributes() -> void:
	var setup: Dictionary = _make_setup()
	var roster: Dictionary[int, Character] = setup["roster"]
	var resolver: BattleResolver = setup["resolver"]
	var record_trait: StandingRecordTrait = setup["trait"]
	_guarantee_debuffs_land(roster)
	for i in 4:
		record_trait._AddInfraction(3)
	roster[0]._skills.append(_levied_sanction_skill())
	var attack_before: int = resolver.GetEffectiveAttributes(3)[Types.Attribute.Attack]

	resolver.ResolveSkill(0, [3], 0)

	var attack_after: int = resolver.GetEffectiveAttributes(3)[Types.Attribute.Attack]
	assert_lt(attack_after, attack_before, "Sanction should lower the target's Attack")
