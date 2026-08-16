extends RefCounted

## Headless stand-in for the turn bar's positional queries: every character counts as
## inside every zone when `characters_in_zones` is set, and `behind_IDs` is returned
## for reach queries (the last query's arguments are recorded for assertions).
class FakeTurnPositions extends TurnPositions:
	var characters_in_zones: bool = false
	# Per-zone occupant override: zone_ID -> the character IDs currently standing in
	# it. When a zone_ID has no entry here, IsCharacterInZone falls back to the flat
	# characters_in_zones boolean (everyone in every zone, or nobody) — set an entry
	# only when a test needs one character to move in or out of one specific zone
	# (e.g. once-per-visit re-triggering).
	var occupants_by_zone: Dictionary[int, Array] = {}
	var behind_IDs: Array[int] = []
	var last_behind_query: Array = []
	var proximity_IDs: Array[int] = []
	var last_proximity_query: Array = []
	var behind_ordered_IDs: Array[int] = []
	var last_behind_ordered_query: Array = []
	var proximity_ordered_IDs: Array[int] = []
	var last_proximity_ordered_query: Array = []
	# Per-owner override for GetCharactersByProximityOrdered, for tests needing an
	# owner-dependent (e.g. mutual-nearest) result rather than one flat answer.
	var proximity_ordered_by_owner: Dictionary = {}
	# Per-character turn-bar section override; a character with no entry here reads
	# as -1 (unknown), the same conservative default the base class returns.
	var sections_by_character: Dictionary[int, int] = {}

	func IsCharacterInZone(p_character_ID: int, p_zone_ID: int) -> bool:
		if(occupants_by_zone.has(p_zone_ID)):
			return occupants_by_zone[p_zone_ID].has(p_character_ID)
		return characters_in_zones

	func GetCharactersBehindBy(p_owner_ID: int, p_bar_percent: float) -> Array[int]:
		last_behind_query = [p_owner_ID, p_bar_percent]
		return behind_IDs

	func GetCharactersWithinProximity(p_owner_ID: int, p_bar_percent: float) -> Array[int]:
		last_proximity_query = [p_owner_ID, p_bar_percent]
		return proximity_IDs

	func GetCharactersBehindOrdered(p_owner_ID: int) -> Array[int]:
		last_behind_ordered_query = [p_owner_ID]
		return behind_ordered_IDs

	func GetCharactersByProximityOrdered(p_owner_ID: int, p_bar_percent: float) -> Array[int]:
		last_proximity_ordered_query = [p_owner_ID, p_bar_percent]
		if(proximity_ordered_by_owner.has(p_owner_ID)):
			var result: Array[int] = []
			result.assign(proximity_ordered_by_owner[p_owner_ID])
			return result
		return proximity_ordered_IDs

	func GetSectionIndex(p_character_ID: int) -> int:
		return sections_by_character.get(p_character_ID, -1)

## Headless stand-in for a reagent-amplifying trait (e.g. the Sorcerer's Arcane
## Instability): always contributes a fixed additive potency amount, for testing
## that scalar reagent effects scale with the summed potency modifier.
class FakeAmplifyingTrait extends CharacterTrait:
	var contribution: float = 0.0

	func _init(p_contribution: float) -> void:
		contribution = p_contribution
		_execution_steps[Types.Combat_Event.Reagent_Consumed] = Callable(self, "OnReagentConsumed")

	func OnReagentConsumed(_p_consumer_ID: int, _p_reagent: ReagentData, _p_resolver: BattleResolver) -> float:
		return contribution

## Headless stand-in for a trait that blocks forward turn-bar bumps (e.g. Caravan
## Cadence's drawback) without applying any status.
class FakeForwardBlockingTrait extends CharacterTrait:
	func BlocksForwardTurnBarBump(_p_owner_ID: int) -> bool:
		return true

## Records the buff it was told the owner just gained (Buff_Applied), for asserting the
## dispatch passes the actual applied instance through.
class FakeBuffGainedRecorder extends CharacterTrait:
	var last_owner_ID: int = -1
	var last_buff: StatusEffects.Buff = null
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Buff_Applied] = Callable(self, "OnBuffGained")

	func OnBuffGained(p_owner_ID: int, p_buff: StatusEffects.Buff, _p_resolver: BattleResolver) -> void:
		last_owner_ID = p_owner_ID
		last_buff = p_buff
		call_count += 1

