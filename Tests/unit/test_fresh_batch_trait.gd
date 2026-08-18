extends GutTest

## Coverage for Scripts/Character/character_traits/CharacterSpecificTraits/fresh_batch_trait.gd:
## the Alchemist's Fresh Batch passive (Concept_Document.md 3.1.3 / 3.3.3).

const NON_PURGING_POOL: Array[String] = ["Lesser_Restorative_Brew", "Lesser_Tincture", "Lesser_Barrier_Brew"]

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _trait: FreshBatchTrait = null
var _random: RandomNumberGenerator = null

func before_each() -> void:
	_trait = FreshBatchTrait.new()
	_random = RandomNumberGenerator.new()
	_random.seed = 1

func test_get_brew_potency_bonus_matches_init_rarity() -> void:
	_trait.Init(Types.Rarity.Epic)
	assert_almost_eq(_trait.GetBrewPotencyBonus(), 0.10, 0.001)

## Volatile Mixture's Uncommon-tier magnitude (the base rarity) lives on Volatile_Mixture.tres,
## not restated in the trait; this guards the derivation against silent drift between the two.
func test_team_damage_bonus_at_uncommon_matches_the_status_resources_own_magnitude() -> void:
	var base_multiplier: float = StatusEffectRegistry.BuffData(Types.Buff_Type.Volatile_Mixture).magnitude
	_trait.Init(Types.Rarity.Uncommon)

	var alchemist: Character = TestFactory.make_character()
	alchemist._current_health = alchemist._attributes[Types.Attribute.Health]
	alchemist._trait = _trait
	var characters: Dictionary[int, Character] = {0: alchemist}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))

	var results: Array[CombatResult] = resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)
	var applied: CombatResult = results.filter(func(r: CombatResult) -> bool:
			return (CombatResult.Kind.Status_Applied == r.kind
					and Types.Buff_Type.Volatile_Mixture == r.buff_type))[0]

	assert_almost_eq(applied.fraction, base_multiplier - 1.0, 0.001,
			"The {percent} description token must show the bonus fraction, not the raw multiplier")

func test_brew_pool_excludes_purging_below_epic() -> void:
	_trait.Init(Types.Rarity.Uncommon)
	for i in 20:
		var key: String = _trait.BrewReagentKey(_random)
		assert_true(NON_PURGING_POOL.has(key),
			"Uncommon/Rare Alchemists must only draw from the 3-key base pool, got %s" % key)

func test_brew_pool_includes_purging_at_epic_and_legendary() -> void:
	_trait.Init(Types.Rarity.Legendary)
	var seen_purging: bool = false
	for i in 50:
		if("Lesser_Purging_Brew" == _trait.BrewReagentKey(_random)):
			seen_purging = true
			break
	assert_true(seen_purging, "Legendary Alchemists must be able to draw Lesser Purging Brew")

func test_brew_reagent_key_never_returns_an_out_of_pool_key() -> void:
	_trait.Init(Types.Rarity.Epic)
	var full_pool: Array[String] = NON_PURGING_POOL.duplicate()
	full_pool.append("Lesser_Purging_Brew")
	for i in 30:
		var key: String = _trait.BrewReagentKey(_random)
		assert_true(full_pool.has(key), "Unexpected brew key: %s" % key)

# --- Team-wide channel 2 factor ---

func _has_buff(p_character: Character, p_type: Types.Buff_Type) -> bool:
	for buff: StatusEffects.Buff in p_character._active_buffs:
		if(p_type == buff.type):
			return true
	return false

func test_ally_reagent_consumption_grants_the_buff_to_the_whole_team() -> void:
	var alchemist: Character = TestFactory.make_character()
	alchemist._current_health = alchemist._attributes[Types.Attribute.Health]
	var alchemist_trait: FreshBatchTrait = FreshBatchTrait.new()
	alchemist_trait.Init(Types.Rarity.Epic)
	alchemist._trait = alchemist_trait
	var ally: Character = TestFactory.make_character()
	ally._current_health = ally._attributes[Types.Attribute.Health]

	var characters: Dictionary[int, Character] = {0: alchemist, 1: ally}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], []))

	# The Alchemist did not consume this reagent — its teammate did.
	resolver.ResolveReagent(1, "Restorative_Draught_Rare", 1)

	assert_true(_has_buff(alchemist, Types.Buff_Type.Volatile_Mixture),
		"An ally's consumption should grant the whole team the buff, the Alchemist included")
	assert_true(_has_buff(ally, Types.Buff_Type.Volatile_Mixture),
		"The consuming ally should also gain the team buff")

func test_alchemists_own_consumption_also_grants_the_team_buff() -> void:
	var alchemist: Character = TestFactory.make_character()
	alchemist._current_health = alchemist._attributes[Types.Attribute.Health]
	var alchemist_trait: FreshBatchTrait = FreshBatchTrait.new()
	alchemist_trait.Init(Types.Rarity.Epic)
	alchemist._trait = alchemist_trait

	var characters: Dictionary[int, Character] = {0: alchemist}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))

	resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)

	assert_true(_has_buff(alchemist, Types.Buff_Type.Volatile_Mixture),
		"The Alchemist's own reagent consumption must also trigger its team-wide factor")

func test_reagent_consumption_across_enemy_lines_does_not_leak_the_buff() -> void:
	var alchemist: Character = TestFactory.make_character()
	alchemist._current_health = alchemist._attributes[Types.Attribute.Health]
	var alchemist_trait: FreshBatchTrait = FreshBatchTrait.new()
	alchemist_trait.Init(Types.Rarity.Legendary)
	alchemist._trait = alchemist_trait
	var enemy: Character = TestFactory.make_character()
	enemy._current_health = enemy._attributes[Types.Attribute.Health]

	var characters: Dictionary[int, Character] = {0: alchemist, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))

	resolver.ResolveReagent(1, "Restorative_Draught_Rare", 1)

	assert_false(_has_buff(alchemist, Types.Buff_Type.Volatile_Mixture),
		"An enemy's reagent consumption must never grant the player team's factor")

func test_team_buff_bucket_key_is_distinct_from_fractured_idols_reagent_damage_bonus() -> void:
	var alchemist: Character = TestFactory.make_character()
	alchemist._current_health = alchemist._attributes[Types.Attribute.Health]
	var alchemist_trait: FreshBatchTrait = FreshBatchTrait.new()
	# Rare (23%) so the two buckets are numerically distinguishable from Fractured Idol
	# Legendary's 20% reagent_damage_bonus below.
	alchemist_trait.Init(Types.Rarity.Rare)
	alchemist._trait = alchemist_trait
	alchemist._skills = [TestFactory.make_strike_skill()]

	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000  # Health(1000) x ATTRIBUTE_HEALTH_MULTIPLIER(4)

	var characters: Dictionary[int, Character] = {0: alchemist, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))

	resolver.ResolveReagent(0, "Fractured_Idol_Legendary", 0)
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var damage_result: CombatResult = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and 1 == r.target_ID)[0]
	var buckets: Dictionary[StringName, float] = damage_result.combined_damage_modifier.Buckets()

	assert_true(buckets.has(&"reagent_damage_bonus"), "Fractured Idol's own bucket must still be present")
	assert_almost_eq(buckets.get(&"reagent_damage_bonus", 0.0), 0.20, 0.001)
	assert_true(buckets.has(&"Volatile_Mixture"), "Fresh Batch's factor must land under its own bucket key")
	assert_almost_eq(buckets.get(&"Volatile_Mixture", 0.0), 0.23, 0.001)
