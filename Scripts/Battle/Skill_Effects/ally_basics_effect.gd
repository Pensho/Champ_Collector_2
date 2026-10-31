class_name AllyBasicsEffect extends SkillEffect

## Every living ally of the caster, the caster included, uses their basic skill against the
## effect's target at no cost. An ally under crowd control does not join.

func Resolve(p_context: SkillCastContext) -> void:
	var resolver: BattleResolver = p_context.resolver
	for target_ID in p_context.TargetsFor(self):
		var allies: Array[int] = resolver.GetSides().AlliesOf(p_context.caster_ID).AliveMembers(
				resolver.GetCharacters())
		for ally_ID in allies:
			if(not resolver.IsCrowdControlled(ally_ID)):
				resolver.GetStatusResolver().ResolveFreeBasic(ally_ID, target_ID)
