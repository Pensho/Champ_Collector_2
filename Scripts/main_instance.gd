class_name Main_Instance extends Node



var _current_scene = null
var _character_collection: CharacterCollection
var _item_collection: ItemCollection
var _reagent_collection: ReagentCollection
var _resources: ResourceHandler
var _progress: ProgressHandler
var _shop: ShopHandler
var _tally_board: TallyBoardHandler
var _save_manager: SaveManager
var _adventure_state_handler: AdventureStateHandler

func Init() -> void:
	_current_scene = self
	_current_scene.name = "Main"
	print("current scene is: ", _current_scene)

	_character_collection = CharacterCollection.new()
	add_child(_character_collection)
	_item_collection = ItemCollection.new()
	add_child(_item_collection)
	_reagent_collection = ReagentCollection.new()
	add_child(_reagent_collection)
	_resources = ResourceHandler.new()
	add_child(_resources)
	_progress = ProgressHandler.new()
	add_child(_progress)
	_shop = ShopHandler.new()
	add_child(_shop)
	_tally_board = TallyBoardHandler.new()
	add_child(_tally_board)
	_save_manager = SaveManager.new()
	add_child(_save_manager)
	_adventure_state_handler = AdventureStateHandler.new()
	_adventure_state_handler.name = "AdventureStateHandler"
	add_child(_adventure_state_handler)
	_adventure_state_handler.add_to_group(SaveManager.GROUP_SAVEABLE)

	var context_container: ContextContainer = ContextContainer.new()

	var content_pool: ContentPool = GameModeRegistry.Active()
	print("build mode: ", content_pool.mode_name)
	for preset: CharacterPreset in content_pool.starting_champions:
		_character_collection.Add(preset.duplicate(true))
	for reagent_key: String in content_pool.RollStartingReagentKeys(StartingReagentCandidates(content_pool)):
		_reagent_collection.Add(reagent_key)

	context_container._scene = "uid://c6c1o3oabj0pf"
	change_scene(context_container)

## The reagents a new game may start with under p_content_pool: everything the pool allows
## that is not brew-only.
static func StartingReagentCandidates(p_content_pool: ContentPool) -> Array[String]:
	var candidate_keys: Array[String] = []
	for reagent_key: String in ReagentRegistry.REAGENTS.keys():
		var reagent: ReagentData = ReagentRegistry.REAGENTS[reagent_key]
		if(reagent.brew_only or not p_content_pool.AllowsReagent(reagent_key, reagent.rarity)):
			continue
		candidate_keys.append(reagent_key)
	return candidate_keys

func change_scene(p_context: ContextContainer) -> void:
	_deferred_change_scene(p_context)

func _deferred_change_scene(p_context: ContextContainer) -> void:
	if(_current_scene.name != "Main" and _current_scene.name != "RunFromEditor"):
		self.remove_child(_current_scene)
		_current_scene.call_deferred("free")

	var scene := ResourceLoader.load(p_context._scene)
	_current_scene = scene.instantiate()
	add_child(_current_scene)
	print("current scene is: ", _current_scene)
	_current_scene.Init(p_context)
