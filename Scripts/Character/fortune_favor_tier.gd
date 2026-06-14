class_name FortuneFavorTier extends Resource

enum TierType
{
	BONE,
	BRASS,
	PARCHMENT,
}

@export var tier_type: TierType
@export var reward_count: int
@export var silver_weight: int
@export var silver_amount: int
@export var supplies_weight: int
@export var supplies_amount: int
@export var recruitable_champions: Array[CharacterPreset]