## Records the debuff it was told just landed on the owner (Debuff_Received), the
## receiver-side counterpart to Debuff_Applied's applier-side dispatch.
class FakeDebuffReceivedRecorder extends CharacterTrait:
	var last_owner_ID: int = -1
	var last_debuff: StatusEffects.Debuff = null
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Debuff_Received] = Callable(self, "OnDebuffReceived")

	func OnDebuffReceived(p_owner_ID: int, p_debuff: StatusEffects.Debuff, _p_resolver: BattleResolver) -> void:
		last_owner_ID = p_owner_ID
		last_debuff = p_debuff
		call_count += 1

## Records that the applier's Debuff_Applied hook fired (the applier-side counterpart
## to FakeDebuffReceivedRecorder's target-side dispatch).
class FakeDebuffAppliedRecorder extends CharacterTrait:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Debuff_Applied] = Callable(self, "OnDebuffApplied")

	func OnDebuffApplied(
			_p_owner_ID: int, _p_target_ID: int, _p_debuff: StatusEffects.Debuff, _p_resolver: BattleResolver) -> void:
		call_count += 1

## Headless stand-in for a trait that extends the duration of any debuff landing on its
## owner (e.g. Contagion Bond's drawback).
class FakeDebuffDurationBonusTrait extends CharacterTrait:
	var bonus: int = 0

	func _init(p_bonus: int) -> void:
		bonus = p_bonus

	func GetIncomingDebuffDurationBonus(_p_owner_ID: int) -> int:
		return bonus

## Records the attacker ID passed to OnDamageTaken (e.g. Glass Refraction/Undertow's
## retaliation), without affecting the incoming damage.
class FakeDamageTakenAttackerRecorder extends CharacterTrait:
	var last_owner_ID: int = -1
	var last_attacker_ID: int = -1
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")

	func OnDamageTaken(p_owner_ID: int, p_attacker_ID: int, _p_resolver: BattleResolver) -> float:
		last_owner_ID = p_owner_ID
		last_attacker_ID = p_attacker_ID
		call_count += 1
		return 1.0

## Headless stand-in for a trait with a fixed incoming single-target redirect chance
## (e.g. Glamour).
class FakeRedirectChanceTrait extends CharacterTrait:
	var chance: float = 0.0

	func _init(p_chance: float) -> void:
		chance = p_chance

	func GetIncomingSingleTargetRedirectChance(_p_owner_ID: int) -> float:
		return chance

## Headless stand-in for a trait with a fixed enemy-AI targeting priority multiplier
## (e.g. Glamour, Double the Fun).
class FakeTargetingPriorityTrait extends CharacterTrait:
	var multiplier: float = 1.0

	func _init(p_multiplier: float) -> void:
		multiplier = p_multiplier

	func GetTargetingPriorityMultiplier() -> float:
		return multiplier

## Headless stand-in for a trait with a fixed GetConditionCount answer for one
## Trait_Count_Source, for DamageEffect/SkillCastContext condition tests without
## needing a real character-specific trait.
class FakeConditionCountTrait extends CharacterTrait:
	var source: Types.Trait_Count_Source
	var count: float = 0.0

	func _init(p_source: Types.Trait_Count_Source, p_count: float) -> void:
		source = p_source
		count = p_count

	func GetConditionCount(
			_p_owner_ID: int,
			_p_target_ID: int,
			p_source: Types.Trait_Count_Source,
			_p_resolver: BattleResolver) -> float:
		return count if p_source == source else 0.0

