extends GutTest

## The Relics whose upside strengthens a status the wearer applies: The Even Tread, The
## Frayed Hour, The Solvent Mark, Signatory's Seal, Quorum Bell, and Prism of Small
## Favors. Each Relic effect is exercised at two rarity steps, plus its drawback.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _wearer_and_resolver() -> Dictionary:
	var wearer: Character = TestFactory.make_character()
	wearer._current_health = wearer._attributes[Types.Attribute.Health]
	var ally: Character = TestFactory.make_character()
	ally._current_health = ally._attributes[Types.Attribute.Health]
	var resolver: BattleResolver = TestFactory.make_resolver(
			{0: wearer, 1: ally}, TestFactory.make_full_sides())
	return {"wearer": wearer, "ally": ally, "resolver": resolver}

# --- The Even Tread ---

func test_even_tread_strengthens_a_buff_the_wearer_applies_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.55], [Types.Rarity.Legendary, 0.85]]:
		var setup: Dictionary = _wearer_and_resolver()
		var relic: TheEvenTreadRelic = TheEvenTreadRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic
		var data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify)
		var base_value: float = setup.resolver.GetStatusResolver().SnapshotStatusValue(data, 0, 0)

		var value: float = relic.GetAppliedBuffValue(0, 0, Types.Buff_Type.Fortify, setup.resolver)

		assert_almost_eq(value, base_value * (1.0 + rarity_and_expected[1]), 0.01,
			"Rarity %s should grant its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_even_tread_denies_allies_critical_hits() -> void:
	var relic: TheEvenTreadRelic = TheEvenTreadRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_true(relic.DeniesAlliesCriticalHits())

func test_even_tread_drawback_reaches_the_wearers_ally_through_the_team() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: TheEvenTreadRelic = TheEvenTreadRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic

	assert_true(Skills.AllyDeniesCriticalHits(setup.resolver.GetSides(), setup.resolver.GetCharacters(), 1),
		"The ally should be denied critical hits by the wearer's Relic")
	assert_false(Skills.AllyDeniesCriticalHits(setup.resolver.GetSides(), setup.resolver.GetCharacters(), 0),
		"The wearer's own denial should not apply to themself")

# --- The Frayed Hour ---

func test_frayed_hour_strengthens_temporal_leak_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 2.50], [Types.Rarity.Legendary, 3.50]]:
		var setup: Dictionary = _wearer_and_resolver()
		var relic: TheFrayedHourRelic = TheFrayedHourRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Temporal_Leak)
		var base_value: float = setup.resolver.GetStatusResolver().SnapshotStatusValue(data, 0, 1)

		var value: float = relic.GetAppliedStatusValue(0, 1, Types.Debuff_Type.Temporal_Leak, setup.resolver)

		assert_almost_eq(value, base_value * (1.0 + rarity_and_expected[1]), 0.01,
			"Rarity %s should grant its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_frayed_hour_gives_no_opinion_on_a_different_debuff_type() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: TheFrayedHourRelic = TheFrayedHourRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAppliedStatusValue(0, 1, Types.Debuff_Type.Burning, setup.resolver), -1.0)

func test_frayed_hour_reduces_a_teammates_barrier_to_a_quarter() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: TheFrayedHourRelic = TheFrayedHourRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic

	var multiplier: float = Skills.TeamBarrierMultiplier(
			setup.resolver.GetSides(), setup.resolver.GetCharacters(), 1)

	assert_almost_eq(multiplier, 0.25, 0.0001,
		"A Barrier landing on the wearer's teammate should be cut to a quarter")

# --- The Solvent Mark ---

func test_solvent_mark_strengthens_its_four_debuffs_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.50], [Types.Rarity.Legendary, 0.70]]:
		var setup: Dictionary = _wearer_and_resolver()
		var relic: TheSolventMarkRelic = TheSolventMarkRelic.new()
		relic.Init(rarity_and_expected[0])
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Unravel)
		var base_value: float = setup.resolver.GetStatusResolver().SnapshotStatusValue(data, 0, 1)

		var value: float = relic.GetAppliedStatusValue(0, 1, Types.Debuff_Type.Unravel, setup.resolver)

		assert_almost_eq(value, base_value * (1.0 + rarity_and_expected[1]), 0.01,
			"Rarity %s should grant its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_solvent_mark_gives_no_opinion_on_an_unrelated_debuff() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: TheSolventMarkRelic = TheSolventMarkRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAppliedStatusValue(0, 1, Types.Debuff_Type.Burning, setup.resolver), -1.0)

func test_solvent_mark_blocks_its_four_debuffs_from_landing_on_the_wearer() -> void:
	var relic: TheSolventMarkRelic = TheSolventMarkRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_true(relic.BlocksIncomingDebuffType(Types.Debuff_Type.Blind))
	assert_false(relic.BlocksIncomingDebuffType(Types.Debuff_Type.Burning))

func test_solvent_mark_doubles_a_debuffs_value_when_the_wearer_receives_it() -> void:
	var relic: TheSolventMarkRelic = TheSolventMarkRelic.new()
	relic.Init(Types.Rarity.Legendary)
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.value = 10.0

	relic.OnDebuffReceived(0, debuff, null)

	assert_eq(debuff.value, 20.0)

# --- Signatory's Seal ---

func test_signatorys_seal_guarantees_its_first_debuffs_per_enemy_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 2], [Types.Rarity.Legendary, 4]]:
		var relic: SignatorysSealRelic = SignatorysSealRelic.new()
		relic.Init(rarity_and_expected[0])
		for i in rarity_and_expected[1]:
			assert_true(relic.DebuffsCannotBeResisted(0, 1),
				"Debuff #%d against this enemy should bypass the resist roll" % (i + 1))
			relic.OnDebuffApplied(0, 1, null, null)

		assert_false(relic.DebuffsCannotBeResisted(0, 1),
			"Rarity %s should stop guaranteeing after its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_signatorys_seal_counts_each_enemy_separately() -> void:
	var relic: SignatorysSealRelic = SignatorysSealRelic.new()
	relic.Init(Types.Rarity.Uncommon)
	relic.OnDebuffApplied(0, 1, null, null)
	relic.OnDebuffApplied(0, 1, null, null)

	assert_false(relic.DebuffsCannotBeResisted(0, 1), "Enemy 1 has already used up its guaranteed debuffs")
	assert_true(relic.DebuffsCannotBeResisted(0, 2), "Enemy 2 has not landed any debuffs yet")

func test_signatorys_seal_applies_signed_writ_to_the_wearer_at_battle_start() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: SignatorysSealRelic = SignatorysSealRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic

	relic.StartOfBattle(0, setup.resolver)

	assert_true(setup.wearer._active_debuffs.any(
			func(d: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Signed_Writ == d.type),
		"The wearer should carry Signed Writ from the start of battle")

# --- Quorum Bell ---

func test_quorum_bell_amplifies_attribute_statuses_while_a_zone_stands_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 0.13], [Types.Rarity.Legendary, 0.20]]:
		var setup: Dictionary = _wearer_and_resolver()
		var relic: QuorumBellRelic = QuorumBellRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic
		TestFactory.place_zone(setup.resolver, 0, 0, TestFactory.make_zone_effect(1), Types.Skill_Target.Single_Enemy)

		relic.StartOfTurn(0, setup.resolver)

		assert_almost_eq(relic.GetAppliedAttributeAmplification(), rarity_and_expected[1], 0.0001,
			"Rarity %s should grant its own ladder step while a zone stands" % Types.RarityName(rarity_and_expected[0]))

