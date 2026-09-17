class_name ContentPool extends Resource

## Restricts the content a build offers: which reagents and Relics random draws (loot drops,
## shop stock) may produce, which champions recruitment may offer, and the starting roster.
## Lookups by key, save loading and debug tools always see the full registries.

const PLAYTEST_FEATURE_TAG: String = "playtest"
const PLAYTEST_POOL_PATH: String = "res://Data/Loot_Tables/Playtest_Content_Pool.tres"

## Reagent family names: a registry key without its rarity suffix, e.g. "Mending_Icon".
@export var reagent_families: Array[String] = []
@export var relic_keys: Array[String] = []
@export var starting_champions: Array[CharacterPreset] = []
## Narrows each Fortune's Favor tier to the champions it already lists that also appear here.
@export var recruitable_champions: Array[CharacterPreset] = []

## The pool random draws obey in this build, or null when nothing is restricted.
static func Active() -> ContentPool:
	if(not OS.has_feature(PLAYTEST_FEATURE_TAG)):
		return null
	return load(PLAYTEST_POOL_PATH)

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
