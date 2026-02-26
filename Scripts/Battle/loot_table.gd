class_name LootTable extends Resource

const LootManager = preload("uid://dgvom8pxqflsm")

var _budget: int = 0

# Type as key and guaranteed amount is value.
@export var _primary_loot: Dictionary[LootManager.LootType, int]

# Type as key and value is weight.
@export var _secondary_loot: Dictionary[LootManager.LootType, int]
@export var _gear_loot: Array[EquipmentPreset]
