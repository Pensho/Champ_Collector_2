extends GutTest

## Regression coverage: two items sharing a slot must each show their own texture, not
## whichever one was collected first (Quorum Bell landing in the Weapon slot before a
## Spear used to permanently cache the Relic's icon for every future Weapon item).

func _preset(p_texture_path: String) -> EquipmentPreset:
	var preset: EquipmentPreset = EquipmentPreset.new()
	preset._name = "Test Item"
	preset._slot = Types.Slot.Weapon
	preset._rarity = Types.Rarity.Common
	preset._texture_path = p_texture_path
	return preset

func test_get_item_texture_reads_each_items_own_texture() -> void:
	var collection: ItemCollection = ItemCollection.new()
	collection.AddPreset(_preset("res://Assets/Champ_Collector/Icons/Items/Spear/Spear_0002.png"))
	collection.AddPreset(_preset(
			"res://Assets/Champ_Collector/Icons/Items/Relics/Quorum_Bell/Quorum_Bell.png"))
	var item_ids: Array = collection._items.keys()

	var first_texture: Texture = collection.GetItemTexture(item_ids[0])
	var second_texture: Texture = collection.GetItemTexture(item_ids[1])

	assert_not_null(first_texture, "The first item's own texture should load")
	assert_not_null(second_texture, "The second item's own texture should load")
	assert_ne(first_texture, second_texture,
		"Two items sharing a slot should not be flattened onto one cached texture")

func test_get_item_texture_returns_null_for_an_unknown_instance() -> void:
	var collection: ItemCollection = ItemCollection.new()

	assert_null(collection.GetItemTexture(999))

func test_get_item_texture_caches_rather_than_reloading_every_call() -> void:
	var collection: ItemCollection = ItemCollection.new()
	collection.AddPreset(_preset("res://Assets/Champ_Collector/Icons/Items/Spear/Spear_0002.png"))
	var item_id: int = collection._items.keys()[0]

	var first_call: Texture = collection.GetItemTexture(item_id)
	var second_call: Texture = collection.GetItemTexture(item_id)

	assert_eq(collection._texture_cache.size(), 1, "One distinct path should cache to one entry")
	assert_same(first_call, second_call, "Repeated lookups should return the same cached Texture, not reload it")

func test_preload_item_textures_warms_every_registered_preset() -> void:
	var collection: ItemCollection = ItemCollection.new()

	collection._PreloadItemTextures()

	for preset: EquipmentPreset in EquipmentPresetRegistry.PRESETS.values():
		assert_true(collection._texture_cache.has(preset._texture_path),
			"Every standard preset's texture should be warmed at startup")
	for preset: EquipmentPreset in EquipmentPresetRegistry.RELIC_PRESETS.values():
		assert_true(collection._texture_cache.has(preset._texture_path),
			"Every Relic preset's texture should be warmed at startup")
