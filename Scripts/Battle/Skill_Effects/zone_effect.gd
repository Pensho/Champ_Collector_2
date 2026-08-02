class_name ZoneEffect extends SkillEffect

## Data shape for a skill's zone placement (duration and the debuffs a Lava-style zone
## applies on trigger). ZoneResolver.PlaceZone does not read this yet: zone placement
## still resolves duration and debuffs directly from Skill.

@export var duration: int = 0
@export var debuffs: Array[Types.Debuff_Type]

func Resolve(_p_context: SkillCastContext) -> void:
	pass
