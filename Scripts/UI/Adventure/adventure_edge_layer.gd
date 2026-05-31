class_name AdventureEdgeLayer extends Control

const LINE_COLOR := Color(0.55, 0.55, 0.55, 0.85)
const LINE_WIDTH := 2.5
const NODE_HALF  := Vector2(40.0, 40.0)

var _edges: Array = []

func set_edges(p_edges: Array) -> void:
	_edges = p_edges
	queue_redraw()

func _draw() -> void:
	for edge in _edges:
		draw_line(edge[0] + NODE_HALF, edge[1] + NODE_HALF, LINE_COLOR, LINE_WIDTH, true)
