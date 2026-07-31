class_name StatusEffectResolver extends RefCounted

## Owns the per-combat buff/debuff lifecycle: apply/cast/tick/expire, the block/consume/
## trigger rules bespoke to individual statuses, and the status-derived reads the damage
## and health paths need. Holds a back-reference to its owning BattleResolver for the
## shared batch/emit/snapshot services status effects need, mirroring ZoneResolver.

var _resolver: BattleResolver

func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver


func ApplyBuff(p_target_ID: int, p_buff_template: StatusEffects.Buff) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return _resolver._EndBatch()
	var data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff_template.type)
	if(_BlockedBySequenceLock(data, target) or _BlockedBySeverance(target)):
		return _resolver._EndBatch()

	var new_value: float = p_buff_template.value if 0.0 != p_buff_template.value or null == data else data.magnitude
	if(Types.Buff_Type.Barrier == p_buff_template.type
			and _KeepsExistingBarrier(p_target_ID, target, new_value)):
		return _resolver._EndBatch()

	_InsertOrRefresh(p_target_ID, true, p_buff_template.type, data, new_value, p_buff_template.duration,
			-1, 0.0, false, p_buff_template.name)
	return _resolver._EndBatch()


func ApplyDebuff(p_target_ID: int, p_debuff_template: StatusEffects.Debuff) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return _resolver._EndBatch()
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_template.type)
	if(_BlockedBySequenceLock(data, target)):
		return _resolver._EndBatch()
	if(_ConsumeAegisIfPresent(p_target_ID, p_debuff_template.source_ID)):
		return _resolver._EndBatch()

	var new_value: float = (p_debuff_template.value if 0.0 != p_debuff_template.value
			else _SnapshotStatusValue(data, p_debuff_template.source_ID))
	_InsertOrRefresh(p_target_ID, false, p_debuff_template.type, data, new_value, p_debuff_template.duration,
			p_debuff_template.source_ID, 0.0, false, p_debuff_template.name)
	return _resolver._EndBatch()


func RemoveBuff(p_target_ID: int, p_buff: StatusEffects.Buff) -> Array[CombatResult]:
	_resolver._BeginBatch()
	_resolver._characters[p_target_ID]._active_buffs.erase(p_buff)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
	result.target_ID = p_target_ID
	result.status_IDs = [p_buff.ID]
	_resolver._Emit(result)
	return _resolver._EndBatch()


## Blocks one incoming attack by consuming the target's Premonition buff, if any.
func ConsumePremonitionIfPresent(p_target_ID: int, p_caster_ID: int) -> bool:
	var target: Character = _resolver._characters[p_target_ID]
	for buff in target._active_buffs:
		if(Types.Buff_Type.Premonition == buff.type):
			RemoveBuff(p_target_ID, buff)
			var missed: CombatResult = CombatResult.new(CombatResult.Kind.Attack_Missed)
			missed.target_ID = p_target_ID
			missed.source_ID = p_caster_ID
			_resolver._Emit(missed)
			return true
	return false


## Saves a character from a fatal hit by consuming their Deathward buff, if any.
func ConsumeDeathwardIfPresent(p_character_ID: int) -> bool:
	var character: Character = _resolver._characters[p_character_ID]
	for buff in character._active_buffs:
		if(Types.Buff_Type.Deathward == buff.type):
			RemoveBuff(p_character_ID, buff)
			return true
	return false


func _CastBuffOfType(p_target_ID: int, p_buff_type: Types.Buff_Type, p_duration: int) -> void:
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return
	var data: StatusEffectData = StatusEffectRegistry.BuffData(p_buff_type)
	if(_BlockedBySequenceLock(data, target) or _BlockedBySeverance(target)):
		return
	var new_value: float = data.magnitude if null != data else 0.0
	if(Types.Buff_Type.Barrier == p_buff_type and _KeepsExistingBarrier(p_target_ID, target, new_value)):
		return

	_InsertOrRefresh(p_target_ID, true, p_buff_type, data, new_value, p_duration,
			-1, 0.0, false, Types.Buff_Type.keys()[p_buff_type])


func CastDebuff(
		p_target_ID: int,
		p_debuff_template: StatusEffects.Debuff,
		p_caster_ID: int,
		p_tick_bonus_per_debuff: float = 0.0,
		p_always_refresh_duration: bool = false,
		p_trigger_mirror_coat: bool = false) -> Array[CombatResult]:
	_resolver._BeginBatch()
	var target: Character = _resolver._characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return _resolver._EndBatch()

	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_template.type)
	if(_BlockedBySequenceLock(data, target)):
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
			else _SnapshotStatusValue(data, p_caster_ID))
	var created: StatusEffects.Effect = _InsertOrRefresh(p_target_ID, false, p_debuff_template.type, data, value,
			p_debuff_template.duration, p_caster_ID, p_tick_bonus_per_debuff, p_always_refresh_duration,
			Types.Debuff_Type.keys()[p_debuff_template.type])
	if(p_trigger_mirror_coat and null != created):
		_TriggerMirrorCoat(p_target_ID, p_caster_ID, p_debuff_template.type)
	return _resolver._EndBatch()

