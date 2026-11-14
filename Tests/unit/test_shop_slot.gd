extends GutTest

func test_standard_gear_entry_resolves_from_the_standard_presets() -> void:
	var entry: Dictionary = {
		"payload": "Scaled_Greaves",
		"item_type": Types.Item_Type.Standard,
	}

	assert_eq(ShopSlot.GearPresetFor(entry), EquipmentPresetRegistry.Get("Scaled_Greaves"))

func test_relic_entry_resolves_from_the_relic_presets() -> void:
	var entry: Dictionary = {
		"payload": "Kiln_Brand",
		"item_type": Types.Item_Type.Relic,
	}

	assert_eq(ShopSlot.GearPresetFor(entry), EquipmentPresetRegistry.GetRelic("Kiln_Brand"))

func test_entry_without_an_item_type_resolves_as_standard_gear() -> void:
	var entry: Dictionary = {"payload": "Scaled_Greaves"}

	assert_eq(ShopSlot.GearPresetFor(entry), EquipmentPresetRegistry.Get("Scaled_Greaves"))

func test_relic_description_shows_its_effect_text_at_the_stock_rarity() -> void:
	var entry: Dictionary = {
		"payload": "Kiln_Brand",
		"item_type": Types.Item_Type.Relic,
		"rarity": Types.Rarity.Epic,
		"attributes": {"Strength": 2},
	}
	var relic_effect: RelicEffect = EquipmentPresetRegistry.GetRelic("Kiln_Brand")._relic_effect.duplicate(true)
	relic_effect.Init(Types.Rarity.Epic)

	var body: String = ShopSlot.GearItemText(entry).body
	assert_string_contains(body, relic_effect._body)
	assert_false(body.contains("Body"), "The Relic text must be initialised, not the placeholder")

func test_every_rolled_relic_key_resolves_to_a_preset() -> void:
	for relic_key in EquipmentPresetRegistry.RELIC_PRESETS.keys():
		var entry: Dictionary = {
			"payload": relic_key,
			"item_type": Types.Item_Type.Relic,
		}

		assert_not_null(ShopSlot.GearPresetFor(entry), "Relic " + relic_key + " should resolve")
