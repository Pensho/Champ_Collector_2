extends GutTest

const CANVAS_WIDTH: float = 1280.0


func test_place_nodes_is_deterministic() -> void:
	var nodes: Array[NodeData] = _GenerateAdventure(7, AdventureLayout.Mechanic_Frequency.HIGH)
	var first: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, CANVAS_WIDTH, 45.0)
	var second: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, CANVAS_WIDTH, 45.0)
	for node in nodes:
		assert_eq(first[node], second[node], "Node %d should land in the same place every time." % node.index)


func test_overlapping_branches_are_ordered_without_crossings() -> void:
	var nodes: Array[NodeData] = _BuildSpine(9)
	nodes.append_array(AdventureGenerator.CreateParallelBranch(nodes[1], nodes[5], 3))
	nodes.append_array(AdventureGenerator.CreateParallelBranch(nodes[2], nodes[7], 4))
	_AssignIndices(nodes)
	assert_gt(AdventureNodePlacement.CountCrossings(_CreationOrderRows(nodes)), 0,
			"Creation order should cross here, or this test proves nothing.")
	assert_eq(AdventureNodePlacement.CountCrossings(AdventureNodePlacement.OrderRows(nodes)), 0,
			"Two staggered branches fit on opposite sides of the spine without crossing.")


func test_ordering_never_adds_crossings_to_generated_adventures() -> void:
	for adventure_seed in range(1, 31):
		var nodes: Array[NodeData] = _GenerateAdventure(adventure_seed, AdventureLayout.Mechanic_Frequency.HIGH)
		var creation_crossings: int = AdventureNodePlacement.CountCrossings(_CreationOrderRows(nodes))
		var ordered_crossings: int = AdventureNodePlacement.CountCrossings(AdventureNodePlacement.OrderRows(nodes))
		assert_lte(ordered_crossings, creation_crossings, "Seed %d gained crossings." % adventure_seed)


func test_rows_keep_every_node_once() -> void:
	var nodes: Array[NodeData] = _GenerateAdventure(3, AdventureLayout.Mechanic_Frequency.HIGH)
	var seen: Dictionary[NodeData, bool] = {}
	for row in AdventureNodePlacement.OrderRows(nodes):
		for node: NodeData in row:
			assert_false(seen.has(node), "Node %d appears twice." % node.index)
			seen[node] = true
	assert_eq(seen.size(), nodes.size(), "Every node should be placed in a row.")


func test_vertical_jitter_stays_within_its_bound() -> void:
	var nodes: Array[NodeData] = _GenerateAdventure(5, AdventureLayout.Mechanic_Frequency.HIGH)
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, CANVAS_WIDTH, 12.0)
	var max_depth: int = 0
	for node in nodes:
		max_depth = maxi(max_depth, node.depth)
	for node in nodes:
		var row_y: float = ((max_depth - node.depth) * AdventureNodePlacement.LAYER_HEIGHT
				+ AdventureNodePlacement.PADDING + AdventureNodePlacement.END_MARGIN)
		assert_almost_eq(positions[node].y, row_y, 12.0, "Node %d drifted past the jitter." % node.index)


func test_zero_vertical_jitter_levels_each_row() -> void:
	var nodes: Array[NodeData] = _GenerateAdventure(5, AdventureLayout.Mechanic_Frequency.HIGH)
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, CANVAS_WIDTH, 0.0)
	for row in AdventureNodePlacement.OrderRows(nodes):
		for node: NodeData in row:
			assert_eq(positions[node].y, positions[row[0]].y, "Row %d should be level." % node.depth)


func test_jitter_never_swaps_or_overlaps_neighbours() -> void:
	var nodes: Array[NodeData] = _GenerateAdventure(11, AdventureLayout.Mechanic_Frequency.HIGH)
	var positions: Dictionary = AdventureNodePlacement.PlaceNodes(nodes, 500.0, 45.0)
	for row in AdventureNodePlacement.OrderRows(nodes):
		for slot_index in range(1, row.size()):
			var gap: float = positions[row[slot_index]].x - positions[row[slot_index - 1]].x
			assert_gte(gap, float(AdventureNodePlacement.NODE_SIZE),
					"Nodes in row %d should keep their order without overlapping." % row[0].depth)


func _GenerateAdventure(p_seed: int, p_branching: AdventureLayout.Mechanic_Frequency) -> Array[NodeData]:
	var layout := AdventureLayout.new()
	layout.branching_paths = p_branching
	var adventure := AdventureData.new()
	adventure.layout = layout
	seed(p_seed)
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(adventure)
	randomize()
	return nodes


func _BuildSpine(p_length: int) -> Array[NodeData]:
	var spine: Array[NodeData] = []
	for depth in p_length:
		var node := NodeData.new()
		node.depth = depth
		if depth > 0:
			spine[-1].next_node.append(node)
			node.previous_node.append(spine[-1])
		spine.append(node)
	return spine


func _AssignIndices(p_nodes: Array[NodeData]) -> void:
	for index in p_nodes.size():
		p_nodes[index].index = index


func _CreationOrderRows(p_nodes: Array[NodeData]) -> Array[Array]:
	var max_depth: int = 0
	for node in p_nodes:
		max_depth = maxi(max_depth, node.depth)
	var rows: Array[Array] = []
	for depth in max_depth + 1:
		rows.append([] as Array[NodeData])
	for node in p_nodes:
		rows[node.depth].append(node)
	return rows
