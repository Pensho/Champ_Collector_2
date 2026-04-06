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

## Skills
const HEAP_ON_MULTIPLIER: float = 0.2

## Battle, Combat
const TURN_DURATION_SECONDS: float = 2.5
const NUMBER_OF_TURN_BAR_ZONES: int = 5
const MAX_STATUS_EFFECTS: int = 8
const MINIMUM_DMG_PERCENT: float = 0.1
const MAX_DIFFICULTY: int = 20

# Resources
const MAX_SUPPLIES: int = 100
