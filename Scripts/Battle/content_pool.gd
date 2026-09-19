class_name ContentPool extends Resource

## Restricts the content a build offers: which reagents and Relics random draws (loot drops,
## shop stock) may produce, which champions recruitment may offer, and the starting roster.
## Lookups by key, save loading and debug tools always see the full registries.

const PLAYTEST_FEATURE_TAG: String = "playtest"
const PLAYTEST_POOL_PATH: String = "res://Data/Loot_Tables/Playtest_Content_Pool.tres"
## Selects a build mode for a headless run (Tests/run_tests.sh's --mode flag sets
## this). Not a command-line argument: GUT's own CLI parser hard-quits on any
## argument it does not recognize, including one passed after "--".
const BUILD_MODE_ENV_VAR: String = "CHAMP_COLLECTOR_BUILD_MODE"

## Test-only override for Active(); see PinForTest() / ClearPin().
static var _pin_active: bool = false
static var _pinned_pool: ContentPool = null

## Reagent family names: a registry key without its rarity suffix, e.g. "Mending_Icon".
@export var reagent_families: Array[String] = []
@export var relic_keys: Array[String] = []
@export var starting_champions: Array[CharacterPreset] = []
## Narrows each Fortune's Favor tier to the champions it already lists that also appear here.
@export var recruitable_champions: Array[CharacterPreset] = []

static func PinForTest(p_pool: ContentPool) -> void:
	_pin_active = true
	_pinned_pool = p_pool

static func ClearPin() -> void:
	_pin_active = false
	_pinned_pool = null

## The pool random draws obey in this build, or null when nothing is restricted.
## Resolution order: a test pin (PinForTest), the BUILD_MODE_ENV_VAR environment
## variable, then the "playtest" feature tag.
static func Active() -> ContentPool:
	if(_pin_active):
		return _pinned_pool
	if(not _IsPlaytestMode()):
		return null
	return load(PLAYTEST_POOL_PATH)

static func _IsPlaytestMode() -> bool:
	if(OS.get_environment(BUILD_MODE_ENV_VAR) == PLAYTEST_FEATURE_TAG):
		return true
	return OS.has_feature(PLAYTEST_FEATURE_TAG)

func AllowsReagent(p_key: String, p_rarity: Types.Rarity) -> bool:
	var rarity_suffix: String = "_" + Types.Rarity.find_key(p_rarity)
	return reagent_families.has(p_key.trim_suffix(rarity_suffix))

func AllowsRelic(p_key: String) -> bool:
	return relic_keys.has(p_key)

func AllowsChampion(p_preset: CharacterPreset) -> bool:
	for allowed: CharacterPreset in recruitable_champions:
		if(allowed.resource_path == p_preset.resource_path):
			return true
	return false
