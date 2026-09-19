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

func test_pin_overrides_the_launch_environment() -> void:
	var pool: ContentPool = _make_pool(["Mending_Icon"], [])
	ContentPool.PinForTest(pool)
	assert_eq(ContentPool.Active(), pool, "A test pin should override the launch environment")
	ContentPool.PinForTest(null)
	assert_null(ContentPool.Active(), "Pinning null should force the unrestricted mode")
	ContentPool.ClearPin()

func test_environment_variable_selects_the_named_mode() -> void:
	var launch_value: String = OS.get_environment(ContentPool.BUILD_MODE_ENV_VAR)
	OS.set_environment(ContentPool.BUILD_MODE_ENV_VAR, ContentPool.PLAYTEST_FEATURE_TAG)
	assert_true(ContentPool._IsPlaytestMode())
	OS.set_environment(ContentPool.BUILD_MODE_ENV_VAR, "other_mode")
	assert_eq(ContentPool._IsPlaytestMode(), OS.has_feature(ContentPool.PLAYTEST_FEATURE_TAG),
			"An unmatched environment variable must not override the feature tag")
	OS.set_environment(ContentPool.BUILD_MODE_ENV_VAR, launch_value)

func test_active_matches_the_feature_tag_without_a_pin_or_environment_variable() -> void:
	var launch_value: String = OS.get_environment(ContentPool.BUILD_MODE_ENV_VAR)
	OS.set_environment(ContentPool.BUILD_MODE_ENV_VAR, "")
	assert_eq(null != ContentPool.Active(), OS.has_feature(ContentPool.PLAYTEST_FEATURE_TAG),
			"With no pin or environment variable, Active() should follow the feature tag alone")
	OS.set_environment(ContentPool.BUILD_MODE_ENV_VAR, launch_value)

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
