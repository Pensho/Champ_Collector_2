class_name BattleResolver extends RefCounted

## Pure combat-resolution core. Owns the per-combat transient state (Heap-On stacks,
## damage multipliers, zones), a seedable RandomNumberGenerator, and the status-effect
## identity counter. Mutates Character state and reports everything that happened as
## CombatResult records — both returned from each entry point and emitted through
## `result_produced` — and never touches CharacterRepresentation or BattleUI.

signal result_produced(p_result: CombatResult)

enum Winner {
	Ongoing,
	Player_Won,
	Monsters_Won,
}

var _characters: Dictionary[int, Character]
var _sides: CombatSides
var _turn_positions: TurnPositions
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _zones: Dictionary[int, Zone] = {}

var _heap_on_stacks: Dictionary[int, int] = {}
var _heap_on_value: Dictionary[int, float] = {}
var _damage_multiplier: Dictionary[int, float] = {}

var _next_status_ID: int = 0
var _batch: Array[CombatResult] = []
var _batch_depth: int = 0


## Pass a non-negative p_seed for reproducible rolls (e.g. from the encounter);
## a negative seed randomizes.
func _init(
		p_characters: Dictionary[int, Character],
		p_sides: CombatSides,
		p_turn_positions: TurnPositions = null,
		p_seed: int = -1) -> void:
	_characters = p_characters
	_sides = p_sides
	_turn_positions = p_turn_positions if p_turn_positions != null else TurnPositions.new()
	if(p_seed >= 0):
		_random.seed = p_seed
	else:
		_random.randomize()


func GetCharacters() -> Dictionary[int, Character]:
	return _characters


func GetSides() -> CombatSides:
	return _sides


func GetTurnPositions() -> TurnPositions:
	return _turn_positions


func GetRandom() -> RandomNumberGenerator:
	return _random


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


## Targeting for this battle's roster; random picks use the resolver's generator.
func FindSkillTargets(p_target_ID: int, p_caster_ID: int, p_target_type: Types.Skill_Target) -> Array[int]:
	return Skills.FindSkillTargets(p_target_ID, p_caster_ID, p_target_type, _characters, _sides, _random)


func IsTheBattleOver() -> Winner:
	if(_sides.enemy.AliveMembers(_characters).is_empty()):
		return Winner.Player_Won
	if(_sides.player.AliveMembers(_characters).is_empty()):
		return Winner.Monsters_Won
	return Winner.Ongoing


## Fires the active character's start-of-turn trait hook and returns its results.
func BeginTurn(p_character_ID: int) -> Array[CombatResult]:
	_BeginBatch()
	var character: Character = _characters[p_character_ID]
	if(null != character._trait and character._trait._execution_steps.has(Types.Combat_Event.Start_Turn)):
		character._trait.StartOfTurn(p_character_ID, self)
	return _EndBatch()


