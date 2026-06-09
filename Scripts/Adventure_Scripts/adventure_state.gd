class_name AdventureState extends Resource

var biome: BiomeData
var template: AdventureTemplate
var difficulty: int = 0
var is_active: bool = false
var current_node_index: int
var last_palayed_date: String
var steps_taken_today: int
var nodes: Array[NodeData]
var _generation_seed: int = -1

# Dictionary[Types.Buff_Type, int] — buff type → turns remaining
var active_effects

static func CalculateScaledDifficulty(p_base: int, p_completed: int, p_total: int) -> int:
	if p_total <= 0:
		return p_base
	var tier: int = mini(int(floor(float(p_completed) * 3.0 / float(p_total))), 2)
	return p_base + tier

func GetNodeSupplyCost() -> int:
	var tier: int = floor(float(steps_taken_today) / GameBalance.ADVENTURE_DAILY_TIER_THRESHOLD)
	return GameBalance.ADVENTURE_ENERGY_COST_PER_TIER * (tier + 1)

func MarkCurrentNodeComplete() -> void:
	for node in nodes:
		if node.index == current_node_index:
			node.is_complete = true
			break

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
		"is_active": is_active,
		"difficulty": difficulty,
		"template_path": template.resource_path if template else "",
		"biome_path": biome.resource_path if biome else "",
		"generation_seed": _generation_seed,
	}

func Deserialize(p_data: Dictionary) -> void:
	current_node_index = p_data.get("current_node_index", 0)
	steps_taken_today = p_data.get("steps_taken_today", 0)
	last_palayed_date = p_data.get("last_played_date", "")
	is_active = p_data.get("is_active", false)
	difficulty = p_data.get("difficulty", 0)

	var template_path: String = p_data.get("template_path", "")
	var biome_path: String = p_data.get("biome_path", "")
	if not template_path.is_empty() and ResourceLoader.exists(template_path):
		template = load(template_path)
	if not biome_path.is_empty() and ResourceLoader.exists(biome_path):
		biome = load(biome_path)

	_generation_seed = p_data.get("generation_seed", -1)
	if template != null and biome != null and _generation_seed >= 0:
		seed(_generation_seed)
		nodes = AdventureGenerator.GenerateAdventure(template, biome)
	else:
		is_active = false

	var completion_map: Dictionary = p_data.get("completed_nodes", {})
	for node in nodes:
		node.is_complete = completion_map.get(node.index, false)
