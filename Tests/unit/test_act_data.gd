extends GutTest

var _act: ActData
var _jungle: AdventureData
var _ruins: AdventureData

func before_each() -> void:
	_jungle = AdventureData.new()
	_ruins = AdventureData.new()
	_act = ActData.new()
	var adventures: Array[AdventureData] = [_jungle, _ruins]
	_act.adventures = adventures

func test_find_adventure_index_returns_matching_index() -> void:
	assert_eq(_act.FindAdventureIndex(_ruins), 1, "Should return the index of the matching adventure.")

func test_find_adventure_index_returns_negative_one_when_absent() -> void:
	assert_eq(_act.FindAdventureIndex(AdventureData.new()), -1,
		"Should return -1 when the act does not hold the adventure.")

func test_find_adventure_index_returns_negative_one_for_null() -> void:
	assert_eq(_act.FindAdventureIndex(null), -1,
		"Should return -1 for an inactive state with no adventure.")

func test_has_adventures_with_a_full_set() -> void:
	assert_true(_act.HasAdventures(), "An act holding both adventures should offer them.")

func test_has_no_adventures_when_empty() -> void:
	assert_false(ActData.new().HasAdventures(), "An act without adventures should not offer them.")

func test_has_no_adventures_with_fewer_than_the_selection_shows() -> void:
	var partial_act: ActData = ActData.new()
	var adventures: Array[AdventureData] = [_jungle]
	partial_act.adventures = adventures
	assert_false(partial_act.HasAdventures(),
		"An act short of the selection screen's adventure count should not offer them.")

func test_adventures_sharing_a_biome_stay_distinct() -> void:
	var shared_biome: BiomeData = BiomeData.new()
	_jungle.biome = shared_biome
	_ruins.biome = shared_biome
	assert_eq(_act.FindAdventureIndex(_ruins), 1,
		"Adventures that share a biome must still resolve to their own index.")
