class_name BattleResolver extends RefCounted

## Pure combat-resolution core. Owns per-combat transient state (Heap-On stacks, damage
## multipliers, zones), a seedable RNG, and the status-effect identity counter. Mutates
## Character state and reports everything as CombatResult records, never touching UI nodes.

signal result_produced(p_result: CombatResult)

enum Winner {
	Ongoing,
	Player_Won,
	Monsters_Won,
}

## Combined_Modifier bucket key for the resolver-owned reagent/graft damage bonus (Concept
## Document 1.1.3): kept as one mechanic since _damage_dealt_bonus already sums those
## contributions before this bucket sees them — see _ResolveDamage.
const _REAGENT_DAMAGE_BONUS_KEY: StringName = &"reagent_damage_bonus"

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
var _cascade_resolver: CascadeResolver
var _current_cascade_depth: int = 0

var _skill_use_counts: Dictionary[String, int] = {}

# Inner Dictionary is Dictionary[Types.Attribute, int]
# keyed by attribute with the accumulated bonus.
var _battle_long_attribute_bonus: Dictionary[int, Dictionary] = {}
# Battle persistent damage-dealt multiplier.
var _damage_dealt_bonus: Dictionary[int, float] = {}

var _next_status_ID: int = 0
var _batch: Array[CombatResult] = []
var _batch_depth: int = 0

var _turn_bar_progress: Dictionary[int, float] = {}
var _turn_bar_damage_remainder: Dictionary[int, float] = {}

# The turn-bar section a player just clicked, consumed once by the next ZoneEffect
# placement in the skill they cast it for; -1 when nothing is pending (an enemy's own
# zone skill has no player choice to consume, so it falls back to a random section).
var _pending_zone_section: int = -1


## Pass a non-negative p_seed for reproducible rolls (e.g. from the encounter); negative randomizes.
func _init(
		p_characters: Dictionary[int, Character],
		p_sides: CombatSides,
		p_turn_positions: TurnPositions = null,
		p_seed: int = -1) -> void:
	_characters = p_characters
	_sides = p_sides
	_turn_positions = p_turn_positions if p_turn_positions != null else TurnPositions.new()
	_cascade_resolver = CascadeResolver.new(self)
	_status_resolver = StatusEffectResolver.new(self)
	_zone_resolver = ZoneResolver.new(self)
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


func GetCascadeResolver() -> CascadeResolver:
	return _cascade_resolver


func SetPendingZoneSection(p_zone_ID: int) -> void:
	_pending_zone_section = p_zone_ID


