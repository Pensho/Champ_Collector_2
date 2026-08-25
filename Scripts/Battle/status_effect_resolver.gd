class_name StatusEffectResolver extends RefCounted

## Owns the per-combat buff/debuff lifecycle: apply/cast/tick/expire, the block/consume/
## trigger rules bespoke to individual statuses, and the status-derived reads the damage
## and health paths need. Holds a back-reference to its owning BattleResolver for the
## shared batch/emit/snapshot services status effects need, mirroring ZoneResolver.

const MAX_SEA_LEGS_STACKS: int = 4

var _resolver: BattleResolver

func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver
	_RegisterCascadeListeners()


## Registers the cascade-channel statuses (Concept_Document.md 1.1.3) this resolver
## triggers off of. Code-registered rather than data-driven: with only a few listeners, a
## StatusEffectData schema field for this isn't warranted yet.
func _RegisterCascadeListeners() -> void:
	var cascade: CascadeResolver = _resolver.GetCascadeResolver()
	cascade.Subscribe(Types.Cascade_Trigger.Status_Expired,
			StringName(Types.Buff_Type.keys()[Types.Buff_Type.Overflow]),
			func(e: CascadeEvent) -> bool: return Types.Buff_Type.Overflow == e.buff_type,
			_CascadeOverflow)
	cascade.Subscribe(Types.Cascade_Trigger.Status_Expired,
			StringName(Types.Buff_Type.keys()[Types.Buff_Type.Rush]),
			func(e: CascadeEvent) -> bool: return Types.Buff_Type.Rush == e.buff_type,
			_CascadeRushStun)
	cascade.Subscribe(Types.Cascade_Trigger.Status_Landed,
			StringName(Types.Buff_Type.keys()[Types.Buff_Type.Mirror_Coat]),
			func(_e: CascadeEvent) -> bool: return true,
			_CascadeMirrorCoat)
	cascade.Subscribe(Types.Cascade_Trigger.Debuff_Ticked,
			&"Comorbidity",
			func(_e: CascadeEvent) -> bool: return true,
			_CascadeComorbidityRetick)
	cascade.Subscribe(Types.Cascade_Trigger.Skill_Resolved,
			StringName(Types.Buff_Type.keys()[Types.Buff_Type.Borrowed_Time]),
			func(e: CascadeEvent) -> bool:
				return (_resolver._HasBuff(e.subject_ID, Types.Buff_Type.Borrowed_Time)
						and _CastSkillHasDamageEffect(e.subject_ID, e.skill_ID)),
			_CascadeBorrowedTime)

func ApplyBuff(p_target_ID: int, p_buff_template: StatusEffects.Buff) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		_EmitStatusEffectDenied(p_target_ID, true, p_buff_template.type)
		return _resolver._EndBatch()
	var data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff_template.type)
	if(_BlockedBySequenceLock(data, target) or _BlockedBySeverance(target)):
		return _resolver._EndBatch()

	var new_value: float = (p_buff_template.value if 0.0 != p_buff_template.value
			else SnapshotStatusValue(data, p_buff_template.source_ID, p_target_ID))
	if(Types.Buff_Type.Barrier == p_buff_template.type
			and _KeepsExistingBarrier(p_target_ID, target, new_value)):
		return _resolver._EndBatch()

	_InsertOrRefresh(p_target_ID, true, p_buff_template.type, data, new_value, p_buff_template.duration,
			p_buff_template.source_ID, p_buff_template.trait_riders, false, p_buff_template.name)
	return _resolver._EndBatch()

func ApplyDebuff(p_target_ID: int, p_debuff_template: StatusEffects.Debuff) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		_EmitStatusEffectDenied(p_target_ID, false, p_debuff_template.type)
		return _resolver._EndBatch()
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_template.type)
	if(_BlockedBySequenceLock(data, target) or _BlockedByDebuffTypeBlock(target, p_debuff_template.type)):
		return _resolver._EndBatch()
	if(_ConsumeAegisIfPresent(p_target_ID, p_debuff_template.source_ID)):
		return _resolver._EndBatch()

	var new_value: float = (p_debuff_template.value if 0.0 != p_debuff_template.value
			else SnapshotStatusValue(data, p_debuff_template.source_ID, p_target_ID))
	_InsertOrRefresh(p_target_ID, false, p_debuff_template.type, data, new_value, p_debuff_template.duration,
			p_debuff_template.source_ID, p_debuff_template.trait_riders, false, p_debuff_template.name)
	return _resolver._EndBatch()

func ApplySeaLegs(
		p_target_ID: int,
		p_source_ID: int,
		p_attribute: Types.Attribute,
		p_value_per_stack: float) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	for buff in target._active_buffs:
		if(Types.Buff_Type.Sea_Legs == buff.type):
			var stacks: int = int(buff.trait_riders.get(&"stacks", 1))
			if(stacks >= MAX_SEA_LEGS_STACKS):
				return _resolver._EndBatch()
			stacks += 1
			buff.trait_riders[&"stacks"] = stacks
			buff.value = p_value_per_stack * stacks
			_EmitBuffApplied(p_target_ID, buff, buff.name)
			return _resolver._EndBatch()
	if(Skills.HasMaxStatusEffects(target)):
		_EmitStatusEffectDenied(p_target_ID, true, Types.Buff_Type.Sea_Legs)
		return _resolver._EndBatch()
	if(_BlockedBySeverance(target)):
		return _resolver._EndBatch()
	var trait_riders: Dictionary[StringName, Variant] = {&"attribute": p_attribute, &"stacks": 1}
	_InsertOrRefresh(p_target_ID, true, Types.Buff_Type.Sea_Legs,
			StatusEffectRegistry.BuffData(Types.Buff_Type.Sea_Legs), p_value_per_stack, 0,
			p_source_ID, trait_riders, false, "Sea Legs")
	return _resolver._EndBatch()

