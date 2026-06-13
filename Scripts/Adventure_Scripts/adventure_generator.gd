class_name AdventureGenerator extends Node


static func GenerateAdventure(p_template: AdventureTemplate, p_biome: BiomeData) -> Array[NodeData]:
	var target_depth: int = randi_range(p_template.MIN_DEPTH, p_template.MAX_DEPTH)

	var spine: Array[NodeData] = _BuildSpine(target_depth)
	_InsertSpecialNodes(spine, NodeData.Node_Type.REST_STOP, SetRestNumber(p_template.rest_stops))
	_InsertSpecialNodes(spine, NodeData.Node_Type.HINT, SetRestNumber(p_template.hint_nodes))
	_InsertSpecialNodes(spine, NodeData.Node_Type.GAMBLE, SetRestNumber(p_template.gamble_nodes))
	_InsertSpecialNodes(spine, NodeData.Node_Type.ESCALATING, SetRestNumber(p_template.escalating_nodes))

	var boss: NodeData = NodeData.new()
	boss.node_type = NodeData.Node_Type.BOSS
	boss.depth = target_depth
	spine[-1].next_node.append(boss)
	boss.previous_node.append(spine[-1])

	var branch_nodes: Array[NodeData] = _AddBranches(spine, p_template.branching_paths)

	var all_nodes: Array[NodeData]
	all_nodes.append_array(spine)
	all_nodes.append(boss)
	all_nodes.append_array(branch_nodes)

	for i in all_nodes.size():
		all_nodes[i].index = i

	_PopulateNodeContexts(all_nodes, p_biome)
	return all_nodes


static func _BuildSpine(p_depth: int) -> Array[NodeData]:
	var spine: Array[NodeData]
	for i in p_depth:
		var node: NodeData = NodeData.new()
		node.node_type = NodeData.Node_Type.FIGHT
		node.depth = i
		if i > 0:
			spine[i - 1].next_node.append(node)
			node.previous_node.append(spine[i - 1])
		spine.append(node)
	return spine


static func _InsertSpecialNodes(p_spine: Array[NodeData], p_node_type: NodeData.Node_Type, p_count: int) -> void:
	if p_count == 0 or p_spine.size() < 2:
		return
	@warning_ignore("integer_division")
	var interval: int = p_spine.size() / (p_count + 1)
	for i in p_count:
		var index: int = interval * (i + 1)
		if index < p_spine.size() - 1 and p_spine[index].node_type == NodeData.Node_Type.FIGHT:
			p_spine[index].node_type = p_node_type


static func _AddBranches(p_spine: Array[NodeData], p_frequency: AdventureTemplate.Mechanic_Frequency) -> Array[NodeData]:
	var branch_count: int = SetNumberOfBranchingPaths(p_frequency)
	var all_branch_nodes: Array[NodeData]
	var used_start_indices: Array[int]

	for _i in branch_count:
		var branch_length: int = SetBranchLength(p_frequency)
		# need at least branch_length + 1 gap between start and end, and stay away from the final node
		var min_start: int = 1
		var max_start: int = p_spine.size() - branch_length - 2
		if max_start <= min_start:
			break

		var start_index: int = _PickUnusedIndex(min_start, max_start, used_start_indices)
		if start_index == -1:
			break
		used_start_indices.append(start_index)

		var end_index: int = start_index + branch_length + 1
		var new_nodes: Array[NodeData] = CreateParallelBranch(p_spine[start_index], p_spine[end_index], branch_length)
		all_branch_nodes.append_array(new_nodes)

	return all_branch_nodes


static func _PickUnusedIndex(p_min: int, p_max: int, p_used: Array[int]) -> int:
	var candidates: Array[int]
	for i in range(p_min, p_max + 1):
		if not p_used.has(i):
			candidates.append(i)
	if candidates.is_empty():
		return -1
	return candidates[randi_range(0, candidates.size() - 1)]


static func CreateParallelBranch(p_start: NodeData, p_end: NodeData, p_length: int) -> Array[NodeData]:
	var branch: Array[NodeData]
	for i in p_length:
		var node: NodeData = NodeData.new()
		node.node_type = NodeData.Node_Type.FIGHT
		node.depth = p_start.depth + 1 + i
		branch.append(node)
	for i in branch.size():
		if i == 0:
			p_start.next_node.append(branch[0])
			branch[0].previous_node.append(p_start)
		else:
			branch[i - 1].next_node.append(branch[i])
			branch[i].previous_node.append(branch[i - 1])
	p_end.previous_node.append(branch[-1])
	branch[-1].next_node.append(p_end)
	return branch


