extends GutTest

## Coverage for Scripts/Character/character_traits/CharacterSpecificTraits/fresh_batch_trait.gd:
## the Alchemist's Fresh Batch passive (Concept_Document.md 3.1.3 / 3.3.3).

const NON_PURGING_POOL: Array[String] = ["Lesser_Restorative_Brew", "Lesser_Tincture", "Lesser_Barrier_Brew"]

var _trait: FreshBatchTrait = null
var _random: RandomNumberGenerator = null

func before_each() -> void:
	_trait = FreshBatchTrait.new()
	_random = RandomNumberGenerator.new()
	_random.seed = 1

func test_potency_bonus_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: -0.10,
		Types.Rarity.Rare: 0.0,
		Types.Rarity.Epic: 0.10,
		Types.Rarity.Legendary: 0.20,
	}
	for rarity: Types.Rarity in expected:
		assert_almost_eq(FreshBatchTrait.POTENCY_BONUS.get(rarity, 0.0), expected[rarity], 0.001,
			"POTENCY_BONUS at %s" % Types.RarityName(rarity))

func test_get_brew_potency_bonus_matches_init_rarity() -> void:
	_trait.Init(Types.Rarity.Epic)
	assert_almost_eq(_trait.GetBrewPotencyBonus(), 0.10, 0.001)

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