func RemoveBuff(p_target_ID: int, p_buff: StatusEffects.Buff) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	target._active_buffs.erase(p_buff)
	# A max-Health buff (e.g. Vigor) may have just been removed; reclamp to the new,
	# possibly smaller max.
	target._current_health = mini(target._current_health, _resolver._MaxHealth(target))
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
	result.target_ID = p_target_ID
	result.status_IDs = [p_buff.ID]
	_resolver._Emit(result)
	return _resolver._EndBatch()

func ReduceBuffDurations(p_target_ID: int, p_amount: int, p_source_ID: int = -1) -> void:
	if(p_amount <= 0):
		return
	var target: Character = _resolver._characters[p_target_ID]
	for buff in target._active_buffs:
		buff.duration -= p_amount
		_EmitStatusDuration(p_target_ID, buff.ID, buff.duration)
	_ExpireBuffs(p_target_ID, p_source_ID)

func ConsumeBuffs(p_target_ID: int, p_count: int) -> int:
	var target: Character = _resolver._characters[p_target_ID]
	var to_remove: Array[StatusEffects.Buff] = target._active_buffs.duplicate()
	if(p_count >= 0):
		to_remove = to_remove.slice(0, p_count)
	for buff in to_remove:
		RemoveBuff(p_target_ID, buff)
	return to_remove.size()

func StealBuff(p_from_ID: int, p_to_ID: int, p_duration: int = -1, p_duration_bonus: int = 0) -> bool:
	var source: Character = _resolver._characters[p_from_ID]
	if(source._active_buffs.is_empty()):
		return false
	var buff: StatusEffects.Buff = source._active_buffs[_resolver._random.randi() % source._active_buffs.size()]
	RemoveBuff(p_from_ID, buff)
	var stolen: StatusEffects.Buff = StatusEffects.Buff.new()
	stolen.type = buff.type
	stolen.value = buff.value
	stolen.duration = (p_duration if p_duration >= 0 else buff.duration) + p_duration_bonus
	stolen.name = buff.name
	ApplyBuff(p_to_ID, stolen)
	return true

func _ExpireBuffs(p_target_ID: int, p_source_ID: int = -1) -> void:
	var target: Character = _resolver._characters[p_target_ID]
	var status_IDs_to_be_removed: Array[int] = []
	for buff in target._active_buffs:
		if(_IsBuffExpired(buff)):
			status_IDs_to_be_removed.append(buff.ID)
	if(status_IDs_to_be_removed.is_empty()):
		return
	target._active_buffs = target._active_buffs.filter(func(buff): return not _IsBuffExpired(buff))
	var removed: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
	removed.target_ID = p_target_ID
	removed.source_ID = p_source_ID
	removed.status_IDs = status_IDs_to_be_removed
	_resolver._Emit(removed)
	target._current_health = mini(target._current_health, _resolver._MaxHealth(target))
	for i in status_IDs_to_be_removed.size():
		_resolver.BroadcastEvent(Types.Combat_Event.Resource_Depleted)

func _IsBuffExpired(p_buff: StatusEffects.Buff) -> bool:
	var data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff.type)
	if(null != data and data.permanent):
		return false
	# Both DamageMultiplier and Borrowed Time are one-shot, consumed-on-use buffs meant
	# to survive the holder's own next cast's start-of-cast decrement, not expire before
	# that cast's Skill_Resolved cascade gets a chance to consume them.
	if(null != data and (StatusEffectData.MagnitudeKind.DamageMultiplier == data.magnitude_kind
			or Types.Buff_Type.Borrowed_Time == p_buff.type)):
		return p_buff.duration < 0
	return p_buff.duration <= 0

func ConsumePremonitionIfPresent(p_target_ID: int, p_caster_ID: int) -> bool:
	var target: Character = _resolver._characters[p_target_ID]
	for buff in target._active_buffs:
		if(Types.Buff_Type.Premonition == buff.type):
			RemoveBuff(p_target_ID, buff)
			var missed: CombatResult = CombatResult.new(CombatResult.Kind.Attack_Missed)
			missed.target_ID = p_target_ID
			missed.source_ID = p_caster_ID
			_resolver._Emit(missed)
			_ResolvePremonitionCounter(p_target_ID, p_caster_ID)
			return true
	return false

## Answers the attack Premonition just negated with an immediate resolution of the
## holder's own basic skill against the attacker (Role_Kit_Design.md 9.16) — a full first
## resolution (trait hook, real use count, every effect), not the stripped repeat shape
## Borrowed Time and the Sorcerer's Echo use, since Premonition is generic across holders
## and its counter has to be faithful to whatever basic it triggers on. Everything past
## the effect loop in BattleResolver.ResolveSkill is deliberately skipped, which is what
## makes the counter cost the holder nothing: no cooldown, no turn-bar movement, no turn.
func _ResolvePremonitionCounter(p_holder_ID: int, p_attacker_ID: int) -> void:
	var holder: Character = _resolver._characters.get(p_holder_ID)
	if(null == holder or holder._current_health <= 0):
		return
	var attacker: Character = _resolver._characters.get(p_attacker_ID)
	if(null == attacker or attacker._current_health <= 0):
		return
	var basic: Skill = Skills.BasicSkill(holder)
	if(null == basic):
		return

	var attributes: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(p_holder_ID)
	var trait_result: TraitSkillResult = Skills.DispatchSkillCast(
			holder, p_holder_ID, [p_attacker_ID], basic.name, attributes, _resolver)

	var use_count: int = _resolver._SkillUseCount(p_holder_ID, basic)
	var context := SkillCastContext.new(
			_resolver, p_holder_ID, [p_attacker_ID], basic, attributes, use_count, trait_result)
	for effect in basic.effects:
		if(context.ConditionMet(effect)):
			effect.Resolve(context)

