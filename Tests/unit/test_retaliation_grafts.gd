extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const GLASS_REFRACTION_PATH: String = "res://Data/Character_Traits/Grafts/Glass_Refraction_Graft.tres"
const UNDERTOW_PATH: String = "res://Data/Character_Traits/Grafts/Undertow_Graft.tres"
const GLAMOUR_PATH: String = "res://Data/Character_Traits/Grafts/Glamour_Graft.tres"

func _make_glass_refraction(p_rarity: Types.Rarity) -> GlassRefractionGraft:
	var graft: GlassRefractionGraft = load(GLASS_REFRACTION_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_undertow(p_rarity: Types.Rarity) -> UndertowGraft:
	var graft: UndertowGraft = load(UNDERTOW_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_glamour(p_rarity: Types.Rarity) -> GlamourGraft:
	var graft: GlamourGraft = load(GLAMOUR_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _bumps(p_batch: Array[CombatResult]) -> Array[CombatResult]:
	return p_batch.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump)

func _damage_to(p_batch: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_batch.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == p_target_ID)

# --- Glass Refraction ---

func test_glass_refraction_deals_mysticism_scaled_backlash_to_the_attacker() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Mysticism] = 100
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: GlassRefractionGraft = _make_glass_refraction(Types.Rarity.Uncommon)

	graft.OnDamageTaken(0, 3, resolver)

	var damage: Array[CombatResult] = _damage_to(resolver._batch, 3)
	assert_eq(damage.size(), 1, "The backlash should strike the attacker")

func test_glass_refraction_does_not_retaliate_against_a_dead_attacker() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[3]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: GlassRefractionGraft = _make_glass_refraction(Types.Rarity.Uncommon)

	graft.OnDamageTaken(0, 3, resolver)

	assert_true(_damage_to(resolver._batch, 3).is_empty())

func test_glass_refraction_does_not_retaliate_against_self_damage() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: GlassRefractionGraft = _make_glass_refraction(Types.Rarity.Uncommon)

	graft.OnDamageTaken(0, 0, resolver)

	assert_true(_damage_to(resolver._batch, 0).is_empty())

# --- Undertow ---

func test_undertow_pulls_an_enemy_attacker_and_self_reduces() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: UndertowGraft = _make_undertow(Types.Rarity.Uncommon)

	graft.OnDamageTaken(0, 3, resolver)

	var bumps: Array[CombatResult] = _bumps(resolver._batch)
	var attacker_bump: Array[CombatResult] = bumps.filter(func(r): return r.target_ID == 3)
	var self_bump: Array[CombatResult] = bumps.filter(func(r): return r.target_ID == 0)
	assert_eq(attacker_bump.size(), 1)
	assert_almost_eq(attacker_bump[0].fraction, -UndertowGraft.PULL_PER_RARITY[Types.Rarity.Uncommon], 0.0001)
	assert_eq(self_bump.size(), 1)
	assert_almost_eq(self_bump[0].fraction, -UndertowGraft.SELF_TURN_BAR_LOSS, 0.0001)

func test_undertow_ignores_an_ally_hit() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: UndertowGraft = _make_undertow(Types.Rarity.Uncommon)

	graft.OnDamageTaken(0, 1, resolver)

	assert_true(_bumps(resolver._batch).is_empty(), "Undertow should only react to an enemy hit")

func test_undertow_ignores_self_damage() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: UndertowGraft = _make_undertow(Types.Rarity.Uncommon)

	graft.OnDamageTaken(0, 0, resolver)

	assert_true(_bumps(resolver._batch).is_empty())

# --- Glamour ---

func test_glamour_targeting_priority_multiplier() -> void:
	var graft: GlamourGraft = _make_glamour(Types.Rarity.Uncommon)
	assert_almost_eq(graft.GetTargetingPriorityMultiplier(), GlamourGraft.TARGETING_PRIORITY_MULTIPLIER, 0.0001)

func test_glamour_takes_ten_percent_more_damage() -> void:
	var graft: GlamourGraft = _make_glamour(Types.Rarity.Uncommon)
	assert_almost_eq(graft.OnDamageTaken(0, 3, null), GlamourGraft.DAMAGE_TAKEN_MULTIPLIER, 0.0001)

func test_glamour_adds_its_damage_dealt_bonus_at_start_of_battle() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Attack] = 200
	roster[0]._skills.append(TestFactory.make_strike_skill())

	var baseline_roster: Dictionary = TestFactory.make_full_roster()
	baseline_roster[0]._attributes[Types.Attribute.Attack] = 200
	baseline_roster[0]._skills.append(TestFactory.make_strike_skill())
	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var baseline_damage: int = _strike_damage(baseline_resolver)

	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var graft: GlamourGraft = _make_glamour(Types.Rarity.Uncommon)
	graft.StartOfBattle(0, resolver)
	var boosted_damage: int = _strike_damage(resolver)

	assert_gt(boosted_damage, baseline_damage, "Glamour's +10% dealt should raise its own subsequent damage")

func _strike_damage(p_resolver: BattleResolver) -> int:
	var results: Array[CombatResult] = p_resolver.ResolveSkill(0, [3], 0)
	for result in results:
		if(CombatResult.Kind.Damage == result.kind and 3 == result.target_ID):
			return result.amount
	return -1