func _RollsResistDebuff(
		p_defender_ID: int,
		p_defender_resistance: int,
		p_attacker_ID: int,
		p_attacker_accuracy: int) -> bool:
	if(_resolver._HasDebuff(p_defender_ID, Types.Debuff_Type.Signed_Writ)):
		return false
	var random_value: float = _resolver._RollFavoring(p_attacker_ID, 0.95, 1.0, true)
	var random_value_2: float = _resolver._RollFavoring(p_defender_ID, 0.95, 1.0, true)
	return p_attacker_accuracy * random_value < p_defender_resistance * random_value_2


## When a debuff lands on a holder with an active Mirror Coat, a copy of it is
## rolled against the attacker's own Resistance and applied directly if it lands.
func _TriggerMirrorCoat(p_holder_ID: int, p_attacker_ID: int, p_debuff_type: Types.Debuff_Type) -> void:
	if(not _resolver._HasBuff(p_holder_ID, Types.Buff_Type.Mirror_Coat) or p_holder_ID == p_attacker_ID
			or not _resolver._characters.has(p_attacker_ID) or _resolver._characters[p_attacker_ID]._current_health <= 0):
		return
	var holder_accuracy: int = _resolver.GetEffectiveAttributes(p_holder_ID)[Types.Attribute.Accuracy]
	var attacker_resistance: int = _resolver.GetEffectiveAttributes(p_attacker_ID)[Types.Attribute.Resistance]
	if(_RollsResistDebuff(p_attacker_ID, attacker_resistance, p_holder_ID, holder_accuracy)):
		var resisted: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Resisted)
		resisted.target_ID = p_attacker_ID
		resisted.source_ID = p_holder_ID
		_resolver._Emit(resisted)
		return
	if(Skills.HasMaxStatusEffects(_resolver._characters[p_attacker_ID])):
		return
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_type)
	var mirrored: StatusEffects.Debuff = StatusEffects.Debuff.new()
	mirrored.type = p_debuff_type
	mirrored.duration = data.duration_default if null != data else 0
	mirrored.source_ID = p_holder_ID
	mirrored.value = _SnapshotStatusValue(data, p_holder_ID)
	mirrored.ID = _resolver._NextStatusID()
	_resolver._characters[p_attacker_ID]._active_debuffs.append(mirrored)
	_EmitDebuffApplied(p_attacker_ID, mirrored, "")


func _TriggerExistingCasterDebuffs(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var caster: Character = _resolver._characters[p_caster_ID]
	var status_IDs_to_be_removed: Array[int] = []
	var tick_damage_by_source: Dictionary[int, int] = {}
	var tick_damage_total: int = 0
	var expiring_plagues: Array[StatusEffects.Debuff] = []
	for debuff in caster._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and data.applies_on_self_tick):
			var tick_damage: int = 0
			match data.magnitude_kind:
				StatusEffectData.MagnitudeKind.MaxHealthPercent:
					tick_damage = int(floor(
							(p_caster_attributes[Types.Attribute.Health]
									* GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * data.magnitude))
				StatusEffectData.MagnitudeKind.CasterAttributeSnapshotPercent:
					tick_damage = int(floor(debuff.value))
				_:
					pass
			if(tick_damage > 0):
				if(debuff.tick_bonus_per_debuff > 0.0):
					var stack_count: int = mini(caster._active_debuffs.size(), GameBalance.DEBUFF_TICK_BONUS_STACK_CAP)
					tick_damage = int(floor(tick_damage * (1.0 + debuff.tick_bonus_per_debuff * stack_count)))
				tick_damage_total += tick_damage
				tick_damage_by_source[debuff.source_ID] = tick_damage_by_source.get(debuff.source_ID, 0) + tick_damage

		debuff.duration -= 1
		_EmitStatusDuration(p_caster_ID, debuff.ID, debuff.duration)
		if(debuff.duration <= 0):
			status_IDs_to_be_removed.append(debuff.ID)
			if(Types.Debuff_Type.Plague == debuff.type):
				expiring_plagues.append(debuff)

	caster._active_debuffs = caster._active_debuffs.filter(func(debuff): return debuff.duration > 0)
	if(not status_IDs_to_be_removed.is_empty()):
		var removed: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
		removed.target_ID = p_caster_ID
		removed.status_IDs = status_IDs_to_be_removed
		_resolver._Emit(removed)

	if(tick_damage_total > 0):
		_resolver._ApplyHealthLoss(p_caster_ID, tick_damage_total)
		var tick: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Tick)
		tick.target_ID = p_caster_ID
		tick.amount = tick_damage_total
		tick.amount_by_source = tick_damage_by_source
		_resolver._Emit(tick)

	for plague in expiring_plagues:
		_SpreadPlague(p_caster_ID, plague)