## Consumes and returns the pending player-chosen section, or -1 if none is pending.
func ConsumePendingZoneSection() -> int:
	var section: int = _pending_zone_section
	_pending_zone_section = -1
	return section


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
	return Skills.FindSkillTargets(p_target_ID, p_caster_ID, effective_type, _characters, _sides, _random, _MaxHealth)


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
	_cascade_resolver.Drain()  # so a tick-triggered cascade precedes the effects below

	var use_count: int = _SkillUseCount(p_caster_ID, cast_skill)
	var context := SkillCastContext.new(self, p_caster_ID, p_target_IDs, cast_skill, caster_attributes,
			use_count, trait_result)
	for effect in cast_skill.effects:
		if(context.ConditionMet(effect)):
			effect.Resolve(context)

	if(caster._current_health > 0):
		var skill_effects_resolved_trait: CharacterTrait = Skills.ActiveHook(
				caster, Types.Combat_Event.Skill_Effects_Resolved)
		if(null != skill_effects_resolved_trait):
			skill_effects_resolved_trait.OnSkillEffectsResolved(
					p_caster_ID, p_target_IDs, cast_skill.name, caster_attributes, self)

	_cascade_resolver.Post(CascadeEvent.ForSkillResolved(p_caster_ID, p_skill_ID, p_target_IDs))
	_cascade_resolver.Drain()  # catches Mirror Coat (from CastDebuff above) and Skill_Resolved listeners
	var is_non_basic: bool = cast_skill.cooldown > 0
	_status_resolver._TriggerManaBurn(p_caster_ID, caster_attributes, is_non_basic)

	for target_ID in p_target_IDs:
		if(not _characters.has(target_ID)):
			continue
		_EmitTurnBarBump(target_ID, trait_result._turn_bar_bump, p_caster_ID)

	_TickCooldowns(caster)
	if(not (is_non_basic and _status_resolver._ConsumeRehearsedIfPresent(p_caster_ID))):
		caster._skills[p_skill_ID].cooldown_left = caster._skills[p_skill_ID].cooldown

	_zone_resolver.TriggerZones(p_caster_ID)

	if(caster._current_health > 0):
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
	_cascade_resolver.Drain()
	_TickCooldowns(caster)
	_zone_resolver.TriggerZones(p_caster_ID)
	if(caster._current_health > 0):
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
	var leak: StatusEffects.Debuff = null
	for debuff in character._active_debuffs:
		if(Types.Debuff_Type.Temporal_Leak == debuff.type):
			leak = debuff
			break
	if(null == leak):
		return _EndBatch()

	var data: StatusEffectData = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Temporal_Leak)
	# The applier's channel-2 factors are frozen into leak.value at application (see
	# StatusEffectResolver._SnapshotStatusValue); 0.0 means the debuff was placed directly
	# rather than through ApplyDebuff/CastDebuff (test setup), so treat that as neutral.
	var multiplier: float = leak.value if 0.0 != leak.value else 1.0
	var progress: float = _turn_bar_progress.get(p_character_ID, 0.0) + p_fraction_moved
	var remainder: float = _turn_bar_damage_remainder.get(p_character_ID, 0.0)
	while(progress >= GameBalance.TURN_BAR_PROGRESS_TRIGGER_FRACTION and character._current_health > 0):
		progress -= GameBalance.TURN_BAR_PROGRESS_TRIGGER_FRACTION
		var speed: int = GetEffectiveAttributes(p_character_ID)[Types.Attribute.Speed]
		remainder += float(speed) * data.magnitude * multiplier
		var damage: int = int(floor(remainder))
		remainder -= float(damage)
		if(damage > 0):
			var actual_damage: int = _ApplyHealthLoss(p_character_ID, damage)
			var result: CombatResult = CombatResult.new(CombatResult.Kind.Debuff_Tick)
			result.source_ID = leak.source_ID
			result.target_ID = p_character_ID
			result.amount = actual_damage
			_Emit(result)
	_turn_bar_progress[p_character_ID] = progress
	_turn_bar_damage_remainder[p_character_ID] = remainder
	return _EndBatch()

func BumpTurnBar(p_target_ID: int, p_fraction: float, p_source_ID: int = -1) -> void:
	_EmitTurnBarBump(p_target_ID, p_fraction, p_source_ID)


## Public entry point for a DamageEffect: resolves one hit like skill/trait damage,
## including the target's Defend hook (e.g. LancerTrait raising Defence) when the caster isn't the target.
func ResolveEffectDamage(
		p_caster_ID: int,
		p_target_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_damage_scaling: Dictionary[Types.Attribute, float],
		p_defense_ignore_factor: float,
		p_combined_damage_modifier: CombinedDamageModifier,
		p_allow_critical: bool = true) -> void:
	var target_attributes: Dictionary[Types.Attribute, int] = GetEffectiveAttributes(p_target_ID)
	if(p_caster_ID != p_target_ID and _characters.has(p_target_ID) and _characters[p_target_ID]._current_health > 0):
		var defend_trait: CharacterTrait = Skills.ActiveHook(_characters[p_target_ID], Types.Combat_Event.Defend)
		if(null != defend_trait):
			defend_trait.OnDefend(p_target_ID, target_attributes, _characters)
	_ResolveDamage(p_caster_ID, p_target_ID, p_caster_attributes, target_attributes, p_damage_scaling,
			p_defense_ignore_factor, p_combined_damage_modifier, p_allow_critical)


