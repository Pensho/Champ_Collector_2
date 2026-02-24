class_name LootTable extends Resource

var _budget: int = 0

enum LootType
{
	Experience,
	Silver,
	Equipment,
	Fortunes_Favor,
	Supplies,
}

# Type as key and value is weight. 0 means it always will be included.
@export var _loot_types: Dictionary[LootType, int]
@export var _gear_loot: EquipmentPreset

func CalculateBudget(p_base_val: int, p_difficulty: int, p_supply_cost: int) -> void:
	_budget = int(p_base_val * pow(p_difficulty, 1.2)) + (p_base_val * p_supply_cost)
