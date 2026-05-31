class_name NodeData extends Resource

enum Node_Type
{
	FIGHT,
	REST_STOP,
	BOSS,
}

var scene_context: Static_Context
var next_node: Array[NodeData]
var previous_node: Array[NodeData]
var index: int
var node_type: Node_Type
var is_complete: bool = false
var depth: int

# set by the generator that gets it from the biomes list
var modifier
