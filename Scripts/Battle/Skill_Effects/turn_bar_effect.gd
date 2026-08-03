class_name TurnBarEffect extends SkillEffect

## Bumps the effect's target group's turn bar by fraction (-1.0 - 1.0) — the skill's own
## contribution only. A trait hook's own turn-bar bump is turn machinery, not skill
## data, and is applied by ResolveSkill directly, independent of any authored effect.

@export var fraction: float = 0.0

func Resolve(p_context: SkillCastContext) -> void:
	for target_ID in p_context.TargetsFor(self):
		p_context.resolver.BumpTurnBar(target_ID, fraction * p_context.zone_magnitude, p_context.caster_ID)
