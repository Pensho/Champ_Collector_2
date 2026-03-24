class_name LootTable extends Resource

const LOOTMANAGER = preload("uid://dgvom8pxqflsm")

@warning_ignore_start("unused_private_class_variable")

var _budget: int = 0

# Type as key and guaranteed amount is value.
@export var _primary_loot: Dictionary[LOOTMANAGER.LootType, int]

# Type as key and value is weight.
@export var _secondary_loot: Dictionary[LOOTMANAGER.LootType, int]
@export var _gear_loot: EquipmentPreset

class DropResult extends Resource:
	var _equipment: EquipmentPreset = null
	var _experience: int = 0
	var _silver: int = 0
	var _fortunes_favor: int = 0
	var _supplies: int = 0

var _drop_result: DropResult = DropResult.new()

@warning_ignore_restore("unused_private_class_variable")
