extends GutTest

const CommonEnums = preload("uid://bkpa0hv70oydy")

var _character: Character = null

func before_each():
	_character = load("res://Scenes/Characters/Character.tscn").instantiate()

func after_each():
	_character.free()

func test_GetEquipmentBonus():
	var equipment_bonus: int = 0
	for attr in _character._attributes.keys():
		equipment_bonus = _character.GetEquipmentBonus(attr)
		assert_eq(0, equipment_bonus, "Character by default should have 0 from equipment bonus.")
