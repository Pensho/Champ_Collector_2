extends GutTest

func test_spend_succeeds_when_enough_supplies() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._supplies = 50
	assert_true(rh.SpendSupplies(30), "Should succeed when supplies >= amount")
	assert_eq(rh._supplies, 20, "Supplies should decrease by the spent amount")
	rh.free()

func test_spend_succeeds_on_exact_amount() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._supplies = 30
	assert_true(rh.SpendSupplies(30), "Should succeed when spending exactly available supplies")
	assert_eq(rh._supplies, 0, "Supplies should reach zero after exact spend")
	rh.free()

func test_spend_fails_when_insufficient() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._supplies = 10
	assert_false(rh.SpendSupplies(30), "Should fail when supplies < amount")
	assert_eq(rh._supplies, 10, "Supplies should be unchanged on failure")
	rh.free()

func test_spend_zero_always_succeeds() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._supplies = 5
	assert_true(rh.SpendSupplies(0), "Spending zero should always succeed")
	assert_eq(rh._supplies, 5, "Supplies should be unchanged when spending zero")
	rh.free()

func test_spend_from_empty_fails() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._supplies = 0
	assert_false(rh.SpendSupplies(1), "Should fail when supplies are empty")
	assert_eq(rh._supplies, 0, "Supplies remain zero after failed spend")
	rh.free()

func test_supply_regen_partial_progress_preserves_remainder() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var result: Dictionary = ResourceHandler.ComputeSupplyRegen(0, now - 2100, now)
	assert_eq(result["supplies"], 30, "35 minutes elapsed should grant +30 supplies")
	assert_eq(result["last_unix"], (now - 2100) + 1800, "Anchor should advance by the consumed 30 minutes, preserving the 5 minute remainder")

func test_supply_regen_caps_at_max_and_resets_anchor() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var result: Dictionary = ResourceHandler.ComputeSupplyRegen(95, now - 2100, now)
	assert_eq(result["supplies"], GameBalance.MAX_SUPPLIES, "Supplies should be capped at MAX_SUPPLIES")
	assert_eq(result["last_unix"], now, "Anchor should reset to now once supplies are full")

func test_supply_regen_below_interval_is_unchanged() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var last: int = now - 300
	var result: Dictionary = ResourceHandler.ComputeSupplyRegen(50, last, now)
	assert_eq(result["supplies"], 50, "Less than one interval elapsed should not grant supplies")
	assert_eq(result["last_unix"], last, "Anchor should be unchanged when no increment has elapsed")

func test_supply_regen_already_full_advances_anchor_without_accrual() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var result: Dictionary = ResourceHandler.ComputeSupplyRegen(GameBalance.MAX_SUPPLIES, now - 2100, now)
	assert_eq(result["supplies"], GameBalance.MAX_SUPPLIES, "Supplies should remain at MAX_SUPPLIES")
	assert_eq(result["last_unix"], now, "Anchor should track now while full, with no accrual")

func test_supply_regen_fresh_anchor_is_set_to_now() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var result: Dictionary = ResourceHandler.ComputeSupplyRegen(20, 0, now)
	assert_eq(result["supplies"], 20, "Supplies should be unchanged on a fresh anchor")
	assert_eq(result["last_unix"], now, "Anchor should be initialized to now")

func test_fortunes_favor_spend_and_add_per_tier() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh.AddFortunesFavor(FortuneFavorTier.TierType.BONE, 3)
	rh.AddFortunesFavor(FortuneFavorTier.TierType.BRASS, 2)

	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.BONE), 3, "Bone balance should reflect added amount")
	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.BRASS), 2, "Brass balance should reflect added amount")
	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.PARCHMENT), 0, "Parchment balance should remain zero")

	assert_true(rh.SpendFortunesFavor(FortuneFavorTier.TierType.BONE, 3), "Should succeed spending exactly the Bone balance")
	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.BONE), 0, "Bone balance should be zero after spending")
	assert_false(rh.SpendFortunesFavor(FortuneFavorTier.TierType.BRASS, 3), "Should fail spending more Brass than available")
	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.BRASS), 2, "Brass balance should be unchanged on failed spend")
	rh.free()

func test_fortunes_favor_serialize_deserialize_round_trip() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh.AddFortunesFavor(FortuneFavorTier.TierType.BONE, 1)
	rh.AddFortunesFavor(FortuneFavorTier.TierType.BRASS, 2)
	rh.AddFortunesFavor(FortuneFavorTier.TierType.PARCHMENT, 3)

	var data: Dictionary = rh.Serialize()

	var rh2: ResourceHandler = ResourceHandler.new()
	rh2.Deserialize(data)

	assert_eq(rh2.GetFortunesFavor(FortuneFavorTier.TierType.BONE), 1, "Bone balance should round-trip")
	assert_eq(rh2.GetFortunesFavor(FortuneFavorTier.TierType.BRASS), 2, "Brass balance should round-trip")
	assert_eq(rh2.GetFortunesFavor(FortuneFavorTier.TierType.PARCHMENT), 3, "Parchment balance should round-trip")
	rh.free()
	rh2.free()

func test_fortunes_favor_deserialize_migrates_old_flat_key_into_bone() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh.Deserialize({"silver": 0, "supplies": 0, "fortunes_favor": 7})

	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.BONE), 7, "Old flat fortunes_favor value should migrate into Bone")
	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.BRASS), 0, "Brass should default to zero on migration")
	assert_eq(rh.GetFortunesFavor(FortuneFavorTier.TierType.PARCHMENT), 0, "Parchment should default to zero on migration")
	rh.free()

func test_spend_silver_succeeds_when_enough_silver() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._silver = 100
	assert_true(rh.SpendSilver(40), "Should succeed when silver >= amount")
	assert_eq(rh._silver, 60, "Silver should decrease by the spent amount")
	rh.free()

func test_spend_silver_fails_when_insufficient() -> void:
	var rh: ResourceHandler = ResourceHandler.new()
	rh._silver = 10
	assert_false(rh.SpendSilver(20), "Should fail when silver < amount")
	assert_eq(rh._silver, 10, "Silver should be unchanged on failure")
	rh.free()

func test_supply_regen_exact_multiple_has_no_remainder() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var last: int = now - 1200
	var result: Dictionary = ResourceHandler.ComputeSupplyRegen(0, last, now)
	assert_eq(result["supplies"], 20, "20 minutes elapsed should grant +20 supplies")
	assert_eq(result["last_unix"], last + 1200, "Anchor should advance exactly by the elapsed time with zero remainder")
