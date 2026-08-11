extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const ROOTFEEDER_PATH: String = "res://Data/Character_Traits/Grafts/Rootfeeder_Graft.tres"

func _make_rootfeeder(p_rarity: Types.Rarity) -> RootfeederGraft:
	var graft: RootfeederGraft = load(ROOTFEEDER_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func test_heal_fraction_scales_by_rarity() -> void:
	var expected: Dictionary[Types.Rarity, float] = RootfeederGraft.HEAL_FRACTION_PER_RARITY
	for rarity: Types.Rarity in expected:
		var graft: RootfeederGraft = _make_rootfeeder(rarity)
		var roster: Dictionary = TestFactory.make_full_roster()
		roster[0]._current_health = 1
		var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

		graft.OnAffectedByZone(0, 3, resolver)

		var max_health: int = resolver.GetMaxHealth(0)
		var expected_heal: int = int(round(max_health * expected[rarity]))
		assert_eq(roster[0]._current_health, mini(1 + expected_heal, max_health),
				"Heal fraction should scale with rarity %s" % Types.RarityName(rarity))

func test_multiplier_is_higher_against_an_enemy_owned_zone() -> void:
	var graft: RootfeederGraft = _make_rootfeeder(Types.Rarity.Uncommon)
	var sides: CombatSides = TestFactory.make_full_sides()

	assert_eq(graft.GetIncomingZoneEffectMultiplier(0, 3, sides), RootfeederGraft.ENEMY_ZONE_EFFECT_MULTIPLIER)

func test_multiplier_is_unscaled_against_an_ally_owned_zone() -> void:
	var graft: RootfeederGraft = _make_rootfeeder(Types.Rarity.Uncommon)
	var sides: CombatSides = TestFactory.make_full_sides()

	assert_eq(graft.GetIncomingZoneEffectMultiplier(0, 1, sides), 1.0)
