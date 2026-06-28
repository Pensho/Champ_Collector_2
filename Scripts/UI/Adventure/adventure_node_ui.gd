class_name AdventureNodeUi extends Control

signal node_selected(p_node: NodeData)

const ICON_FIGHT := preload("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
const ICON_BOSS := preload("res://Assets/Adventure/Node_UI/Node_Icon_Boss.png")
const NODE_ICON_GAMBLE = preload("uid://ccshf1gvvumar")
const NODE_ICON_REST = preload("uid://bsn1u4nb0l2el")
const NODE_ICON_HINT = preload("uid://djln10dgso1ut")
const NODE_ICON_ESCALATE = preload("uid://bj0oacuyl1oti")

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
		NodeData.Node_Type.REST_STOP:
			_icon.texture = NODE_ICON_REST
		NodeData.Node_Type.HINT:
			_icon.texture = NODE_ICON_HINT
		NodeData.Node_Type.GAMBLE:
			_icon.texture = NODE_ICON_GAMBLE
		NodeData.Node_Type.ESCALATE:
			_icon.texture = NODE_ICON_ESCALATE

func _on_button_up() -> void:
	if not _node_data.is_complete:
		node_selected.emit(_node_data)
