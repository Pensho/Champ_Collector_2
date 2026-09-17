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

## The champions this tier offers in this build; read this rather than recruitable_champions.
func RecruitableChampions(p_content_pool: ContentPool = ContentPool.Active()) -> Array[CharacterPreset]:
	if(null == p_content_pool):
		return recruitable_champions
	var champions: Array[CharacterPreset] = []
	for preset: CharacterPreset in recruitable_champions:
		if(p_content_pool.AllowsChampion(preset)):
			champions.append(preset)
	return champions
