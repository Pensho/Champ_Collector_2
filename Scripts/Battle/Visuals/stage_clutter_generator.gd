class_name StageClutterGenerator extends RefCounted

## Pure static scatter for the floor band's ground clutter, deterministic for a given seed.
## No nodes, no drawing — mirrors AdventureBackgroundGenerator, but candidate cells are
## rolled from density alone since a StageClutterEntry carries no noise thresholds.
## Placements stay inside the floor rect and clear of every character's avoidance radius,
## measured from the character's feet — the representation's ground contact, not the
## top-left corner its node position reports.

## Candidate grid pitch across the floor strip. One element at most per cell per entry, so
## this bounds how dense a fully-saturated entry can read.
const CELL_SIZE: float = 32.0

static func Generate(
		p_entries: Array[StageClutterEntry],
		p_floor_rect: Rect2,
		p_character_positions: Array[Vector2],
		p_seed: int) -> Array[DecorPlacement]:
	var placements: Array[DecorPlacement] = []
	if p_entries.is_empty() or p_floor_rect.size.x <= 0.0 or p_floor_rect.size.y <= 0.0:
		return placements

	var columns: int = ceili(p_floor_rect.size.x / CELL_SIZE)
	var rows: int = ceili(p_floor_rect.size.y / CELL_SIZE)

	for row in rows:
		for column in columns:
			var cell_origin: Vector2 = p_floor_rect.position + Vector2(column, row) * CELL_SIZE
			var cell_rect: Rect2 = Rect2(cell_origin, Vector2(CELL_SIZE, CELL_SIZE)).intersection(
					p_floor_rect)
			if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
				continue

			var cell_rng := RandomNumberGenerator.new()
			cell_rng.seed = hash([p_seed, column, row])
			var candidate: Vector2 = cell_rect.position + Vector2(
					cell_rng.randf() * cell_rect.size.x,
					cell_rng.randf() * cell_rect.size.y)

			for entry: StageClutterEntry in p_entries:
				if entry == null:
					continue
				if cell_rng.randf() > clampf(entry.density, 0.0, 1.0):
					continue
				if not _ClearsCharacters(candidate, p_character_positions,
						entry.character_avoidance_radius):
					continue
				placements.append(_BuildPlacement(entry, candidate, cell_rng))

	placements.sort_custom(_SortByY)
	return placements


static func _ClearsCharacters(
		p_point: Vector2,
		p_character_positions: Array[Vector2],
		p_radius: float) -> bool:
	if p_radius <= 0.0:
		return true
	for character_position: Vector2 in p_character_positions:
		if p_point.distance_to(character_position) < p_radius:
			return false
	return true


static func _BuildPlacement(
		p_entry: StageClutterEntry,
		p_point: Vector2,
		p_rng: RandomNumberGenerator) -> DecorPlacement:
	var placement := DecorPlacement.new()
	placement.texture = (p_entry.textures[p_rng.randi_range(0, p_entry.textures.size() - 1)]
			if not p_entry.textures.is_empty() else null)
	placement.position = p_point
	placement.scale = p_rng.randf_range(p_entry.scale_min, p_entry.scale_max)
	placement.rotation_degrees = p_rng.randf_range(
			-p_entry.rotation_jitter_degrees, p_entry.rotation_jitter_degrees)
	placement.flip_h = p_entry.allow_horizontal_flip and p_rng.randf() < 0.5
	placement.tint = p_entry.tint
	return placement


## Nearer clutter draws last so it overlaps what sits further up the strip.
static func _SortByY(p_a: DecorPlacement, p_b: DecorPlacement) -> bool:
	return p_a.position.y < p_b.position.y
