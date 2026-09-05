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
const ROSTER_SLOT_BASE_PRICE: int = 1000
const ROSTER_SLOT_PRICE_INCREMENT: int = 500

## Tallies
const TALLY_VALUE_PER_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Common: 0,
	Types.Rarity.Uncommon: 1,
	Types.Rarity.Rare: 4,
	Types.Rarity.Epic: 20,
	Types.Rarity.Legendary: 100,
}

## Release
const RELEASE_SILVER_PER_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Common: 0,
	Types.Rarity.Uncommon: 200,
	Types.Rarity.Rare: 600,
	Types.Rarity.Epic: 2000,
	Types.Rarity.Legendary: 8000,
}
const RELEASE_SUPPLIES_PER_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Common: 0,
	Types.Rarity.Uncommon: 5,
	Types.Rarity.Rare: 15,
	Types.Rarity.Epic: 40,
	Types.Rarity.Legendary: 100,
}
const RELEASE_SILVER_LEVEL_DIVISOR: int = 25

## Tally Board
const TALLY_BOARD_SLOTS: int = 3
const TALLY_BOARD_RESTOCK_INTERVAL_SECONDS: int = 86400
const TALLY_BOARD_PRICE_PER_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Common: 0,
	Types.Rarity.Uncommon: 40,
	Types.Rarity.Rare: 150,
	Types.Rarity.Epic: 600,
	Types.Rarity.Legendary: 2500,
}

## Renown
const RENOWN_MAX_RANK: int = 5
const RENOWN_ATTRIBUTE_BONUS_PERCENT: int = 6
const RENOWN_SPEED_BONUS_PERCENT: int = 3
const RENOWN_ATTRIBUTES: Array[Types.Attribute] = [
	Types.Attribute.Health,
	Types.Attribute.Speed,
	Types.Attribute.Attack,
	Types.Attribute.Defence,
	Types.Attribute.Accuracy,
	Types.Attribute.Resistance,
	Types.Attribute.Mysticism,
	Types.Attribute.Knowledge,
]

## Experience Formula
# XPrequired =
# (Level / EXPERIENCE_FACTOR)^EXPERIENCE_EXPONENT * EXPERIENCE_CONSTANT_1
# + EXPERIENCE_CONSTANT_2 * Level + EXPERIENCE_CONSTANT_3
const EXPERIENCE_FACTOR: float = 1.3
const EXPERIENCE_EXPONENT: float = 2.4
const EXPERIENCE_CONSTANT_1: float = 9.295
const EXPERIENCE_CONSTANT_2: float = 10.0
const EXPERIENCE_CONSTANT_3: float = 10.0

## Level up
const LEVEL_UP_POINTS_TO_DISTRIBUTE: int = 20
const MAX_LEVEL: int = 50

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
		
	Types.Slot.OffHand: [
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
const FLICKER_ZONE_BASE_BUMP: float = 0.15
# Ally turn bar zone effect magnitude scaling per point of the placing character's Knowledge.
const ZONE_KNOWLEDGE_SCALING: float = 0.005

## Barrier
# Additive attribute-scaled Barrier: ceil((BASE + COEFF * attribute) * (1 + bonus)).
const BARRIER_ZONE_BASE: float = 5.0
const BARRIER_ZONE_KNOWLEDGE_COEFF: float = 0.75
const BARRIER_DIRECT_BASE: float = 5.0
const BARRIER_DIRECT_COEFF: float = 1.0

## Battle, Combat
const TURN_DURATION_SECONDS: float = 2.5
const NUMBER_OF_TURN_BAR_ZONES: int = 5
const MAX_STATUS_EFFECTS: int = 8
const MINIMUM_DMG_PERCENT: float = 0.1
# Defence's mitigation ratio is Defence / (Defence + DEFENCE_SCALE_CONSTANT)
const DEFENCE_SCALE_CONSTANT: float = 100.0
# Fraction of turn-bar progress that triggers movement-based damage.
const TURN_BAR_PROGRESS_TRIGGER_FRACTION: float = 0.1
const MAX_DIFFICULTY: int = 20
const MINIMUM_CRIT_DAMAGE: float = 125.0
# Sentinel duration for "active for the rest of the battle" (never decremented within it).
const BATTLE_PERMANENT_EFFECT: int = 999999

# Resources
const MAX_SUPPLIES: int = 100
const SUPPLY_REGEN_AMOUNT: int = 10
const SUPPLY_REGEN_INTERVAL_SECONDS: int = 600
const ENCOUNTER_BASE_SUPPLY_COST: int = 6 # base; surcharges (e.g. adventure tier) add on top
const ADVENTURE_SUPPLY_COST_TIER_INCREASE: int = 3

# Shop
const SHOP_SLOT_COUNT: int = 6
const SHOP_GEAR_SLOTS: int = 3
const SHOP_RESTOCK_INTERVAL_SECONDS: int = 3600
const SHOP_FORTUNES_FAVOR_COOLDOWN_SECONDS: int = 259200 # 3 days
const SHOP_BUY_MARKUP: float = 2.5
const SHOP_RELIC_MARKUP_MULTIPLIER: float = 3.0
const SHOP_SUPPLIES_BUNDLE_AMOUNT: int = 25
const SHOP_SUPPLIES_PRICE: int = 400
const SHOP_FORTUNES_FAVOR_PRICE: int = 1200

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