## The core sequence: trait hook, caster status ticks, skill effect, per-target
## resolution, cooldowns, zone triggers, and the end-of-turn trait hook.
func ResolveSkill(p_caster_ID: int, p_target_IDs: Array[int], p_skill_ID: int) -> Array[CombatResult]:
	_BeginBatch()
	var caster: Character = _characters[p_caster_ID]
	var cast_skill: Skill = caster._skills[p_skill_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = caster.GetBattleAttributes()

	var trait_result: TraitSkillResult = TraitSkillResult.new()
	if(null != caster._trait and caster._trait._execution_steps.has(Types.Combat_Event.Skill_Cast)):
		trait_result = caster._trait.OnSkillCast(p_caster_ID, p_target_IDs, cast_skill.name, caster_attributes, self)

	if(not caster._active_debuffs.is_empty()):
		_TriggerExistingCasterDebuffs(p_caster_ID, caster_attributes)

	if(not caster._active_buffs.is_empty()):
		_TriggerExistingCasterBuffs(p_caster_ID, caster_attributes)

	_ResolveSkillEffect(p_caster_ID, caster_attributes, cast_skill)

	var target_attributes: Dictionary[Types.Attribute, int]
	for target_ID in p_target_IDs:
		if(not _characters.has(target_ID)):
			continue
		var target: Character = _characters[target_ID]
		if(p_caster_ID != target_ID):
			target_attributes = target.GetBattleAttributes()
			Skills.TriggerTargetBuffs(target, target_attributes)
			Skills.TriggerTargetDebuffs(target, target_attributes)
			if(null != target._trait and target._trait._execution_steps.has(Types.Combat_Event.Defend)):
				target._trait.OnDefend(target_ID, target_attributes, _characters)

		if(not cast_skill.buffs.is_empty() and target._current_health > 0):
			_CastBuff(target_ID, cast_skill)

		if(not cast_skill.debuffs.is_empty() and target._current_health > 0):
			_CastDebuff(target_ID, target_attributes[Types.Attribute.Resistance], caster_attributes[Types.Attribute.Accuracy],
					cast_skill, p_caster_ID)

		if(not cast_skill.damage_scaling.is_empty()):
			_ResolveDamage(p_caster_ID, target_ID, caster_attributes, target_attributes,
					cast_skill, trait_result._damage_multiplier)

		var total_bump: float = cast_skill.turn_effect + trait_result._turn_bar_bump
		if(0.0 != total_bump):
			var bump: CombatResult = CombatResult.new(CombatResult.Kind.Turn_Bar_Bump)
			bump.target_ID = target_ID
			bump.fraction = total_bump
			_Emit(bump)

	for i in caster._skills.size():
		if(caster._skills[i].cooldown_left > 0):
			caster._skills[i].cooldown_left -= 1
	caster._skills[p_skill_ID].cooldown_left = caster._skills[p_skill_ID].cooldown

	TriggerZones(p_caster_ID)

	if(null != caster._trait and caster._trait._execution_steps.has(Types.Combat_Event.End_Turn)):
		caster._trait.EndOfTurn(p_caster_ID, self)
	return _EndBatch()


## Places a zone on the turn bar. Returns the results, empty when the slot is taken.
func PlaceZone(p_zone_ID: int, p_owner_ID: int, p_skill: Skill) -> Array[CombatResult]:
	_BeginBatch()
	if(_zones.has(p_zone_ID)):
		print("Zone is already used")
		return _EndBatch()
	var zone: Zone = Zone.new()
	zone.CreateNew(p_skill.skill_type, p_skill.duration, p_owner_ID, p_skill.target,
			_characters[p_owner_ID].GetBattleAttribute(Types.Attribute.Knowledge))
	_zones[p_zone_ID] = zone
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Placed)
	result.zone_ID = p_zone_ID
	result.source_ID = p_owner_ID
	result.duration = zone._duration
	result.skill_type = zone._type
	_Emit(result)
	return _EndBatch()


## Applies a buff from a template (traits, adventure effects, debug tools).
func ApplyBuff(p_target_ID: int, p_buff_template: StatusEffects.Buff) -> Array[CombatResult]:
	_BeginBatch()
	var target: Character = _characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return _EndBatch()

	for i in target._active_buffs.size():
		if(target._active_buffs[i].type == p_buff_template.type):
			if(Skills.OverwritableBuff(p_buff_template.type)):
				if(p_buff_template.duration > target._active_buffs[i].duration):
					target._active_buffs[i].duration = p_buff_template.duration
					_EmitStatusDuration(p_target_ID, target._active_buffs[i].ID, p_buff_template.duration)
				return _EndBatch()

	var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	new_buff.type = p_buff_template.type
	new_buff.duration = p_buff_template.duration
	new_buff.name = p_buff_template.name
	new_buff.value = p_buff_template.value
	new_buff.ID = _NextStatusID()
	target._active_buffs.append(new_buff)
	_EmitBuffApplied(p_target_ID, new_buff, new_buff.name)
	return _EndBatch()


