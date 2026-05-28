class_name AdventureGraphUi extends Control

signal node_selected(p_node: NodeData)

@export var _node_ui_scene: PackedScene
@export var _scroll_container: ScrollContainer
@export var _v_box: VBoxContainer

const NODE_ROW_HEIGHT: int = 96

func Populate(p_nodes: Array[NodeData]) -> void:
	for child in _v_box.get_children():
		child.queue_free()

	var by_depth: Dictionary = {}
	for node in p_nodes:
		if not by_depth.has(node.depth):
			by_depth[node.depth] = []
		by_depth[node.depth].append(node)

	var depths: Array = by_depth.keys()
	depths.sort()

	var eligible_row_index: int = 0
	var row_index: int = 0
	for depth in depths:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		for node_data: NodeData in by_depth[depth]:
			var is_eligible: bool = _IsEligible(node_data)
			var node_ui: AdventureNodeUi = _node_ui_scene.instantiate()
			row.add_child(node_ui)
			node_ui.Init(node_data, is_eligible)
			node_ui.node_selected.connect(node_selected.emit)
			if is_eligible and not node_data.is_complete:
				eligible_row_index = row_index
		_v_box.add_child(row)
		row_index += 1

	await get_tree().process_frame
	_scroll_container.scroll_vertical = eligible_row_index * NODE_ROW_HEIGHT

func _IsEligible(p_node: NodeData) -> bool:
	if p_node.previous_node.is_empty():
		return true
	for prev in p_node.previous_node:
		if not prev.is_complete:
			return false
	return true
