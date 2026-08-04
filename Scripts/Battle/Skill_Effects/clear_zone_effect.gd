class_name ClearZoneEffect extends SkillEffect

## Removes one zone from the turn bar (Refutation): a player-chosen section via the
## pending zone channel, or a random occupied one for an AI caster. If the zone was
## enemy-placed, damages the placing enemy scaling with Knowledge and the zone's
## remaining charges; if ally-placed (the owner's own zone included), reduces the
## placing ally's zone skill's cooldown.

@export var damage_scaling_per_charge: Dictionary[Types.Attribute, float] = {
	Types.Attribute.Knowledge: 0.1}
@export var cooldown_reduction: int = 2

func Resolve(p_context: SkillCastContext) -> void:
	var zone_resolver: ZoneResolver = p_context.resolver.GetZoneResolver()
	var zone_ID: int = _ResolveZoneID(p_context, zone_resolver)
	if(-1 == zone_ID or not zone_resolver.HasZone(zone_ID)):
		return
	var zone: Zone = zone_resolver.GetZones()[zone_ID]
	var owner_ID: int = zone._owner_ID
	var charges_remaining: int = zone._charges
	var source_name: String = zone._source_name
	var sides: CombatSides = p_context.resolver.GetSides()
	zone_resolver.ClearZone(zone_ID)
	if(sides.AreEnemies(p_context.caster_ID, owner_ID)):
		_DamagePlacer(p_context, owner_ID, charges_remaining)
	else:
		_ReduceZoneSkillCooldown(p_context.resolver, owner_ID, source_name)

func _DamagePlacer(p_context: SkillCastContext, p_owner_ID: int, p_charges_remaining: int) -> void:
	var scaling: Dictionary[Types.Attribute, float] = {}
	for attribute in damage_scaling_per_charge.keys():
		scaling[attribute] = damage_scaling_per_charge[attribute] * p_charges_remaining
	var combined_damage_modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	if(1.0 != p_context.trait_result._damage_multiplier):
		combined_damage_modifier.Contribute(
				CombinedDamageModifier.TRAIT_RESOURCE_KEY, p_context.trait_result._damage_multiplier - 1.0)
	p_context.resolver.ResolveEffectDamage(p_context.caster_ID, p_owner_ID, p_context.caster_attributes,
			scaling, 1.0, combined_damage_modifier)

func _ReduceZoneSkillCooldown(p_resolver: BattleResolver, p_owner_ID: int, p_source_name: String) -> void:
	if("" == p_source_name or not p_resolver.GetCharacters().has(p_owner_ID)):
		return
	for skill in p_resolver.GetCharacters()[p_owner_ID]._skills:
		if(p_source_name == skill.name):
			skill.cooldown_left = maxi(0, skill.cooldown_left - cooldown_reduction)
			return

func _ResolveZoneID(p_context: SkillCastContext, p_zone_resolver: ZoneResolver) -> int:
	var pending: int = p_context.resolver.ConsumePendingZoneSection()
	if(-1 != pending):
		return pending
	var occupied: Array[int] = p_zone_resolver.GetZones().keys()
	if(occupied.is_empty()):
		return -1
	return occupied[p_context.resolver.GetRandom().randi_range(0, occupied.size() - 1)]
