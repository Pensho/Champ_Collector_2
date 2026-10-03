class_name AdventureData extends Resource

@export var display_name: String
@export var selection_texture: Texture2D

@export var layout: AdventureLayout
@export var biome: BiomeData

# Each type of opponent shall be assigned a weight for how often/likely they should appear
@export var possible_opponents: Dictionary[CharacterPreset, int]
@export var possible_bosses: Array[CharacterPreset]

@export var combat_rewards: LootTable
@export var boss_rewards: LootTable
@export var hint_rewards: LootTable
@export var escalate_rewards: LootTable