func test_quorum_bell_grants_no_amplification_without_a_standing_zone() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: QuorumBellRelic = QuorumBellRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic

	relic.StartOfTurn(0, setup.resolver)

	assert_eq(relic.GetAppliedAttributeAmplification(), 0.0)

func test_quorum_bell_taxes_a_teammates_cooldownless_damage() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var wearer: Character = setup.wearer
	var ally: Character = setup.ally
	var resolver: BattleResolver = setup.resolver
	var relic: QuorumBellRelic = QuorumBellRelic.new()
	relic.Init(Types.Rarity.Legendary)
	wearer._trait = relic
	ally._skills = [TestFactory.make_strike_skill()]

	var result: TraitSkillResult = Skills.DispatchSkillCast(
			ally, 1, [3], ally._skills[0].name, resolver.GetEffectiveAttributes(1), resolver)

	assert_almost_eq(result._damage_multiplier, 0.70, 0.0001,
		"A teammate's cooldown-0 skill should deal 30% less damage")

# --- Prism of Small Favors ---

func test_prism_of_small_favors_grants_crit_chance_per_held_buff_up_to_its_cap_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Uncommon, 2], [Types.Rarity.Legendary, 4]]:
		var setup: Dictionary = _wearer_and_resolver()
		var relic: PrismOfSmallFavorsRelic = PrismOfSmallFavorsRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic
		for i in rarity_and_expected[1] + 2:
			var buff: StatusEffects.Buff = StatusEffects.Buff.new()
			buff.type = Types.Buff_Type.Fortify
			buff.duration = 3
			buff.name = "Fortify_%d" % i
			setup.wearer._active_buffs.append(buff)
		relic.OnBuffGained(0, null, setup.resolver)

		var delta: int = relic.GetAttributeDelta(Types.Attribute.CritChance, 0)

		assert_eq(delta, rarity_and_expected[1] * PrismOfSmallFavorsRelic.CRIT_CHANCE_PER_BUFF,
			"Rarity %s should cap the counted buffs at its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_prism_of_small_favors_grants_no_crit_chance_before_a_buff_is_gained() -> void:
	var relic: PrismOfSmallFavorsRelic = PrismOfSmallFavorsRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAttributeDelta(Types.Attribute.CritChance, 0), 0)

func test_prism_of_small_favors_halves_a_buff_applied_to_the_wearer() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: PrismOfSmallFavorsRelic = PrismOfSmallFavorsRelic.new()
	relic.Init(Types.Rarity.Legendary)
	var data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify)
	var base_value: float = setup.resolver.GetStatusResolver().SnapshotStatusValue(data, 0, 0)

	var value: float = relic.GetAppliedBuffValue(0, 0, Types.Buff_Type.Fortify, setup.resolver)

	assert_almost_eq(value, base_value * 0.5, 0.01)

func test_prism_of_small_favors_gives_no_opinion_on_a_buff_applied_to_someone_else() -> void:
	var setup: Dictionary = _wearer_and_resolver()
	var relic: PrismOfSmallFavorsRelic = PrismOfSmallFavorsRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAppliedBuffValue(0, 1, Types.Buff_Type.Fortify, setup.resolver), -1.0)
