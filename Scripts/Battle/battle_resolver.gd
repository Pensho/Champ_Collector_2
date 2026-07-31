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

const _BROADCASTABLE_EVENTS: Array[Types.Combat_Event] = [
	Types.Combat_Event.Start_Combat,
	Types.Combat_Event.Start_Turn,
	Types.Combat_Event.End_Turn,
	Types.Combat_Event.Resource_Depleted,
]

var _characters: Dictionary[int, Character]
var _sides: CombatSides
var _turn_positions: TurnPositions
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _zone_resolver: ZoneResolver
var _status_resolver: StatusEffectResolver
var _health_transfer_resolver: HealthTransferResolver

var _heap_on_stacks: Dictionary[int, int] = {}
var _heap_on_value: Dictionary[int, float] = {}
var _damage_multiplier: Dictionary[int, float] = {}

# Inner Dictionary is Dictionary[Types.Attribute, int]
# keyed by attribute with the accumulated bonus.
var _battle_long_attribute_bonus: Dictionary[int, Dictionary] = {}
# Battle persistent damage-dealt multiplier.
var _damage_dealt_bonus: Dictionary[int, float] = {}

var _next_status_ID: int = 0
var _batch: Array[CombatResult] = []
var _batch_depth: int = 0

var _turn_bar_progress: Dictionary[int, float] = {}


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
	_status_resolver = StatusEffectResolver.new(self)
	_zone_resolver = ZoneResolver.new(self)
	_health_transfer_resolver = HealthTransferResolver.new(self)
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


## Max Health including max-Health buffs, in the same units as `_current_health`.
func GetMaxHealth(p_character_ID: int) -> int:
	return _MaxHealth(_characters[p_character_ID])


func GetZoneResolver() -> ZoneResolver:
	return _zone_resolver


func GetStatusResolver() -> StatusEffectResolver:
	return _status_resolver


func GetEffectiveAttributes(p_character_ID: int) -> Dictionary[Types.Attribute, int]:
	var character: Character = _characters[p_character_ID]
	var attributes: Dictionary[Types.Attribute, int] = character.GetBaseAttributes()
	character.ApplyEquipmentBonuses(attributes)
	character.ApplyTraitAttributeBonus(attributes)
	_ApplyLongAttributeBonus(p_character_ID, attributes)
	Skills.ApplyActiveAttributeModifiers(character, attributes)
	return attributes

func _ApplyLongAttributeBonus(p_character_ID: int, p_attributes: Dictionary[Types.Attribute, int]) -> void:
	var bonus: Dictionary = _battle_long_attribute_bonus.get(p_character_ID, {})
	for attribute: Types.Attribute in bonus.keys():
		p_attributes[attribute] += bonus[attribute]


func FindSkillTargets(p_target_ID: int, p_caster_ID: int, p_target_type: Types.Skill_Target) -> Array[int]:
	var effective_type: Types.Skill_Target = p_target_type
	var is_single_target: bool = (Types.Skill_Target.Single_Enemy == p_target_type
			or Types.Skill_Target.Single_Ally == p_target_type)
	if(is_single_target and _HasDebuff(p_caster_ID, Types.Debuff_Type.Refracted)):
		effective_type = Types.Skill_Target.Random_One
	elif(is_single_target and _RollsIncomingRedirect(p_target_ID)):
		var redirected_ID: int = _RandomOtherCharacter(p_target_ID)
		if(redirected_ID != -1):
			EmitTraitText(p_target_ID, "Refracted!")
			return [redirected_ID]
	return Skills.FindSkillTargets(p_target_ID, p_caster_ID, effective_type, _characters, _sides, _random)


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
	var active_trait: CharacterTrait = Skills.ActiveHook(character, Types.Combat_Event.Start_Turn)
	if(null != active_trait):
		active_trait.StartOfTurn(p_character_ID, self)
	return _EndBatch()


