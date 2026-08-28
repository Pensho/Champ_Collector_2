extends GutTest

## The Relics built on ally-event and sustain plumbing: Ceded Ground, Mercy Stitch,
## Understudy's Coat, and Laden Coffer. Each Relic effect is exercised at two rarity
## steps, plus its drawback.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _wearer_and_ally() -> Dictionary:
	var wearer: Character = TestFactory.make_character()
	wearer._current_health = wearer._attributes[Types.Attribute.Health]
	var ally: Character = TestFactory.make_character()
	ally._current_health = ally._attributes[Types.Attribute.Health]
	var resolver: BattleResolver = TestFactory.make_resolver(
			{0: wearer, 1: ally}, TestFactory.make_full_sides())
	return {"wearer": wearer, "ally": ally, "resolver": resolver}

# --- Ceded Ground ---

func test_ceded_ground_heals_an_ally_holding_the_wearers_buff_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.08], [Types.Rarity.Legendary, 0.17]]:
		var setup: Dictionary = _wearer_and_ally()
		setup.wearer._attributes[Types.Attribute.Health] = 10000
		setup.wearer._current_health = 10000
		setup.ally._attributes[Types.Attribute.Health] = 10000
		setup.ally._current_health = 1000
		var relic: CededGroundRelic = CededGroundRelic.new()
		relic.Init(rarity_and_expected[0])
		var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
		fortify.type = Types.Buff_Type.Fortify
		fortify.duration = 3
		fortify.source_ID = 0
		setup.ally._active_buffs.append(fortify)
		var wearer_health_before: int = setup.wearer._current_health
		var ally_health_before: int = setup.ally._current_health

		relic.OnAllyCriticalHit(0, 1, 3, 1000, setup.resolver)

		var expected_heal: int = int(floor(1000 * rarity_and_expected[1]))
		assert_eq(setup.ally._current_health, ally_health_before + expected_heal,
			"Rarity %s should heal the ally its own ladder step of the damage dealt" % Types.RarityName(rarity_and_expected[0]))
		assert_eq(setup.wearer._current_health, wearer_health_before - expected_heal,
			"The healing should be paid out of the wearer's own Health")

func test_ceded_ground_does_nothing_without_the_wearers_buff() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: CededGroundRelic = CededGroundRelic.new()
	relic.Init(Types.Rarity.Legendary)
	var wearer_health_before: int = setup.wearer._current_health
	var ally_health_before: int = setup.ally._current_health

	relic.OnAllyCriticalHit(0, 1, 3, 1000, setup.resolver)

	assert_eq(setup.ally._current_health, ally_health_before)
	assert_eq(setup.wearer._current_health, wearer_health_before)

func test_ceded_ground_charges_the_wearer_nothing_when_the_ally_is_already_at_full_health() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: CededGroundRelic = CededGroundRelic.new()
	relic.Init(Types.Rarity.Legendary)
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	fortify.source_ID = 0
	setup.ally._active_buffs.append(fortify)
	setup.ally._current_health = setup.resolver.GetMaxHealth(1)
	var wearer_health_before: int = setup.wearer._current_health

	relic.OnAllyCriticalHit(0, 1, 3, 1000, setup.resolver)

	assert_eq(setup.wearer._current_health, wearer_health_before,
		"The wearer should not pay when the ally is already at full Health and gains nothing")

func test_ceded_ground_reduces_mysticism() -> void:
	var relic: CededGroundRelic = CededGroundRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAttributeDelta(Types.Attribute.Mysticism, 100), -50,
		"The Mysticism drawback is a flat 50%, not rarity-scaled")

