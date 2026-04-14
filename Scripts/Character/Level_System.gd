class_name LevelSystem
extends Node

static func LevelUpCriteriaMet(p_character: Character) -> bool:
	var xp_requirement: float = GetExperienceRequirement(p_character._level)
	print("Experience required for level up: ", xp_requirement, " experience accumulated: ", p_character._experience)
	if(xp_requirement <= p_character._experience):
		p_character._experience = max(p_character._experience - xp_requirement, 0)
		return true
	return false

static func GetExperienceRequirement(p_current_level: int) -> float:
	var xp_requirement: float = pow(
		(float(p_current_level) / Game_Balance.EXPERIENCE_FACTOR), 
		Game_Balance.EXPERIENCE_EXPONENT)
	xp_requirement *= Game_Balance.EXPERIENCE_CONSTANT_1
	xp_requirement += Game_Balance.EXPERIENCE_CONSTANT_2 * float(p_current_level)
	xp_requirement = round(xp_requirement + Game_Balance.EXPERIENCE_CONSTANT_3)
	return xp_requirement

static func AddExperience(p_character: Character, p_experiene_gained: int) -> void:
	p_character._experience += p_experiene_gained
	while LevelUpCriteriaMet(p_character):
		LevelUpReward(p_character)

static func LevelUpReward(p_character: Character) -> void:
	p_character._level += 1
	var weights: Dictionary[Types.Attribute, int] = p_character._attributes_weights._weights
	
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
	
	print("\nStarting distribution of ", Game_Balance.LEVEL_UP_POINTS_TO_DISTRIBUTE + floor(pow(p_character._level, 1.1)), " points for level up.\n")
	
	# Each level should increase health a bit.
	new_attributes[Types.Attribute.Health] += 2
	
	var random_roll: int = 0
	for i in range(Game_Balance.LEVEL_UP_POINTS_TO_DISTRIBUTE + floor(pow(p_character._level, 1.1))):
		random_roll = randi_range(0, total_weight)
		
		var chosen_attribute: Types.Attribute
		for attribute in cumulative_weights.keys():
			if(random_roll <= cumulative_weights[attribute]):
				chosen_attribute = attribute
				break
		new_attributes[chosen_attribute] += 1
	
	print("--- Results ---")
	print("new attributes for ", p_character._name)
	for attribute in new_attributes:
		print(attribute, " is now ", new_attributes[attribute])
	
	p_character._attributes = new_attributes
	
	print("character ", p_character._name, " just leveled up to ", p_character._level)

static func SetOpponentLevel(p_character: Character, p_level: int, p_boss: bool = false) -> void:
	if(p_level < 1 or p_level > 999):
		print("Cannot set opponent level below 1 or above 999")
		return
	if(p_level <= p_character._level):
		return
	var total_levels_gained: float = float(p_level - p_character._level)
	p_character._level = p_level
	
	var total_base_points: float = 0.0
	for attribute in p_character._attributes.keys():
		total_base_points += p_character._attributes[attribute]
	
	p_character._attributes[Types.Attribute.Health] += 2
	
	for attribute in p_character._attributes.keys():
		var base_value: int = p_character._attributes[attribute]
		var weight: float = float(base_value) / float(total_base_points)
		var points: float
		if(Types.Attribute.Speed == attribute):
			points = Game_Balance.LEVEL_UP_POINTS_TO_DISTRIBUTE + float(p_character._level * 2)
		else:
			points = Game_Balance.LEVEL_UP_POINTS_TO_DISTRIBUTE + float(pow(p_character._level * 3, 1.1))
		if(p_boss):
			points *= 1.5
		var points_gained = weight * points * total_levels_gained
		p_character._attributes[attribute] = round(int(base_value + points_gained))
	
