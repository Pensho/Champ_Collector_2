class_name AdventureNodePreview extends Control

signal engage_confirmed(p_node: NodeData)
signal cancelled

@export var _label_type: Label
@export var _label_cost: Label
@export var _label_desc: Label

var _node_data: NodeData

func Show(p_node: NodeData, p_supply_cost: int) -> void:
	_node_data = p_node
	match p_node.node_type:
		NodeData.Node_Type.FIGHT:
			_label_type.text = "Battle"
		NodeData.Node_Type.REST_STOP:
			_label_type.text = "Rest Stop"
		NodeData.Node_Type.BOSS:
			_label_type.text = "Boss"
		NodeData.Node_Type.HINT:
			_label_type.text = "Hint"
		NodeData.Node_Type.GAMBLE:
			_label_type.text = "Gamble"
		NodeData.Node_Type.ESCALATING:
			_label_type.text = "Escalating Challenge"
	match p_node.node_type:
		NodeData.Node_Type.FIGHT, NodeData.Node_Type.BOSS:
			_label_cost.text = "Cost: " + str(p_supply_cost) + " Supplies"
		_:
			_label_cost.text = ""
	_label_desc.text = ""
	visible = true

func _on_engage_button_up() -> void:
	engage_confirmed.emit(_node_data)
	visible = false

func _on_back_button_up() -> void:
	cancelled.emit()
	visible = false
