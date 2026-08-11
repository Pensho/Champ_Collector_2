extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const SYMBIOTIC_ANCHOR_PATH: String = "res://Data/Character_Traits/Grafts/Symbiotic_Anchor_Graft.tres"

func _make_symbiotic_anchor(p_rarity: Types.Rarity) -> SymbioticAnchorGraft:
	var graft: SymbioticAnchorGraft = load(SYMBIOTIC_ANCHOR_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func test_start_of_battle_shares_resistance_and_attack_with_the_only_living_ally() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(SYMBIOTIC_ANCHOR_PATH))
	roster[2]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	roster[0]._trait.StartOfBattle(0, resolver)

	var expected_resistance: int = roster[1].GetTotalAttribute(Types.Attribute.Resistance) \
			+ int(ceilf(roster[0].GetTotalAttribute(Types.Attribute.Resistance) * 0.20))
	var expected_attack: int = roster[1].GetTotalAttribute(Types.Attribute.Attack) \
			+ int(ceilf(roster[0].GetTotalAttribute(Types.Attribute.Attack) * 0.20))
	assert_eq(resolver.GetEffectiveAttributes(1)[Types.Attribute.Resistance], expected_resistance)
	assert_eq(resolver.GetEffectiveAttributes(1)[Types.Attribute.Attack], expected_attack)

func test_re_tethers_to_the_surviving_ally_when_the_tethered_ally_dies() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(SYMBIOTIC_ANCHOR_PATH))
	roster[2]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._trait.StartOfBattle(0, resolver)

	roster[1]._current_health = 0
	roster[2]._current_health = roster[2]._attributes[Types.Attribute.Health]
	roster[0]._trait.OnAllyDeath(0, 1, resolver)

	var expected_resistance: int = roster[2].GetTotalAttribute(Types.Attribute.Resistance) \
			+ int(ceilf(roster[0].GetTotalAttribute(Types.Attribute.Resistance) * 0.20))
	assert_eq(resolver.GetEffectiveAttributes(2)[Types.Attribute.Resistance], expected_resistance,
			"The new sole survivor should now carry the shared bonus")

func test_a_non_tethered_allys_death_is_a_no_op() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(SYMBIOTIC_ANCHOR_PATH))
	roster[2]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._trait.StartOfBattle(0, resolver)
	var before: int = resolver.GetEffectiveAttributes(1)[Types.Attribute.Resistance]

	roster[0]._trait.OnAllyDeath(0, 2, resolver)

	assert_eq(resolver.GetEffectiveAttributes(1)[Types.Attribute.Resistance], before,
			"Death of an ally that was never tethered should not re-tether")

func test_symbiote_alone_leaves_no_tether_and_does_not_crash() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(SYMBIOTIC_ANCHOR_PATH))
	roster[1]._current_health = 0
	roster[2]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	roster[0]._trait.StartOfBattle(0, resolver)

	var graft: SymbioticAnchorGraft = roster[0]._trait as SymbioticAnchorGraft
	assert_eq(graft._tethered_ally_ID, -1)

func test_shared_bonus_is_a_snapshot_that_ignores_later_symbiote_stat_changes() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(SYMBIOTIC_ANCHOR_PATH))
	roster[2]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._trait.StartOfBattle(0, resolver)
	var before: int = resolver.GetEffectiveAttributes(1)[Types.Attribute.Resistance]

	resolver.AdjustLongAttributeBonus(0, Types.Attribute.Resistance, 50)

	assert_eq(resolver.GetEffectiveAttributes(1)[Types.Attribute.Resistance], before,
			"The ally's shared bonus should not follow later changes to the Symbiote's Resistance")
