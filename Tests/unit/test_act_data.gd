extends GutTest

var _act: ActData
var _jungle_biome: BiomeData
var _ruins_biome: BiomeData

func before_each() -> void:
	_jungle_biome = BiomeData.new()
	_ruins_biome = BiomeData.new()
	var jungle_entry: ActBiomeEntry = ActBiomeEntry.new()
	jungle_entry.biome = _jungle_biome
	var ruins_entry: ActBiomeEntry = ActBiomeEntry.new()
	ruins_entry.biome = _jungle_biome
	_act = ActData.new()
	var entries: Array[ActBiomeEntry] = [jungle_entry, ruins_entry]
	_act.biome_entries = entries

func test_find_entry_index_for_biome_returns_matching_index() -> void:
	assert_eq(_act.FindEntryIndexForBiome(_jungle_biome), 0,
		"Should return the first entry whose biome matches.")

func test_find_entry_index_for_biome_returns_negative_one_when_absent() -> void:
	assert_eq(_act.FindEntryIndexForBiome(_ruins_biome), -1,
		"Should return -1 when no entry's biome matches.")

func test_find_entry_index_for_biome_returns_negative_one_when_empty() -> void:
	_act.biome_entries = []
	assert_eq(_act.FindEntryIndexForBiome(_jungle_biome), -1,
		"Should return -1 when there are no entries to search.")

func test_find_entry_index_for_biome_returns_first_of_shared_biome() -> void:
	# Act 1's placeholder shape: two entries pointing at the same biome.
	var shared: ActData = ActData.new()
	var first_entry: ActBiomeEntry = ActBiomeEntry.new()
	first_entry.biome = _jungle_biome
	var second_entry: ActBiomeEntry = ActBiomeEntry.new()
	second_entry.biome = _jungle_biome
	var shared_entries: Array[ActBiomeEntry] = [first_entry, second_entry]
	shared.biome_entries = shared_entries
	assert_eq(shared.FindEntryIndexForBiome(_jungle_biome), 0,
		"Should return the first matching entry when multiple entries share a biome.")
