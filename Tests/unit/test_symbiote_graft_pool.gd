extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const WRETCHED_CONSCRIPT_PATH: String = "res://Data/Character_Traits/Grafts/Wretched_Conscript_Graft.tres"
const SPREADING_ROT_PATH: String = "res://Data/Character_Traits/Grafts/Spreading_Rot_Graft.tres"
const REACTIVE_PLATING_PATH: String = "res://Data/Character_Traits/Grafts/Reactive_Plating_Graft.tres"
const STRENGTH_IN_NUMBERS_PATH: String = "res://Data/Character_Traits/Grafts/Strength_In_Numbers_Graft.tres"
const HOLLOW_HUNGER_PATH: String = "res://Data/Character_Traits/Grafts/Hollow_Hunger_Graft.tres"
const CARRION_BLOOM_PATH: String = "res://Data/Character_Traits/Grafts/Carrion_Bloom_Graft.tres"
const OVERGROWTH_PATH: String = "res://Data/Character_Traits/Grafts/Overgrowth_Graft.tres"

func _make_wretched_conscript(p_rarity: Types.Rarity) -> WretchedConscriptGraft:
	var graft: WretchedConscriptGraft = load(WRETCHED_CONSCRIPT_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_spreading_rot(p_rarity: Types.Rarity) -> SpreadingRotGraft:
	var graft: SpreadingRotGraft = load(SPREADING_ROT_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_reactive_plating(p_rarity: Types.Rarity) -> ReactivePlatingGraft:
	var graft: ReactivePlatingGraft = load(REACTIVE_PLATING_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_hollow_hunger(p_rarity: Types.Rarity) -> HollowHungerGraft:
	var graft: HollowHungerGraft = load(HOLLOW_HUNGER_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_carrion_bloom(p_rarity: Types.Rarity) -> CarrionBloomGraft:
	var graft: CarrionBloomGraft = load(CARRION_BLOOM_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func _make_overgrowth(p_rarity: Types.Rarity) -> OvergrowthGraft:
	var graft: OvergrowthGraft = load(OVERGROWTH_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

# --- Wretched Conscript ---

func test_wretched_conscript_defence_bonus_scales_by_rarity() -> void:
	for rarity: Types.Rarity in WretchedConscriptGraft.DEFENCE_BONUS_PER_RARITY:
		var graft: WretchedConscriptGraft = _make_wretched_conscript(rarity)
		var expected: int = int(ceilf(100 * WretchedConscriptGraft.DEFENCE_BONUS_PER_RARITY[rarity]))
		assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), expected,
				"Defence bonus should scale with rarity %s" % Types.RarityName(rarity))

func test_wretched_conscript_has_no_drawback() -> void:
	var graft: WretchedConscriptGraft = _make_wretched_conscript(Types.Rarity.Epic)
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Speed, 100), 0)

func test_wretched_conscript_total_attribute_includes_bonus_and_stays_pristine() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Epic
	var base_defence: int = character._attributes[Types.Attribute.Defence]
	var expected_delta: int = int(ceilf(base_defence * WretchedConscriptGraft.DEFENCE_BONUS_PER_RARITY[Types.Rarity.Epic]))

	character.ApplyGraft(load(WRETCHED_CONSCRIPT_PATH))

	assert_eq(character.GetTotalAttribute(Types.Attribute.Defence), base_defence + expected_delta)
	assert_eq(character._attributes[Types.Attribute.Defence], base_defence,
			"_attributes must stay the pristine ungrafted base")

# --- Spreading Rot ---

func test_spreading_rot_health_bonus_scales_by_rarity() -> void:
	for rarity: Types.Rarity in SpreadingRotGraft.HEALTH_BONUS_PER_RARITY:
		var graft: SpreadingRotGraft = _make_spreading_rot(rarity)
		var expected: int = int(ceilf(100 * SpreadingRotGraft.HEALTH_BONUS_PER_RARITY[rarity]))
		assert_eq(graft.GetAttributeDelta(Types.Attribute.Health, 100), expected,
				"Health bonus should scale with rarity %s" % Types.RarityName(rarity))

func test_spreading_rot_onskillcast_applies_blight_to_enemy_not_ally() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	var sides: CombatSides = TestFactory.make_full_sides()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, sides)
	var graft: SpreadingRotGraft = _make_spreading_rot(Types.Rarity.Uncommon)

	graft.OnSkillCast(0, [3, 1], "Strike", {}, resolver)

	assert_eq(roster[3]._active_debuffs.size(), 1, "The enemy target should be Blighted")
	assert_eq(roster[3]._active_debuffs[0].type, Types.Debuff_Type.Blight)
	assert_true(roster[1]._active_debuffs.is_empty(), "The ally target should not be Blighted")

func test_spreading_rot_start_of_turn_reduces_health_by_3_percent_of_max() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Rare
	character.ApplyGraft(load(SPREADING_ROT_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, CombatSides.new([0], []))
	var max_health: int = resolver.GetMaxHealth(0)
	character._current_health = max_health

	character._trait.StartOfTurn(0, resolver)

	assert_eq(character._current_health, max_health - int(0.03 * max_health))

# --- Reactive Plating ---

func test_reactive_plating_ondamagetaken_adds_hardened_stack_and_caps_at_9() -> void:
	var graft: ReactivePlatingGraft = _make_reactive_plating(Types.Rarity.Uncommon)

	for i in 12:
		graft.OnDamageTaken(0, null)

	assert_eq(graft._stacks, 9)

func test_reactive_plating_defence_bonus_scales_with_stacks() -> void:
	var graft: ReactivePlatingGraft = _make_reactive_plating(Types.Rarity.Uncommon)
	for i in 3:
		graft.OnDamageTaken(0, null)

	assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), 6)

