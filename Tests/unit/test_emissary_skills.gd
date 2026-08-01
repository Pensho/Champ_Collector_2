extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Emissary's Iron Ledger kit: Citation (damage bonus from the target's
# Standing Record tally via GetOutgoingDamageBonus), Signed Writ (buff-duration shear +
# its own debuff, escalating past 6 Infractions), and Levied Sanction (Sanction's
# magnitude set from the tally at the moment of application).

func _make_setup() -> Dictionary:
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var record_trait: StandingRecordTrait = StandingRecordTrait.new()
	record_trait.Init(Types.Rarity.Uncommon)
	roster[0]._trait = record_trait
	record_trait.StartOfBattle(0, resolver)
	return {"roster": roster, "resolver": resolver, "trait": record_trait}

func _citation_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Citation"
	skill.damage_scaling = {Types.Attribute.Knowledge: 0.7}
	return skill

func _signed_writ_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Signed Writ"
	skill.cooldown = 3
	skill.duration = 1
	skill.debuffs = {Types.Skill_Target.Single_Enemy: [Types.Debuff_Type.Signed_Writ]}
	skill.buff_duration_reduction = {Types.Skill_Target.Single_Enemy: 1}
	skill.escalated_at_infractions = 6
	return skill

func _levied_sanction_skill() -> Skill:
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Levied Sanction"
	skill.cooldown = 4
	skill.duration = 2
	skill.debuffs = {Types.Skill_Target.Single_Enemy: [Types.Debuff_Type.Sanction]}
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

func test_get_outgoing_damage_bonus_scales_with_infractions_and_rate() -> void:
	var setup: Dictionary = _make_setup()
	var record_trait: StandingRecordTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	for i in 4:
		record_trait._AddInfraction(3)

	var bonus: float = record_trait.GetOutgoingDamageBonus(0, 3, resolver)

	assert_eq(bonus, 4.0 * StandingRecordTrait.GetRatePerInfraction(Types.Rarity.Uncommon))

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
