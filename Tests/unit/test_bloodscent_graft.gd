extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const BLOODSCENT_PATH: String = "res://Data/Character_Traits/Grafts/Bloodscent_Graft.tres"

func _make_bloodscent(p_rarity: Types.Rarity) -> BloodscentGraft:
	var graft: BloodscentGraft = load(BLOODSCENT_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func test_bloodscent_heals_on_a_killing_blow() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(BLOODSCENT_PATH))
	roster[0]._current_health = 1
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	roster[0]._trait.OnKill(0, 3, resolver)

	assert_eq(roster[0]._current_health, 1 + int(round(resolver.GetMaxHealth(0) * BloodscentGraft.KILL_HEAL_FRACTION)))

func test_bloodscent_penalizes_a_target_above_half_health_even_if_lowest() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[3]._current_health = resolver.GetMaxHealth(3)
	roster[4]._current_health = resolver.GetMaxHealth(4)
	roster[5]._current_health = resolver.GetMaxHealth(5)
	var graft: BloodscentGraft = _make_bloodscent(Types.Rarity.Uncommon)

	var bonus: float = graft.GetOutgoingDamageBonus(0, 3, resolver)

	assert_almost_eq(bonus, -BloodscentGraft.ABOVE_HALF_PENALTY, 0.0001,
			"Penalty wins even for the lowest-Health enemy when it is above 50% Health")

func test_bloodscent_bonuses_the_lowest_health_enemy_at_or_below_half_health() -> void:
	for rarity: Types.Rarity in BloodscentGraft.LOWEST_HEALTH_BONUS_PER_RARITY:
		var roster: Dictionary = TestFactory.make_full_roster()
		var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
		roster[3]._current_health = int(resolver.GetMaxHealth(3) * 0.5)
		roster[4]._current_health = roster[3]._current_health + 1
		roster[5]._current_health = roster[3]._current_health + 1
		var graft: BloodscentGraft = _make_bloodscent(rarity)

		var bonus: float = graft.GetOutgoingDamageBonus(0, 3, resolver)

		assert_almost_eq(bonus, BloodscentGraft.LOWEST_HEALTH_BONUS_PER_RARITY[rarity], 0.0001)

func test_bloodscent_gives_no_bonus_to_a_non_lowest_enemy_at_or_below_half_health() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[3]._current_health = int(resolver.GetMaxHealth(3) * 0.5)
	roster[4]._current_health = roster[3]._current_health - 1
	roster[5]._current_health = roster[3]._current_health + 1
	var graft: BloodscentGraft = _make_bloodscent(Types.Rarity.Uncommon)

	var bonus: float = graft.GetOutgoingDamageBonus(0, 3, resolver)

	assert_eq(bonus, 0.0)