func test_reactive_plating_defence_bonus_is_zero_before_any_hit() -> void:
	var graft: ReactivePlatingGraft = _make_reactive_plating(Types.Rarity.Uncommon)

	assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), 0)

func test_reactive_plating_defence_bonus_applies_outside_of_defending() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Uncommon
	character.ApplyGraft(load(REACTIVE_PLATING_PATH))
	(character._trait as ReactivePlatingGraft).OnDamageTaken(0, null)
	var base_defence: int = character._attributes[Types.Attribute.Defence]
	var expected_delta: int = int(ceilf(base_defence * 0.02))

	assert_eq(character.GetTotalAttribute(Types.Attribute.Defence), base_defence + expected_delta,
			"The Hardened bonus is an inherent attribute delta, not conditional on being attacked")

func test_reactive_plating_speed_drawback_stays_flat_across_rarities() -> void:
	var expected: int = -int(ceilf(100 * absf(ReactivePlatingGraft.SPEED_DRAWBACK)))
	for rarity: Types.Rarity in ReactivePlatingGraft.DEFENCE_BONUS_PER_STACK:
		var graft: ReactivePlatingGraft = _make_reactive_plating(rarity)
		assert_eq(graft.GetAttributeDelta(Types.Attribute.Speed, 100), expected)

# --- Strength in Numbers ---

func test_strength_in_numbers_bonus_scales_with_living_ally_count() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(STRENGTH_IN_NUMBERS_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	roster[0]._trait.StartOfBattle(0, resolver)

	var graft: GraftEffect = roster[0]._trait as GraftEffect
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), 16,
			"Two other living allies should scale the bonus to 2x the per-ally bonus")
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), 16)

func test_strength_in_numbers_recomputes_on_ally_death() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(STRENGTH_IN_NUMBERS_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._trait.StartOfBattle(0, resolver)

	roster[1]._current_health = 0
	roster[0]._trait.OnAllyDeath(0, 1, resolver)

	var graft: GraftEffect = roster[0]._trait as GraftEffect
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), 8,
			"Only one other living ally should remain")
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), 8)

# --- Hollow Hunger ---

func test_hollow_hunger_heals_owner_by_lifesteal_fraction_of_damage_dealt() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(HOLLOW_HUNGER_PATH))
	roster[0]._current_health = 1
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			0, [3], resolver.GetCombatAttributes(0), {Types.Attribute.Attack: 1.0})

	var damage_dealt: int = 0
	var healed: int = -1
	for result in results:
		if(CombatResult.Kind.Damage == result.kind and 3 == result.target_ID):
			damage_dealt = result.amount
		if(CombatResult.Kind.Heal == result.kind and 0 == result.target_ID):
			healed = result.amount

	assert_gt(damage_dealt, 0, "The strike should have dealt damage to size the lifesteal")
	assert_eq(healed, int(round(damage_dealt * HollowHungerGraft.LIFESTEAL_FRACTION_PER_RARITY[Types.Rarity.Uncommon])))

