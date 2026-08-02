class_name AlternatingEffect extends SkillEffect

## Cycles through effects by this cast's use_count, so a skill can behave differently
## on alternating (or any N-way rotating) casts — one effect per alternate.

@export var effects: Array[SkillEffect]

func Resolve(p_context: SkillCastContext) -> void:
	if(effects.is_empty()):
		return
	var effect: SkillEffect = effects[p_context.use_count % effects.size()]
	if(p_context.ConditionMet(effect)):
		effect.Resolve(p_context)
