class_name ActData extends Resource

@export var display_name: String
@export var biome_entries: Array[ActBiomeEntry]

func FindEntryIndexForBiome(p_biome: BiomeData) -> int:
	for i in range(biome_entries.size()):
		if biome_entries[i].biome == p_biome:
			return i
	return -1