func _TriggerExistingCasterBuffs(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var caster: Character = _resolver._characters[p_caster_ID]
	var status_IDs_to_be_removed: Array[int] = []
	var heal_total: int = 0
	var self_cost_total: int = 0
	var expiring_overflows: Array[StatusEffects.Buff] = []
	var expiring_rush_count: int = 0

	for buff in caster._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and data.applies_on_self_tick):
			match data.magnitude_kind:
				StatusEffectData.MagnitudeKind.DamageMultiplier:
					_resolver._damage_multiplier[p_caster_ID] = _resolver._damage_multiplier.get(p_caster_ID, 1.0) * buff.value
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

		buff.duration -= 1
		_EmitStatusDuration(p_caster_ID, buff.ID, buff.duration)
		if(buff.duration <= 0):
			status_IDs_to_be_removed.append(buff.ID)
			if(Types.Buff_Type.Overflow == buff.type):
				expiring_overflows.append(buff)
			elif(Types.Buff_Type.Rush == buff.type):
				expiring_rush_count += 1

	caster._active_buffs = caster._active_buffs.filter(func(buff): return buff.duration > 0)
	if(not status_IDs_to_be_removed.is_empty()):
		var removed: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
		removed.target_ID = p_caster_ID
		removed.status_IDs = status_IDs_to_be_removed
		_resolver._Emit(removed)
		# A max-Health buff may have just expired; reclamp current health to
		# the new, smaller max (_MaxHealth reads the buffs that remain after the filter above).
		caster._current_health = mini(caster._current_health, _resolver._MaxHealth(caster))
		for i in status_IDs_to_be_removed.size():
			_resolver.BroadcastEvent(Types.Combat_Event.Resource_Depleted)

	for i in expiring_overflows.size():
		_TriggerOverflow(p_caster_ID)

	for i in expiring_rush_count:
		_TriggerRushStun(p_caster_ID)

	if(heal_total > 0):
		var healed: int = _resolver._ApplyHeal(p_caster_ID, heal_total)
		var heal_result: CombatResult = CombatResult.new(CombatResult.Kind.Heal)
		heal_result.target_ID = p_caster_ID
		heal_result.amount = healed
		_resolver._Emit(heal_result)

	if(self_cost_total > 0 and caster._current_health > 0):
		_resolver._ApplyHealthLoss(p_caster_ID, self_cost_total)
		var cost_result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
		cost_result.target_ID = p_caster_ID
		cost_result.amount = self_cost_total
		_resolver._Emit(cost_result)


func _BlockedBySequenceLock(p_data: StatusEffectData, p_target: Character) -> bool:
	if(null == p_data or not p_data.attribute_modifiers.has(Types.Attribute.Speed)):
		return false
	for debuff in p_target._active_debuffs:
		if(Types.Debuff_Type.Sequence_Lock == debuff.type):
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
		p_tick_bonus_per_debuff: float,
		p_always_refresh_duration: bool,
		p_display_name: String) -> StatusEffects.Effect:
	var target: Character = _resolver._characters[p_target_ID]
	var active: Array = target._active_buffs if p_is_buff else target._active_debuffs

	if(not p_is_buff and p_duration > 0 and null != target._trait):
		p_duration += target._trait.GetIncomingDebuffDurationBonus(p_target_ID)

	if(null == p_data or not p_data.stackable):
		for i in active.size():
			if(active[i].type == p_type):
				if(null == p_data or p_data.overwritable):
					if(p_always_refresh_duration or p_duration > active[i].duration):
						active[i].duration = p_duration
						if(not p_is_buff):
							active[i].tick_bonus_per_debuff = p_tick_bonus_per_debuff
						_EmitStatusDuration(p_target_ID, active[i].ID, p_duration)
				return null

	if(p_is_buff):
		var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
		new_buff.type = p_type as Types.Buff_Type
		new_buff.duration = p_duration
		new_buff.name = p_display_name
		new_buff.value = p_value
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
	new_debuff.tick_bonus_per_debuff = p_tick_bonus_per_debuff
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
				_resolver._ApplyHealthLoss(p_caster_ID, damage)
				var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
				result.source_ID = debuff.source_ID
				result.target_ID = p_caster_ID
				result.amount = damage
				_resolver._Emit(result)
			return


