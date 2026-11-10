class_name AdventureNodePlacement extends RefCounted

## Pure placement of adventure nodes on the map canvas: one row per depth, deepest at the
## top. Rows are ordered to reduce road crossings before nodes are spread across their
## row's slots and jittered.

const LAYER_HEIGHT: int = 180
const NODE_SIZE: int = 80
const PADDING: int = 30
const HORIZONTAL_JITTER: float = 55.0
const DEFAULT_VERTICAL_JITTER: float = 45.0
## Empty map kept above the boss (last) node so it has the same decorated run-off as the
## space below the first node. One extra layer past the boss, mirroring the bottom margin.
const END_MARGIN: int = LAYER_HEIGHT

## Restart 0 keeps creation order on ties; the others break ties randomly, which lets a
## branch settle on either side of the path it leaves.
const ORDERING_RESTARTS: int = 24
const ORDERING_SWEEPS: int = 3


static func CanvasHeight(p_nodes: Array[NodeData]) -> float:
	return (_MaxDepth(p_nodes) + 1) * LAYER_HEIGHT + PADDING * 2 + END_MARGIN


## Node top-left positions keyed by NodeData. Deterministic for a given node graph.
static func PlaceNodes(p_nodes: Array[NodeData], p_canvas_width: float, p_vertical_jitter: float) -> Dictionary:
	var positions: Dictionary = {}
	var max_depth: int = _MaxDepth(p_nodes)
	for row: Array[NodeData] in OrderRows(p_nodes):
		var count: int = row.size()
		var slot_width: float = p_canvas_width / (count + 1)
		# Kept under half the free space between slots so jitter never swaps neighbours.
		var horizontal_jitter: float = clampf((slot_width - NODE_SIZE) * 0.5, 0.0, HORIZONTAL_JITTER)
		for slot_index in count:
			var node: NodeData = row[slot_index]
			var base_x: float = (slot_index + 1) * slot_width - NODE_SIZE / 2.0
			var rng := RandomNumberGenerator.new()
			rng.seed = node.index
			var jitter_x: float = rng.randf_range(-horizontal_jitter, horizontal_jitter)
			var jitter_y: float = rng.randf_range(-p_vertical_jitter, p_vertical_jitter)
			var x: float = clampf(base_x + jitter_x, PADDING, p_canvas_width - NODE_SIZE - PADDING)
			var y: float = (max_depth - node.depth) * LAYER_HEIGHT + PADDING + END_MARGIN + jitter_y
			positions[node] = Vector2(x, y)
	return positions


## Nodes grouped by depth (index = depth), each row ordered left to right with the fewest
## crossings found between adjacent rows.
static func OrderRows(p_nodes: Array[NodeData]) -> Array[Array]:
	var rows: Array[Array] = _GroupByDepth(p_nodes)
	var best_rows: Array[Array] = _CopyRows(rows)
	var best_crossings: int = CountCrossings(rows)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	for restart in ORDERING_RESTARTS:
		if best_crossings == 0:
			break
		var tie_keys: Dictionary[NodeData, float] = {}
		for node in p_nodes:
			tie_keys[node] = float(node.index) if restart == 0 else rng.randf()
		var candidate: Array[Array] = _CopyRows(rows)
		for _sweep in ORDERING_SWEEPS:
			for depth in range(1, candidate.size()):
				_SortByNeighbours(candidate[depth], candidate[depth - 1], true, tie_keys)
			var crossings: int = CountCrossings(candidate)
			if crossings < best_crossings:
				best_crossings = crossings
				best_rows = _CopyRows(candidate)
			for depth in range(candidate.size() - 2, -1, -1):
				_SortByNeighbours(candidate[depth], candidate[depth + 1], false, tie_keys)
			crossings = CountCrossings(candidate)
			if crossings < best_crossings:
				best_crossings = crossings
				best_rows = _CopyRows(candidate)
	return best_rows


## Crossings between straight edges of adjacent rows, given each row's left-to-right order.
static func CountCrossings(p_rows: Array[Array]) -> int:
	var crossings: int = 0
	for depth in range(p_rows.size() - 1):
		var lower_slots: Dictionary[NodeData, int] = _SlotIndices(p_rows[depth])
		var upper_slots: Dictionary[NodeData, int] = _SlotIndices(p_rows[depth + 1])
		var edges: Array[Vector2i] = []
		for node: NodeData in p_rows[depth]:
			for next: NodeData in node.next_node:
				if upper_slots.has(next):
					edges.append(Vector2i(lower_slots[node], upper_slots[next]))
		for first in edges.size():
			for second in range(first + 1, edges.size()):
				var lower_order: int = edges[first].x - edges[second].x
				var upper_order: int = edges[first].y - edges[second].y
				if lower_order * upper_order < 0:
					crossings += 1
	return crossings


## Sorts p_row by the mean normalised position of each node's neighbours in p_neighbour_row
## (predecessors when p_use_previous, successors otherwise). Nodes with no neighbour there
## keep their own position as their key.
static func _SortByNeighbours(
		p_row: Array, p_neighbour_row: Array, p_use_previous: bool, p_tie_keys: Dictionary[NodeData, float]) -> void:
	var neighbour_slots: Dictionary[NodeData, int] = _SlotIndices(p_neighbour_row)
	var sort_keys: Dictionary[NodeData, float] = {}
	for slot_index in p_row.size():
		var node: NodeData = p_row[slot_index]
		var neighbours: Array[NodeData] = node.previous_node if p_use_previous else node.next_node
		var total: float = 0.0
		var count: int = 0
		for neighbour in neighbours:
			if neighbour_slots.has(neighbour):
				total += float(neighbour_slots[neighbour] + 1) / (p_neighbour_row.size() + 1)
				count += 1
		sort_keys[node] = total / count if count > 0 else float(slot_index + 1) / (p_row.size() + 1)
	p_row.sort_custom(func(p_a: NodeData, p_b: NodeData) -> bool:
		if not is_equal_approx(sort_keys[p_a], sort_keys[p_b]):
			return sort_keys[p_a] < sort_keys[p_b]
		return p_tie_keys[p_a] < p_tie_keys[p_b])


static func _GroupByDepth(p_nodes: Array[NodeData]) -> Array[Array]:
	var rows: Array[Array] = []
	rows.resize(_MaxDepth(p_nodes) + 1)
	for depth in rows.size():
		rows[depth] = [] as Array[NodeData]
	for node in p_nodes:
		rows[node.depth].append(node)
	for row in rows:
		row.sort_custom(func(p_a: NodeData, p_b: NodeData) -> bool: return p_a.index < p_b.index)
	return rows


static func _CopyRows(p_rows: Array[Array]) -> Array[Array]:
	var copy: Array[Array] = []
	for row in p_rows:
		copy.append(row.duplicate())
	return copy


static func _SlotIndices(p_row: Array) -> Dictionary[NodeData, int]:
	var slots: Dictionary[NodeData, int] = {}
	for slot_index in p_row.size():
		slots[p_row[slot_index]] = slot_index
	return slots


static func _MaxDepth(p_nodes: Array[NodeData]) -> int:
	var max_depth: int = 0
	for node in p_nodes:
		max_depth = maxi(max_depth, node.depth)
	return max_depth