static func make_character() -> Character:
	var c: Character = Character.new()
	c._name = "TestCharacter"
	c._level = 1
	c._experience = 0
	c._attributes[Types.Attribute.Health] = 10
	c._attributes[Types.Attribute.Speed] = 5
	c._attributes[Types.Attribute.Attack] = 8
	c._attributes[Types.Attribute.Defence] = 6
	c._attributes[Types.Attribute.Accuracy] = 7
	c._attributes[Types.Attribute.Resistance] = 6
	c._attributes[Types.Attribute.Mysticism] = 4
	c._attributes[Types.Attribute.Knowledge] = 4
	c._attributes[Types.Attribute.CritChance] = 5
	c._attributes[Types.Attribute.CritDamage] = 150
	return c

## Builds a full 6-slot battle roster (players 0-2, monsters 3-5), all alive.
## Handy for exercising FindSkillTargets, which now filters on existence and health.
static func make_full_roster() -> Dictionary:
	var roster: Dictionary[int, Character] = {}
	for id in range(6):
		var c: Character = make_character()
		c._current_health = c._attributes[Types.Attribute.Health]
		roster[id] = c
	return roster

## Sides matching make_full_roster(): players 0-2, monsters 3-5.
static func make_full_sides() -> CombatSides:
	return CombatSides.new([0, 1, 2], [3, 4, 5])

## A resolver over the given roster with a fixed default seed, so tests are
## reproducible unless they opt into another seed.
static func make_resolver(
		p_characters: Dictionary[int, Character],
		p_sides: CombatSides,
		p_turn_positions: TurnPositions = null,
		p_seed: int = 0) -> BattleResolver:
	return BattleResolver.new(p_characters, p_sides, p_turn_positions, p_seed)

## A plain single-enemy damage skill scaling 1:1 with Attack.
static func make_strike_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Strike"
	skill.target = Types.Skill_Target.Single_Enemy
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	skill.effects = [effect]
	return skill

## A skill with no damage, buffs, or debuffs — resolving it only ticks the caster's
## own statuses and cooldowns.
static func make_empty_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Idle"
	skill.target = Types.Skill_Target.Single_Enemy
	return skill

## A Lava-Zone-style ZoneEffect (Burning on trigger) with a generous charge count for
## tests that trigger it repeatedly.
static func make_lava_zone_effect() -> ZoneEffect:
	var burning: ApplyDebuffEffect = ApplyDebuffEffect.new()
	burning.debuff_type = Types.Debuff_Type.Burning
	burning.duration = 2
	return make_zone_effect(10, [burning])

## A bare ZoneEffect with p_charges and no on_trigger effects (or the given ones), for
## tests that only care about placement/lifecycle, not a specific triggered effect.
static func make_zone_effect(p_charges: int, p_on_trigger: Array[SkillEffect] = []) -> ZoneEffect:
	var effect: ZoneEffect = ZoneEffect.new()
	effect.charges = p_charges
	effect.on_trigger = p_on_trigger
	return effect

## Places a zone through the resolver's ZoneResolver, snapshotting the owner's current
## effective attributes the way ZoneEffect.Resolve would during a real cast.
static func place_zone(p_resolver: BattleResolver, p_zone_ID: int, p_owner_ID: int,
		p_zone_effect: ZoneEffect, p_target: Types.Skill_Target,
		p_source_name: String = "") -> Array[CombatResult]:
	return p_resolver.GetZoneResolver().PlaceZone(p_zone_ID, p_owner_ID, p_zone_effect, p_target,
			p_resolver.GetEffectiveAttributes(p_owner_ID), p_source_name)

## A SkillCastContext for effect-class unit tests, skipping ResolveSkill's turn
## machinery entirely: effects are exercised directly via effect.Resolve(context).
static func make_context(
		p_resolver: BattleResolver,
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_use_count: int = 0,
		p_trait_result: TraitSkillResult = null) -> SkillCastContext:
	var caster_attributes: Dictionary[Types.Attribute, int] = p_resolver.GetEffectiveAttributes(p_caster_ID)
	var trait_result: TraitSkillResult = p_trait_result if null != p_trait_result else TraitSkillResult.new()
	return SkillCastContext.new(p_resolver, p_caster_ID, p_target_IDs, p_skill, caster_attributes,
			p_use_count, trait_result)

static func make_loot_table() -> LootTable:
	return LootTable.new()

static func make_adventure_state() -> AdventureState:
	return AdventureState.new()
