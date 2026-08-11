extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Regression coverage for the Emissary's Iron Ledger kit. General Citation/Signed
# Writ/Levied Sanction content coverage lives in test_skill_content_sweep.gd; the
# condition-mutual-exclusion engine case lives in test_skill_effects.gd.

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

## Removes debuff-resist as a source of flakiness for the debuff-landing tests below.
func _guarantee_debuffs_land(p_roster: Dictionary[int, Character]) -> void:
	p_roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	p_roster[3]._attributes[Types.Attribute.Resistance] = 0

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