## Saves a character from a fatal hit by consuming their Deathward buff, if any.
func ConsumeDeathwardIfPresent(p_character_ID: int) -> bool:
	var character: Character = _resolver._characters[p_character_ID]
	for buff in character._active_buffs:
		if(Types.Buff_Type.Deathward == buff.type):
			RemoveBuff(p_character_ID, buff)
			return true
	return false

func ConsumeDamageMultiplierFactors(p_caster_ID: int) -> Dictionary[StringName, float]:
	var factors: Dictionary[StringName, float] = {}
	if(not _resolver._characters.has(p_caster_ID)):
		return factors
	var caster: Character = _resolver._characters[p_caster_ID]
	for buff in caster._active_buffs.duplicate():
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and StatusEffectData.MagnitudeKind.DamageMultiplier == data.magnitude_kind):
			var key: StringName = StringName(Types.Buff_Type.keys()[buff.type])
			factors[key] = factors.get(key, 0.0) + (buff.value - 1.0)
			RemoveBuff(p_caster_ID, buff)
	return factors

func HasBuffOfType(p_character_ID: int, p_type: Types.Buff_Type) -> bool:
	var character: Character = _resolver._characters[p_character_ID]
	for buff in character._active_buffs:
		if(p_type == buff.type):
			return true
	return false

## Consumes the character's Catalyst buff, if any, returning its potency bonus (0.0 if absent).
func ConsumeCatalystIfPresent(p_consumer_ID: int) -> float:
	var consumer: Character = _resolver._characters[p_consumer_ID]
	for buff in consumer._active_buffs:
		if(Types.Buff_Type.Catalyst == buff.type):
			var bonus: float = buff.value
			RemoveBuff(p_consumer_ID, buff)
			return bonus
	return 0.0


func CastDebuff(
		p_target_ID: int,
		p_debuff_template: StatusEffects.Debuff,
		p_caster_ID: int,
		p_trait_riders: Dictionary[StringName, Variant] = {},
		p_always_refresh_duration: bool = false,
		p_trigger_mirror_coat: bool = false) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		_EmitStatusEffectDenied(p_target_ID, false, p_debuff_template.type)
		return _resolver._EndBatch()

	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_template.type)
	if(_BlockedBySequenceLock(data, target) or _BlockedByDebuffTypeBlock(target, p_debuff_template.type)):
		return _resolver._EndBatch()
	if(_ConsumeAegisIfPresent(p_target_ID, p_caster_ID)):
		return _resolver._EndBatch()

	var target_resistance: int = _resolver.GetEffectiveAttributes(p_target_ID)[Types.Attribute.Resistance]
	var caster_accuracy: int = _resolver.GetEffectiveAttributes(p_caster_ID)[Types.Attribute.Accuracy]
	if(_RollsResistDebuff(p_target_ID, target_resistance, p_caster_ID, caster_accuracy)):
		var resisted: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Resisted)
		resisted.target_ID = p_target_ID
		resisted.source_ID = p_caster_ID
		_resolver._Emit(resisted)
		return _resolver._EndBatch()

	var value: float = (p_debuff_template.value if 0.0 != p_debuff_template.value
			else SnapshotStatusValue(data, p_caster_ID, p_target_ID))
	var caster: Character = _resolver._characters.get(p_caster_ID)
	var duration: int = p_debuff_template.duration
	if(duration > 0):
		duration += Skills.OutgoingDebuffDurationBonus(caster, p_caster_ID)
	var created: StatusEffects.Effect = _InsertOrRefresh(p_target_ID, false, p_debuff_template.type, data, value,
			duration, p_caster_ID, p_trait_riders, p_always_refresh_duration,
			Types.Debuff_Type.keys()[p_debuff_template.type])
	if(p_trigger_mirror_coat and null != created):
		var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Landed)
		event.subject_ID = p_target_ID
		event.origin_ID = p_caster_ID
		event.debuff_type = p_debuff_template.type
		_resolver.GetCascadeResolver().Post(event)
	return _resolver._EndBatch()

func _RollsResistDebuff(
		p_defender_ID: int,
		p_defender_resistance: int,
		p_attacker_ID: int,
		p_attacker_accuracy: int) -> bool:
	if(_resolver._HasDebuff(p_defender_ID, Types.Debuff_Type.Signed_Writ)):
		return false
	var attacker: Character = _resolver._characters.get(p_attacker_ID)
	if(Skills.DebuffsCannotBeResisted(attacker, p_attacker_ID, p_defender_ID)):
		return false
	var random_value: float = _resolver.RollFavoring(p_attacker_ID, 0.85, 1.0, true)
	var random_value_2: float = _resolver.RollFavoring(p_defender_ID, 0.85, 1.0, true)
	return p_attacker_accuracy * random_value < p_defender_resistance * random_value_2


## When a debuff lands on a holder with an active Mirror Coat, a copy of it is
## rolled against the attacker's own Resistance and applied directly if it lands.
func _CascadeMirrorCoat(p_event: CascadeEvent) -> void:
	var holder_ID: int = p_event.subject_ID
	var attacker_ID: int = p_event.origin_ID
	var debuff_type: Types.Debuff_Type = p_event.debuff_type
	if(not _resolver._HasBuff(holder_ID, Types.Buff_Type.Mirror_Coat) or holder_ID == attacker_ID
			or not _resolver._characters.has(attacker_ID) or _resolver._characters[attacker_ID]._current_health <= 0):
		return
	var holder_accuracy: int = _resolver.GetEffectiveAttributes(holder_ID)[Types.Attribute.Accuracy]
	var attacker_resistance: int = _resolver.GetEffectiveAttributes(attacker_ID)[Types.Attribute.Resistance]
	if(_RollsResistDebuff(attacker_ID, attacker_resistance, holder_ID, holder_accuracy)):
		var resisted: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Resisted)
		resisted.target_ID = attacker_ID
		resisted.source_ID = holder_ID
		_resolver._Emit(resisted)
		return
	if(Skills.HasMaxStatusEffects(_resolver._characters[attacker_ID])):
		_EmitStatusEffectDenied(attacker_ID, false, debuff_type)
		return
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff_type)
	var mirrored: StatusEffects.Debuff = StatusEffects.Debuff.new()
	mirrored.type = debuff_type
	mirrored.duration = data.duration_default if null != data else 0
	mirrored.source_ID = holder_ID
	mirrored.value = SnapshotStatusValue(data, holder_ID, attacker_ID)
	mirrored.ID = _resolver._NextStatusID()
	_resolver._characters[attacker_ID]._active_debuffs.append(mirrored)
	_EmitDebuffApplied(attacker_ID, mirrored, "")


