extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const BLOODSCENT_PATH: String = "res://Data/Character_Traits/Grafts/Bloodscent_Graft.tres"

func _make_bloodscent(p_rarity: Types.Rarity) -> BloodscentGraft:
	var graft: BloodscentGraft = load(BLOODSCENT_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

## Fixed outgoing-damage bonus for exercising the On_Kill / conditional-damage primitives
## in isolation from Bloodscent's own target-Health branching.
class FakeOutgoingDamageTrait extends CharacterTrait:
	var bonus: float = 0.0
	var kill_calls: Array = []

	func _init(p_bonus: float = 0.0) -> void:
		bonus = p_bonus
		_execution_steps[Types.Combat_Event.On_Kill] = Callable(self, "OnKill")

	func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
		return bonus

	func OnKill(p_owner_ID: int, p_victim_ID: int, _p_resolver: BattleResolver) -> void:
		kill_calls.append([p_owner_ID, p_victim_ID])

# --- P1: on-kill hook ---

func test_on_kill_fires_on_a_lethal_attack() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_strike_skill())
	roster[0]._attributes[Types.Attribute.Attack] = 1000
	roster[3]._current_health = 1
	roster[3]._attributes[Types.Attribute.Defence] = 0
	var trait_probe: FakeOutgoingDamageTrait = FakeOutgoingDamageTrait.new()
	roster[0]._trait = trait_probe
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveSkill(0, [3], 0)

	assert_eq(trait_probe.kill_calls, [[0, 3]], "OnKill should fire with (owner, victim) on the killing blow")

func test_on_kill_does_not_fire_on_a_non_lethal_hit() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_strike_skill())
	var trait_probe: FakeOutgoingDamageTrait = FakeOutgoingDamageTrait.new()
	roster[0]._trait = trait_probe
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveSkill(0, [3], 0)

	assert_true(trait_probe.kill_calls.is_empty(), "A non-lethal hit should not fire On_Kill")

func test_on_kill_does_not_fire_when_deathward_rescues_the_target() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_strike_skill())
	roster[0]._attributes[Types.Attribute.Attack] = 1000
	roster[3]._current_health = 1
	roster[3]._attributes[Types.Attribute.Defence] = 0
	var deathward: StatusEffects.Buff = StatusEffects.Buff.new()
	deathward.type = Types.Buff_Type.Deathward
	deathward.duration = 2
	roster[3]._active_buffs.append(deathward)
	var trait_probe: FakeOutgoingDamageTrait = FakeOutgoingDamageTrait.new()
	roster[0]._trait = trait_probe
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveSkill(0, [3], 0)

	assert_true(trait_probe.kill_calls.is_empty(), "A Deathward rescue to 1 HP is not a kill")
	assert_eq(roster[3]._current_health, 1)

# --- P2: target-Health-conditional outgoing-damage bonus ---

func test_outgoing_damage_bonus_raises_dealt_damage() -> void:
	var boosted_damage: int = _strike_damage(FakeOutgoingDamageTrait.new(0.5))
	var baseline_damage: int = _strike_damage(FakeOutgoingDamageTrait.new(0.0))

	assert_gt(boosted_damage, baseline_damage, "+0.5 should raise the primary target's dealt damage")

func test_outgoing_damage_bonus_lowers_dealt_damage() -> void:
	var reduced_damage: int = _strike_damage(FakeOutgoingDamageTrait.new(-0.25))
	var baseline_damage: int = _strike_damage(FakeOutgoingDamageTrait.new(0.0))

	assert_lt(reduced_damage, baseline_damage, "-0.25 should lower the primary target's dealt damage")

func test_default_trait_leaves_damage_unchanged() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_strike_skill())
	roster[0]._attributes[Types.Attribute.Attack] = 200
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], 0)

	var baseline_damage: int = _strike_damage(FakeOutgoingDamageTrait.new(0.0))
	assert_eq(_damage_amount(results, 3), baseline_damage)

func _strike_damage(p_trait: CharacterTrait) -> int:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._skills.append(TestFactory.make_strike_skill())
	roster[0]._attributes[Types.Attribute.Attack] = 200
	roster[0]._trait = p_trait
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], 0)
	return _damage_amount(results, 3)

func _damage_amount(p_results: Array[CombatResult], p_target_ID: int) -> int:
	for result in p_results:
		if(CombatResult.Kind.Damage == result.kind and p_target_ID == result.target_ID):
			return result.amount
	return -1

# --- Bloodscent ---

func test_bloodscent_has_no_attribute_bonus_or_drawback() -> void:
	var graft: BloodscentGraft = _make_bloodscent(Types.Rarity.Epic)
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), 0)
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), 0)

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
