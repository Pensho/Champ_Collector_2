class_name NodeData extends Resource

@export var scene_context: Static_Context

@export var next_node: Array[NodeData]
@export var previous_node: Array[NodeData]

# set by the generator that gets it from the biomes list
var modifier

var index: int
