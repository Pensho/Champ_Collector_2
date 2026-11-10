class_name AdventureRoadGenerator extends Node

## Pure static pipeline that turns a straight node-to-node edge into a winding polyline,
## deterministic for a given seed. No nodes, no drawing — mirrors
## AdventureBackgroundGenerator so it stays fully unit-testable.
##
## The winding comes from the biome's own detail_noise field (the same field that places
## decor), sampled at two interior points along the edge and folded by p_seed so different
## adventures wind differently while staying stable across redraws.

## Sway scales with edge length so short edges stay near-straight; capped so long edges
## do not wander off the road bed.
const SWAY_LENGTH_RATIO: float = 0.18
const SWAY_MAX: float = 45.0

const INTERIOR_T_FIRST: float = 0.35
const INTERIOR_T_SECOND: float = 0.65

const TESSELLATE_STAGES: int = 5
const TESSELLATE_TOLERANCE: float = 2.0

const DEGENERATE_LENGTH: float = 0.001


## One edge being routed as a street, between two node centres.
class StreetEdge:
	var key: Vector2i
	var from_center: Vector2
	var to_center: Vector2
	var lane: int = 0

	func _init(p_from: NodeData, p_to: NodeData, p_node_positions: Dictionary) -> void:
		key = Vector2i(p_from.index, p_to.index)
		from_center = StructureLayoutGenerator.NodeCenter(p_node_positions[p_from])
		to_center = StructureLayoutGenerator.NodeCenter(p_node_positions[p_to])

	func ComesWithin(p_other: StreetEdge, p_margin: float) -> bool:
		var own_left: float = minf(from_center.x, to_center.x)
		var own_right: float = maxf(from_center.x, to_center.x)
		var other_left: float = minf(p_other.from_center.x, p_other.to_center.x)
		var other_right: float = maxf(p_other.from_center.x, p_other.to_center.x)
		return own_left <= other_right + p_margin and other_left <= own_right + p_margin

## Coordinates are offset by a seed-derived vector before sampling detail_noise, so the
## same biome noise field produces a different wind per edge/seed instead of always
## reading the same patch of noise.
const SEED_OFFSET_RANGE: int = 4096


static func BuildRoadPoints(
		p_from: Vector2,
		p_to: Vector2,
		p_detail_noise: FastNoiseLite,
		p_seed: int) -> PackedVector2Array:
	var direction: Vector2 = p_to - p_from
	var length: float = direction.length()
	if length < DEGENERATE_LENGTH:
		return PackedVector2Array([p_from, p_to])

	var perpendicular: Vector2 = (direction / length).orthogonal()
	var sway: float = clampf(length * SWAY_LENGTH_RATIO, 0.0, SWAY_MAX)
	var seed_offset := Vector2(p_seed % SEED_OFFSET_RANGE, (p_seed / SEED_OFFSET_RANGE) % SEED_OFFSET_RANGE)

	var curve := Curve2D.new()
	curve.add_point(p_from)
	curve.add_point(_BuildInteriorPoint(p_from, p_to, INTERIOR_T_FIRST, perpendicular, sway, p_detail_noise, seed_offset))
	curve.add_point(_BuildInteriorPoint(p_from, p_to, INTERIOR_T_SECOND, perpendicular, sway, p_detail_noise, seed_offset))
	curve.add_point(p_to)

	return curve.tessellate(TESSELLATE_STAGES, TESSELLATE_TOLERANCE)


## Street roads for constructed biomes, keyed by Vector2i(from index, to index). Each road
## leaves its node vertically, makes one horizontal run in the gap between the two rows, and
## enters its target vertically, corners cut at 45°. Runs sharing a gap get separate lanes,
## ordered so routing adds no crossings beyond those of straight lines between the same
## nodes. Edges that skip a row are drawn straight.
static func BuildStreetRoads(
		p_nodes: Array[NodeData],
		p_node_positions: Dictionary,
		p_settings: StructureLayoutData) -> Dictionary[Vector2i, PackedVector2Array]:
	var roads: Dictionary[Vector2i, PackedVector2Array] = {}
	var row_bounds: Dictionary[int, Vector2] = _RowVerticalBounds(p_nodes, p_node_positions)
	var gaps: Dictionary[int, Array] = {}
	for node in p_nodes:
		for next: NodeData in node.next_node:
			var street := StreetEdge.new(node, next, p_node_positions)
			if next.depth != node.depth + 1:
				roads[street.key] = PackedVector2Array([street.from_center, street.to_center])
				continue
			if not gaps.has(node.depth):
				gaps[node.depth] = []
			gaps[node.depth].append(street)
	for depth in gaps:
		# The lower row (this depth) sits lower on screen, so its top bounds the band's bottom.
		var band_top: float = row_bounds[depth + 1].y + p_settings.street_clearance
		var band_bottom: float = row_bounds[depth].x - p_settings.street_clearance
		_RouteGap(gaps[depth], band_top, band_bottom, p_settings, roads)
	return roads


