extends Control

@export var _graph_ui: AdventureGraphUi
@export var _preview: AdventureNodePreview
@export var _interaction_panel: AdventureInteractionPanel
#@export var _label_supplies: Label
@export var _label_steps: Label
@export var _label_effects: Label
@export var _button_finish: Button

var _state: AdventureState
var _hub_scene: String

func Init(p_context: ContextContainer) -> void:
	_state = p_context._adventure_state
	_hub_scene = p_context._arguments.get("Hub_Scene", "")
	_state.CheckDailyActivity()
	_UpdateHeader()
	if _state.biome != null:
		_graph_ui.SetBiomeVisuals(_state.biome.visual_data, _state._generation_seed)
	_graph_ui.Populate(_state.nodes)
	_graph_ui.node_selected.connect(_on_node_selected)
	_preview.engage_confirmed.connect(_on_engage_confirmed)
	_preview.cancelled.connect(func(): _preview.visible = false)
	_interaction_panel.resolved.connect(_on_interaction_resolved)
	if _IsBossComplete():
		_button_finish.show()

func _UpdateHeader() -> void:
	#_label_supplies.text = "Supplies: " + str(main.GetInstance()._resources._supplies)
	#		+ "/" + str(GameBalance.MAX_SUPPLIES)
	_label_steps.text = "Steps taken today: " + str(_state.steps_taken_today)
	var effect_parts: Array[String] = []
	for type: Types.Buff_Type in _state.active_buffs:
		var combats: int = _state.active_buffs[type]
		var remaining: String = "rest of adventure" if combats >= GameBalance.ADVENTURE_PERMANENT_EFFECT else str(combats)
		effect_parts.append("%s (%s)" % [Types.Buff_Type.keys()[type], remaining])
	for type: Types.Debuff_Type in _state.active_debuffs:
		var combats: int = _state.active_debuffs[type]
		var remaining: String = "rest of adventure" if combats >= GameBalance.ADVENTURE_PERMANENT_EFFECT else str(combats)
		effect_parts.append("%s (%s)" % [Types.Debuff_Type.keys()[type], remaining])
	_label_effects.text = "Active effects: " + ", ".join(effect_parts) if not effect_parts.is_empty() else ""

func _on_node_selected(p_node: NodeData) -> void:
	_preview.Show(p_node, _state.GetNodeSupplyCost())

func _on_engage_confirmed(p_node: NodeData) -> void:
	var supply_cost: int = _state.GetNodeSupplyCost()
	_state.TakeStep()
	_state.current_node_index = p_node.index
	_UpdateHeader()
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = p_node.scene_context
	context_container._previous_scene = "uid://mtv6bnpp8kjx"
	context_container._arguments["Hub_Scene"] = _hub_scene
	context_container._arguments["Supply_Cost"] = supply_cost
	context_container._adventure_state = _state
	var completed: int = _state.nodes.filter(func(n: NodeData) -> bool: return n.is_complete).size()
	context_container._arguments["Difficulty"] = AdventureState.CalculateScaledDifficulty(
			_state.difficulty, completed, _state.nodes.size())
	context_container._arguments["Biome_Path"] = _state.biome.resource_path if _state.biome else ""
	context_container._arguments["Is_Boss"] = p_node.node_type == NodeData.Node_Type.BOSS
	var difficulty: int = context_container._arguments["Difficulty"]
	match p_node.node_type:
		NodeData.Node_Type.FIGHT, NodeData.Node_Type.BOSS:
			context_container._scene = "uid://d3hg8jxy8xj8n"
		NodeData.Node_Type.REST_STOP, NodeData.Node_Type.HINT, NodeData.Node_Type.GAMBLE, NodeData.Node_Type.ESCALATE:
			_preview.visible = false
			_GrantNodeLoot(p_node, difficulty)
			_interaction_panel.Show(p_node, _state)
			return
	main.GetInstance().change_scene(context_container)

func _GrantNodeLoot(p_node: NodeData, p_difficulty: int) -> void:
	var ctx: Static_Context = p_node.scene_context
	var loot_table: LootTable
	var fraction: float
	match p_node.node_type:
		NodeData.Node_Type.HINT:
			loot_table = (ctx as ContextHint)._loot_table
			fraction = GameBalance.ADVENTURE_HINT_REWARD_BUDGET_FRACTION
		NodeData.Node_Type.ESCALATE:
			loot_table = (ctx as ContextEscalate)._loot_table
			fraction = GameBalance.ADVENTURE_ESCALATE_REWARD_BUDGET_FRACTION
		_:
			return
	if loot_table == null:
		return
	loot_table._budget = int(LootManager.CalculateBudget(p_difficulty) * fraction)
	loot_table._drop_result = LootTable.DropResult.new()
	LootManager.DistributeRewards(loot_table, p_difficulty)

func _on_interaction_resolved() -> void:
	_state.MarkCurrentNodeComplete()
	_graph_ui.Populate(_state.nodes)
	_UpdateHeader()

func _IsBossComplete() -> bool:
	for node in _state.nodes:
		if node.node_type == NodeData.Node_Type.BOSS and node.is_complete:
			return true
	return false

func _on_finish_adventure_button_up() -> void:
	main.GetInstance()._adventure_state_handler._state = AdventureState.new()
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cwjabuf3kdtft"
	context_container._previous_scene = _hub_scene
	main.GetInstance().change_scene(context_container)

func _on_hub_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = _hub_scene
	main.GetInstance().change_scene(context_container)