func _TriggerExistingCasterDebuffs(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var caster: Character = _resolver._characters[p_caster_ID]
	var tick: Dictionary = _ComputeDebuffTickDamage(caster, p_caster_attributes)
	var status_IDs_to_be_removed: Array[int] = []
	for debuff in caster._active_debuffs:
		debuff.duration -= 1
		_EmitStatusDuration(p_caster_ID, debuff.ID, debuff.duration)
		if(debuff.duration <= 0):
			status_IDs_to_be_removed.append(debuff.ID)

	caster._active_debuffs = caster._active_debuffs.filter(func(debuff): return debuff.duration > 0)
	if(not status_IDs_to_be_removed.is_empty()):
		var removed: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
		removed.target_ID = p_caster_ID
		removed.status_IDs = status_IDs_to_be_removed
		_resolver._Emit(removed)

	_EmitDebuffTickIfAny(p_caster_ID, tick)
	_PostComorbidityCascadeIfAny(p_caster_ID, tick)

## Sums tick damage across p_target's active debuffs. With p_only_repeating_source_id left at
## -1, sums every ticking debuff at its own (unmultiplied) magnitude — Comorbidity's repeat is a
## separate cascade instance (see _CascadeComorbidityRetick), not a multiplier on this sum. Pass
## a source ID to instead sum only that source's Comorbidity-flagged debuffs, for resolving a
## single repeat instance.
func _ComputeDebuffTickDamage(
		p_target: Character,
		p_target_attributes: Dictionary[Types.Attribute, int],
		p_only_repeating_source_id: int = -1) -> Dictionary:
	var tick_damage_by_source: Dictionary[int, int] = {}
	var tick_damage_total: int = 0
	var repeating_source_ids: Dictionary[int, bool] = {}
	for debuff in p_target._active_debuffs:
		if(p_only_repeating_source_id >= 0
				and (not debuff.trait_riders.get(&"repeats_per_distinct_debuff", false)
						or debuff.source_ID != p_only_repeating_source_id)):
			continue
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null == data or not data.applies_on_self_tick):
			continue
		var tick_damage: int = 0
		match data.magnitude_kind:
			StatusEffectData.MagnitudeKind.MaxHealthPercent:
				var rolled_magnitude: float = data.magnitude
				if(data.magnitude_max > data.magnitude):
					rolled_magnitude = _resolver.RollFavoring(
							p_target._instance_ID, data.magnitude, data.magnitude_max, false)
				tick_damage = int(floor(
						(p_target_attributes[Types.Attribute.Health]
								* GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * rolled_magnitude))
			StatusEffectData.MagnitudeKind.CasterAttributeSnapshotPercent:
				tick_damage = int(floor(debuff.value))
			_:
				pass
		if(tick_damage <= 0):
			continue
		if(p_only_repeating_source_id < 0
				and debuff.trait_riders.get(&"repeats_per_distinct_debuff", false)):
			repeating_source_ids[debuff.source_ID] = true
		tick_damage_total += tick_damage
		tick_damage_by_source[debuff.source_ID] = tick_damage_by_source.get(debuff.source_ID, 0) + tick_damage
	return {
		"total": tick_damage_total,
		"by_source": tick_damage_by_source,
		"distinct_count": _DistinctDebuffTypeCount(p_target),
		"repeating_source_ids": repeating_source_ids.keys(),
	}

func _DistinctDebuffTypeCount(p_character: Character) -> int:
	var distinct_types: Dictionary[Types.Debuff_Type, bool] = {}
	for debuff in p_character._active_debuffs:
		distinct_types[debuff.type] = true
	return distinct_types.size()

func _EmitDebuffTickIfAny(p_target_ID: int, p_tick: Dictionary) -> void:
	var total: int = p_tick.get("total", 0)
	if(total <= 0):
		return
	var actual_total: int = _resolver._ApplyHealthLoss(p_target_ID, total)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Tick)
	result.target_ID = p_target_ID
	result.amount = actual_total
	result.amount_by_source = p_tick.get("by_source", {})
	_resolver._Emit(result)

## Comorbidity (Concept_Document.md 1.1.3's cascade channel): a debuff that carries
## repeats_per_distinct_debuff resolves one extra cascade instance per distinct debuff type on
## the target beyond itself, each instance re-ticking only that source's own flagged debuffs.
## Posted per source so two different casters' Comorbidity-flagged debuffs on the same target
## each get their own instances.
func _PostComorbidityCascadeIfAny(p_target_ID: int, p_tick: Dictionary) -> void:
	if(p_tick.get("total", 0) <= 0):
		return
	if(_resolver._characters[p_target_ID]._current_health <= 0):
		return
	var extra_instances: int = maxi(0, int(p_tick.get("distinct_count", 0)) - 1)
	if(extra_instances <= 0):
		return
	for source_ID in p_tick.get("repeating_source_ids", []):
		var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Debuff_Ticked)
		event.subject_ID = p_target_ID
		event.origin_ID = source_ID
		event.instance_count = extra_instances
		_resolver.GetCascadeResolver().Post(event)

