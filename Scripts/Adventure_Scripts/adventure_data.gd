class_name AdventureData extends Resource

@export var display_name: String
@export var selection_texture: Texture2D

@export var layout: AdventureLayout
@export var biome: BiomeData

# Each battle variant is assigned a weight for how likely it is to appear on a FIGHT node
@export var battle_variants: Dictionary[Context_Battle, int]
@export var boss_battle_variants: Array[Context_Battle]

@export var combat_rewards: LootTable
@export var boss_rewards: LootTable
@export var hint_rewards: LootTable
@export var escalate_rewards: LootTable

@export var buff_pool: AdventureBuffPool
