class_name BiomeData extends Resource

@export var factions: Types.Faction

# Each type of opponent shall be assigned a weight for how often/likely they should appear
@export var possible_opponents: Dictionary[CharacterPreset, int]
@export var possible_bosses: Array[CharacterPreset]

@export var combat_rewards: LootTable
@export var boss_rewards: LootTable
@export var hint_rewards: LootTable
@export var escalate_rewards: LootTable

var possible_node_modifiers: Dictionary[String, int]
var possible_rest_stop_buffs: Dictionary[Types.Buff_Type, int]

# Probably another resource containing various UI elements to describe the biome
var visual_theme
