extends GutTest

func _make_pool(p_reagent_families: Array[String], p_relic_keys: Array[String]) -> ContentPool:
	var pool: ContentPool = ContentPool.new()
	pool.reagent_families = p_reagent_families
	pool.relic_keys = p_relic_keys
	return pool

func _default_mode_name() -> String:
	return GameModeRegistry.DefaultPool().mode_name

func _non_default_mode_name() -> String:
	for pool: ContentPool in GameModeRegistry.POOLS:
		if(not pool.is_default_mode):
			return pool.mode_name
	return ""

func _restore_selection(p_launch_value: String, p_launch_setting: Variant) -> void:
	ProjectSettings.set_setting(GameModeRegistry.BUILD_MODE_SETTING, p_launch_setting)
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, p_launch_value)

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
	GameModeRegistry.PinForTest(pool)
	assert_eq(GameModeRegistry.Active(), pool, "A test pin should override the launch environment")
	GameModeRegistry.ClearPin()
	assert_eq(GameModeRegistry.Active(), GameModeRegistry._PoolForMode(GameModeRegistry.ResolveModeName()),
			"Clearing the pin should restore the run's own build mode")

func test_environment_variable_selects_the_named_mode() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, _non_default_mode_name())
	assert_eq(GameModeRegistry.ResolveModeName(), _non_default_mode_name())
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, _default_mode_name())
	assert_eq(GameModeRegistry.ResolveModeName(), _default_mode_name(),
			"The environment variable must be able to force the default mode")
	_restore_selection(launch_value, launch_setting)

func test_unknown_mode_name_falls_back_to_the_default_mode() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, "typo_mode")
	assert_eq(GameModeRegistry.ResolveModeName(), _default_mode_name())
	assert_eq(GameModeRegistry.Active(), GameModeRegistry.DefaultPool())
	_restore_selection(launch_value, launch_setting)

func test_project_setting_selects_the_mode_when_no_environment_variable_is_set() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, "")
	ProjectSettings.set_setting(GameModeRegistry.BUILD_MODE_SETTING, _non_default_mode_name())
	assert_eq(GameModeRegistry.ResolveModeName(), _non_default_mode_name())
	ProjectSettings.set_setting(GameModeRegistry.BUILD_MODE_SETTING, _default_mode_name())
	assert_eq(GameModeRegistry.ResolveModeName(), _default_mode_name())
	_restore_selection(launch_value, launch_setting)

func test_environment_variable_outranks_the_project_setting() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	ProjectSettings.set_setting(GameModeRegistry.BUILD_MODE_SETTING, _non_default_mode_name())
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, _default_mode_name())
	assert_eq(GameModeRegistry.ResolveModeName(), _default_mode_name(),
			"A test run naming its mode must not be redirected by the project setting")
	_restore_selection(launch_value, launch_setting)

func test_empty_sources_run_the_default_mode() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, "")
	ProjectSettings.set_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	assert_eq(GameModeRegistry.ResolveModeName(), _default_mode_name(),
			"An empty environment variable and setting must run the default mode")
	_restore_selection(launch_value, launch_setting)

func test_a_feature_tag_never_selects_a_mode() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, "")
	ProjectSettings.set_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	# OS.has_feature() has been observed returning true for a mode name no export preset
	# declares, which silently selected that mode. Only the two text sources may select one.
	assert_eq(GameModeRegistry.ResolveModeName(), _default_mode_name(),
			"Mode selection must not depend on OS.has_feature()")
	_restore_selection(launch_value, launch_setting)

func test_active_is_never_null() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	for mode_name: String in [_default_mode_name(), _non_default_mode_name(), "", "typo_mode"]:
		OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, mode_name)
		assert_not_null(GameModeRegistry.Active(), "Active() returned null for mode '%s'" % mode_name)
	_restore_selection(launch_value, launch_setting)

