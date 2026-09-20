class_name GameModeRegistry

## Every shipped game mode, as its ContentPool. Preload-based like the other registries
## (DirAccess-based discovery is unsafe on Android export), so a new mode is its resource
## plus one line here. Selecting one is ResolveModeName(); the pool it names is Active().

const POOLS: Array[ContentPool] = [
	preload("res://Data/Game_Modes/Full_Game_Content_Pool.tres"),
	preload("res://Data/Game_Modes/Playtest_Content_Pool.tres"),
]
## Selects a build mode for a headless run (Tests/run_tests.sh's --mode flag sets this).
## Not a command-line argument: GUT's own CLI parser hard-quits on any argument it does
## not recognize, including one passed after "--".
const BUILD_MODE_ENVIRONMENT_VARIABLE: String = "CHAMP_COLLECTOR_BUILD_MODE"
## Selects a build mode for editor play-runs, editable under Project Settings ->
## Champ Collector -> Build. Empty runs the default mode, so reaching any other mode
## always takes naming it here, in the environment variable, or in an export preset.
const BUILD_MODE_SETTING: String = "champ_collector/build/content_pool_mode"

## Test-only override for Active(); see PinForTest() / ClearPin().
static var _pinned_pool: ContentPool = null

static func PinForTest(p_pool: ContentPool) -> void:
	_pinned_pool = p_pool

static func ClearPin() -> void:
	_pinned_pool = null

## The pool this run obeys. A test pin wins; otherwise the mode ResolveModeName() names.
static func Active() -> ContentPool:
	if(null != _pinned_pool):
		return _pinned_pool
	var pool: ContentPool = _PoolForMode(ResolveModeName())
	if(null == pool):
		return DefaultPool()
	return pool

static func DefaultPool() -> ContentPool:
	for pool: ContentPool in POOLS:
		if(pool.is_default_mode):
			return pool
	push_error("No game mode is flagged as the default; falling back to %s." % POOLS[0].mode_name)
	return POOLS[0]

## The mode this run obeys, ignoring any test pin. The environment variable wins over the
## project setting, so a headless run can name its mode past whatever the editor is set to.
## Everything unset runs the default mode. These two sources are deliberate: both are
## inspectable as text, and a mode is never selected by anything the project does not state.
## An exported build carries its mode in the project setting baked into project.godot.
static func ResolveModeName() -> String:
	var environment_mode: String = OS.get_environment(BUILD_MODE_ENVIRONMENT_VARIABLE)
	if(not environment_mode.is_empty()):
		return _NormalizeModeName(environment_mode,
				"the %s environment variable" % BUILD_MODE_ENVIRONMENT_VARIABLE)
	var setting_mode: String = str(ProjectSettings.get_setting(BUILD_MODE_SETTING, ""))
	if(not setting_mode.is_empty()):
		return _NormalizeModeName(setting_mode, "the '%s' project setting" % BUILD_MODE_SETTING)
	return DefaultPool().mode_name

static func _PoolForMode(p_mode_name: String) -> ContentPool:
	for pool: ContentPool in POOLS:
		if(pool.mode_name == p_mode_name):
			return pool
	return null

static func _NormalizeModeName(p_mode: String, p_source_description: String) -> String:
	if(null != _PoolForMode(p_mode)):
		return p_mode
	var known_mode_names: Array[String] = []
	for pool: ContentPool in POOLS:
		known_mode_names.append(pool.mode_name)
	var default_mode_name: String = DefaultPool().mode_name
	push_warning("Unknown build mode '%s' from %s; running '%s'. Expected one of %s."
			% [p_mode, p_source_description, default_mode_name, ", ".join(known_mode_names)])
	return default_mode_name