## The core sequence: trait hook, caster status ticks, skill effect, per-target
## resolution, cooldowns, zone triggers, and the end-of-turn trait hook.
func ResolveSkill(p_caster_ID: int, p_target_IDs: Array[int], p_skill_ID: int) -> Array[CombatResult]:
	_BeginBatch()
	var caster: Character = _characters[p_caster_ID]
	var cast_skill: Skill = caster._skills[p_skill_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = GetEffectiveAttributes(p_caster_ID)

	var trait_result: TraitSkillResult = TraitSkillResult.new()
	var skill_cast_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.Skill_Cast)
	if(null != skill_cast_trait):
		trait_result = skill_cast_trait.OnSkillCast(p_caster_ID, p_target_IDs, cast_skill.name, caster_attributes, self)

	if(not caster._active_debuffs.is_empty()):
		_status_resolver._TriggerExistingCasterDebuffs(p_caster_ID, caster_attributes)

	if(not caster._active_buffs.is_empty()):
		_status_resolver._TriggerExistingCasterBuffs(p_caster_ID, caster_attributes)

	_ResolveSkillEffect(p_caster_ID, caster_attributes, cast_skill)
	var health_paid: int = _health_transfer_resolver.ResolveHealthCosts(p_caster_ID, p_target_IDs, cast_skill)
	_ResolveStatusGroups(p_caster_ID, p_target_IDs, cast_skill, trait_result._tick_bonus_per_debuff, health_paid)
	_health_transfer_resolver.ResolveHealthGains(p_caster_ID, p_target_IDs, cast_skill, caster_attributes)

	var is_non_basic: bool = cast_skill.cooldown > 0
	_status_resolver._TriggerManaBurn(p_caster_ID, caster_attributes, is_non_basic)

	var target_attributes: Dictionary[Types.Attribute, int]
	for target_ID in p_target_IDs:
		if(not _characters.has(target_ID)):
			continue
		var target: Character = _characters[target_ID]
		if(p_caster_ID != target_ID):
			target_attributes = GetEffectiveAttributes(target_ID)
			var defend_trait: CharacterTrait = Skills.ActiveHook(target, Types.Combat_Event.Defend)
			if(null != defend_trait):
				defend_trait.OnDefend(target_ID, target_attributes, _characters)

		if(not cast_skill.damage_scaling.is_empty()):
			_ResolveDamage(p_caster_ID, target_ID, caster_attributes, target_attributes,
					cast_skill, trait_result._damage_multiplier)

		var total_bump: float = cast_skill.turn_effect + trait_result._turn_bar_bump
		_EmitTurnBarBump(target_ID, total_bump, p_caster_ID)

	_TickCooldowns(caster)
	if(not (is_non_basic and _status_resolver._ConsumeRehearsedIfPresent(p_caster_ID))):
		caster._skills[p_skill_ID].cooldown_left = caster._skills[p_skill_ID].cooldown

	_zone_resolver.TriggerZones(p_caster_ID)

	var end_turn_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.End_Turn)
	if(null != end_turn_trait):
		end_turn_trait.EndOfTurn(p_caster_ID, self)
	return _EndBatch()


## A Stun-affected character's turn: still ticks their own statuses (so Stun's own
## duration decrements and clears itself) and zones, but casts no skill.
func ResolveStunTurn(p_caster_ID: int) -> Array[CombatResult]:
	_BeginBatch()
	var caster: Character = _characters[p_caster_ID]
	var caster_attributes: Dictionary[Types.Attribute, int] = GetEffectiveAttributes(p_caster_ID)
	if(not caster._active_debuffs.is_empty()):
		_status_resolver._TriggerExistingCasterDebuffs(p_caster_ID, caster_attributes)
	if(not caster._active_buffs.is_empty()):
		_status_resolver._TriggerExistingCasterBuffs(p_caster_ID, caster_attributes)
	_TickCooldowns(caster)
	_zone_resolver.TriggerZones(p_caster_ID)
	var end_turn_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.End_Turn)
	if(null != end_turn_trait):
		end_turn_trait.EndOfTurn(p_caster_ID, self)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Turn_Skipped)
	result.target_ID = p_caster_ID
	_Emit(result)
	return _EndBatch()


