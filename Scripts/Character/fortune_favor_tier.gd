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

@export_group("Reveal")
@export var silver_texture: Texture2D
@export var supplies_texture: Texture2D
## Dealt out shuffled to the panels that hold no reward, repeating only when they run out.
@export var empty_textures: Array[Texture2D]
## Reward effects are authored with emitting off; the reveal panel restarts each
## CPUParticles2D as it lands.
@export var silver_particles: PackedScene
@export var supplies_particles: PackedScene

## The champions this tier offers in this build; read this rather than recruitable_champions.
func RecruitableChampions(p_content_pool: ContentPool = GameModeRegistry.Active()) -> Array[CharacterPreset]:
	var champions: Array[CharacterPreset] = []
	for preset: CharacterPreset in recruitable_champions:
		if(p_content_pool.AllowsChampion(preset)):
			champions.append(preset)
	return champions
