extends GutTest

const HUB_SCENE: String = "uid://cfdrcdtsx2jh7"

var _hub_act: ActData
var _hub_track: AudioStream
var _adventure_track: AudioStream
var _contexts: Array[ContextContainer] = []

func before_each() -> void:
	_hub_track = AudioStreamWAV.new()
	_adventure_track = AudioStreamWAV.new()
	_hub_act = ActData.new()
	_hub_act.music_track = _hub_track

func after_each() -> void:
	for context: ContextContainer in _contexts:
		context.free()
	_contexts.clear()

func _MakeContext(p_scene: String) -> ContextContainer:
	var context: ContextContainer = ContextContainer.new()
	context._scene = p_scene
	_contexts.append(context)
	return context

func _MakeAdventureState() -> AdventureState:
	var adventure: AdventureData = AdventureData.new()
	adventure.music_track = _adventure_track
	var state: AdventureState = AdventureState.new()
	state.adventure = adventure
	return state

func test_scene_outside_an_adventure_plays_the_hub_track() -> void:
	var context: ContextContainer = _MakeContext(HUB_SCENE)
	assert_eq(Main_Instance.MusicTrackFor(context, _hub_act), _hub_track)

func test_adventure_context_plays_the_adventure_track() -> void:
	var context: ContextContainer = _MakeContext(HUB_SCENE)
	context._adventure_state = _MakeAdventureState()
	assert_eq(Main_Instance.MusicTrackFor(context, _hub_act), _adventure_track)

func test_adventure_state_without_an_adventure_plays_the_hub_track() -> void:
	var context: ContextContainer = _MakeContext(HUB_SCENE)
	context._adventure_state = AdventureState.new()
	assert_eq(Main_Instance.MusicTrackFor(context, _hub_act), _hub_track)

func test_main_menu_is_silent() -> void:
	var context: ContextContainer = _MakeContext(Main_Instance.MAIN_MENU_SCENE)
	assert_null(Main_Instance.MusicTrackFor(context, _hub_act))

func test_save_load_screen_is_silent() -> void:
	var context: ContextContainer = _MakeContext(Main_Instance.SAVE_LOAD_SCENE)
	assert_null(Main_Instance.MusicTrackFor(context, _hub_act))