func AccumulateTurnBarMovement(p_character_ID: int, p_fraction_moved: float) -> Array[CombatResult]:
	_BeginBatch()
	if(p_fraction_moved <= 0.0 or not _characters.has(p_character_ID)):
		return _EndBatch()
	var character: Character = _characters[p_character_ID]
	if(character._current_health <= 0):
		return _EndBatch()
	var has_temporal_leak: bool = false
	for debuff in character._active_debuffs:
		if(Types.Debuff_Type.Temporal_Leak == debuff.type):
			has_temporal_leak = true
			break
	if(not has_temporal_leak):
		return _EndBatch()

	var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Temporal_Leak)
	var progress: float = _turn_bar_progress.get(p_character_ID, 0.0) + p_fraction_moved
	while(progress >= GameBalance.TURN_BAR_PROGRESS_TRIGGER_FRACTION and character._current_health > 0):
		progress -= GameBalance.TURN_BAR_PROGRESS_TRIGGER_FRACTION
		var speed: int = GetEffectiveAttributes(p_character_ID)[Types.Attribute.Speed]
		var damage: int = int(floor(speed * data.magnitude))
		if(damage > 0):
			_ApplyHealthLoss(p_character_ID, damage)
			var result: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Tick)
			result.target_ID = p_character_ID
			result.amount = damage
			_Emit(result)
	_turn_bar_progress[p_character_ID] = progress
	return _EndBatch()

func BumpTurnBar(p_target_ID: int, p_fraction: float, p_source_ID: int = -1) -> void:
	_EmitTurnBarBump(p_target_ID, p_fraction, p_source_ID)

func AggregateDamageMultipliers(p_character_ID: int, p_amount: float) -> void:
	_damage_dealt_bonus[p_character_ID] = _damage_dealt_bonus.get(p_character_ID, 0.0) + p_amount

func BroadcastEvent(p_event: Types.Combat_Event) -> void:
	assert(_BROADCASTABLE_EVENTS.has(p_event),
			"BroadcastEvent only supports owner/resolver-shaped hooks; got " + Types.Combat_Event.keys()[p_event])
	for character_ID in _characters.keys():
		var character: Character = _characters[character_ID]
		if(null != character._trait and character._trait._execution_steps.has(p_event)):
			character._trait._execution_steps[p_event].call(character_ID, self)

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


func ResolveReagent(
		p_consumer_ID: int, p_reagent_key: String, p_target_ID: int,
		p_extra_potency: float = 0.0) -> Array[CombatResult]:
	_BeginBatch()
	var reagent: ReagentData = ReagentRegistry.Get(p_reagent_key)
	var consumer: Character = _characters[p_consumer_ID]
	var potency: float = 1.0 + p_extra_potency
	var reagent_trait: CharacterTrait = Skills.ActiveHook(consumer, Types.Combat_Event.Reagent_Consumed)
	if(not reagent.binary and null != reagent_trait):
		potency += reagent_trait.OnReagentConsumed(p_consumer_ID, reagent, self)
	_ResolveReagentEffect(p_consumer_ID, p_target_ID, reagent, potency)
	BroadcastEvent(Types.Combat_Event.Resource_Depleted)
	return _EndBatch()


## Heals each target by a fraction of their max Health, or p_raw_amount (>= 0) when given.
func ResolveTraitHeal(
		p_target_IDs: Array[int], p_max_health_fraction: float, p_raw_amount: int = -1) -> Array[CombatResult]:
	_BeginBatch()
	for target_ID in p_target_IDs:
		if(not _characters.has(target_ID) or _characters[target_ID]._current_health <= 0):
			continue
		var requested: int = (p_raw_amount if p_raw_amount >= 0
				else int(round(_MaxHealth(_characters[target_ID]) * p_max_health_fraction)))
		var healed: int = _ApplyHeal(target_ID, requested)
		var result: CombatResult = CombatResult.new(CombatResult.Kind.Heal)
		result.target_ID = target_ID
		result.amount = healed
		_Emit(result)
	return _EndBatch()


func ResolveTraitDamage(
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_damage_scaling: Dictionary[Types.Attribute, float],
		p_allow_critical: bool = true) -> Array[CombatResult]:
	_BeginBatch()
	var synthetic_skill: Skill = Skill.new()
	synthetic_skill.damage_scaling = p_damage_scaling
	var target_attributes: Dictionary[Types.Attribute, int]
	for target_ID in p_target_IDs:
		if(not _characters.has(target_ID) or _characters[target_ID]._current_health <= 0):
			continue
		target_attributes = GetEffectiveAttributes(target_ID)
		_ResolveDamage(p_caster_ID, target_ID, p_caster_attributes, target_attributes,
				synthetic_skill, 1.0, p_allow_critical)
	return _EndBatch()


