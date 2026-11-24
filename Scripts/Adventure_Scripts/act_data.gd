class_name ActData extends Resource

## The adventure selection screen offers exactly this many adventures side by side.
const ADVENTURE_COUNT: int = 2

@export var display_name: String
@export var adventures: Array[AdventureData]
@export var gear_pool: Array[EquipmentPreset] = []
## Plays in the act's hub and every scene outside an Adventure.
@export var music_track: AudioStream
@export_file("*.tscn") var hub_scene: String
@export_file("*.tscn") var region_map_scene: String

func FindAdventureIndex(p_adventure: AdventureData) -> int:
	return adventures.find(p_adventure)

func HasAdventures() -> bool:
	return adventures.size() >= ADVENTURE_COUNT
