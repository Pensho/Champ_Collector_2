class_name LevelSystem
extends Node

const Types = preload("res://Scripts/common_enums.gd")

const FACTOR: float = 1.3
const CONSTANT_1: float = 2.0
const CONSTANT_2: int = 10
const CONSTANT_3: int = 10

const BASE_WEIGHTS: Dictionary[Types.Attribute, int] = {
	Types.Attribute.Health: 5,
	Types.Attribute.Speed: 1,
	Types.Attribute.Attack: 5,
	Types.Attribute.Defence: 5,
	Types.Attribute.Accuracy: 5,
	Types.Attribute.Resistance: 5,
	Types.Attribute.Mysticism: 5,
	Types.Attribute.Knowledge: 4,
	Types.Attribute.Pressence: 4,
}

const POINTS_TO_DISTRIBUTE: int = 19
const PRIMARY_ATTRIBUTE_MODIFIER: int = 5

static func LevelUpCriteriaMet(p_character: Character) -> bool:
	var xp_requirement: float = pow((float(p_character._level) / FACTOR), CONSTANT_1)
	xp_requirement *= CONSTANT_2
	xp_requirement += CONSTANT_3 * p_character._level
	xp_requirement = round(xp_requirement)
	print("Experience required for level up: ", xp_requirement, " experience accumulated: ", p_character._experience)
	if(xp_requirement <= p_character._experience):
		return true
	else:
		return false

static func AddExperience(p_character: Character, p_value: int) -> void:
	p_character._experience += p_value
	if(LevelUpCriteriaMet(p_character)):
		p_character._experience = 0
		LevelUpReward(p_character)

static func LevelUpReward(p_character: Character) -> void:
	p_character._level += 1
	var weights: Dictionary[Types.Attribute, int] = BASE_WEIGHTS.duplicate(true)
	for attribute in p_character._attributes_weights:
		weights[attribute] += PRIMARY_ATTRIBUTE_MODIFIER
	
	var cumulative_weights: Dictionary[Types.Attribute, int]
	var current_sum: int = 0
	for attribute in weights.keys():
		current_sum += weights[attribute]
		cumulative_weights[attribute] = current_sum
	var total_weight = current_sum
	
	var new_attributes: Dictionary[Types.Attribute, int] = p_character._attributes.duplicate(true)
	print("old attributes for ", p_character._name)
	for attribute in new_attributes.keys():
		print(attribute, " was ", new_attributes[attribute])
	
	print("\nStarting distribution of points for level up.\n")
	
	# Each level should increase health a bit.
	new_attributes[Types.Attribute.Health] += 1
	
	var random_roll: int = 0
	for i in range(POINTS_TO_DISTRIBUTE):
		random_roll = randi_range(0, total_weight)
		
		var chosen_attribute: Types.Attribute
		for attribute in cumulative_weights.keys():
			if(random_roll < cumulative_weights[attribute]):
				chosen_attribute = attribute
				break
		new_attributes[chosen_attribute] += 1
	
	print("--- Results ---")
	print("new attributes for ", p_character._name)
	for attribute in new_attributes:
		print(attribute, " is now ", new_attributes[attribute])
	
	p_character._attributes = new_attributes
	
	print("character ", p_character._name, " just leveled up to ", p_character._level)
