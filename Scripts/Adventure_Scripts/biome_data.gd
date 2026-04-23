class_name BiomeData extends Resource

@export var factions: Types.Faction

# Each type of opponent shall be assigned a weight for how often/likely they should appear
@export var possible_opponents: Dictionary[CharacterPreset, int]
@export var possible_bosses: Array[CharacterPreset]

@export var possible_rewards: LootTable

# Should likely be a Dictionary[type, weight]
var possible_node_modifiers

# Should likely be a Dictionary[buff, cost]
var possible_rest_stop_buffs

# Probably another resource containing various UI elements to describe the biome
var visual_theme
