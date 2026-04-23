class_name Adventure extends Resource

var biome: BiomeData
var current_node_index: int

# Probably a dictionary holding [type, duration]
var active_effects

var steps_taken_today: int

var nodes: Array[NodeData]
