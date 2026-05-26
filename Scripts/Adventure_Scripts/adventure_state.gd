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

func Serialize() -> Dictionary:
	var completion_map: Dictionary[int, bool]
	for node in nodes:
		if node.is_complete:
			completion_map[node.index] = true
	return {
		"current_node_index": current_node_index,
		"steps_taken_today": steps_taken_today,
		"last_played_date": last_palayed_date,
		"completed_nodes": completion_map,
	}

func Deserialize(p_data: Dictionary) -> void:
	current_node_index = p_data.get("current_node_index", 0)
	steps_taken_today = p_data.get("steps_taken_today", 0)
	last_palayed_date = p_data.get("last_played_date", "")
	var completion_map: Dictionary = p_data.get("completed_nodes", {})
	for node in nodes:
		node.is_complete = completion_map.get(node.index, false)
