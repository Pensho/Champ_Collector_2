class_name LootTable extends Resource

const LOOTMANAGER = preload("uid://dgvom8pxqflsm")

@warning_ignore_start("unused_private_class_variable")

# Type as key and guaranteed amount is value.
@export var _primary_loot: Dictionary[LOOTMANAGER.LootType, int]

# Type as key and value is weight.
@export var _secondary_loot: Dictionary[LOOTMANAGER.LootType, int]
@export var _gear_loot: EquipmentPreset
@export var _reagent_max_rarity: Types.Rarity = Types.Rarity.Epic

var _budget: int = 0

class DropResult extends Resource:
	var _equipment: EquipmentPreset = null
	var _experience: int = 0
	var _silver: int = 0
	var _fortunes_favor: Dictionary[FortuneFavorTier.TierType, int] = {}
	var _supplies: int = 0
	var _reagents: Array[String] = []

var _drop_result: DropResult = DropResult.new()

@warning_ignore_restore("unused_private_class_variable")
