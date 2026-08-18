class_name StealBuffEffect extends SkillEffect

## Steals count buffs from each of the effect's target group and re-applies them to a
## single recipient rolled once from the "to" group.

@export var count: int = 1
@export var to: Types.Skill_Target = Types.Skill_Target.Self
## -1 keeps each stolen buff's own remaining duration.
@export var duration_override: int = -1
@export var duration_bonus: int = 0

func Resolve(p_context: SkillCastContext) -> void:
	var resolver: BattleResolver = p_context.resolver
	var status_resolver: StatusEffectResolver = resolver.GetStatusResolver()
	var recipients: Array[int] = p_context.TargetsForGroup(to)
	if(recipients.is_empty()):
		return
	var recipient_ID: int = recipients[resolver.GetRandom().randi_range(0, recipients.size() - 1)]
	for target_ID in p_context.TargetsFor(self):
		for i in count:
			status_resolver.StealBuff(target_ID, recipient_ID, duration_override, duration_bonus)