## Applies a debuff from a template without a resist roll (adventure effects, debug).
func ApplyDebuff(p_target_ID: int, p_debuff_template: StatusEffects.Debuff) -> Array[CombatResult]:
	_BeginBatch()
	var target: Character = _characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return _EndBatch()

	for i in target._active_debuffs.size():
		if(target._active_debuffs[i].type == p_debuff_template.type):
			if(Skills.OverwritableDebuff(p_debuff_template.type)):
				if(p_debuff_template.duration > target._active_debuffs[i].duration):
					target._active_debuffs[i].duration = p_debuff_template.duration
					_EmitStatusDuration(p_target_ID, target._active_debuffs[i].ID, p_debuff_template.duration)
				return _EndBatch()

	var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	new_debuff.type = p_debuff_template.type
	new_debuff.duration = p_debuff_template.duration
	new_debuff.name = p_debuff_template.name
	new_debuff.source_ID = p_debuff_template.source_ID
	new_debuff.ID = _NextStatusID()
	target._active_debuffs.append(new_debuff)
	_EmitDebuffApplied(p_target_ID, new_debuff, new_debuff.name)
	return _EndBatch()


func RemoveBuff(p_target_ID: int, p_buff: StatusEffects.Buff) -> Array[CombatResult]:
	_BeginBatch()
	_characters[p_target_ID]._active_buffs.erase(p_buff)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
	result.target_ID = p_target_ID
	result.status_IDs = [p_buff.ID]
	_Emit(result)
	return _EndBatch()


## Trait flavor text ("Stole buff!", "Avoided!") routed through the result stream.
func EmitTraitText(p_target_ID: int, p_text: String, p_color: Color = Color.WHITE) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Trait_Text)
	result.target_ID = p_target_ID
	result.text = p_text
	result.color = p_color
	_Emit(result)


## Sets health directly (debug tools), running the same clamp and death handling as
## combat damage.
func SetCurrentHealth(p_character_ID: int, p_health: int) -> Array[CombatResult]:
	_BeginBatch()
	var character: Character = _characters[p_character_ID]
	var was_alive: bool = character._current_health > 0
	character._current_health = clampi(p_health, 0, _MaxHealth(character))
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
	result.target_ID = p_character_ID
	result.amount = 0
	_Emit(result)
	if(was_alive and character._current_health <= 0):
		_HandleDeath(p_character_ID)
	return _EndBatch()


func _BeginBatch() -> void:
	if(_batch_depth == 0):
		_batch = []
	_batch_depth += 1


func _EndBatch() -> Array[CombatResult]:
	_batch_depth -= 1
	return _batch


func _Emit(p_result: CombatResult) -> void:
	_batch.append(p_result)
	result_produced.emit(p_result)


func _NextStatusID() -> int:
	_next_status_ID += 1
	return _next_status_ID - 1


func _MaxHealth(p_character: Character) -> int:
	return p_character.GetBattleAttribute(Types.Attribute.Health) * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER


func _EmitStatusDuration(p_target_ID: int, p_status_ID: int, p_duration: int) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Duration)
	result.target_ID = p_target_ID
	result.status_ID = p_status_ID
	result.duration = p_duration
	_Emit(result)


func _EmitBuffApplied(p_target_ID: int, p_buff: StatusEffects.Buff, p_display_name: String) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Applied)
	result.target_ID = p_target_ID
	result.status_ID = p_buff.ID
	result.is_buff = true
	result.buff_type = p_buff.type
	result.duration = p_buff.duration
	result.text = p_display_name
	_Emit(result)


func _EmitDebuffApplied(p_target_ID: int, p_debuff: StatusEffects.Debuff, p_display_name: String) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Status_Applied)
	result.target_ID = p_target_ID
	result.status_ID = p_debuff.ID
	result.is_buff = false
	result.debuff_type = p_debuff.type
	result.duration = p_debuff.duration
	result.text = p_display_name
	_Emit(result)


## Loses health, clamps, and handles the alive-to-dead transition.
func _ApplyHealthLoss(p_character_ID: int, p_amount: int) -> void:
	var character: Character = _characters[p_character_ID]
	var was_alive: bool = character._current_health > 0
	character._current_health = clampi(character._current_health - p_amount, 0, _MaxHealth(character))
	if(was_alive and character._current_health <= 0):
		_HandleDeath(p_character_ID)