func _ResolveReagentEffect(
		p_consumer_ID: int, p_target_ID: int, p_reagent: ReagentData, p_potency: float) -> void:
	match p_reagent.effect_kind:
		ReagentData.EffectKind.Attribute_Increase:
			_ApplyReagentAttributeIncrease(p_target_ID, p_reagent.affected_attribute, p_reagent.magnitude, p_potency)
		ReagentData.EffectKind.Random_Attribute_Increase:
			var attribute: Types.Attribute = ReagentResolver.RandomTinctureAttribute(_random)
			_ApplyReagentAttributeIncrease(p_target_ID, attribute, p_reagent.magnitude, p_potency)
		ReagentData.EffectKind.Heal:
			var requested: int = ReagentResolver.HealAmount(_MaxHealth(_characters[p_target_ID]), p_reagent.magnitude, p_potency)
			var healed: int = _ApplyHeal(p_target_ID, requested)
			var result: CombatResult = CombatResult.new(CombatResult.Kind.Heal)
			result.target_ID = p_target_ID
			result.amount = healed
			_Emit(result)
		ReagentData.EffectKind.Remove_Debuffs:
			_RemoveStatuses(_characters[p_target_ID]._active_debuffs, p_target_ID,
					ReagentResolver.PotencyScaledCount(p_reagent.magnitude, p_potency))
		ReagentData.EffectKind.Destroy_Enemy_Buffs:
			_RemoveStatuses(_characters[p_target_ID]._active_buffs, p_target_ID,
					ReagentResolver.PotencyScaledCount(p_reagent.magnitude, p_potency))
		ReagentData.EffectKind.Reduce_Cooldown:
			var amount: int = ReagentResolver.PotencyScaledCount(p_reagent.magnitude, p_potency)
			for skill in _characters[p_target_ID]._skills:
				if(skill.cooldown_left > 0):
					skill.cooldown_left = maxi(0, skill.cooldown_left - amount)
		ReagentData.EffectKind.Turn_Bar_Reset:
			var result: CombatResult = CombatResult.new(CombatResult.Kind.Turn_Bar_Reset_Pending)
			result.target_ID = p_consumer_ID
			result.fraction = ReagentResolver.PercentFraction(p_reagent.magnitude, p_potency)
			_Emit(result)
		ReagentData.EffectKind.Clear_Zone:
			_zone_resolver.ClearZone(p_target_ID)
		ReagentData.EffectKind.Health_Cost_Damage_Bonus:
			var consumer: Character = _characters[p_consumer_ID]
			var cost: int = ReagentResolver.HealthCostAmount(
					_MaxHealth(consumer), p_reagent.magnitude, p_potency, consumer._current_health)
			if(cost > 0):
				_ApplyHealthLoss(p_consumer_ID, cost)
				var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
				result.target_ID = p_consumer_ID
				result.amount = cost
				_Emit(result)
			AggregateDamageMultipliers(p_consumer_ID,
					ReagentResolver.PercentFraction(p_reagent.secondary_magnitude, p_potency))
		ReagentData.EffectKind.Barrier:
			var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
			barrier.type = Types.Buff_Type.Barrier
			barrier.name = "Barrier"
			barrier.duration = 2
			barrier.value = ReagentResolver.BarrierAmount(
					_MaxHealth(_characters[p_target_ID]), p_reagent.magnitude, p_potency)
			_status_resolver.ApplyBuff(p_target_ID, barrier)
		ReagentData.EffectKind.Random_Attribute_Buff:
			var buff_type: Types.Buff_Type = ReagentResolver.RandomAttributeBuff(_random)
			var buff: StatusEffects.Buff = StatusEffects.Buff.new()
			buff.type = buff_type
			buff.name = Types.Buff_Type.keys()[buff_type]
			buff.duration = 3
			buff.value = ReagentResolver.PercentFraction(p_reagent.magnitude, p_potency)
			_status_resolver.ApplyBuff(p_target_ID, buff)
		var invalid_kind:
			print("Invalid reagent effect kind: ", invalid_kind)


func _ApplyReagentAttributeIncrease(
		p_target_ID: int, p_attribute: Types.Attribute, p_magnitude: float, p_potency: float) -> void:
	var pre_status_attributes: Dictionary[Types.Attribute, int] = _characters[p_target_ID].GetTotalAttributes()
	_ApplyLongAttributeBonus(p_target_ID, pre_status_attributes)
	var current: int = pre_status_attributes[p_attribute]
	var bonus_amount: int = ReagentResolver.AttributeIncreaseAmount(current, p_magnitude, p_potency)
	AdjustLongAttributeBonus(p_target_ID, p_attribute, bonus_amount)


