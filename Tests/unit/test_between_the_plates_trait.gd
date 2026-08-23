extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Thief's Between the Plates passive (Role_Kit_Design.md section 9.12): a
# base-referenced Defence bypass, subtracted in points from a debuff-free reference Defence
# (base + equipment + trait deltas + battle-long bonuses + Defence buffs, excluding Defence
# debuffs) rather than a multiplicative ignore — the reference stays intact under a teammate's
# Defence shred (route G, the Architect's Expose Weakness), which is the whole point of the
# base-referenced shape over a plain ignore factor.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _fortify() -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Fortify
	buff.duration = 2
	return buff

func _expose_weakness(p_value: float) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Expose_Weakness
	debuff.value = p_value
	debuff.duration = 2
	return debuff

# --- Trait rarity ladder ---

func test_rarity_ladder_returns_expected_rates() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.10,
		Types.Rarity.Rare: 0.13,
		Types.Rarity.Epic: 0.16,
		Types.Rarity.Legendary: 0.20,
	}
	for rarity: Types.Rarity in expected:
		var trait_instance: BetweenThePlatesTrait = BetweenThePlatesTrait.new()
		trait_instance.Init(rarity)
		assert_almost_eq(trait_instance.GetBaseDefenceIgnoreRate(0), expected[rarity], 0.001,
			"Rarity %s should carry the documented ignore rate" % Types.RarityName(rarity))

func test_common_rarity_defaults_to_zero_rate() -> void:
	var trait_instance: BetweenThePlatesTrait = BetweenThePlatesTrait.new()
	trait_instance.Init(Types.Rarity.Common)
	assert_eq(trait_instance.GetBaseDefenceIgnoreRate(0), 0.0,
		"Common has no entry in the rarity ladder and must carry no ignore")

# --- Resolver-level base-referenced ignore ---

func test_ignore_subtracts_points_not_a_fraction() -> void:
	_roster[0]._trait = BetweenThePlatesTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Legendary)
	_roster[3]._attributes[Types.Attribute.Defence] = 120

	var effective: float = _resolver._EffectiveDefenceAfterIgnore(0, 3, 120.0, 1.0)

	assert_almost_eq(effective, 96.0, 0.01,
		"Legendary's 20% of a 120 reference should subtract 24 points, not scale the total")

func test_multiple_scales_the_ignore() -> void:
	_roster[0]._trait = BetweenThePlatesTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Legendary)
	_roster[3]._attributes[Types.Attribute.Defence] = 120

	var base_multiple: float = _resolver._EffectiveDefenceAfterIgnore(0, 3, 120.0, 1.0)
	var pierce_multiple: float = _resolver._EffectiveDefenceAfterIgnore(0, 3, 120.0, 2.5)

	assert_almost_eq(pierce_multiple, 60.0, 0.01, "2.5x the 20% rate should subtract 60 of 120")
	assert_lt(pierce_multiple, base_multiple, "A higher multiple must ignore more Defence")

func test_ignore_floors_at_zero() -> void:
	_roster[0]._trait = BetweenThePlatesTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Legendary)
	_roster[3]._attributes[Types.Attribute.Defence] = 50

	var effective: float = _resolver._EffectiveDefenceAfterIgnore(0, 3, 50.0, 10.0)

	assert_eq(effective, 0.0, "Defence must floor at zero, never go negative")

func test_non_thief_caster_carries_no_ignore() -> void:
	_roster[3]._attributes[Types.Attribute.Defence] = 120

	var effective: float = _resolver._EffectiveDefenceAfterIgnore(0, 3, 120.0, 1.0)

	assert_almost_eq(effective, 120.0, 0.01, "A caster with no declared rate must not move Defence")

func test_a_defence_debuff_on_the_target_does_not_shrink_the_ignores_own_points() -> void:
	# Route G: the Architect's Expose Weakness shreds the target's Defence, and the Thief's
	# ignore must read the UNSHREDDED reference so the two compound instead of one eating
	# the other's contribution.
	_roster[0]._trait = BetweenThePlatesTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Legendary)
	_roster[3]._attributes[Types.Attribute.Defence] = 120
	_resolver.GetStatusResolver().ApplyDebuff(3, _expose_weakness(0.44))

	var shredded_defence: float = float(_resolver.GetEffectiveAttributes(3)[Types.Attribute.Defence])
	var effective: float = _resolver._EffectiveDefenceAfterIgnore(0, 3, shredded_defence, 1.0)

	assert_almost_eq(shredded_defence, 67.0, 1.0, "Expose Weakness at -44% should shred 120 to ~67")
	# 20% of the UNSHREDDED 120 reference is 24 points, not 20% of the shredded 67 (13.4) —
	# the two effects compound rather than one eating the other's contribution.
	assert_almost_eq(effective, shredded_defence - 24.0, 1.0,
		"The ignore's own points must come off the debuff-free reference, not the shredded value")

func test_a_defence_buff_on_the_target_raises_the_ignores_reference() -> void:
	_roster[0]._trait = BetweenThePlatesTrait.new()
	_roster[0]._trait.Init(Types.Rarity.Legendary)
	_roster[3]._attributes[Types.Attribute.Defence] = 120
	_resolver.GetStatusResolver().ApplyBuff(3, _fortify())

	var debuff_free_defence: float = float(_resolver.GetEffectiveAttributes(3, false)[Types.Attribute.Defence])

	assert_gt(debuff_free_defence, 120.0,
		"A durable Defence buff (Fortify) must count toward the debuff-free reference")