## Resolves one Comorbidity cascade instance: re-ticks only p_event.origin_ID's own
## repeats_per_distinct_debuff-flagged debuffs on p_event.subject_ID, at their own unmultiplied
## magnitude. Does not itself post further cascade events — CascadeResolver's once-per-action
## dedup already covers the originating trigger.
func _CascadeComorbidityRetick(p_event: CascadeEvent) -> void:
	var target: Character = _resolver._characters.get(p_event.subject_ID)
	if(null == target or target._current_health <= 0):
		return
	var attributes: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(p_event.subject_ID)
	var tick: Dictionary = _ComputeDebuffTickDamage(target, attributes, p_event.origin_ID)
	_EmitDebuffTickIfAny(p_event.subject_ID, tick)

func _CastSkillHasDamageEffect(p_caster_ID: int, p_skill_ID: int) -> bool:
	var caster: Character = _resolver._characters.get(p_caster_ID)
	if(null == caster or p_skill_ID < 0 or p_skill_ID >= caster._skills.size()):
		return false
	for effect in caster._skills[p_skill_ID].effects:
		if(effect is DamageEffect):
			return true
	return false

func _CascadeBorrowedTime(p_event: CascadeEvent) -> void:
	var holder_ID: int = p_event.subject_ID
	var holder: Character = _resolver._characters.get(holder_ID)
	if(null == holder or holder._current_health <= 0):
		return
	var fraction: float = 0.0
	for buff in holder._active_buffs:
		if(Types.Buff_Type.Borrowed_Time == buff.type):
			fraction = buff.value
			RemoveBuff(holder_ID, buff)
			break
	if(0.0 == fraction):
		return
	var cast_skill: Skill = holder._skills[p_event.skill_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(holder_ID)
	var context := SkillCastContext.new(_resolver, holder_ID, p_event.target_IDs, cast_skill,
			caster_attributes, 0, TraitSkillResult.new())
	context.repeat_bonus = fraction - 1.0
	var resolved_any: bool = false
	for effect in cast_skill.effects:
		if(effect is DamageEffect and context.ConditionMet(effect)):
			resolved_any = true
			effect.Resolve(context)
	if(resolved_any):
		_resolver.EmitBurstInstance(&"Borrowed Time", holder_ID, Types.Cascade_Trigger.Skill_Resolved)


func ForceExtraDebuffTick(p_target_ID: int) -> void:
	var target: Character = _resolver._characters[p_target_ID]
	var attributes: Dictionary[Types.Attribute, int] = _resolver.GetEffectiveAttributes(p_target_ID)
	var tick: Dictionary = _ComputeDebuffTickDamage(target, attributes)
	_EmitDebuffTickIfAny(p_target_ID, tick)
	_PostComorbidityCascadeIfAny(p_target_ID, tick)


func _TriggerExistingCasterBuffs(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var caster: Character = _resolver._characters[p_caster_ID]
	var heal_total: int = 0
	var self_cost_total: int = 0
	var expiring_overflows: Array[StatusEffects.Buff] = []
	var expiring_rush_count: int = 0

	for buff in caster._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and data.applies_on_self_tick):
			match data.magnitude_kind:
				StatusEffectData.MagnitudeKind.MaxHealthPercent:
					heal_total += int(floor(
							(p_caster_attributes[Types.Attribute.Health]
									* GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * data.magnitude))
				StatusEffectData.MagnitudeKind.RandomAttributePercent:
					var attribute: Types.Attribute = ReagentResolver.RandomTinctureAttribute(_resolver._random)
					p_caster_attributes[attribute] += int(ceilf(p_caster_attributes[attribute] * data.magnitude))
				_:
					pass
			if(data.self_tick_max_health_cost_percent > 0.0):
				self_cost_total += int(ceil(
						(p_caster_attributes[Types.Attribute.Health]
								* GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * data.self_tick_max_health_cost_percent))

		if(null != data and data.permanent):
			continue
		buff.duration -= 1
		_EmitStatusDuration(p_caster_ID, buff.ID, buff.duration)
		if(buff.duration <= 0):
			if(Types.Buff_Type.Overflow == buff.type):
				expiring_overflows.append(buff)
			elif(Types.Buff_Type.Rush == buff.type):
				expiring_rush_count += 1

	_ExpireBuffs(p_caster_ID)

	# instance_count carries how many expired, rather than one Post per entry — the
	# once-per-(mechanic, subject) dedup rule would otherwise collapse a second Post for
	# the same holder down to a single instance.
	if(not expiring_overflows.is_empty()):
		var overflow_event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
		overflow_event.subject_ID = p_caster_ID
		overflow_event.buff_type = Types.Buff_Type.Overflow
		overflow_event.instance_count = expiring_overflows.size()
		_resolver.GetCascadeResolver().Post(overflow_event)

	if(expiring_rush_count > 0):
		var rush_event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
		rush_event.subject_ID = p_caster_ID
		rush_event.buff_type = Types.Buff_Type.Rush
		rush_event.instance_count = expiring_rush_count
		_resolver.GetCascadeResolver().Post(rush_event)

	if(heal_total > 0):
		var healed: int = _resolver._ApplyHeal(p_caster_ID, heal_total)
		var heal_result: CombatResult = CombatResult.new(CombatResult.Kind.Heal)
		heal_result.target_ID = p_caster_ID
		heal_result.amount = healed
		_resolver._Emit(heal_result)

	if(self_cost_total > 0 and caster._current_health > 0):
		var actual_self_cost: int = _resolver._ApplyHealthLoss(p_caster_ID, self_cost_total)
		var cost_result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
		cost_result.target_ID = p_caster_ID
		cost_result.amount = actual_self_cost
		_resolver._Emit(cost_result)


func _BlockedBySequenceLock(p_data: StatusEffectData, p_target: Character) -> bool:
	if(null == p_data or not p_data.attribute_modifiers.has(Types.Attribute.Speed)):
		return false
	for debuff in p_target._active_debuffs:
		if(Types.Debuff_Type.Sequence_Lock == debuff.type):
			return true
	return false

func _BlockedByDebuffTypeBlock(p_target: Character, p_debuff_type: Types.Debuff_Type) -> bool:
	for source: CharacterTrait in p_target.HookSources():
		if(source.BlocksIncomingDebuffType(p_debuff_type)):
			return true
	return false


func _BlockedBySeverance(p_target: Character) -> bool:
	for debuff in p_target._active_debuffs:
		if(Types.Debuff_Type.Severance == debuff.type):
			return true
	return false


## Blocks one incoming debuff by consuming the target's Aegis buff, if any.
func _ConsumeAegisIfPresent(p_target_ID: int, p_source_ID: int) -> bool:
	var target: Character = _resolver._characters[p_target_ID]
	for buff in target._active_buffs:
		if(Types.Buff_Type.Aegis == buff.type):
			RemoveBuff(p_target_ID, buff)
			var blocked: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Blocked)
			blocked.target_ID = p_target_ID
			blocked.source_ID = p_source_ID
			_resolver._Emit(blocked)
			return true
	return false


## Consumes the caster's Rehearsed buff, if any, reporting whether cooldown
## assignment should be skipped for the skill just cast.
func _ConsumeRehearsedIfPresent(p_caster_ID: int) -> bool:
	for buff in _resolver._characters[p_caster_ID]._active_buffs:
		if(Types.Buff_Type.Rehearsed == buff.type):
			RemoveBuff(p_caster_ID, buff)
			return true
	return false


func _InsertOrRefresh(
		p_target_ID: int,
		p_is_buff: bool,
		p_type: int,
		p_data: StatusEffectData,
		p_value: float,
		p_duration: int,
		p_source_ID: int,
		p_trait_riders: Dictionary[StringName, Variant],
		p_always_refresh_duration: bool,
		p_display_name: String) -> StatusEffects.Effect:
	var target: Character = _resolver._characters[p_target_ID]
	var active: Array = target._active_buffs if p_is_buff else target._active_debuffs

	if(not p_is_buff and p_duration > 0):
		p_duration += Skills.IncomingDebuffDurationBonus(target, p_target_ID)

	if(null != p_data and Skills.IsAmplifiableKind(p_data.magnitude_kind)):
		var amplification: float = Skills.AppliedAttributeAmplification(
				p_source_ID, _resolver._characters, _resolver.GetSides())
		if(amplification > 0.0):
			# Duplicated so the stamp never leaks onto the caster's own shared
			# trait_result._trait_riders dictionary, which several callers pass by
			# reference across multiple targets.
			p_trait_riders = p_trait_riders.duplicate()
			p_trait_riders[&"attribute_amplification"] = amplification

	if(null == p_data or not p_data.stackable):
		for i in active.size():
			if(active[i].type == p_type):
				if(null == p_data or p_data.overwritable):
					if(p_always_refresh_duration or p_duration > active[i].duration):
						active[i].duration = p_duration
						active[i].trait_riders = p_trait_riders
						_EmitStatusDuration(p_target_ID, active[i].ID, p_duration)
				return null

	if(p_is_buff):
		var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
		new_buff.type = p_type as Types.Buff_Type
		new_buff.duration = p_duration
		new_buff.name = p_display_name
		new_buff.value = p_value
		new_buff.source_ID = p_source_ID
		new_buff.trait_riders = p_trait_riders
		new_buff.ID = _resolver._NextStatusID()
		target._active_buffs.append(new_buff)
		_EmitBuffApplied(p_target_ID, new_buff, p_display_name)
		return new_buff

	var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	new_debuff.type = p_type as Types.Debuff_Type
	new_debuff.duration = p_duration
	new_debuff.name = p_display_name
	new_debuff.source_ID = p_source_ID
	new_debuff.value = p_value
	new_debuff.trait_riders = p_trait_riders
	new_debuff.ID = _resolver._NextStatusID()
	target._active_debuffs.append(new_debuff)
	_EmitDebuffApplied(p_target_ID, new_debuff, p_display_name)
	return new_debuff


func _KeepsExistingBarrier(p_target_ID: int, p_target: Character, p_new_value: float) -> bool:
	for buff in p_target._active_buffs:
		if(Types.Buff_Type.Barrier == buff.type):
			if(buff.value >= p_new_value):
				return true
			RemoveBuff(p_target_ID, buff)
			return false
	return false


## Deals Mysticism-scaled damage to a Mana Burn holder when they cast a non-basic skill.
func _TriggerManaBurn(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_is_non_basic: bool) -> void:
	if(not p_is_non_basic):
		return
	var caster: Character = _resolver._characters[p_caster_ID]
	for debuff in caster._active_debuffs:
		if(Types.Debuff_Type.Mana_Burn == debuff.type):
			var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Mana_Burn)
			var damage: int = int(floor(p_caster_attributes[Types.Attribute.Mysticism] * data.magnitude))
			if(damage > 0):
				var actual_damage: int = _resolver._ApplyHealthLoss(p_caster_ID, damage)
				var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
				result.source_ID = debuff.source_ID
				result.target_ID = p_caster_ID
				result.amount = actual_damage
				_resolver._Emit(result)
			return


## Deals Mysticism-scaled damage to every living enemy when Overflow expires.
func _CascadeOverflow(p_event: CascadeEvent) -> void:
	var holder_ID: int = p_event.subject_ID
	var side: CombatTeam = _resolver._sides.EnemiesOf(holder_ID)
	if(null == side):
		return
	var data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Overflow)
	_resolver.ResolveTraitDamage(holder_ID, side.AliveMembers(_resolver._characters),
			_resolver.GetEffectiveAttributes(holder_ID), {Types.Attribute.Mysticism: data.magnitude})