## Deals Mysticism-scaled magical damage to every living enemy when Overflow expires.
func _TriggerOverflow(p_holder_ID: int) -> void:
	var side: CombatTeam = _resolver._sides.EnemiesOf(p_holder_ID)
	if(null == side):
		return
	var data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Overflow)
	_resolver.ResolveTraitDamage(p_holder_ID, side.AliveMembers(_resolver._characters),
			_resolver.GetEffectiveAttributes(p_holder_ID), {Types.Attribute.Mysticism: data.magnitude})


func _TriggerRushStun(p_holder_ID: int) -> void:
	if(Skills.HasMaxStatusEffects(_resolver._characters[p_holder_ID])):
		return
	var stun: StatusEffects.Debuff = StatusEffects.Debuff.new()
	stun.type = Types.Debuff_Type.Stun
	stun.duration = 1
	stun.source_ID = p_holder_ID
	stun.ID = _resolver._NextStatusID()
	_resolver._characters[p_holder_ID]._active_debuffs.append(stun)
	_EmitDebuffApplied(p_holder_ID, stun, "")


func _SpreadPlague(p_holder_ID: int, p_expiring: StatusEffects.Debuff) -> void:
	var side: CombatTeam = _resolver._sides.AlliesOf(p_holder_ID)
	if(null == side):
		return
	var candidates: Array[int] = side.AliveMembers(_resolver._characters)
	candidates.erase(p_holder_ID)
	if(candidates.is_empty()):
		return
	var target_ID: int = candidates[_resolver._random.randi_range(0, candidates.size() - 1)]
	if(Skills.HasMaxStatusEffects(_resolver._characters[target_ID])):
		return
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Plague)
	var spread: StatusEffects.Debuff = StatusEffects.Debuff.new()
	spread.type = Types.Debuff_Type.Plague
	spread.duration = data.duration_default if null != data else 0
	spread.source_ID = p_expiring.source_ID
	spread.value = p_expiring.value
	spread.ID = _resolver._NextStatusID()
	_resolver._characters[target_ID]._active_debuffs.append(spread)
	_EmitDebuffApplied(target_ID, spread, "")


func _SnapshotStatusValue(p_data: StatusEffectData, p_source_ID: int) -> float:
	if(null == p_data):
		return 0.0
	if(StatusEffectData.MagnitudeKind.CasterAttributeSnapshotPercent == p_data.magnitude_kind):
		if(not _resolver._characters.has(p_source_ID)):
			return 0.0
		var source_attributes: Dictionary[Types.Attribute, int] = _resolver._characters[p_source_ID].GetTotalAttributes()
		_resolver._ApplyLongAttributeBonus(p_source_ID, source_attributes)
		var value: float = 0.0
		for attribute in p_data.attribute_modifiers.keys():
			value += p_data.magnitude * float(source_attributes[attribute])
		return value
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


func _OpportunistDamageMultiplier(p_caster_ID: int, p_target: Character) -> float:
	if(not _resolver._characters.has(p_caster_ID)):
		return 1.0
	var multiplier: float = 1.0
	for buff in _resolver._characters[p_caster_ID]._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and StatusEffectData.MagnitudeKind.PerTargetDebuffDamagePercent == data.magnitude_kind):
			multiplier += buff.value * p_target._active_debuffs.size()
	return multiplier


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
	var trait_multiplier: float = (character._trait.GetIncomingHealMultiplier(p_character_ID)
			if null != character._trait else 1.0)
	return maxf(multiplier * trait_multiplier, 0.0)


func _TriggerDamageTakenReactions(p_character_ID: int) -> void:
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
	result.text = p_display_name
	_resolver._Emit(result)
	var target: Character = _resolver._characters[p_target_ID]
	var buff_trait: CharacterTrait = Skills.ActiveHook(target, Types.Combat_Event.Buff_Applied)
	if(null != buff_trait):
		buff_trait.OnBuffGained(p_target_ID, p_buff, _resolver)


func _EmitDebuffApplied(p_target_ID: int, p_debuff: StatusEffects.Debuff, p_display_name: String) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Applied)
	result.target_ID = p_target_ID
	result.status_ID = p_debuff.ID
	result.is_buff = false
	result.debuff_type = p_debuff.type
	result.duration = p_debuff.duration
	result.source_ID = p_debuff.source_ID
	result.text = p_display_name
	_resolver._Emit(result)
	Skills.DispatchDebuffApplied(p_debuff, p_target_ID, _resolver._characters, _resolver)
	var target: Character = _resolver._characters[p_target_ID]
	var debuff_trait: CharacterTrait = Skills.ActiveHook(target, Types.Combat_Event.Debuff_Received)
	if(null != debuff_trait):
		debuff_trait.OnDebuffReceived(p_target_ID, p_debuff, _resolver)
