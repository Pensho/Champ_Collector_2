class_name RemoveRandomDebuffEffect extends SkillEffect

## Removes one random active debuff from each of the effect's targets.

func Resolve(p_context: SkillCastContext) -> void:
	var resolver: BattleResolver = p_context.resolver
	for target_ID in p_context.TargetsFor(self):
		var debuffs: Array = resolver.GetCharacters()[target_ID]._active_debuffs
		if(debuffs.is_empty()):
			continue
		var index: int = resolver.GetRandom().randi_range(0, debuffs.size() - 1)
		resolver.GetStatusResolver().RemoveDebuff(target_ID, debuffs[index])