## Applies a Health cost to p_character_ID and emits the resulting Damage result.
## Returns the Health actually paid.
func ResolveHealthCost(p_character_ID: int, p_amount: int) -> int:
	var paid: int = _ApplyHealthCost(p_character_ID, p_amount)
	if(paid > 0):
		var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
		result.target_ID = p_character_ID
		result.amount = paid
		_Emit(result)
	return paid


## Heals p_character_ID and emits the resulting Heal result. Returns the Health
## actually gained.
func ResolveHealthGain(p_character_ID: int, p_amount: int) -> int:
	var healed: int = _ApplyHeal(p_character_ID, p_amount)
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Heal)
	result.target_ID = p_character_ID
	result.amount = healed
	_Emit(result)
	return healed

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


## Emits the presentation-only marker that precedes one burst instance's results, so the
## battle view can escalate their combat text (Concept_Document.md 1.1.5). Emitted by the
## cascade channel and by trait-local instance loops that bypass it.
func EmitBurstInstance(
		p_mechanic_key: StringName,
		p_subject_ID: int,
		p_trigger: Types.Cascade_Trigger) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Cascade_Triggered)
	result.target_ID = p_subject_ID
	result.text = String(p_mechanic_key)
	result.cascade_trigger = p_trigger
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
	if(not reagent.binary):
		var reagent_trait: CharacterTrait = Skills.ActiveHook(consumer, Types.Combat_Event.Reagent_Consumed)
		if(null != reagent_trait):
			potency += reagent_trait.OnReagentConsumed(p_consumer_ID, reagent, self)
		potency += _status_resolver.ConsumeCatalystIfPresent(p_consumer_ID)
	_ResolveReagentEffect(p_consumer_ID, p_target_ID, reagent, potency)
	Skills.TriggerAllyReagentConsumedHook(_sides, _characters, p_consumer_ID, reagent, self)
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
	var target_attributes: Dictionary[Types.Attribute, int]
	for target_ID in p_target_IDs:
		if(not _characters.has(target_ID) or _characters[target_ID]._current_health <= 0):
			continue
		target_attributes = GetEffectiveAttributes(target_ID)
		_ResolveDamage(p_caster_ID, target_ID, p_caster_attributes, target_attributes,
				p_damage_scaling, 1.0, CombinedDamageModifier.new(), p_allow_critical)
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
				var actual_cost: int = _ApplyHealthLoss(p_consumer_ID, cost)
				var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
				result.target_ID = p_consumer_ID
				result.amount = actual_cost
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
	if(_batch_depth == 1):
		_cascade_resolver.Drain()
	_batch_depth -= 1
	if(_batch_depth == 0):
		_cascade_resolver.ResetForNextAction()
	return _batch


func _Emit(p_result: CombatResult) -> void:
	p_result.cascade_depth = _current_cascade_depth
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
	return chance > 0.0 and RollFavoring(p_target_ID, 0.0, 1.0, false) < chance


func _RandomOtherCharacter(p_excluded_ID: int) -> int:
	var candidates: Array[int] = _sides.AllMembers().filter(
			func(id: int) -> bool: return id != p_excluded_ID and _characters.has(id) and _characters[id]._current_health > 0)
	if(candidates.is_empty()):
		return -1
	return candidates[_random.randi_range(0, candidates.size() - 1)]


## Rolls once, or twice keeping the better/worse result for the roll's owner when
## they hold Luck or Hexed (an owner holding both cancels out to a single roll).
func RollFavoring(p_character_ID: int, p_min: float, p_max: float, p_higher_is_better: bool) -> float:
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
	Skills.DispatchAllyTurnBarIncreased(p_source_ID, p_target_ID, p_fraction, _characters, _sides, self)
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

func _ApplyHealthLoss(p_character_ID: int, p_amount: int) -> int:
	var reduced_amount: int = int(floor(
			float(p_amount) * _status_resolver._DamageTakenMultiplier(_characters[p_character_ID])))
	var remaining: int = _status_resolver._AbsorbWithBarrier(p_character_ID, reduced_amount)
	if(remaining <= 0):
		return 0
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
	return remaining


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


