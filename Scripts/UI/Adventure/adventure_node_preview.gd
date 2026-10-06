class_name AdventureNodePreview extends Control

signal engage_confirmed(p_node: NodeData, p_preparation: CombatPreparation.Choice)
signal cancelled

@export var _label_type: Label
@export var _label_desc: Label
@export var _preparation_row: Control
@export var _card_prepare: PreparationCard
@export var _card_bait: PreparationCard
@export var _button_engage: Button

var _node_data: NodeData
var _preparation: CombatPreparation.Choice = CombatPreparation.Choice.NONE

func Show(p_node: NodeData) -> void:
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
		NodeData.Node_Type.ESCALATE:
			_label_type.text = "Escalate Challenge"
	_label_desc.text = ""
	_preparation = CombatPreparation.Choice.NONE
	_SetupPreparationCards()
	visible = true

func _SetupPreparationCards() -> void:
	var supplies: int = main.GetInstance()._resources.GetSupplies()
	var prepare_cost: int = CombatPreparation.Cost(CombatPreparation.Choice.PREPARE)
	var bait_cost: int = CombatPreparation.Cost(CombatPreparation.Choice.BAIT)
	_card_prepare.Setup("Prepare", "Team starts with +%d%% turn bar" % roundi(
			GameBalance.ADVENTURE_PREPARE_TURN_BAR_FRACTION * 100.0), prepare_cost, supplies >= prepare_cost)
	_card_bait.Setup("Bait", "Fight at +%d difficulty for better loot" % (
			GameBalance.ADVENTURE_BAIT_DIFFICULTY_INCREASE), bait_cost, supplies >= bait_cost)
	_card_prepare.visible = CombatPreparation.IsOffered(CombatPreparation.Choice.PREPARE, _node_data.node_type)
	_card_bait.visible = CombatPreparation.IsOffered(CombatPreparation.Choice.BAIT, _node_data.node_type)
	_preparation_row.visible = _card_prepare.visible or _card_bait.visible
	_RefreshPreparationChosen()

func _RefreshPreparationChosen() -> void:
	_card_prepare.SetChosen(_preparation == CombatPreparation.Choice.PREPARE)
	_card_bait.SetChosen(_preparation == CombatPreparation.Choice.BAIT)
	var cost: int = CombatPreparation.Cost(_preparation)
	_button_engage.text = "Engage (-%d Supplies)" % cost if cost > 0 else "Engage"

func _on_prepare_pressed() -> void:
	_preparation = CombatPreparation.Toggle(_preparation, CombatPreparation.Choice.PREPARE)
	_RefreshPreparationChosen()

func _on_bait_pressed() -> void:
	_preparation = CombatPreparation.Toggle(_preparation, CombatPreparation.Choice.BAIT)
	_RefreshPreparationChosen()

func _on_engage_button_up() -> void:
	engage_confirmed.emit(_node_data, _preparation)
	visible = false

func _on_back_button_up() -> void:
	cancelled.emit()
	visible = false