static func SetRestNumber(p_frequency: AdventureTemplate.Mechanic_Frequency) -> int:
	match p_frequency:
		AdventureTemplate.Mechanic_Frequency.LOW:
			return randi_range(0, 1)
		AdventureTemplate.Mechanic_Frequency.MEDIUM:
			return randi_range(2, 3)
		AdventureTemplate.Mechanic_Frequency.HIGH:
			return randi_range(3, 5)
		AdventureTemplate.Mechanic_Frequency.NONE, _:
			return 0


static func SetNumberOfBranchingPaths(p_frequency: AdventureTemplate.Mechanic_Frequency) -> int:
	match p_frequency:
		AdventureTemplate.Mechanic_Frequency.LOW:
			return randi_range(2, 3)
		AdventureTemplate.Mechanic_Frequency.MEDIUM:
			return randi_range(4, 6)
		AdventureTemplate.Mechanic_Frequency.HIGH:
			return randi_range(7, 9)
		AdventureTemplate.Mechanic_Frequency.NONE, _:
			return 0


static func SetBranchLength(p_frequency: AdventureTemplate.Mechanic_Frequency) -> int:
	match p_frequency:
		AdventureTemplate.Mechanic_Frequency.LOW:
			return randi_range(3, 5)
		AdventureTemplate.Mechanic_Frequency.MEDIUM:
			return randi_range(2, 4)
		AdventureTemplate.Mechanic_Frequency.HIGH:
			return randi_range(2, 3)
		AdventureTemplate.Mechanic_Frequency.NONE, _:
			return 0


static func _PopulateNodeContexts(p_nodes: Array[NodeData], p_biome: BiomeData) -> void:
	for node in p_nodes:
		match node.node_type:
			NodeData.Node_Type.FIGHT:
				if p_biome.possible_opponents.is_empty():
					continue
				var ctx := Context_Battle.new()
				ctx._enemies_wave_1 = [
					_WeightedRandomPick(p_biome.possible_opponents),
					_WeightedRandomPick(p_biome.possible_opponents),
					_WeightedRandomPick(p_biome.possible_opponents),
				]
				ctx._loot_table = p_biome.possible_rewards
				node.scene_context = ctx
			NodeData.Node_Type.BOSS:
				if p_biome.possible_bosses.is_empty():
					continue
				var ctx := Context_Battle.new()
				ctx._enemies_wave_1 = [p_biome.possible_bosses.pick_random()]
				ctx._loot_table = p_biome.boss_rewards if p_biome.boss_rewards != null else p_biome.possible_rewards
				node.scene_context = ctx
			NodeData.Node_Type.REST_STOP:
				var rest_ctx := ContextRestStop.new()
				rest_ctx.granted_buff = _RandomBuffType()
				node.scene_context = rest_ctx
			NodeData.Node_Type.HINT:
				var hint_ctx := ContextHint.new()
				hint_ctx.reward_silver = GameBalance.ADVENTURE_HINT_REWARD_SILVER
				hint_ctx.reward_supplies = GameBalance.ADVENTURE_HINT_REWARD_SUPPLIES
				node.scene_context = hint_ctx
			NodeData.Node_Type.GAMBLE:
				var gamble_ctx := ContextGamble.new()
				gamble_ctx.win_buff = _RandomBuffType()
				gamble_ctx.loss_debuff = _RandomDebuffType()
				node.scene_context = gamble_ctx
			NodeData.Node_Type.ESCALATING:
				var escalating_ctx := ContextEscalating.new()
				escalating_ctx.reward_silver = GameBalance.ADVENTURE_ESCALATING_REWARD_SILVER
				escalating_ctx.reward_supplies = GameBalance.ADVENTURE_ESCALATING_REWARD_SUPPLIES
				node.scene_context = escalating_ctx


static func _RandomBuffType() -> Types.Buff_Type:
	var values: Array = Types.Buff_Type.values()
	values.erase(Types.Buff_Type.Invalid)
	return values.pick_random()


static func _RandomDebuffType() -> Types.Debuff_Type:
	var values: Array = Types.Debuff_Type.values()
	values.erase(Types.Debuff_Type.Invalid)
	return values.pick_random()


static func _WeightedRandomPick(p_pool: Dictionary[CharacterPreset, int]) -> CharacterPreset:
	var total: int = 0
	for w in p_pool.values():
		total += w
	var roll: int = randi_range(0, total - 1)
	var cumulative: int = 0
	for key: CharacterPreset in p_pool.keys():
		cumulative += p_pool[key]
		if roll < cumulative:
			return key
	return p_pool.keys()[-1]
