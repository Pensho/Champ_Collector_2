class_name ActData extends Resource

@export var display_name: String
@export var adventures: Array[AdventureData]

func FindAdventureIndex(p_adventure: AdventureData) -> int:
	return adventures.find(p_adventure)
