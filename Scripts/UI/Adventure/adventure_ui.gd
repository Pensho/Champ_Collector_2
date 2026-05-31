extends Control

@export var _graph_ui: AdventureGraphUi
@export var _preview: AdventureNodePreview
#@export var _label_supplies: Label
@export var _label_steps: Label

var _state: AdventureState
var _hub_scene: String

func Init(p_context: ContextContainer) -> void:
	_state = p_context._adventure_state
	_hub_scene = p_context._arguments.get("Hub_Scene", "")
	_state.CheckDailyActivity()
	_UpdateHeader()
	_graph_ui.Populate(_state.nodes)
	_graph_ui.node_selected.connect(_on_node_selected)
	_preview.engage_confirmed.connect(_on_engage_confirmed)
	_preview.cancelled.connect(func(): _preview.visible = false)

func _UpdateHeader() -> void:
	#_label_supplies.text = "Supplies: " + str(main.GetInstance()._resources._supplies) + "/" + str(GameBalance.MAX_SUPPLIES)
	_label_steps.text = "Steps today: " + str(_state.steps_taken_today) + "/" + str(GameBalance.ADVENTURE_MAX_DAILY_STEPS)

func _on_node_selected(p_node: NodeData) -> void:
	_preview.Show(p_node, _state.GetNodeSupplyCost())

func _on_engage_confirmed(p_node: NodeData) -> void:
	_state.TakeStep()
	_state.current_node_index = p_node.index
	_UpdateHeader()
	var cc: ContextContainer = ContextContainer.new()
	cc._static_context = p_node.scene_context
	cc._previous_scene = "uid://mtv6bnpp8kjx"
	cc._arguments["Hub_Scene"] = _hub_scene
	cc._adventure_state = _state
	var completed: int = _state.nodes.filter(func(n: NodeData) -> bool: return n.is_complete).size()
	cc._arguments["Difficulty"] = AdventureState.CalculateScaledDifficulty(_state.difficulty, completed, _state.nodes.size())
	cc._arguments["Biome_Path"] = _state.biome.resource_path if _state.biome else ""
	cc._arguments["Is_Boss"] = p_node.node_type == NodeData.Node_Type.BOSS
	match p_node.node_type:
		NodeData.Node_Type.FIGHT, NodeData.Node_Type.BOSS:
			cc._scene = "uid://d3hg8jxy8xj8n"
		NodeData.Node_Type.REST_STOP:
			_graph_ui.Populate(_state.nodes)
			_preview.visible = false
			return
	main.GetInstance().change_scene(cc)

func _on_hub_button_up() -> void:
	var cc: ContextContainer = ContextContainer.new()
	cc._scene = _hub_scene
	main.GetInstance().change_scene(cc)
