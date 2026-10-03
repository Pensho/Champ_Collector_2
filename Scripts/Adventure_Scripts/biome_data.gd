class_name BiomeData extends Resource

@export var visual_data: BiomeVisualData
@export var stage_scenes: Array[PackedScene]

var possible_node_modifiers: Dictionary[String, int]
var possible_rest_stop_buffs: Dictionary[Types.Buff_Type, int]
