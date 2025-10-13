class_name LevelSystem
extends Node

const Types = preload("res://Scripts/common_enums.gd")

static func LevelUpCriteriaMet(p_character: Character) -> bool:
	var xp_requirement: float = pow(
		(float(p_character._level) / main.GAME_BALANCE.EXPERIENCE_FACTOR), 
		main.GAME_BALANCE.EXPERIENCE_EXPONENT)
	xp_requirement *= main.GAME_BALANCE.EXPERIENCE_CONSTANT_1
	xp_requirement += main.GAME_BALANCE.EXPERIENCE_CONSTANT_2 * p_character._level
	xp_requirement = round(xp_requirement + main.GAME_BALANCE.EXPERIENCE_CONSTANT_3)
	print("Experience required for level up: ", xp_requirement, " experience accumulated: ", p_character._experience)
	return xp_requirement <= p_character._experience

static func AddExperience(p_character: Character, p_value: int) -> void:
	p_character._experience += p_value
	if(LevelUpCriteriaMet(p_character)):
		p_character._experience = 0
		LevelUpReward(p_character)

static func LevelUpReward(p_character: Character) -> void:
	p_character._level += 1
	var weights: Dictionary[Types.Attribute, int] = main.GAME_BALANCE.BASE_ATTRIBUTE_WEIGHTS.duplicate(true)
	for attribute in p_character._attributes_weights:
		weights[attribute] += main.GAME_BALANCE.CHARACTER_ATTRIBUTE_WEIGHT
	
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
	for i in range(main.GAME_BALANCE.LEVEL_UP_POINTS_TO_DISTRIBUTE):
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