func _CascadeRushStun(p_event: CascadeEvent) -> void:
	var holder_ID: int = p_event.subject_ID
	if(Skills.HasMaxStatusEffects(_resolver._characters[holder_ID])):
		_EmitStatusEffectDenied(holder_ID, false, Types.Debuff_Type.Stun)
		return
	var stun: StatusEffects.Debuff = StatusEffects.Debuff.new()
	stun.type = Types.Debuff_Type.Stun
	stun.duration = 1
	stun.source_ID = holder_ID
	stun.ID = _resolver._NextStatusID()
	_resolver._characters[holder_ID]._active_debuffs.append(stun)
	_EmitDebuffApplied(holder_ID, stun, "")


func SnapshotStatusValue(p_data: StatusEffectData, p_source_ID: int, p_target_ID: int) -> float:
	if(null == p_data):
		return 0.0
	var reads_source_attributes: bool = (p_data.caster_scaled
			or StatusEffectData.MagnitudeKind.CasterAttributeSnapshotPercent == p_data.magnitude_kind)
	if(reads_source_attributes):
		if(not _resolver._characters.has(p_source_ID)):
			return 0.0
		var source_attributes: Dictionary[Types.Attribute, int] = _resolver._characters[p_source_ID].GetTotalAttributes()
		_resolver._ApplyLongAttributeBonus(p_source_ID, source_attributes)
		var value: float = 0.0
		if(p_data.caster_scaled):
			for attribute in p_data.attribute_modifiers.keys():
				value += p_data.magnitude * absf(p_data.attribute_modifiers[attribute]) * float(source_attributes[attribute])
			return value
		for attribute in p_data.attribute_modifiers.keys():
			value += p_data.magnitude * float(source_attributes[attribute])
		var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
		_resolver._ContributePersistentCasterFactors(p_source_ID, p_target_ID, modifier)
		return value * modifier.Product()
	if(StatusEffectData.MagnitudeKind.TurnBarMovementDamagePercent == p_data.magnitude_kind):
		var leak_modifier: CombinedDamageModifier = CombinedDamageModifier.new()
		_resolver._ContributePersistentCasterFactors(p_source_ID, p_target_ID, leak_modifier)
		return leak_modifier.Product()
	return p_data.magnitude