func test_every_registered_pool_declares_a_unique_mode_name() -> void:
	var seen_names: Array[String] = []
	for pool: ContentPool in GameModeRegistry.POOLS:
		assert_false(pool.mode_name.is_empty(), "%s declares no mode name" % pool.resource_path)
		assert_false(seen_names.has(pool.mode_name), "Duplicate mode name: %s" % pool.mode_name)
		seen_names.append(pool.mode_name)

func test_exactly_one_pool_is_the_default() -> void:
	var default_pools: Array[String] = []
	for pool: ContentPool in GameModeRegistry.POOLS:
		if(pool.is_default_mode):
			default_pools.append(pool.mode_name)
	assert_eq(default_pools.size(), 1, "Exactly one mode must be the default, found: %s" % ", ".join(default_pools))

func test_active_loads_the_pool_of_the_mode_the_environment_names() -> void:
	var launch_value: String = OS.get_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE)
	var launch_setting: Variant = ProjectSettings.get_setting(GameModeRegistry.BUILD_MODE_SETTING, "")
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, _non_default_mode_name())
	assert_eq(GameModeRegistry.Active().mode_name, _non_default_mode_name())
	OS.set_environment(GameModeRegistry.BUILD_MODE_ENVIRONMENT_VARIABLE, _default_mode_name())
	assert_eq(GameModeRegistry.Active(), GameModeRegistry.DefaultPool())
	_restore_selection(launch_value, launch_setting)

func test_starting_reagent_candidates_exclude_disallowed_and_brew_only_reagents() -> void:
	var pool: ContentPool = _make_pool(["Mending_Icon", "Thiefs_Regret"], [])
	var candidate_keys: Array[String] = Main_Instance.StartingReagentCandidates(pool)
	assert_gt(candidate_keys.size(), 0, "Sanity check: the pool should allow at least one drawable reagent")
	for reagent_key: String in candidate_keys:
		var reagent: ReagentData = ReagentRegistry.REAGENTS[reagent_key]
		assert_false(reagent.brew_only, "Brew-only reagent offered: %s" % reagent_key)
		assert_true(pool.AllowsReagent(reagent_key, reagent.rarity), "Disallowed reagent offered: %s" % reagent_key)

func test_starting_reagent_roll_draws_its_count_from_the_candidates() -> void:
	var pool: ContentPool = _make_pool(["Mending_Icon"], [])
	pool.starting_reagent_count = 5
	var drawn_keys: Array[String] = pool.RollStartingReagentKeys(["Mending_Icon_Rare", "Mending_Icon_Epic"])
	assert_eq(drawn_keys.size(), 5)
	for reagent_key: String in drawn_keys:
		assert_true(reagent_key in ["Mending_Icon_Rare", "Mending_Icon_Epic"], "Unexpected draw: %s" % reagent_key)

func test_starting_reagent_roll_is_empty_at_zero() -> void:
	var pool: ContentPool = _make_pool(["Mending_Icon"], [])
	pool.starting_reagent_count = 0
	assert_eq(pool.RollStartingReagentKeys(["Mending_Icon_Rare"]).size(), 0)

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

func test_tier_offers_its_full_list_under_the_default_pool() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Bone_Tier.tres")
	assert_eq(tier.RecruitableChampions(GameModeRegistry.DefaultPool()), tier.recruitable_champions,
			"The default pool must offer every champion its tiers list")

func test_tier_offers_only_champions_the_pool_also_lists() -> void:
	var tier: FortuneFavorTier = load("res://Data/Recruitment/Bone_Tier.tres")
	var pool: ContentPool = ContentPool.new()
	pool.recruitable_champions = [load("res://Data/Character_Player_Variants/Thief.tres"),
		load("res://Data/Character_Player_Variants/Centaur_Lancer.tres")]
	var offered: Array[CharacterPreset] = tier.RecruitableChampions(pool)
	assert_eq(offered.size(), 1, "A pool champion the tier does not list must not be added to the tier")
	assert_eq(offered[0]._name, "Thief")