## Positive p_delta grants a flat attribute bonus for the rest of the battle, negative removes one.
func AdjustLongAttributeBonus(p_character_ID: int, p_attribute: Types.Attribute, p_delta: int) -> void:
	var bonus: Dictionary = _battle_long_attribute_bonus.get(p_character_ID, {})
	bonus[p_attribute] = bonus.get(p_attribute, 0) + p_delta
	_battle_long_attribute_bonus[p_character_ID] = bonus


func _RemoveStatuses(p_statuses: Array, p_target_ID: int, p_count: int) -> void:
	for i in mini(p_count, p_statuses.size()):
		var removed = p_statuses[0]
		p_statuses.remove_at(0)
		var result: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Removed)
		result.target_ID = p_target_ID
		result.status_IDs = [removed.ID]
		_Emit(result)


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


func _HasBuff(p_character_ID: int, p_type: Types.Buff_Type) -> bool:
	if(not _characters.has(p_character_ID)):
		return false
	for buff in _characters[p_character_ID]._active_buffs:
		if(buff.type == p_type):
			return true
	return false


func _HasDebuff(p_character_ID: int, p_type: Types.Debuff_Type) -> bool:
	if(not _characters.has(p_character_ID)):
		return false
	for debuff in _characters[p_character_ID]._active_debuffs:
		if(debuff.type == p_type):
			return true
	return false


func _RollsIncomingRedirect(p_target_ID: int) -> bool:
	var target: Character = _characters.get(p_target_ID)
	if(null == target or null == target._trait):
		return false
	var chance: float = target._trait.GetIncomingSingleTargetRedirectChance(p_target_ID)
	return chance > 0.0 and _random.randf() < chance


func _RandomOtherCharacter(p_excluded_ID: int) -> int:
	var candidates: Array[int] = _sides.AllMembers().filter(
			func(id: int) -> bool: return id != p_excluded_ID and _characters.has(id) and _characters[id]._current_health > 0)
	if(candidates.is_empty()):
		return -1
	return candidates[_random.randi_range(0, candidates.size() - 1)]


## Rolls once, or twice keeping the better/worse result for the roll's owner when
## they hold Luck or Hexed (an owner holding both cancels out to a single roll).
func _RollFavoring(p_character_ID: int, p_min: float, p_max: float, p_higher_is_better: bool) -> float:
	var first: float = _random.randf_range(p_min, p_max)
	var has_luck: bool = _HasBuff(p_character_ID, Types.Buff_Type.Luck)
	var has_hexed: bool = _HasDebuff(p_character_ID, Types.Debuff_Type.Hexed)
	if(has_luck == has_hexed):
		return first
	var second: float = _random.randf_range(p_min, p_max)
	if(p_higher_is_better):
		return max(first, second) if has_luck else min(first, second)
	return min(first, second) if has_luck else max(first, second)


func _EmitTurnBarBump(p_target_ID: int, p_fraction: float, p_source_ID: int = -1) -> void:
	if(0.0 == p_fraction or _HasDebuff(p_target_ID, Types.Debuff_Type.Anchor)):
		return
	if(p_fraction < 0.0 and _HasBuff(p_target_ID, Types.Buff_Type.Steadfast)):
		return
	var target: Character = _characters.get(p_target_ID)
	if(p_fraction > 0.0 and null != target and null != target._trait
			and target._trait.BlocksForwardTurnBarBump(p_target_ID)):
		return
	var bump: CombatResult = CombatResult.new(CombatResult.Kind.Turn_Bar_Bump)
	bump.target_ID = p_target_ID
	bump.fraction = p_fraction
	_Emit(bump)
	_EmitTurnBarBump(p_source_ID, Skills.TurnBarTithe(p_source_ID, p_target_ID, p_fraction, _characters, _sides, self))

func _TickCooldowns(p_caster: Character) -> void:
	if(_BlockedByFatigue(p_caster)):
		return
	for i in p_caster._skills.size():
		if(p_caster._skills[i].cooldown_left > 0):
			p_caster._skills[i].cooldown_left -= 1


