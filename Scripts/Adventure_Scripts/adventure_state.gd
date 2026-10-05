class_name AdventureState extends Resource

var adventure: AdventureData
var difficulty: int = 0
var is_active: bool = false
var current_node_index: int
var nodes: Array[NodeData]

# Adventure-spanning effects: type -> combats remaining (ADVENTURE_PERMANENT_EFFECT = rest of adventure)
var active_buffs: Dictionary[Types.Buff_Type, int]
var active_debuffs: Dictionary[Types.Debuff_Type, int]

var _generation_seed: int = -1

static func CalculateScaledDifficulty(p_base: int, p_completed: int, p_total: int) -> int:
	if p_total <= 0:
		return p_base
	var tier: int = mini(int(floor(float(p_completed) * 3.0 / float(p_total))), 2)
	return p_base + tier

func MarkCurrentNodeComplete() -> void:
	for node in nodes:
		if node.index == current_node_index:
			node.is_complete = true
			break

func AddAdventureBuff(p_type: Types.Buff_Type, p_combats: int) -> void:
	active_buffs[p_type] = maxi(active_buffs.get(p_type, 0), p_combats)

func AddAdventureDebuff(p_type: Types.Debuff_Type, p_combats: int) -> void:
	active_debuffs[p_type] = maxi(active_debuffs.get(p_type, 0), p_combats)

func DecrementAdventureEffects() -> void:
	for type: Types.Buff_Type in active_buffs.keys().duplicate():
		if active_buffs[type] >= GameBalance.ADVENTURE_PERMANENT_EFFECT:
			continue
		active_buffs[type] -= 1
		if active_buffs[type] <= 0:
			active_buffs.erase(type)
	for type: Types.Debuff_Type in active_debuffs.keys().duplicate():
		if active_debuffs[type] >= GameBalance.ADVENTURE_PERMANENT_EFFECT:
			continue
		active_debuffs[type] -= 1
		if active_debuffs[type] <= 0:
			active_debuffs.erase(type)

func Serialize() -> Dictionary:
	var completion_map: Dictionary[int, bool]
	for node in nodes:
		if node.is_complete:
			completion_map[node.index] = true
	return {
		"current_node_index": current_node_index,
		"completed_nodes": completion_map,
		"is_active": is_active,
		"difficulty": difficulty,
		"adventure_path": adventure.resource_path if adventure else "",
		"generation_seed": _generation_seed,
		"active_buffs": active_buffs,
		"active_debuffs": active_debuffs,
	}

func Deserialize(p_data: Dictionary) -> void:
	current_node_index = p_data.get("current_node_index", 0)
	is_active = p_data.get("is_active", false)
	difficulty = p_data.get("difficulty", 0)

	var adventure_path: String = p_data.get("adventure_path", "")
	if not adventure_path.is_empty() and ResourceLoader.exists(adventure_path):
		adventure = load(adventure_path)

	_generation_seed = p_data.get("generation_seed", -1)
	if adventure != null and _generation_seed >= 0:
		seed(_generation_seed)
		nodes = AdventureGenerator.GenerateAdventure(adventure)
	else:
		is_active = false

	var completion_map: Dictionary = {}
	for key in p_data.get("completed_nodes", {}):
		completion_map[int(key)] = true
	for node in nodes:
		node.is_complete = completion_map.get(node.index, false)

	active_buffs.clear()
	for key in p_data.get("active_buffs", {}):
		active_buffs[int(key) as Types.Buff_Type] = p_data["active_buffs"][key]
	active_debuffs.clear()
	for key in p_data.get("active_debuffs", {}):
		active_debuffs[int(key) as Types.Debuff_Type] = p_data["active_debuffs"][key]