func test_ceded_ground_fires_through_a_real_critical_hit() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: CededGroundRelic = CededGroundRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.duration = 3
	fortify.source_ID = 0
	setup.ally._active_buffs.append(fortify)
	var enemy: Character = TestFactory.make_character()
	enemy._current_health = 4000
	enemy._attributes[Types.Attribute.Health] = 1000
	setup.wearer._attributes[Types.Attribute.Health] = 10000
	setup.wearer._current_health = 10000
	var characters: Dictionary[int, Character] = {0: setup.wearer, 1: setup.ally, 2: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], [2]))
	var wearer_health_before: int = setup.wearer._current_health
	var attack_attributes: Dictionary[Types.Attribute, int] = resolver.GetEffectiveAttributes(1)
	attack_attributes[Types.Attribute.CritChance] = 100
	attack_attributes[Types.Attribute.CritDamage] = 200

	resolver.ResolveEffectDamage(1, 2, attack_attributes, {Types.Attribute.Attack: 1.0}, 1.0, CombinedDamageModifier.new())

	assert_lt(setup.wearer._current_health, wearer_health_before,
		"A real critical hit from the buffed ally should pay the wearer's Health through the real dispatch path")

# --- Mercy Stitch ---

func test_mercy_stitch_saves_the_wearer_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.20], [Types.Rarity.Legendary, 0.45]]:
		var relic: MercyStitchRelic = MercyStitchRelic.new()
		relic.Init(rarity_and_expected[0])

		var floor_health: int = relic.GetDamageTakenHealthFloor(0, -500, 1000)

		var expected: int = int(round(1000 * 0.25)) + int(round(1000 * rarity_and_expected[1]))
		assert_eq(floor_health, mini(expected, 1000),
			"Rarity %s should leave the wearer at 25%% plus its own ladder-step heal" % Types.RarityName(rarity_and_expected[0]))

func test_mercy_stitch_only_triggers_once_per_battle() -> void:
	var relic: MercyStitchRelic = MercyStitchRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_true(relic.GetDamageTakenHealthFloor(0, -500, 1000) >= 0, "First trigger should fire")
	assert_eq(relic.GetDamageTakenHealthFloor(0, -500, 1000), -1, "A second trigger in the same battle should not fire")

	relic.StartOfBattle(0, null)
	assert_true(relic.GetDamageTakenHealthFloor(0, -500, 1000) >= 0, "A new battle should reset the trigger")

func test_mercy_stitch_gives_no_opinion_above_the_floor() -> void:
	var relic: MercyStitchRelic = MercyStitchRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetDamageTakenHealthFloor(0, 500, 1000), -1,
		"Damage that stays above 25% Health should not trigger the save")

func test_mercy_stitch_reduces_damage_at_or_below_forty_percent_health() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: MercyStitchRelic = MercyStitchRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var max_health: int = setup.resolver.GetMaxHealth(0)
	setup.wearer._current_health = int(max_health * 0.40)

	assert_almost_eq(relic.GetOutgoingDamageBonus(0, 1, setup.resolver), -0.40, 0.0001)

func test_mercy_stitch_gives_no_damage_penalty_above_the_threshold() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: MercyStitchRelic = MercyStitchRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	setup.wearer._current_health = setup.resolver.GetMaxHealth(0)

	assert_eq(relic.GetOutgoingDamageBonus(0, 1, setup.resolver), 0.0)

func test_mercy_stitch_fires_through_a_real_lethal_range_hit() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: MercyStitchRelic = MercyStitchRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	setup.wearer._attributes[Types.Attribute.Health] = 1000
	setup.wearer._current_health = 4000  # Health(1000) x ATTRIBUTE_HEALTH_MULTIPLIER(4)
	setup.wearer._attributes[Types.Attribute.Defence] = 0
	relic.StartOfBattle(0, setup.resolver)
	var attack_attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Attack: 100000}
	var damage_scaling: Dictionary[Types.Attribute, float] = {Types.Attribute.Attack: 1.0}
	var received: Array[CombatResult] = []
	setup.resolver.result_produced.connect(func(r: CombatResult) -> void: received.append(r))

	setup.resolver.ResolveEffectDamage(1, 0, attack_attributes,
			damage_scaling, 1.0, CombinedDamageModifier.new(), false)

	var heal_results: Array[CombatResult] = received.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Heal == r.kind and 0 == r.target_ID)
	assert_eq(heal_results.size(), 1, "The save should surface as a Heal result, not a silent clamp")
	if(not heal_results.is_empty()):
		assert_gt(heal_results[0].amount, 0, "The Heal result should carry the restored amount")

	assert_gt(setup.wearer._current_health, 0, "The wearer must survive a real lethal-range hit")
	var health_fraction: float = float(setup.wearer._current_health) / float(setup.resolver.GetMaxHealth(0))
	assert_almost_eq(health_fraction, 0.25 + 0.45, 0.01,
		"The wearer should land at 25% plus the Legendary heal")