## How many times p_caster_ID has cast p_skill this battle so far, including this
## cast (so the first call returns 0). Advances the shared per-skill counter.
func _SkillUseCount(p_caster_ID: int, p_skill: Skill) -> int:
	var key: String = "%d:%s" % [p_caster_ID, p_skill.name]
	var uses: int = _skill_use_counts.get(key, 0)
	_skill_use_counts[key] = uses + 1
	return uses


## Contributes the caster's persistent channel-2 factors (trait bonus, reagent/graft bonus,
## Opportunist) into the modifier — shared by attack resolution and any tick needing the
## caster's damage-scaling state. Excludes DamageMultiplier buffs, consumed by an attack.
func _ContributePersistentCasterFactors(
		p_caster_ID: int, p_target_ID: int, p_modifier: CombinedDamageModifier) -> void:
	if(not _characters.has(p_caster_ID) or not _characters.has(p_target_ID)):
		return
	var target: Character = _characters[p_target_ID]
	var attacker_trait: CharacterTrait = _characters[p_caster_ID]._trait
	if(null != attacker_trait):
		p_modifier.Contribute(StringName(attacker_trait.get_script().get_global_name()),
				attacker_trait.GetOutgoingDamageBonus(p_caster_ID, p_target_ID, self))
	p_modifier.Contribute(_REAGENT_DAMAGE_BONUS_KEY, _damage_dealt_bonus.get(p_caster_ID, 0.0))
	var opportunist_factors: Dictionary[StringName, float] = (
			_status_resolver._OpportunistDamageFactors(p_caster_ID, target))
	for key: StringName in opportunist_factors:
		p_modifier.Contribute(key, opportunist_factors[key])
	var missing_health_factors: Dictionary[StringName, float] = (
			_status_resolver._MissingHealthDamageFactors(p_caster_ID, p_target_ID, target))
	for key: StringName in missing_health_factors:
		p_modifier.Contribute(key, missing_health_factors[key])
	var debuff_value_factors: Dictionary[StringName, float] = (
			_status_resolver._DebuffValueDamageFactors(target))
	for key: StringName in debuff_value_factors:
		p_modifier.Contribute(key, debuff_value_factors[key])


