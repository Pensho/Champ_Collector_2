extends GutTest

# Loads every shipped ContentPool resource and asserts it is usable — a future build
# mode is covered by adding its content pool resource under Data/Loot_Tables/, not by
# adding a test.

const LOOT_TABLE_ROOT: String = "res://Data/Loot_Tables"
const TIER_PATHS: Array[String] = [
	"res://Data/Recruitment/Bone_Tier.tres",
	"res://Data/Recruitment/Brass_Tier.tres",
	"res://Data/Recruitment/Parchment_Tier.tres",
]

func test_every_content_pool_names_only_registered_content() -> void:
	var pools: Array[ContentPool] = _CollectContentPools()
	assert_gt(pools.size(), 0, "Sanity check: the loot table directory scan should find at least one ContentPool")
	for pool in pools:
		for relic_key in pool.relic_keys:
			assert_true(EquipmentPresetRegistry.RELIC_PRESETS.has(relic_key),
					"%s: unregistered Relic %s" % [pool.resource_path, relic_key])
		for family in pool.reagent_families:
			assert_true(ReagentRegistry.REAGENTS.has(family + "_Uncommon"),
					"%s: unregistered reagent family %s" % [pool.resource_path, family])

func test_every_content_pool_starting_roster_fits_the_roster_cap() -> void:
	var pools: Array[ContentPool] = _CollectContentPools()
	assert_gt(pools.size(), 0, "Sanity check: the loot table directory scan should find at least one ContentPool")
	for pool in pools:
		assert_true(pool.starting_champions.size() <= GameBalance.COLLECTION_START_ROSTER_SIZE,
				"%s: starting roster (%d) exceeds the roster cap (%d)" %
				[pool.resource_path, pool.starting_champions.size(), GameBalance.COLLECTION_START_ROSTER_SIZE])

func test_every_content_pool_lets_every_tier_offer_a_champion() -> void:
	var pools: Array[ContentPool] = _CollectContentPools()
	assert_gt(pools.size(), 0, "Sanity check: the loot table directory scan should find at least one ContentPool")
	for pool in pools:
		for tier_path in TIER_PATHS:
			var tier: FortuneFavorTier = load(tier_path)
			assert_gt(tier.RecruitableChampions(pool).size(), 0,
					"%s: %s has no offerable champion under this pool" % [pool.resource_path, tier_path])

func _CollectContentPools() -> Array[ContentPool]:
	var pools: Array[ContentPool] = []
	var paths: Array[String] = []
	_CollectTresPaths(LOOT_TABLE_ROOT, paths)
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