func _BlockedByFatigue(p_character: Character) -> bool:
	for debuff in p_character._active_debuffs:
		if(Types.Debuff_Type.Fatigue == debuff.type):
			return true
	return false


func _MaxHealth(p_character: Character) -> int:
	var health: int = p_character.GetTotalAttribute(Types.Attribute.Health)
	for buff in p_character._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and StatusEffectData.MagnitudeKind.MaxHealthAttributePercent == data.magnitude_kind):
			health += int(ceilf(health * buff.value))
	return health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER


## Loses health, clamps, and handles the alive-to-dead transition.
func _ApplyHealthLoss(p_character_ID: int, p_amount: int) -> void:
	var reduced_amount: int = int(floor(
			float(p_amount) * _status_resolver._DamageTakenMultiplier(_characters[p_character_ID])))
	var remaining: int = _status_resolver._AbsorbWithBarrier(p_character_ID, reduced_amount)
	if(remaining <= 0):
		return
	_status_resolver._TriggerDamageTakenReactions(p_character_ID)
	var character: Character = _characters[p_character_ID]
	var was_alive: bool = character._current_health > 0
	var new_health: int = clampi(character._current_health - remaining, 0, _MaxHealth(character))
	if(was_alive and new_health <= 0):
		if(_status_resolver.ConsumeDeathwardIfPresent(p_character_ID)):
			new_health = 1
	character._current_health = new_health
	if(was_alive and character._current_health <= 0):
		_HandleDeath(p_character_ID)


## Returns the Health actually gained, after any healing-reduction debuff and clamping.
func _ApplyHeal(p_character_ID: int, p_amount: int) -> int:
	var character: Character = _characters[p_character_ID]
	var health_before: int = character._current_health
	var reduced_amount: int = int(floor(float(p_amount) * _status_resolver._HealingMultiplier(p_character_ID)))
	character._current_health = clampi(character._current_health + reduced_amount, 0, _MaxHealth(character))
	return character._current_health - health_before

func _ApplyHealthCost(p_character_ID: int, p_amount: int) -> int:
	var character: Character = _characters[p_character_ID]
	var health_before: int = character._current_health
	var capped_amount: int = mini(p_amount, health_before - 1)
	if(capped_amount <= 0):
		return 0
	_ApplyHealthLoss(p_character_ID, capped_amount)
	return health_before - character._current_health

func _HandleDeath(p_character_ID: int) -> void:
	var character: Character = _characters[p_character_ID]
	character._active_buffs.clear()
	character._active_debuffs.clear()
	var cleared: CombatResult = CombatResult.new(CombatResult.Kind.Statuses_Cleared)
	cleared.target_ID = p_character_ID
	_Emit(cleared)
	var death_trait: CharacterTrait = Skills.ActiveHook(character, Types.Combat_Event.On_Death)
	if(null != death_trait):
		death_trait.OnDeath()
	var death: CombatResult = CombatResult.new(CombatResult.Kind.Death)
	death.target_ID = p_character_ID
	_Emit(death)

	var allies: CombatTeam = _sides.AlliesOf(p_character_ID)
	if(null != allies):
		for ally_ID in allies.AliveMembers(_characters):
			var ally: Character = _characters[ally_ID]
			var ally_death_trait: CharacterTrait = Skills.ActiveHook(ally, Types.Combat_Event.Ally_Death)
			if(null != ally_death_trait):
				ally_death_trait.OnAllyDeath(ally_ID, p_character_ID, self)


## Caster-side skill mechanics that key off per-combat state (Heap On stacking).
func _ResolveSkillEffect(
		p_caster_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_skill: Skill) -> void:
	match p_skill.skill_type:
		Types.Skill_Type.Heap_On:
			if(0 == _heap_on_stacks.get(p_caster_ID, 0)):
				_heap_on_value[p_caster_ID] = (float(p_caster_attributes[Types.Attribute.Health])
						* GameBalance.HEAP_ON_MULTIPLIER)
			p_caster_attributes[Types.Attribute.Health] += int(
					_heap_on_value[p_caster_ID] * float(_heap_on_stacks.get(p_caster_ID, 0)))
			_heap_on_stacks[p_caster_ID] = _heap_on_stacks.get(p_caster_ID, 0) + 1

