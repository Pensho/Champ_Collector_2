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
