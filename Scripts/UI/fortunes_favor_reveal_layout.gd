class_name FortunesFavorRevealLayout

## Spreads a Favor's rewards over the reveal panels. The last entry is the center panel,
## which holds the champion when there is one; an empty Dictionary marks a filler panel.
static func AssignRewardsToPanels(p_rewards: Array[Dictionary], p_panel_count: int) -> Array[Dictionary]:
	assert(not p_rewards.is_empty() and p_rewards.size() <= p_panel_count,
			"AssignRewardsToPanels: reward count must be between 1 and the panel count")
	var remaining: Array[Dictionary] = p_rewards.duplicate()
	var center_index: int = randi_range(0, remaining.size() - 1)
	for index in remaining.size():
		if(remaining[index]["type"] == RecruitmentManager.RewardType.CHAMPION):
			center_index = index
			break
	var center: Dictionary = remaining[center_index]
	remaining.remove_at(center_index)

	var outer: Array[Dictionary] = remaining
	while(outer.size() < p_panel_count - 1):
		outer.append({})
	outer.shuffle()
	outer.append(center)
	return outer

static func IsChampion(p_entry: Dictionary) -> bool:
	return p_entry.get("type", -1) == RecruitmentManager.RewardType.CHAMPION

static func GlowColor(p_entry: Dictionary, p_neutral: Color) -> Color:
	if(p_entry.is_empty()):
		return Color(0.0, 0.0, 0.0, 0.0)
	if(IsChampion(p_entry)):
		var champion: CharacterPreset = p_entry["champion"]
		return RarityColors.TEXT.get(champion._rarity, p_neutral)
	return p_neutral

static func PolygonCentroid(p_points: PackedVector2Array) -> Vector2:
	var doubled_area: float = 0.0
	var weighted_sum: Vector2 = Vector2.ZERO
	for index in p_points.size():
		var current: Vector2 = p_points[index]
		var following: Vector2 = p_points[(index + 1) % p_points.size()]
		var cross: float = current.cross(following)
		doubled_area += cross
		weighted_sum += (current + following) * cross
	if(is_zero_approx(doubled_area)):
		var average: Vector2 = Vector2.ZERO
		for point in p_points:
			average += point
		return average / maxf(p_points.size(), 1.0)
	return weighted_sum / (3.0 * doubled_area)

static func PolygonBounds(p_points: PackedVector2Array) -> Rect2:
	var bounds: Rect2 = Rect2(p_points[0], Vector2.ZERO)
	for point in p_points:
		bounds = bounds.expand(point)
	return bounds

## Screen pixels per texture pixel at which a texture centered on p_focus covers p_bounds.
static func CoverScale(p_texture_size: Vector2, p_bounds: Rect2, p_focus: Vector2) -> float:
	var half_width: float = maxf(p_focus.x - p_bounds.position.x, p_bounds.end.x - p_focus.x)
	var half_height: float = maxf(p_focus.y - p_bounds.position.y, p_bounds.end.y - p_focus.y)
	return maxf(2.0 * half_width / p_texture_size.x, 2.0 * half_height / p_texture_size.y)

## Polygon2D uv coordinates (texture pixels) that center the texture on the polygon's
## centroid and scale it to cover the polygon's bounds.
static func CoverUvs(p_points: PackedVector2Array, p_texture_size: Vector2) -> PackedVector2Array:
	var focus: Vector2 = PolygonCentroid(p_points)
	var scale: float = CoverScale(p_texture_size, PolygonBounds(p_points), focus)
	var uvs: PackedVector2Array = PackedVector2Array()
	for point in p_points:
		uvs.append((point - focus) / scale + p_texture_size * 0.5)
	return uvs

## Unit vector pointing from the screen center through the panel; zero for a centered panel.
static func BurstDirection(p_panel_center: Vector2, p_screen_center: Vector2) -> Vector2:
	var offset: Vector2 = p_panel_center - p_screen_center
	if(offset.length() < 1.0):
		return Vector2.ZERO
	return offset.normalized()

## Moves every edge of a convex polygon outward by p_distance (inward when negative).
static func OffsetPolygon(p_points: PackedVector2Array, p_distance: float) -> PackedVector2Array:
	var count: int = p_points.size()
	var normals: PackedVector2Array = _OutwardEdgeNormals(p_points)
	var offset: PackedVector2Array = PackedVector2Array()
	for index in count:
		var previous_normal: Vector2 = normals[(index - 1 + count) % count]
		var next_normal: Vector2 = normals[index]
		var miter: Vector2 = (previous_normal + next_normal).normalized()
		var miter_length: float = p_distance / maxf(miter.dot(next_normal), 0.25)
		offset.append(p_points[index] + miter * miter_length)
	return offset

## p_count points spread evenly along the polygon outline, each with its outward normal.
## Returns {"points": PackedVector2Array, "normals": PackedVector2Array}.
static func EdgeEmission(p_points: PackedVector2Array, p_count: int) -> Dictionary:
	var count: int = p_points.size()
	var normals: PackedVector2Array = _OutwardEdgeNormals(p_points)
	var perimeter: float = 0.0
	for index in count:
		perimeter += p_points[index].distance_to(p_points[(index + 1) % count])
	var emission_points: PackedVector2Array = PackedVector2Array()
	var emission_normals: PackedVector2Array = PackedVector2Array()
	var edge: int = 0
	var edge_start_distance: float = 0.0
	for sample in p_count:
		var distance: float = perimeter * (sample + 0.5) / p_count
		var edge_length: float = p_points[edge].distance_to(p_points[(edge + 1) % count])
		while(distance > edge_start_distance + edge_length and edge < count - 1):
			edge_start_distance += edge_length
			edge += 1
			edge_length = p_points[edge].distance_to(p_points[(edge + 1) % count])
		var weight: float = (distance - edge_start_distance) / maxf(edge_length, 0.001)
		emission_points.append(p_points[edge].lerp(p_points[(edge + 1) % count], weight))
		emission_normals.append(normals[edge])
	return {"points": emission_points, "normals": emission_normals}

static func _OutwardEdgeNormals(p_points: PackedVector2Array) -> PackedVector2Array:
	var centroid: Vector2 = PolygonCentroid(p_points)
	var normals: PackedVector2Array = PackedVector2Array()
	for index in p_points.size():
		var start: Vector2 = p_points[index]
		var end: Vector2 = p_points[(index + 1) % p_points.size()]
		var normal: Vector2 = (end - start).orthogonal().normalized()
		if(normal.dot((start + end) * 0.5 - centroid) < 0.0):
			normal = -normal
		normals.append(normal)
	return normals
