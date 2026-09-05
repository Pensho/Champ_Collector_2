extends GutTest

func test_payout_matches_tables_at_level_zero() -> void:
	var payout: Dictionary = LootManager.GetReleaseValue(Types.Rarity.Rare, 0)
	assert_eq(payout["silver"], GameBalance.RELEASE_SILVER_PER_RARITY[Types.Rarity.Rare],
			"With no level scaling, Silver should equal the flat rarity table value")
	assert_eq(payout["supplies"], GameBalance.RELEASE_SUPPLIES_PER_RARITY[Types.Rarity.Rare],
			"Supplies should be flat per rarity, unaffected by level")
	assert_eq(payout["tallies"], GameBalance.TALLY_VALUE_PER_RARITY[Types.Rarity.Rare],
			"Tallies should be flat per rarity, unaffected by level")

func test_silver_scales_with_level() -> void:
	var base: int = GameBalance.RELEASE_SILVER_PER_RARITY[Types.Rarity.Epic]
	var payout: Dictionary = LootManager.GetReleaseValue(Types.Rarity.Epic, 25)
	assert_eq(payout["silver"], base * 2, "Level 25 should double the Silver payout (×(1 + level/25))")

func test_supplies_and_tallies_do_not_scale_with_level() -> void:
	var low_level: Dictionary = LootManager.GetReleaseValue(Types.Rarity.Legendary, 1)
	var high_level: Dictionary = LootManager.GetReleaseValue(Types.Rarity.Legendary, 50)
	assert_eq(low_level["supplies"], high_level["supplies"], "Supplies payout should not depend on level")
	assert_eq(low_level["tallies"], high_level["tallies"], "Tallies payout should not depend on level")

func test_payout_increases_with_rarity() -> void:
	var uncommon: Dictionary = LootManager.GetReleaseValue(Types.Rarity.Uncommon, 1)
	var legendary: Dictionary = LootManager.GetReleaseValue(Types.Rarity.Legendary, 1)
	assert_true(legendary["silver"] > uncommon["silver"], "Legendary should pay out more Silver than Uncommon")
	assert_true(legendary["supplies"] > uncommon["supplies"], "Legendary should pay out more Supplies than Uncommon")
	assert_true(legendary["tallies"] > uncommon["tallies"], "Legendary should pay out more Tallies than Uncommon")
