extends GutTest

func test_upgrade_increments_level_and_gain() -> void:
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Boots
	eq._rarity = Types.Rarity.Rare
	eq._attributes[Types.Attribute.Speed] = 10

	eq.Upgrade()

	assert_eq(eq._level, 1, "Level should increment by 1")
	assert_eq(eq._attributes[Types.Attribute.Speed], 10 + (3 + int(Types.Rarity.Rare)), "Gain should equal 3 + rarity")
	eq.free()

func test_can_upgrade_false_at_max_level() -> void:
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Boots
	eq._rarity = Types.Rarity.Common
	eq._level = GameBalance.MAX_ITEM_LEVEL

	assert_false(eq.CanUpgrade(), "Item at max level should not be upgradeable")
	eq.free()

func test_upgrade_only_chooses_attributes_item_holds() -> void:
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Boots
	eq._rarity = Types.Rarity.Common
	eq._attributes[Types.Attribute.Speed] = 5

	for i in range(10):
		eq.Upgrade()

	for attribute in eq._attributes.keys():
		if(Types.Attribute.Speed != attribute):
			assert_eq(eq._attributes[attribute], 0, "Only the held attribute should ever gain value")
	eq.free()

func test_upgrade_falls_back_to_slot_pool_when_no_nonzero_attributes() -> void:
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Boots
	eq._rarity = Types.Rarity.Relic

	eq.Upgrade()

	var total: int = 0
	for attribute in eq._attributes.keys():
		total += eq._attributes[attribute]
	assert_eq(total, 3 + int(Types.Rarity.Relic), "Fallback upgrade should add gain to one slot-pool attribute")
	eq.free()
