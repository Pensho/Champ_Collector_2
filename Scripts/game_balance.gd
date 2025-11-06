class_name GameBalance
extends Resource

const Types = preload("res://Scripts/common_enums.gd")

## Character
const CHARACTER_BASE_CRIT_CH: int = 5
const CHARACTER_BASE_CRIT_DMG: int = 150

const ATTRIBUTE_HEALTH_MULTIPLIER: int = 7

## CharacterCollection
const COLLECTION_START_ROSTER_SIZE: int = 50
const COLLECTION_SIZE_INCREMENT: int = 10
const COLLECTION_LIMIT: int = 200

## Experience Formula
# XPrequired =
# (Level / EXPERIENCE_FACTOR)^EXPERIENCE_EXPONENT * EXPERIENCE_CONSTANT_1
# + EXPERIENCE_CONSTANT_2 * Level + EXPERIENCE_CONSTANT_3
const EXPERIENCE_FACTOR: float = 1.3
const EXPERIENCE_EXPONENT: float = 2.37
const EXPERIENCE_CONSTANT_1: int = 8
const EXPERIENCE_CONSTANT_2: int = 1
const EXPERIENCE_CONSTANT_3: int = 5

## Level up
const LEVEL_UP_POINTS_TO_DISTRIBUTE: int = 19
const CHARACTER_ATTRIBUTE_WEIGHT: int = 5
const BASE_ATTRIBUTE_WEIGHTS: Dictionary[Types.Attribute, int] = {
	Types.Attribute.Health: 5,
	Types.Attribute.Speed: 1,
	Types.Attribute.Attack: 5,
	Types.Attribute.Defence: 5,
	Types.Attribute.Accuracy: 5,
	Types.Attribute.Resistance: 5,
	Types.Attribute.Mysticism: 5,
	Types.Attribute.Knowledge: 4,
}

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
		Types.Attribute.Mysticism,],
		
	Types.Slot.Boots: [
		Types.Attribute.Speed,
		Types.Attribute.Health,
		Types.Attribute.Accuracy,
		Types.Attribute.Knowledge,
		Types.Attribute.Attack,
		Types.Attribute.Defence,
		Types.Attribute.CritChance,],
}
const ITEM_COLLECTION_LIMIT: int = 1000

## Skills
const HEAP_ON_MULTIPLIER: float = 0.2

## Battle, Combat
const TURN_DURATION_SECONDS: float = 2.5
const NUMBER_OF_TURN_BAR_ZONES: int = 5
