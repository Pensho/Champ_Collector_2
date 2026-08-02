class_name ConsumeBuffsEffect extends SkillEffect

## Consumes buffs from the effect's target group, accumulating the removed count onto
## context.buffs_consumed for a later DamageEffect scaling off Buffs_Consumed.

## -1 consumes every buff the target holds.
@export var count: int = -1

func Resolve(p_context: SkillCastContext) -> void:
	var status_resolver: StatusEffectResolver = p_context.resolver.GetStatusResolver()
	for target_ID in p_context.TargetsFor(self):
		p_context.buffs_consumed += status_resolver.ConsumeBuffs(target_ID, count)