func _ResolveStatusGroups(
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_tick_bonus_per_debuff: float,
		p_health_paid: int = 0) -> void:
	for target_type in p_skill.buffs.keys():
		for target_ID in _ResolveStatusGroupTargets(p_caster_ID, p_target_IDs, p_skill, target_type):
			for buff_type in p_skill.buffs[target_type]:
				var value_override: float = -1.0
				if(Types.Buff_Type.Barrier == buff_type and p_skill.barrier_from_health_paid > 0.0):
					value_override = float(p_health_paid) * p_skill.barrier_from_health_paid
				_status_resolver._CastBuffOfType(target_ID, buff_type, p_skill.duration, value_override)

	for target_type in p_skill.debuffs.keys():
		for target_ID in _ResolveStatusGroupTargets(p_caster_ID, p_target_IDs, p_skill, target_type):
			for debuff_type in p_skill.debuffs[target_type]:
				var cast_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
				cast_debuff.type = debuff_type
				cast_debuff.duration = p_skill.duration
				_status_resolver.CastDebuff(target_ID, cast_debuff, p_caster_ID,
						p_tick_bonus_per_debuff, true, true)

func _ResolveStatusGroupTargets(
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_target_type: Types.Skill_Target) -> Array[int]:
	var group_IDs: Array[int] = (p_target_IDs if p_target_type == p_skill.target
			else _ResolveIndependentStatusGroup(p_caster_ID, p_target_type))
	return group_IDs.filter(func(id): return _characters.has(id) and _characters[id]._current_health > 0)

func _ResolveIndependentStatusGroup(p_caster_ID: int, p_target_type: Types.Skill_Target) -> Array[int]:
	var group_IDs: Array[int] = []
	match p_target_type:
		Types.Skill_Target.Self, Types.Skill_Target.Single_Ally:
			group_IDs = [p_caster_ID]
		Types.Skill_Target.All_Allies, Types.Skill_Target.All_Other_Allies, Types.Skill_Target.Ally_Not_Self:
			group_IDs = _sides.AlliesOf(p_caster_ID).members.duplicate()
			if(Types.Skill_Target.All_Allies != p_target_type):
				group_IDs.erase(p_caster_ID)
		Types.Skill_Target.Random_Ally:
			group_IDs = Skills.SingleTargetArray(_sides.AlliesOf(p_caster_ID).RandomAliveMember(_characters, _random))
		Types.Skill_Target.All_Enemies:
			group_IDs = _sides.EnemiesOf(p_caster_ID).members
		Types.Skill_Target.Random_Enemy:
			group_IDs = Skills.SingleTargetArray(_sides.EnemiesOf(p_caster_ID).RandomAliveMember(_characters, _random))
		Types.Skill_Target.Random_One:
			group_IDs = Skills.SingleTargetArray(_sides.RandomAliveMember(_characters, _random))
		Types.Skill_Target.All:
			group_IDs = _sides.AllMembers()
		Types.Skill_Target.Most_Injured_Ally:
			group_IDs = Skills.SingleTargetArray(
					Skills.MostInjured(_sides.AlliesOf(p_caster_ID).members, _characters, _MaxHealth))
		_:
			print("Skill target enum has no caster-relative resolution for a secondary status group: ", p_target_type)
	return group_IDs


