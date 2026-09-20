extends GutTest

# Loads every shipped ContentPool resource and asserts it is usable — a future build
# mode is covered by adding its content pool resource under Data/Game_Modes/, not by
# adding a test.

const GAME_MODE_ROOT: String = "res://Data/Game_Modes"
const CHAMPION_PRESET_ROOT: String = "res://Data/Character_Player_Variants"
const TIER_PATHS: Array[String] = [
	"res://Data/Recruitment/Bone_Tier.tres",
	"res://Data/Recruitment/Brass_Tier.tres",
	"res://Data/Recruitment/Parchment_Tier.tres",
]

func test_every_shipped_pool_is_registered() -> void:
	var registered_paths: Array[String] = []
	for pool: ContentPool in GameModeRegistry.POOLS:
		registered_paths.append(pool.resource_path)
	var shipped_paths: Array[String] = []
	for pool in _CollectContentPools():
		shipped_paths.append(pool.resource_path)
	for path in shipped_paths:
		assert_true(registered_paths.has(path),
				"%s is not registered in GameModeRegistry.POOLS" % path)
	for path in registered_paths:
		assert_true(shipped_paths.has(path),
				"GameModeRegistry.POOLS registers %s, which is not under %s" % [path, GAME_MODE_ROOT])

func test_the_default_pool_lists_every_registered_reagent_family() -> void:
	var default_pool: ContentPool = GameModeRegistry.DefaultPool()
	for reagent_key: String in ReagentRegistry.REAGENTS.keys():
		var reagent: ReagentData = ReagentRegistry.REAGENTS[reagent_key]
		assert_true(default_pool.AllowsReagent(reagent_key, reagent.rarity),
				"The default pool omits reagent %s" % reagent_key)

func test_the_default_pool_lists_every_registered_relic() -> void:
	var default_pool: ContentPool = GameModeRegistry.DefaultPool()
	for relic_key: String in EquipmentPresetRegistry.RELIC_PRESETS.keys():
		assert_true(default_pool.AllowsRelic(relic_key), "The default pool omits Relic %s" % relic_key)

func test_the_default_pool_lists_every_champion_preset() -> void:
	var default_pool: ContentPool = GameModeRegistry.DefaultPool()
	var paths: Array[String] = []
	_CollectTresPaths(CHAMPION_PRESET_ROOT, paths)
	assert_gt(paths.size(), 0, "Sanity check: the champion preset scan should find at least one preset")
	for path in paths:
		var preset: CharacterPreset = load(path)
		assert_true(default_pool.AllowsChampion(preset), "The default pool omits champion %s" % path)

func test_every_content_pool_names_only_registered_content() -> void:
	var pools: Array[ContentPool] = _CollectContentPools()
	assert_gt(pools.size(), 0, "Sanity check: the game mode directory scan should find at least one ContentPool")
	for pool in pools:
		for relic_key in pool.relic_keys:
			assert_true(EquipmentPresetRegistry.RELIC_PRESETS.has(relic_key),
					"%s: unregistered Relic %s" % [pool.resource_path, relic_key])
		for family in pool.reagent_families:
			assert_true(_IsRegisteredReagentFamily(family),
					"%s: unregistered reagent family %s" % [pool.resource_path, family])

func test_every_content_pool_starting_roster_fits_the_roster_cap() -> void:
	var pools: Array[ContentPool] = _CollectContentPools()
	assert_gt(pools.size(), 0, "Sanity check: the game mode directory scan should find at least one ContentPool")
	for pool in pools:
		assert_true(pool.starting_champions.size() <= GameBalance.COLLECTION_START_ROSTER_SIZE,
				"%s: starting roster (%d) exceeds the roster cap (%d)" %
				[pool.resource_path, pool.starting_champions.size(), GameBalance.COLLECTION_START_ROSTER_SIZE])

func test_every_content_pool_lets_every_tier_offer_a_champion() -> void:
	var pools: Array[ContentPool] = _CollectContentPools()
	assert_gt(pools.size(), 0, "Sanity check: the game mode directory scan should find at least one ContentPool")
	for pool in pools:
		for tier_path in TIER_PATHS:
			var tier: FortuneFavorTier = load(tier_path)
			assert_gt(tier.RecruitableChampions(pool).size(), 0,
					"%s: %s has no offerable champion under this pool" % [pool.resource_path, tier_path])

## A family is registered when a reagent key is the family itself (the Alchemist brews,
## which carry no rarity suffix) or the family plus a rarity suffix.
func _IsRegisteredReagentFamily(p_family: String) -> bool:
	for reagent_key: String in ReagentRegistry.REAGENTS.keys():
		if(reagent_key == p_family or reagent_key.begins_with(p_family + "_")):
			return true
	return false

func _CollectContentPools() -> Array[ContentPool]:
	var pools: Array[ContentPool] = []
	var paths: Array[String] = []
	_CollectTresPaths(GAME_MODE_ROOT, paths)
	for path in paths:
		var resource: Resource = load(path)
		if resource is ContentPool:
			pools.append(resource)
	return pools

func _CollectTresPaths(p_dir_path: String, p_out: Array[String]) -> void:
	var dir := DirAccess.open(p_dir_path)
	assert_not_null(dir, "Could not open directory: " + p_dir_path)
	if null == dir:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while "" != entry:
		if not entry.begins_with("."):
			var full_path: String = "%s/%s" % [p_dir_path, entry]
			if dir.current_is_dir():
				_CollectTresPaths(full_path, p_out)
			elif entry.ends_with(".tres"):
				p_out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
