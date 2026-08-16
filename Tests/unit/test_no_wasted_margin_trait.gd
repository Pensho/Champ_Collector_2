extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _trait: NoWastedMarginTrait = null

func before_each() -> void:
	_trait = NoWastedMarginTrait.new()

# --- Rarity-keyed conversion rate ---

func test_overflow_rate_by_rarity() -> void:
	var rates: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 2.0,
		Types.Rarity.Rare: 3.0,
		Types.Rarity.Epic: 4.0,
		Types.Rarity.Legendary: 5.0,
	}
	for rarity: Types.Rarity in rates:
		_trait.Init(rarity)
		assert_almost_eq(_trait.GetCritChanceOverflowRate(), rates[rarity], 0.0001,
			"Overflow rate must match the rarity table for %s" % Types.Rarity.keys()[rarity])

func test_overflow_rate_defaults_to_zero_for_unlisted_rarity() -> void:
	_trait.Init(Types.Rarity.Common)
	assert_almost_eq(_trait.GetCritChanceOverflowRate(), 0.0, 0.0001,
		"Common is not in the rarity table and must convert nothing")

# --- Skills.CritChanceOverflowRate: team-wide fan-out ---

func test_skills_crit_chance_overflow_rate_sums_across_the_living_team() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._trait = NoWastedMarginTrait.new()
	roster[0]._trait.Init(Types.Rarity.Legendary)
	var sides: CombatSides = TestFactory.make_full_sides()

	assert_almost_eq(Skills.CritChanceOverflowRate(sides, roster, 0), 5.0, 0.0001,
		"The trait holder's own rate must count")
	assert_almost_eq(Skills.CritChanceOverflowRate(sides, roster, 1), 5.0, 0.0001,
		"A living ally must read the same team-wide rate")
	assert_almost_eq(Skills.CritChanceOverflowRate(sides, roster, 3), 0.0, 0.0001,
		"An enemy must not read the Appraiser's ally-side rate")

func test_skills_crit_chance_overflow_rate_ignores_a_dead_holder() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._trait = NoWastedMarginTrait.new()
	roster[0]._trait.Init(Types.Rarity.Legendary)
	roster[0]._current_health = 0
	var sides: CombatSides = TestFactory.make_full_sides()

	assert_almost_eq(Skills.CritChanceOverflowRate(sides, roster, 1), 0.0, 0.0001,
		"A dead trait holder must not contribute its rate")

# --- End-to-end: the crit-damage overflow term in _ResolveDamage ---

func test_overflow_increases_crit_damage_dealt_above_one_hundred_chance() -> void:
	var baseline_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var overflow_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for roster in [baseline_roster, overflow_roster]:
		roster[0]._skills.append(TestFactory.make_strike_skill())
		roster[0]._attributes[Types.Attribute.CritChance] = 120
	overflow_roster[0]._trait = NoWastedMarginTrait.new()
	overflow_roster[0]._trait.Init(Types.Rarity.Legendary)

	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var overflow_resolver: BattleResolver = TestFactory.make_resolver(overflow_roster, TestFactory.make_full_sides())

	var baseline_results: Array[CombatResult] = baseline_resolver.ResolveSkill(0, [3], 0)
	var overflow_results: Array[CombatResult] = overflow_resolver.ResolveSkill(0, [3], 0)

	var baseline_damage: Array = baseline_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	var overflow_damage: Array = overflow_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	assert_true(baseline_damage[0].critical and overflow_damage[0].critical,
		"Both hits should be guaranteed crits at 120 Critical Chance")
	assert_gt(overflow_damage[0].amount, baseline_damage[0].amount,
		"No Wasted Margin should convert the 20 excess Critical Chance into extra Critical Damage")

func test_overflow_contributes_nothing_at_or_below_one_hundred_chance() -> void:
	var baseline_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var overflow_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for roster in [baseline_roster, overflow_roster]:
		roster[0]._skills.append(TestFactory.make_strike_skill())
		roster[0]._attributes[Types.Attribute.CritChance] = 100
	overflow_roster[0]._trait = NoWastedMarginTrait.new()
	overflow_roster[0]._trait.Init(Types.Rarity.Legendary)

	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var overflow_resolver: BattleResolver = TestFactory.make_resolver(overflow_roster, TestFactory.make_full_sides())

	var baseline_results: Array[CombatResult] = baseline_resolver.ResolveSkill(0, [3], 0)
	var overflow_results: Array[CombatResult] = overflow_resolver.ResolveSkill(0, [3], 0)

	var baseline_damage: Array = baseline_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	var overflow_damage: Array = overflow_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	assert_eq(overflow_damage[0].amount, baseline_damage[0].amount,
		"Exactly 100 Critical Chance leaves nothing to convert, so damage must match the baseline")
