class_name ActData extends Resource

@export var display_name: String
@export var adventures: Array[AdventureData]
@export var gear_pool: Array[EquipmentPreset] = []
## Plays in the act's hub and every scene outside an Adventure.
@export var music_track: AudioStream

func FindAdventureIndex(p_adventure: AdventureData) -> int:
	return adventures.find(p_adventure)
