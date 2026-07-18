extends RefCounted

## Headless stand-in for the turn bar's positional queries: every character counts as
## inside every zone when `characters_in_zones` is set, and `behind_IDs` is returned
## for reach queries (the last query's arguments are recorded for assertions).
class FakeTurnPositions extends TurnPositions:
	var characters_in_zones: bool = false
	var behind_IDs: Array[int] = []
	var last_behind_query: Array = []

	func IsCharacterInZone(_p_character_ID: int, _p_zone_ID: int) -> bool:
		return characters_in_zones

	func GetCharactersBehindBy(p_owner_ID: int, p_bar_percent: float) -> Array[int]:
		last_behind_query = [p_owner_ID, p_bar_percent]
		return behind_IDs

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
	skill.damage_scaling = {Types.Attribute.Attack: 1.0}
	return skill

## A skill with no damage, buffs, or debuffs — resolving it only ticks the caster's
## own statuses and cooldowns.
static func make_empty_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Idle"
	skill.target = Types.Skill_Target.Single_Enemy
	return skill

static func make_lava_zone_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Lava Zone"
	skill.target = Types.Skill_Target.ZoneAll
	skill.skill_type = Types.Skill_Type.Lava_Zone
	skill.duration = 10
	skill.debuffs = {Types.Skill_Target.ZoneAll: Types.Debuff_Type.Burning}
	return skill

static func make_loot_table() -> LootTable:
	return LootTable.new()

static func make_adventure_state() -> AdventureState:
	return AdventureState.new()
