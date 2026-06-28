class_name BiomeRegionData extends Resource

## One zone in the coarse region grid (e.g. Forest, Clearing, Rubble). Region_noise
## samples are mapped to a zone by cumulative selection_weight across all of a
## biome's regions.

@export var name: String
@export var selection_weight: float = 1.0
@export var tint: Color = Color.WHITE
@export var decor: Array[ZoneDecorEntry]
