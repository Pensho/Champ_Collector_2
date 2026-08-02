class_name ZoneEffect extends SkillEffect

## Data shape for a skill's zone placement (duration and the debuffs a Lava-style zone
## applies on trigger), read by ZoneResolver.PlaceZone. Never appears in an effects
## array resolved by the generic skill loop — zone-target skills route straight to
## PlaceZone and carry no other effect.

@export var duration: int = 0
@export var debuffs: Array[Types.Debuff_Type]

func Resolve(_p_context: SkillCastContext) -> void:
	pass
