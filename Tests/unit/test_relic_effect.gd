extends GutTest

# Coverage for the Relic carrier (Documents/Plans/Plan_Relic_Implementation.md Phase 2): a
# Relic preset's effect resource instantiates per-equip at the wearer's rolled rarity, reading
# Relic_Design.md's five-step ladder off RelicEffect.Magnitude().

func test_all_relic_presets_are_registered_and_resolve() -> void:
	var relic_keys: Array[String] = EquipmentPresetRegistry.RELIC_PRESETS.keys()
	assert_eq(relic_keys.size(), 24, "Every catalog entry in Relic_Design.md should have a preset")
	for key in relic_keys:
		var preset: EquipmentPreset = EquipmentPresetRegistry.GetRelic(key)
		assert_not_null(preset, "Relic preset '%s' should resolve" % key)
		assert_eq(preset._item_type, Types.Item_Type.Relic, "Relic preset '%s' should carry the Relic item type" % key)
		assert_not_null(preset._relic_effect, "Relic preset '%s' should carry an effect resource" % key)

func test_get_random_relic_key_returns_a_registered_key() -> void:
	var key: String = EquipmentPresetRegistry.GetRandomRelicKey()
	assert_true(EquipmentPresetRegistry.RELIC_PRESETS.has(key), "The random key should be one of the registered Relic presets")

func test_get_random_relic_key_for_slot_only_returns_that_slot() -> void:
	for slot in [Types.Slot.Weapon, Types.Slot.OffHand, Types.Slot.Boots]:
		for i in range(20):
			var key: String = EquipmentPresetRegistry.GetRandomRelicKeyForSlot(slot)
			assert_false(key.is_empty(), "The catalog carries at least one Relic per live slot")
			assert_eq(EquipmentPresetRegistry.GetRelic(key)._slot, slot,
				"GetRandomRelicKeyForSlot should never cross slots")

func test_get_random_relic_key_for_slot_returns_empty_for_a_slot_with_no_relics() -> void:
	var key: String = EquipmentPresetRegistry.GetRandomRelicKeyForSlot(Types.Slot.Helmet)
	assert_eq(key, "", "A slot the Relic catalog never targets should return an empty key")

func test_relic_effect_instantiates_at_equipping_rarity() -> void:
	var preset: EquipmentPreset = EquipmentPresetRegistry.GetRelic("The_Long_Furrow").duplicate(true)
	preset._rarity = Types.Rarity.Legendary

	var equipment: Equipment = Equipment.new()
	equipment.InstantiateNew(preset, 0)

	assert_not_null(equipment._relic_effect, "Equipping a Relic preset should carry its effect onto the Equipment instance")
	assert_almost_eq(equipment._relic_effect.Magnitude(), 0.55, 0.0001,
		"The Long Furrow's Legendary step should be 55%, per Relic_Design.md")
	equipment.free()

func test_relic_effect_ladder_scales_with_rarity() -> void:
	var preset: EquipmentPreset = EquipmentPresetRegistry.GetRelic("The_Long_Furrow").duplicate(true)

	for rarity_and_expected in [
		[Types.Rarity.Common, 0.25],
		[Types.Rarity.Uncommon, 0.30],
		[Types.Rarity.Rare, 0.35],
		[Types.Rarity.Epic, 0.45],
		[Types.Rarity.Legendary, 0.55],
	]:
		preset._rarity = rarity_and_expected[0]
		var equipment: Equipment = Equipment.new()
		equipment.InstantiateNew(preset, 0)
		assert_almost_eq(equipment._relic_effect.Magnitude(), rarity_and_expected[1], 0.0001,
			"Rarity %s should read the matching ladder step" % Types.RarityName(rarity_and_expected[0]))
		equipment.free()

func test_relic_effect_instances_are_independent_per_equipment() -> void:
	var preset: EquipmentPreset = EquipmentPresetRegistry.GetRelic("The_Long_Furrow")

	var equipment_a: Equipment = Equipment.new()
	var preset_a: EquipmentPreset = preset.duplicate(true)
	preset_a._rarity = Types.Rarity.Common
	equipment_a.InstantiateNew(preset_a, 0)

	var equipment_b: Equipment = Equipment.new()
	var preset_b: EquipmentPreset = preset.duplicate(true)
	preset_b._rarity = Types.Rarity.Legendary
	equipment_b.InstantiateNew(preset_b, 1)

	assert_almost_eq(equipment_a._relic_effect.Magnitude(), 0.25, 0.0001, "First instance should keep its own rarity step")
	assert_almost_eq(equipment_b._relic_effect.Magnitude(), 0.55, 0.0001, "Second instance should keep its own rarity step")
	equipment_a.free()
	equipment_b.free()

func test_relic_preset_setup_rolls_half_attributes() -> void:
	var preset: EquipmentPreset = EquipmentPresetRegistry.GetRelic("Kiln_Brand").duplicate(true)
	preset._rarity = Types.Rarity.Epic
	preset.Setup()

	var total: int = 0
	for attribute in preset._attributes.keys():
		total += preset._attributes[attribute]
	var expected_per_step: int = ceili(Game_Balance.ITEM_ATTRIBUTE_PER_RARITY / 2.0)
	assert_eq(total, int(Types.Rarity.Epic) * expected_per_step,
		"A Relic preset rolled through the registry should still gain the halved per-step attribute total")