func _AttackerCritChanceBonus(p_target: Character) -> int:
	var bonus: int = 0
	for debuff in p_target._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and StatusEffectData.MagnitudeKind.AttackerCritChanceBonus == data.magnitude_kind):
			bonus += int(debuff.value)
	return bonus


func _AttackerCritDamageBonus(p_target: Character) -> int:
	var bonus: int = 0
	for debuff in p_target._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and StatusEffectData.MagnitudeKind.AttackerCritDamageBonus == data.magnitude_kind):
			bonus += int(debuff.value)
	return bonus


func _OpportunistDamageFactors(p_caster_ID: int, p_target: Character) -> Dictionary[StringName, float]:
	var factors: Dictionary[StringName, float] = {}
	if(not _resolver._characters.has(p_caster_ID)):
		return factors
	var has_opportunist: bool = false
	var opportunist_value: float = 0.0
	for buff in _resolver._characters[p_caster_ID]._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and StatusEffectData.MagnitudeKind.PerTargetDebuffDamagePercent == data.magnitude_kind):
			has_opportunist = true
			opportunist_value = buff.value
			break
	if(not has_opportunist):
		return factors
	var debuff_types_present: Dictionary[Types.Debuff_Type, bool] = {}
	for debuff in p_target._active_debuffs:
		debuff_types_present[debuff.type] = true
	for debuff_type in debuff_types_present:
		var key: StringName = StringName(Types.Debuff_Type.keys()[debuff_type])
		factors[key] = factors.get(key, 0.0) + opportunist_value
	return factors

func _MissingHealthFraction(p_character_ID: int) -> float:
	var max_health: int = _resolver.GetMaxHealth(p_character_ID)
	if(max_health <= 0):
		return 0.0
	var character: Character = _resolver._characters[p_character_ID]
	return clampf(1.0 - float(character._current_health) / float(max_health), 0.0, 1.0)

func _MissingHealthDamageFactors(
		p_caster_ID: int, p_target_ID: int, p_target: Character) -> Dictionary[StringName, float]:
	var factors: Dictionary[StringName, float] = {}
	if(_resolver._characters.has(p_caster_ID)):
		for buff in _resolver._characters[p_caster_ID]._active_buffs:
			var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
			if(null != data and StatusEffectData.MagnitudeKind.HolderMissingHealthDamagePercent == data.magnitude_kind):
				var contribution: float = buff.value * _MissingHealthFraction(p_caster_ID)
				if(0.0 != contribution):
					var key: StringName = StringName(Types.Buff_Type.keys()[buff.type])
					factors[key] = factors.get(key, 0.0) + contribution
	for debuff in p_target._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and StatusEffectData.MagnitudeKind.AttackerDamagePerHolderMissingHealth == data.magnitude_kind):
			var contribution: float = debuff.value * _MissingHealthFraction(p_target_ID)
			if(0.0 != contribution):
				var key: StringName = StringName(Types.Debuff_Type.keys()[debuff.type])
				factors[key] = factors.get(key, 0.0) + contribution
	return factors

## Debuffs on p_target whose value (usually snapshotted at application, e.g. Sanction's
## Infraction tally) scales the attacker's own damage, independent of magnitude_kind.
func _DebuffValueDamageFactors(p_target: Character) -> Dictionary[StringName, float]:
	var factors: Dictionary[StringName, float] = {}
	for debuff in p_target._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null == data or 0.0 == data.attacker_damage_value_multiple):
			continue
		var contribution: float = debuff.value * data.attacker_damage_value_multiple
		if(0.0 != contribution):
			var key: StringName = StringName(Types.Debuff_Type.keys()[debuff.type])
			factors[key] = factors.get(key, 0.0) + contribution
	return factors


func _DamageTakenMultiplier(p_character: Character) -> float:
	var multiplier: float = 1.0
	for buff in p_character._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and StatusEffectData.MagnitudeKind.IncomingDamageReduction == data.magnitude_kind):
			multiplier -= (buff.value if 0.0 != buff.value else data.magnitude)
	return maxf(multiplier, 0.0)


