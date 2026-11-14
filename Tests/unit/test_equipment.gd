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

func test_every_standard_preset_has_a_sub_type_of_its_own_slot() -> void:
	for key in EquipmentPresetRegistry.PRESETS:
		var preset: EquipmentPreset = EquipmentPresetRegistry.PRESETS[key]
		assert_not_null(preset._sub_type, "%s should have a sub-type" % key)
		if(null != preset._sub_type):
			assert_eq(preset._sub_type._slot, preset._slot,
				"%s's sub-type should share its slot" % key)

func test_no_relic_preset_has_a_sub_type() -> void:
	for key in EquipmentPresetRegistry.RELIC_PRESETS:
		assert_null(EquipmentPresetRegistry.RELIC_PRESETS[key]._sub_type,
			"Relic %s should have no sub-type" % key)

func _sub_typed_item(p_implicit: Types.Attribute, p_rarity: Types.Rarity) -> Equipment:
	var implicit: AttributeImplicit = AttributeImplicit.new()
	implicit._attribute = p_implicit
	implicit._base_value = 6
	var sub_type: ItemSubType = ItemSubType.new()
	sub_type._slot = Types.Slot.Weapon
	sub_type._implicit = implicit
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Weapon
	eq._rarity = p_rarity
	eq._sub_type = sub_type
	return eq

func test_implicit_is_sized_by_rarity() -> void:
	var common: Equipment = _sub_typed_item(Types.Attribute.Attack, Types.Rarity.Common)
	var legendary: Equipment = _sub_typed_item(Types.Attribute.Attack, Types.Rarity.Legendary)
	assert_eq(common.GetImplicitBonus(Types.Attribute.Attack), 6, "Common uses the base value")
	assert_eq(legendary.GetImplicitBonus(Types.Attribute.Attack),
		roundi(6 * GameBalance.ITEM_IMPLICIT_RARITY_MULTIPLIER[4]), "Rarity scales the base value")
	assert_eq(common.GetImplicitBonus(Types.Attribute.Mysticism), 0,
		"The implicit applies only to its own attribute")
	common.free()
	legendary.free()

func test_upgrades_leave_the_implicit_unchanged() -> void:
	var eq: Equipment = _sub_typed_item(Types.Attribute.Attack, Types.Rarity.Rare)
	eq._attributes[Types.Attribute.CritChance] = 5
	var before: int = eq.GetImplicitBonus(Types.Attribute.Attack)
	for i in range(GameBalance.MAX_ITEM_LEVEL):
		eq.Upgrade()
	assert_eq(eq.GetImplicitBonus(Types.Attribute.Attack), before, "Upgrades never grow the implicit")
	assert_eq(eq._attributes[Types.Attribute.Attack], 0,
		"Upgrades only grow rolled attributes, never write the implicit into them")
	eq.free()

func test_relic_has_no_implicit() -> void:
	var eq: Equipment = _sub_typed_item(Types.Attribute.Attack, Types.Rarity.Rare)
	eq._item_type = Types.Item_Type.Relic
	assert_eq(eq.GetImplicitBonus(Types.Attribute.Attack), 0, "A Relic grants no implicit")
	eq._sub_type = null
	eq._item_type = Types.Item_Type.Standard
	assert_eq(eq.GetImplicitBonus(Types.Attribute.Attack), 0, "An item without a sub-type grants no implicit")
	eq.free()

func test_base_implicit_grants_no_attribute() -> void:
	var sub_type: ItemSubType = ItemSubType.new()
	sub_type._implicit = ItemImplicit.new()
	var eq: Equipment = Equipment.new()
	eq._rarity = Types.Rarity.Legendary
	eq._sub_type = sub_type
	for attribute in Types.Attribute.values():
		assert_eq(eq.GetImplicitBonus(attribute), 0, "A non-attribute implicit adds no attribute")
	eq.free()

func test_instantiated_item_carries_its_preset_sub_type() -> void:
	var preset: EquipmentPreset = EquipmentPresetRegistry.Get("Briar_Staff").duplicate(true)
	preset._rarity = Types.Rarity.Uncommon
	preset.Setup()
	var eq: Equipment = Equipment.new()
	eq.InstantiateNew(preset, 0)
	assert_not_null(eq._sub_type)
	var implicit: AttributeImplicit = preset._sub_type._implicit
	assert_eq(eq.GetImplicitBonus(Types.Attribute.Attack), implicit.Value(Types.Rarity.Uncommon))
	eq.free()

func test_item_text_shows_the_implicit_only_for_a_standard_item() -> void:
	var eq: Equipment = _sub_typed_item(Types.Attribute.Attack, Types.Rarity.Epic)
	assert_eq(eq.GetItemText().implicit, "Attack +%d" % roundi(6 * GameBalance.ITEM_IMPLICIT_RARITY_MULTIPLIER[3]))
	eq._item_type = Types.Item_Type.Relic
	assert_eq(eq.GetItemText().implicit, "", "A Relic shows no implicit line")
	eq.free()

func test_item_text_splits_type_and_signed_attributes() -> void:
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Speed: -3, Types.Attribute.Attack: 5}
	var standard: ItemText = ItemText.Build(Types.Slot.Weapon, Types.Item_Type.Standard, Types.Rarity.Common, attributes)
	assert_eq(standard.subtitle, "Weapon")
	assert_string_contains(standard.body, "Speed -3")
	assert_false(standard.body.contains("--"), "A negative attribute shows a single minus")
	var relic: ItemText = ItemText.Build(Types.Slot.Weapon, Types.Item_Type.Relic, Types.Rarity.Common, attributes)
	assert_eq(relic.subtitle, "Relic Weapon")
