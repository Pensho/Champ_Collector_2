class_name NodeData extends Resource

enum Node_Type
{
	FIGHT,
	REST_STOP,
	BOSS,
	HINT,
	GAMBLE,
	ESCALATE,
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

func IsEligible() -> bool:
	if previous_node.is_empty():
		return true
	for previous in previous_node:
		if previous.is_complete and not previous.next_node.any(
				func(p_next: NodeData) -> bool: return p_next.is_complete):
			return true
	return false