# --- Understudy's Coat ---

func test_understudys_coat_redirects_a_hit_on_the_lowest_health_ally_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.85], [Types.Rarity.Legendary, 0.60]]:
		var setup: Dictionary = _wearer_and_ally()
		var relic: UnderstudysCoatRelic = UnderstudysCoatRelic.new()
		relic.Init(rarity_and_expected[0])
		setup.wearer._trait = relic
		var other_ally: Character = TestFactory.make_character()
		other_ally._current_health = other_ally._attributes[Types.Attribute.Health]
		setup.resolver.GetCharacters()[2] = other_ally
		setup.ally._current_health = 1  # the lowest-Health ally

		var fraction: float = relic.OnAllyDamageTaken(0, 1, setup.resolver)

		assert_almost_eq(fraction, rarity_and_expected[1], 0.0001,
			"Rarity %s should redirect its own ladder step for the lowest-Health ally" % Types.RarityName(rarity_and_expected[0]))

func test_understudys_coat_does_not_redirect_a_higher_health_ally() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: UnderstudysCoatRelic = UnderstudysCoatRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic
	var other_ally: Character = TestFactory.make_character()
	other_ally._current_health = 1  # the lowest-Health ally, not setup.ally
	setup.resolver.GetCharacters()[2] = other_ally

	assert_eq(relic.OnAllyDamageTaken(0, 1, setup.resolver), 0.0,
		"An ally who isn't the lowest-Health one should not be redirected")

func test_understudys_coat_does_not_redirect_a_hit_on_the_wearer() -> void:
	var setup: Dictionary = _wearer_and_ally()
	var relic: UnderstudysCoatRelic = UnderstudysCoatRelic.new()
	relic.Init(Types.Rarity.Legendary)
	setup.wearer._trait = relic

	assert_eq(relic.OnAllyDamageTaken(0, 0, setup.resolver), 0.0,
		"The wearer can't redirect a hit on themself")

func test_understudys_coat_reduces_damage() -> void:
	var relic: UnderstudysCoatRelic = UnderstudysCoatRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_almost_eq(relic.GetOutgoingDamageBonus(0, 1, null), -0.35, 0.0001,
		"The damage drawback is a flat 35%, not rarity-scaled")

# --- Laden Coffer ---

func test_laden_coffer_grants_reward_multiplier_at_two_rarities() -> void:
	for rarity_and_expected in [[Types.Rarity.Common, 0.10], [Types.Rarity.Legendary, 0.35]]:
		var relic: LadenCofferRelic = LadenCofferRelic.new()
		relic.Init(rarity_and_expected[0])

		assert_almost_eq(relic.GetRewardMultiplier(), 1.0 + rarity_and_expected[1], 0.0001,
			"Rarity %s should grant its own ladder step" % Types.RarityName(rarity_and_expected[0]))

func test_laden_coffer_reduces_speed() -> void:
	var relic: LadenCofferRelic = LadenCofferRelic.new()
	relic.Init(Types.Rarity.Legendary)

	assert_eq(relic.GetAttributeDelta(Types.Attribute.Speed, 100), -30,
		"The Speed drawback is a flat 30%, not rarity-scaled")