func test_hollow_hunger_health_drawback_stays_flat_across_rarities() -> void:
	for rarity: Types.Rarity in HollowHungerGraft.LIFESTEAL_FRACTION_PER_RARITY:
		var graft: HollowHungerGraft = _make_hollow_hunger(rarity)
		assert_eq(graft.GetAttributeDelta(Types.Attribute.Health, 100), -15)

# --- Carrion Bloom ---

func test_carrion_bloom_start_of_turn_heals_the_lowest_health_living_ally() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(CARRION_BLOOM_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[1]._current_health = 1

	roster[0]._trait.StartOfTurn(0, resolver)

	assert_eq(roster[1]._current_health, 1 + int(round(resolver.GetMaxHealth(1) * 0.03)),
			"The lowest-Health living ally (including the owner as its own ally) should be healed")

func test_carrion_bloom_start_of_turn_can_heal_the_owner_itself() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0]._attributes[Types.Attribute.Health] = 1000
	roster[0].ApplyGraft(load(CARRION_BLOOM_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._current_health = 1

	roster[0]._trait.StartOfTurn(0, resolver)

	assert_gt(roster[0]._current_health, 1,
			"The Symbiote itself should be eligible when it is lowest, even with its own halved self-heal")

func test_carrion_bloom_halves_healing_the_owner_receives() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(CARRION_BLOOM_PATH))
	roster[0]._current_health = 1
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	resolver.ResolveTraitHeal([0], 0.0, 10)

	assert_eq(roster[0]._current_health, 1 + 5, "Healing the owner should be halved by the graft's drawback")

func test_carrion_bloom_health_bonus_scales_by_rarity() -> void:
	for rarity: Types.Rarity in CarrionBloomGraft.HEALTH_BONUS_PER_RARITY:
		var graft: CarrionBloomGraft = _make_carrion_bloom(rarity)
		var expected: int = int(ceilf(100 * CarrionBloomGraft.HEALTH_BONUS_PER_RARITY[rarity]))
		assert_eq(graft.GetAttributeDelta(Types.Attribute.Health, 100), expected)

# --- Overgrowth ---

func test_overgrowth_heal_scales_with_current_stack_count() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Uncommon
	character.ApplyGraft(load(OVERGROWTH_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, CombatSides.new([0], []))
	character._current_health = 1

	character._trait.StartOfTurn(0, resolver)
	var health_after_first: int = character._current_health
	character._current_health = 1
	character._trait.StartOfTurn(0, resolver)

	var max_health: int = resolver.GetMaxHealth(0)
	assert_eq(health_after_first, 1 + int(round(max_health * 0.01)))
	assert_eq(character._current_health, 1 + int(round(max_health * 0.02)),
			"The second stack should heal for twice as much as the first")

func test_overgrowth_grants_regeneration_to_every_ally_at_six_stacks_and_resets() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(OVERGROWTH_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	for i in 6:
		roster[0]._trait.StartOfTurn(0, resolver)

	for ally_ID in [0, 1, 2]:
		assert_eq(roster[ally_ID]._active_buffs.size(), 1)
		assert_eq(roster[ally_ID]._active_buffs[0].type, Types.Buff_Type.Regeneration)
		assert_eq(roster[ally_ID]._active_buffs[0].duration, 1)
	assert_eq((roster[0]._trait as OvergrowthGraft)._stacks, 0)

func test_overgrowth_does_not_grant_regeneration_below_six_stacks() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(OVERGROWTH_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	for i in 5:
		roster[0]._trait.StartOfTurn(0, resolver)

	assert_true(roster[1]._active_buffs.is_empty())
	assert_eq((roster[0]._trait as OvergrowthGraft)._stacks, 5)

func test_strength_in_numbers_applies_no_ally_penalty_when_alone() -> void:
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._rarity = Types.Rarity.Uncommon
	roster[0].ApplyGraft(load(STRENGTH_IN_NUMBERS_PATH))
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._trait.StartOfBattle(0, resolver)

	roster[1]._current_health = 0
	roster[0]._trait.OnAllyDeath(0, 1, resolver)
	roster[2]._current_health = 0
	roster[0]._trait.OnAllyDeath(0, 2, resolver)

	var graft: GraftEffect = roster[0]._trait as GraftEffect
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), -25)
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Defence, 100), 0,
			"No Defence penalty while isolated, only Resistance")
