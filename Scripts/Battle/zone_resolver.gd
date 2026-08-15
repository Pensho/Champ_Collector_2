class_name ZoneResolver extends RefCounted

## Owns the per-combat zone lifecycle (placement, once-per-visit triggering, and
## clearing). A zone's own effect is data (Zone._on_trigger, authored on the placing
## skill's ZoneEffect) resolved through the same SkillCastContext/SkillEffect loop as
## any other skill, so this class has no per-zone-kind logic of its own. Holds a
## back-reference to its owning BattleResolver for the shared batch/emit/snapshot
## services zone effects need.

var _zones: Dictionary[int, Zone] = {}
var _resolver: BattleResolver

func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver

func GetZones() -> Dictionary[int, Zone]:
	return _zones

func HasZone(p_zone_ID: int) -> bool:
	return _zones.has(p_zone_ID)

## Unoccupied section indices, ascending — so the first entry is always the left-most
## free section, not merely section 0 (ZoneEffect.Section.Left_Most_Empty relies on
## this ordering).
func AvailableZoneIDs() -> Array[int]:
	var available: Array[int] = []
	for zone_number in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		if(not _zones.has(zone_number)):
			available.append(zone_number)
	return available

## p_owner_attributes should be the owner's full effective attributes (e.g.
## BattleResolver.GetEffectiveAttributes), snapshotted once at placement — an
## on_trigger effect may scale off any attribute, not only Knowledge, and this keeps
## that snapshot identical to what a live cast's own effects would see.
func PlaceZone(
		p_zone_ID: int,
		p_owner_ID: int,
		p_zone_effect: ZoneEffect,
		p_target: Types.Skill_Target,
		p_owner_attributes: Dictionary[Types.Attribute, int],
		p_source_name: String = "") -> Array[CombatResult]:
	_resolver._BeginBatch()
	if(_zones.has(p_zone_ID)):
		return _resolver._EndBatch()
	var zone: Zone = Zone.new()
	zone.CreateNew(p_zone_effect.charges, p_owner_ID, p_target, p_owner_attributes,
			p_zone_effect.on_trigger.duplicate(), p_zone_effect.visual_scene, p_source_name)
	_zones[p_zone_ID] = zone
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Placed)
	result.zone_ID = p_zone_ID
	result.source_ID = p_owner_ID
	result.charges = zone._charges
	result.visual_scene = zone._visual_scene
	_resolver._Emit(result)
	Skills.TriggerZoneConstructedHook(_resolver._characters, p_owner_ID, p_zone_ID, _resolver)
	return _resolver._EndBatch()

func SetZoneCharges(p_zone_ID: int, p_charges: int) -> void:
	if(not _zones.has(p_zone_ID)):
		return
	_zones[p_zone_ID]._charges = p_charges
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Charges_Changed)
	result.zone_ID = p_zone_ID
	result.charges = p_charges
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
	for zone_ID in _zones.keys():
		_ForgetDepartedVisitors(zone_ID)
	for character_ID in characters.keys():
		if(character_ID == p_active_character_ID or characters[character_ID]._current_health <= 0):
			continue
		for ID in _zones.keys():
			var zone: Zone = _zones[ID]
			if(zone._charges == 0):
				continue
			if(not _resolver._turn_positions.IsCharacterInZone(character_ID, ID)):
				continue
			if(zone._affected_since_entry.has(character_ID)):
				continue
			if(not Skills.CorrectZoneTarget(zone._owner_ID, character_ID, zone._target, sides)):
				continue
			if(_resolver._HasBuff(character_ID, Types.Buff_Type.Slipstream)
					and sides.AreEnemies(character_ID, zone._owner_ID)):
				continue
			var trigger_count: int = (
					2 if (_resolver._HasBuff(character_ID, Types.Buff_Type.Resonance)
							and sides.AreAllies(character_ID, zone._owner_ID))
					else 1)
			for i in trigger_count:
				_ResolveZoneEffect(zone, ID, character_ID)
			zone._affected_since_entry.append(character_ID)
			zone._charges -= 1
			var triggered: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Triggered)
			triggered.zone_ID = ID
			triggered.target_ID = character_ID
			triggered.charges = zone._charges
			_resolver._Emit(triggered)
			# Restrict the trigger to one zone per character.
			break
	for ID in _zones.keys().duplicate():
		if(_zones[ID]._charges == 0):
			ClearZone(ID)
			_resolver.BroadcastEvent(Types.Combat_Event.Resource_Depleted)
	return _resolver._EndBatch()

func _ForgetDepartedVisitors(p_zone_ID: int) -> void:
	var zone: Zone = _zones[p_zone_ID]
	for character_ID in zone._affected_since_entry.duplicate():
		if(not _resolver._turn_positions.IsCharacterInZone(character_ID, p_zone_ID)):
			zone._affected_since_entry.erase(character_ID)

func ReplenishZoneCharge(p_zone_ID: int, p_amount: int, p_max_charges: int) -> void:
	if(not _zones.has(p_zone_ID) or _zones[p_zone_ID]._charges >= p_max_charges):
		return
	SetZoneCharges(p_zone_ID, mini(_zones[p_zone_ID]._charges + p_amount, p_max_charges))

## Multiplies the zone's on_trigger damage by p_factor going forward, compounding with
## any prior call (e.g. the Sorcerer's Echo, which amplifies the zone its own cast placed
## once per Echo).
func AmplifyZoneDamage(p_zone_ID: int, p_factor: float) -> void:
	if(not _zones.has(p_zone_ID)):
		return
	_zones[p_zone_ID]._damage_multiplier *= p_factor

func _ResolveZoneEffect(p_zone: Zone, p_zone_ID: int, p_character_ID: int) -> void:
	var affected: Character = _resolver._characters[p_character_ID]
	var effect_multiplier: float = 1.0
	if(null != affected._trait):
		effect_multiplier = affected._trait.GetIncomingZoneEffectMultiplier(
				p_character_ID, p_zone._owner_ID, _resolver._sides)
	var context := SkillCastContext.new(_resolver, p_zone._owner_ID, [p_character_ID], null,
			p_zone._owner_attributes, 0, TraitSkillResult.new())
	context.is_zone_trigger = true
	context.zone_target = p_zone._target
	context.zone_ID = p_zone_ID
	context.zone_magnitude = Skills.ZoneMagnitude(1.0, p_zone._owner_knowledge) * effect_multiplier
	context.zone_source_name = p_zone._source_name
	context.zone_damage_multiplier = p_zone._damage_multiplier
	for effect in p_zone._on_trigger:
		if(context.ConditionMet(effect)):
			effect.Resolve(context)
	if(context.status_effect_attempted and not context.status_effect_landed):
		return
	if(affected._current_health <= 0):
		return
	var reactive: CharacterTrait = Skills.ActiveHook(affected, Types.Combat_Event.Zone_Affected)
	if(null != reactive):
		reactive.OnAffectedByZone(p_character_ID, p_zone._owner_ID, _resolver)
