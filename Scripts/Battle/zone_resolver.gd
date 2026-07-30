class_name ZoneResolver extends RefCounted

## Owns the per-combat zone lifecycle (placement, triggering, per-type effects,
## clearing). Holds a back-reference to its owning BattleResolver for the shared
## batch/emit/snapshot services zone effects need.

var _zones: Dictionary[int, Zone] = {}
var _resolver: BattleResolver

func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver

func GetZones() -> Dictionary[int, Zone]:
	return _zones

func HasZone(p_zone_ID: int) -> bool:
	return _zones.has(p_zone_ID)

func AvailableZoneIDs() -> Array[int]:
	var available: Array[int] = []
	for zone_number in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		if(not _zones.has(zone_number)):
			available.append(zone_number)
	return available

func PlaceZone(p_zone_ID: int, p_owner_ID: int, p_skill: Skill) -> Array[CombatResult]:
	_resolver._BeginBatch()
	if(_zones.has(p_zone_ID)):
		print("Zone is already used")
		return _resolver._EndBatch()
	var zone: Zone = Zone.new()
	zone.CreateNew(p_skill.skill_type, p_skill.duration, p_owner_ID, p_skill.target,
			_resolver._characters[p_owner_ID].GetTotalAttribute(Types.Attribute.Knowledge),
			p_skill.debuffs.get(p_skill.target, Types.Debuff_Type.Invalid))
	_zones[p_zone_ID] = zone
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Placed)
	result.zone_ID = p_zone_ID
	result.source_ID = p_owner_ID
	result.duration = zone._duration
	result.skill_type = zone._type
	_resolver._Emit(result)
	Skills.TriggerZoneConstructedHook(_resolver._characters, p_owner_ID, p_zone_ID, _resolver)
	return _resolver._EndBatch()

func SetZoneDuration(p_zone_ID: int, p_duration: int) -> void:
	if(not _zones.has(p_zone_ID)):
		return
	_zones[p_zone_ID]._duration = p_duration
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Duration_Changed)
	result.zone_ID = p_zone_ID
	result.duration = p_duration
	_resolver._Emit(result)

func ClearZone(p_zone_ID: int) -> void:
	if(not _zones.has(p_zone_ID)):
		return
	_zones[p_zone_ID].free()
	_zones.erase(p_zone_ID)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Cleared)
	result.zone_ID = p_zone_ID
	_resolver._Emit(result)

func TriggerZones(p_active_character_ID: int) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var characters: Dictionary[int, Character] = _resolver._characters
	var sides: CombatSides = _resolver._sides
	for character_ID in characters.keys():
		if(character_ID == p_active_character_ID or characters[character_ID]._current_health <= 0):
			continue
		for ID in _zones.keys():
			if(_zones[ID]._duration == 0):
				continue
			if(not _resolver._turn_positions.IsCharacterInZone(character_ID, ID)):
				continue
			if(not Skills.CorrectZoneTarget(_zones[ID]._owner_ID, character_ID, _zones[ID]._target, sides)):
				continue
			if(_resolver._HasBuff(character_ID, Types.Buff_Type.Slipstream)
					and sides.AreEnemies(character_ID, _zones[ID]._owner_ID)):
				continue
			var trigger_count: int = (
					2 if (_resolver._HasBuff(character_ID, Types.Buff_Type.Resonance)
							and sides.AreAllies(character_ID, _zones[ID]._owner_ID))
					else 1)
			for i in trigger_count:
				_ResolveZoneEffect(_zones[ID], ID, character_ID)
			_zones[ID]._duration -= 1
			var triggered: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Triggered)
			triggered.zone_ID = ID
			triggered.target_ID = character_ID
			triggered.duration = _zones[ID]._duration
			_resolver._Emit(triggered)
			# Restrict the trigger to one zone per character.
			break
	for ID in _zones.keys():
		if(_zones[ID]._duration == 0):
			_zones[ID].free()
			_zones.erase(ID)
	return _resolver._EndBatch()

func ReplenishZoneCharge(p_zone_ID: int, p_amount: int, p_max_charges: int) -> void:
	if(not _zones.has(p_zone_ID) or _zones[p_zone_ID]._duration >= p_max_charges):
		return
	SetZoneDuration(p_zone_ID, mini(_zones[p_zone_ID]._duration + p_amount, p_max_charges))

func _ResolveZoneEffect(p_zone: Zone, p_zone_ID: int, p_character_ID: int) -> void:
	var affected: Character = _resolver._characters[p_character_ID]
	var effect_multiplier: float = 1.0
	if(null != affected._trait):
		effect_multiplier = affected._trait.GetIncomingZoneEffectMultiplier(
				p_character_ID, p_zone._owner_ID, _resolver._sides)
	match p_zone._type:
		Types.Skill_Type.Flicker_Zone:
			_resolver._EmitTurnBarBump(p_character_ID,
					Skills.ZoneMagnitude(GameBalance.FLICKER_ZONE_BASE_BUMP, p_zone._owner_knowledge)
							* effect_multiplier, p_zone._owner_ID)
		Types.Skill_Type.Lava_Zone:
			if(Skills.HasMaxStatusEffects(affected)):
				return
			if(_resolver.GetStatusResolver()._ConsumeAegisIfPresent(p_character_ID, p_zone._owner_ID)):
				return
			var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_zone._debuff_type)
			var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			new_debuff.type = p_zone._debuff_type
			new_debuff.duration = data.duration_default if null != data else 0
			new_debuff.source_ID = p_zone._owner_ID
			new_debuff.value = (_resolver.GetStatusResolver()._SnapshotStatusValue(data, p_zone._owner_ID)
					* effect_multiplier)
			new_debuff.ID = _resolver._NextStatusID()
			affected._active_debuffs.append(new_debuff)
			_resolver.GetStatusResolver()._EmitDebuffApplied(p_character_ID, new_debuff, "")
		Types.Skill_Type.Barrier_Zone:
			Skills.ApplyBarrierZone(_resolver, p_zone._owner_ID, p_zone_ID, p_zone._owner_knowledge, p_character_ID)
		Types.Skill_Type.Spore_Zone:
			if(_resolver._sides.AreAllies(p_character_ID, p_zone._owner_ID)):
				var regeneration: StatusEffects.Buff = StatusEffects.Buff.new()
				regeneration.type = Types.Buff_Type.Regeneration
				regeneration.name = "Regeneration"
				regeneration.duration = 1
				regeneration.value = (Skills.ZoneMagnitude(
						StatusEffectRegistry.BuffData(Types.Buff_Type.Regeneration).magnitude, p_zone._owner_knowledge)
						* effect_multiplier)
				if(_resolver.GetStatusResolver().ApplyBuff(p_character_ID, regeneration).is_empty()):
					return
			else:
				var blight: StatusEffects.Debuff = StatusEffects.Debuff.new()
				blight.type = Types.Debuff_Type.Blight
				blight.duration = 1
				blight.source_ID = p_zone._owner_ID
				blight.value = (Skills.ZoneMagnitude(
						StatusEffectRegistry.DebuffData(Types.Debuff_Type.Blight).magnitude, p_zone._owner_knowledge)
						* effect_multiplier)
				if(_resolver.GetStatusResolver().ApplyDebuff(p_character_ID, blight).is_empty()):
					return
	var reactive: CharacterTrait = Skills.ActiveHook(affected, Types.Combat_Event.Zone_Affected)
	if(null != reactive):
		reactive.OnAffectedByZone(p_character_ID, p_zone._owner_ID, _resolver)