static func _RouteGap(
		p_streets: Array,
		p_band_top: float,
		p_band_bottom: float,
		p_settings: StructureLayoutData,
		p_roads: Dictionary[Vector2i, PackedVector2Array]) -> void:
	var rightward: Array[StreetEdge] = []
	var leftward: Array[StreetEdge] = []
	for street: StreetEdge in p_streets:
		var horizontal_offset: float = street.to_center.x - street.from_center.x
		if is_zero_approx(horizontal_offset):
			p_roads[street.key] = PackedVector2Array([street.from_center, street.to_center])
		elif horizontal_offset > 0.0:
			rightward.append(street)
		else:
			leftward.append(street)
	# Within each direction, the road starting furthest along it, then the one reaching
	# furthest, takes the lane nearest its source; see BuildStreetRoads.
	rightward.sort_custom(func(p_a: StreetEdge, p_b: StreetEdge) -> bool:
		if p_a.from_center.x != p_b.from_center.x:
			return p_a.from_center.x > p_b.from_center.x
		return p_a.to_center.x > p_b.to_center.x)
	leftward.sort_custom(func(p_a: StreetEdge, p_b: StreetEdge) -> bool:
		if p_a.from_center.x != p_b.from_center.x:
			return p_a.from_center.x < p_b.from_center.x
		return p_a.to_center.x < p_b.to_center.x)
	# Opposite-direction streets only share horizontal extent when their straight lines
	# cross, so assigning both groups together just keeps such a pair off one lane.
	var routed: Array[StreetEdge] = rightward + leftward
	var lane_count: int = _AssignLanes(routed, p_settings.lane_spacing)
	if lane_count == 0:
		return

	var band_height: float = p_band_bottom - p_band_top
	if band_height < 0.0:
		for street in routed:
			p_roads[street.key] = PackedVector2Array([street.from_center, street.to_center])
		return
	var spacing: float = 0.0
	if lane_count > 1:
		spacing = minf(p_settings.lane_spacing, band_height / (lane_count - 1))
		if spacing < p_settings.minimum_lane_spacing:
			for street in routed:
				p_roads[street.key] = PackedVector2Array([
					street.from_center,
					Vector2(street.from_center.x, p_band_bottom),
					Vector2(street.to_center.x, p_band_top),
					street.to_center,
				])
			return
	var nearest_lane_y: float = (p_band_top + p_band_bottom) * 0.5 + spacing * (lane_count - 1) * 0.5
	for street in routed:
		var lane_y: float = nearest_lane_y - street.lane * spacing
		p_roads[street.key] = _Chamfer(PackedVector2Array([
			street.from_center,
			Vector2(street.from_center.x, lane_y),
			Vector2(street.to_center.x, lane_y),
			street.to_center,
		]), p_settings.chamfer_size)


## Gives each street, in order, the lowest lane above every earlier street whose horizontal
## extent comes within p_margin of its own. Returns the number of lanes used.
static func _AssignLanes(p_streets: Array[StreetEdge], p_margin: float) -> int:
	var lane_count: int = 0
	for index in p_streets.size():
		var street: StreetEdge = p_streets[index]
		street.lane = 0
		for earlier_index in index:
			var earlier: StreetEdge = p_streets[earlier_index]
			if street.ComesWithin(earlier, p_margin):
				street.lane = maxi(street.lane, earlier.lane + 1)
		lane_count = maxi(lane_count, street.lane + 1)
	return lane_count


## Cuts every interior corner by p_size along both of its segments, capped at half of the
## shorter one so neighbouring cuts never overlap.
static func _Chamfer(p_points: PackedVector2Array, p_size: float) -> PackedVector2Array:
	if p_size <= 0.0:
		return p_points
	var result := PackedVector2Array([p_points[0]])
	for index in range(1, p_points.size() - 1):
		var incoming: Vector2 = p_points[index] - p_points[index - 1]
		var outgoing: Vector2 = p_points[index + 1] - p_points[index]
		var cut: float = minf(p_size, minf(incoming.length(), outgoing.length()) * 0.5)
		if cut <= 0.0:
			result.append(p_points[index])
			continue
		result.append(p_points[index] - incoming.normalized() * cut)
		result.append(p_points[index] + outgoing.normalized() * cut)
	result.append(p_points[-1])
	return result


## Per depth, Vector2(top, bottom) of the union of that row's node rects.
static func _RowVerticalBounds(p_nodes: Array[NodeData], p_node_positions: Dictionary) -> Dictionary[int, Vector2]:
	var bounds: Dictionary[int, Vector2] = {}
	for node in p_nodes:
		var top: float = p_node_positions[node].y
		var bottom: float = top + AdventureNodePlacement.NODE_SIZE
		if bounds.has(node.depth):
			bounds[node.depth] = Vector2(minf(bounds[node.depth].x, top), maxf(bounds[node.depth].y, bottom))
		else:
			bounds[node.depth] = Vector2(top, bottom)
	return bounds


static func _BuildInteriorPoint(
		p_from: Vector2,
		p_to: Vector2,
		p_t: float,
		p_perpendicular: Vector2,
		p_sway: float,
		p_detail_noise: FastNoiseLite,
		p_seed_offset: Vector2) -> Vector2:
	var base_point: Vector2 = p_from.lerp(p_to, p_t)
	var sample_point: Vector2 = base_point + p_seed_offset
	var noise_sample: float = p_detail_noise.get_noise_2d(sample_point.x, sample_point.y)
	return base_point + p_perpendicular * noise_sample * p_sway