func _HealingMultiplier(p_character_ID: int) -> float:
	var character: Character = _resolver._characters[p_character_ID]
	var multiplier: float = 1.0
	for debuff in character._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and StatusEffectData.MagnitudeKind.IncomingHealReduction == data.magnitude_kind):
			multiplier -= (debuff.value if 0.0 != debuff.value else data.magnitude)
	var trait_multiplier: float = Skills.IncomingHealMultiplier(character, p_character_ID)
	return maxf(multiplier * trait_multiplier, 0.0)


func _TriggerDamageTakenReactions(p_character_ID: int, p_attacker_ID: int = BattleResolver.NO_ATTACKER) -> void:
	if(BattleResolver.NO_ATTACKER != p_attacker_ID):
		var character: Character = _resolver._characters[p_character_ID]
		for debuff in character._active_debuffs:
			if(Types.Debuff_Type.Dead_Weight == debuff.type):
				var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Dead_Weight)
				_resolver._EmitTurnBarBump(p_character_ID, -data.magnitude)
				break
		for buff in character._active_buffs:
			if(Types.Buff_Type.Battle_Orders == buff.type):
				var data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Battle_Orders)
				var allies: CombatTeam = _resolver._sides.AlliesOf(p_character_ID)
				if(null != allies):
					for ally_ID in allies.AliveMembers(_resolver._characters):
						if(ally_ID != p_character_ID):
							_resolver._EmitTurnBarBump(ally_ID, data.magnitude)
				break
	_TriggerAttackerDebuffOnDamage(p_character_ID, p_attacker_ID)

func _TriggerAttackerDebuffOnDamage(p_character_ID: int, p_attacker_ID: int) -> void:
	if(p_attacker_ID == BattleResolver.NO_ATTACKER or p_attacker_ID == p_character_ID
			or not _resolver._characters.has(p_attacker_ID)
			or not _resolver.GetSides().AreEnemies(p_character_ID, p_attacker_ID)):
		return
	var character: Character = _resolver._characters[p_character_ID]
	for buff in character._active_buffs:
		var rider: Variant = buff.trait_riders.get(&"attacker_debuff_on_damage")
		if(rider is Dictionary):
			var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			debuff.type = rider.get(&"type")
			debuff.duration = rider.get(&"duration", 0)
			CastDebuff(p_attacker_ID, debuff, p_character_ID)
			break


## Absorbs as much of an incoming loss as the holder's active Barrier can cover,
## consuming it once its value is exhausted, and returns the remainder.
func _AbsorbWithBarrier(p_character_ID: int, p_amount: int) -> int:
	var character: Character = _resolver._characters[p_character_ID]
	for buff in character._active_buffs:
		if(Types.Buff_Type.Barrier == buff.type):
			var absorbed: int = mini(p_amount, int(buff.value))
			if(absorbed <= 0):
				return p_amount
			buff.value -= absorbed
			var result: CombatResult = CombatResult.new(CombatResult.Kind.Barrier_Absorbed)
			result.target_ID = p_character_ID
			result.amount = absorbed
			_resolver._Emit(result)
			if(buff.value <= 0.0):
				RemoveBuff(p_character_ID, buff)
			return p_amount - absorbed
	return p_amount


func _EmitStatusDuration(p_target_ID: int, p_status_ID: int, p_duration: int) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Duration)
	result.target_ID = p_target_ID
	result.status_ID = p_status_ID
	result.duration = p_duration
	_resolver._Emit(result)


func _EmitBuffApplied(p_target_ID: int, p_buff: StatusEffects.Buff, p_display_name: String) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Applied)
	result.target_ID = p_target_ID
	result.status_ID = p_buff.ID
	result.is_buff = true
	result.buff_type = p_buff.type
	result.duration = p_buff.duration
	result.amount = int(p_buff.value)
	var buff_data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff.type)
	result.fraction = (Skills.DisplayedAttributeModifierFraction(buff_data, p_buff.value, p_buff.trait_riders)
			if null != buff_data else p_buff.value)
	result.text = p_display_name
	_resolver._Emit(result)
	var target: Character = _resolver._characters[p_target_ID]
	if(target._current_health <= 0):
		return
	for buff_trait: CharacterTrait in Skills.ActiveHooks(target, Types.Combat_Event.Buff_Applied):
		buff_trait.OnBuffGained(p_target_ID, p_buff, _resolver)


func _EmitStatusEffectDenied(p_target_ID: int, p_is_buff: bool, p_type: int) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Effect_Denied)
	result.target_ID = p_target_ID
	result.is_buff = p_is_buff
	if(p_is_buff):
		result.buff_type = p_type as Types.Buff_Type
	else:
		result.debuff_type = p_type as Types.Debuff_Type
	_resolver._Emit(result)


func _EmitDebuffApplied(p_target_ID: int, p_debuff: StatusEffects.Debuff, p_display_name: String) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Applied)
	result.target_ID = p_target_ID
	result.status_ID = p_debuff.ID
	result.is_buff = false
	result.debuff_type = p_debuff.type
	result.duration = p_debuff.duration
	result.source_ID = p_debuff.source_ID
	result.amount = int(p_debuff.value)
	var debuff_data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff.type)
	result.fraction = (Skills.DisplayedAttributeModifierFraction(debuff_data, p_debuff.value, p_debuff.trait_riders)
			if null != debuff_data else p_debuff.value)
	result.text = p_display_name
	_resolver._Emit(result)
	Skills.DispatchDebuffApplied(p_debuff, p_target_ID, _resolver._characters, _resolver)
	var target: Character = _resolver._characters[p_target_ID]
	if(target._current_health <= 0):
		return
	for debuff_trait: CharacterTrait in Skills.ActiveHooks(target, Types.Combat_Event.Debuff_Received):
		debuff_trait.OnDebuffReceived(p_target_ID, p_debuff, _resolver)