func _ResolveDamage(
		p_caster_ID: int,
		p_target_ID: int,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_target_attributes: Dictionary[Types.Attribute, int],
		p_damage_scaling: Dictionary[Types.Attribute, float],
		p_defense_ignore_factor: float,
		p_combined_damage_modifier: CombinedDamageModifier,
		p_allow_critical: bool = true) -> void:
	var random_value: float = _random.randf_range(0.95, 1.05)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	var rolled_critical: bool = false

	var effective_scaling: Dictionary[Types.Attribute, float] = p_damage_scaling
	if(not effective_scaling.is_empty() and _HasDebuff(p_caster_ID, Types.Debuff_Type.Warped)):
		var total_weight: float = 0.0
		for weight in effective_scaling.values():
			total_weight += weight
		effective_scaling = {Types.Attribute.Mysticism: total_weight}

	for key in effective_scaling.keys():
		caster_scaled_attribute_aggregate += effective_scaling[key] * float(p_caster_attributes[key])
	# Some status skills deal no damage. So no need to continue.
	if(0.0 == caster_scaled_attribute_aggregate):
		return

	if(_status_resolver.ConsumePremonitionIfPresent(p_target_ID, p_caster_ID)):
		return

	var target: Character = _characters[p_target_ID]
	var crit_roll: float = RollFavoring(p_caster_ID, 1.0, 100.0, false)
	if(p_allow_critical):
		var total_crit_chance: float = float(
				p_caster_attributes[Types.Attribute.CritChance] + _status_resolver._AttackerCritChanceBonus(target))
		if(crit_roll <= total_crit_chance):
			rolled_critical = true
			var overflow_rate: float = Skills.CritChanceOverflowRate(_sides, _characters, p_caster_ID)
			var overflow_crit_damage: float = maxf(0.0, total_crit_chance - 100.0) * overflow_rate
			crit_multiplier = max(
					GameBalance.MINIMUM_CRIT_DAMAGE,
					float(p_caster_attributes[Types.Attribute.CritDamage] + _status_resolver._AttackerCritDamageBonus(target))
							+ overflow_crit_damage - (p_target_attributes[Types.Attribute.Knowledge] * 0.5)
					) * 0.01

	_ContributePersistentCasterFactors(p_caster_ID, p_target_ID, p_combined_damage_modifier)
	var damage_multiplier_factors: Dictionary[StringName, float] = (
			_status_resolver.ConsumeDamageMultiplierFactors(p_caster_ID))
	for key: StringName in damage_multiplier_factors:
		p_combined_damage_modifier.Contribute(key, damage_multiplier_factors[key])
	caster_scaled_attribute_aggregate *= p_combined_damage_modifier.Product()

	var effective_defence: float = p_target_attributes[Types.Attribute.Defence] * p_defense_ignore_factor
	var damage_dealt: int = Skills.MitigatedDamage(effective_defence,
			caster_scaled_attribute_aggregate, crit_multiplier, random_value)

	var redirect: Array = Skills.FindDamageRedirect(self, p_caster_ID, p_target_ID)
	var soaker_ID: int = redirect[0]
	var soaker_damage: int = 0
	if(soaker_ID != -1):
		var redirect_fraction: float = float(redirect[1])
		var soaker_defence: float = (
				GetEffectiveAttributes(soaker_ID)[Types.Attribute.Defence] * p_defense_ignore_factor)
		soaker_damage = Skills.MitigatedDamage(soaker_defence,
				caster_scaled_attribute_aggregate * redirect_fraction, crit_multiplier, random_value)
		damage_dealt = int(round(damage_dealt * (1.0 - redirect_fraction)))

	if(soaker_damage > 0):
		var actual_soaker_damage: int = _ApplyHealthLoss(soaker_ID, soaker_damage)
		_EmitDamageResult(p_caster_ID, soaker_ID, actual_soaker_damage, rolled_critical, p_combined_damage_modifier)

	if(damage_dealt == 0):
		return
	if(target._current_health > 0):
		var damage_taken_trait: CharacterTrait = Skills.ActiveHook(target, Types.Combat_Event.Damage_Taken)
		if(damage_dealt > 0 and null != damage_taken_trait):
			damage_dealt = int(round(damage_dealt * damage_taken_trait.OnDamageTaken(p_target_ID, p_caster_ID, self)))
	if(damage_dealt == 0):
		return

	var actual_damage_dealt: int = _ApplyHealthLoss(p_target_ID, damage_dealt)
	_EmitDamageResult(p_caster_ID, p_target_ID, actual_damage_dealt, rolled_critical, p_combined_damage_modifier)

	var caster: Character = _characters[p_caster_ID]
	if(caster._current_health > 0):
		var damage_dealt_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.Damage_Dealt)
		if(null != damage_dealt_trait):
			damage_dealt_trait.OnDamageDealt(p_caster_ID, p_target_ID, actual_damage_dealt, self)
		if(rolled_critical):
			var critical_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.Critical_Hit)
			if(null != critical_trait):
				critical_trait.OnCriticalHit(p_caster_ID, p_target_ID, self)

	if(target._current_health <= 0 and caster._current_health > 0):
		var kill_trait: CharacterTrait = Skills.ActiveHook(caster, Types.Combat_Event.On_Kill)
		if(null != kill_trait):
			kill_trait.OnKill(p_caster_ID, p_target_ID, self)


func _EmitDamageResult(
		p_source_ID: int, p_target_ID: int, p_amount: int, p_critical: bool,
		p_combined_damage_modifier: CombinedDamageModifier) -> void:
	var result: CombatResult = CombatResult.new(CombatResult.Kind.Damage)
	result.source_ID = p_source_ID
	result.target_ID = p_target_ID
	result.amount = p_amount
	result.critical = p_critical
	result.combined_damage_modifier = p_combined_damage_modifier
	_Emit(result)
