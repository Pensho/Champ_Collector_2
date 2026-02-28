class_name LootTable extends Resource

const LootManager = preload("uid://dgvom8pxqflsm")

@warning_ignore_start("unused_private_class_variable")

var _budget: int = 0

# Type as key and guaranteed amount is value.
@export var _primary_loot: Dictionary[LootManager.LootType, int]

# Type as key and value is weight.
@export var _secondary_loot: Dictionary[LootManager.LootType, int]
@export var _gear_loot: EquipmentPreset #Array[EquipmentPreset]

class DropResult extends Resource:
	var _equipment: EquipmentPreset = null
	var _experience: int = 0
	var _silver: int = 0

var _drop_result: DropResult = DropResult.new()

@warning_ignore_restore("unused_private_class_variable")
