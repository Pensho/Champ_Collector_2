class_name AdventureEdgeLayer extends Control

## Draws the StructureLayout's roads, one Line2D per edge, textured from the biome's
## road_textures. Falls back to a thin untextured line when no biome visual data is
## configured, so the graph still renders.

const FALLBACK_LINE_COLOR := Color(0.55, 0.55, 0.55, 0.85)
const FALLBACK_LINE_WIDTH := 2.5
const ROAD_COLOR := Color(0.8, 0.8, 0.8, 1.0)

var _visual_data: BiomeVisualData
var _generation_seed: int = -1

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func configure(p_visual_data: BiomeVisualData, p_generation_seed: int) -> void:
	_visual_data = p_visual_data
	_generation_seed = p_generation_seed

func set_roads(p_layout: StructureLayout) -> void:
	for road_key in p_layout.roads:
		add_child(_BuildRoadLine(road_key, p_layout.roads[road_key]))

func _BuildRoadLine(p_road_key: Vector2i, p_points: PackedVector2Array) -> Line2D:
	var line := Line2D.new()
	line.points = p_points
	if _visual_data == null:
		line.width = FALLBACK_LINE_WIDTH
		line.default_color = FALLBACK_LINE_COLOR
		return line

	line.width = _visual_data.road_width if _visual_data.road_width > 0.0 else FALLBACK_LINE_WIDTH
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var textures: Array[Texture2D] = _visual_data.road_textures
	if textures.is_empty():
		line.default_color = FALLBACK_LINE_COLOR
		return line
	# Picked per edge from the seed, so it is stable across redraws.
	line.default_color = ROAD_COLOR
	var road_seed: int = StructureLayoutGenerator.RoadSeed(_generation_seed, p_road_key)
	line.texture = textures[posmod(hash([road_seed, "texture"]), textures.size())]
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return line
