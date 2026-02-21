class_name LevelSystem
extends Node

const Types = preload("res://Scripts/common_enums.gd")

static func LevelUpCriteriaMet(p_character: Character) -> bool:
	var xp_requirement: float = pow(
		(float(p_character._level) / Game_Balance.EXPERIENCE_FACTOR), 
		Game_Balance.EXPERIENCE_EXPONENT)
	xp_requirement *= Game_Balance.EXPERIENCE_CONSTANT_1
	xp_requirement += Game_Balance.EXPERIENCE_CONSTANT_2 * p_character._level
	xp_requirement = round(xp_requirement + Game_Balance.EXPERIENCE_CONSTANT_3)
	print("Experience required for level up: ", xp_requirement, " experience accumulated: ", p_character._experience)
	return xp_requirement <= p_character._experience

static func AddExperience(p_character: Character, p_value: int) -> void:
	p_character._experience += p_value
	if(LevelUpCriteriaMet(p_character)):
		p_character._experience = 0
		LevelUpReward(p_character)

static func LevelUpReward(p_character: Character) -> void:
	p_character._level += 1
	var weights: Dictionary[Types.Attribute, int] = Game_Balance.BASE_ATTRIBUTE_WEIGHTS.duplicate(true)
	for attribute in p_character._attributes_weights:
		weights[attribute] += Game_Balance.CHARACTER_ATTRIBUTE_WEIGHT
	
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
	for i in range(Game_Balance.LEVEL_UP_POINTS_TO_DISTRIBUTE):
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

static func SetOpponentLevel(p_character: Character, p_level: int) -> void:
	if(p_level < 1 or p_level > 999):
		print("Cannot set opponent level below 1 or above 999")
		return
	var total_levels_gained = p_character._level - 1
	p_character._level = p_level
	
	var total_base_points: float = 0.0
	for attribute in p_character._attributes.keys():
		total_base_points += p_character._attributes[attribute]
	
	for attribute in p_character._attributes.keys():
		var base_value = p_character._attributes[attribute]
		var weight = base_value / total_base_points
		var points_gained = weight * Game_Balance.LEVEL_UP_POINTS_TO_DISTRIBUTE * total_levels_gained
		p_character._attributes[attribute] = round(base_value + points_gained)
	
