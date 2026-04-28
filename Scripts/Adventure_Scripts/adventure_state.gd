class_name AdventureState extends Resource

var biome: BiomeData
var current_node_index: int
var last_palayed_date: String
var steps_taken_today: int
var nodes: Array[NodeData]

# Probably a dictionary holding [type, duration]
var active_effects

func GetNodeSupplyCost() -> int:
	var tier: int = floor(float(steps_taken_today) / GameBalance.ADVENTURE_DAILY_TIER_THRESHOLD)
	return GameBalance.ADVENTURE_ENERGY_COST_PER_TIER * (tier + 1)

func TakeStep():
	var cost: int = GetNodeSupplyCost()
	if (false == main.GetInstance()._resources.SpendSupplies(cost)):
		return
	steps_taken_today += 1

func CheckDailyActivity():
	if (last_palayed_date != Time.get_date_string_from_system()):
		steps_taken_today = 0
		last_palayed_date = Time.get_date_string_from_system()

func Serialize() -> void:
	# TODO: Implement serialization logic for AdventureState via resource saver and give JSON saver a String reference
	pass

func Deserialize(data: Dictionary) -> void:
	# TODO: Implement deserialization logic for AdventureState via resource loader and get JSON loader by a String reference
	pass
