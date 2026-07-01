class_name AdventureEdgeLayer extends Control

## Draws node-to-node connections as winding dirt roads: one Line2D per edge, wound by
## AdventureRoadGenerator and textured with a tiling dirt strip. Falls back to a straight
## untextured line when no biome visual data is configured, so the graph still renders.

const FALLBACK_LINE_COLOR := Color(0.55, 0.55, 0.55, 0.85)
const FALLBACK_LINE_WIDTH := 2.5
const ROAD_WIDTH := 16.0
const ROAD_COLOR := Color(0.8, 0.8, 0.8, 1.0)
const NODE_HALF := Vector2(40.0, 40.0)

## One is picked per edge (seeded, so it's stable across redraws) so neighbouring roads
## don't all read as the exact same tiled strip.
const ROAD_TEXTURES: Array[Texture2D] = [
	preload("res://Assets/Adventure/Background/Shared/dirt_road_01.png"),
	preload("res://Assets/Adventure/Background/Shared/dirt_road_02.png"),
	preload("res://Assets/Adventure/Background/Shared/dirt_road_03.png"),
]

var _edges: Array = []
var _visual_data: BiomeVisualData
var _generation_seed: int = -1

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func configure(p_visual_data: BiomeVisualData, p_generation_seed: int) -> void:
	_visual_data = p_visual_data
	_generation_seed = p_generation_seed

func set_edges(p_edges: Array) -> void:
	_edges = p_edges
	_Rebuild()

func _Rebuild() -> void:
	for edge in _edges:
		add_child(_BuildRoadLine(edge))

func _BuildRoadLine(p_edge: Array) -> Line2D:
	var from_position: Vector2 = p_edge[0] + NODE_HALF
	var to_position: Vector2 = p_edge[1] + NODE_HALF
	var line := Line2D.new()
	if _visual_data == null:
		line.points = PackedVector2Array([from_position, to_position])
		line.width = FALLBACK_LINE_WIDTH
		line.default_color = FALLBACK_LINE_COLOR
		return line

	var from_index: int = p_edge[2]
	var to_index: int = p_edge[3]
	var road_seed: int = hash([_generation_seed, from_index, to_index])
	line.points = AdventureRoadGenerator.BuildRoadPoints(from_position, to_position, _visual_data.detail_noise, road_seed)
	line.width = ROAD_WIDTH
	line.default_color = ROAD_COLOR
	line.texture = ROAD_TEXTURES[posmod(hash([road_seed, "texture"]), ROAD_TEXTURES.size())]
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	return line
