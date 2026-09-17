extends GutTest

func _make_pool(p_reagent_families: Array[String], p_relic_keys: Array[String]) -> ContentPool:
	var pool: ContentPool = ContentPool.new()
	pool.reagent_families = p_reagent_families
	pool.relic_keys = p_relic_keys
	return pool

func test_allows_reagent_matches_the_family_across_rarities() -> void:
	var pool: ContentPool = _make_pool(["Mending_Icon"], [])
	assert_true(pool.AllowsReagent("Mending_Icon_Uncommon", Types.Rarity.Uncommon))
	assert_true(pool.AllowsReagent("Mending_Icon_Legendary", Types.Rarity.Legendary))
	assert_false(pool.AllowsReagent("Sigil_Speed_Uncommon", Types.Rarity.Uncommon))

func test_allows_relic_matches_listed_keys_only() -> void:
	var pool: ContentPool = _make_pool([], ["Kiln_Brand"])
	assert_true(pool.AllowsRelic("Kiln_Brand"))
	assert_false(pool.AllowsRelic("Quorum_Bell"))

func test_no_pool_is_active_without_the_playtest_feature_tag() -> void:
	assert_false(OS.has_feature(ContentPool.PLAYTEST_FEATURE_TAG), "The test run must not carry the playtest tag")
	assert_null(ContentPool.Active(), "Without the playtest tag random draws should be unrestricted")

func test_playtest_pool_names_only_registered_content() -> void:
	var pool: ContentPool = load(ContentPool.PLAYTEST_POOL_PATH)
	for relic_key in pool.relic_keys:
		assert_true(EquipmentPresetRegistry.RELIC_PRESETS.has(relic_key), "Unregistered Relic: %s" % relic_key)
	for family in pool.reagent_families:
		assert_true(ReagentRegistry.REAGENTS.has(family + "_Uncommon"), "Unregistered reagent family: %s" % family)

func test_random_reagent_draw_only_returns_allowed_families() -> void:
	var pool: ContentPool = _make_pool(["Mending_Icon", "Thiefs_Regret"], [])
	for i in 30:
		var key: String = ReagentRegistry.GetRandomKeyForRarity(Types.Rarity.Rare, pool)
		assert_true(key in ["Mending_Icon_Rare", "Thiefs_Regret_Rare"], "Disallowed reagent drawn: %s" % key)

func test_random_reagent_draw_is_empty_when_the_pool_allows_nothing() -> void:
	assert_eq(ReagentRegistry.GetRandomKeyForRarity(Types.Rarity.Rare, _make_pool([], [])), "")

func test_random_relic_draws_only_return_allowed_keys() -> void:
	var pool: ContentPool = _make_pool([], ["Kiln_Brand", "Mercy_Stitch"])
	for i in 30:
		var key: String = EquipmentPresetRegistry.GetRandomRelicKey(pool)
		assert_true(key in ["Kiln_Brand", "Mercy_Stitch"], "Disallowed Relic drawn: %s" % key)
	for i in 10:
		assert_eq(EquipmentPresetRegistry.GetRandomRelicKeyForSlot(Types.Slot.Weapon, pool), "Kiln_Brand")

func test_random_relic_draw_for_slot_is_empty_when_the_pool_has_none_for_it() -> void:
	var pool: ContentPool = _make_pool([], ["Kiln_Brand"])
	assert_eq(EquipmentPresetRegistry.GetRandomRelicKeyForSlot(Types.Slot.Boots, pool), "")

func test_tier_offers_its_full_list_without_a_pool() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Bone_Tier.tres")
	assert_eq(tier.RecruitableChampions(null), tier.recruitable_champions)

func test_tier_offers_only_champions_the_pool_also_lists() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Bone_Tier.tres")
	var pool: ContentPool = ContentPool.new()
	pool.recruitable_champions = [load("res://Data/Character_Player_Variants/Thief.tres"),
		load("res://Data/Character_Player_Variants/Centaur_Lancer.tres")]
	var offered: Array[CharacterPreset] = tier.RecruitableChampions(pool)
	assert_eq(offered.size(), 1, "A pool champion the tier does not list must not be added to the tier")
	assert_eq(offered[0]._name, "Thief")

func test_playtest_pool_recruits_and_starts_with_champions_every_tier_can_offer() -> void:
	var pool: ContentPool = load(ContentPool.PLAYTEST_POOL_PATH)
	assert_eq(pool.starting_champions.size(), 3)
	for tier_path in ["res://Data/Recruitment/Bone_Tier.tres", "res://Data/Recruitment/Brass_Tier.tres",
			"res://Data/Recruitment/Parchment_Tier.tres"]:
		var tier: FortuneFavorTier = load(tier_path)
		assert_eq(tier.RecruitableChampions(pool).size(), pool.recruitable_champions.size(),
			"%s should list every playtest champion" % tier_path)
