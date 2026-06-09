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
