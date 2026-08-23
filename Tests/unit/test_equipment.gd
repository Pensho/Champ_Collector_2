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
	eq._rarity = Types.Rarity.Epic

	eq.Upgrade()

	var total: int = 0
	for attribute in eq._attributes.keys():
		total += eq._attributes[attribute]
	assert_eq(total, 3 + int(Types.Rarity.Epic), "Fallback upgrade should add gain to one slot-pool attribute")
	eq.free()

func test_relic_upgrade_gain_is_half_standard_rounded_up() -> void:
	var standard_gain: int = Equipment.UpgradeAttributeGain(Types.Rarity.Rare, Types.Item_Type.Standard)
	var relic_gain: int = Equipment.UpgradeAttributeGain(Types.Rarity.Rare, Types.Item_Type.Relic)
	assert_eq(relic_gain, ceili(standard_gain / 2.0), "A Relic's upgrade gain should be the standard gain halved and rounded up")

func test_relic_setup_gain_is_half_standard_rounded_up() -> void:
	var standard_gain: int = Equipment.SetupAttributeGain(Types.Item_Type.Standard)
	var relic_gain: int = Equipment.SetupAttributeGain(Types.Item_Type.Relic)
	assert_eq(relic_gain, ceili(standard_gain / 2.0), "A Relic's setup gain should be the standard gain halved and rounded up")

func test_relic_equipment_upgrade_uses_halved_gain() -> void:
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Boots
	eq._rarity = Types.Rarity.Rare
	eq._item_type = Types.Item_Type.Relic
	eq._attributes[Types.Attribute.Speed] = 10

	eq.Upgrade()

	var expected_gain: int = ceili((Game_Balance.ITEM_UPGRADE_FLAT_BONUS + int(Types.Rarity.Rare)) / 2.0)
	assert_eq(eq._attributes[Types.Attribute.Speed], 10 + expected_gain, "A Relic's own Upgrade() should apply the halved gain")
	eq.free()

func test_relic_preset_setup_rolls_half_standard_attribute_total() -> void:
	var standard_preset: EquipmentPreset = EquipmentPreset.new()
	standard_preset._slot = Types.Slot.Boots
	standard_preset._rarity = Types.Rarity.Epic
	standard_preset.Setup()
	var standard_total: int = 0
	for attribute in standard_preset._attributes.keys():
		standard_total += standard_preset._attributes[attribute]

	var relic_preset: EquipmentPreset = EquipmentPreset.new()
	relic_preset._slot = Types.Slot.Boots
	relic_preset._rarity = Types.Rarity.Epic
	relic_preset._item_type = Types.Item_Type.Relic
	relic_preset.Setup()
	var relic_total: int = 0
	for attribute in relic_preset._attributes.keys():
		relic_total += relic_preset._attributes[attribute]

	var expected_per_step: int = ceili(Game_Balance.ITEM_ATTRIBUTE_PER_RARITY / 2.0)
	assert_eq(relic_total, int(Types.Rarity.Epic) * expected_per_step,
		"A Relic preset's setup roll should total half the standard per-step gain, rounded up, across every rarity step")
	assert_eq(standard_total, int(Types.Rarity.Epic) * Game_Balance.ITEM_ATTRIBUTE_PER_RARITY,
		"A Standard preset's setup roll should be unaffected by the split")