func _ResolveDamage(
		p_caster_ID: int,
		p_target_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_target_attributes: Dictionary[Types.Attribute, int],
		p_skill: Skill,
		p_trait_multiplier: float,
		p_allow_critical: bool = true) -> void:
	var random_value: float = _RollFavoring(p_caster_ID, 0.95, 1.05, true)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	var rolled_critical: bool = false

	var effective_scaling: Dictionary[Types.Attribute, float] = p_skill.damage_scaling
	if(not effective_scaling.is_empty() and _HasDebuff(p_caster_ID, Types.Debuff_Type.Warped)):
		var total_weight: float = 0.0
		for weight in effective_scaling.values():
			total_weight += weight
		effective_scaling = {Types.Attribute.Mysticism: total_weight}

	for key in effective_scaling.keys():
		caster_scaled_attribute_aggregate += (effective_scaling[key]
				* float(p_caster_attributes[key]) * p_trait_multiplier)
	# Some status skills deal no damage. So no need to continue.
	if(0.0 == caster_scaled_attribute_aggregate):
		return

	if(_status_resolver.ConsumePremonitionIfPresent(p_target_ID, p_caster_ID)):
		return

	var target: Character = _characters[p_target_ID]
	var crit_roll: float = _RollFavoring(p_caster_ID, 1.0, 100.0, false)
	if(p_allow_critical and crit_roll <= float(
			p_caster_attributes[Types.Attribute.CritChance] + _status_resolver._AttackerCritChanceBonus(target))):
		rolled_critical = true
		crit_multiplier = max(
				GameBalance.MINIMUM_CRIT_DAMAGE,
				float(p_caster_attributes[Types.Attribute.CritDamage] + _status_resolver._AttackerCritDamageBonus(target)
						- (p_target_attributes[Types.Attribute.Knowledge] * 0.5))
				) * 0.01

	var attacker_trait: CharacterTrait = _characters[p_caster_ID]._trait
	var conditional_bonus: float = 0.0
	if(null != attacker_trait):
		conditional_bonus = attacker_trait.GetOutgoingDamageBonus(p_caster_ID, p_target_ID, self)

	var effective_defence: float = p_target_attributes[Types.Attribute.Defence] * p_skill.defense_ignore_factor
	var damage_dealt: int = Skills.MitigatedDamage(effective_defence,
			caster_scaled_attribute_aggregate, crit_multiplier, random_value,
			_damage_multiplier.get(p_caster_ID, 1.0), _damage_dealt_bonus.get(p_caster_ID, 0.0) + conditional_bonus,
			_status_resolver._OpportunistDamageMultiplier(p_caster_ID, target))

	var redirect: Array = Skills.FindDamageRedirect(self, p_caster_ID, p_target_ID)
	var soaker_ID: int = redirect[0]
	var soaker_damage: int = 0
	if(soaker_ID != -1):
		var redirect_fraction: float = float(redirect[1])
		var soaker: Character = _characters[soaker_ID]
		var soaker_defence: float = (
				GetEffectiveAttributes(soaker_ID)[Types.Attribute.Defence] * p_skill.defense_ignore_factor)
		soaker_damage = Skills.MitigatedDamage(soaker_defence,
				caster_scaled_attribute_aggregate * redirect_fraction, crit_multiplier, random_value,
				_damage_multiplier.get(p_caster_ID, 1.0), _damage_dealt_bonus.get(p_caster_ID, 0.0),
				_status_resolver._OpportunistDamageMultiplier(p_caster_ID, soaker))
		damage_dealt = int(round(damage_dealt * (1.0 - redirect_fraction)))

	_damage_multiplier.erase(p_caster_ID)

	if(soaker_damage > 0):
		_ApplyHealthLoss(soaker_ID, soaker_damage)
		_EmitDamageResult(p_caster_ID, soaker_ID, soaker_damage, rolled_critical)

	if(damage_dealt == 0):
		return
	var damage_taken_trait: CharacterTrait = Skills.ActiveHook(target, Types.Combat_Event.Damage_Taken)
	if(damage_dealt > 0 and null != damage_taken_trait):
		damage_dealt = int(round(damage_dealt * damage_taken_trait.OnDamageTaken(p_target_ID, p_caster_ID, self)))
	if(damage_dealt == 0):
		return

	_ApplyHealthLoss(p_target_ID, damage_dealt)
	_EmitDamageResult(p_caster_ID, p_target_ID, damage_dealt, rolled_critical)

	var caster: Character = _characters[p_caster_ID]
	var damage_dealt_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.Damage_Dealt)
	if(null != damage_dealt_trait):
		damage_dealt_trait.OnDamageDealt(p_caster_ID, p_target_ID, damage_dealt, self)
	if(rolled_critical):
		var critical_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.Critical_Hit)
		if(null != critical_trait):
			critical_trait.OnCriticalHit(p_caster_ID, p_target_ID, self)

	if(target._current_health <= 0 and caster._current_health > 0):
		var kill_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.On_Kill)
		if(null != kill_trait):
			kill_trait.OnKill(p_caster_ID, p_target_ID, self)


func _EmitDamageResult(p_source_ID: int, p_target_ID: int, p_amount: int, p_critical: bool) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
	result.source_ID = p_source_ID
	result.target_ID = p_target_ID
	result.amount = p_amount
	result.critical = p_critical
	_Emit(result)
