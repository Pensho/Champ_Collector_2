class_name AdventureNodeUi extends Control

signal node_selected(p_node: NodeData)

const ICON_FIGHT := preload("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
const ICON_BOSS := preload("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Sea.png")

@export var _icon: TextureRect
@export var _button: Button

var _node_data: NodeData

func Init(p_node: NodeData, p_is_eligible: bool) -> void:
	_node_data = p_node
	# Modulate to indicate state
	if p_node.is_complete:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif p_is_eligible:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		modulate = Color(0.3, 0.3, 0.3, 0.6)
	_button.disabled = not p_is_eligible and not p_node.is_complete
	match p_node.node_type:
		NodeData.Node_Type.FIGHT:
			_icon.texture = ICON_FIGHT
		NodeData.Node_Type.BOSS:
			_icon.texture = ICON_BOSS

func _on_button_up() -> void:
	if not _node_data.is_complete:
		node_selected.emit(_node_data)
