extends GutTest

# Regression coverage: SetTargetingOrder must weigh total attributes (base +
# equipment), not just the base _attributes dictionary, or an equipped
# character can be mis-sorted relative to an unequipped one with a higher
# base stat.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _battle: Battle = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null

func before_each() -> void:
	_battle = Battle.new()
	_main_inst = Main_Instance.new()
	_item_col = ItemCollection.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst

func after_each() -> void:
	_battle.free()
	_item_col.free()
	_main_inst.free()
	main._instance = null

func test_targeting_order_accounts_for_equipment_bonus() -> void:
	var tankier_base: Character = TestFactory.make_character()
	tankier_base._attributes[Types.Attribute.Health] = 20
	tankier_base._attributes[Types.Attribute.Defence] = 20

	var equipped: Character = TestFactory.make_character()
	equipped._attributes[Types.Attribute.Health] = 10
	equipped._attributes[Types.Attribute.Defence] = 10
	var armor: Equipment = Equipment.new()
	armor._slot = Types.Slot.Weapon
	armor._attributes[Types.Attribute.Defence] = 50
	_item_col._items[0] = armor
	equipped.EquipItem(0)

	_battle._characters = {0: tankier_base, 1: equipped}
	_battle.SetTargetingOrder()

	assert_eq(_battle._targeting_order[0], 1,
		"The equipped character's total Defence should outweigh the unequipped character's higher base stats")
	armor.free()
