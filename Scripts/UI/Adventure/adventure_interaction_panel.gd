class_name AdventureInteractionPanel extends Control

signal resolved

@export var _label_type: Label
@export var _label_description: Label
@export var _button_primary: Button
@export var _button_secondary: Button
@export var _button_tertiary: Button

var _node_data: NodeData
var _state: AdventureState

func Show(p_node: NodeData, p_state: AdventureState) -> void:
	_node_data = p_node
	_state = p_state
	_button_primary.hide()
	_button_secondary.hide()
	_button_tertiary.hide()
	_DisconnectAll(_button_primary.pressed)
	_DisconnectAll(_button_secondary.pressed)
	_DisconnectAll(_button_tertiary.pressed)

	match p_node.node_type:
		NodeData.Node_Type.REST_STOP:
			_ShowRestStop(p_node.scene_context as ContextRestStop)
		NodeData.Node_Type.HINT:
			_ShowHint(p_node.scene_context as ContextHint)
		NodeData.Node_Type.GAMBLE:
			_ShowGamble(p_node.scene_context as ContextGamble)
		NodeData.Node_Type.ESCALATING:
			_ShowEscalating(p_node.scene_context as ContextEscalating)
	visible = true

func _DisconnectAll(p_signal: Signal) -> void:
	for connection in p_signal.get_connections():
		p_signal.disconnect(connection["callable"])

func _ShowRestStop(p_context: ContextRestStop) -> void:
	_label_type.text = "Rest Stop"
	var buff_name: String = Types.Buff_Type.keys()[p_context.granted_buff]
	_label_description.text = "Choose how long to receive %s." % buff_name

	_button_primary.text = "%s for next combat (%d Supplies)" % [buff_name, GameBalance.ADVENTURE_REST_STOP_TIER_1_COST]
	_button_primary.disabled = false
	_button_primary.show()
	_button_primary.pressed.connect(_on_rest_stop_tier_chosen.bind(p_context, GameBalance.ADVENTURE_REST_STOP_TIER_1_COST, GameBalance.ADVENTURE_REST_STOP_TIER_1_COMBATS), CONNECT_ONE_SHOT)

	_button_secondary.text = "%s for next 3 combats (%d Supplies)" % [buff_name, GameBalance.ADVENTURE_REST_STOP_TIER_2_COST]
	_button_secondary.disabled = not _CanAfford(GameBalance.ADVENTURE_REST_STOP_TIER_2_COST)
	_button_secondary.show()
	_button_secondary.pressed.connect(_on_rest_stop_tier_chosen.bind(p_context, GameBalance.ADVENTURE_REST_STOP_TIER_2_COST, GameBalance.ADVENTURE_REST_STOP_TIER_2_COMBATS), CONNECT_ONE_SHOT)

	_button_tertiary.text = "%s for rest of adventure (%d Supplies)" % [buff_name, GameBalance.ADVENTURE_REST_STOP_TIER_3_COST]
	_button_tertiary.disabled = not _CanAfford(GameBalance.ADVENTURE_REST_STOP_TIER_3_COST)
	_button_tertiary.show()
	_button_tertiary.pressed.connect(_on_rest_stop_tier_chosen.bind(p_context, GameBalance.ADVENTURE_REST_STOP_TIER_3_COST, GameBalance.ADVENTURE_PERMANENT_EFFECT), CONNECT_ONE_SHOT)

func _CanAfford(p_cost: int) -> bool:
	return p_cost == 0 or main.GetInstance()._resources._supplies >= p_cost

func _on_rest_stop_tier_chosen(p_context: ContextRestStop, p_cost: int, p_combats: int) -> void:
	if p_cost > 0 and not main.GetInstance()._resources.SpendSupplies(p_cost):
		return
	_state.AddAdventureBuff(p_context.granted_buff, p_combats)
	_Resolve()

func _ShowHint(p_context: ContextHint) -> void:
	_label_type.text = "Hint"
	_label_description.text = p_context.hint_text

	_button_primary.text = "Continue"
	_button_primary.disabled = false
	_button_primary.show()
	_button_primary.pressed.connect(_on_hint_acknowledged.bind(p_context), CONNECT_ONE_SHOT)

func _on_hint_acknowledged(p_context: ContextHint) -> void:
	if p_context._loot_table != null:
		main.GetInstance()._resources._silver += p_context._loot_table._drop_result._silver
		main.GetInstance()._resources.AddSupplies(p_context._loot_table._drop_result._supplies)
	_Resolve()

func _ShowGamble(p_context: ContextGamble) -> void:
	_label_type.text = "Gamble"
	var buff_name: String = Types.Buff_Type.keys()[p_context.win_buff]
	var debuff_name: String = Types.Debuff_Type.keys()[p_context.loss_debuff]
	_label_description.text = "50/50: win %s for %d combats, or lose with %s for %d combats." % [
		buff_name, p_context.buff_combats, debuff_name, p_context.debuff_combats]

	_button_primary.text = "Take the gamble"
	_button_primary.disabled = false
	_button_primary.show()
	_button_primary.pressed.connect(_on_gamble_resolved.bind(p_context), CONNECT_ONE_SHOT)

	_button_secondary.text = "Decline"
	_button_secondary.disabled = false
	_button_secondary.show()
	_button_secondary.pressed.connect(_Resolve, CONNECT_ONE_SHOT)

func _on_gamble_resolved(p_context: ContextGamble) -> void:
	if randf() < 0.5:
		_state.AddAdventureBuff(p_context.win_buff, p_context.buff_combats)
		_label_description.text = "You won! Gained %s for %d combats." % [
			Types.Buff_Type.keys()[p_context.win_buff], p_context.buff_combats]
	else:
		_state.AddAdventureDebuff(p_context.loss_debuff, p_context.debuff_combats)
		_label_description.text = "You lost! Afflicted with %s for %d combats." % [
			Types.Debuff_Type.keys()[p_context.loss_debuff], p_context.debuff_combats]
	_button_primary.hide()
	_button_secondary.text = "Continue"
	_button_secondary.disabled = false
	_button_secondary.show()
	_button_secondary.pressed.connect(_Resolve, CONNECT_ONE_SHOT)

func _ShowEscalating(p_context: ContextEscalating) -> void:
	_label_type.text = "Escalating Challenge"
	var reward_silver: int = p_context._loot_table._drop_result._silver if p_context._loot_table != null else 0
	var reward_supplies: int = p_context._loot_table._drop_result._supplies if p_context._loot_table != null else 0
	_label_description.text = "Gain %d Silver and %d Supplies, but the rest of this adventure becomes permanently harder (+%d difficulty)." % [
		reward_silver, reward_supplies, p_context.difficulty_increase]

	_button_primary.text = "Accept"
	_button_primary.disabled = false
	_button_primary.show()
	_button_primary.pressed.connect(_on_escalating_accepted.bind(p_context), CONNECT_ONE_SHOT)

	_button_secondary.text = "Decline"
	_button_secondary.disabled = false
	_button_secondary.show()
	_button_secondary.pressed.connect(_Resolve, CONNECT_ONE_SHOT)

func _on_escalating_accepted(p_context: ContextEscalating) -> void:
	_state.difficulty += p_context.difficulty_increase
	if p_context._loot_table != null:
		main.GetInstance()._resources._silver += p_context._loot_table._drop_result._silver
		main.GetInstance()._resources.AddSupplies(p_context._loot_table._drop_result._supplies)
	_Resolve()

func _Resolve() -> void:
	visible = false
	resolved.emit()
