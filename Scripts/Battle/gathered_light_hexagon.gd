class_name GatheredLightHexagon extends Node2D

## Gathered Light's slices, shown beside the Hue-Eater and flown at the party by GatheredLightLaunch.

const SLICE_COUNT: int = 6

@export var _slices: Array[Node2D]

func SetSlices(p_count: int) -> void:
	visible = p_count > 0
	for index in _slices.size():
		_slices[index].visible = index < p_count
