extends GutTest

## Releasing or sacrificing a champion must hand its gear back to the unequipped pool.
## Clearing only the character's _held_items leaves the item's _held_by pointing at an
## instance that no longer exists, which hides the item from the Armory for good.

var _main_inst: Main_Instance = null
var _item_collection: ItemCollection = null

func before_each():
	_main_inst = Main_Instance.new()
	_item_collection = ItemCollection.new()
	_main_inst._item_collection = _item_collection
	main._instance = _main_inst

func after_each():
	for item: Equipment in _item_collection._items.values():
		item.free()
	_item_collection.free()
	_main_inst.free()
	main._instance = null

func _EquipmentPresetFor(p_slot: Types.Slot) -> EquipmentPreset:
	var preset: EquipmentPreset = EquipmentPreset.new()
	preset._name = "Test Item"
	preset._slot = p_slot
	preset._rarity = Types.Rarity.Common
	preset._texture_path = "res://Assets/Champ_Collector/Icons/Items/Spear/Spear_0002.png"
	return preset

func _CharacterHolding(p_slots: Array[Types.Slot]) -> Character:
	var character: Character = Character.new()
	character._name = "Test Champion"
	for slot: Types.Slot in p_slots:
		_item_collection.AddPreset(_EquipmentPresetFor(slot))
		var item_id: int = _item_collection._items.keys().back()
		_item_collection.EquipCollectionItem(item_id)
		character._held_items[slot] = item_id
	return character

func test_unequip_all_held_items_returns_every_item_to_the_unequipped_pool() -> void:
	var character: Character = _CharacterHolding([Types.Slot.Weapon, Types.Slot.Boots])
	var held_ids: Array = character._held_items.values().duplicate()

	_item_collection.UnequipAllHeldItems(character)

	for item_id: int in held_ids:
		assert_eq(_item_collection._items[item_id]._held_by, ItemCollection.UNEQUIPPED,
				"Gear from a removed champion should be selectable again")
	assert_true(character._held_items.is_empty(), "The character's slots should be emptied")

func test_unequip_all_held_items_does_not_delete_the_items() -> void:
	var character: Character = _CharacterHolding([Types.Slot.Weapon])
	var starting_size: int = _item_collection.Size()

	_item_collection.UnequipAllHeldItems(character)

	assert_eq(_item_collection.Size(), starting_size, "Removing a champion is an unequip, not an item delete")

func test_unequip_all_held_items_tolerates_an_item_that_no_longer_exists() -> void:
	var character: Character = _CharacterHolding([Types.Slot.Weapon])
	var item_id: int = character._held_items[Types.Slot.Weapon]
	var removed_item: Equipment = _item_collection._items[item_id]
	_item_collection.Remove(item_id)
	removed_item.free()

	_item_collection.UnequipAllHeldItems(character)

	assert_true(character._held_items.is_empty(), "A stale held ID should not block clearing the slots")

func test_removed_character_leaves_the_collection() -> void:
	var collection: CharacterCollection = CharacterCollection.new()
	var character: Character = Character.new()
	character._instance_ID = 7
	collection._characters[7] = character

	collection.Remove(7)

	assert_false(collection._characters.has(7), "A released champion should no longer be in the roster")
	collection.free()

func test_the_last_champion_cannot_be_released() -> void:
	var collection: Dictionary[int, Character] = {0: Character.new()}

	assert_false(InspectCollectionMenu.CanReleaseCharacter(collection, 0),
			"Releasing the only champion would leave an empty roster")

func test_a_champion_can_be_released_while_another_remains() -> void:
	var collection: Dictionary[int, Character] = {0: Character.new(), 1: Character.new()}

	assert_true(InspectCollectionMenu.CanReleaseCharacter(collection, 0),
			"With a second champion in the roster, release should be allowed")

func test_release_is_refused_without_a_selection() -> void:
	var collection: Dictionary[int, Character] = {0: Character.new(), 1: Character.new()}

	assert_false(InspectCollectionMenu.CanReleaseCharacter(collection, -1),
			"With no champion selected there is nothing to release")
