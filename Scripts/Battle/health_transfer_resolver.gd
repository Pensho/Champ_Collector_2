class_name HealthTransferResolver extends RefCounted

## Resolves Skill.health_change (a signed max-Health-fraction transfer) and
## Skill.heal_scaling (attribute-scaled healing). Holds a back-reference to its owning
## BattleResolver for the shared batch/emit/snapshot services these steps need,
## mirroring ZoneResolver and StatusEffectResolver.

var _resolver: BattleResolver

func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver

func ResolveHealthCosts(p_caster_ID: int, p_target_IDs: Array[int], p_skill: Skill) -> int:
	var status_resolver: StatusEffectResolver = _resolver.GetStatusResolver()
	var caster_paid: int = 0
	for target_type in p_skill.health_change.keys():
		var fraction: float = p_skill.health_change[target_type]
		if(fraction >= 0.0):
			continue
		for target_ID in status_resolver._ResolveStatusGroupTargets(p_caster_ID, p_target_IDs, p_skill, target_type):
			var requested: int = int(round(_resolver._MaxHealth(_resolver._characters[target_ID]) * -fraction))
			var paid: int = _resolver._ApplyHealthCost(target_ID, requested)
			if(paid > 0):
				var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
				result.target_ID = target_ID
				result.amount = paid
				_resolver._Emit(result)
			if(target_ID == p_caster_ID):
				caster_paid = paid
	return caster_paid

func ResolveHealthGains(
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var status_resolver: StatusEffectResolver = _resolver.GetStatusResolver()
	for target_type in p_skill.health_change.keys():
		var fraction: float = p_skill.health_change[target_type]
		if(fraction <= 0.0):
			continue
		for target_ID in status_resolver._ResolveStatusGroupTargets(p_caster_ID, p_target_IDs, p_skill, target_type):
			var requested: int = int(round(_resolver._MaxHealth(_resolver._characters[target_ID]) * fraction))
			_EmitHealthGain(target_ID, requested)

	for target_type in p_skill.heal_scaling.keys():
		var scaling: Dictionary = p_skill.heal_scaling[target_type]
		var requested: int = 0
		for attribute: Types.Attribute in scaling.keys():
			requested += int(round(float(scaling[attribute]) * float(p_caster_attributes[attribute])))
		for target_ID in status_resolver._ResolveStatusGroupTargets(p_caster_ID, p_target_IDs, p_skill, target_type):
			_EmitHealthGain(target_ID, requested)


func _EmitHealthGain(p_target_ID: int, p_requested: int) -> void:
	var healed: int = _resolver._ApplyHeal(p_target_ID, p_requested)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Heal)
	result.target_ID = p_target_ID
	result.amount = healed
	_resolver._Emit(result)
