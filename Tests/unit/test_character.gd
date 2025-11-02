extends GutTest

const CommonEnums = preload("uid://bkpa0hv70oydy")

func test_GetEquipmentBonus():
	var character: Character = load("res://Scenes/Characters/Character.tscn").instantiate()
	
	var equipment_bonus: int = 0
	for attr in character._attributes.keys():
		equipment_bonus = character.GetEquipmentBonus(attr)
		assert_eq(0, equipment_bonus, "Character by default should have 0 from equipment bonus.")
