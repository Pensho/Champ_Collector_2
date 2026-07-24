extends GutTest

const CommonEnums = preload("uid://bkpa0hv70oydy")

var _character: Character = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null

func before_each():
	_character = Character.new()
	_main_inst = Main_Instance.new()
	_item_col = ItemCollection.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst

func after_each():
	_item_col.free()
	_main_inst.free()
	main._instance = null

# --- Default / no-equipment baseline ---

func test_GetEquipmentBonus():
	var equipment_bonus: int = 0
	for attr in _character._attributes.keys():
		equipment_bonus = _character.GetEquipmentBonus(attr)
		assert_eq(0, equipment_bonus, "Character by default should have 0 from equipment bonus.")

func test_get_battle_attribute_equals_base_when_no_equipment() -> void:
	_character._attributes[Types.Attribute.Attack] = 25
	assert_eq(_character.GetTotalAttribute(Types.Attribute.Attack), 25,
		"GetTotalAttribute should equal base attribute when no items are equipped")

# --- UnequipItem ---

func test_unequip_removes_slot() -> void:
	_character._held_items[Types.Slot.Weapon] = 0
	_character.UnequipItem(Types.Slot.Weapon)
	assert_false(_character._held_items.has(Types.Slot.Weapon),
		"Weapon slot should be empty after UnequipItem")

func test_unequip_noop_on_empty_slot() -> void:
	_character.UnequipItem(Types.Slot.Boots)
	assert_false(_character._held_items.has(Types.Slot.Boots),
		"Unequipping an already-empty slot should not crash or change state")

# --- EquipItem ---

func test_equip_item_occupies_slot() -> void:
	var weapon: Equipment = Equipment.new()
	weapon._slot = Types.Slot.Weapon
	_item_col._items[0] = weapon
	_character.EquipItem(0)
	assert_true(_character._held_items.has(Types.Slot.Weapon),
		"Weapon slot should be occupied after EquipItem")
	assert_eq(_character._held_items[Types.Slot.Weapon], 0,
		"Held item ID should match the equipped item's instance ID")
	weapon.free()

func test_equip_item_does_not_overwrite_occupied_slot() -> void:
	var weapon1: Equipment = Equipment.new()
	weapon1._slot = Types.Slot.Weapon
	var weapon2: Equipment = Equipment.new()
	weapon2._slot = Types.Slot.Weapon
	_item_col._items[0] = weapon1
	_item_col._items[1] = weapon2
	_character.EquipItem(0)
	_character.EquipItem(1)
	assert_eq(_character._held_items[Types.Slot.Weapon], 0,
		"Second EquipItem into an occupied slot must leave the original item in place")
	weapon1.free()
	weapon2.free()

# --- GetEquipmentBonus and GetTotalAttribute with item ---

func test_get_equipment_bonus_with_item_equipped() -> void:
	var weapon: Equipment = Equipment.new()
	weapon._slot = Types.Slot.Weapon
	weapon._attributes[Types.Attribute.Attack] = 15
	_item_col._items[0] = weapon
	_character.EquipItem(0)
	assert_eq(_character.GetEquipmentBonus(Types.Attribute.Attack), 15,
		"GetEquipmentBonus should reflect the weapon's Attack value")
	weapon.free()

func test_get_battle_attribute_includes_equipment_bonus() -> void:
	_character._attributes[Types.Attribute.Attack] = 10
	var weapon: Equipment = Equipment.new()
	weapon._slot = Types.Slot.Weapon
	weapon._attributes[Types.Attribute.Attack] = 5
	_item_col._items[0] = weapon
	_character.EquipItem(0)
	assert_eq(_character.GetTotalAttribute(Types.Attribute.Attack), 15,
		"GetTotalAttribute should sum base attribute and equipment bonus")
	weapon.free()
