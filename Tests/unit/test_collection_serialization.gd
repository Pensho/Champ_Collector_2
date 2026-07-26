extends GutTest

const LANCER_PRESET = preload("res://Data/Character_Player_Variants/Lancer.tres")
const RED_BOOTS_PRESET = preload("uid://c3g7cshxhg0rw")

# --- ItemCollection ---

func test_item_collection_serialize_roundtrip() -> void:
	var col1: ItemCollection = ItemCollection.new()
	var eq: Equipment = Equipment.new()
	eq._slot = Types.Slot.Boots
	eq._rarity = Types.Rarity.Rare
	eq._preset_path = "res://Data/Item_Presets/Red_Boots.tres"
	eq._texture = "res://Assets/Champ_Collector/Icons/Items/Red_Boot/Red_Boot_0003.png"
	eq._attributes[Types.Attribute.Speed] = 42
	eq._attributes[Types.Attribute.Defence] = 7
	eq._held_by = -1
	eq._instance_ID = 0
	eq._level = 3
	col1._items[0] = eq
	col1._next_id = 1

	var data: Dictionary = col1.Serialize()
	assert_eq(data["next_ID"], 1, "Serialized next_ID should match")

	var col2: ItemCollection = ItemCollection.new()
	col2.Deserialize(data)

	assert_eq(col2._items.size(), 1, "Item count must survive roundtrip")
	var restored: Equipment = col2._items[0]
	assert_eq(restored._attributes[Types.Attribute.Speed], 42,
		"Speed attribute must survive ItemCollection roundtrip")
	assert_eq(restored._attributes[Types.Attribute.Defence], 7,
		"Defence attribute must survive ItemCollection roundtrip")
	assert_eq(restored._held_by, -1, "held_by must survive roundtrip")
	assert_eq(restored._instance_ID, 0, "instance_ID must survive roundtrip")
	assert_eq(restored._level, 3, "level must survive ItemCollection roundtrip")
	assert_eq(col2._next_id, 1, "next_id must survive roundtrip")

	for item in col2._items.values():
		item.free()
	eq.free()
	col1.free()
	col2.free()

func test_item_collection_deserialize_legacy_preset_uid_key() -> void:
	var col2: ItemCollection = ItemCollection.new()
	col2.Deserialize({
		"items": [{
			"preset_UID": "uid://c3g7cshxhg0rw",
			"attributes": {},
			"instance_ID": 0,
			"held_by": -1,
			"rarity": Types.Rarity.Rare,
			"level": 0,
		}],
		"next_ID": 1,
	})

	assert_eq(col2._items.size(), 1,
		"A legacy save using the old 'preset_UID' key must still resolve and load")

	for item in col2._items.values():
		item.free()
	col2.free()

func test_item_collection_empty_roundtrip() -> void:
	var col1: ItemCollection = ItemCollection.new()
	var data: Dictionary = col1.Serialize()
	var col2: ItemCollection = ItemCollection.new()
	col2.Deserialize(data)
	assert_eq(col2._items.size(), 0, "Empty collection roundtrip should yield empty collection")
	col1.free()
	col2.free()

# --- CharacterCollection ---

func test_character_collection_serialize_roundtrip() -> void:
	var col1: CharacterCollection = CharacterCollection.new()
	seed(42)
	col1.Add(LANCER_PRESET.duplicate(true))

	var original: Character = col1.GetAllCharacters().values()[0]
	original._level = 7
	original._experience = 123
	var preset_path: String = original._preset_path

	var data: Dictionary = col1.Serialize()

	var col2: CharacterCollection = CharacterCollection.new()
	col2.Deserialize(data)

	assert_eq(col2.Size(), 1, "Character count must survive roundtrip")
	var restored: Character = col2.GetAllCharacters().values()[0]
	assert_eq(restored._level, 7, "Level must survive CharacterCollection roundtrip")
	assert_eq(restored._experience, 123, "Experience must survive CharacterCollection roundtrip")
	assert_eq(restored._preset_path, preset_path, "preset_path must survive roundtrip")

	col1.free()
	col2.free()

func test_character_collection_empty_roundtrip() -> void:
	var col1: CharacterCollection = CharacterCollection.new()
	var data: Dictionary = col1.Serialize()
	var col2: CharacterCollection = CharacterCollection.new()
	col2.Deserialize(data)
	assert_eq(col2.Size(), 0, "Empty collection roundtrip should yield empty collection")
	col1.free()
	col2.free()

func test_character_collection_skips_unresolvable_preset_path() -> void:
	var col1: CharacterCollection = CharacterCollection.new()
	seed(42)
	col1.Add(LANCER_PRESET.duplicate(true))
	var valid_character: Character = col1.GetAllCharacters().values()[0]
	valid_character._instance_ID = 1

	var data: Dictionary = col1.Serialize()
	data["characters"].append({
		"preset_path": "res://Data/Character_Player_Variants/Does_Not_Exist.tres",
		"experience": 0,
		"level": 1,
		"attributes": {},
		"held_items": {},
		"instance_ID": 2,
		"attribute_weights": "",
		"graft": "",
	})

	var col2: CharacterCollection = CharacterCollection.new()
	col2.Deserialize(data)

	assert_engine_error("err != OK")
	assert_engine_error("found")
	assert_push_error("unresolvable preset_path")
	assert_eq(col2.Size(), 1,
		"An unresolvable preset_path entry must be skipped, leaving the valid entry intact")

	col1.free()
	col2.free()

func test_character_collection_skips_empty_preset_path() -> void:
	var col1: CharacterCollection = CharacterCollection.new()
	var data: Dictionary = {
		"characters": [{
			"preset_path": "",
			"experience": 0,
			"level": 1,
			"attributes": {},
			"held_items": {},
			"instance_ID": 1,
			"attribute_weights": "",
			"graft": "",
		}],
		"max_amount": Game_Balance.COLLECTION_START_ROSTER_SIZE,
		"next_ID": 1,
	}

	col1.Deserialize(data)

	assert_push_error("empty preset_path")
	assert_eq(col1.Size(), 0, "An empty preset_path entry must be skipped")

	col1.free()