func _HandleDeath(p_character_ID: int) -> void:
	var character: Character = _characters[p_character_ID]
	character._active_buffs.clear()
	character._active_debuffs.clear()
	var cleared: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Cleared)
	cleared.target_ID = p_character_ID
	_Emit(cleared)
	if(null != character._trait and character._trait._execution_steps.has(Types.Combat_Event.On_Death)):
		character._trait.OnDeath()
	var death: CombatResult = CombatResult.new(CombatResult.Kind.Death)
	death.target_ID = p_character_ID
	_Emit(death)


## Caster-side skill mechanics that key off per-combat state (Heap On stacking).
func _ResolveSkillEffect(
		p_caster_ID: int,
		p_caster_attr: Dictionary[Types.Attribute, int],
		p_skill: Skill) -> void:
	match p_skill.skill_type:
		Types.Skill_Type.Heap_On:
			if(0 == _heap_on_stacks.get(p_caster_ID, 0)):
				_heap_on_value[p_caster_ID] = (float(p_caster_attr[Types.Attribute.Health])
						* GameBalance.HEAP_ON_MULTIPLIER)
			p_caster_attr[Types.Attribute.Health] += int(
					_heap_on_value[p_caster_ID] * float(_heap_on_stacks.get(p_caster_ID, 0)))
			_heap_on_stacks[p_caster_ID] = _heap_on_stacks.get(p_caster_ID, 0) + 1


