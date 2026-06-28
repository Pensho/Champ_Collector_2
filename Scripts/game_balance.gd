class_name GameBalance
extends Node

## Character
const CHARACTER_BASE_CRIT_CH: int = 5
const CHARACTER_BASE_CRIT_DMG: int = 150

const ATTRIBUTE_HEALTH_MULTIPLIER: int = 4

## CharacterCollection
const COLLECTION_START_ROSTER_SIZE: int = 50
const COLLECTION_SIZE_INCREMENT: int = 10
const COLLECTION_LIMIT: int = 200

## Experience Formula
# XPrequired =
# (Level / EXPERIENCE_FACTOR)^EXPERIENCE_EXPONENT * EXPERIENCE_CONSTANT_1
# + EXPERIENCE_CONSTANT_2 * Level + EXPERIENCE_CONSTANT_3
const EXPERIENCE_FACTOR: float = 1.3
const EXPERIENCE_EXPONENT: float = 2.4
const EXPERIENCE_CONSTANT_1: float = 9.0
const EXPERIENCE_CONSTANT_2: float = 9.0
const EXPERIENCE_CONSTANT_3: float = 0.0

## Level up
const LEVEL_UP_POINTS_TO_DISTRIBUTE: int = 20

## Item
const ITEM_ATTRIBUTE_PER_RARITY: int = 5
# Item attribute composition
const ITEM_TYPE_ATTRIBUTES: Dictionary = {
	Types.Slot.Weapon: [
		Types.Attribute.Attack,
		Types.Attribute.Mysticism,
		Types.Attribute.Accuracy,
		Types.Attribute.CritChance,
		Types.Attribute.CritDamage,],
		
	Types.Slot.Shield: [
		Types.Attribute.Health,
		Types.Attribute.Defence,
		Types.Attribute.Resistance,
		Types.Attribute.Mysticism,
		Types.Attribute.Accuracy,],
		
	Types.Slot.Boots: [
		Types.Attribute.Speed,
		Types.Attribute.Health,
		Types.Attribute.Accuracy,
		Types.Attribute.Knowledge,
		Types.Attribute.Attack,
		Types.Attribute.Defence,
		Types.Attribute.CritChance,],
}
const ITEM_COLLECTION_LIMIT: int = 400
const MAX_ITEM_LEVEL: int = 10
const ITEM_UPGRADE_FLAT_BONUS: int = 3
const BASE_ITEM_UPGRADE_COST: int = 25

## Skills
const HEAP_ON_MULTIPLIER: float = 0.2

## Battle, Combat
const TURN_DURATION_SECONDS: float = 2.5
const NUMBER_OF_TURN_BAR_ZONES: int = 5
const MAX_STATUS_EFFECTS: int = 8
const MINIMUM_DMG_PERCENT: float = 0.1
const MAX_DIFFICULTY: int = 20
const MINIMUM_CRIT_DAMAGE: float = 125.0

# Resources
const MAX_SUPPLIES: int = 100
const SUPPLY_REGEN_AMOUNT: int = 10
const SUPPLY_REGEN_INTERVAL_SECONDS: int = 600
const ENCOUNTER_BASE_SUPPLY_COST: int = 6 # base; surcharges (e.g. adventure tier) add on top

# Adventure
const ADVENTURE_DAILY_TIER_THRESHOLD: int = 3
const ADVENTURE_ENERGY_COST_TIER_2_MULTIPLIER: int = 2
const ADVENTURE_MAX_DAILY_STEPS: int = 6

# Adventure-spanning effects
# Sentinel value for "active for the rest of the adventure" (never decremented).
const ADVENTURE_PERMANENT_EFFECT: int = 999999
# Turn duration applied to an adventure-spanning buff/debuff so it lasts an entire combat.
const ADVENTURE_BUFF_COMBAT_DURATION: int = 5
const ADVENTURE_REST_STOP_TIER_1_COMBATS: int = 1
const ADVENTURE_REST_STOP_TIER_2_COMBATS: int = 3
const ADVENTURE_REST_STOP_TIER_1_COST: int = 0
const ADVENTURE_REST_STOP_TIER_2_COST: int = 6
const ADVENTURE_REST_STOP_TIER_3_COST: int = 18
const ADVENTURE_GAMBLE_BUFF_COMBATS: int = 4
const ADVENTURE_GAMBLE_DEBUFF_COMBATS: int = 3
const ADVENTURE_ESCALATE_DIFFICULTY_INCREASE: int = 1
const ADVENTURE_HINT_REWARD_BUDGET_FRACTION: float = 0.05
const ADVENTURE_ESCALATE_REWARD_BUDGET_FRACTION: float = 0.15
