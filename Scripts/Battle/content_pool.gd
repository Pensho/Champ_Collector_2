class_name ContentPool extends Resource

## One game mode's content: which reagents and Relics random draws (loot drops, shop stock)
## may produce, which champions recruitment may offer, and what a new game starts with.
## Every mode has a pool, including the full game, so a mode is a resource rather than a
## branch. GameModeRegistry selects the one this run obeys.
## Lookups by key, save loading and debug tools always see the full registries.

## This mode's name wherever a mode can be selected: the build mode environment variable,
## the build mode project setting, and an export preset's custom feature tag.
@export var mode_name: String = ""
## The mode every unset selection source falls back to, and the one an unrecognized mode
## name falls back to. Exactly one shipped pool sets this.
@export var is_default_mode: bool = false
## Reagent family names: a registry key without its rarity suffix, e.g. "Mending_Icon".
@export var reagent_families: Array[String] = []
@export var relic_keys: Array[String] = []
@export var starting_champions: Array[CharacterPreset] = []
## Narrows each Fortune's Favor tier to the champions it already lists that also appear here.
@export var recruitable_champions: Array[CharacterPreset] = []
## How many reagents a new game starts with, drawn from this pool's own families.
@export var starting_reagent_count: int = 0

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

## starting_reagent_count draws, with repetition, from p_candidate_keys. The caller supplies
## the candidates rather than this resource reading ReagentRegistry: a pool's script must not
## depend on a registry that resolves a pool, or the pools preloaded by GameModeRegistry can
## load before this script does and arrive without it.
func RollStartingReagentKeys(p_candidate_keys: Array[String]) -> Array[String]:
	var drawn_keys: Array[String] = []
	if(starting_reagent_count <= 0 or p_candidate_keys.is_empty()):
		return drawn_keys
	for i: int in starting_reagent_count:
		drawn_keys.append(p_candidate_keys[randi_range(0, p_candidate_keys.size() - 1)])
	return drawn_keys