## Ticks the caster's own debuffs at the start of their action. Burning deals damage;
## the tick is reported with a per-source split for post-battle damage attribution.
func _TriggerExistingCasterDebuffs(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var caster: Character = _characters[p_caster_ID]
	var status_IDs_to_be_removed: Array[int] = []
	var burning_damage_by_source: Dictionary[int, int] = {}
	var burning_damage_total: int = 0
	for debuff in caster._active_debuffs:
		match debuff.type:
			Types.Debuff_Type.Burning:
				var tick_damage: int = int(floor(
						(p_caster_attributes[Types.Attribute.Health]
								* GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))
				burning_damage_total += tick_damage
				if(not burning_damage_by_source.has(debuff.source_ID)):
					burning_damage_by_source[debuff.source_ID] = 0
				burning_damage_by_source[debuff.source_ID] += tick_damage
			Types.Debuff_Type.Enfeeble:
				p_caster_attributes[Types.Attribute.Attack] -= int(
						ceilf(p_caster_attributes[Types.Attribute.Attack] * 0.3))
			Types.Debuff_Type.Expose_Weakness:
				p_caster_attributes[Types.Attribute.Defence] -= int(
						ceilf(p_caster_attributes[Types.Attribute.Defence] * 0.3))

		debuff.duration -= 1
		_EmitStatusDuration(p_caster_ID, debuff.ID, debuff.duration)
		if(debuff.duration <= 0):
			status_IDs_to_be_removed.append(debuff.ID)

	caster._active_debuffs = caster._active_debuffs.filter(func(debuff): return debuff.duration > 0)
	if(not status_IDs_to_be_removed.is_empty()):
		var removed: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
		removed.target_ID = p_caster_ID
		removed.status_IDs = status_IDs_to_be_removed
		_Emit(removed)

	if(burning_damage_total > 0):
		var tick: CombatResult = CombatResult.new(CombatResult.Kind.Burning_Tick)
		tick.target_ID = p_caster_ID
		tick.amount = burning_damage_total
		tick.amount_by_source = burning_damage_by_source
		_Emit(tick)
		_ApplyHealthLoss(p_caster_ID, burning_damage_total)


func _TriggerExistingCasterBuffs(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	var caster: Character = _characters[p_caster_ID]
	var status_IDs_to_be_removed: Array[int] = []

	for buff in caster._active_buffs:
		match buff.type:
			Types.Buff_Type.Empower:
				p_caster_attributes[Types.Attribute.Attack] += int(
						ceilf(p_caster_attributes[Types.Attribute.Attack] * 0.3))
			Types.Buff_Type.Fortify:
				p_caster_attributes[Types.Attribute.Defence] += int(
						ceilf(p_caster_attributes[Types.Attribute.Defence] * 0.3))
			Types.Buff_Type.Daunting_Strength:
				_damage_multiplier[p_caster_ID] = _damage_multiplier.get(p_caster_ID, 1.0) * 2.0
			Types.Buff_Type.Phalanx_Guard:
				pass
			_:
				pass

		buff.duration -= 1
		_EmitStatusDuration(p_caster_ID, buff.ID, buff.duration)
		if(buff.duration <= 0):
			status_IDs_to_be_removed.append(buff.ID)

	caster._active_buffs = caster._active_buffs.filter(func(buff): return buff.duration > 0)
	if(not status_IDs_to_be_removed.is_empty()):
		var removed: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
		removed.target_ID = p_caster_ID
		removed.status_IDs = status_IDs_to_be_removed
		_Emit(removed)


## Applies the cast skill's buff to a target (announced with the buff's enum name).
func _CastBuff(p_target_ID: int, p_skill: Skill) -> void:
	var target: Character = _characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return

	for i in target._active_buffs.size():
		if(target._active_buffs[i].type == p_skill.buffs[p_skill.target]):
			if(Skills.OverwritableBuff(p_skill.buffs[p_skill.target])):
				if(p_skill.duration > target._active_buffs[i].duration):
					target._active_buffs[i].duration = p_skill.duration
					_EmitStatusDuration(p_target_ID, target._active_buffs[i].ID, p_skill.duration)
				return

	var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	new_buff.type = p_skill.buffs[p_skill.target]
	new_buff.duration = p_skill.duration
	new_buff.ID = _NextStatusID()
	target._active_buffs.append(new_buff)
	_EmitBuffApplied(p_target_ID, new_buff, Types.Buff_Type.keys()[new_buff.type])


## Applies the cast skill's debuff to a target, rolled accuracy versus resistance.
func _CastDebuff(
		p_target_ID: int,
		p_target_resistance: int,
		p_caster_accuracy: int,
		p_skill: Skill,
		p_caster_ID: int) -> void:
	var target: Character = _characters[p_target_ID]
	if(Skills.HasMaxStatusEffects(target)):
		return

	var random_value: float = _random.randf_range(0.95, 1.0)
	var random_value_2: float = _random.randf_range(0.95, 1.0)
	if(p_caster_accuracy * random_value < p_target_resistance * random_value_2):
		var resisted: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Resisted)
		resisted.target_ID = p_target_ID
		resisted.source_ID = p_caster_ID
		_Emit(resisted)
		return

	for i in target._active_debuffs.size():
		if(target._active_debuffs[i].type == p_skill.debuffs[p_skill.target]):
			if(Skills.OverwritableDebuff(p_skill.debuffs[p_skill.target])):
				target._active_debuffs[i].duration = p_skill.duration
				_EmitStatusDuration(p_target_ID, target._active_debuffs[i].ID, p_skill.duration)
				return

	var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	new_debuff.type = p_skill.debuffs[p_skill.target]
	new_debuff.duration = p_skill.duration
	new_debuff.source_ID = p_caster_ID
	new_debuff.ID = _NextStatusID()
	target._active_debuffs.append(new_debuff)
	_EmitDebuffApplied(p_target_ID, new_debuff, Types.Debuff_Type.keys()[new_debuff.type])


## Computes and applies skill damage to one target, including the crit roll, the
## Daunting Strength multiplier, and the target's on-damage-taken trait hook.
func _ResolveDamage(
		p_caster_ID: int,
		p_target_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_target_attributes: Dictionary[Types.Attribute, int],
		p_skill: Skill,
		p_trait_multiplier: float) -> void:
	var random_value: float = _random.randf_range(0.95, 1.05)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	var rolled_critical: bool = false

	for key in p_skill.damage_scaling.keys():
		caster_scaled_attribute_aggregate += (p_skill.damage_scaling[key]
				* float(p_caster_attributes[key]) * p_trait_multiplier)
	# Some status skills deal no damage. So no need to continue.
	if(0.0 == caster_scaled_attribute_aggregate):
		return

	if(Skills.RollsCritical(p_caster_attributes[Types.Attribute.CritChance], _random)):
		rolled_critical = true
		crit_multiplier = max(
				GameBalance.MINIMUM_CRIT_DAMAGE,
				float(p_caster_attributes[Types.Attribute.CritDamage]
						- (p_target_attributes[Types.Attribute.Knowledge] * 0.5))
				) * 0.01

	var effective_defence: float = p_target_attributes[Types.Attribute.Defence] * p_skill.defense_ignore_factor
	var damage_ratio: float = (
			caster_scaled_attribute_aggregate / (effective_defence + caster_scaled_attribute_aggregate + 1.0))
	var mitigation_factor: float = (
			GameBalance.MINIMUM_DMG_PERCENT + ((1.0 - GameBalance.MINIMUM_DMG_PERCENT) * damage_ratio))
	var damage_dealt: int = int(ceil(mitigation_factor
			* (caster_scaled_attribute_aggregate * _damage_multiplier.get(p_caster_ID, 1.0))
			* crit_multiplier * random_value))
	_damage_multiplier.erase(p_caster_ID)

	if(damage_dealt == 0):
		return
	var target: Character = _characters[p_target_ID]
	if(damage_dealt > 0 and null != target._trait
			and target._trait._execution_steps.has(Types.Combat_Event.Damage_Taken)):
		damage_dealt = int(round(damage_dealt * target._trait.OnDamageTaken(p_target_ID, target._rarity, self)))
	if(damage_dealt == 0):
		return

	var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
	result.source_ID = p_caster_ID
	result.target_ID = p_target_ID
	result.amount = damage_dealt
	result.critical = rolled_critical
	_Emit(result)
	_ApplyHealthLoss(p_target_ID, damage_dealt)


## Fires the zones that living, non-active characters stand in — at most one zone per
## character — then decrements and expires triggered zones. Runs automatically at the
## end of ResolveSkill; public for headless tests that drive zones directly.
func TriggerZones(p_active_character_ID: int) -> Array[CombatResult]:
	_BeginBatch()
	for character_ID in _characters.keys():
		if(character_ID == p_active_character_ID or _characters[character_ID]._current_health <= 0):
			continue
		for ID in _zones.keys():
			if(_zones[ID]._duration == 0):
				continue
			if(not _turn_positions.IsCharacterInZone(character_ID, ID)):
				continue
			if(not Skills.CorrectZoneTarget(_zones[ID]._owner_ID, character_ID, _zones[ID]._target, _sides)):
				continue
			_ResolveZoneEffect(_zones[ID], character_ID)
			_zones[ID]._duration -= 1
			var triggered: CombatResult = CombatResult.new(CombatResult.Kind.Zone_Triggered)
			triggered.zone_ID = ID
			triggered.target_ID = character_ID
			triggered.duration = _zones[ID]._duration
			_Emit(triggered)
			# Restrict the trigger to one zone per character.
			break
	for ID in _zones.keys():
		if(_zones[ID]._duration == 0):
			# Zone extends Node, so erasing the reference alone would leak it.
			_zones[ID].free()
			_zones.erase(ID)
	return _EndBatch()


func _ResolveZoneEffect(p_zone: Zone, p_character_ID: int) -> void:
	match p_zone._type:
		Types.Skill_Type.Flicker_Zone:
			var bump: CombatResult = CombatResult.new(CombatResult.Kind.Turn_Bar_Bump)
			bump.target_ID = p_character_ID
			bump.fraction = Skills.AllyZoneMagnitude(GameBalance.FLICKER_ZONE_BASE_BUMP, p_zone._owner_knowledge)
			_Emit(bump)
		Types.Skill_Type.Lava_Zone:
			var target: Character = _characters[p_character_ID]
			if(Skills.HasMaxStatusEffects(target)):
				return
			var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			# TODO: add a status effect container to the Zone class and use that instead.
			new_debuff.type = Types.Debuff_Type.Burning
			new_debuff.duration = 2 # TODO: Replace with a defined number from the skill.
			new_debuff.source_ID = p_zone._owner_ID
			new_debuff.ID = _NextStatusID()
			target._active_debuffs.append(new_debuff)
			_EmitDebuffApplied(p_character_ID, new_debuff, "")
